//
//  CTCamera.m
//  SmartPhoto Camera
//
//  Created by Roland Hordos on 2013-05-06.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreLocation/CoreLocation.h>
#import "CTCamera.h"
#import <ImageIO/ImageIO.h>
#import "GSGreenScreenEffect.h"
#import "GSVideoProcessor.h"
#import "CTVideoProcessor.h"
#import "CTCameraViewController.h"
#import "AMConstants.h"
#import "Photo.h"
#import "PhotoLayout.h"
#import "PhotoSession.h"
#import "AMStorageManager.h"

// Class extension for private data and accessors such as read only properties.
@interface CTCamera() {
    const GLfloat *normalizedSquareVertices;
    AMStorageManager *store;
}
//@property (strong, nonatomic) GLKTextureInfo *background;
//@property (nonatomic, readwrite, strong) CTVideoProcessor *videoProcessor;

@end


@implementation CTCamera

@synthesize glContext;
@synthesize videoProcessor = videoProcessor_;
@synthesize videoTextureCache = videoTextureCache_;
@synthesize effect = effect_;
@synthesize greenScreenEffect = greenScreenEffect_;
@synthesize deviceOrientation;
@synthesize interfaceOrientation;
@synthesize fovCurtainLeftPercent, fovCurtainRightPercent, fovCurtainTopPercent, fovCurtainBottomPercent;
@synthesize countdownStepSeconds;
@synthesize runOnce;
@synthesize recordNextCompositeFrame;
@synthesize recentCompositeFrame;
@synthesize recentCompositeFrameInfo;
@synthesize gpsInfo;

-(id) init {
    NSLog(@"%s", __FUNCTION__);
    self = [super init];
    
    if (self) {
        store = [AMStorageManager sharedInstance];

        // We re-use a single OpenGL context to avoid gl error 0x0501
        glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        effect_ = [[GLKBaseEffect alloc] init];
        videoProcessor_ = [[CTVideoProcessor alloc] init];

        // Setup GPS
        gps = [[CLLocationManager alloc] init];
        gps.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        gps.delegate = self;
        gpsInfo = nil;
        [gps startUpdatingLocation];

        runOnce = TRUE;
        self.layoutToggle = FALSE;

        assetsLibrary = nil;
        recordNextCompositeFrame = FALSE;
        recentCompositeFrame = nil;
        recentCompositeFrameInfo = NULL;

        _shader = kAMCameraShaderDefault;

        // Loose coupling from video processor, just let us know when we can pick up our photos ;)
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveNewPhotoAvailable:)
                                                     name:AMCameraNewCompositeFrameNotification
                                                   object:nil];

        // Note many of our property defaults loaded by our parent CTKiosk on assembly.
    }
    
    return self;
}

- (void)dealloc
{
    NSLog(@"%s", __FUNCTION__);

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [self.videoProcessor stopAndTearDownCaptureSession];
    self.videoProcessor.delegate = nil;
    self.videoProcessor = nil;

    // Cleanup glContext
//    [EAGLContext setCurrentContext:nil];      // Should be called by orig setCurrentContext caller
    greenScreenEffect_ = nil;
    effect_ = nil;
    glContext = nil;

    if (recentCompositeFrameInfo) {
        CFRelease(recentCompositeFrameInfo);
    }
    
    recentCompositeFrame = nil;
    _background = nil;
}

- (NSString *)photoStoreDirectory {
    NSString *storePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return [storePath stringByAppendingPathComponent:AMHttpPhotoStoreUriComponent];
}

- (void)start:(UIView *)view layout:(PhotoLayout *)layout {
    CTKiosk *kiosk = [CTKiosk sharedInstance];

    // Make the GL context current.
    [EAGLContext setCurrentContext:glContext];

    // Primary layer provides video camera feed with green screen effect as realtime texture filter.
    // Uses defaults: Not relying on the contents being the same after drawing, and 32 bit RGBA format.
//    CAEAGLLayer *cameraLayer = (CAEAGLLayer *)glkView.layer;

    // If it's the first start, perform some setup.
    if (!greenScreenEffect_) {
        greenScreenEffect_ = [[GSGreenScreenEffect alloc] init];

//        // Setup transparent background with source based transparency blending (source being camera).
//        glClearColor(0.0f, /* Red */ 0.0f, /* Green */ 0.0f, /* Blue */ 0.0f /* Alpha */);
//        glEnable(GL_BLEND);
//        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

        // Cache the textures - one of the largest memory issues
        CVReturn err = CVOpenGLESTextureCacheCreate(
                kCFAllocatorDefault,
                NULL,        // cache attributes dictionary
                glContext,
                NULL,        // texture attributes dictionary
                &videoTextureCache_);

        if (err) {
            NSLog(@"Could not prepare Texture Cache due to %d", err);
        }

        normalizedSquareVertices = [self isRetina] ? [self retinaVerticies] : [self nonRetinaVerticies];
    }

    // Primary layer provides video camera feed with green screen effect as realtime texture filter.
    // Uses defaults: Not relying on the contents being the same after drawing, and 32 bit RGBA format.
    // TODO - RH - more unnecessary code basically used for commentary    CAEAGLLayer *cameraLayer = (CAEAGLLayer *)self.view.layer;

    // Set a background image.
    // Presently the background MUST be cleared out before we setup GL.
    NSString *backgroundFileName = nil;
//    UIImage *foregroundImage = nil;
    if (layout) {
        backgroundFileName = layout.background;

        if (layout.foreground) {
            NSString *foregroundUrl = [kiosk.storePath stringByAppendingPathComponent:layout.foreground];
            self.foregroundImage = [UIImage imageWithContentsOfFile:foregroundUrl];
        } else {
            self.foregroundImage = nil;
        }
    } else {
        NSLog(@"No default layout set for the Kiosk.  Reverting to hard coded default layout1.jpg");
        backgroundFileName = @"layout1.jpg";
//        if (self.layoutToggle) {
//            backgroundFileName = @"layout1.jpg";
//        } else {
//            backgroundFileName = @"layout2.jpg";
//        }
    }
//        backgroundFileName = kiosk.currentPhotoSession.entity.layout.background;

    NSString *backgroundUrl = [kiosk.storePath stringByAppendingPathComponent:backgroundFileName];
    UIImage *backgroundImage = [UIImage imageWithContentsOfFile:backgroundUrl];
    if (!backgroundImage) {
        // TODO - add non-modal self dismissing dialog
//        CTKioskShowAlert([NSString stringWithFormat:@"Background %@ could not be found.", backgroundFileName]);
//            backgroundImage = [UIImage imageNamed:backgroundFileName];
        [NSException raise:@"Could not load background image." format:@""];
    }

    // Orient the image correctly based upon device and super view orientation.
    CGAffineTransform currentTransform = view.transform;
//        NSLog(@"Incoming view is transformed as: a:%f b:%f c:%f d:%f tx:%f ty:%f",
//                currentTransform.a, currentTransform.b, currentTransform.c, currentTransform.d,
//                currentTransform.tx, currentTransform.ty);

    // Rotate the image, not the reference view.
    UIImage *rotatedBackgroundImage = nil;

    deviceOrientation = [[UIDevice currentDevice] orientation];
    interfaceOrientation = [self interfaceOrientation];

    // Does the device orientation match the interface?  If not then adjust.
    switch (deviceOrientation) {
        case UIDeviceOrientationLandscapeLeft:
//                NSLog(@"Device orientation: Landscape Left (home button right)");
            switch (interfaceOrientation) {
                case UIInterfaceOrientationLandscapeLeft:
//                        NSLog(@"Orientations match.");
                    if (currentTransform.b >= 0 && currentTransform.c < 0) {
//                            NSLog(@"Transformed correctly to LL, so rotate background +90");
                        rotatedBackgroundImage = [self
                                rotateLayoutImage:backgroundImage
                                      orientation:UIImageOrientationRight];

                        if (self.foregroundImage) {
                            self.foregroundImage = [self rotateLayoutImage:self.foregroundImage
                                                               orientation:UIImageOrientationRight];
                        }
                    } else {
//                            NSLog(@"But transformed incorrectly to LR, so rotate background +90");
                        rotatedBackgroundImage = [self
                                rotateLayoutImage:backgroundImage
                                      orientation:UIImageOrientationLeft];

                        if (self.foregroundImage) {
                            self.foregroundImage = [self rotateLayoutImage:self.foregroundImage
                                                               orientation:UIImageOrientationLeft];
                        }
                    }
                    break;
                case UIInterfaceOrientationLandscapeRight:
//                        NSLog(@"Orientation mis-match.");
                    if (currentTransform.b >= 0 && currentTransform.c < 0) {
//                            NSLog(@"Transformed incorrectly to LL, rotate background +90");
                        rotatedBackgroundImage = [self
                                rotateLayoutImage:backgroundImage
                                      orientation:UIImageOrientationLeft];
                        if (self.foregroundImage) {
                            self.foregroundImage = [self rotateLayoutImage:self.foregroundImage
                                                               orientation:UIImageOrientationLeft];
                        }
                    } else {
//                            NSLog(@"Transformed correctly to LR, so rotate background -90");
                        rotatedBackgroundImage = [self
                                rotateLayoutImage:backgroundImage
                                      orientation:UIImageOrientationRight];
                        if (self.foregroundImage) {
                            self.foregroundImage = [self rotateLayoutImage:self.foregroundImage
                                                               orientation:UIImageOrientationRight];
                        }
                    }
                    break;
                case UIInterfaceOrientationPortrait:break;
                case UIInterfaceOrientationPortraitUpsideDown:break;
                default:
                    NSLog(@"Unhandled orientation scenario, device:%ld interface:%ld", (long)deviceOrientation, (long)interfaceOrientation);
            }
            break;
        case UIDeviceOrientationLandscapeRight:
//                NSLog(@"Device orientation: Landscape Right (home button left)");
            switch (interfaceOrientation) {
                case UIInterfaceOrientationLandscapeLeft:
//                        NSLog(@"Orientation mis-match.");
                    if (currentTransform.b >= 0 && currentTransform.c < 0) {
//                            NSLog(@"Transformed incorrectly to LL, so rotate background +90");
                        rotatedBackgroundImage = [self
                                rotateLayoutImage:backgroundImage
                                      orientation:UIImageOrientationLeft];
                    } else {
//                            NSLog(@"But transformed incorrectly to LR, so rotate background -90");
                        rotatedBackgroundImage = [self
                                rotateLayoutImage:backgroundImage
                                      orientation:UIImageOrientationRight];
                    }
                    break;
                case UIInterfaceOrientationLandscapeRight:
//                        NSLog(@"Orientations match.");
                    if (currentTransform.b >= 0 && currentTransform.c < 0) {
//                            NSLog(@"Transformed incorrectly to LL, rotate background +90");
                        rotatedBackgroundImage = [self
                                rotateLayoutImage:backgroundImage
                                      orientation:UIImageOrientationLeft];
                    } else {
//                            NSLog(@"Transformed correctly to LR, so rotate background -90");
                        rotatedBackgroundImage = [self
                                rotateLayoutImage:backgroundImage
                                      orientation:UIImageOrientationRight];
                    }
                    break;
                case UIInterfaceOrientationPortrait:break;
                case UIInterfaceOrientationPortraitUpsideDown:break;
                default:
                    NSLog(@"Unhandled orientation scenario, device:%ld, interface:%ld",
                            (long)deviceOrientation, (long)interfaceOrientation);
            }
            break;
        case UIDeviceOrientationPortrait:
//                NSLog(@"Device orientation: Portrait");
            break;
        case UIDeviceOrientationPortraitUpsideDown:
//                NSLog(@"Device orientation: Portrait Upside Down");
            break;
        default:
            NSLog(@"Device orientation: %ld", (long)deviceOrientation);
            break;
    }

//        NSLog(@"Outgoing image orientation %d", rotatedBackgroundImage.imageOrientation);

    if (rotatedBackgroundImage) {
        self.background = [GLKTextureLoader textureWithCGImage:[rotatedBackgroundImage CGImage] options:nil error:NULL];
    } else {
        self.background = [GLKTextureLoader textureWithCGImage:[backgroundImage CGImage] options:nil error:NULL];
    }

//???    if (self.foregroundImage) {
//        self.foreground = [GLKTextureLoader textureWithCGImage:[self.foregroundImage CGImage] options:nil error:NULL];
//    } else {
//        self.foreground = nil;
//    }

    self.effect.texture2d0.name = self.background.name;
    self.effect.texture2d0.target = self.background.target;

    // Ready OpenGL
    //Setup transparent background with source based transparency blending (source being camera).
    glClearColor(0.0f, /* Red */ 0.0f, /* Green */ 0.0f, /* Blue */ 0.0f /* Alpha */);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
}

- (void)stop {
    NSLog(@"%s", __FUNCTION__);

    if (self.videoProcessor) {
        [self.videoProcessor stopAndTearDownCaptureSession];
    }

    // Free the huge overhead of the GL background texture.
    if (_background) {
        GLuint name = _background.name;
        glDeleteTextures(1, &name);     // Delete 1 item named _____
        _background = nil;
    }
//    glFinish();

    // TEMP TEST - can we cleanly swap out different backgrounds???
    self.layoutToggle = !self.layoutToggle;

//
//    self.effect = nil;
//    self.greenScreenEffect = nil;
//    self.videoProcessor.delegate = nil;
//    self.videoProcessor = nil;
}

-(void) pause {
    NSLog(@"%s", __FUNCTION__);

    // There is no public(allowed in AppStore) method for iOS to run continuously in the background for our purposes (serving HTTP).
    // So, we stop the server when the app is paused (if a users exits from the app or locks a device) and
    // restart the server when the app is resumed (based on this document: http://developer.apple.com/library/ios/#technotes/tn2277/_index.html )
    recordNextCompositeFrame = NO;
}

-(void) resume {
    NSLog(@"%s", __FUNCTION__);
}

- (void)freeMemory {
    NSLog(@"%s", __FUNCTION__);

// TODO flush texture cache (loaded backgrounds) with CVOpenGLESTextureCacheFlush
// TODO consider kCVOpenGLESTextureCacheMaximumTextureAgeKey

//    assetsLibrary = nil;
//    recentCompositeFrame = nil;
//    gps = nil;
}

- (void)prepareForPicture {
    AVCaptureDevice *cameraDevice = videoProcessor_.cameraDevice;
    if ([cameraDevice lockForConfiguration:NULL]) {
        DDLogVerbose(@"Camera locked for Configuration");

        // Set the frame rate.
//        cameraDevice.activeVideoMinFrameDuration = CMTimeMake(1, 20);
        //                [cameraDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        [cameraDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];

//        if (cameraDevice.autoFocusRangeRestrictionSupported) {
//            // Autofocus should ignore distant targets.
//            [cameraDevice setAutoFocusRangeRestriction:AVCaptureAutoFocusRangeRestrictionNear];
//        }

        if (cameraDevice.isSmoothAutoFocusEnabled) {
            // Turn off this setting, meant to be for less intrusive video
            // recording.  Our photo booth wants fast autofocus.
            [cameraDevice setSmoothAutoFocusEnabled:NO];
        }

//        if ([cameraDevice isExposureModeSupported:AVCaptureExposureModeLocked]) {
        if ([cameraDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            DDLogVerbose(@"Locking exposure mid screen");
            // You pass a CGPoint where {0,0} represents the top left of the picture area,
            // and {1,1} represents the bottom right in landscape mode with the home button
            // on the right—this applies even if the device is in portrait mode.
            CGPoint exposurePoint = CGPointMake(0.5f, 0.5f);
            [cameraDevice setExposurePointOfInterest:exposurePoint];
            [cameraDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }

        // Autofocus center screen
        if ([cameraDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus] && cameraDevice.isFocusPointOfInterestSupported) {
            DDLogVerbose(@"Auto focusing mid screen");
            CGPoint focusPoint = CGPointMake(0.5f, 0.5f);
            [cameraDevice setFocusPointOfInterest:focusPoint];
            [cameraDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
//            [cameraDevice setFocusMode:AVCaptureFocusModeLocked];
        }

        if ([cameraDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance] && cameraDevice.isFocusPointOfInterestSupported) {
            DDLogVerbose(@"Auto focusing mid screen");
            CGPoint focusPoint = CGPointMake(0.5f, 0.5f);
            [cameraDevice setFocusPointOfInterest:focusPoint];
            [cameraDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
//            [cameraDevice setFocusMode:AVCaptureFocusModeLocked];
        }

        // Turn on the camera torch if available.
        if (cameraDevice.isTorchAvailable) {
            DDLogVerbose(@"Turning on torch");
            [cameraDevice setTorchMode:AVCaptureTorchModeOn];
        }

        [cameraDevice unlockForConfiguration];
    } else {
        DDLogVerbose(@"Could not Lock Camera for Configuration.");
    }
    
    // Configure the texture filter for runtime settings.
    // If the shader changed, update the OpenGL environment.
    if (![self.shader isEqualToString:self.greenScreenEffect.shaderName]) {
        [self.greenScreenEffect removeCurrentShaderProgram];
        self.greenScreenEffect.shaderName = self.shader;
        DDLogVerbose(@"Switched to shader %@", self.shader);
    } else {
        DDLogVerbose(@"Using shader %@", self.shader);
    }
}

- (void)turnOnTorch {
    AVCaptureDevice *cameraDevice = videoProcessor_.cameraDevice;
    if ([cameraDevice lockForConfiguration:NULL]) {
        DDLogVerbose(@"Camera locked for Configuration");

        // Turn on the camera torch if available.
        if (cameraDevice.isTorchAvailable) {
            DDLogVerbose(@"Turning on torch");
            [cameraDevice setTorchMode:AVCaptureTorchModeOn];
        }

        [cameraDevice unlockForConfiguration];
    } else {
        DDLogVerbose(@"Could not Lock Camera for Configuration.");
    }
}

- (void)takePicture {
    NSLog(@"%s", __FUNCTION__);
    /*
     Put up a flag for the video processor (really the delegate) to see and save a new frame during the next
     video frame processing loop.
     */
    recordNextCompositeFrame = YES;
}

- (void)receiveNewPhotoAvailable:(NSNotification *)notification {
    /*
     We expect notifications to come in out of the video processor / gl thread.
     */
    [self performSelectorOnMainThread:@selector(newPhotoAvailable:) withObject:notification waitUntilDone:NO];
}

- (void)newPhotoAvailable:(NSNotification *)notification {
    // Video processor has a new composite frame we can read.
    UIImage *newPhoto = recentCompositeFrame;

    if (!assetsLibrary) {
        assetsLibrary = [[ALAssetsLibrary alloc] init];
    }

    // In case it's ref is nilled by memory warning while we're using it.
//    ALAssetsLibrary *pictureLibrary = assetsLibrary;

    // Accent the image info with GPS info
//    NSAssert(recentCompositeFrameInfo != nil, @"We have a recent composite frame but no frame metatdata.");
//    CFMutableDictionaryRef imageMetadata = CFDictionaryCreateMutableCopy(NULL, 0, recentCompositeFrameInfo);
//    CFDictionarySetValue(imageMetadata, kCGImagePropertyGPSDictionary, (__bridge const void *)(gpsInfo));
    CFMutableDictionaryRef imageMetadata = recentCompositeFrameInfo;
    if (gpsInfo) {
        CFDictionarySetValue(imageMetadata, kCGImagePropertyGPSDictionary, (__bridge const void *)(gpsInfo));
    }

//        NSDictionary *usableImageMetadata = (__bridge NSDictionary*)recentCompositeFrameInfo;
//        NSMutableDictionary *imageMetadata = [[NSMutableDictionary alloc] initWithDictionary:usableImageMetadata copyItems:YES];
//        [imageMetadata setValue:gpsInfo forKey:@"{GPS}"];

    // Write to camera roll
    NSDictionary *usefulImageMetadata = (__bridge NSDictionary*)imageMetadata;
    [assetsLibrary writeImageToSavedPhotosAlbum: [newPhoto CGImage] metadata:usefulImageMetadata
        completionBlock:^(NSURL *assetURL, NSError *error)
        {
            if (error) {
                NSLog(@"ERROR: the image failed to be written");
            }
            else {
                NSLog(@"PHOTO SAVED - assetURL: %@", assetURL);
                // TODO - how to release now that we're done with it
//                CFRelease(recentCompositeFrameInfo);
            }

            [[NSNotificationCenter defaultCenter] postNotificationName:AMCameraNewCameraRollPhotoNotification object:assetURL];
        }];

    // Write to disk
    NSString *targetFilePath = [self photoStoreDirectory];
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
    NSString *targetFileName = [NSString stringWithFormat:@"photo-%f.jpg",
                    timeInterval];
    NSURL *targetUrl = [NSURL fileURLWithPath:[targetFilePath
            stringByAppendingPathComponent:targetFileName]];

    // Start a CoreData object at the same time and store

    if ([self writeCGImage:[recentCompositeFrame CGImage] toURL:targetUrl
              withType:kUTTypeJPEG
            andOptions:imageMetadata]) {

        NSLog(@"New image saved to disk at %@", targetUrl);

        // Record a CD entity
        // Create and store a Photo entity.
        Photo *photo = (Photo *)[NSEntityDescription
                insertNewObjectForEntityForName:@"Photo"
                         inManagedObjectContext:store.currentMOC];

        [photo setCreatedOn:[NSDate date]];
        [photo setToKioskOn:[NSDate date]];
        [photo setPhotoUrl:[targetUrl absoluteString]];

        // Core Data relationships
        CTKiosk *kiosk = [CTKiosk sharedInstance];
        [kiosk.currentPhotoSession.entity addPhotosObject:photo];
        [photo setSession:kiosk.currentPhotoSession.entity];

        // Then store.
        NSError *error = nil;
        if ([store.currentMOC save:&error]) {
            NSLog(@"New Photo entity stored.");
        } else {
            // TODO Handle the error.
            NSLog(@"Error saving new photo entity: %@",
                    [error localizedDescription]);
        }

        // Then let everyone know.
        [[NSNotificationCenter defaultCenter]
                postNotificationName:AMCameraNewDiskPhotoNotification
                              object:targetFileName];
    } else {
        NSLog(@"Error saving photo to disk.");
    }

}

//- (void)captureStillImageAsynchronouslyFromConnection:videoConnection
//        completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error)
//{
//
//    if (imageDataSampleBuffer != NULL)
//
//    {
//
//        CFDictionaryRef exifAttachments = CMGetAttachment(imageDataSampleBuffer,kCGImagePropertyExifDictionary, NULL);
//        CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL, imageDataSampleBuffer, kCMAttachmentMode_ShouldPropagate);
//
//
//        NSDictionary *gpsDict = [NSDictionary dictionaryWithObjectsAndKeys:@"1",kCGImagePropertyGPSVersion,
//                                                                           @"78.4852",kCGImagePropertyGPSLatitude,@"32.1456",kCGImagePropertyGPSLongitude, nil];
//
//        CMSetAttachment(imageDataSampleBuffer,kCGImagePropertyGPSDictionary,gpsDict,kCMAttachmentMode_ShouldPropagate);
//
//        CFDictionaryRef newMetadata = CMCopyDictionaryOfAttachments(NULL, imageDataSampleBuffer, kCMAttachmentMode_ShouldPropagate);
//        CFDictionaryRef gpsAttachments = CMGetAttachment(imageDataSampleBuffer,kCGImagePropertyGPSDictionary, NULL);
//
//        if (exifAttachments)
//        { // Attachments may be read or additional ones written
//
//        }
//
//        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
//        UIImage *image = [[UIImage alloc] initWithData:imageData];
//
//        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//        /
//
//
//        NSDictionary *newDict = (NSDictionary *)newMetadata;
//
//        [library writeImageToSavedPhotosAlbum:[image CGImage]
//                                     metadata:newDict completionBlock:^(NSURL *assetURL, NSError *error)
//        {
//            if (error)
//            {
//
//            }
//        }];
//
//        [library release];
//        [image release];
//        CFRelease(metadataDict);
//        CFRelease(newMetadata);
//
//    }
//    else if (error)
//    {
//
//    }
//
//}];
//


- (BOOL)writeCGImage:(CGImageRef)image toURL:(NSURL*)url
            withType:(CFStringRef)imageType
          andOptions:(CFDictionaryRef)options {

    CGImageDestinationRef target = CGImageDestinationCreateWithURL(
            (__bridge CFURLRef) url,
            imageType, // UTI Uniform Type Identifier
            1,         // count
            nil);      // future

    CGImageDestinationAddImage(target, image, options);
    BOOL success = CGImageDestinationFinalize(target);

    CFRelease(target);
    if (options)
        CFRelease(options);

    return success;
}


- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    /*
     Format the location info as if GPS information for photo metadata use.  We only need a single instance of this then we're done with the location manager completely.
     */
    if (newLocation && !gpsInfo) {
        NSLog(@"Have Location information.");

        [manager stopUpdatingLocation];

        // Create formatted date
        NSTimeZone      *timeZone   = [NSTimeZone timeZoneWithName:@"UTC"];
        NSDateFormatter *formatter  = [[NSDateFormatter alloc] init];
        [formatter setTimeZone:timeZone];
        [formatter setDateFormat:@"HH:mm:ss.SS"];

        // Create GPS Dictionary
        gpsInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithFloat:fabs(newLocation.coordinate.latitude)], kCGImagePropertyGPSLatitude
                , ((newLocation.coordinate.latitude >= 0) ? @"N" : @"S"), kCGImagePropertyGPSLatitudeRef
                , [NSNumber numberWithFloat:fabs(newLocation.coordinate.longitude)], kCGImagePropertyGPSLongitude
                , ((newLocation.coordinate.longitude >= 0) ? @"E" : @"W"), kCGImagePropertyGPSLongitudeRef
                , [formatter stringFromDate:[newLocation timestamp]], kCGImagePropertyGPSTimeStamp
                , nil];

        gps = nil;
    }
}

- (void)setCompositeImage:(UIImage *)image incomingTransform:
        (CGAffineTransform)currentTransform {

    UIImageView *helperView = [[UIImageView alloc] initWithImage:image];

    recentCompositeFrame = [UIImage imageWithCGImage:helperView.image.CGImage
                                                scale:1.0
                                          orientation:UIImageOrientationUp];
}

- (void)setCompositeImageBAK:(UIImage *)image incomingTransform:
        (CGAffineTransform)currentTransform {
    /*
     Depending on the device, user interface, and image orientations,
     transform the output image to a normalized ImageOrientationUp.

     Keep track of the number of 180 degree
     */

//    recentCompositeFrame = image;
//    UIImageView *helperView = [[UIImageView alloc] initWithImage:image];
//    helperView.transform = CGAffineTransformMakeRotation(M_PI);
////    recentCompositeFrame = helperView.image;
//
//    recentCompositeFrame = [UIImage imageWithCGImage:helperView.image.CGImage
//                                                scale:1.0
//                                          orientation:UIImageOrientationDown];
//
// =-=-=-=-=-=-

//    UIGraphicsBeginImageContext(image.size);
//
//    CGContextRef context=(UIGraphicsGetCurrentContext());
//
//    CGContextRotateCTM (context, M_PI_2);
//
//    [image drawAtPoint:CGPointMake(image.size.width, image.size.height)];
//    recentCompositeFrame = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();

// =-=-=-=-=-=-


//    UIGraphicsBeginImageContext(image.size);
//    CGContextRef cgContext = UIGraphicsGetCurrentContext();
//
//    float width = image.size.width;
//    float height = image.size.height;
//
////    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, image.size.width);
//    // Rotating 180 means putting the origin on the opposite corner.
//    CGContextTranslateCTM(cgContext, width, height);
//    CGContextRotateCTM(cgContext, M_PI);
////    CGContextConcatCTM(cgContext, flipVertical);
//    CGContextDrawImage(cgContext, CGRectMake(0, 0, height, width), [image CGImage]);
//    recentCompositeFrame = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//}

    deviceOrientation = [[UIDevice currentDevice] orientation];
    interfaceOrientation = [self interfaceOrientation];
    int rotationCounter = 0;

    // Does the device orientation match the interface?  If not then adjust.
    NSLog(@"Camera orientation?");
    switch (deviceOrientation) {
        case UIDeviceOrientationLandscapeLeft:
//            NSLog(@"Device orientation: Landscape Left (home button right)");
            switch (interfaceOrientation) {
                case UIInterfaceOrientationLandscapeLeft:
//                    NSLog(@"Interface orientation LL (match).");
                    if (currentTransform.b >= 0 && currentTransform.c < 0) {
//                        NSLog(@"Interface transformed correctly to LL.");
                        recentCompositeFrame = [self rotateImage:image
                                                         radians:M_PI];
                    } else {
//                        NSLog(@"But transformed incorrectly to LR .. +1");
                        rotationCounter ++;
                    }
                    break;
                case UIInterfaceOrientationLandscapeRight:
//                    NSLog(@"Orientation mis-match.");
                    if (currentTransform.b >= 0 && currentTransform.c < 0) {
//                        NSLog(@"Transformed incorrectly to LL, rotate 180");
                        recentCompositeFrame = [self rotateImage:image
                                                         radians:M_PI];
                    } else {
//                        NSLog(@"Transformed correctly to LR");
                        recentCompositeFrame = [self rotateImage:image
                                                         radians:M_PI];
                    }
                    break;
                case UIInterfaceOrientationPortrait:break;
                case UIInterfaceOrientationPortraitUpsideDown:break;
                default:
                    NSLog(@"Unhandled orientation scenario, device:%ld, interface:%ld",
                            (long)deviceOrientation, (long)interfaceOrientation);
            }
            break;
        case UIDeviceOrientationLandscapeRight:
//            NSLog(@"Device orientation: Landscape Right (home button left)");
            switch (interfaceOrientation) {
                case UIInterfaceOrientationLandscapeLeft:
//                    NSLog(@"Orientation mis-match.");
                    if (currentTransform.b >= 0 && currentTransform.c < 0) {
//                        NSLog(@"Transformed incorrectly to LL, so rotate background +90");
                        recentCompositeFrame = [self rotateImage:image
                                                         radians:M_PI];
                    } else {
//                        NSLog(@"But transformed incorrectly to LR, so rotate background -90");
                        recentCompositeFrame = [self rotateImage:image
                                                         radians:M_PI];
                    }
                    break;
                case UIInterfaceOrientationLandscapeRight:
//                    NSLog(@"Orientations match.");
                    if (currentTransform.b >= 0 && currentTransform.c < 0) {
//                        NSLog(@"Transformed incorrectly to LL, rotate background +90");
                        recentCompositeFrame = [self rotateImage:image
                                                         radians:M_PI];
                    } else {
//                        NSLog(@"Transformed correctly to LR, so rotate background -90");
                        recentCompositeFrame = [self rotateImage:image
                                                         radians:M_PI];
                    }
                    break;
                case UIInterfaceOrientationPortrait:break;
                case UIInterfaceOrientationPortraitUpsideDown:break;
                default:
                    NSLog(@"Unhandled orientation scenario, device:%ld, interface:%ld",
                            (long)deviceOrientation, (long)interfaceOrientation);
            }
            break;
        case UIDeviceOrientationPortrait:
//            NSLog(@"Device orientation: Portrait");
            break;
        case UIDeviceOrientationPortraitUpsideDown:
//            NSLog(@"Device orientation: Portrait Upside Down");
            break;
        default:
            NSLog(@"Device orientation: %ld", (long)deviceOrientation);
            break;
    }

//    NSLog(@"Incoming image orientation is %d", image.imageOrientation);
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
//            NSLog(@"Incoming image orientation is not right.");
            rotationCounter ++;
            break;
        case UIImageOrientationUp:
            // noop
            break;
        default:
            NSLog(@"WARNING:  Unhandled scenario of incoming image orientation.");
    }

    if (rotationCounter % 2 != 0) {
        // Odd number of 180 rotation "ticks" so net result is need for 180.
//        UIImage *rotatedImage = [self rotateImage:image radians:M_PI];
        recentCompositeFrame = [self rotateImage:image radians:M_PI];

//        recentCompositeFrame = [UIImage imageWithCGImage:rotatedImage.CGImage
//                                                    scale:[[UIScreen mainScreen] scale]
//                                              orientation:UIImageOrientationUp];
    }
}

- (UIImage *)rotateLayoutImage:(UIImage *)layoutImage
                   orientation:(UIImageOrientation)imageOrientation
{
    UIGraphicsBeginImageContext(layoutImage.size);
    CGContextRef cgContext = UIGraphicsGetCurrentContext();

    float width = layoutImage.size.width;
    float height = layoutImage.size.height;
    CGAffineTransform flipVertical;

    switch (imageOrientation) {
        case UIImageOrientationLeft:
            // Rotating coordinates 90 degrees means putting the zeroes at the top right, and the old width is the new height.
            CGContextTranslateCTM(cgContext, width, 0);
            CGContextRotateCTM(cgContext, M_PI_2);
            // For this system the background images also need to be flipped vertically (to get the GL coordinates?)
            flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, layoutImage.size.width);
            CGContextConcatCTM(cgContext, flipVertical);
            CGContextDrawImage(cgContext, CGRectMake(0, 0, height, width), [layoutImage CGImage]);
            break;
        case UIImageOrientationRight:
            // Rotating coordinates -90 degrees means putting the zeroes at the bottom left, and the old width is the new height.
            CGContextTranslateCTM(cgContext, 0, height);
            CGContextRotateCTM(cgContext, -M_PI_2);
            // For this system the background images also need to be flipped vertically (to get the GL coordinates?)
            flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, layoutImage.size.width);
            CGContextConcatCTM(cgContext, flipVertical);
            CGContextDrawImage(cgContext, CGRectMake(0, 0, height, width), [layoutImage CGImage]);
            break;
        default:
            NSLog(@"Orientation case not handled: %ld", (long)imageOrientation);
            return nil;
    }
    UIImage *rotatedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return rotatedImage;
}

- (UIImage *)rotateImage:(UIImage *)image radians:(float)radians {
    UIGraphicsBeginImageContext(image.size);
    CGContextRef cgContext = UIGraphicsGetCurrentContext();

    CGAffineTransform currentTransform = CGContextGetCTM(cgContext);
    if (!CGAffineTransformIsIdentity(currentTransform)) {
//        currentTransform = CGAffineTransformIdentity;
    }

//    CGFloat scale = [[UIScreen mainScreen] scale];
    CGFloat scale = 1.0;
//    CGContextScaleCTM(UIGraphicsGetCurrentContext(), scale, scale);

    float width = image.size.width * scale;
    float height = image.size.height * scale;

//    CGContextRotateCTM(cgContext, M_PI);
//    CGContextConcatCTM(cgContext, flipVertical);

//    CGContextTranslateCTM(cgContext, width / 4, height * 2 / 3);
//    CGContextRotateCTM(cgContext, radians);

//    CGContextScaleCTM(cgContext, -1.0, 1.0);

// =-=-=
//    CGContextRotateCTM(cgContext, M_PI);
////    CGContextConcatCTM(cgContext, flipVertical);

//=-=-=-=
//    CGContextTranslateCTM(context, 0, image.size.height);
//    CGContextScaleCTM(context, 1.0, -1.0);
//=-=-=-=

    CGContextDrawImage(cgContext, CGRectMake(0, 0, height, width), [image CGImage]);
    UIImage *rotatedImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();
    return rotatedImage;
}

- (BOOL)isRetina
{
    return [[UIScreen mainScreen] scale] == 2.0;
}

- (const CGFloat*)retinaVerticies
{
    static const GLfloat squareVertices[] =
            {
                    -1.0f,  1.0f,
                    -1.0f, -1.0f,
                    1.0f,  1.0f,
                    1.0f, -1.0f,
            };
    return squareVertices;
}

- (const CGFloat*)nonRetinaVerticies
{
    static const GLfloat squareVertices[] =
            {
                    -1.0f, -1.0f,
                    1.0f, -1.0f,
                    -1.0f,  1.0f,
                    1.0f,  1.0f,
            };
    return squareVertices;
}


//- (void)renderWithSquareVertices:(const GLfloat*)squareVertices
//                 textureVertices:(const GLfloat*)textureVertices
- (void)render:(const GLfloat*)textureVertices
{
    // Update attribute values.
    glVertexAttribPointer(GLKVertexAttribPosition,
            2,
            GL_FLOAT,
            0,
            0,
            normalizedSquareVertices);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribTexCoord0,
            2,
            GL_FLOAT,
            0,
            0,
            textureVertices);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}



@end
