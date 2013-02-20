//
//  Car.h
//  BWObjectMappingDemo
//
//  Created by Lucas Medeiros on 19/02/13.
//
//

#import <Foundation/Foundation.h>

@class Engine;

@interface Car : NSObject

@property (nonatomic, copy)   NSString *model;
@property (nonatomic, copy)   NSString *year;
@property (nonatomic, strong) Engine   *engine;
@property (nonatomic, strong) NSArray  *wheels;

@end
