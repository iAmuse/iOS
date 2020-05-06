//
//  Kiosk.h
//  SmartPhoto Camera
//
//  Created by Roland Hordos on 2013-05-06.
//  Copyright (c) 2013 Tandroid. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "CTKiosk.h"

@interface NHViewController : GLKViewController {

    int countdownSequence;
    NSTimeInterval countdownInterval;
    NSTimer *countdownTimer;
    SEL countdownTimerSelector;
    NSMethodSignature *countdownTimerMethodSig;
    NSInvocation *countdownTimerInvocation;

    IBOutlet UILabel *lblTestCmp;
    
    CTKiosk *kiosk;
}

@property (retain, nonatomic) UILabel *lblTestCmp;

- (void)doUpdateTimer;

@end

