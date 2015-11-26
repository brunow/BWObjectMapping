//
//  MappingProvider.m
//  BWObjectMappingDemo
//
//  Created by Lucas Medeiros on 19/02/13.
//
//

#import "MappingProvider.h"
#import "Car.h"
#import "Engine.h"
#import "Wheel.h"

@implementation MappingProvider

+ (BWObjectMapping *)carMapping
{
    return [BWObjectMapping mappingForObject:[Car class] block:^(BWObjectMapping *mapping) {
        [mapping mapAttributeFromArray:@[@"model", @"year"]];
        [mapping hasOneWithRelationMapping:[self engineMapping] forKeyPath:@"engine"];
        [mapping hasManyWithRelationMapping:[self wheelMapping] forKeyPath:@"wheels"];
        [mapping hasManyWithRelationMapping:[self wheelMapping] forKeyPath:@"wheelsSet"];
        [mapping hasManyWithRelationMapping:[self wheelMapping] forKeyPath:@"wheelsOrderedSet"];
    }];
}

+ (BWObjectMapping *)engineMapping
{
    return [BWObjectMapping mappingForObject:[Engine class] block:^(BWObjectMapping *mapping) {
        [mapping mapAttributeFromArray:@[@"type"]];
    }];
}

+ (BWObjectMapping *)wheelMapping
{
    return [BWObjectMapping mappingForObject:[Wheel class] block:^(BWObjectMapping *mapping) {
        [mapping mapAttributeFromArray:@[@"size"]];
        [mapping mapAttributeFromDictionary:@{
            @"id": @"identifier"
         }];
    }];
}

@end
