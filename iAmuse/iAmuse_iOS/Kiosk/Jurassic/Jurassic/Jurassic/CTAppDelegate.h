//
//  CTAppDelegate.h
//  Jurassic
//
//  Created by Roland Hordos on 2013-05-25.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CTKiosk.h"
#import "AMCloudClient.h"

@import Firebase;
@import GoogleSignIn;


@class HTTPServer;

@interface CTAppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate,GIDSignInDelegate>
{
    CTKiosk *kiosk;             // Master object, highest level that assembles the entire Kiosk application.

    AMCloudClient *cloudClient;
    SEL idleTimerSelector;
    NSMethodSignature *idleTimerMethodSig;
    NSInvocation *idleTimerInvocation;
   
   
}
@property (retain,nonatomic) NSString *globalVariable;
@property (retain,nonatomic) NSString *userId;
@property (retain,nonatomic) NSString *fullName;
@property (retain,nonatomic) NSString *email;
@property (strong, nonatomic) NSTimer *idleTimer; // Get a feel for the user's attention.
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UIImage *img;
@property(nonatomic,retain) NSMutableArray *sharedArray;
@property(nonatomic, assign) int globalIndexValue;

// UIResponder messages
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;

- (void)resetIdleTimer;
- (void) appSettingsDidChange:(NSNotification*)notification;
- (void)userDidLeave;
- (void)showThankYou:(NSNotification*)notification;
- (void) didSenseUser:(NSNotification*)notification;

- (void)receivePresentError:(NSNotification*)notification;

- (void)setInitialViewCtr;

@end
