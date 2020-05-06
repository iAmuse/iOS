//
//  ViewController.h
//  iAmuseTest
//
//  Created by IPHONE-02 on 1/13/15.
//  Copyright (c) 2015 Himanshu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CTKiosk.h"
#import "GPUImage.h"
#import "CTSettingsViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "AMStorageManager.h"
#import <QuartzCore/QuartzCore.h>


#define TOCROPVIEW_BACKGROUND_COLOR [UIColor colorWithWhite:0.12f alpha:1.0f]


/* When the user taps down to resize the box, this state is used
 to determine where they tapped and how to manipulate the box */
typedef NS_ENUM(NSInteger, TOCropViewOverlayEdge) {
    TOCropViewOverlayEdgeNone,
    TOCropViewOverlayEdgeTopLeft,
    TOCropViewOverlayEdgeTop,
    TOCropViewOverlayEdgeTopRight,
    TOCropViewOverlayEdgeRight,
    TOCropViewOverlayEdgeBottomRight,
    TOCropViewOverlayEdgeBottom,
    TOCropViewOverlayEdgeBottomLeft,
    TOCropViewOverlayEdgeLeft
};


@interface ViewController : UIViewController<UIGestureRecognizerDelegate,SettingsViewCompleteDelegate,GPUImageVideoCameraDelegate,CLLocationManagerDelegate>
    {
        
        
        GPUImageOutput<GPUImageInput> * filter;
        GPUImageStillCamera * stillCamera;
        // Per-frame execution variables that need occasional exposure as properties.
        // Somewhat out of place, presently it's this controller that is hit every frame.
        int shotsRemaining;
        int countdownSequence;
        NSTimeInterval countdownInterval;
        NSTimer * countdownTimer;
        SEL countdownTimerSelector;
        NSMethodSignature * countdownTimerMethodSig;
        NSInvocation * countdownTimerInvocation;
        
        UITapGestureRecognizer * tap;
        
        CTKiosk * kiosk;
        
//        __weak IBOutlet UIButton *settingsBtn;
        float currentScale;
        float currentXOffset;
        float currentYOffset;
        UIDeviceOrientation deviceOrientation;
        UIInterfaceOrientation interfaceOrientation;
        
         NSTimer *idleTimer;
        
        BOOL recordNextCompositeFrame;
        
        ALAssetsLibrary * assetsLibrary;
        CLLocationManager * gps;
        AMStorageManager * store;
        UIImage * imageToBeStored;
        UILabel * lblInstruction;
        
        __weak IBOutlet UIImageView * faddedImage;
        __weak IBOutlet UIButton *cameraBtn;
        __weak IBOutlet UIButton *doneBtn;
        
        
        CGPoint _originalCenter;
        CGPoint _originalCenterL;
        CGRect _originalRectL;
        CGRect _originalRect;
        
        // Live camera
        
        NSString *selectedMediaForLive;
        
        BOOL _addedObservers;
        BOOL _recording;
        UIBackgroundTaskIdentifier _backgroundRecordingID;
        BOOL _allowedToUseGPU;
        
        NSTimer *_labelTimer;
        
    }
- (IBAction)hideCameraAction:(id)sender;
    
    @property NSDictionary * gpsInfo;
    @property (atomic) CFMutableDictionaryRef recentCompositeFrameInfo;
    
    @property (nonatomic, assign) BOOL isTestingCamera;
    @property (strong, nonatomic) UIImage * foregroundImage;
    
    @property (strong, nonatomic) IBOutlet UIView * cameraView;
    @property (strong, nonatomic) IBOutlet UIView * mainCameraView;
    @property (strong, nonatomic) IBOutlet UIImageView * bgImage;
    @property (strong, nonatomic) IBOutlet UIImageView * tempBg;
    @property (weak, nonatomic) IBOutlet UIImageView *croppedBgFrame;
    @property (weak, nonatomic) IBOutlet UIView *baseView;
@property (weak, nonatomic) IBOutlet UIButton *settingsBtn;
- (IBAction)settingsBtnAction:(id)sender;


    //@property (nonatomic, strong) GPUImageVideoCamera * videoCamera;
    @property (nonatomic, strong) GPUImageStillCamera * stillCamera;
    @property (nonatomic, strong) GPUImagePicture * sourcePicture;
- (IBAction)changeCameraMode:(UIButton *)sender;
    
    @property (nonatomic) CGFloat thresholdValue;
    @property (weak, nonatomic) IBOutlet UIImageView *waterMarkImageView;
@property (weak, nonatomic) IBOutlet UIView *cropView;
@property (strong, nonatomic) IBOutlet UIScrollView *viewVideoL;
@property (strong, nonatomic) IBOutlet UIScrollView *viewVideo;
@property (strong, nonatomic) IBOutlet UIView *viewTop;
@property (strong, nonatomic) IBOutlet UIView *viewTopL;
@property (strong, nonatomic) IBOutlet UIView *viewCropL;
@property (strong, nonatomic) IBOutlet UIView *viewPortrait;
@property (strong, nonatomic) IBOutlet UIButton *btnFitToScreen;
- (IBAction)fitTOScreenPressed:(id)sender;

@property (strong, nonatomic) IBOutlet UILabel *lblResize;

    @end

