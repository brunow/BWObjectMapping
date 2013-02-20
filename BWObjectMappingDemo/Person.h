//
//  Person.h
//  BWObjectMappingDemo
//
//  Created by Lucas Medeiros on 19/02/13.
//
//

#import <Foundation/Foundation.h>

typedef enum {
    GenderMale,
    GenderFemale
} Gender;

@interface Person : NSObject

@property (nonatomic, copy)   NSString *name;
@property (nonatomic, copy)   NSString *email;
@property (nonatomic, copy)   NSString *skype;
@property (nonatomic, assign) Gender   gender;
@property (nonatomic, strong) NSArray  *phones;
@property (nonatomic, strong) NSDictionary *location;

@end
