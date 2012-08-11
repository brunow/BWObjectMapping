//
//  User.h
//  BWObjectMappingDemo
//
//  Created by Bruno Wernimont on 21/07/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Comment;

@interface User : NSObject

@property (nonatomic, strong) NSNumber *userID;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSArray *comments;

@end
