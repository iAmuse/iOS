//  ScreenShotViewController.m
//  iAmuse
//
//  Created by Himanshu on 2/5/15.
//  Copyright (c) 2015 iAmuse Inc. All rights reserved.
//

#import "ScreenShotViewController.h"
#import "AMUtility.h"
#import "WebCommunication.h"
#import "MBProgressHUD.h"
#import "AMConstants.h"
#import "NSData+Base64.h"
#define IS_IOS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_RETINA ([[UIScreen mainScreen] scale] >= 2.0)

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define SCREEN_MIN_LENGTH (MIN(SCREEN_WIDTH, SCREEN_HEIGHT))

#define IS_IPHONE_4_OR_LESS (IS_IPHONE && SCREEN_MAX_LENGTH < 568.0)
#define IS_IPHONE_5 (IS_IPHONE && SCREEN_MAX_LENGTH == 568.0)
#define IS_IPHONE_6 (IS_IPHONE && SCREEN_MAX_LENGTH == 667.0)
#define IS_IPHONE_6P (IS_IPHONE && SCREEN_MAX_LENGTH == 736.0)

#define kSendScreenShotToServerNotification @"sendCameraScreenShot"
#define kImage @"images"
#define kUserId @"userId"

@interface ScreenShotViewController ()
    @property (weak, nonatomic) IBOutlet GPUImageView *cameraView;
    
    @end

@implementation ScreenShotViewController
    @synthesize  sourcePicture,stillCamera,screenShotImage;
    
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setOrientation];
    // Do any additional setup after loading the view.
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(deviceOrientationDidChange:)
                                                 name: UIDeviceOrientationDidChangeNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(screenShotDone:)
                                                 name: kSendScreenShotToServerNotification
                                               object: nil];
    
    
}
- (void)viewWillAppear:(BOOL)animated
    {
        [super viewWillAppear:animated];
        
        NSLog(@"%s", __FUNCTION__);
        [self startCamera];
    }
    
#pragma mark - Start Camera Method
    
- (void)startCamera
    {
        NSUserDefaults * userdefault = [NSUserDefaults standardUserDefaults];
        // Init Camera
        filter = [[GPUImageFilter alloc] init];
        
        NSString *camMod=[userdefault objectForKey:@"cameraMode"];
        NSLog(@"CamMod is %@",camMod);
        
        
//        if ([[userdefault objectForKey:@"cameraMode"] isEqualToString:@"Rear"] || [userdefault objectForKey:@"cameraMode"] == nil) {
//            stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionBack];
//        }
//        else
//        {
//            stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionFront];
//        }
        
        if ([[userdefault objectForKey:@"cameraMode"] isEqualToString:@"Front"] || [userdefault objectForKey:@"cameraMode"] == nil) {
            stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionFront];
        }
        else
        {
            stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionBack];
        }
        
        
        
        
        
        stillCamera.outputImageOrientation = [self interfaceOrientation];
        stillCamera.horizontallyMirrorFrontFacingCamera = NO;
        stillCamera.horizontallyMirrorRearFacingCamera = NO;
        // Create custom GPUImage camera
        [stillCamera addTarget:filter];
        
        
        [self.cameraView setFrame:CGRectMake(self.cameraView.frame.origin.x, self.cameraView.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height)];
        
        GPUImageView *filterView = (GPUImageView *)self.cameraView;
        [filter forceProcessingAtSize:filterView.sizeInPixels];
        [filter addTarget:filterView];
        // Begin showing video camera stream
        [stillCamera startCameraCapture];
        
        [self performSelector:@selector(takeScreenShot) withObject:nil afterDelay:7.0];
    }
#pragma mark - Take Screenshot Method
    
- (void)takeScreenShot {
    
    NSLog(@"%s", __FUNCTION__);
    
    [stillCamera capturePhotoAsImageProcessedUpToFilter:filter withCompletionHandler:^(UIImage *processedImage, NSError *error){
        if(processedImage)
        {
            screenShotImage = [UIImage imageWithCGImage:processedImage.CGImage scale:1.0 orientation:UIImageOrientationUp];
            [[NSNotificationCenter defaultCenter] postNotificationName:kSendScreenShotToServerNotification object:nil];
        }
    }];
    
}
- (void)screenShotDone:(NSNotification *)notification {
    
    [self performSelectorOnMainThread:@selector(sendScreenShot) withObject:nil waitUntilDone:NO];
}
    
#pragma mark - Post Screenshot Server API Call
    
- (void)sendScreenShot
    {
        if(screenShotImage)
        {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeIndeterminate;
            hud.labelText = @"Please wait while we are uploading the color palette to server.";
            NSMutableDictionary * dict = [NSMutableDictionary dictionary];
            NSData *imgdata =  UIImageJPEGRepresentation(screenShotImage,.2);
            NSString *base64string = [imgdata base64EncodedString];
            [dict setObject:base64string forKey:kImage];
            [dict setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"userId"] forKey:@"userId"];
            //        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:PENDING_SCREENSHOT_REQUEST];
            //        [[NSUserDefaults standardUserDefaults]synchronize];
            
            WebCommunication * webComm = [WebCommunication new];
            [webComm callToServerRequestDictionary:dict onURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kAMBaseURL,kAMSendScreenShotURL]] WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm)
             {
                 NSLog(@"response : %@",response);
                 if(!error)
                 {
                     if([[response objectForKey:@"responseDescription"] isEqualToString:@"Success"])
                     {
                         [[NSUserDefaults standardUserDefaults] setBool:NO forKey:PENDING_SCREENSHOT_REQUEST];
                         [[NSUserDefaults standardUserDefaults]synchronize];
                         [self performSelector:@selector(hideHUD) withObject:nil afterDelay:4.0];
                     }
                 }
                 else
                 {
                     [self performSelector:@selector(hideHUD) withObject:nil afterDelay:4.0];
                 }
             }];
        }
    }
    
- (void)hideHUD
    {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [self dismissViewControllerAnimated:YES completion:nil];
        
    }
#pragma mark - Device Orientation Method
    
- (void)deviceOrientationDidChange:(NSNotification *)notification {
    [self setOrientation];
}
    
- (void)setOrientation
    {
        NSLog(@"%s", __FUNCTION__);
        
        UIInterfaceOrientation orientation = [self interfaceOrientation];
        
        // We only need to handle landscape and portrait.
        if (orientation == UIDeviceOrientationFaceUp ||
            orientation == UIDeviceOrientationFaceDown ||
            orientation == UIDeviceOrientationUnknown ||
            stillCamera.outputImageOrientation == orientation) {
            return;
        }
        GPUImageView *filterView = (GPUImageView *)self.cameraView;
        [filter forceProcessingAtSize:filterView.sizeInPixels];
        stillCamera.outputImageOrientation = orientation;
    }
    
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:(BOOL)animated];
    
    NSLog(@"%s", __FUNCTION__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}
    
    @end

