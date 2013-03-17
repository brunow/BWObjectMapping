#import "Kiwi.h"

#import "BWObjectMapper.h"
#import "User.h"
#import "Comment.h"
#import "Person.h"
#import "Entity.h"
#import "Car.h"
#import "Engine.h"
#import "Wheel.h"
#import "MappingProvider.h"
#import "AppDelegate.h"

#define CUSTOM_VALUE_VALUE @"customValue"

SPEC_BEGIN(BWObjectMapperSpecs)

describe(@"mapping", ^{
    
    context(@"Simple object", ^{
        
        beforeAll(^{
            [[BWObjectMapper shared] unregisterAllMappings];
            
            [BWObjectMapping mappingForObject:[User class] block:^(BWObjectMapping *mapping) {
                [mapping mapPrimaryKeyAttribute:@"id" toAttribute:@"userID"];
                [mapping mapKeyPath:@"first_name" toAttribute:@"firstName"];
                [mapping mapKeyPath:@"created_at" toAttribute:@"createdAt"];
                [[BWObjectMapper shared] registerMapping:mapping withRootKeyPath:@"user"];
            }];
            
            [BWObjectMapping mappingForObject:[Comment class] block:^(BWObjectMapping *objectMapping) {
                [objectMapping mapKeyPath:@"comment" toAttribute:@"comment"];
                
                [objectMapping mapKeyPath:@"custom_value" toAttribute:@"customValue" valueBlock:^id(id value, id object) {
                    return CUSTOM_VALUE_VALUE;
                }];
                
                [[BWObjectMapper shared] registerMapping:objectMapping withRootKeyPath:@"comment"];
            }];
            
        });
        
        it(@"should map the right object mapping", ^{
            id expectedFirstName = @"bruno";
            id expectedUserID = [NSNumber numberWithInt:4];
            
            NSDictionary *userJSON = [NSDictionary dictionaryWithObjectsAndKeys:
                                      expectedFirstName, @"first_name",
                                      expectedUserID, @"id",
                                      nil];
            
            NSDictionary *JSON = [NSDictionary dictionaryWithObject:userJSON forKey:@"user"];
            
            NSArray *objects = [[BWObjectMapper shared] objectsFromJSON:JSON];
            User *user = [objects lastObject];
            Class class = [[objects lastObject] class];
            
            [[theValue(class) should] equal:theValue([User class])];
            [[theValue(objects.count) should] equal:theValue(1)];
            [[user.userID should] equal:expectedUserID];
            [[user.firstName should] equal:expectedFirstName];
        });
        
        it(@"should map object with the given class", ^{
            NSDictionary *userJSON = [NSDictionary dictionaryWithObjectsAndKeys:
                                      @"bruno", @"first_name",
                                      nil];
            
            NSDictionary *JSON = [NSDictionary dictionaryWithObject:userJSON forKey:@"user"];
            
            NSArray *objects = [[BWObjectMapper shared] objectsFromJSON:JSON withObjectClass:[User class]];
            Class class = [[objects lastObject] class];
            
            [[theValue(class) should] equal:theValue([User class])];
        });
        
        it(@"should have many objects", ^{
            NSDictionary *userDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                      @"bruno", @"first_name",
                                      @"3", @"id",
                                      nil];
            
            NSDictionary *dict = [NSDictionary dictionaryWithObject:userDict forKey:@"user"];
            NSMutableArray *JSON = [NSMutableArray array];
            
            int expectedNumberOfObjects = 5;
            
            for (int i = 0; i < expectedNumberOfObjects; i++) {
                [JSON addObject:dict];
            }
            
            int objectCount = [[[BWObjectMapper shared] objectsFromJSON:JSON] count];
            [[theValue(objectCount) should] equal:theValue(expectedNumberOfObjects)];
        });
        
        it(@"should map date", ^{
            NSDictionary *userDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                      @"1981-10-23T07:45:00Z", @"created_at",
                                      nil];
            
            User *user = [[BWObjectMapper shared] objectFromJSON:userDict withObjectClass:[User class]];
            
            NSDate *expectedDate = [NSDate dateWithTimeIntervalSince1970:372671100];
            
            [[user.createdAt should] equal:expectedDate];
        });
        
        it(@"should map custom value", ^{
            NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"a value that must be transformed", @"custom_value",
                                  nil];
            
            Comment *comment = [[BWObjectMapper shared] objectFromJSON:dict withObjectClass:[Comment class]];
            
            NSString *expected = CUSTOM_VALUE_VALUE;
            
            [[comment.customValue should] equal:expected];
        });
        
        it(@"should call didMapObject block", ^{
            __block BOOL hasCalledDidMapObjectBlock = NO;
            BWObjectMapper *mapper = [BWObjectMapper shared];
            
            [mapper didMapObjectWithBlock:^(id object) {
                hasCalledDidMapObjectBlock = YES;
            }];
            
            [mapper objectFromJSON:nil withObjectClass:[Comment class]];
            [mapper setDidMapObjectBlock:nil];
            
            [[theValue(hasCalledDidMapObjectBlock) should] equal:theValue(YES)];
        });
        
        it(@"should add attribute mapping from array and dictionary", ^{
            [BWObjectMapping mappingForObject:[User class] block:^(BWObjectMapping *mapping) {
                [mapping mapAttributeFromArray:@[@"name"]];
                [mapping mapAttributeFromDictionary:@{@"created_at" : @"createdAt"}];
                
                [[theValue([mapping.attributeMappings count]) should] equal:theValue(2)];
            }];
        });
        
        it(@"should set nil value from null even if value is already set to an existing object", ^{
            BWObjectMapping *m = [BWObjectMapping mappingForObject:[User class] block:^(BWObjectMapping *mapping) {
                [mapping mapKeyPath:@"first_name" toAttribute:@"firstName"];
                [[BWObjectMapper shared] registerMapping:mapping];
            }];
            
            id JSON = @{@"first_name": @"Bruno"};
            User *user = [[BWObjectMapper shared] objectFromJSON:JSON withMapping:m];
            [[user.firstName should] equal:@"Bruno"];
            
            JSON = @{@"first_name": [NSNull null]};
            [[BWObjectMapper shared] objectFromJSON:JSON withMapping:m existingObject:user];
            [[@"Bruno" shouldNot] equal:user.firstName];
        });
        
    });
    
    context(@"Many object", ^{
        __block NSDictionary *JSON;
        
        beforeAll(^{
            [[BWObjectMapper shared] unregisterAllMappings];
            
            [BWObjectMapping mappingForObject:[Person class] block:^(BWObjectMapping *mapping) {
                [mapping mapKeyPath:@"name" toAttribute:@"name"];
                [[BWObjectMapper shared] registerMapping:mapping withRootKeyPath:@"persons"];
            }];
            
            [BWObjectMapping mappingForObject:[User class] block:^(BWObjectMapping *mapping) {
                [mapping mapKeyPath:@"email" toAttribute:@"email"];
                [[BWObjectMapper shared] registerMapping:mapping withRootKeyPath:@"users"];
            }];
        });
        
        beforeEach(^{
            JSON = @{@"persons": @[ @{@"name": @"Bruno"} ],
                     @"users" : @[ @{@"email": @"hello@brunowernimont.be"} ]
                     };
        });
        
        it(@"should map one person person object and one user object", ^{
            NSArray *objects = [[BWObjectMapper shared] objectsFromJSON:JSON];
            
            [[theValue(objects.count) should] equal:theValue(2)];
            
            Person *person = [objects objectAtIndex:0];
            User *user = [objects objectAtIndex:1];
            
            [[theValue([person class]) should] equal:theValue([Person class])];
            [[theValue([user class]) should] equal:theValue([User class])];
        });
        
    });
    
    context(@"Nested Attributes", ^{
        
        __block Person *person;
        __block NSDictionary *JSON;
        __block BWObjectMapping *personMapping;
        
        beforeAll(^{
            
            personMapping = [BWObjectMapping mappingForObject:[Person class] block:^(BWObjectMapping *mapping) {
                [mapping mapKeyPath:@"person.name" toAttribute:@"name"];
                [mapping mapKeyPath:@"person.contact.email" toAttribute:@"email"];
                [mapping mapKeyPath:@"person.contact.others.skype" toAttribute:@"skype"];
                [mapping mapKeyPath:@"person.contact.phones" toAttribute:@"phones"];
                [mapping mapKeyPath:@"person.address.location" toAttribute:@"location"];
            }];
            
        });
        
        beforeEach(^{
            
            JSON = @{ @"person" : @{ @"name" : @"Lucas",
                                     @"contact" : @{
                                             @"email" : @"lucastoc@gmail.com",
                                             @"phones" : @[ @"(12)1233-1333", @"(85)12331233" ],
                                             @"others" : @{ @"skype" : @"aspmedeiros"}
                                             },
                                     @"address" : @{
                                             @"location" : @{ @"lat": @(-18.123123123), @"long" : @(3.1123123123) }
                                             }
                                     }
                      };
            
            person = [[BWObjectMapper shared] objectFromJSON:JSON withMapping:personMapping];
            
        });
        
        specify(^{
            [[person should] beNonNil];
        });
        
        specify(^{
            [[person.name should] equal:[[JSON objectForKey:@"person"] objectForKey:@"name"]];
        });
        
        specify(^{
            [[person.email should] equal:[[[JSON objectForKey:@"person"] objectForKey:@"contact"] objectForKey:@"email"]];
        });
        
        specify(^{
            [[person.skype should] equal:[[[[JSON objectForKey:@"person"] objectForKey:@"contact"] objectForKey:@"others"] objectForKey:@"skype"]];
        });
        
        specify(^{
            int phonesCount = [person.phones count];
            int expectedPhoneCount = [[[[JSON objectForKey:@"person"] objectForKey:@"contact"] objectForKey:@"phones"] count];
            [[theValue(phonesCount) should] equal:theValue(expectedPhoneCount)];
        });
        
        specify(^{
            [[person.location should] equal:[[[JSON objectForKey:@"person"] objectForKey:@"address"] objectForKey:@"location"]];
        });
        
        
    });
    
    context(@"Custom conversion to enum", ^{
        
        context(@"when is a male", ^{
            
            __block Person *person;
            __block NSDictionary *JSON;
            __block BWObjectMapping *personMapping;
            
            beforeAll(^{
                
                personMapping = [BWObjectMapping mappingForObject:[Person class] block:^(BWObjectMapping *mapping) {
                    [mapping mapKeyPath:@"person.name" toAttribute:@"name"];
                    [mapping mapKeyPath:@"person.gender" toAttribute:@"gender" valueBlock:^id(id value, id object) {
                        if ([value isEqualToString:@"male"]) {
                            return @(GenderMale);
                        } else {
                            return @(GenderFemale);
                        }
                    }];
                }];
                
            });
            
            beforeEach(^{
                
                JSON = @{ @"person" : @{ @"name" : @"Lucas", @"gender": @"male" } };
                person = [[BWObjectMapper shared] objectFromJSON:JSON withMapping:personMapping];
                
            });
            
            specify(^{
                [[person should] beNonNil];
            });
            
            specify(^{
                [[person.name should] equal:[[JSON objectForKey:@"person"] objectForKey:@"name"]];
            });
            
            specify(^{
                [[theValue(person.gender) should] equal:theValue(GenderMale)];
            });
            
        });
        
        context(@"when is female", ^{
            
            __block Person *person;
            __block NSDictionary *JSON;
            __block BWObjectMapping *personMapping;
            
            beforeAll(^{
                
                personMapping = [BWObjectMapping mappingForObject:[Person class] block:^(BWObjectMapping *mapping) {
                    [mapping mapKeyPath:@"person.name" toAttribute:@"name"];
                    [mapping mapKeyPath:@"person.gender" toAttribute:@"gender" valueBlock:^id(id value, id object) {
                        if ([value isEqualToString:@"male"]) {
                            return @(GenderMale);
                        } else {
                            return @(GenderFemale);
                        }
                    }];
                }];
                
            });
            
            beforeEach(^{
                
                JSON = @{ @"person" : @{ @"name" : @"Jenny", @"gender": @"female" } };
                person = [[BWObjectMapper shared] objectFromJSON:JSON withMapping:personMapping];
                
            });
            
            specify(^{
                [[person should] beNonNil];
            });
            
            specify(^{
                [[person.name should] equal:[[JSON objectForKey:@"person"] objectForKey:@"name"]];
            });
            
            specify(^{
                [[theValue(person.gender) should] equal:theValue(GenderFemale)];
            });
            
        });
        
    });
    
    context(@"Has one relation", ^{
        
        __block Car *car;
        __block NSDictionary *carJSON;
        
        beforeEach(^{
            
            carJSON = @{ @"model" : @"HB20",
                      @"year" : @"2013",
                      @"engine" : @{ @"type" : @"v8" }
                      };
            
            car = [[BWObjectMapper shared] objectFromJSON:carJSON withMapping:[MappingProvider carMapping]];
            
        });
        
        specify(^{
            [[car should] beNonNil];
        });
        
        specify(^{
            [[car.engine should] beNonNil];
        });
        
        specify(^{
            [[car.engine.type should] equal:[[carJSON objectForKey:@"engine"] objectForKey:@"type"]];
        });
        
    });
    
    context(@"Has many relation", ^{
        
        __block Car *car;
        __block NSDictionary *carWithWheelsJSON;
        
        beforeEach(^{
            
            carWithWheelsJSON = @{ @"model" : @"HB20",
                                   @"year" : @"2013",
                                   @"engine" : @{ @"type" : @"v8" },
                                   @"wheels" : @[ @{ @"id" : @"123123123", @"type" : @"16" }, @{ @"id" : @"1234", @"type" : @"17" } ],
                                   @"wheelsSet" : @[ @{ @"id" : @"123123123", @"type" : @"16" }, @{ @"id" : @"1234", @"type" : @"17" } ],
                                   @"wheelsOrderedSet" : @[ @{ @"id" : @"123123123", @"type" : @"16" }, @{ @"id" : @"1234", @"type" : @"17" } ]
                                };
            
            car = [[BWObjectMapper shared] objectFromJSON:carWithWheelsJSON withMapping:[MappingProvider carMapping]];
            
        });
        
        specify(^{
            [[car should] beNonNil];
        });
        
        specify(^{
            [[car.wheels should] beNonNil];
        });
        
        specify(^{
            [[car.wheels should] beNonNil];
        });
        
        specify(^{
            [[theValue([car.wheels count]) should] beGreaterThan:theValue(0)];
            [[car.wheels should] beKindOfClass:[NSArray class]];
        });
        
        describe(@"Array must be converted to NSSet and NSOrderedSet", ^{
            specify(^{
                [[theValue([car.wheelsSet count]) should] beGreaterThan:theValue(0)];
                [[car.wheelsSet should] beKindOfClass:[NSSet class]];
                
                [[theValue([car.wheelsOrderedSet count]) should] beGreaterThan:theValue(0)];
                [[car.wheelsOrderedSet should] beKindOfClass:[NSOrderedSet class]];
            });
        });
        
    });
    
    context(@"Core data object", ^{
        
        beforeAll(^{
            [[BWObjectMapper shared] unregisterAllMappings];
            
            [BWObjectMapping mappingForObject:[Entity class] block:^(BWObjectMapping *mapping) {
                [mapping mapKeyPath:@"bool" toAttribute:@"boolValue"];
                [mapping mapKeyPath:@"int" toAttribute:@"intValue"];
                [mapping mapKeyPath:@"double" toAttribute:@"doubleValue"];
                [mapping mapKeyPath:@"float" toAttribute:@"floatValue"];
                [mapping mapKeyPath:@"string" toAttribute:@"stringValue"];
                
                [[BWObjectMapper shared] registerMapping:mapping];
            }];
            
            [[BWObjectMapper shared] objectWithBlock:^id(Class objectClass, NSString *primaryKey, id primaryKeyValue, id JSON) {
                AppDelegate *app = [[UIApplication sharedApplication] delegate];
                NSManagedObjectContext *context = [app managedObjectContext];
                
                NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:@"Entity"
                                                                        inManagedObjectContext:context];
                
                return object;
            }];
        });
        
        it(@"should map core data special values", ^{
            id expectedBool = [NSNumber numberWithBool:YES];
            id expectedInt = [NSNumber numberWithInt:10];
            id expectedDouble = [NSNumber numberWithDouble:3.1f];
            id expectedFloat = [NSNumber numberWithFloat:3.4f];
            id expectedString = @"stringValue";
            
            NSDictionary *dict = @{
                @"bool" : expectedBool,
                @"int" : expectedInt,
                @"double" : expectedDouble,
                @"float" : expectedFloat,
                @"string" : expectedString
            };
            
            Entity *entity = [[BWObjectMapper shared] objectFromJSON:dict withObjectClass:[Entity class]];
            [[entity.boolValue should] equal:expectedBool];
            [[entity.intValue should] equal:expectedInt];
            [[entity.doubleValue should] equal:expectedDouble];
            [[entity.floatValue should] equal:expectedFloat];
            [[entity.stringValue should] equal:expectedString];
        });
        
    });
    
});

SPEC_END