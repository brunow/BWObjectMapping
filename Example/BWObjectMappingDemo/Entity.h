//
//  Entity.h
//  BWObjectMappingDemo
//
//  Created by cesar4 on 30/07/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Entity : NSManagedObject

@property (nonatomic, retain) NSNumber * boolValue;
@property (nonatomic, retain) NSNumber * intValue;
@property (nonatomic, retain) NSNumber * doubleValue;
@property (nonatomic, retain) NSNumber * floatValue;
@property (nonatomic, retain) NSString * stringValue;

@end
