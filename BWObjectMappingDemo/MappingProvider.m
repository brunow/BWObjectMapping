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

@implementation MappingProvider

+ (BWObjectMapping *)carMapping
{
    return [BWObjectMapping mappingForObject:[Car class] block:^(BWObjectMapping *mapping) {
        [mapping mapAttributeFromArray:@[@"model", @"year"]];
        [mapping hasOneWithRelationMapping:[self engineMapping] fromKeyPath:@"engine"];
    }];
}

+ (BWObjectMapping *)engineMapping
{
    return [BWObjectMapping mappingForObject:[Engine class] block:^(BWObjectMapping *mapping) {
        [mapping mapAttributeFromArray:@[@"type"]];
    }];
}

@end
