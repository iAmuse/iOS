//
// Created by Roland Hordos on 2013-07-01.
// Copyright (c) 2013 iAmuse Inc. All rights reserved.
//


#import <Foundation/Foundation.h>

#define IS_PHONE  UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone

@interface AMConstants : NSObject
    
    // Setup
    extern NSString* const kAMInstallationErrorDomain;
    extern NSInteger const kAMInstallationErrorBadBackground;
    extern NSString* const kAMReinstallWithReason;
    extern NSString* const kAMReinstallAlertTitle;
    extern NSString* const kAMCoreDataStoreFileName;
    
    // User Defaults
    extern NSString* const kAMUserEmailUserDefaultsKey;
    extern NSString* const kAMPasswordUserDefaultsKey;
    
    // Status
    extern NSString* const kAMDefaultErrorResolutionSuggestion;
    
    // Device
    extern NSString* const AMDeviceModeStrTouchScreen;
    extern NSString* const AMDeviceModeStrCamera;
    extern NSString* const AMDeviceModeSettingsKey;
    
    //Ratio
    
    extern NSString* const kAMImageRatioUserDefaultsKey;
    extern NSString* const AMRatioModeSettingsKey;
    extern NSString* const AMRatioModeStrAspectFit;
    extern NSString* const AMRatioModeStrAspectFill;
    extern NSString* const AMRatioModeStrScaleToFill;
    
    
    // Kiosk
    extern NSString* const kAMProductCode;
    extern uint const AMNumberOfPicturesPerSession;
    extern CGFloat const AMIdleFeelTimeoutDefault;
    extern NSString* const AMIdleFeelTimeoutKey;
    extern NSInteger const kAMPrintSelectRollPaceSecs;
    extern float const kAMPrintSelectRollDurationSecs;
    
    // Print Kiosk
    extern NSString* const kAMDisplayTimestampFormat;
    
    // Green Screen
    extern CGFloat const DEFAULT_SCREEN_WIDTH;
    extern NSString* const SCREEN_WIDTH_KEY;
    
    extern CGFloat const DEFAULT_SCREEN_HEIGHT;
    extern NSString* const SCREEN_HEIGHT_KEY;
    
    extern NSString* const FOV_CURTAIN_KEY_LEFT;
    extern CGFloat const DEFAULT_FOV_CURTAIN_PERCENT_LEFT;
    extern NSString* const FOV_CURTAIN_KEY_RIGHT;
    extern CGFloat const DEFAULT_FOV_CURTAIN_PERCENT_RIGHT;
    extern NSString* const FOV_CURTAIN_KEY_TOP;
    extern CGFloat const DEFAULT_FOV_CURTAIN_PERCENT_TOP;
    extern NSString* const FOV_CURTAIN_KEY_BOTTOM;
    extern CGFloat const DEFAULT_FOV_CURTAIN_PERCENT_BOTTOM;
    
    
    // Splash Screen
    extern int const SPLASH_FIRST_INSTRUCTION_SEQUENCE;
    extern int const SPLASH_LAST_INSTRUCTION_SEQUENCE;
    extern NSString* const SPLASH_INSTR1;
#define SPLASH_INSTR1_FONT [UIFont systemFontOfSize:80];
#define SPLASH_INSTR1_FONT_COLOR [UIColor cyanColor];
    extern NSString* const SPLASH_INSTR2;
#define SPLASH_INSTR2_FONT [UIFont systemFontOfSize:60];
#define SPLASH_INSTR2_FONT_COLOR [UIColor clearColor];
    
    // Camera
    extern CGFloat const DEFAULT_SCREEN_DISTANCE;
    extern NSString* const SCREEN_DISTANCE_KEY;
    extern NSString* const TARGET_DISTANCE_KEY;
    extern NSString* const CAMERA_IP_KEY;
    extern NSString* const TOUCHSCREEN_IP_KEY;
    extern NSString* const PRINT_KIOSK_IP_KEY;
    extern NSString* const DEFAULT_CAMERA_IP;
    extern NSString* const DEFAULT_TOUCHSCREEN_IP;
    
    // Selection Screen
    extern int const kAMSelectSceneCarouselImageWidth;
    extern int const kAMSelectPrintCarouselImageWidth;
    
    extern NSString* const kAMCameraCountdownStepIntervalKey;
    extern NSString* const kAMCameraShaderKey;
    extern NSString* const kAMCameraShaderDefault;
    extern NSString* const AMPhotoCurrentRenderVersion;
    extern NSTimeInterval const kAMCameraThankYouDurationSecs;
    
    // API
    extern const uint AMHttpCameraApiPort;
    extern const uint AMHttpTouchScreenApiPort;
    extern const uint AMHttpPrintKioskApiPort;
    extern const float AMCameraCountdownStepIntervalDefault;
    extern NSString* const AMHttpCameraApiDocRoot;
    extern NSString* const AMHttpPhotoStoreUriComponent;
    extern NSString* const AMRunTestNotification;
    extern NSString* const AMCameraResumePhotoSessionNotification;
    extern NSString* const AMCameraResetPhotoShootNotification;
    extern NSString* const AMCameraStopPhotoSessionNotification;
    extern NSString* const AMBackToEventNotification;
    extern NSString* const AMShowCameraNotification;
    extern NSString* const AMShowThankYouNotification;
    extern NSString* const AMRefreshDataNotification;
    extern NSString* const AMCameraNewCompositeFrameNotification;
    extern NSString* const AMCameraNewCameraRollPhotoNotification;
    extern NSString* const AMCameraNewDiskPhotoNotification;
    extern NSString* const AMCameraNewRemotePhotoNotification;
    extern NSString* const kAMNewPhotoObjectNotification;
    extern NSString* const kAMRefreshPrintContentNotification;
    extern NSString* const kAMJSONTimestampFormat;
    extern NSString* const AMGPUImageCameraNewCompositeFrameNotification;
    extern NSString* const AMSendScreenShotServerNotification ;
    extern NSString* const AMGetRGBConfigurationNotification ;
    extern NSString* const AMUpdatePendingImageCountNotification ;
    extern NSString* const AMEventConfigurationUpdateNotification ;
    
    // Workflow
    extern NSString* const AMDidSenseUser;
    extern NSString* const AMUserDidLeave;
    extern NSString* const AMWorkflowNormalCourse;
    extern NSString* const AMWorkflowGoBack;
    extern NSString* const AMWorkflowResetToSplash;
    extern NSString* const kAMDefaultPrinterId;
    
    
    // UI
    extern NSString * const kAMPresentErrorNotification;
    
    // Cloud
    extern NSString * const KIOSK_CLOUD_SERVICE_URL;
    extern NSString * AMCloudServiceBase;
    extern NSString * AMCloudServiceSecureBase;
    extern NSString * AMCloudServiceAuthURL;
    extern NSString * AMCloudServiceRestURIPing;
    extern NSString * AMCloudServiceRestURIActivate;
    extern NSString * const AMAuthenticationRequiredNotification;
    extern NSString * const AMAuthenticationResultNotification;
    extern NSString * const AMAuthenticationAuthenticated;
    
    // Print Kiosk
    extern NSString * const kAMImageFileNameNothingToPrint;
    extern NSString * const kAMPrintKioskLockPIN;
    
    //NewServerAPI
    extern NSString * const baseurl;
    extern NSString * const kAMBaseURL;
    extern NSString * const kAMGetConfigurationURL;
    extern NSString * const kAMSendScreenShotURL;
    extern NSString * const kAMDeviceTokenURL;
    extern NSString * const kAMImageWithEmailUploadURL ;
    extern NSString * const kAMDeviceToken ;
    extern NSString * const kAMOldDeviceToken ;
    
    extern NSString * const SERVER_RGB_CONFIGURATION;
    extern NSString * const HAVE_SERVER_RGB_CONFIGURATION;
    extern NSString * const PENDING_SCREENSHOT_REQUEST;
    extern NSString * const PENDING_CONFIGUARTION_REQUEST;
    extern NSString * const DEVICE_TOKEN_SENT ;
    
    @end

