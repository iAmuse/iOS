//
//  ViewController.h
//  iAmuseTest
//
//  Created by IPHONE-02 on 1/13/15.
//  Copyright (c) 2015 Himanshu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPUImage.h"
#import "CTKiosk.h"

@interface ViewController : UIViewController
{
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageStillCamera * stillCamera;
    CTKiosk *kiosk;
    // Per-frame execution variables that need occasional exposure as properties.
    // Somewhat out of place, presently it's this controller that is hit every frame.
    float currentScale;
    float currentXOffset;
    float currentYOffset;
    UIDeviceOrientation deviceOrientation;
    UIInterfaceOrientation interfaceOrientation;

}
@property (strong, nonatomic) UIImage *foregroundImage;

@property (strong, nonatomic) IBOutlet UIView *cameraView;
@property (strong, nonatomic) IBOutlet UIImageView *bgImage;
@property(nonatomic, strong) GPUImageVideoCamera*  videoCamera;
@property(nonatomic, strong) GPUImageStillCamera*  stillCamera;

@property(nonatomic, strong) GPUImageMovie * movieFile;
@property(nonatomic, strong) GPUImagePicture * sourcePicture;

@end

