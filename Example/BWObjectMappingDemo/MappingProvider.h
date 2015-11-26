//
//  MappingProvider.h
//  BWObjectMappingDemo
//
//  Created by Lucas Medeiros on 19/02/13.
//
//

#import <Foundation/Foundation.h>
#import "BWObjectMapper.h"

@interface MappingProvider : NSObject

+ (BWObjectMapping *)carMapping;
+ (BWObjectMapping *)engineMapping;

@end
