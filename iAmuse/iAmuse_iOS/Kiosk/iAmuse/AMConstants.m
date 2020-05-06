//
// Created by Roland Hordos on 2013-07-01.
// Copyright (c) 2013 iAmuse Inc. All rights reserved.
//


#import "AMConstants.h"


@implementation AMConstants
    
    // Setup
    NSString* const kAMInstallationErrorDomain = @"kAMInstallationErrorDomain";
    NSInteger const kAMInstallationErrorBadBackground = 1;
    NSString* const kAMReinstallWithReason = @"kAMReinstallWithReason";
    NSString* const kAMReinstallAlertTitle = @"Sorry, Please Reinstall";
    NSString* const kAMCoreDataStoreFileName = @"iamuse";
    
    // User Defaults
    NSString* const kAMUserEmailUserDefaultsKey = @"User E-Mail";
    NSString* const kAMPasswordUserDefaultsKey = @"Password";
    
    // Status
    NSString* const kAMDefaultErrorResolutionSuggestion = @"Please report this at the iAmuse website with description and/or screenshot.";
    
    // Device
    NSString* const AMDeviceModeStrTouchScreen = @"Touch Screen";
    NSString* const AMDeviceModeStrCamera = @"Camera";
    NSString* const AMDeviceModeSettingsKey = @"Device Mode";
    
    //Ratio
    NSString* const kAMImageRatioUserDefaultsKey = @"Ratio";
    NSString* const AMRatioModeSettingsKey = @" Image Ratio";
    NSString* const AMRatioModeStrAspectFit = @"Aspect Fit";
    NSString* const AMRatioModeStrAspectFill = @"Aspect Fill";
    NSString* const AMRatioModeStrScaleToFill = @"Scale to Fill";
    
    
    // Kiosk
    //NSString* const kAMProductCode = @"Jurassic GreenScreen";
#ifdef JURASSIC
    NSString* const kAMProductCode = @"GreenScreen Kiosk";
#else
    NSString* const kAMProductCode = @"iAmuse Green Screen";
#endif
    
    // Print Kiosk
    
    uint const AMNumberOfPicturesPerSession = 3;
    CGFloat const AMIdleFeelTimeoutDefault = 2.0f; // in minutes
    NSString* const AMIdleFeelTimeoutKey = @"Interaction Timeout";
    NSInteger const kAMPrintSelectRollPaceSecs = 6;
    float const kAMPrintSelectRollDurationSecs = 4;
    
    
    
    
    // Green Screen
    CGFloat const DEFAULT_SCREEN_WIDTH = 1.5f;
    NSString* const SCREEN_WIDTH_KEY = @"Screen Width";
    CGFloat const DEFAULT_SCREEN_HEIGHT = 2.1f;
    NSString* const SCREEN_HEIGHT_KEY = @"Screen Height";
    
    NSString* const FOV_CURTAIN_KEY_LEFT = @"FOV Left Curtain";
#ifdef JURASSIC
    CGFloat const DEFAULT_FOV_CURTAIN_PERCENT_LEFT = 24.0f;
    CGFloat const DEFAULT_FOV_CURTAIN_PERCENT_RIGHT = 28.0f;
    CGFloat const DEFAULT_FOV_CURTAIN_PERCENT_TOP = 1.0f;
    CGFloat const DEFAULT_FOV_CURTAIN_PERCENT_BOTTOM = 1.0f;
#else
    
    CGFloat const DEFAULT_FOV_CURTAIN_PERCENT_LEFT = 33.0f;
    CGFloat const DEFAULT_FOV_CURTAIN_PERCENT_RIGHT = 30.0f;
    CGFloat const DEFAULT_FOV_CURTAIN_PERCENT_TOP = 6.0f;
    CGFloat const DEFAULT_FOV_CURTAIN_PERCENT_BOTTOM = 0.1f;
    
#endif
    NSString* const FOV_CURTAIN_KEY_RIGHT = @"FOV Right Curtain";
    NSString* const FOV_CURTAIN_KEY_TOP = @"FOV Top Curtain";
    NSString* const FOV_CURTAIN_KEY_BOTTOM = @"FOV Bottom Curtain";
    
    
    // Splash Screen
    int const SPLASH_FIRST_INSTRUCTION_SEQUENCE = 1;
    int const SPLASH_LAST_INSTRUCTION_SEQUENCE = 2;
    NSString* const SPLASH_INSTR1 = @"Take Your Picture with a Dinosaur .. NOW";
    //int const INSTR1_FONT_SIZE = 60;
    NSString* const SPLASH_INSTR2 = @"Touch to Start";
    //int const INSTR2_FONT_SIZE = 80;
    
    // Camera
    CGFloat const DEFAULT_SCREEN_DISTANCE = 2.3f;
    NSString * const SCREEN_DISTANCE_KEY = @"Screen Distance";
    NSString * const TARGET_DISTANCE_KEY = @"Target Distance";
    NSString * const CAMERA_IP_KEY       = @"Camera Address";
    NSString * const TOUCHSCREEN_IP_KEY  = @"Touch Panel Address";
    NSString * const PRINT_KIOSK_IP_KEY  = @"Print Kiosk Address";
    
#ifdef JURASSIC
    //IP of iPhone device on which we run iAmuse
    NSString * const DEFAULT_CAMERA_IP = @"";
    //IP of iPad device on which we run iAmusePrint
    NSString * const DEFAULT_TOUCHSCREEN_IP = @"";
#else
    //IP of iPhone device on which we run iAmuse
    NSString * const DEFAULT_CAMERA_IP = @"";
    //IP of iPad device on which we run iAmuse
    NSString * const DEFAULT_TOUCHSCREEN_IP = @"";
#endif
    
    
    //#ifdef JURASSIC
    ////IP of iPhone device on which we run iAmuse
    //NSString * const DEFAULT_CAMERA_IP = @"192.168.1.250";
    ////IP of iPad device on which we run iAmusePrint
    //NSString * const DEFAULT_TOUCHSCREEN_IP = @"192.168.1.239";
    //#else
    ////IP of iPhone device on which we run iAmuse
    //NSString * const DEFAULT_CAMERA_IP = @"192.168.1.250";
    ////IP of iPad device on which we run iAmuse
    //NSString * const DEFAULT_TOUCHSCREEN_IP = @"192.168.1.217";
    //#endif
    
    
    //#ifdef JURASSIC
    //NSString* const DEFAULT_CAMERA_IP = @"192.168.15.7";
    //NSString* const DEFAULT_TOUCHSCREEN_IP = @"192.168.15.4";
    //#else
    //NSString* const DEFAULT_CAMERA_IP = @"192.168.1.100";
    //NSString* const DEFAULT_TOUCHSCREEN_IP = @"192.168.1.101";
    //#endif
    
    
    //// Cloud
    //#ifdef DEBUG
    //    NSString* const KIOSK_CLOUD_SERVICE_URL = @"http://localhost:8080";
    //#else
    //    NSString* const KIOSK_CLOUD_SERVICE_URL = @"https://iamuse-kiosk.appspot.com";
    //#endif
    //
    //#ifdef DEBUG
    //    NSString *AMCloudServiceBase = @"http://localhost:8080";
    //    NSString *AMCloudServiceSecureBase = @"http://localhost:8080";
    //    NSString *AMCloudServiceAuthURL = @"http://localhost:8080/auth/jsonpassword";
    //#else
    
    // Selection Screen
    int const kAMSelectSceneCarouselImageWidth = 700;
    //int const kAMSelectSceneCarouselImageWidth = 400;
    int const kAMSelectPrintCarouselImageWidth = 550;
    //int const kAMSelectPrintCarouselImageWidth = 450;
    NSString* const kAMDisplayTimestampFormat = @"MMM d  h:mm a";
    
    NSString* const kAMCameraCountdownStepIntervalKey = @"Countdown Delay";
    NSString* const kAMCameraShaderKey = @"Shader";
    NSString* const kAMCameraShaderDefault = @"white50step80power4";
    NSTimeInterval const kAMCameraThankYouDurationSecs = 8; //15
    
    // API
    uint const AMHttpCameraApiPort = 8079;
    uint const AMHttpTouchScreenApiPort = 8078;
    uint const AMHttpPrintKioskApiPort = 8078;
    float const AMCameraCountdownStepIntervalDefault = 1.0;
    NSString* const AMHttpCameraApiDocRoot = @"www";
    NSString* const AMHttpPhotoStoreUriComponent = @"Photos";
    NSString* const AMPhotoCurrentRenderVersion = @"d1c1";
    NSString* const AMRunTestNotification = @"AMRunTest";
    NSString* const AMCameraResumePhotoSessionNotification = @"AMCameraResumePhotoSession";
    NSString* const AMCameraResetPhotoShootNotification = @"AMCameraResetPhotoShoot";
    NSString* const AMCameraStopPhotoSessionNotification = @"AMCameraPausePhotoSession";
    NSString* const AMBackToEventNotification = @"AMBackToEventNotification";
    NSString* const AMShowCameraNotification = @"AMShowCamera";
    NSString* const AMShowThankYouNotification = @"AMShowThankYou";
    NSString* const AMRefreshDataNotification = @"AMRefreshDataNotification";
    NSString* const AMCameraNewCompositeFrameNotification = @"AMCameraNewCompositeFrame";
    NSString* const AMCameraNewCameraRollPhotoNotification = @"AMCameraNewCameraRollPhoto";
    NSString* const AMCameraNewDiskPhotoNotification = @"AMCameraNewDiskPhoto";
    NSString* const AMCameraNewRemotePhotoNotification = @"AMCameraNewRemotePhoto";
    NSString* const kAMNewPhotoObjectNotification = @"kAMNewPhotoObjectNotification";
    NSString* const kAMRefreshPrintContentNotification = @"kAMRefreshPrintContentNotification";
    NSString* const kAMJSONTimestampFormat = @"yyyy'-'MM'-'dd' 'HH':'mm':'ss"; // 2014-06-20 19:00:00
    
    //Added by Himanshu
    NSString* const AMGPUImageCameraNewCompositeFrameNotification = @"AMGPUImageCameraNewCompositeFrame";
    NSString* const AMSendScreenShotServerNotification = @"sendScreenShotToServerNotification";
    NSString* const AMGetRGBConfigurationNotification = @"getRGBFromServerNotification";
    NSString* const AMUpdatePendingImageCountNotification = @"UpdatePendingImageCountNotification";
    NSString* const AMEventConfigurationUpdateNotification = @"EventConfigurationUpdateNotification";
    
    
    
    // Workflow
    NSString* const AMDidSenseUser = @"AMDidSenseUser";
    NSString* const AMUserDidLeave = @"AMUserDidLeave";
    NSString* const AMWorkflowNormalCourse = @"Forward";
    NSString* const AMWorkflowGoBack = @"Back";
    NSString* const AMWorkflowResetToSplash = @"Splash";
    NSString* const kAMDefaultPrinterId = @"DefaulPrinter";
    
    // UI
    NSString* const kAMPresentErrorNotification = @"kAMPresentErrorNotification";
    
    
    NSString *AMCloudServiceBase = @"http://iamuse-kiosk.appspot.com";
    NSString *AMCloudServiceSecureBase = @"https://iamuse-kiosk.appspot.com";
    NSString *AMCloudServiceAuthURL = @"https://iamuse-kiosk.appspot.com/auth/jsonpassword";
    //#endif
    NSString *AMCloudServiceRestURIPing = @"ping";
    NSString *AMCloudServiceRestURIActivate = @"activate";
    
    NSString* const AMAuthenticationResultNotification =
    @"AMAuthenticationResultNotification";
    NSString* const AMAuthenticationRequiredNotification =
    @"AMAuthenticationRequiredNotification";
    NSString* const AMAuthenticationAuthenticated = @"Authenticated";
    NSString* const AMAuthenticationRequired = @"Required";
    
    // Print Kiosk
    NSString* const kAMImageFileNameNothingToPrint = @"nothing_to_print.png";
    NSString* const kAMPrintKioskLockPIN = @"2356";
    
    //LiveURL_Dev2Server
    
    //NSString* const kAMBaseURL = @"http://project.rapidsoft.in:8080/iamuseserver_new/v1/iamuse/";
    //NSString* const kAMBaseURL = @"http://iamuse.rapidsoft.in:8080/iamuseserver/v1/iamuse/";
    
    //TestURL_LocalServer
    //NSString* const kAMBaseURL = @"http://192.168.1.31:8080/iamuseserver_internal//v1/iamuse/";
    
 //   NSString* const kAMBaseURL = @"http://admin.iamuse.com/iamuseserver_internal/v1/iamuse/";       //main server

//NSString* const kAMBaseURL = @"http://stark.eastus.cloudapp.azure.com:8000/iamuseserver_internal/v1/iamuse/";  //local server

//NSString* const kAMBaseURL = @"http://192.168.2.33:8000/iamuseserver_internal/v1/iamuse/";    //testing server

NSString* const kAMBaseURL = @"http://star-k.eastus.cloudapp.azure.com:8000/iamuseserver_internal/v1/iamuse/";//new server


//NSString* const kAMBaseURL = @"http://192.168.2.14:8080/iamuseserver_internal/v1/iamuse/";

//NSString* const kAMBaseURL = @"http://iamuses.eastus.cloudapp.azure.com:8080/iamuseserver_internal/v1/iamuse/";

//NSString* const kAMBaseURL = @"http://192.168.2.33:8000/IAmuse/iamuseserver_internal/v1/iamuse/";

    //NSString* const kAMBaseURL = @"http://project.rapidsoft.in:8080/iamuseserver_internal/v1/iamuse/";
    
    
    //NSString* const baseurl  =   @"http://project.rapidsoft.in:8080";
    //NSString* const baseurl   =  @"http://192.168.1.31:8080";
//    NSString* const baseurl  =   @"http://admin.iamuse.com";        //main server

// NSString* const baseurl  =   @"http://stark.eastus.cloudapp.azure.com:8000/IAmuse/";//local server

// NSString* const baseurl  =   @"http://192.168.2.33:8000/";

 NSString* const baseurl  =   @"http://star-k.eastus.cloudapp.azure.com:8000/IAmuse/";  //new server

//NSString* const baseurl  =   @"http://iamuses.eastus.cloudapp.azure.com:8080/IAmuse/";//Production server

//NSString* const baseurl  =   @"http://192.168.2.33:8000/IAmuse/";

//NSString* const baseurl  =   @"http://192.168.2.14:8080/iamuse/";



    NSString* const kAMGetConfigurationURL = @"firstTimeRGBConfiguration";
    NSString* const kAMSendScreenShotURL = @"imageupload";
    NSString* const kAMDeviceTokenURL = @"saveDeviceToken";
    NSString* const kAMImageWithEmailUploadURL = @"imageuploadWithEmailId";
    NSString* const kAMDeviceToken = @"deviceToken";
    NSString* const kAMOldDeviceToken = @"oldDeviceToken";
    
    NSString* const SERVER_RGB_CONFIGURATION = @"serverRGBConfiguration";
    NSString* const HAVE_SERVER_RGB_CONFIGURATION = @"haveServerRGBConfiguration";
    NSString* const PENDING_SCREENSHOT_REQUEST = @"pendingScreenshotReq";
    NSString* const PENDING_CONFIGUARTION_REQUEST = @"pendingConfiguartionReq";
    NSString* const DEVICE_TOKEN_SENT = @"tokenSentToServer";
    
    
    @end

