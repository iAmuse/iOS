//
//  CTKiosk.h
//  SmartPhoto Camera
//
//  Created by Roland Hordos on 2013-05-06.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//
//  

#import "CTScreen.h"
#import "CTCamera.h"
#import "HTTPServer.h"
#import "CTPhotoSession.h"
#import "Photo.h"
#import "MBProgressHUD.h"

@protocol SendImagesToServerProtocol <NSObject>

- (void)imagesSendingSuccessfull;
- (void)imagesSendingNotSucessfull;

@end

@class CTScreen;
@class CTCamera;
@class Kiosk;
@class PhotoLayout;

//
// Device Modes
//
typedef NS_ENUM(NSInteger, CTKioskDeviceMode) {
    CTKioskDeviceModeCamera,
    CTKioskDeviceModeTouchScreen,
};

@interface CTKiosk : NSObject < UIPrintInteractionControllerDelegate >
{

//    @private NSObject *_projectId;
//	@private NSObject *_installationId;
//	@private NSObject *_openTime;
//	@private NSObject *_closeTime;
//	@private NSObject *_timezone;

    Kiosk * entity;                      // Core Data
    CTKioskDeviceMode deviceMode;       // Touchscreen | Camera
//    float *idleFeelingTimeoutMins;

    CTScreen * physicalBackgroundScreen;

    // Camera and Photo
	CTCamera * camera;
//    NSMutableArray *photoLayouts;
    CTPhotoSession * currentPhotoSession;

    // Networking
    HTTPServer * httpServer;
    uint httpServerPort;
    NSURL * networkCameraBaseURL;
    NSURL * networkTouchScreenBaseURL;
    NSURL * networkPrintKioskBaseURL;
    
    NSMutableArray * pendingPhotosUrls;
    UIAlertView * alert_forIP;
    MBProgressHUD *hud;
    NSTimer *timer;
    
}

@property (nonatomic,assign) BOOL isUploadingPendingPhotos;

@property (nonatomic) NSInteger autoConfigureCount;
@property (nonatomic, strong) NSDate *startingTimeStamp;
@property (nonatomic) Kiosk *entity;
@property (nonatomic,strong) NSString *eventId;
@property (nonatomic,assign) BOOL isSubscribed;

@property (nonatomic,assign) BOOL isPhone;

@property (nonatomic,assign) BOOL isName;

@property (nonatomic, readonly) CTKioskDeviceMode deviceMode;
@property (nonatomic) float idleFeelingTimeoutMins;

@property (nonatomic, readonly) BOOL deviceIdiomIsPhone;
@property NSString * productCode;
@property (nonatomic) NSString *storePath;

@property CTCamera * camera;
@property (nonatomic, strong) NSMutableArray * photoLayouts;
@property (nonatomic, strong) NSMutableArray * photos;
@property (nonatomic, assign) BOOL isGetConnectionDeviceAddress;
@property (nonatomic) PhotoLayout * currentPhotoLayout;
@property (nonatomic) CTPhotoSession * currentPhotoSession;

@property BOOL hasExternalCameraDisplay;

@property (nonatomic, weak) id <SendImagesToServerProtocol> delegate;

+ (id)sharedInstance;

//-(id) init;

- (void)startup:(NSString *)eventId;
- (void)pause;
- (void)resume;
- (void)shutdown;
- (BOOL)startServer;
- (void)userHeartbeat;
- (void)startTimer;
-(void)loadPersistentSettings:(BOOL)showAlert;
- (NSString *)photoStoreDirectory;

- (UIUserInterfaceIdiom)deviceType; // Results of UI_USER_INTERFACE_IDIOM

- (PhotoLayout *)getPhotoLayoutAtIndex:(NSInteger)index;

- (CTPhotoSession *)startPhotoSession:(PhotoLayout *)selectedPhotoLayout
                    selectedSessionId:(NSString *)sessionId;

- (void)pausePhotoSession;

- (void)newCameraRollPhoto:(NSNotification *)notification;

- (void)selectPhoto:(Photo *)photo;
- (void)saveSelectedPhotos:(NSMutableArray *)photos;
- (void)setEmailAddress:(NSString *)emailAddress;
- (void)setName:(NSString *)name;
- (void)setNumber:(NSString *)number;

- (void)emailPhoto;
- (void)print:(UIViewController *)viewController dialogFocus:(UIButton *)dialogFocus;
- (UIImage *)printPreview:(UIViewController *)viewController dialogFocus:(UIButton *)dialogFocus;

- (void)sharePhotoPubliclyOfAge:(BOOL)okayToShare;
- (void)chooseNewsletter:(BOOL)value;

- (void)networkCameraThankYou;
- (void)removeLookAtiPadScreen;
- (void)selectedPhotoFromReviewPicture:(Photo *)selectedPhoto;
- (void)autoConfigureCameraAndTouchDevice;
- (NSString *)getIPAddressofDevice;
- (void)registerDeviceOnServer;
- (void)backToEventScene;
- (void)backToThankYou;
- (void)subscriptionUpdate;

//
//  Return a list of photos selected by users today, as the list of eligible
//  photos for printing.
//
- (void)handlePendingImageUploadingRequest;

- (NSArray *)getPrintablePhotosMetaData;
- (void)loadPhotoLayouts:(NSString *)eventId;
- (void)checkPendingImageForUploading:(BOOL)isUploadPending;
@end
