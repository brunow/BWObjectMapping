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

#import "BWObjectMapper.h"

#import "BWObjectAttributeMapping.h"
#import "BWObjectValueMapper.h"
#import "BWOjectRelationAttributeMapping.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface BWObjectMapper ()

@property (nonatomic, strong) NSMutableDictionary *mutableMappings;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation BWObjectMapper


////////////////////////////////////////////////////////////////////////////////////////////////////
+ (BWObjectMapper *)shared {
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
+ (BWObjectMapper *)mapperWithSharedMappings {
    BWObjectMapper *mapper = [[self alloc] init];
    [mapper registerMappings:[self shared].mappings];
    mapper.objectBlock = [self shared].objectBlock;
    return mapper;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)init {
    self = [super init];
    if (self) {
        self.mutableMappings = [NSMutableDictionary dictionary];
        self.defaultMappings = [NSMutableDictionary dictionary];
        self.defaultDateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZZZZ";
    }
    return self;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSDictionary *)mappings {
    return [self.mutableMappings copy];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)registerMappings:(NSDictionary *)mappings {
    self.mutableMappings = [mappings mutableCopy];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)unregisterAllMappings {
    [self.mutableMappings removeAllObjects];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)registerMappingForClass:(Class)klass {
    [self registerMappingForClass:klass withRootKeyPath:nil];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)registerMappingForClass:(Class)klass withRootKeyPath:(NSString *)keyPath {
    [self registerMappingForClass:klass withRootKeyPath:keyPath mapping:nil];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)registerMappingForClass:(Class)klass mapping:(BWObjectMappingMappingBlock)mappingBlock {
    [self registerMappingForClass:klass withRootKeyPath:nil mapping:mappingBlock];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)registerMappingForClass:(Class)klass withRootKeyPath:(NSString *)keyPath mapping:(BWObjectMappingMappingBlock)mappingBlock {
    BWObjectMapping *mapping = [[BWObjectMapping alloc] initWithObjectClass:klass];
    
    if (mappingBlock) {
        mappingBlock(mapping);
    }
    
    [self registerMapping:mapping
          withRootKeyPath:keyPath];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)registerMapping:(BWObjectMapping *)mapping {
    [self registerMapping:mapping withRootKeyPath:nil];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)registerMapping:(BWObjectMapping *)mapping withRootKeyPath:(NSString *)keyPath {
    NSString *objectName = NSStringFromClass(mapping.objectClass);
    mapping.rootKeyPath = keyPath;
    [self.mutableMappings setObject:mapping forKey:objectName];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)objectWithBlock:(BWObjectMappingObjectBlock)objectBlock {
    self.objectBlock = objectBlock;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didMapObjectWithBlock:(BWObjectMappingObjectDidMapObjectBlock)didMapBlock {
    self.didMapObjectBlock = didMapBlock;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSArray *)objectsFromJSON:(id)JSON withMapping:(BWObjectMapping *)mapping userInfo:(id)userInfo {
    NSMutableArray *objects = [NSMutableArray array];
    
    if ([JSON isKindOfClass:[NSArray class]]) {
        
        for (id obj in JSON) {
            NSArray *newObjects = [self objectsFromJSON:obj withMapping:mapping userInfo:userInfo];
            [objects addObjectsFromArray:newObjects];
        }
        
    } else if ([JSON objectForKey:mapping.rootKeyPath]) {
        NSArray *newObjects = [self objectsFromJSON:[JSON objectForKey:mapping.rootKeyPath] withMapping:mapping userInfo:userInfo];
        [objects addObjectsFromArray:newObjects];
        
    } else if ([JSON isKindOfClass:[NSDictionary class]]) {
        id object = [self objectFromJSON:JSON withMapping:mapping userInfo:userInfo];
        
        if (nil != object)
            [objects addObject:object];
    }
    
    return [NSArray arrayWithArray:objects];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSArray *)objectsFromJSON:(id)JSON withObjectClass:(Class)objectClass userInfo:(id)userInfo {
    NSString *objectName = NSStringFromClass(objectClass);
    BWObjectMapping *mapping = [self.mappings objectForKey:objectName];
    return [self objectsFromJSON:JSON withMapping:mapping userInfo:userInfo];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSArray *)objectsFromJSON:(id)JSON userInfo:(id)userInfo {
    NSMutableArray *objects = [NSMutableArray array];
    
    if ([JSON isKindOfClass:[NSArray class]]) {
        
        for (id obj in JSON) {
            NSArray *newObjects = [self objectsFromJSON:obj userInfo:userInfo];
            [objects addObjectsFromArray:newObjects];
        }
        
    } else if ([JSON isKindOfClass:[NSDictionary class]]) {
        
        for (NSString *key in self.mappings) {
            BWObjectMapping *objectMapping = [self.mappings objectForKey:key];
            NSString *rootKeyPath = objectMapping.rootKeyPath;
            id rootKeyPathObject = [JSON objectForKey:rootKeyPath];
            
            if (nil != rootKeyPathObject) {
                NSArray *newbjects = [self objectsFromJSON:rootKeyPathObject withMapping:objectMapping userInfo:userInfo];
                
                if (newbjects.count > 0)
                    [objects addObjectsFromArray:newbjects];
            }
        }
        
    }
    
    return [NSArray arrayWithArray:objects];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)objectFromJSON:(id)JSON withMapping:(BWObjectMapping *)mapping userInfo:(id)userInfo {
    return [self objectFromJSON:JSON withMapping:mapping existingObject:nil userInfo:userInfo];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)objectFromJSON:(id)JSON withMapping:(BWObjectMapping *)mapping existingObject:(id)object userInfo:(id)userInfo {
    id JSONToMap = [JSON objectForKey:mapping.rootKeyPath];
    
    if (nil == JSONToMap || [NSNull null] == JSONToMap)
        JSONToMap = JSON;
    
    NSString *primaryKey = mapping.primaryKeyAttribute.attribute;
    id primaryKeyValue = [JSONToMap objectForKey:mapping.primaryKeyAttribute.keyPath];
    
    if (nil == object) {
        if (nil == self.objectBlock) {
            object = [[mapping.objectClass alloc] init];
        } else {
            object = self.objectBlock(mapping.objectClass, primaryKey, primaryKeyValue, JSONToMap, userInfo);
        }
    }
    
    [self mapDictionary:JSONToMap toObject:object withMapping:mapping userInfo:userInfo];
    
    return object;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)objectFromJSON:(id)JSON withObjectClass:(Class)objectClass userInfo:(id)userInfo {
    return [self objectFromJSON:JSON withObjectClass:objectClass existingObject:nil userInfo:userInfo];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)objectFromJSON:(id)JSON withObjectClass:(Class)objectClass existingObject:(id)object userInfo:(id)userInfo {
    NSString *objectName = NSStringFromClass(objectClass);
    BWObjectMapping *mapping = [self.mappings objectForKey:objectName];
    
    if (nil == mapping) {
        mapping = [[BWObjectMapping alloc] initWithObjectClass:objectClass];
    }
    
    return [self objectFromJSON:JSON withMapping:mapping existingObject:object userInfo:userInfo];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)objectFromJSON:(id)JSON userInfo:(id)userInfo {
    return [self objectFromJSON:JSON existingObject:nil userInfo:userInfo];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)objectFromJSON:(id)JSON existingObject:(id)object userInfo:(id)userInfo {
    id parsedObject = nil;
    
    for (NSString *key in self.mappings) {
        BWObjectMapping *objectMapping = [self.mappings objectForKey:key];
        if (objectMapping.objectClass == [object class]) {
            parsedObject = [self objectFromJSON:JSON withMapping:objectMapping existingObject:object userInfo:userInfo];
            
            break;
        }
    }
    
    return parsedObject;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)mapKeyPath:(NSString *)keyPath toAttribute:(NSString *)attribute {
    [self.defaultMappings setObject:keyPath forKey:attribute];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSArray *)objectsFromJSON:(id)JSON withMapping:(BWObjectMapping *)mapping {
    return [self objectsFromJSON:JSON withMapping:mapping userInfo:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSArray *)objectsFromJSON:(id)JSON withObjectClass:(Class)objectClass {
    return [self objectsFromJSON:JSON withObjectClass:objectClass userInfo:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSArray *)objectsFromJSON:(id)JSON {
    return [self objectsFromJSON:JSON userInfo:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)objectFromJSON:(id)JSON withMapping:(BWObjectMapping *)mapping {
    return [self objectFromJSON:JSON withMapping:mapping userInfo:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)objectFromJSON:(id)JSON withMapping:(BWObjectMapping *)mapping existingObject:(id)object {
    return [self objectFromJSON:JSON withMapping:mapping existingObject:object userInfo:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)objectFromJSON:(id)JSON withObjectClass:(Class)objectClass {
    return [self objectFromJSON:JSON withObjectClass:objectClass userInfo:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)objectFromJSON:(id)JSON withObjectClass:(Class)objectClass existingObject:(id)object {
    return [self objectFromJSON:JSON withObjectClass:objectClass existingObject:object userInfo:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)objectFromJSON:(id)JSON {
    return [self objectsFromJSON:JSON userInfo:nil];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)objectFromJSON:(id)JSON existingObject:(id)object {
    return [self objectFromJSON:JSON existingObject:object userInfo:nil];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)mapDictionary:(NSDictionary *)dict toObject:(id)object withMapping:(BWObjectMapping *)mapping  userInfo:userInfo {
    for (NSString *key in mapping.attributeMappings) {
        BWObjectAttributeMapping *attributeMapping = [mapping.attributeMappings objectForKey:key];
        [[BWObjectValueMapper shared] setValue:[dict valueForKeyPath:attributeMapping.keyPath]
                                    forKeyPath:attributeMapping.attribute
                          withAttributeMapping:attributeMapping
                                     forObject:object];
    }
    //
    for (NSString *key in mapping.hasOneMappings) {
        BWOjectRelationAttributeMapping *relationObjectMapping = [mapping.hasOneMappings objectForKey:key];
        id result = nil;
        id relationJSON = [dict objectForKey:key];
        
        if (nil == relationJSON) {
            break;
        }
        
        if (nil != relationObjectMapping.objectMapping && [NSNull null] != relationJSON) {
            result = [self objectFromJSON:relationJSON
                              withMapping:relationObjectMapping.objectMapping userInfo:userInfo];
            
        } else if (nil != relationObjectMapping.objectMappingClass && [NSNull null] != relationJSON) {
            result = [self objectFromJSON:relationJSON
                          withObjectClass:relationObjectMapping.objectMappingClass  userInfo:userInfo];
        }
        
        if (nil != relationObjectMapping.valueBlock) {
            result = relationObjectMapping.valueBlock(result);
        }
        
        [object setValue:result forKeyPath:relationObjectMapping.attribute];
    }
    //
    for (NSString *key in mapping.hasManyMappings) {
        BWOjectRelationAttributeMapping *relationObjectMapping = [mapping.hasManyMappings objectForKey:key];
        NSArray *result = nil;
        id relationJSON = [dict objectForKey:key];
        
        if (nil == relationJSON) {
            break;
        }
        
        if (nil != relationObjectMapping.objectMapping && [NSNull null] != relationJSON) {
            result = [self objectsFromJSON:relationJSON
                               withMapping:relationObjectMapping.objectMapping  userInfo:userInfo];
            
        } else if (nil != relationObjectMapping.objectMappingClass && [NSNull null] != relationJSON) {
            result = [self objectsFromJSON:relationJSON
                           withObjectClass:relationObjectMapping.objectMappingClass  userInfo:userInfo];
        }
        
        if (nil != relationObjectMapping.valueBlock) {
            result = relationObjectMapping.valueBlock(result);
        }
        
        [[BWObjectValueMapper shared] setValue:result forKeyPath:relationObjectMapping.attribute withAttributeMapping:nil forObject:object];
    }
    //
    if (nil != self.didMapObjectBlock) {
        self.didMapObjectBlock(object);
    }
    
    if (mapping.completionBlock) {
        mapping.completionBlock(object, dict);
    }
}


@end
