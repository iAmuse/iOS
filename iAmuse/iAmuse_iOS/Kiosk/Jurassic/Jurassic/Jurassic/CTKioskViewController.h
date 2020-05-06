//
//  CTKioskViewController.h
//  Jurassic
//
//  Used by the camera as it's interim controller when it's not busy capturing and processing video.
//
//  Created by Roland Hordos on 2013-05-25.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "CTCameraViewController.h"
#import "CTSettingsViewController.h"

@class CTCameraViewController;

@interface CTKioskViewController : UIViewController < CameraSessionDelegate,
 SettingsViewCompleteDelegate, GLKViewControllerDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate >
{
    BOOL showing;
    BOOL haveToLoadRGBFromServer;
    
    CTCameraViewController * cameraVC;
    UIImageView * introTouchLayer; // Used for touch detection and introduction graphic.

    UIDeviceOrientation deviceOrientation;
    UIInterfaceOrientation interfaceOrientation;

    __weak IBOutlet UIImageView * settingsGear;
    __weak IBOutlet UIImageView *backgroundImage;

    NSTimer * thankYouCountdownTimer; // Countdown timer for thank you message.
    SEL thankYouCountdownTimerSelector;
    NSMethodSignature * thankYouCountdownTimerMethodSig;
    NSInvocation * thankYouCountdownTimerInvocation;
    int thankYouCountdownSequence;
    NSTimeInterval thankYouCountdownInterval;
    
    UILabel * lblThankYou;
    IBOutlet UIView * viewAbovefaddedView;
    
    CGFloat textFieldValue;
  
}

@property (weak, nonatomic) IBOutlet UIButton *settingButton;
@property (strong, nonatomic) NSArray * colorRGBInfo;
@property (weak, nonatomic) IBOutlet UIButton *clearButton;
@property (strong, nonatomic) NSString *lockPIN;
@property (assign, nonatomic) BOOL isTestingCamera;


- (void)showCamera;
- (void)showThankYou;
- (void)thankYouCountdownTimerTick;
- (void)screenDoubleTap:(UITapGestureRecognizer *)gesture;
- (IBAction)clearPhotos:(id)sender;
- (IBAction)showSettings:(id)sender;

@end

