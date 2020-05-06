//
//  CTCameraViewController.h
//  Jurassic
//
//  Created by Roland Hordos on 2013-05-25.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "CTKiosk.h"
#import "CTSettingsViewController.h"
#import <OpenGLES/ES2/glext.h>


@protocol CameraSessionDelegate;

@interface CTCameraViewController : GLKViewController <SettingsViewCompleteDelegate,
                                                       UIGestureRecognizerDelegate>
{

    int shotsRemaining;
    int countdownSequence;
    NSTimeInterval countdownInterval;
    NSTimer *countdownTimer;
    SEL countdownTimerSelector;
    NSMethodSignature *countdownTimerMethodSig;
    NSInvocation *countdownTimerInvocation;

    UITapGestureRecognizer *tap;
    IBOutlet UILabel *lblInstruction;

    CTKiosk *kiosk;

    // Per-frame execution variables that need occasional exposure as properties.
    // Somewhat out of place, presently it's this controller that is hit every frame.
    float currentScale;
    float currentXOffset;
    float currentYOffset;
}

@property (retain, nonatomic) UILabel *lblTestCmp;

- (void)resetPhotoShoot:(NSNotification *)notification;
- (void)newPhotoDidStore:(NSNotification *)notification;
- (void)receiveStopPhotoSession:(NSNotification *)notification;
- (void)doUpdateTimer;
- (void)screenTap:(UITapGestureRecognizer *)gesture;

@end


@protocol CameraSessionDelegate <NSObject>
@required
- (void)cameraViewController:(CTCameraViewController *)cameraViewController didFinishSession:(CTPhotoSession *)session;
@end

