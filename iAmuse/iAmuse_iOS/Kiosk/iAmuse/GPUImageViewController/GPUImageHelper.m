//
//  GPUImageHelper.m
//  iAmuse
//
//  Created by IPHONE-02 on 2/3/15.
//  Copyright (c) 2015 iAmuse Inc. All rights reserved.
//

#import "GPUImageHelper.h"
#import <ImageIO/ImageIO.h>
#import "PhotoSession.h"
#import "CTKiosk.h"

@implementation GPUImageHelper
@synthesize screeShotImage;

+ (id)sharedInstance
{
    static GPUImageHelper *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveNewGPUImagePhotoAvailable:)
                                                     name:AMGPUImageCameraNewCompositeFrameNotification
                                                   object:nil];

    });
    return sharedInstance;
}

- (void)intialize
{
       // Setup GPS
    gps = [[CLLocationManager alloc] init];
    gps.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    gps.delegate = self;
    self.gpsInfo = nil;
    [gps startUpdatingLocation];
    store = [AMStorageManager sharedInstance];
    self.recentCompositeFrameInfo = NULL;
    screeShotImage = nil;

}
- (void)dealloc
{
    NSLog(@"%s", __FUNCTION__);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    screeShotImage = nil;
}

- (void)receiveNewGPUImagePhotoAvailable:(NSNotification *)notification {
    
    [self performSelectorOnMainThread:@selector(newPhotoAvailable:) withObject:notification waitUntilDone:NO];
}
- (void)newPhotoAvailable:(NSNotification* )notification {
    
    UIImage *newPhoto = screeShotImage;
    
    if (!assetsLibrary) {
        assetsLibrary = [[ALAssetsLibrary alloc] init];
    }
    
    // Accent the image info with GPS info
    NSAssert(self.recentCompositeFrameInfo != nil, @"We have a recent composite frame but no frame metatdata.");
    CFMutableDictionaryRef imageMetadata = self.recentCompositeFrameInfo;
    if (self.gpsInfo) {
        CFDictionarySetValue(imageMetadata, kCGImagePropertyGPSDictionary, (__bridge const void *)(self.gpsInfo));
    }
    
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
    
    if ([self writeCGImage:[newPhoto CGImage] toURL:targetUrl
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
        // Core Data relationships
        CTKiosk *kiosk1 = [CTKiosk sharedInstance];
        [kiosk1.currentPhotoSession.entity addPhotosObject:photo];
        [photo setSession:kiosk1.currentPhotoSession.entity];
        
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

- (NSString *)photoStoreDirectory {
    NSString *storePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return [storePath stringByAppendingPathComponent:AMHttpPhotoStoreUriComponent];
}
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    /*
     Format the location info as if GPS information for photo metadata use.  We only need a single instance of this then we're done with the location manager completely.
     */
    if (newLocation && !self.gpsInfo) {
        NSLog(@"Have Location information.");
        
        [manager stopUpdatingLocation];
        
        // Create formatted date
        NSTimeZone      *timeZone   = [NSTimeZone timeZoneWithName:@"UTC"];
        NSDateFormatter *formatter  = [[NSDateFormatter alloc] init];
        [formatter setTimeZone:timeZone];
        [formatter setDateFormat:@"HH:mm:ss.SS"];
        
        // Create GPS Dictionary
        self.gpsInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                        [NSNumber numberWithFloat:fabs(newLocation.coordinate.latitude)], kCGImagePropertyGPSLatitude
                        , ((newLocation.coordinate.latitude >= 0) ? @"N" : @"S"), kCGImagePropertyGPSLatitudeRef
                        , [NSNumber numberWithFloat:fabs(newLocation.coordinate.longitude)], kCGImagePropertyGPSLongitude
                        , ((newLocation.coordinate.longitude >= 0) ? @"E" : @"W"), kCGImagePropertyGPSLongitudeRef
                        , [formatter stringFromDate:[newLocation timestamp]], kCGImagePropertyGPSTimeStamp
                        , nil];
        
        gps = nil;
    }
}

@end
