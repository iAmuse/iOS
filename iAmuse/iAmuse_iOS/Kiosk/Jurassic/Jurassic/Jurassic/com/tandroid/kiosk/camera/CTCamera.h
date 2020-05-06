//
//  CTCamera.h
//  SmartPhoto Camera
//
//  Created by Roland Hordos on 2013-05-06.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import <CoreLocation/CoreLocation.h>
#import "CTKiosk.h"
#import "HTTPServer.h"
#import "PhotoLayout.h"

@class GSGreenScreenEffect;
@class CTCameraViewController;
@class ALAssetsLibrary;
@class CLLocationManager;
@class GLKBaseEffect;
@class GLKTextureInfo;
@class GLKView;

//@class CTKiosk;
@protocol CLLocationManagerDelegate;
@class CTVideoProcessor;

@interface CTCamera :NSObject <CLLocationManagerDelegate> {

    UIDeviceOrientation deviceOrientation;
    UIInterfaceOrientation interfaceOrientation;

    float fovCurtainLeftPercent;
    float fovCurtainRightPercent;
    float fovCurtainTopPercent;
    float fovCurtainBottomPercent;
    
//    HTTPServer *httpServer;
    EAGLContext *glContext;

    ALAssetsLibrary *assetsLibrary;

    CLLocationManager *gps;

    BOOL runOnce;
//    BOOL layoutToggle;
}

@property (strong, nonatomic) EAGLContext *glContext;
@property (nonatomic, readwrite, strong) CTVideoProcessor *videoProcessor;
@property (nonatomic, readwrite, assign) CVOpenGLESTextureCacheRef videoTextureCache;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (strong, nonatomic) GSGreenScreenEffect *greenScreenEffect;
@property UIDeviceOrientation deviceOrientation;
@property UIInterfaceOrientation interfaceOrientation;
@property BOOL recordNextCompositeFrame;
@property (atomic) UIImage *recentCompositeFrame;
@property (atomic) CFMutableDictionaryRef recentCompositeFrameInfo;
@property (strong, nonatomic) GLKTextureInfo *background;
@property (strong, nonatomic) GLKTextureInfo *foreground;
@property (strong, nonatomic) UIImage *foregroundImage;
@property (strong, nonatomic) NSString *shader;

@property float distanceToScreen;
@property float optimalDistanceToTarget;
@property float fovCurtainLeftPercent;
@property float fovCurtainRightPercent;
@property float fovCurtainTopPercent;
@property float fovCurtainBottomPercent;
@property float countdownStepSeconds;
@property BOOL runOnce;
@property BOOL layoutToggle;

@property NSDictionary *gpsInfo;

- (id)init;
- (void)start:(UIView *)view layout:(PhotoLayout *)layout;
- (void)pause;
- (void)resume;
- (void)stop;

- (void)freeMemory;

- (NSString *)photoStoreDirectory;
- (void)prepareForPicture;
- (void)turnOnTorch;
- (void)takePicture;
- (void)receiveNewPhotoAvailable:(NSNotification *)notification;
- (void)setCompositeImage:(UIImage *)image incomingTransform:
        (CGAffineTransform)currentTransform;
//- (void)renderWithSquareVertices:(const GLfloat*)squareVertices
//                 textureVertices:(const GLfloat*)textureVertices;
- (void)render:(const GLfloat*)textureVertices;

@end
