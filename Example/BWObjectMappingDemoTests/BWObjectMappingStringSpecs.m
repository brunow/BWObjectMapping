#import <Kiwi/Kiwi.h>
#import "NSString+BWObjectMapping.h"

SPEC_BEGIN(BWObjectMappingStringSpecs)

describe(@"BWObjectMappingStringSpecs", ^{
    
    it(@"should capitalize first letter of first word", ^{
        id expected = @"StringByCapitalizingFirstLetter";
        id value = [(NSString *)@"stringByCapitalizingFirstLetter" BWO_stringByCapitalizingFirstLetter];
        [[value should] equal:expected];
    });
    
    it(@"should camelize string", ^{
        id expected = @"myVar";
        id value = [@"my_var" BWO_stringByCamelizingString];
        [[value should] equal:expected];
    });
    
    it(@"should make underscored string", ^{
        id expected = @"first_letter";
        id value = [@"firstLetter" BWO_stringByUnderscoringWord];
        [[value should] equal:expected];
    });
    
});

SPEC_END