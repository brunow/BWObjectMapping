//
//  BWObjectMappingSpec.m
//  BWObjectMappingDemo
//
//  Created by Lucas Medeiros on 19/02/13.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import "BWObjectMapping.h"
#import "MappingProvider.h"
#import "Kiwi.h"


SPEC_BEGIN(BWObjectMappingSpec)

describe(@"BWObjectMapping", ^{
   
    describe(@"#hasOneWithRelationMapping:forKeyPath:", ^{
        
        __block BWObjectMapping *mapping;
        
        beforeEach(^{
            mapping = [MappingProvider carMapping];
        });
        
        specify(^{
            [[mapping should] respondToSelector:@selector(hasOneWithRelationMapping:forKeyPath:)];
        });
        
        specify(^{
            [[mapping should] respondToSelector:@selector(hasOneMappings)];
        });
        
        specify(^{
            [[mapping.hasOneMappings should] beNonNil];
        });
        
    });
    
    describe(@"#hasManyWithRelationMapping:forKeyPath", ^{
        
        __block BWObjectMapping *mapping;
        
        beforeEach(^{
            mapping = [MappingProvider carMapping];
        });
        
        specify(^{
            [[mapping should] respondToSelector:@selector(hasManyWithRelationMapping:forKeyPath:)];
        });
        
        specify(^{
            [[mapping should] respondToSelector:@selector(hasManyMappings)];
        });
        
        specify(^{
            [[mapping.hasManyMappings should] beNonNil];
        });
        
    });
    
});

SPEC_END


