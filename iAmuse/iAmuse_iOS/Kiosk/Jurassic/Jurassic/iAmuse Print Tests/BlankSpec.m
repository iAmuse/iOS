//
//  BlankSpec.m
//  Eventum
//
//  Created by Roland Hordos on 2014-06-17.
//  Copyright (c) 2014 Touchlytic Software Inc. All rights reserved.
//

#import "Kiwi.h"
#import "KiwiMacros.h"
#import <ReactiveCocoa/ReactiveCocoa/NSObject+RACPropertySubscribing.h>
#import <ReactiveCocoa/ReactiveCocoa/RACSubscriptingAssignmentTrampoline.h>
#import <ReactiveCocoa/ReactiveCocoa/RACDisposable.h>
#import <ReactiveCocoa/ReactiveCocoa/RACScheduler.h>
#import "RACSignal.h"
#import "RACSignal+Operations.h"

SPEC_BEGIN(BlankSpec)

describe(@"Large", ^{
    
    describe(@"Small", ^{
        
        beforeAll(^{    // occurs once
        });
        
        beforeEach(^{
        });
        
        it(@"does ..", ^{
            [[theValue(0) should] beNo];
        });
        
    });
});

SPEC_END