//
//  AMPrintKiosk.h
//  iAmuse
//
//  Created by Roland Hordos on 2014-06-30.
//  Copyright (c) 2014 iAmuse Inc. All rights reserved.
//

#import "CTScreen.h"
#import "CTCamera.h"
#import "HTTPServer.h"
#import "CTPhotoSession.h"

@class CTScreen;
@class CTCamera;
@class Kiosk;
@class PhotoLayout;

@interface AMPrintKiosk : NSObject <UIPrintInteractionControllerDelegate> {
    HTTPServer *httpServer;
    uint httpServerPort;
    NSURL *networkTouchScreenBaseURL;
}

@property (nonatomic, strong) Kiosk *entity;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) UIImage *selectedPhoto;
@property (nonatomic, assign) float idleFeelingTimeoutMins;

@property (nonatomic, strong) UIButton *printBtn;

@property (nonatomic, strong) UIBarButtonItem *barBtn;

@property (nonatomic, assign) BOOL userIsPresent;

@property (nonatomic, strong) NSString *storePath;

+ (id)sharedInstance;

- (void)startup;
- (void)pause;
- (void)resume;
- (void)shutdown;
- (BOOL)startServer;

- (void)userHeartbeat;
- (void)loadPersistentSettings;
- (void)loadPhotos;
- (NSString *)photoStoreDirectory;

- (void)downloadPrintablePhotoMetadataFromKiosk;
- (void)newCameraRollPhoto:(NSNotification *)notification;
- (void)refreshPrintablePhotosList:(NSNotification *)notification;

- (void)print:(UIViewController *)viewController dialogFocus:(UIView *)dialogFocus;


@end
