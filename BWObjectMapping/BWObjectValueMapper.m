//
// Created by Bruno Wernimont on 2012
// Copyright 2012 BWObjectMapping
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "BWObjectValueMapper.h"

#import "BWObjectMapper.h"
#import "BWObjectMappingBlocks.h"

#import <objc/runtime.h>

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface BWObjectValueMapper ()

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation BWObjectValueMapper


////////////////////////////////////////////////////////////////////////////////////////////////////
+ (BWObjectValueMapper *)shared {
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setValue:(id)value
      forKeyPath:(NSString *)keyPath
withAttributeMapping:(BWObjectAttributeMapping *)attributeMapping
       forObject:(id)object {
    
    if (nil == value) {
        return;
    }
    
    id transformedValue = value;
    
    if ([NSNull class] == [transformedValue class]) {
        transformedValue = nil;
        [object setValue:transformedValue forKeyPath:keyPath];
        return;
    }
    
    if ([value isKindOfClass:[NSString class]]) {
        NSDate *date = [self parseDateValue:value withAttributeMapping:attributeMapping object:object];
        
        if (nil != date) {
            transformedValue = date;
        }
    }
    
    if (nil != attributeMapping.valueBlock) {
        transformedValue = [self transformValue:value
                                 withValueBlock:attributeMapping.valueBlock
                                     fromObject:object];
    }
    
    if ([object isKindOfClass:NSClassFromString(@"NSManagedObject")]) {
        transformedValue = [self transformValue:transformedValue forKeyPath:keyPath withCoreDataObject:object];
    }
    
    if ([transformedValue isKindOfClass:[NSArray class]]) {
        transformedValue = [self transformArrayValue:transformedValue forKeyPath:keyPath withObject:object];
    }
    
    [object setValue:transformedValue forKeyPath:keyPath];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private


////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)transformArrayValue:(id)value forKeyPath:(NSString *)keyPath withObject:(id)object {
    NSString *propertyString = [self propertyStringTypeForName:keyPath object:object];
    
    if ([propertyString isEqualToString:@"NSSet"]) {
        return [NSSet setWithArray:value];
        
    } else if ([propertyString isEqualToString:@"NSOrderedSet"]) {
        return [NSOrderedSet orderedSetWithArray:value];
        
    } else if ([propertyString isEqualToString:@"NSArray"]) {
        return value;
    }
    
    return nil;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)transformValue:(id)value forKeyPath:(NSString *)keyPath withCoreDataObject:(NSManagedObject *)object {
    if (nil == value) {
        return nil;
    }
    
    NSAttributeDescription *attributeDesc = [[[object entity] attributesByName] objectForKey:keyPath];
    
    id transformedValue = nil;
    
    if(nil == attributeDesc) {
        return value;
    }
    
    NSAttributeType attributeType = attributeDesc.attributeType;
    Class expectedClass = NSClassFromString(attributeDesc.attributeValueClassName);
    
    if([value isKindOfClass:expectedClass]) {
        return value;
    }
    
    switch (attributeType) {
        case NSBooleanAttributeType:
            if([value respondsToSelector:@selector(boolValue)])
                transformedValue = [NSNumber numberWithBool:[value boolValue]];
            break;
        case NSInteger16AttributeType :
        case NSInteger32AttributeType :
            if([value respondsToSelector:@selector(intValue)])
                transformedValue = [NSNumber numberWithLong:[value intValue]];
            break;
        case NSInteger64AttributeType :
            if([value respondsToSelector:@selector(longLongValue)])
                transformedValue = [NSNumber numberWithLongLong:[value longLongValue]];
            break;
        case NSDecimalAttributeType :
            if([value isKindOfClass:[NSString class]])
                transformedValue = [NSDecimalNumber decimalNumberWithString:value];
            break;
        case NSDoubleAttributeType :
            if([value respondsToSelector:@selector(doubleValue)])
                transformedValue = [NSNumber numberWithDouble:[value doubleValue]];
            break;
        case NSFloatAttributeType :
            if([value respondsToSelector:@selector(floatValue)])
                transformedValue = [NSNumber numberWithFloat:[value floatValue]];
            break;
        case NSStringAttributeType :
            if([value respondsToSelector:@selector(stringValue)])
                transformedValue = [value stringValue];
            break;
        case NSDateAttributeType :
        case NSBinaryDataAttributeType:
            break;
        case NSObjectIDAttributeType:
        case NSTransformableAttributeType:
            break;
        default :
            transformedValue = value;
            break;
    }
    
    return transformedValue;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)transformValue:(id)value withValueBlock:(BWObjectMappingValueBlock)valueBlock fromObject:(id)object {
    return valueBlock(value, object);
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSDate *)parseDateValue:(NSString *)value withAttributeMapping:(BWObjectAttributeMapping *)attributeMapping object:(id)object {
    NSString *cacheKey = [NSString stringWithFormat:@"%@-%@-isDate", NSStringFromClass([object class]), attributeMapping.attribute];
    
    if ([value length] > 30) {
        [[self cache] setValue:@(NO) forKey:cacheKey];
        return nil;
    }
    
    if ([[self cache] objectForKey:cacheKey] && NO == [[[self cache] objectForKey:cacheKey] boolValue]) {
        return nil;
    }
    
    NSString *dateFormat = nil;
    
    if (nil != attributeMapping.dateFormat) {
        dateFormat = attributeMapping.dateFormat;
    } else {
        dateFormat = [[BWObjectMapper shared] defaultDateFormat];
    }
    
    NSString *dateformaterKey = [NSString stringWithFormat:@"dateFormatter-%d-%@", [BWObjectMapper shared].timeZoneForSecondsFromGMT, dateFormat];
    
    NSDateFormatter *dateFormatter = [[self cache] objectForKey:dateformaterKey];
    if (nil == dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:[BWObjectMapper shared].timeZoneForSecondsFromGMT];
        dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [dateFormatter setDateFormat:dateFormat];
        [[self cache] setObject:dateFormatter forKey:dateformaterKey];
    }
    
    NSDate *date = [dateFormatter dateFromString:value];
    
    if (value) {
        BOOL isDate = !!date;
        [[self cache] setValue:@(isDate) forKey:cacheKey];
    }
    
    return date;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)propertyStringTypeForName:(NSString *)propertyName object:(id)object {
    return [BWObjectValueMapper propertyStringTypeForName:propertyName klass:[object class]];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSString *)propertyStringTypeForName:(NSString *)propertyName klass:(Class)klass {
    NSString *cacheKey = [NSString stringWithFormat:@"%@-%@-propertyStringType", NSStringFromClass(klass), propertyName];
    
    if ([[self cache] objectForKey:cacheKey]) {
        return [[self cache] objectForKey:cacheKey];
    }
    
    objc_property_t property = class_getProperty(klass, [propertyName UTF8String]);
    
    if (NULL == property) {
        return nil;
    }
    
    unsigned int numberOfAttributes = 0;
    objc_property_attribute_t *attributes = property_copyAttributeList(property, &numberOfAttributes);
    
    NSString *attributeType = nil;
    
    unsigned int i = 0;
    BOOL foundAttributeType = NO;
    while (i < numberOfAttributes || !foundAttributeType) {
        const char *attributeName = attributes[i].name;
        if (1 == strlen(attributeName)) {
            switch (attributeName[0]) {
                case 'T':
                    attributeType = [NSString stringWithFormat:@"%s", attributes[i].value];
                    foundAttributeType = YES;
                    break;
            }
        }
        
        i++;
    }
    
    if ([attributeType length] > 3) {
        NSString *propertyType = [attributeType substringWithRange:NSMakeRange(2, attributeType.length-3)];
        [[self cache] setObject:propertyType forKey:cacheKey];
        return propertyType;
    }
    
    return nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSMutableDictionary *)cache {
    return [[self class] cache];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSMutableDictionary *)cache {
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[NSMutableDictionary alloc] init];
    });
    return _sharedObject;
}


@end
