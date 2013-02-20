## BWObjectMapping

Small library that parse JSON and map it to any object, works with NSManagedObject.

## Example object interface

	@interface User : NSObject

	@property (nonatomic, strong) NSNumber *userID;
	@property (nonatomic, strong) NSString *firstName;
	@property (nonatomic, strong) NSDate *createdAt;

	@end

## Mapping

	[BWObjectMapping mappingForObject:[User class] block:^(BWObjectMapping *mapping) {
		[mapping mapPrimaryKeyAttribute:@"id" toAttribute:@"userID"];
		[mapping mapKeyPath:@"first_name" toAttribute:@"firstName"];
		[mapping mapAttributeFromArray:@[@"name"]];
		[mapping mapAttributeFromDictionary:@{@"created_at" : @"createdAt"}];    
      
		[[BWObjectMapper shared] registerMapping:mapping withRootKeyPath:@"user"];
	}];

At the last line we register the mapping and give a root key path. You don't need to have one, but if not the mapper will not be able to guess which mapping class to use.

## Object creation

	[[BWObjectMapper shared] objectWithBlock:^id(Class objectClass, NSString *primaryKey, id primaryKeyValue, id JSON) {
		return [[objectClass alloc] init];
	}];

## The json

	{
		"user": [{
			"id": 1,
			"first_name": "Bruno",
			"created_at": "2012-08-10T06:12:28Z"
		}]
	}

Default parsing date format is Rails format.

## Map json to object

	NSArray *objects = [[BWObjectMapper shared] objectsFromJSON:JSON];

Because the JSON contain a root key path, the mapping automatically discover.

## All mapping methods

	- (NSArray *)objectsFromJSON:(id)JSON withMapping:(BWObjectMapping *)mapping;

	- (NSArray *)objectsFromJSON:(id)JSON withObjectClass:(Class)objectClass;

	- (NSArray *)objectsFromJSON:(id)JSON;

	- (id)objectFromJSON:(id)JSON withMapping:(BWObjectMapping *)mapping;

	- (id)objectFromJSON:(id)JSON withMapping:(BWObjectMapping *)mapping existingObject:(id)object;

	- (id)objectFromJSON:(id)JSON withObjectClass:(Class)objectClass;

	- (id)objectFromJSON:(id)JSON withObjectClass:(Class)objectClass existingObject:(id)object;

	- (id)objectFromJSON:(id)JSON;

	- (id)objectFromJSON:(id)JSON existingObject:(id)object;

## Note about date format

If you don't use Rails date format you have two options:

1. Specify global date format

	[objectMapping mapKeyPath:@"created_at" toAttribute:@"createdAt" dateFormat:@""];

2. Custom date format on each attribute.

	[[BWObjectMapper shared] setDefaultDateFormat:@""];	

## Handling relation

Let's suppose you have a JSON like this:

```JSON

{
    "model": "HB20",
    "year": "2013",
    "engine": {
        "type": "v8"
    },
    "wheels": [
        {
            "id": "123123123",
            "type": "16"
        },
        {
            "id": "1234",
            "type": "17"
        }
    ]
}

```

* First define your models:

```objective-c

@interface Car : NSObject

@property (nonatomic, copy)   NSString *model;
@property (nonatomic, copy)   NSString *year;
@property (nonatomic, strong) Engine   *engine;
@property (nonatomic, strong) NSArray  *wheels;

@end

@interface Engine : NSObject

@property (nonatomic, copy) NSString *type;

@end

@interface Wheel : NSObject

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *size;

@end

```

* After this what you need to do is define their mappings in somewhere like this:

```objective-c

#import "MappingProvider.h"
#import "Car.h"
#import "Engine.h"
#import "Wheel.h"

@implementation MappingProvider

+ (BWObjectMapping *)carMapping
{
    return [BWObjectMapping mappingForObject:[Car class] block:^(BWObjectMapping *mapping) {
        [mapping mapAttributeFromArray:@[@"model", @"year"]];
        [mapping hasOneWithRelationMapping:[self engineMapping] fromKeyPath:@"engine"];
        [mapping hasManyWithRelationMapping:[self wheelMapping] fromKeyPath:@"wheels"];
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

```

* And to instanciate the root object you can do this:

```objective-c

Car *car = [[BWObjectMapper shared] objectFromJSON:carJSON withMapping:[MappingProvider carMapping]];
```

## Installation

**Copy BWObjectMapper dir** into your **project**.

Or with **Cocoapods**

	pod 'BWObjectMapper', :git => "https://github.com/brunow/BWObjectMapper.git", :tag => "0.2.0"

## ARC

BWObjectMapper is ARC only.

## Contact

Bruno Wernimont

- Twitter - [@brunowernimont](http://twitter.com/brunowernimont)
