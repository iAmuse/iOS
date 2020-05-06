//  ScreenShotViewController.h
//  iAmuse
//
//  Created by Himanshu on 2/5/15.
//  Copyright (c) 2015 iAmuse Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPUImage.h"
@interface ScreenShotViewController : UIViewController
    {
        GPUImageOutput<GPUImageInput> *filter;
        
        NSArray * colorComponents;
        UIDeviceOrientation deviceOrientation;
        UIInterfaceOrientation interfaceOrientation;
    }
    @property(nonatomic,strong)UIImage * screenShotImage ;
    @property(nonatomic, strong) GPUImageStillCamera*  stillCamera;
    @property(nonatomic, strong) GPUImagePicture * sourcePicture;
    
    @end

