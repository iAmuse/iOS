//
//  CTAppDelegate.h
//  Jurassic
//
//  Created by Roland Hordos on 2013-05-25.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AMCloudClient.h"

@class HTTPServer;
@class AMPrintKiosk;

@interface AMPrintAppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate>
{
    AMPrintKiosk *kiosk;
//    AMCloudClient *cloudClient;

    NSTimer *idleTimer;         // Get a feel for the user's attention.
    SEL idleTimerSelector;
    NSMethodSignature *idleTimerMethodSig;
    NSInvocation *idleTimerInvocation;
}

@property (strong, nonatomic) UIWindow *window;

// UIResponder messages
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;

- (void)resetIdleTimer;
- (void)appSettingsDidChange:(NSNotification*)notification;
- (void)userDidLeave;
- (void)didSenseUser:(NSNotification*)notification;

- (void)receivePresentError:(NSNotification*)notification;


- (void)test;

@end
