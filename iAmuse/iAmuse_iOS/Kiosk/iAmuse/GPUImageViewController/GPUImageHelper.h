//
//  GPUImageHelper.h
//  iAmuse
//
//  Created by IPHONE-02 on 2/3/15.
//  Copyright (c) 2015 iAmuse Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMConstants.h"
#import <CoreLocation/CoreLocation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "AMStorageManager.h"

@interface GPUImageHelper : NSObject<CLLocationManagerDelegate>
{
    ALAssetsLibrary *assetsLibrary;
    CLLocationManager *gps;
    AMStorageManager *store;

}
@property (nonatomic,strong) UIImage * screeShotImage;

@property NSDictionary *gpsInfo;
@property (atomic) CFMutableDictionaryRef recentCompositeFrameInfo;
+ (id)sharedInstance;

- (void)intialize;
@end
