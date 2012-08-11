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
		[mapping mapKeyPath:@"created_at" toAttribute:@"createdAt"];                
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


## Installation

**Copy BWObjectMapper dir** into your **project**.

## ARC

BWObjectMapper is ARC only.

## Todo

- Handle relation (Has many, has one, …)

## Contact

Bruno Wernimont

- Twitter - [@brunowernimont](http://twitter.com/brunowernimont)