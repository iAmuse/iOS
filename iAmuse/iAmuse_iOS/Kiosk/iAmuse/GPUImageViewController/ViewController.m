//
//  ViewController.m
//  iAmuseTest
//
//  Created by IPHONE-02 on 1/13/15.
//  Copyright (c) 2015 Himanshu. All rights reserved.
//

#import "ViewController.h"
#import "PhotoSession.h"
#import "Kiosk.h"
#import "AMConstants.h"
#import "CTAppDelegate.h"
#import <ImageIO/ImageIO.h>
#import "AMUtility.h"
#import "FovSettingView.h"
#import "UIView+Toast.h"
#import "ABPadLockScreenViewController.h"
#import "CTSettingsViewController.h"
#import "WebCommunication.h"

#define MAX3(a,b,c) ( MAX(a, MAX(b,c)) )
#define IS_IOS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_RETINA ([[UIScreen mainScreen] scale] >= 2.0)

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define SCREEN_MIN_LENGTH (MIN(SCREEN_WIDTH, SCREEN_HEIGHT))

#define IS_IPHONE_4S_OR_LESS (IS_IPHONE && SCREEN_MAX_LENGTH < 568.0)
#define IS_IPHONE_5 (IS_IPHONE && SCREEN_MAX_LENGTH == 568.0)
#define IS_IPHONE_6 (IS_IPHONE && SCREEN_MAX_LENGTH == 667.0)
#define IS_IPHONE_6P (IS_IPHONE && SCREEN_MAX_LENGTH == 736.0)

#define kMaxIdleTimeSeconds 3.0
@implementation UIImage(Crop)

- (UIImage *)crop:(CGRect)rect
{
    if (self.scale > 1.0f)
    {
        rect = CGRectMake(rect.origin.x * self.scale, rect.origin.y * self.scale,
                          rect.size.width * self.scale, rect.size.height * self.scale);
    }
    
    CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
    UIImage * result = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
    //UIImage * result = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return result;
    
    // **************** CODE FOR DIFFERENT SCALE
    //    float scale = [UIScreen mainScreen].scale;
    //    if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && (scale >= 2.0))
    //    {
    //        rect = CGRectMake(rect.origin.x * scale, rect.origin.y * scale,
    //                          rect.size.width * scale, rect.size.height * scale);
    //    }
    //    CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
    //    UIImage * result = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:self.imageOrientation];
    //    CGImageRelease(imageRef);
    //    return result;
    
}
@end

@interface ViewController ()<FovValueChangeDelegate>
{
    CGRect maskFrame;
    GPUImageView * filterView;
       GPUImageCropFilter *Croper;
    GPUImageChromaKeyBlendFilter *Chroma;
    GPUImageView *filteredVideoView;
     GPUImageTransformFilter *transformLive;
    
    BOOL isTestSession;
    CGFloat scalefactor;
    FovSettingView *fovView;
    CGImageRef masked,mask;
     NSUndoManager *_undoManager;
     NSUndoManager * undoManager;
    ABPadLockScreenViewController *lockScreen;
    
    NSString *flag;
}



@property (assign, nonatomic) CGRect videoFrame;
@property (assign, nonatomic) CGRect croperRect;
@property (assign, nonatomic) CGRect mainFrameRect;
@property (assign, nonatomic) CGRect videoFrameL;
//@property (assign, nonatomic) CGRect newFrame;

@property (strong, nonatomic) UIImageView *imageFrame1;
@property (strong, nonatomic) UIImageView *imageFrame2;
@property (strong, nonatomic) UIImageView *imageFrame3;
@property (strong, nonatomic) UIImageView *imageFrame4;

@property (strong, nonatomic) UIImageView *imageFrameL1;
@property (strong, nonatomic) UIImageView *imageFrameL2;
@property (strong, nonatomic) UIImageView *imageFrameL3;
@property (strong, nonatomic) UIImageView *imageFrameL4;



@end

@implementation ViewController

UIImageView *dot;

@synthesize sourcePicture, stillCamera;
@synthesize thresholdValue;//, videoCamera;


CGFloat kResizeThumbSize = 45.0f;
BOOL isResizingLR;
BOOL isResizingUL;
BOOL isResizingUR;
BOOL isResizingLL;
CGPoint touchStart;


CGPoint panOriginPointL;
CGRect cropOriginFrameL;
TOCropViewOverlayEdge tappedEdgeL;
CGRect newFrameL;

CGPoint panOriginPoint;
CGRect cropOriginFrame;
TOCropViewOverlayEdge tappedEdge;
CGRect newFrame;

CGRect frameRotate;

float zoomScale = 0.0;
float zoomScaleL = 0.0;


 int maxWidth, maxHeight;

CGRect OriginalrectVideoL;
CGPoint OriginalcenterVideoL;
CGRect OriginalrectVideo;
CGPoint OriginalcenterVideo;
CGRect OriginalrectCropL;
CGPoint OriginalcenterCropL;
CGRect OriginalrectCrop;
CGPoint OriginalcenterCrop;
CGRect TemprectCropL;
CGPoint TempcenterCropL;
CGRect TemprectCrop;
CGPoint TempcenterCrop;
BOOL IsConstraint;

CGRect OriginalrectLiveVideoL;
CGPoint OriginalcenterLiveVideoL;
CGRect OriginalrectLiveVideo;
CGPoint OriginalcenterLiveVideo;



- (void)viewDidLoad
{
    [super viewDidLoad];
  //  [self SubscriptionUpdate];
    flag=@"false";
    float wid,hei,hh;
    wid=self.view.frame.size.width;
  //  hh=self.view.frame.size.height-186;
    
    if(wid>1024)
    {
        hei=121.0f;
        hh=self.view.frame.size.height-242;
        
    }else
    {
        hei=93.0f;
        hh=580.0f;
        
         //hh=self.view.frame.size.height-186;
    }
    
    
    self.viewTop=[[UIView alloc] initWithFrame:CGRectMake(00.0f, 00.0f, self.view.frame.size.width, hei)];
    self.viewTop.hidden=YES;
    
//    self.viewVideo=[[UIScrollView alloc] initWithFrame:CGRectMake(00.0f, 00.0f, self.view.frame.size.width, 580.0f)];
    
    self.viewVideo=[[UIScrollView alloc] initWithFrame:CGRectMake(00.0f, 00.0f, self.view.frame.size.width, hh)];
    
    self.viewVideo.hidden=YES;
    
    if (IS_IPAD)
    {
        self.mainCameraView.frame = CGRectMake(0, 0, 1024, 768);
    }
    shotsRemaining = 0;
    dot.hidden=NO;
    
    [self resetIdleTimer];
    
    
    
    //    GPUImageView *gpuImageView = [[GPUImageView alloc]initWithFrame:CGRectMake(self.cameraView.frame.origin.x, self.cameraView.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height)];
    // self.cameraView.frame = CGRectMake(self.cameraView.frame.origin.x, self.cameraView.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
    
    store = [AMStorageManager sharedInstance];
    kiosk = [CTKiosk sharedInstance];
    [kiosk loadPersistentSettings:NO];
    
    assetsLibrary = nil;
    
    //    recordNextCompositeFrame = FALSE;
    
    // Setup GPS
    
    gps = [[CLLocationManager alloc] init];
    gps.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    gps.delegate = self;
    self.gpsInfo = nil;
    [gps startUpdatingLocation];
    
    self.recentCompositeFrameInfo = NULL;
    
  //  [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    
    
    
  
    
    
    
    
    
    //        [[NSNotificationCenter defaultCenter] addObserver:self
    //                                                 selector:@selector(showSettingScreen:)
    //                                                     name:@"OpenSettingSceneNotification"
    //                                                   object:nil];
    //
    //        [[NSNotificationCenter defaultCenter] addObserver:self
    //                                                 selector:@selector(showSettingScreen:)
    //                                                     name:@"showSettingScreen"
    //                                                   object:nil];
    //
    //        [[NSNotificationCenter defaultCenter] addObserver:self
    //                                                 selector:@selector(lockCancel:)
    //                                                     name:@"lockCancel"
    //                                                   object:nil];
    //
    
    
    
    
    
    
    
    
    
    
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(deviceOrientationDidChange:)
                                                 name: UIDeviceOrientationDidChangeNotification
                                               object: nil];
    
    // Tell us when camera api events happen from the built in web server.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetPhotoShoot:)
                                                 name:AMCameraResetPhotoShootNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveStopPhotoSession:)
                                                 name:AMCameraStopPhotoSessionNotification
                                               object:nil];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(callingFunction:)
                                                 name:@"checkingAction"
                                               object:nil];
    
    
    
    
    
    
    
    
    
    // We want to know when the photo has actually been saved.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newPhotoDidStore:)
                                                 name:AMCameraNewDiskPhotoNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveNewGPUImagePhotoAvailable:)
                                                 name:AMGPUImageCameraNewCompositeFrameNotification
                                               object:nil];
//    [self getWaterMarkImage];
}

- (void)viewWillLayoutSubviews
{
    if (!tap)
    {
        tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(screenTap:)];
        tap.numberOfTapsRequired = 1;
        tap.delegate = self;
        [self.view addGestureRecognizer:tap];
    }
}

//- (NSUInteger)supportedInterfaceOrientations
//{
//    return  UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
//}

//- (NSUInteger)supportedInterfaceOrientations
//{
//    return  UIInterfaceOrientationMaskLandscapeRight ;
//}


- (NSUInteger)supportedInterfaceOrientations
{
    return  UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}


- (void)getWaterMarkImage
{
    [self.waterMarkImageView setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.waterMarkImageView.contentMode = UIViewContentModeScaleAspectFit;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    PhotoLayout * layout = [self getCurrentLayout];
    NSString * assetPath = [kiosk.storePath stringByAppendingPathComponent:[NSString stringWithFormat:@"Events/%@/watermark",layout.eventId]];
    // NSString *getImagePath = [documentsDirectory stringByAppendingPathComponent:layout.background];
    UIImage *image = [UIImage imageWithContentsOfFile:assetPath];
    if (!image)
    {
        //        image = self.waterMarkImageView.image;;
        //        NSData *imageData = UIImagePNGRepresentation(image);
        //        [imageData writeToFile:assetPath atomically:NO];
    }
    else
    {
        //self.waterMarkImageView.image = image;
        //  self.waterMarkImageView.backgroundColor = [UIColor redColor];
        self.waterMarkImageView.image = image;
    }
}

- (void)screenTap:(UITapGestureRecognizer *)gesture
{
    if(!self.isTestingCamera)
    {
        [self stopPhotoSession];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
  //  [self SubscriptionUpdate];

    //    recordNextCompositeFrame = FALSE;



    [cameraBtn removeFromSuperview];
    [cameraBtn setFrame:CGRectMake(self.view.frame.size.width - 60, cameraBtn.frame.origin.y, cameraBtn.frame.size.width, cameraBtn.frame.size.height)];
    [self.view addSubview:cameraBtn];
    [doneBtn setHidden:NO];
    [_btnFitToScreen setHidden:NO];
    [_lblResize setHidden:NO];

    [_settingsBtn setHidden:NO];
    if (!self.isTestingCamera)
    {

         [self getWaterMarkImage];

        [self startCamera:YES];
        [doneBtn setHidden:YES];
         [_btnFitToScreen setHidden:YES];
         [_lblResize setHidden:YES];

        [_settingsBtn setHidden:YES];
        //     [self resetPhotoShoot:nil];

        // Initialize rotated label to use for countdown.
        if (!lblInstruction)
        {
            // Roughly we want to be bottom center with width approx 250 and height approx 50.
            CGRect parentBounds = self.view.bounds;
            int ourWidth = 500;
            int ourMarginBottom = 15;
            int ourHeight = 500;
            //     CGRect ourBounds = CGRectMake((parentBounds.size.width - ourWidth) / 2, ourMarginBottom, ourWidth, ourHeight);

            CGRect ourBounds = CGRectMake((parentBounds.size.width - ourWidth) / 2,100,ourWidth, ourHeight);

            //        double rotationRads = 0;

            lblInstruction = [[UILabel alloc] initWithFrame:ourBounds];
            lblInstruction.numberOfLines = 1;
            lblInstruction.text = @"";
            lblInstruction.backgroundColor = [UIColor clearColor];
            lblInstruction.layer.cornerRadius = 10;
            lblInstruction.alpha = 0.6;
//            lblInstruction.textColor = [UIColor colorWithRed:255 green:255 blue:255 alpha:0.5];
               lblInstruction.textColor = [UIColor whiteColor];
            lblInstruction.textAlignment = NSTextAlignmentCenter;
            lblInstruction.font = [UIFont systemFontOfSize:40];
            lblInstruction.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            //        if (rotationRads != 0)
            //        {
            //            // this line will never executes as rotationRads will always be 0
            //            lblInstruction.transform = CGAffineTransformMakeRotation(rotationRads);
            //        }

            dot      =[[UIImageView alloc] initWithFrame:CGRectMake(0,(self.view.frame.size.height/2)-180,560,360)];
            dot.image=[UIImage imageNamed:@"Look at the camera icon.png"];
            [self.view addSubview:dot];

            [self.view addSubview:lblInstruction];
        }

    }
    else
    {


         [self setupInitialView];


        [self performSelector:@selector(dismissCameraOfTestSession) withObject:nil afterDelay:120];
        //        fovView = [FovSettingView newFovSettingView];
        //        fovView.frame = self.view.frame;
        //        fovView.userInteractionEnabled = YES;
        //        fovView.delegate = self;
        //        [fovView showFovValues];
        //        [self.view addSubview:fovView];
        NSUserDefaults * userdefault = [NSUserDefaults standardUserDefaults];
        // Init Camera
        filter = [[GPUImageFilter alloc] init];
        
        NSString *camMod=[userdefault objectForKey:@"cameraMode"];
        NSLog(@"CamMod is %@",camMod);
        
        
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


//
//        Croper = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.819335938, 0, 0.159179688, 0.19921875)];
//
//        [self.cameraView setFrame:CGRectMake(839,93,163,153)];


        filterView = (GPUImageView *)self.cameraView;
        [filter forceProcessingAtSize:filterView.sizeInPixels];
        [filter addTarget:filterView];
        // Begin showing video camera stream

//        [stillCamera addTarget:Croper];
//        [Croper addTarget:filterView];




       [stillCamera startCameraCapture];

    }
}


//- (void)viewWillAppear:(BOOL)animated
//{
//    [super viewWillAppear:animated];
//
//    //    recordNextCompositeFrame = FALSE;
//
//
//
//    [cameraBtn removeFromSuperview];
//    [cameraBtn setFrame:CGRectMake(self.view.frame.size.width - 60, cameraBtn.frame.origin.y, cameraBtn.frame.size.width, cameraBtn.frame.size.height)];
//    [self.view addSubview:cameraBtn];
//    [doneBtn setHidden:NO];
//    [_btnFitToScreen setHidden:NO];
//    [_lblResize setHidden:NO];
//
//    [_settingsBtn setHidden:NO];
//    if (!self.isTestingCamera)
//    {
//
//        [self getWaterMarkImage];
//
//        [self startCamera:YES];
//        [doneBtn setHidden:YES];
//        [_btnFitToScreen setHidden:YES];
//        [_lblResize setHidden:YES];
//
//        [_settingsBtn setHidden:YES];
//        //     [self resetPhotoShoot:nil];
//
//        // Initialize rotated label to use for countdown.
//        if (!lblInstruction)
//        {
//            // Roughly we want to be bottom center with width approx 250 and height approx 50.
//            CGRect parentBounds = self.view.bounds;
//            int ourWidth = 500;
//            int ourMarginBottom = 15;
//            int ourHeight = 500;
//            //     CGRect ourBounds = CGRectMake((parentBounds.size.width - ourWidth) / 2, ourMarginBottom, ourWidth, ourHeight);
//
//            CGRect ourBounds = CGRectMake((parentBounds.size.width - ourWidth) / 2,100,ourWidth, ourHeight);
//
//            //        double rotationRads = 0;
//
//            lblInstruction = [[UILabel alloc] initWithFrame:ourBounds];
//            lblInstruction.numberOfLines = 1;
//            lblInstruction.text = @"";
//            lblInstruction.backgroundColor = [UIColor clearColor];
//            lblInstruction.layer.cornerRadius = 10;
//            lblInstruction.alpha = 0.6;
//            //            lblInstruction.textColor = [UIColor colorWithRed:255 green:255 blue:255 alpha:0.5];
//            lblInstruction.textColor = [UIColor whiteColor];
//            lblInstruction.textAlignment = NSTextAlignmentCenter;
//            lblInstruction.font = [UIFont systemFontOfSize:40];
//            lblInstruction.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
//            //        if (rotationRads != 0)
//            //        {
//            //            // this line will never executes as rotationRads will always be 0
//            //            lblInstruction.transform = CGAffineTransformMakeRotation(rotationRads);
//            //        }
//
//            dot      =[[UIImageView alloc] initWithFrame:CGRectMake(0,(self.view.frame.size.height/2)-180,560,360)];
//            dot.image=[UIImage imageNamed:@"Look at the camera icon.png"];
//            [self.view addSubview:dot];
//
//            [self.view addSubview:lblInstruction];
//        }
//
//    }
//    else
//    {
//
//
//        [self setupInitialView];
//
//
//        [self performSelector:@selector(dismissCameraOfTestSession) withObject:nil afterDelay:120];
//        //        fovView = [FovSettingView newFovSettingView];
//        //        fovView.frame = self.view.frame;
//        //        fovView.userInteractionEnabled = YES;
//        //        fovView.delegate = self;
//        //        [fovView showFovValues];
//        //        [self.view addSubview:fovView];
//        NSUserDefaults * userdefault = [NSUserDefaults standardUserDefaults];
//        // Init Camera
//        filter = [[GPUImageFilter alloc] init];
//        if ([[userdefault objectForKey:@"cameraMode"] isEqualToString:@"Front"] || [userdefault objectForKey:@"cameraMode"] == nil) {
//            stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionFront];
//        }
//        else
//        {
//            stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionBack];
//        }
//        stillCamera.outputImageOrientation = [self interfaceOrientation];
//        stillCamera.horizontallyMirrorFrontFacingCamera = NO;
//        stillCamera.horizontallyMirrorRearFacingCamera = NO;
//        // Create custom GPUImage camera
//        [stillCamera addTarget:filter];
//
//
//
//        UIImageView * tempview = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"image-8.png"]];
//        tempview.backgroundColor = [UIColor clearColor];
//        [self.view addSubview:tempview];
//        UIImage * newimage1 = [self captureView:tempview withArea:tempview.frame];
//        [tempview removeFromSuperview];
//        NSLog(@"newimage1 %f %f", newimage1.size.height,newimage1.size.width);
//
//
//        sourcePicture = [[GPUImagePicture alloc] initWithImage:newimage1 smoothlyScaleOutput:YES];
//        [sourcePicture addTarget:filter];
//        [sourcePicture processImage];
//
//        [self.mainCameraView setFrame:CGRectMake( 0, 0, self.view.frame.size.width, self.view.frame.size.height)];
//        [self.cameraView setFrame:maskFrame];
//        filterView = (GPUImageView *)self.cameraView;
//
//        filterView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
//        GPUImageSobelEdgeDetectionFilter *edgeFilter = [[GPUImageSobelEdgeDetectionFilter alloc] init];
//
//
//
//        GPUImageColorMatrixFilter *conversionFilter = [[GPUImageColorMatrixFilter alloc] init];
//        conversionFilter.colorMatrix = (GPUMatrix4x4){
//            {0.0, 0.0, 0.0, 1.0},
//            {0.0, 0.0, 0.0, 1.0},
//            {0.0, 0.0, 0.0, 1.0},
//            {1.0,0.0,0.0,0.0},
//        };
//
//        //    [sourcePicture addTarget:edgeFilter];
//        [edgeFilter addTarget:conversionFilter];
//
//        Croper = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0, 0, 1, 1)];
//        [filter addTarget:Croper];
//
//        transformLive = [GPUImageTransformFilter new];
//        //    [self.transformFilter forceProcessingAtSize:backSize];
//        [transformLive setAffineTransform:CGAffineTransformIdentity];
//        [transformLive setBackgroundColorRed:0.000 green:0.000 blue:0.000 alpha:0.000];
//        [Croper addTarget:transformLive];
//
//
//        [self.cameraView setFrame:CGRectMake(self.cameraView.frame.origin.x, self.cameraView.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height)];
//
//
//        //
//        //        Croper = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.819335938, 0, 0.159179688, 0.19921875)];
//        //
//        //        [self.cameraView setFrame:CGRectMake(839,93,163,153)];
//
//        [filterView setBackgroundColorRed:0 green:0 blue:0 alpha:0];
//        filterView.backgroundColor = [UIColor clearColor];
//        [Croper addTarget:filterView];
//
//
//        [Croper forceProcessingAtSize:filterView.sizeInPixels];
//
//
////        filterView = (GPUImageView *)self.cameraView;
////        [filter forceProcessingAtSize:filterView.sizeInPixels];
////        [filter addTarget:filterView];
//        // Begin showing video camera stream
//
//        //        [stillCamera addTarget:Croper];
//        //        [Croper addTarget:filterView];
//
//
//
//
//        [stillCamera startCameraCapture];
//
//    }
//}
//
//




- (void)dismissCameraOfTestSession
{
    [self dismissViewControllerAnimated:YES completion: nil];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        //        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        [self dismissViewControllerAnimated:YES completion: nil];
        
    }
}

- (void)startCameraWithTimer
{
    self.isTestingCamera = NO;
    [fovView removeFromSuperview];
    [self resetPhotoShoot:nil];
    
    // Initialize rotated label to use for countdown.
    if (!lblInstruction)
    {
        // Roughly we want to be bottom center with width approx 250 and height approx 50.
        CGRect parentBounds = self.view.bounds;
        int ourWidth = 330;
        int ourMarginBottom = 15;
        int ourHeight = 45;
        CGRect ourBounds = CGRectMake((parentBounds.size.width - ourWidth) / 2, ourMarginBottom, ourWidth, ourHeight);
        //        double rotationRads = 0;
        
        lblInstruction = [[UILabel alloc] initWithFrame:ourBounds];
        lblInstruction.numberOfLines = 1;
        lblInstruction.text = @"";
        lblInstruction.backgroundColor = [UIColor clearColor];
        lblInstruction.layer.cornerRadius = 10;
        lblInstruction.alpha = 0.6;

      //  lblInstruction.textColor = [UIColor colorWithRed:255 green:255 blue:255 alpha:0.5];
           lblInstruction.textColor = [UIColor whiteColor];
        lblInstruction.textAlignment = NSTextAlignmentCenter;
        lblInstruction.font = [UIFont systemFontOfSize:40];
        lblInstruction.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        //        if (rotationRads != 0)
        //        {
        //            // this line will never executes as rotationRads will always be 0
        //            lblInstruction.transform = CGAffineTransformMakeRotation(rotationRads);
        //        }
        
        
        
        [self.view addSubview:lblInstruction];
        
        
        //     CGRect yourBounds = CGRectMake((parentBounds.size.width - ourWidth) / 2, 100, ourWidth, ourHeight);
        
        
        
    }
    
}

- (void)updateFovValuesOnCamera
{
    // [self setUp];
    [self ApplyFovAndPositionToCamera];
}

#pragma mark - Start Camera Method

- (void)startCamera:(BOOL)isBackCamera
{
    
    // Init Camera
    self.cameraView.backgroundColor = [UIColor clearColor];
    self.tempBg.backgroundColor = [UIColor clearColor];
    
    // For mirroring of camera rotate 180 degree
    
    if (([[[NSUserDefaults standardUserDefaults] valueForKey:@"Mirror Effect"] isEqualToString:@"Yes"])||([[[NSUserDefaults standardUserDefaults] valueForKey:@"Mirror Effect"]length ] == 0))
    {
        // self.baseView.layer.affineTransform = CATransform3DGetAffineTransform(CATransform3DConcat(self.baseView.layer.transform,CATransform3DMakeRotation(M_PI, 0.0, 1.0, 0.0f)));
    }
    
 
    
    
    // color pixel having highest value will be replaced with the filter with pixel value , be default green will be replaced
    NSArray * rgbColorComponent = [[NSUserDefaults standardUserDefaults]objectForKey:SERVER_RGB_CONFIGURATION];
    
    NSString * rComponent = @"0";
    NSString * gComponent = @"0";
    NSString * bComponent = @"0";
    
    NSMutableArray * components = [[NSMutableArray alloc]initWithObjects:rComponent, gComponent,bComponent, nil];
    
    if([rgbColorComponent count] > 0)
    {
        NSInteger r = [rgbColorComponent[0]integerValue];
        NSInteger g = [rgbColorComponent[1]integerValue];
        NSInteger b = [rgbColorComponent[2]integerValue];
        
        NSInteger max = MAX3(r, g, b);
        NSInteger index = [rgbColorComponent indexOfObject:[NSString stringWithFormat:@"%ld",(long)max]];
        
        max = 255;
        [components replaceObjectAtIndex:index withObject:[NSString stringWithFormat:@"%ld",(long)max]];
        
        //            gComponent = @"255";
        //            [components replaceObjectAtIndex:1 withObject:gComponent];
    }
    else
    {
        gComponent = @"255";
        [components replaceObjectAtIndex:1 withObject:gComponent];
    }
    
    
    filter = [[GPUImageChromaKeyBlendFilter alloc] init];
    [(GPUImageChromaKeyBlendFilter *)filter setSmoothing:0.07];
    [(GPUImageChromaKeyBlendFilter *)filter setColorToReplaceRed:[components[0] floatValue]/255.0 green:[components[1] floatValue]/255.0 blue:[components[2] floatValue]/255.0];
    [(GPUImageChromaKeyBlendFilter *)filter setThresholdSensitivity:0.43];
    [(GPUImageChromaKeyBlendFilter *)filter setBackgroundColorRed:0.0 green:1.0 blue:0.0 alpha:1.0];

    [filter useNextFrameForImageCapture];
    //[filter setInputRotation:kGPUImageRotate180 atIndex:0];
    
    NSUserDefaults * userdefault = [NSUserDefaults standardUserDefaults];
    
    if ([[userdefault objectForKey:@"cameraMode"] isEqualToString:@"Front"] || [userdefault objectForKey:@"cameraMode"] == nil) {
     //   stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionFront];
        
        
        stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetPhoto cameraPosition:AVCaptureDevicePositionFront];
    }
    else
    {
     //  stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionBack];
        
         stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetPhoto cameraPosition:AVCaptureDevicePositionBack];
        
        
    }
    stillCamera.delegate = self;
    stillCamera.outputImageOrientation = [self interfaceOrientation];
    stillCamera.horizontallyMirrorFrontFacingCamera = NO;
    stillCamera.horizontallyMirrorRearFacingCamera = NO;
    [stillCamera addTarget:filter];
    
    
    
    [self setUp];
    
   
    self.mainCameraView.backgroundColor = [UIColor clearColor];
    
    // For image rotation effect implementation
    UIImageView * tempview = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"image-8.png"]];
    tempview.backgroundColor = [UIColor clearColor];
    [self.view addSubview:tempview];
    UIImage * newimage1 = [self captureView:tempview withArea:tempview.frame];
    [tempview removeFromSuperview];
    NSLog(@"newimage1 %f %f", newimage1.size.height,newimage1.size.width);
    
  
    
       CGRect newFrame6 = CGRectMake( _cameraView.frame.origin.x, _cameraView.frame.origin.y, _cameraView.frame.size.width, _cameraView.frame.size.height);
    
    
    CGRect newFrame7 =self.tempBg.frame;
    
    CGRect rect = CGRectMake(0, 93, 1024, 580);
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSData *data = [userDefaults objectForKey:@"mainFrameRect"];
    
    NSValue *val1=[NSKeyedUnarchiver unarchiveObjectWithData:data];;
    
    CGRect cropervalue=[val1 CGRectValue];
    
    NSData *data1 = [userDefaults objectForKey:@"croperRect"];
    
    NSValue *val2=[NSKeyedUnarchiver unarchiveObjectWithData:data1];;
    
    CGRect transformvalue=[val2 CGRectValue];
    

    // croperRect
    
    if(data1==nil)
    {
        transformvalue=CGRectMake(0, 0, 1, 1);
    }

    sourcePicture = [[GPUImagePicture alloc] initWithImage:newimage1 smoothlyScaleOutput:YES];
    [sourcePicture addTarget:filter];
    [sourcePicture processImage];
    
    
//    CGRect transValue=[self croperValue:CGRectMake(_cameraView.frame.origin.x, _cameraView.frame.origin.y, _cameraView.frame.size.width, _cameraView.frame.size.width)];
    
    
   //    Croper = [[GPUImageCropFilter alloc] initWithCropRegion:transformvalue];
    
    float widthnew=transformvalue.size.width;
    float heightnew=transformvalue.size.height;
    
    widthnew=widthnew*newFrame6.size.width;
    heightnew=heightnew*newFrame6.size.height;
    
//            Croper = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.5,0.5,0.5,0.5)];
//
//        //    [self.cameraView setFrame:CGRectMake(839,93,163,153)];
//
//
 //    [self.cameraView setFrame:CGRectMake( 100, 100, 100, 100)];
    
   
    if(data==nil)
    {
        cropervalue=rect;
    }

    
    if (CGRectEqualToRect(cropervalue, rect)) {
        
        NSLog(@"Success");
//        [self.mainCameraView setFrame:CGRectMake( 0, 0, 1024, 768)];
        
          [self.mainCameraView setFrame:CGRectMake( 0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        [self.cameraView setFrame:maskFrame];
         filterView = (GPUImageView *)self.cameraView;
        
        
   //       filterView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
        
        GPUImageSobelEdgeDetectionFilter *edgeFilter = [[GPUImageSobelEdgeDetectionFilter alloc] init];
        
        GPUImageColorMatrixFilter *conversionFilter = [[GPUImageColorMatrixFilter alloc] init];
        conversionFilter.colorMatrix = (GPUMatrix4x4){
            {0.0, 0.0, 0.0, 1.0},
            {0.0, 0.0, 0.0, 1.0},
            {0.0, 0.0, 0.0, 1.0},
            {1.0,0.0,0.0,0.0},
        };
        
        //    [sourcePicture addTarget:edgeFilter];
        [edgeFilter addTarget:conversionFilter];
        
        
//         [filter forceProcessingAtSize:filterView.sizeInPixels];
//        [filter addTarget:filterView];
        
        Croper = [[GPUImageCropFilter alloc] initWithCropRegion:transformvalue];
        [filter addTarget:Croper];
        
        transformLive = [GPUImageTransformFilter new];
        //    [self.transformFilter forceProcessingAtSize:backSize];
        [transformLive setAffineTransform:CGAffineTransformIdentity];
        [transformLive setBackgroundColorRed:0.000 green:0.000 blue:0.000 alpha:0.000];
        [Croper addTarget:transformLive];
        
        
        //        filteredVideoView = [[GPUImageView alloc] initWithFrame:_viewPlayerCamera.frame];
        [filterView setBackgroundColorRed:0 green:0 blue:0 alpha:0];
        filterView.backgroundColor = [UIColor clearColor];
        [Croper addTarget:filterView];
        
        
        [Croper forceProcessingAtSize:filterView.sizeInPixels];
        
        
        
        // do some stuff
    }else
    {
        
//         [self.cameraView setFrame:cropervalue];
        
        float wid,hei,hh;
        wid=self.view.frame.size.width;
        
        if(wid>1024)
        {
            hei=121.0f;
            hh=self.view.frame.size.height-242;
            
        }else
        {
            hei=93.0f;
            hh=580.0f;
            
            //hh=self.view.frame.size.height-186;
        }
        
        
        
        
        float x,y,width,height;
        x=cropervalue.origin.x/self.view.frame.size.width;
        x=x*maskFrame.size.width;
        x=x+maskFrame.origin.x;
        
        float diff=cropervalue.origin.y-hei;
        
//        y=cropervalue.origin.y/self.view.frame.size.height;
         y=diff/hh;
        y=y*maskFrame.size.height;
        y=y+maskFrame.origin.y;
       //y=y-45;
        
        width=cropervalue.size.width/self.view.frame.size.width;
        width=width*maskFrame.size.width;
        
        height=cropervalue.size.height/hh;
        height=height*maskFrame.size.height;
        
        
        cropervalue=CGRectMake(x, y, width,height);
        
        
        
        
        
          [self.mainCameraView setFrame:CGRectMake( 0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        
//         [self.mainCameraView setFrame:CGRectMake( 0, 0, 1024, 768)];
         [self.cameraView setFrame:cropervalue];
         filterView = (GPUImageView *)self.cameraView;
        // [filter forceProcessingAtSize:filterView.sizeInPixels];
        
        
    //      filterView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
        
        NSLog(@"initial values %@", NSStringFromCGRect(filterView.frame));
        
        
        
        // Input image (replace the green background)
//        UIImage *inputImage;
//        UIImage *TempinputImage = [UIImage imageNamed:@"BackgroundTransperant"];
//        inputImage = [self imageByScalingProportionallyToSize:self.cameraView.frame.size resizeImage:TempinputImage];
//        sourcePicture = [[GPUImagePicture alloc] initWithImage:inputImage smoothlyScaleOutput:YES];
        
        GPUImageSobelEdgeDetectionFilter *edgeFilter = [[GPUImageSobelEdgeDetectionFilter alloc] init];
        
        GPUImageColorMatrixFilter *conversionFilter = [[GPUImageColorMatrixFilter alloc] init];
        conversionFilter.colorMatrix = (GPUMatrix4x4){
            {0.0, 0.0, 0.0, 1.0},
            {0.0, 0.0, 0.0, 1.0},
            {0.0, 0.0, 0.0, 1.0},
            {1.0,0.0,0.0,0.0},
        };
        
    //    [sourcePicture addTarget:edgeFilter];
        [edgeFilter addTarget:conversionFilter];
        
        
        Croper = [[GPUImageCropFilter alloc] initWithCropRegion:transformvalue];
        [filter addTarget:Croper];
        
        transformLive = [GPUImageTransformFilter new];
        //    [self.transformFilter forceProcessingAtSize:backSize];
        [transformLive setAffineTransform:CGAffineTransformIdentity];
        [transformLive setBackgroundColorRed:0.000 green:0.000 blue:0.000 alpha:0.000];
        [Croper addTarget:transformLive];
        
        
//        filteredVideoView = [[GPUImageView alloc] initWithFrame:_viewPlayerCamera.frame];
        [filterView setBackgroundColorRed:0 green:0 blue:0 alpha:0];
        filterView.backgroundColor = [UIColor clearColor];
        [Croper addTarget:filterView];
        
        
        [Croper forceProcessingAtSize:filterView.sizeInPixels];
        
        
     //  [filter forceProcessingAtSize:filterView.sizeInPixels];
//        [filter addTarget:Croper];
//        [Croper addTarget:filterView];
        
     //   filterView.fillMode = kGPUImageFillModeStretch;
        NSLog(@"final values %@", NSStringFromCGRect(filterView.frame));
        
//        [stillCamera addTarget:Croper];
//                [Croper addTarget:filterView];
        
        
    }
    
 //   filterView = (GPUImageView *)self.cameraView;
//    [filter forceProcessingAtSize:filterView.sizeInPixels];
//    [filter addTarget:filterView];
    
    
//            [filter addTarget:Croper];
//            [Croper addTarget:filterView];
    
    
    
//    if (CGRectEqualToRect(_mainFrameRect, rect)) {
//
//        NSLog(@"Successfully executed");
//
//
//        // do some stuff
//    }
//    else
//    {
//         NSLog(@"Failure executed");
//    }
    
    
    
    [stillCamera startCameraCapture];
    
    [self.view bringSubviewToFront:cameraBtn];
    
}


- (UIImage *)getRotatedImage:(UIImage *)initialImage
{
    UIImage * flippedImage = [UIImage imageWithCGImage:initialImage.CGImage
                                                 scale:initialImage.scale
                                           orientation:UIImageOrientationUpMirrored];
    
    return flippedImage;
}

#pragma mark - Capture View Screenshot Method

-(UIImage *)captureView:(UIImageView *)view withArea:(CGRect)screenRect
{
    UIGraphicsBeginImageContext(screenRect.size);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[UIColor clearColor] set];
    CGContextFillRect(ctx, screenRect);
    
    [view.layer renderInContext:ctx];
    
    UIImage * newImage = newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (void)stopCamera
{
    if (shotsRemaining == 0)
    {
        //  [[NSNotificationCenter defaultCenter] postNotificationName:@"Address Found" object:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AllImagesClickedNotification" object:nil];
        
    }
    if(countdownTimer)
    {
        [countdownTimer invalidate];
        countdownTimer = nil;
    }
    [stillCamera stopCameraCapture];
    
    [stillCamera removeAllTargets];
    
    stillCamera = nil;
}

#pragma mark - SetUp Background Layout  Method

-(void)setUp
{
    // Determine the photo layout to use for the background.
    
    
    PhotoLayout * layout = [self getCurrentLayout];
    // Set a background image.
    // Presently the background MUST be cleared out before we setup GL.
    NSString * backgroundFileName = nil;
    
    
    
    
    //    [self.bgImage setFrame:CGRectMake(self.bgImage.frame.origin.x, self.bgImage.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height)];
    
    self.bgImage.frame = CGRectMake(self.bgImage.frame.origin.x, self.bgImage.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
    
    
    //    [faddedImage setFrame:CGRectMake(faddedImage.frame.origin.x, faddedImage.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height)];
    
    faddedImage.frame = CGRectMake(faddedImage.frame.origin.x, faddedImage.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
    
    
    //     [self.croppedBgFrame setFrame:CGRectMake(self.croppedBgFrame.frame.origin.x, self.croppedBgFrame.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height)];
    
    self.croppedBgFrame.frame = CGRectMake(self.croppedBgFrame.frame.origin.x, self.croppedBgFrame.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
    
    
    self.tempBg.frame = CGRectMake(self.tempBg.frame.origin.x, self.tempBg.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
    
    [self.view layoutIfNeeded];
    [self ApplyFovAndPositionToCamera];
    
    
    if (_isTestingCamera) {
        NSFetchRequest * request = [[NSFetchRequest alloc] init];
        NSEntityDescription * entity = [NSEntityDescription
                                        entityForName:@"PhotoLayout"
                                        inManagedObjectContext:store.currentMOC];
        [request setEntity:entity];
        NSPredicate * predicate = [NSPredicate
                                   predicateWithFormat:@"eventId == %@", kiosk.eventId];
        
        [request setPredicate:predicate];
        NSError * error;
        NSArray * results = [store.currentMOC executeFetchRequest:request
                                                            error:&error];
        if ([results count] > 0)
        {
            layout = results[0];
        }
        
    }
    
    if (layout)
    {
        backgroundFileName = layout.background;
       
    }
    else
    {
        NSLog(@"No default layout set for the Kiosk. Reverting to hard coded default layout1.jpg");
        backgroundFileName = @"layout1.jpg";
    }
    
    NSString * backgroundUrl = [kiosk.storePath stringByAppendingPathComponent:backgroundFileName];
    UIImage * backgroundImage = [UIImage imageWithContentsOfFile:backgroundUrl];
    if (!backgroundImage)
    {
        
        backgroundImage = [UIImage imageNamed:@""];
        
        
       
    }
    
    
    
    UIImage * maskImage = nil;
    if (layout)
    {
        if (layout.foreground.length>0)
        {
            NSString * foregroundUrl = [kiosk.storePath stringByAppendingPathComponent:layout.foreground];
            maskImage = [UIImage imageWithContentsOfFile:foregroundUrl];
            if (isTestSession)
            {
                maskImage = nil;
            }
        }
        else
        {
            //            maskImage = [UIImage imageNamed:@"transparent.jpg"];
        }
    }
    
    UIImage * maskedImage;
    self.bgImage.image = backgroundImage;
    
    if (1)
    {
        //Mask is coming from server
        maskedImage = [self maskImage:backgroundImage withMask:maskImage];
        if (!maskImage)
        {
            maskedImage = nil;
        }
        faddedImage.backgroundColor = [UIColor clearColor];
        
        faddedImage.hidden = YES;
        self.croppedBgFrame.backgroundColor = [UIColor blackColor];
        UIImage *customMask = [self getMaskImage];
        self.croppedBgFrame.backgroundColor = [UIColor clearColor];
    //    self.croppedBgFrame.backgroundColor = [UIColor redColor];
        customMask = [self imageResize:customMask andResizeTo:faddedImage.frame.size];
        UIImage *customMaskImage = [self maskImage:backgroundImage withMask:customMask];
        //        faddedImage.image = customMaskImage;
        //        self.croppedBgFrame.frame = faddedImage.frame;
        
        
        
      //  UIImage *customMaskImage = [UIImage imageNamed:@"image.png"];
//        UIImage *watermarkImage = [UIImage imageNamed:@"example.png"];
//
//
//
//        UIGraphicsBeginImageContext(customMaskImage.size);
//        [customMaskImage drawInRect:CGRectMake(0, 0, customMaskImage.size.width, customMaskImage.size.height)];
//        [watermarkImage drawInRect:CGRectMake(0, 0, customMaskImage.size.width, customMaskImage.size.height)];
//        customMaskImage = UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();
        
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        NSString * subId = [defaults stringForKey:@"subscriptionType"];
        
        if ([subId integerValue] == 1)
        {
            
//            UIImage *watermarkImage = [UIImage imageNamed:@"example.png"];
            
               UIImage *watermarkImage = [UIImage imageNamed:@"iAmuse-Watermark.png"];
            
            UIGraphicsBeginImageContext(customMaskImage.size);
            [customMaskImage drawInRect:CGRectMake(0, 0, customMaskImage.size.width, customMaskImage.size.height)];
            [watermarkImage drawInRect:CGRectMake(0, 0, customMaskImage.size.width, customMaskImage.size.height)];
            customMaskImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
        }
        
        
        
        
    //    NSLog(@"result is %@",result);
        
        
        
        
        self.croppedBgFrame.image = customMaskImage;
        faddedImage.image = maskedImage;
        faddedImage.hidden = NO;
        
        
    }
    else
    {
        
        //Custom mask creation
        self.croppedBgFrame.backgroundColor = [UIColor blackColor];
        UIImage *customMask = [self getMaskImage];
        self.croppedBgFrame.backgroundColor = [UIColor clearColor];
        customMask = [self imageResize:customMask andResizeTo:backgroundImage.size];
        UIImage *customMaskImage = [self maskImage:backgroundImage withMask:customMask];
        //        faddedImage.image = customMaskImage;
        self.croppedBgFrame.image = customMaskImage;
    }
}

- (UIImage *)getMaskImage
{
    
    //maskFrame=CGRectMake(235, 108, 108,140);
    
    
    
    float wid,hei,hh;
    wid=self.view.frame.size.width;
    //  hh=self.view.frame.size.height-186;
    
    if(wid>1024)
    {
        hei=121.0f;
        hh=self.view.frame.size.height-242;
        
    }else
    {
        hei=93.0f;
        hh=580.0f;
        
        //hh=self.view.frame.size.height-186;
    }
    
    CGRect rectangleVAlue;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSData *data = [userDefaults objectForKey:@"mainFrameRect"];
    
    NSValue *val1=[NSKeyedUnarchiver unarchiveObjectWithData:data];;
    
    CGRect cropervalue=[val1 CGRectValue];
    
    CGRect webValues=maskFrame;
    float x,y,width,height;
    x=cropervalue.origin.x/self.view.frame.size.width;
    x=x*maskFrame.size.width;
    x=x+maskFrame.origin.x;
    
    
    float diff=cropervalue.origin.y-hei;
    
//    y=cropervalue.origin.y/self.view.frame.size.height;
     y=diff/hh;
    y=y*maskFrame.size.height;
    y=y+maskFrame.origin.y;
  //  y=y-45;
    
    width=cropervalue.size.width/self.view.frame.size.width;
    width=width*maskFrame.size.width;
    
    
    
    height=cropervalue.size.height/hh;
    height=height*maskFrame.size.height;
    
     CGRect rect = CGRectMake(0, 93, 1024, 580);
    if(data==nil)
    {
        cropervalue=rect;
    }
    
     if (CGRectEqualToRect(cropervalue, rect)) {
         
         rectangleVAlue=maskFrame;
     }
    else
    {
        rectangleVAlue=CGRectMake(x, y, width,height);
    }
    
   // cropervalue=CGRectMake(x, maskFrame.origin.y, width,height);
    UIImageView *whiteView = [[UIImageView alloc]initWithFrame:rectangleVAlue];
    //    self.mainCameraView.transform = CGAffineTransformScale(CGAffineTransformIdentity, scalefactor, scalefactor);
    
    
    
    
  // whiteView.backgroundColor = [UIColor redColor];
    
    whiteView.backgroundColor = [UIColor whiteColor];
    [self.croppedBgFrame addSubview:whiteView];
    
    UIGraphicsBeginImageContext(self.croppedBgFrame.frame.size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [self.croppedBgFrame.layer renderInContext:ctx];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [whiteView removeFromSuperview];
    
    return newImage;
}

- (UIImage *)imageResize :(UIImage*)img andResizeTo:(CGSize)newSize
{
    CGFloat scale = [[UIScreen mainScreen]scale];
    /*You can remove the below comment if you dont want to scale the image in retina   device .Dont forget to comment UIGraphicsBeginImageContextWithOptions*/
    //UIGraphicsBeginImageContext(newSize);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, scale);
    [img drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
   
    
    return newImage;
}

- (BOOL)ApplyFovAndPositionToCamera
{
    PhotoLayout *layout = [self getCurrentLayout];
    if (_isTestingCamera) {
        NSFetchRequest * request = [[NSFetchRequest alloc] init];
        NSEntityDescription * entity = [NSEntityDescription
                                        entityForName:@"PhotoLayout"
                                        inManagedObjectContext:store.currentMOC];
        [request setEntity:entity];
        NSPredicate * predicate = [NSPredicate
                                   predicateWithFormat:@"eventId == %@", kiosk.eventId];
        
        [request setPredicate:predicate];
        NSError * error;
        NSArray * results = [store.currentMOC executeFetchRequest:request
                                                            error:&error];
        if ([results count] > 0)
        {
            layout = results[0];
        }
        
    }
    CGFloat xOffset = [layout.xOffset floatValue];
    CGFloat yOffset = [layout.yOffset floatValue];
    //xOffset = 0;
    //yOffset = 0;
    NSLog(@"%@",layout.scale);
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    
    float leftPercent = [defaults floatForKey:FOV_CURTAIN_KEY_LEFT];     // %
    float rightPercent = [defaults floatForKey:FOV_CURTAIN_KEY_RIGHT];   // %
    float topPercent = [defaults floatForKey:FOV_CURTAIN_KEY_TOP];       // %
    float bottomPercent = [defaults floatForKey:FOV_CURTAIN_KEY_BOTTOM]; // %
    
    
    
    //    [self.mainCameraView setFrame:CGRectMake(0, 0, self.bgImage.frame.size.width, self.bgImage.frame.size.height)];
    float leftFOV = (leftPercent * self.mainCameraView.frame.size.width) / 100;
    float rightFOV = (rightPercent * self.mainCameraView.frame.size.width) / 100;
    float topFOV = (topPercent * self.mainCameraView.frame.size.height) / 100;
    float bottomFOV = (bottomPercent * self.mainCameraView.frame.size.height) / 100;
    
    
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"Position"] isEqualToString:@"No"])
    {
        xOffset = 0.0;
        yOffset = 0.0;
    }
    
  
    
    
    
    CGRect frame1 = CGRectMake(rightFOV + self.mainCameraView.frame.origin.x, topFOV + self.mainCameraView.frame.origin.y, self.mainCameraView.frame.size.width - (leftFOV + rightFOV), self.mainCameraView.frame.size.height - (topFOV + bottomFOV));
    
    frame1.origin.x = (frame1.origin.x + ((self.bgImage.frame.size.width * xOffset) / 100));
    frame1.origin.y = (frame1.origin.y - ((self.bgImage.frame.size.height * yOffset) / 100));
    
   
    maskFrame = CGRectMake(0, 0, 0, 0);
    if ([layout.foreground length] > 0)
    {
        maskFrame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    }
    
    
    
    
    CGRect frame = self.mainCameraView.frame;
    frame.origin.x = (frame.origin.x + ((self.bgImage.frame.size.width * xOffset) / 100));
    frame.origin.y = (frame.origin.y - ((self.bgImage.frame.size.height * yOffset) / 100));
    self.mainCameraView.frame = frame;
    
    //Do here
    CGRect frame2 = self.mainCameraView.frame;
    frame2.origin.x = xOffset;
    frame2.origin.y = yOffset;
    frame2.size.width = [layout.cameraWidth floatValue];
    frame2.size.height = [layout.cameraHieght floatValue];
    
    
    maskFrame = frame2;
    
    
    CGFloat factor = self.mainCameraView.frame.size.width / self.view.frame.size.width;
    
    
    self.mainCameraView.frame = frame2;
    CGPoint center = self.mainCameraView.center;
    
    
    
    [self.mainCameraView setFrame:CGRectMake(maskFrame.origin.x, maskFrame.origin.y, self.mainCameraView.frame.size.width, self.mainCameraView.frame.size.height)];
    
    
    
    leftFOV = (leftPercent * self.cameraView.frame.size.width) / 100;
    rightFOV = (rightPercent * self.cameraView.frame.size.width) / 100;
    topFOV = (topPercent * self.cameraView.frame.size.height) / 100;
    bottomFOV = (bottomPercent * self.cameraView.frame.size.height) / 100;
    
    
    
    CGFloat width = self.cameraView.frame.size.width - (leftFOV + rightFOV);
    CGFloat height = self.cameraView.frame.size.height - (topFOV + bottomFOV);
    
    CGFloat fac = maskFrame.size.width / width;
    CGFloat hei = maskFrame.size.height / height;
    
    
    
    if (fac > hei)
    {
        [self.mainCameraView setFrame:CGRectMake(0, 0, self.cameraView.frame.size.width*fac , self.cameraView.frame.size.height*fac )];
        
    }
    else
    {
        [self.mainCameraView setFrame:CGRectMake(0, 0, self.cameraView.frame.size.width*hei , self.cameraView.frame.size.height*hei)];
        
    }
    
    
    
    
    self.cameraView.center = CGPointMake(self.mainCameraView.frame.size.width / 2, self.mainCameraView.frame.size.height / 2);
    
    
    

    if (fac > hei)
    {
       
      //  self.cameraView.transform = CGAffineTransformScale(CGAffineTransformIdentity, fac,fac);
        
    }
    else
    {
        
     //   self.cameraView.transform = CGAffineTransformScale(CGAffineTransformIdentity, hei, hei);
        
    }


    [self.cameraView setFrame:CGRectMake(0, 0, self.mainCameraView.frame.size.width, self.mainCameraView.frame.size.height)];
    
    
    
    leftFOV = (leftPercent * self.cameraView.frame.size.width) / 100;
    rightFOV = (rightPercent * self.cameraView.frame.size.width) / 100;
    topFOV = (topPercent * self.cameraView.frame.size.height) / 100;
    bottomFOV = (bottomPercent * self.cameraView.frame.size.height) / 100;
    
    
    CGRect fovFrame = CGRectMake(leftFOV, topFOV, self.cameraView.frame.size.width - (leftFOV + rightFOV), self.cameraView.frame.size.height - (topFOV + bottomFOV));
    
    CGPoint fovCenter = CGPointMake(fovFrame.origin.x + (fovFrame.size.width / 2), fovFrame.origin.y + (fovFrame.size.height / 2));
    
    
    
    [self.mainCameraView setFrame:CGRectMake((maskFrame.origin.x + (maskFrame.size.width / 2)) - fovCenter.x, (maskFrame.origin.y + (maskFrame.size.height / 2)) - fovCenter.y, self.mainCameraView.frame.size.width, self.mainCameraView.frame.size.height)];
    
    
    
    
    if (layout.xOffset)
    {
        
    }
    else
    {
        
        [self.view makeToast:@"Full screen camera feed. Please configure this background on admin portal to use customized camera feed"];
        
        return NO;
    }
    
    return YES;
    
    
}



- (UIImage *)maskImage:(UIImage *)image withMask:(UIImage *)maskImage
{
    CGImageRef maskRef = maskImage.CGImage;
    
    mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                             CGImageGetHeight(maskRef),
                             CGImageGetBitsPerComponent(maskRef),
                             CGImageGetBitsPerPixel(maskRef),
                             CGImageGetBytesPerRow(maskRef),
                             CGImageGetDataProvider(maskRef), NULL, false);
    
    masked = CGImageCreateWithMask([image CGImage], mask);
    //    CFRelease(mask);
    UIImage *img = [UIImage imageWithCGImage:masked];
    //    CGImageRelease(maskRef);
    CGImageRelease(mask);
    CGImageRelease(masked);
    
    mask = nil;
    masked = nil;
    //    PhotoLayout *layout = [self getCurrentLayout];
    //    if ([layout.foreground length] == 0)
    //    {
    //        return nil;
    //    }
    
    return img;
}

- (UIImage *)rotateLayoutImage:(UIImage *)layoutImage orientation:(UIImageOrientation)imageOrientation
{
    UIGraphicsBeginImageContext(layoutImage.size);
    CGContextRef cgContext = UIGraphicsGetCurrentContext();
    
    float width = layoutImage.size.width;
    float height = layoutImage.size.height;
    CGAffineTransform flipVertical;
    
    switch (imageOrientation)
    {
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
    UIImage * rotatedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return rotatedImage;
}

#pragma mark - Get Current Layout  Method

- (PhotoLayout *)getCurrentLayout
{
    [kiosk loadPhotoLayouts:kiosk.eventId];
    PhotoLayout * currentLayout = nil;
    if (kiosk.currentPhotoSession && kiosk.currentPhotoSession.entity)
    {
        currentLayout = kiosk.currentPhotoSession.entity.layout;
    }
    else
    {
        // We might not have a session setup yet, so use the default layout for the kiosk.
        if (kiosk.entity && kiosk.entity.defaultLayout)
        {
            NSLog(@"Using default kiosk photo layout.");
            currentLayout = kiosk.entity.defaultLayout;
            isTestSession = YES;
        }
        else
        {
            if ([kiosk.photoLayouts count] == 0) {
                [kiosk loadPhotoLayouts:kiosk.eventId];
            }
            currentLayout = [kiosk.photoLayouts firstObject];
            isTestSession = YES;
        }
    }
    if (currentLayout)
    {
        currentScale = [currentLayout.scale floatValue];
        if (currentScale == 0)
        {
            currentScale = 1.0;
        }
        currentXOffset = [currentLayout.xOffset floatValue] / 100;
        currentYOffset = [currentLayout.yOffset floatValue] / 100;
    }
    else
    {
        currentScale   = 1.0;
        currentXOffset = 0.0;
        currentYOffset = 0.0;
    }
    return currentLayout;
}

- (void)resetPhotoShoot:(NSNotification *)notification
{
    //    NSLog(@"%s", __FUNCTION__);
    
    // Initialize Countdown Timer
    shotsRemaining = AMNumberOfPicturesPerSession;
    countdownSequence = 10;
    countdownTimerSelector = @selector(doUpdateTimer);
    
    
    if ([self respondsToSelector:countdownTimerSelector])
    {
        // create and initialize timer
        countdownTimerMethodSig = [self methodSignatureForSelector:countdownTimerSelector];
        if (countdownTimerMethodSig != nil)
        {
            countdownTimerInvocation = [NSInvocation invocationWithMethodSignature:countdownTimerMethodSig];
            [countdownTimerInvocation setTarget:self];
            [countdownTimerInvocation setSelector:countdownTimerSelector];
            
            countdownInterval = kiosk.camera.countdownStepSeconds;
            countdownInterval = 0.2;
            
            countdownTimer = [NSTimer scheduledTimerWithTimeInterval:countdownInterval invocation:countdownTimerInvocation repeats:YES];
        }
        else
        {
            NSLog(@"Timer method signature is nil");
        }
    }
    else
    {
        NSLog(@"Timer will not respond to selector");
    }
}

- (void)receiveStopPhotoSession:(NSNotification *)notification
{
    //We expect notifications to come in out of the http server thread.
    [self performSelectorOnMainThread:@selector(stopPhotoSession) withObject:nil waitUntilDone:NO];
}



- (void)callingFunction:(NSNotification *)notification
{
    //We expect notifications to come in out of the http server thread.
    [self performSelectorOnMainThread:@selector(gotoSplash) withObject:nil waitUntilDone:NO];
}


- (void)newPhotoDidStore:(NSNotification *)notification
{
    //    NSLog(@"%s", __FUNCTION__);
    // We expect this notification to come in from the main thread.
    shotsRemaining--;
    // If there are no remaining shots to take, return to the splash screen.
    if (shotsRemaining <= 0)
    {
        [self returnToSplash];
    }
}

- (void)stopPhotoSession
{
    
    
    
    //    NSLog(@"%s", __FUNCTION__);
    if (_isTestingCamera) {
        return;
    }
    [self returnToSplash];
}


- (void)gotoSplash
{
    
    
    
    //    NSLog(@"%s", __FUNCTION__);
    if (_isTestingCamera) {
        return;
    }
    [self calling];
}

#pragma mark - Camera Timer Related  Method

- (void)doUpdateTimer
{
    CGFloat countdownSequenceFloat = (CGFloat)countdownSequence;
    CGFloat backgroundAlpha = countdownSequenceFloat / 10.0;
    //NSLog(@"background alpha %f", backgroundAlpha);
    
    //    lblInstruction.backgroundColor  = [UIColor colorWithRed:0.0 green:0.0
    //                                                       blue:0.0
    //                                                      alpha:backgroundAlpha];
    
    lblInstruction.backgroundColor  = [UIColor clearColor];
    
    // Depending on the sequence, display something different.
    switch (countdownSequence)
    {
        case 0:
            // switch shoot to inactive in photo session
            // take photo
            // save photo
            lblInstruction.text = @"";
            dot.hidden=YES;
            [self takePicture];
            countdownSequence = 10;
            if (shotsRemaining <= 0)
            {
                [countdownTimer invalidate];
                countdownTimer = nil;
            }
            break;
        case 1:
        case 2:
        case 3:
        case 4:
        case 5:
        {
            dot.hidden=YES;
            
            [countdownTimer invalidate];
            countdownTimer = nil;
            
            countdownTimerInvocation = [NSInvocation invocationWithMethodSignature:countdownTimerMethodSig];
            [countdownTimerInvocation setTarget:self];
            [countdownTimerInvocation setSelector:countdownTimerSelector];
            
            
            countdownInterval = kiosk.camera.countdownStepSeconds;
            
            
            countdownTimer = [NSTimer scheduledTimerWithTimeInterval:countdownInterval invocation:countdownTimerInvocation repeats:YES];
            
            
            lblInstruction.font = [UIFont systemFontOfSize:650];
            lblInstruction.text = [NSString stringWithFormat:@"%d",countdownSequence];
        }
            break;
        case 10:
            
            dot.hidden=YES;
            
            //[kiosk.camera turnOnTorch];
            //[kiosk.camera prepareForPicture];
        default:
        {
            //     dot.hidden=NO;
            NSString *str;
            
            lblInstruction.font = [UIFont systemFontOfSize:60];
            //         lblInstruction.text = [NSString stringWithFormat:@"Get ready for picture %d of %d", (AMNumberOfPicturesPerSession - shotsRemaining + 1),  AMNumberOfPicturesPerSession];
            
            
            str = [NSString stringWithFormat:@"Picture %d of %d", (AMNumberOfPicturesPerSession - shotsRemaining + 1),  AMNumberOfPicturesPerSession];
            NSMutableAttributedString *attString =
            [[NSMutableAttributedString alloc]
             initWithString: str];
            
            [attString addAttribute: NSForegroundColorAttributeName
                              value: [UIColor colorWithRed:255 green:255 blue:255 alpha:0.5]
                              range: NSMakeRange(8,1)];
            
            
            [attString addAttribute: NSFontAttributeName
                              value:  [UIFont fontWithName:@"Helvetica" size:230]
                              range: NSMakeRange(8,1)];
            
            
            
            lblInstruction.attributedText  = attString;
            
            dot.hidden=YES;
            
        }
            break;
    }
    // Count .. down!
    countdownSequence --;
    [self.view setNeedsDisplay];
}
#pragma mark - GPUImage Capture  Method

- (void)takePicture
{
    //    NSLog(@"%s", __FUNCTION__);
    imageToBeStored = nil;
    //    recordNextCompositeFrame = YES;
    self.tempBg.image = nil;
    self.tempBg.hidden = YES;
    self.cameraView.hidden = NO;
    
    
    
    
    float wid,hei,hh;
    wid=self.view.frame.size.width;
    //  hh=self.view.frame.size.height-186;
    
    if(wid>1024)
    {
        hei=121.0f;
        hh=self.view.frame.size.height-242;
        
    }else
    {
        hei=93.0f;
        hh=580.0f;
        
        //hh=self.view.frame.size.height-186;
    }
    
    
    
    CGRect rect = CGRectMake(0, hei, self.view.frame.size.width, hh);
 //     CGRect rect = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
     GPUImageOutput<GPUImageInput> * filter111;
      NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [userDefaults objectForKey:@"mainFrameRect"];
    
    
    
    NSValue *val1=[NSKeyedUnarchiver unarchiveObjectWithData:data];;
    
    CGRect cropervalue=[val1 CGRectValue];
    
    if(data==nil)
    {
        cropervalue=rect;
    }
    
      if (CGRectEqualToRect(cropervalue, rect)) {
          
          filter111=filter;
          
      }
    else
    {
        filter111=Croper;
    }
//    filterView.fillMode=
//    [stillCamera addTarget:filterView];
    
    
    
    [stillCamera capturePhotoAsImageProcessedUpToFilter:filter111 withCompletionHandler:^(UIImage * processedImage, NSError * error){
        if(processedImage)
        {
            
            
            lblInstruction.hidden = YES;
            
            //   dot.hidden=YES;
            
            self.tempBg.hidden = NO;
            //NSLog(@"image oreintation %d",processedImage.imageOrientation);
            //UIInterfaceOrientation orientation = [self interfaceOrientation];
            //NSLog(@"view oreintation%d",orientation);
            
            
            processedImage = [UIImage imageWithCGImage:processedImage.CGImage scale:1.0 orientation:UIImageOrientationUp];
            //            CGAffineTransform transform = self.tempBg.transform;
            //            self.tempBg.transform = CGAffineTransformScale(transform, 2.0, 2.0);
            
            
            self.tempBg.frame = self.cameraView.frame;
            //            self.tempBg.transform = self.mainCameraView.transform;
            self.tempBg.image = processedImage;
            
      
            
            
            self.cameraView.hidden = YES;
            
            //            while (!lblInstruction.hidden)
            //            {
            //                lblInstruction.hidden = YES;
            //            }
            [cameraBtn setHidden:YES];
            UIImage * screenshot=nil;
            //            if (([[[NSUserDefaults standardUserDefaults] valueForKey:@"Mirror Effect"] isEqualToString:@"Yes"])||([[[NSUserDefaults standardUserDefaults] valueForKey:@"Mirror Effect"] length] == 0))
            if(0)
            {
                self.baseView.layer.affineTransform = CATransform3DGetAffineTransform(CATransform3DConcat(self.baseView.layer.transform,CATransform3DMakeRotation(M_PI, 0.0, 1.0, 0.0f)));
                
                screenshot = [AMUtility captureView:self.view];
                
                self.baseView.layer.affineTransform = CATransform3DGetAffineTransform(CATransform3DConcat(self.baseView.layer.transform,CATransform3DMakeRotation(M_PI, 0.0, 1.0, 0.0f)));
            }
            else
            {
                screenshot = [AMUtility captureView:self.view];
                
//                screenshot = [self screenshot];
                
            }
            
            
            
            self.tempBg.image = nil;
            self.tempBg.hidden = YES;
            self.cameraView.hidden = NO;
            
            
            imageToBeStored = screenshot;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:AMGPUImageCameraNewCompositeFrameNotification object:nil];
            lblInstruction.hidden = NO;
            [cameraBtn setHidden:NO];
        }
    }];
}

- (void)returnToSplash
{
    
    
    
    
    
    
    
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * result = [defaults stringForKey:@"splashScreen"];
    
    if([result isEqualToString:@"correct"])
    {
        
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"touchiPad"
         object:nil];
        
        [defaults setObject:@"incorrect" forKey:@"splashScreen"];
        
        
    }
    
    
    
    
    NSLog(@"Crash Found");
    
    [stillCamera removeAllTargets];
    [filter removeAllTargets];
    filter = nil;
    [self.cameraView removeFromSuperview];
    
    
    
    countdownTimerInvocation = nil;
    
    [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
    
    [self stopCamera];
    stillCamera = nil;
    [countdownTimer invalidate];
    // [idleTimer invalidate];
    countdownTimer = nil;
    [self dismissViewControllerAnimated:YES completion: nil];
    
}


- (void)calling
{
    
    
    
    
    
    
    
    
    //    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    //    NSString * result = [defaults stringForKey:@"splashScreen"];
    //
    //    if([result isEqualToString:@"correct"])
    //    {
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"touchiPad"
     object:nil];
    
    //   [defaults setObject:@"incorrect" forKey:@"splashScreen"];
    
    
    // }
    
    
    
    
    NSLog(@"Crash Found");
    
    [stillCamera removeAllTargets];
    [filter removeAllTargets];
    filter = nil;
    [self.cameraView removeFromSuperview];
    
    
    
    countdownTimerInvocation = nil;
    
    [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
    
    [self stopCamera];
    stillCamera = nil;
    [countdownTimer invalidate];
    // [idleTimer invalidate];
    countdownTimer = nil;
    [self dismissViewControllerAnimated:YES completion: nil];
    
}


- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if(recordNextCompositeFrame && sampleBuffer)
    {
        self.recentCompositeFrameInfo = nil;
        //        recordNextCompositeFrame = FALSE;
        CFDictionaryRef metaDict = CMCopyDictionaryOfAttachments(NULL, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
        self.recentCompositeFrameInfo = CFDictionaryCreateMutableCopy(NULL, 0, metaDict);
        CFRelease(metaDict);
        CFRelease(sampleBuffer);
    }
}

#pragma mark - Device Orientation Method

//- (void)deviceOrientationDidChange:(NSNotification *)notification
//{
//    //    NSLog(@"%s", __FUNCTION__);
//    if (kiosk.deviceMode == CTKioskDeviceModeCamera)
//    {
//        UIInterfaceOrientation orientation = UIDeviceOrientationLandscapeLeft;
//
//        // We only need to handle landscape and portrait.
//        if (orientation == UIDeviceOrientationFaceUp ||
//            orientation == UIDeviceOrientationFaceDown ||
//            orientation == UIDeviceOrientationUnknown ||
//            stillCamera.outputImageOrientation == orientation)
//        {
//            //            return;
//        }
//
//
//        //        UIImage * newimage = [self captureView:self.bgImage withArea:self.bgImage.frame];
//        //        UIImage * cropedimage = [newimage crop:self.mainCameraView.frame];
//        //        UIImage * rotatedimage = [self getRotatedImage:cropedimage];
//
//        // For image rotation effect implementation
//        UIImageView * tempview = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"image-8.png"]];
//        tempview.backgroundColor = [UIColor clearColor];
//        [self.view addSubview:tempview];
//        UIImage * newimage1 = [self captureView:tempview withArea:tempview.frame];
//        [tempview removeFromSuperview];
//
//        if(filter)
//        {
//            [filter useNextFrameForImageCapture];
//            sourcePicture = [[GPUImagePicture alloc] initWithImage:newimage1 smoothlyScaleOutput:YES];
//            [sourcePicture addTarget:filter];
//            [sourcePicture processImage];
//            stillCamera.outputImageOrientation = [self interfaceOrientation];
//        }
//    }
//}


- (void)deviceOrientationDidChange:(NSNotification *)notification
{
    //    NSLog(@"%s", __FUNCTION__);
    if (kiosk.deviceMode == CTKioskDeviceModeCamera)
    {
        UIInterfaceOrientation orientation = UIDeviceOrientationLandscapeLeft;

        // We only need to handle landscape and portrait.
        if (orientation == UIDeviceOrientationFaceUp ||
            orientation == UIDeviceOrientationFaceDown ||
            orientation == UIDeviceOrientationUnknown ||
            stillCamera.outputImageOrientation == orientation)
        {
            //            return;
        }


        //        UIImage * newimage = [self captureView:self.bgImage withArea:self.bgImage.frame];
        //        UIImage * cropedimage = [newimage crop:self.mainCameraView.frame];
        //        UIImage * rotatedimage = [self getRotatedImage:cropedimage];

        // For image rotation effect implementation
        UIImageView * tempview = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"image-8.png"]];
        tempview.backgroundColor = [UIColor clearColor];
        [self.view addSubview:tempview];
        UIImage * newimage1 = [self captureView:tempview withArea:tempview.frame];
        [tempview removeFromSuperview];

        if(filter)
        {
            [filter useNextFrameForImageCapture];
            sourcePicture = [[GPUImagePicture alloc] initWithImage:newimage1 smoothlyScaleOutput:YES];
            [sourcePicture addTarget:filter];
            [sourcePicture processImage];
            stillCamera.outputImageOrientation = [self interfaceOrientation];
        }
    }
}



#pragma mark - New Picture Available Notification Method

- (void)receiveNewGPUImagePhotoAvailable:(NSNotification *)notification
{
    [self performSelectorOnMainThread:@selector(newPhotoAvailable:) withObject:notification waitUntilDone:NO];
}

#pragma mark - Storing Assets Method

- (void)newPhotoAvailable:(NSNotification *)notification
{
    if (!assetsLibrary)
    {
        assetsLibrary = [[ALAssetsLibrary alloc] init];
    }
    
    
    [assetsLibrary writeImageToSavedPhotosAlbum:[imageToBeStored CGImage] orientation:ALAssetOrientationUp completionBlock:^(NSURL *assetURL, NSError *error)
     {
         if (error)
         {
             NSLog(@"ERROR: image failed to be written");
         }
         else
         {
             NSLog(@"PHOTO SAVED - assetURL: %@", assetURL);
         }
         [[NSNotificationCenter defaultCenter] postNotificationName:AMCameraNewCameraRollPhotoNotification object:assetURL];
     }];
    
    // Write to disk
    NSString * targetFilePath = [self photoStoreDirectory];
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
    NSString * targetFileName = [NSString stringWithFormat:@"photo-%f.jpg",
                                 timeInterval];
    NSURL * targetUrl = [NSURL fileURLWithPath:[targetFilePath
                                                stringByAppendingPathComponent:targetFileName]];
    
    // Start a CoreData object at the same time and store
    
    if ([self writeCGImage:[imageToBeStored CGImage] toURL:targetUrl
                  withType:kUTTypeJPEG  andOptions:nil])
    {
        NSLog(@"New image saved to disk at %@", targetUrl);
        // Record a CD entity
        // Create and store a Photo entity.
        Photo * photo = (Photo *)[NSEntityDescription
                                  insertNewObjectForEntityForName:@"Photo"
                                  inManagedObjectContext:store.currentMOC];
        [photo setCreatedOn:[NSDate date]];
        [photo setToKioskOn:[NSDate date]];
        [photo setPhotoUrl:[targetUrl absoluteString]];
        
        // Core Data relationships
        [kiosk.currentPhotoSession.entity addPhotosObject:photo];
        [photo setSession:kiosk.currentPhotoSession.entity];
        [photo setEventId:kiosk.currentPhotoSession.entity.layout.eventId];
        if (kiosk.currentPhotoSession.entity.layout.defaultId != nil || ![kiosk.currentPhotoSession.entity.layout.defaultId isKindOfClass:[NSNull class]])
        {
            [photo setDefaultId:kiosk.currentPhotoSession.entity.layout.defaultId];
        }
        
        [photo setLayoutId:kiosk.currentPhotoSession.entity.layout.order];
        
        // Then store.
        NSError * error = nil;
        if ([store.currentMOC save:&error])
        {
            NSLog(@"New Photo entity stored.");
        }
        else
        {
            // TODO Handle the error.
            NSLog(@"Error saving new photo entity: %@", [error localizedDescription]);
        }
        
        // Then let everyone know.
        [[NSNotificationCenter defaultCenter]
         postNotificationName:AMCameraNewDiskPhotoNotification
         object:targetFileName];
    }
    else
    {
        NSLog(@"Error saving photo to disk.");
    }
}

- (BOOL)writeCGImage:(CGImageRef)image toURL:(NSURL *)url withType:(CFStringRef)imageType andOptions:(CFDictionaryRef)options
{
    CGImageDestinationRef target = CGImageDestinationCreateWithURL(
                                                                   (__bridge CFURLRef) url,
                                                                   imageType, // UTI Uniform Type Identifier
                                                                   1, // count
                                                                   nil);// future
    
    CGImageDestinationAddImage(target, image, nil);
    BOOL success = CGImageDestinationFinalize(target);
    
    CFRelease(target);
    if (options)
        CFRelease(options);
    
    return success;
}

- (NSString *)photoStoreDirectory
{
    NSString * storePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return [storePath stringByAppendingPathComponent:AMHttpPhotoStoreUriComponent];
}

#pragma mark - CLLocation Delegates Method

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    /*
     Format the location info as if GPS information for photo metadata use.  We only need a single instance of this then we're done with the location manager completely.
     */
    if (newLocation && !self.gpsInfo)
    {
        NSLog(@"Have Location information.");
        [manager stopUpdatingLocation];
        
        // Create formatted date
        NSTimeZone      * timeZone   = [NSTimeZone timeZoneWithName:@"UTC"];
        NSDateFormatter * formatter  = [[NSDateFormatter alloc] init];
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

#pragma mark - Delloc Method

- (void)dealloc
{
    CGImageRelease(mask);
    CGImageRelease(masked);
    NSLog(@"%s", __FUNCTION__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    //    NSLog(@"%s", __FUNCTION__);
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AMGPUImageCameraNewCompositeFrameNotification object:nil];
    
    [super viewWillDisappear:(BOOL)animated];
    [fovView removeFromSuperview];
}

- (void)viewDidDisappear:(BOOL)animated
{
    //    CFRelease((__bridge CFTypeRef)(filter));
    //    filter = nil;
    //
    //    [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
    //
    ////    NSLog(@"%s", __FUNCTION__);
    //    self.cameraView = nil;
    //    filterView = nil;
    //    [self stopCamera];
    //    stillCamera = nil;
    //
    //    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //    [[NSNotificationCenter defaultCenter] removeObserver:self name:AMGPUImageCameraNewCompositeFrameNotification object:nil];
    [super viewDidDisappear:(BOOL)animated];
}

- (void)settingsViewController:(CTSettingsViewController *)settingsViewController didFinishSettings:(NSUserDefaults *)settings
{
    /*
     Delegate for modal view to tell presenting controller it's done, close me.
     */
    //    NSLog(@"%s", __FUNCTION__);
    
    [self dismissViewControllerAnimated:YES completion: nil];
    [kiosk loadPersistentSettings:YES];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)hideCameraAction:(id)sender {
    
    
    CGRect newFrame;
    CGRect cropFrame;
    CGRect cropFrame2;
    
    newFrame = CGRectMake( _cropView.frame.origin.x, _cropView.frame.origin.y, _cropView.frame.size.width, _cropView.frame.size.height);
    
    
  //  CGRect newFrame4 = CGRectMake( filterView.frame.origin.x, filterView.frame.origin.y, filterView.frame.size.width, filterView.frame.size.height);
    
//     CGRect newFrame4 = CGRectMake(0.0f,0.0f,1024.0f,580.0f);
    
    
    float wid,hei,hh;
    wid=self.view.frame.size.width;
    //  hh=self.view.frame.size.height-186;
    
    if(wid>1024)
    {
        hei=121.0f;
        hh=self.view.frame.size.height-242;
        
    }else
    {
        hei=93.0f;
        hh=580.0f;
    }
    
    
    
    
    
    
//     CGRect newFrame4 = CGRectMake(0.0f,0.0f,self.view.frame.size.width,580.0f);
    
//     CGRect newFrame4 = CGRectMake(0.0f,0.0f,self.view.frame.size.width,hh);
    
     CGRect newFrame4 = CGRectMake(0.0f,0.0f,self.view.frame.size.width,hh);
    
    
//    CGRect newFrame3 = CGRectMake( newFrame.origin.x - newFrame4.origin.x, newFrame.origin.y - newFrame4.origin.y - _viewTop.frame.size.height, newFrame.size.width, newFrame.size.height);
    
     CGRect newFrame3 = CGRectMake( newFrame.origin.x - newFrame4.origin.x, newFrame.origin.y - newFrame4.origin.y- _viewTop.frame.size.height, newFrame.size.width, newFrame.size.height);
    
    cropFrame = newFrame3;
    
    cropFrame2 = newFrame4;
    
    CGAffineTransform t = CGAffineTransformMakeScale(1.0 / cropFrame2.size.width, 1.0 / cropFrame2.size.height);
    CGRect unitRect = CGRectApplyAffineTransform(cropFrame, t);
    
    
    
    CGRect MainFrame = newFrame;
    
    
    _croperRect=unitRect;
    _mainFrameRect=MainFrame;
    
    
    CGRect rect = CGRectMake(0, 93, 1024, 580);
    
    
    if (CGRectEqualToRect(_mainFrameRect, rect) || CGRectIsEmpty(_mainFrameRect)) {
        
        NSLog(@"Success");
        
        
        // do some stuff
    }
   
    
    float width=_mainFrameRect.size.width;
    width=width/1024;
    
    float height=_mainFrameRect.size.height;
    height=height/height;
    
    
     NSUserDefaults * userdefault = [NSUserDefaults standardUserDefaults];
    
    NSValue *value = [NSValue valueWithCGRect:_mainFrameRect];
     NSValue *value1 = [NSValue valueWithCGRect:_croperRect];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
    NSData *data1 = [NSKeyedArchiver archivedDataWithRootObject:value1];
    [userdefault setObject:data  forKey:@"mainFrameRect"];
    [userdefault setObject:data1  forKey:@"croperRect"];
    
    
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)changeCameraMode:(UIButton *)sender {
    sender.selected = !sender.selected;
    [stillCamera stopCameraCapture];
    
    [stillCamera removeAllTargets];
    
    stillCamera = nil;
    if (sender.selected) {
        [self startCamera:NO];
    }
    else
    {
        [self startCamera:YES];
    }
}


- (void)resetIdleTimer {
    if (!idleTimer) {
        idleTimer = [NSTimer scheduledTimerWithTimeInterval:kMaxIdleTimeSeconds
                                                     target:self
                                                   selector:@selector(idleTimerExceeded)
                                                   userInfo:nil
                                                    repeats:YES];
    }
    else {
        if (fabs([idleTimer.fireDate timeIntervalSinceNow]) < kMaxIdleTimeSeconds-1.0) {
            [idleTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:kMaxIdleTimeSeconds]];
        }
    }
}




- (void)idleTimerExceeded {
    if( idleTimer != nil)
    {
        
        [idleTimer invalidate];
        // idleTimer = nil;
    }
    NSLog(@"time elapased");
    // [self resetPhotoShoot:nil];
    
    
    if (!self.isTestingCamera)
    {
        [self resetPhotoShoot:nil];
    }
    
}

- (IBAction)settingsBtnAction:(id)sender {
    
    
    
    
    
    
    
    
    
    //    NSLog(@"hello");
    //    [[NSNotificationCenter defaultCenter] addObserver:self
    //                                             selector:@selector(showSettingScreen1:)
    //                                                 name:@"OpenSettingSceneNotification"
    //                                               object:nil];
    //
    //    [[NSNotificationCenter defaultCenter] addObserver:self
    //                                             selector:@selector(showSettingScreen1:)
    //                                                 name:@"showSettingScreen"
    //                                               object:nil];
    //
    //    [[NSNotificationCenter defaultCenter] addObserver:self
    //                                             selector:@selector(lockCancel1:)
    //                                                 name:@"lockCancel"
    //                                               object:nil];
    //
    //    lockScreen = [[ABPadLockScreenViewController alloc] initWithDelegate:nil complexPin:NO];
    //    lockScreen.showSetting = YES;
    //
    //
    //    lockScreen.modalPresentationStyle = UIModalPresentationFullScreen;
    //    [lockScreen cancelButtonDisabled:NO];
    //    lockScreen.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    //
    //    [self presentViewController:lockScreen animated:YES completion:nil];
    //
    //
    
    
    
    // [self authorizePrint];
    
    //    [[NSNotificationCenter defaultCenter] addObserver:self
    //                                             selector:@selector(showSettingScreen1:)
    //                                                 name:@"showEvent"
    //                                               object:nil];
    //
    //
    //    lockScreen = [[ABPadLockScreenViewController alloc] initWithDelegate:nil complexPin:NO];
    //    // lockScreen.showSetting = YES;
    //
    //
    //    lockScreen.modalPresentationStyle = UIModalPresentationFullScreen;
    //    [lockScreen cancelButtonDisabled:NO];
    //    lockScreen.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    //
    //    [self presentViewController:lockScreen animated:YES completion:nil];
    //
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clicked:)
                                                 name:@"settingsButton"
                                               object:nil];
    
    
    lockScreen = [[ABPadLockScreenViewController alloc] initWithDelegate:nil complexPin:NO];
    // lockScreen.showSetting = YES;
    
    
    lockScreen.modalPresentationStyle = UIModalPresentationFullScreen;
    [lockScreen cancelButtonDisabled:NO];
    lockScreen.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    
    [self presentViewController:lockScreen animated:YES completion:nil];
    
    
    
    
    NSLog(@"pin value is %@",lockScreen.pinValue);
    
}


- (void)clicked:(NSNotification *)notification
{
    
    
    
    NSLog(@"success");
    
    [lockScreen dismissViewControllerAnimated:NO completion:nil];
    
    UIViewController *viewController;
    viewController = [self .storyboard instantiateViewControllerWithIdentifier:@"EventListViewController"];
    [self.navigationController pushViewController:viewController animated:YES];
    
    //  [self performSegueWithIdentifier:@"settings" sender:self];
    //  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"OpenSettingSceneNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"showSettingScreen" object:nil];
    //  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"lockCancel" object:nil];
    
}


- (void)updateCropCornerViewFrameRotate{
    
    _imageFrame1.frame = CGRectMake(0, 0, 20, 20);
    //
    _imageFrame2.frame = CGRectMake(_cropView.frame.size.width - 20, 0, 20, 20);
    //
    _imageFrame3.frame = CGRectMake(0, _cropView.frame.size.height - 20, 20, 20);
    //
    _imageFrame4.frame = CGRectMake(_cropView.frame.size.width - 20, _cropView.frame.size.height - 20, 20, 20);
    
    
//    _imageFrameL1.frame = CGRectMake(0, 0, 20, 20);
//    //
//    _imageFrameL2.frame = CGRectMake(_viewCropL.frame.size.width - 20, 0, 20, 20);
//    //
//    _imageFrameL3.frame = CGRectMake(0, _viewCropL.frame.size.height - 20, 20, 20);
//    //
//    _imageFrameL4.frame = CGRectMake(_viewCropL.frame.size.width - 20, _viewCropL.frame.size.height - 20, 20, 20);
}


- (void)setupInitialView {
    
  
    
    [_cropView setUserInteractionEnabled:YES];
    
    
    
   
    
//    _videoFrame = _viewVideo.frame;
//    _videoFrameL = _viewVideoL.frame;
    
    
//    _btnSave.titleLabel.textColor = [UIColor colorWithRed:95.0/255.0 green:203.0/255.0 blue:30.0/255.0 alpha:1.0];
//    _btnSaveL.titleLabel.textColor = [UIColor colorWithRed:95.0/255.0 green:203.0/255.0 blue:30.0/255.0 alpha:1.0];
    
    //UIGraphicsBeginImageContext(_viewCrop.frame.size);
    //[[UIImage imageNamed:@"frame"] drawInRect:_viewCrop.bounds];
    //UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    //UIGraphicsEndImageContext();
    //_viewCrop.backgroundColor = [UIColor colorWithPatternImage:image];
    
    
    maxWidth = 1280;
    maxHeight = 720;
    
    
   // self.tool = [RotateVideo new];
    
//    NSString * temp = [NSSearchPathForDirectoriesInDomains(NSMoviesDirectory, NSUserDomainMask, YES) firstObject];
//    temp = [temp stringByAppendingPathComponent:@"DownloadVideo"];
//    if ([[NSFileManager defaultManager] fileExistsAtPath:temp] == NO) {
//        [[NSFileManager defaultManager] createDirectoryAtPath:temp withIntermediateDirectories:YES attributes:nil error:nil];
//    }
//
//    self.rotateTargetPath = [temp stringByAppendingPathComponent:@"rotate.mp4"];
//
//    NSLog(@" asset crop %@", assetCrop);
    
  //  if (IsLiveCamera == YES) {
//
//        if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)){
//
//            _originalCenterL = _viewVideo.center;
//            _originalCenter = _viewVideo.center;
//            _originalRectL = _viewVideoL.frame;
//            _originalRect = _viewVideo.frame;
//
//            //            [_viewVideoL addSubview:videoCropPlayer.view];
//
//            CGRect newFrame1 = CGRectMake( _viewVideo.frame.origin.x, _viewVideo.frame.origin.y + _viewTop.bounds.size.height, _viewVideo.frame.size.width, _viewVideo.frame.size.height);
//
//            newFrame1=CGRectMake(self.cameraView.frame.origin.x, self.cameraView.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
//
//            self.cropView.frame = newFrame1;
//            self.cropView.center = _viewVideo.center;
//
//            self.cropView.layer.borderColor = [UIColor yellowColor].CGColor;
//            self.cropView.layer.borderWidth = 3.0f;
//
//            CGRect newFrame = CGRectMake( _viewVideoL.frame.origin.x, _viewVideoL.frame.origin.y + _viewTopL.bounds.size.height, _viewVideoL.frame.size.width, _viewVideoL.frame.size.height);
//
//            newFrame=CGRectMake(self.cameraView.frame.origin.x, self.cameraView.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
//
//
//            self.viewCropL.frame = newFrame;
//            self.viewCropL.center = _viewVideoL.center;
//
//            self.viewCropL.layer.borderColor = [UIColor yellowColor].CGColor;
//            self.viewCropL.layer.borderWidth = 3.0f;
//
////            _viewPortrait.hidden = YES;
////            _viewLandscape.hidden = NO;
//
//        }
     //   else{
            
            _originalCenterL = _viewVideoL.center;
            _originalCenter = _viewVideo.center;
            _originalRectL = _viewVideoL.frame;
            _originalRect = _viewVideo.frame;
            
            //            [_viewVideo addSubview:videoCropPlayer.view];
            
            
            
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            
            NSData *data = [userDefaults objectForKey:@"mainFrameRect"];
            
            NSValue *val1=[NSKeyedUnarchiver unarchiveObjectWithData:data];;
            
            CGRect cropervalue=[val1 CGRectValue];
            
            NSData *data1 = [userDefaults objectForKey:@"croperRect"];
            
            NSValue *val2=[NSKeyedUnarchiver unarchiveObjectWithData:data1];;
            
            CGRect transformvalue=[val2 CGRectValue];
            CGRect newFrame1;
            if (data==nil) {
              newFrame1   = CGRectMake( _viewVideo.frame.origin.x, _viewVideo.frame.origin.y + _viewTop.bounds.size.height, _viewVideo.frame.size.width, _viewVideo.frame.size.height);
            }
            else
            {
                 newFrame1   = cropervalue;
            }
            
            
      //      CGRect newFrame1 = CGRectMake( _viewVideo.frame.origin.x, _viewVideo.frame.origin.y + _viewTop.bounds.size.height, _viewVideo.frame.size.width, _viewVideo.frame.size.height);
            
        //   newFrame1= CGRectMake(self.cameraView.frame.origin.x, self.cameraView.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
            
          //     newFrame1= CGRectMake(512, 383, 512, 290);
            
            self.cropView.frame = newFrame1;
         //   self.cropView.center = _viewVideo.center;
            
            self.cropView.layer.borderColor = [UIColor yellowColor].CGColor;
            self.cropView.layer.borderWidth = 3.0f;
            
            CGRect newFrame = CGRectMake(0, 90, self.view.frame.size.width, 600);
            
            
           newFrame= CGRectMake(0, 90, self.view.frame.size.width, 580);
            
            self.viewCropL.frame = newFrame;
            self.viewCropL.center = _viewVideoL.center;
            
            self.viewCropL.layer.borderColor = [UIColor yellowColor].CGColor;
            self.viewCropL.layer.borderWidth = 3.0f;
            
//            _viewPortrait.hidden = NO;
//            _viewLandscape.hidden = YES;
            
      //  }
        
        _imageFrame1.translatesAutoresizingMaskIntoConstraints = NO;
        _imageFrame2.translatesAutoresizingMaskIntoConstraints = NO;
        _imageFrame3.translatesAutoresizingMaskIntoConstraints = NO;
        _imageFrame4.translatesAutoresizingMaskIntoConstraints = NO;
//
//        CGRect newFrame = CGRectMake( videoCropPlayer.videoBounds.origin.x, videoCropPlayer.videoBounds.origin.y + _viewTop.bounds.size.height, videoCropPlayer.videoBounds.size.width, videoCropPlayer.videoBounds.size.height);
    
        UIImage *image1 = [UIImage imageNamed:@"frame-4"];
        _imageFrame1 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 234, 20, 20)];
        _imageFrame1.image = image1;
        //    _imageFrame1.frame = CGRectMake(_viewCrop.bounds.origin.x, _viewCrop.bounds.origin.y, 20, 20);
        [_cropView addSubview:_imageFrame1];
        [_cropView bringSubviewToFront:_imageFrame1];
        //    _imageFrame1.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        _cropView.autoresizesSubviews = YES;
        _cropView.clipsToBounds = YES;
        
        UIImage *image2 = [UIImage imageNamed:@"frame-1"];
        _imageFrame2 = [[UIImageView alloc] initWithFrame:CGRectMake(_cropView.frame.origin.x, _cropView.frame.origin.y, 20, 20)];
        _imageFrame2.image = image2;
        [_cropView addSubview:_imageFrame2];
        [_cropView bringSubviewToFront:_imageFrame2];
        //    _imageFrame2.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        _cropView.autoresizesSubviews = YES;
        _cropView.clipsToBounds = YES;
        
        UIImage *image3 = [UIImage imageNamed:@"frame-3"];
        _imageFrame3 = [[UIImageView alloc] initWithFrame:CGRectMake(_cropView.frame.origin.x, _cropView.frame.origin.y, 20, 20)];
        _imageFrame3.image = image3;
        [_cropView addSubview:_imageFrame3];
        [_cropView bringSubviewToFront:_imageFrame3];
        //    _imageFrame3.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        _cropView.autoresizesSubviews = YES;
        _cropView.clipsToBounds = YES;
        
        UIImage *image4 = [UIImage imageNamed:@"frame-2"];
        _imageFrame4 = [[UIImageView alloc] initWithFrame:CGRectMake(_cropView.frame.origin.x, _cropView.frame.origin.y, 20, 20)];
        _imageFrame4.image = image4;
        [_cropView addSubview:_imageFrame4];
        [_cropView bringSubviewToFront:_imageFrame4];
        //    _imageFrame4.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        _cropView.autoresizesSubviews = YES;
        _cropView.clipsToBounds = YES;
        
        
        UIImage *imageL1 = [UIImage imageNamed:@"frame-4"];
        _imageFrameL1 = [[UIImageView alloc] initWithFrame:CGRectMake(_viewCropL.frame.origin.x, _viewCropL.frame.origin.y, 20, 20)];
        _imageFrameL1.image = imageL1;
        [_viewCropL addSubview:_imageFrameL1];
        [_viewCropL bringSubviewToFront:_imageFrameL1];
        //    _imageFrameL1.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        _viewCropL.autoresizesSubviews = YES;
        _viewCropL.clipsToBounds = YES;
        
        UIImage *imageL2 = [UIImage imageNamed:@"frame-1"];
        _imageFrameL2 = [[UIImageView alloc] initWithFrame:CGRectMake(_viewCropL.frame.origin.x, _viewCropL.frame.origin.y, 20, 20)];
        _imageFrameL2.image = imageL2;
        [_viewCropL addSubview:_imageFrameL2];
        [_viewCropL bringSubviewToFront:_imageFrameL2];
        //    _imageFrameL2.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        _viewCropL.autoresizesSubviews = YES;
        _viewCropL.clipsToBounds = YES;
        
        UIImage *imageL3 = [UIImage imageNamed:@"frame-3"];
        _imageFrameL3 = [[UIImageView alloc] initWithFrame:CGRectMake(_viewCropL.frame.origin.x, _viewCropL.frame.origin.y, 20, 20)];
        _imageFrameL3.image = imageL3;
        [_viewCropL addSubview:_imageFrameL3];
        [_viewCropL bringSubviewToFront:_imageFrameL3];
        //    _imageFrameL3.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        _viewCropL.autoresizesSubviews = YES;
        _viewCropL.clipsToBounds = YES;
        
        UIImage *imageL4 = [UIImage imageNamed:@"frame-2"];
        _imageFrameL4 = [[UIImageView alloc] initWithFrame:CGRectMake(_viewCropL.frame.origin.x, _viewCropL.frame.origin.y, 20, 20)];
        _imageFrameL4.image = imageL4;
        [_viewCropL addSubview:_imageFrameL4];
        [_viewCropL bringSubviewToFront:_imageFrameL4];
        //    _imageFrameL4.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        _viewCropL.autoresizesSubviews = YES;
        _viewCropL.clipsToBounds = YES;
        
        [self updateCropCornerViewFrameRotate];
        
//    }else if (assetCrop != nil){
//
//
//        _videoUrl = (NSURL *)[[(AVURLAsset *)assetCrop URL] fileReferenceURL];
//
//        [self.viewFrame setThemeColor:[UIColor whiteColor]];
//        [self.viewFrame setAsset:assetCrop];
//        [self.viewFrame setShowsRulerView:YES];
//        //[viewFrame setRulerLabelInterval:10];
//        [self.viewFrame setTrackerColor:[UIColor cyanColor]];
//        [self.viewFrame setDelegate:self];
//
//        [self.viewFrame setLeftThumbImage:[UIImage imageNamed:@"FrameStart"]];
//        [self.viewFrame setRightThumbImage:[UIImage imageNamed:@"FrameStart"]];
//
//        // important: reset subviews
//        [self.viewFrame resetSubviews];
//
//        asset = assetCrop;
//
//        //        playerItem = [AVPlayerItem playerItemWithAsset:asset];
//        //        player = [AVPlayer playerWithPlayerItem:playerItem];
//        //        playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
//        //        playerLayer.masksToBounds = YES;
//        //        playerLayer.opacity = 0.75;
//        //        AVAssetTrack *videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
//        //        CGSize size = videoTrack.naturalSize;
//        //        size = CGSizeApplyAffineTransform(size, asset.preferredTransform);
//        //        size = CGSizeApplyAffineTransform(size, videoTrack.preferredTransform);
//        //        size = CGSizeMake(fabs(size.width), fabs(size.height));
//        ////        self.viewVideo.frame = CGRectMake(30, 100, 300, 300 * size.height / size.width);
//        //        playerLayer.frame = self.viewVideo.bounds;
//        //        [self.viewVideo.layer addSublayer:playerLayer];
//        //        [player play];
//
//        //AVPlayerViewController
//        videoCropPlayer=[[AVPlayerViewController alloc]init];
//
//        //---- Display chekerBoard image
//        videoCropPlayer.view.backgroundColor = [UIColor clearColor];
//        //-------
//
//
//        //play Video
//        CGRect bounds = _viewVideo.bounds; // get bounds of parent view
//
//        if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)){
//            bounds = _viewVideoL.bounds; // get bounds of parent view
//        }
//        else{
//            bounds = _viewVideo.bounds; // get bounds of parent view
//        }
//
//        //CGRect subviewFrame = CGRectInset(bounds, 0, 0); // left and right margin of 0
//        videoCropPlayer.view.frame = bounds;
//
//        //adding autoresizing for player
//        videoCropPlayer.view.autoresizingMask = (
//                                                 UIViewAutoresizingFlexibleWidth
//                                                 | UIViewAutoresizingFlexibleHeight
//                                                 );
//        //add to view
//        playerItem = [AVPlayerItem playerItemWithAsset:asset];
//
//        videoCropPlayer.showsPlaybackControls = NO;
//        self->videoCropPlayer.player=[AVPlayer playerWithPlayerItem:playerItem];
//        //[self->videoCropPlayer.player play];
//
//        //        [videoCropPlayer.contentOverlayView addSubview:_viewCrop];
//        //        [videoCropPlayer.contentOverlayView bringSubviewToFront:_viewCrop];
//        //        [videoCropPlayer.contentOverlayView setUserInteractionEnabled:YES];
//
//        self.isPlaying = !self.isPlaying;
//        [self.viewFrame hideTracker:!self.isPlaying];
//        //        [videoCropPlayer.player seekToTime:CurrrentTime];
//        if (CMTimeCompare([asset duration], CurrrentTime) >= 0) {
//            [videoCropPlayer.player seekToTime:CurrrentTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
//        }else{
//            [videoCropPlayer.player seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
//        }
//
//        if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)){
//
//            _originalCenterL = _viewVideoL.center;
//            _originalCenter = _viewVideo.center;
//            _originalRectL = _viewVideoL.frame;
//            _originalRect = _viewVideo.frame;
//
//            [_viewVideoL addSubview:videoCropPlayer.view];
//
//            CGRect newFrame1 = CGRectMake( videoCropPlayer.videoBounds.origin.x, videoCropPlayer.videoBounds.origin.y + _viewTop.bounds.size.height, videoCropPlayer.videoBounds.size.width, videoCropPlayer.videoBounds.size.height);
//
//            self.viewCrop.frame = newFrame1;
//
//            self.viewCrop.layer.borderColor = [UIColor yellowColor].CGColor;
//            self.viewCrop.layer.borderWidth = 3.0f;
//
//            CGRect newFrame = CGRectMake( videoCropPlayer.videoBounds.origin.x, videoCropPlayer.videoBounds.origin.y + _viewTopL.bounds.size.height, videoCropPlayer.videoBounds.size.width, videoCropPlayer.videoBounds.size.height);
//
//            self.viewCropL.frame = newFrame;
//
//            self.viewCropL.layer.borderColor = [UIColor yellowColor].CGColor;
//            self.viewCropL.layer.borderWidth = 3.0f;
//
//            _viewPortrait.hidden = YES;
//            _viewLandscape.hidden = NO;
//
//        }
//        else{
//
//            _originalCenterL = _viewVideoL.center;
//            _originalCenter = _viewVideo.center;
//            _originalRectL = _viewVideoL.frame;
//            _originalRect = _viewVideo.frame;
//
//            [_viewVideo addSubview:videoCropPlayer.view];
//
//            CGRect newFrame1 = CGRectMake( videoCropPlayer.videoBounds.origin.x, videoCropPlayer.videoBounds.origin.y + _viewTop.bounds.size.height, videoCropPlayer.videoBounds.size.width, videoCropPlayer.videoBounds.size.height);
//
//            self.viewCrop.frame = newFrame1;
//
//            self.viewCrop.layer.borderColor = [UIColor yellowColor].CGColor;
//            self.viewCrop.layer.borderWidth = 3.0f;
//
//            CGRect newFrame = CGRectMake( videoCropPlayer.videoBounds.origin.x, videoCropPlayer.videoBounds.origin.y + _viewTopL.bounds.size.height, videoCropPlayer.videoBounds.size.width, videoCropPlayer.videoBounds.size.height);
//
//            self.viewCropL.frame = newFrame;
//
//            self.viewCropL.layer.borderColor = [UIColor yellowColor].CGColor;
//            self.viewCropL.layer.borderWidth = 3.0f;
//
//            _viewPortrait.hidden = NO;
//            _viewLandscape.hidden = YES;
//
//        }
//
//        _imageFrame1.translatesAutoresizingMaskIntoConstraints = NO;
//        _imageFrame2.translatesAutoresizingMaskIntoConstraints = NO;
//        _imageFrame3.translatesAutoresizingMaskIntoConstraints = NO;
//        _imageFrame4.translatesAutoresizingMaskIntoConstraints = NO;
//
//        CGRect newFrame = CGRectMake( videoCropPlayer.videoBounds.origin.x, videoCropPlayer.videoBounds.origin.y + _viewTop.bounds.size.height, videoCropPlayer.videoBounds.size.width, videoCropPlayer.videoBounds.size.height);
//
//        UIImage *image1 = [UIImage imageNamed:@"frame-1"];
//        _imageFrame1 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 234, 20, 20)];
//        _imageFrame1.image = image1;
//        //    _imageFrame1.frame = CGRectMake(_viewCrop.bounds.origin.x, _viewCrop.bounds.origin.y, 20, 20);
//        [_viewCrop addSubview:_imageFrame1];
//        [_viewCrop bringSubviewToFront:_imageFrame1];
//        //    _imageFrame1.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
//        _viewCrop.autoresizesSubviews = YES;
//        _viewCrop.clipsToBounds = YES;
//
//        UIImage *image2 = [UIImage imageNamed:@"frame-2"];
//        _imageFrame2 = [[UIImageView alloc] initWithFrame:CGRectMake(_viewCrop.frame.origin.x, _viewCrop.frame.origin.y, 20, 20)];
//        _imageFrame2.image = image2;
//        [_viewCrop addSubview:_imageFrame2];
//        [_viewCrop bringSubviewToFront:_imageFrame2];
//        //    _imageFrame2.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
//        _viewCrop.autoresizesSubviews = YES;
//        _viewCrop.clipsToBounds = YES;
//
//        UIImage *image3 = [UIImage imageNamed:@"frame-3"];
//        _imageFrame3 = [[UIImageView alloc] initWithFrame:CGRectMake(_viewCrop.frame.origin.x, _viewCrop.frame.origin.y, 20, 20)];
//        _imageFrame3.image = image3;
//        [_viewCrop addSubview:_imageFrame3];
//        [_viewCrop bringSubviewToFront:_imageFrame3];
//        //    _imageFrame3.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
//        _viewCrop.autoresizesSubviews = YES;
//        _viewCrop.clipsToBounds = YES;
//
//        UIImage *image4 = [UIImage imageNamed:@"frame-4"];
//        _imageFrame4 = [[UIImageView alloc] initWithFrame:CGRectMake(_viewCrop.frame.origin.x, _viewCrop.frame.origin.y, 20, 20)];
//        _imageFrame4.image = image4;
//        [_viewCrop addSubview:_imageFrame4];
//        [_viewCrop bringSubviewToFront:_imageFrame4];
//        //    _imageFrame4.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
//        _viewCrop.autoresizesSubviews = YES;
//        _viewCrop.clipsToBounds = YES;
//
//
//
//
//        UIImage *imageL1 = [UIImage imageNamed:@"frame-1"];
//        _imageFrameL1 = [[UIImageView alloc] initWithFrame:CGRectMake(_viewCropL.frame.origin.x, _viewCropL.frame.origin.y, 20, 20)];
//        _imageFrameL1.image = imageL1;
//        [_viewCropL addSubview:_imageFrameL1];
//        [_viewCropL bringSubviewToFront:_imageFrameL1];
//        //    _imageFrameL1.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
//        _viewCropL.autoresizesSubviews = YES;
//        _viewCropL.clipsToBounds = YES;
//
//        UIImage *imageL2 = [UIImage imageNamed:@"frame-2"];
//        _imageFrameL2 = [[UIImageView alloc] initWithFrame:CGRectMake(_viewCropL.frame.origin.x, _viewCropL.frame.origin.y, 20, 20)];
//        _imageFrameL2.image = imageL2;
//        [_viewCropL addSubview:_imageFrameL2];
//        [_viewCropL bringSubviewToFront:_imageFrameL2];
//        //    _imageFrameL2.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
//        _viewCropL.autoresizesSubviews = YES;
//        _viewCropL.clipsToBounds = YES;
//
//        UIImage *imageL3 = [UIImage imageNamed:@"frame-3"];
//        _imageFrameL3 = [[UIImageView alloc] initWithFrame:CGRectMake(_viewCropL.frame.origin.x, _viewCropL.frame.origin.y, 20, 20)];
//        _imageFrameL3.image = imageL3;
//        [_viewCropL addSubview:_imageFrameL3];
//        [_viewCropL bringSubviewToFront:_imageFrameL3];
//        //    _imageFrameL3.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
//        _viewCropL.autoresizesSubviews = YES;
//        _viewCropL.clipsToBounds = YES;
//
//        UIImage *imageL4 = [UIImage imageNamed:@"frame-4"];
//        _imageFrameL4 = [[UIImageView alloc] initWithFrame:CGRectMake(_viewCropL.frame.origin.x, _viewCropL.frame.origin.y, 20, 20)];
//        _imageFrameL4.image = imageL4;
//        [_viewCropL addSubview:_imageFrameL4];
//        [_viewCropL bringSubviewToFront:_imageFrameL4];
//        //    _imageFrameL4.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
//        _viewCropL.autoresizesSubviews = YES;
//        _viewCropL.clipsToBounds = YES;
//
//        [self updateCropCornerViewFrameRotate];
//
//    }
    
//    [_btnSave setEnabled:NO];
//    [_btnSaveL setEnabled:NO];
//    [self performSelector:@selector(orientationChanged) withObject:self afterDelay:1.0];
    
//    _imgConstraintL.image = [UIImage imageNamed:@"off"];
//    _imgConstarint.image = [UIImage imageNamed:@"off"];
    
    //    UIImage *image = [UIImage imageNamed:@"frame"];
    //    TTImageView *_imageFrame = [[TTImageView alloc] initWithFrame:_viewCrop.bounds];
    //    _imageFrame.image = image;
    //    [_viewCrop addSubview:_imageFrame];
    //    [_viewCrop bringSubviewToFront:_imageFrame];
    //    _viewCrop.autoresizesSubviews = YES;
    //    _viewCrop.clipsToBounds = YES;
    
    //    UIImage *image = [UIImage imageNamed:@"frame"];
    //    _viewCrop.layer.contents = (__bridge id _Nullable)(image.CGImage);
    //    _viewCrop.layer.masksToBounds = YES;
    //    _viewCropL.layer.contents = (__bridge id _Nullable)(image.CGImage);
    //    _viewCropL.layer.masksToBounds = YES;
    
    
    //    _viewCornerP = [[CornerView alloc] initWithFrame:_viewCrop.bounds];
    //    _viewCornerP.backgroundColor = UIColor.blueColor;
    //    _viewCornerP.lineColor = UIColor.redColor;
    //    _viewCornerP.lineWidth = 5.0;
    //    _viewCornerP.sizeMultiplier = 2.0;
    //    [_viewCrop addSubview:_viewCornerP];
    //    [_viewCrop bringSubviewToFront:_viewCornerP];
    //    _viewCornerP.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    //    _viewCrop.autoresizesSubviews = YES;
    //    _viewCrop.clipsToBounds = YES;
    
    
    //    self.viewVideo.backgroundColor = [UIColor blackColor];
    //    self.viewVideo.minimumZoomScale = 0.10;
    //    self.viewVideo.maximumZoomScale = 5.0;
    //    self.viewVideo.delegate = self;
    //    self.viewVideo.userInteractionEnabled = YES;
    self.viewVideo.clipsToBounds = YES;
    //
    //    self.viewVideoL.backgroundColor = [UIColor blackColor];
    //    self.viewVideoL.minimumZoomScale = 0.10;
    //    self.viewVideoL.maximumZoomScale = 5.0;
    //    self.viewVideoL.delegate = self;
    //    self.viewVideoL.userInteractionEnabled = YES;
    self.viewVideoL.clipsToBounds = YES;
    
    
//    if (IsLiveCamera) {
//        [self setupLiveVideo];
//    }
    
    
}


#pragma mark - Resizeview

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    
    
    // [self updateCropCornerViewFrameRotate];
//
//    if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)){
//        UITouch *touch = [[event allTouches] anyObject];
//        touchStart = [[touches anyObject] locationInView:self.viewCropL];
//        isResizingLR = (self.viewCropL.bounds.size.width - touchStart.x < kResizeThumbSize && self.viewCropL.bounds.size.height - touchStart.y < kResizeThumbSize);
//        isResizingUL = (touchStart.x <kResizeThumbSize && touchStart.y <kResizeThumbSize);
//        isResizingUR = (self.viewCropL.bounds.size.width-touchStart.x < kResizeThumbSize && touchStart.y<kResizeThumbSize);
//        isResizingLL = (touchStart.x <kResizeThumbSize && self.viewCropL.bounds.size.height -touchStart.y <kResizeThumbSize);
//
//        OriginalrectCropL = self.viewCropL.frame;
//        OriginalcenterCropL = self.viewCropL.center;
//
//
//    }
  //  else{
        UITouch *touch = [[event allTouches] anyObject];
        touchStart = [[touches anyObject] locationInView:self.cropView];
        isResizingLR = (self.cropView.bounds.size.width - touchStart.x < kResizeThumbSize && self.cropView.bounds.size.height - touchStart.y < kResizeThumbSize);
        isResizingUL = (touchStart.x <kResizeThumbSize && touchStart.y <kResizeThumbSize);
        isResizingUR = (self.cropView.bounds.size.width-touchStart.x < kResizeThumbSize && touchStart.y<kResizeThumbSize);
        isResizingLL = (touchStart.x <kResizeThumbSize && self.cropView.bounds.size.height -touchStart.y <kResizeThumbSize);
        
        OriginalrectCrop = self.cropView.frame;
        OriginalcenterCrop = self.cropView.center;
        
        
        
  //  }
    
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    
 //  [self updateCropCornerViewFrameRotate];
   
        
        if ([filterView pointInside:[[touches anyObject] locationInView:_cropView] withEvent:event]) {
            // Do something here!
            
            
            
            CGPoint touchPoint = [[touches anyObject] locationInView:_cropView];
            CGPoint previous = [[touches anyObject] previousLocationInView:_cropView];
            
            CGFloat deltaWidth = touchPoint.x - previous.x;
            CGFloat deltaHeight = touchPoint.y - previous.y;
            
            // get the frame values so we can calculate changes below
            CGFloat x = _cropView.frame.origin.x;
            CGFloat y = _cropView.frame.origin.y;
            CGFloat width = _cropView.frame.size.width;
            CGFloat height = _cropView.frame.size.height;
            
            
            CGRect newVideoFrame = _viewVideo.frame;
            
            
            float wid,hei,hh;
            wid=self.view.frame.size.width;
            //  hh=self.view.frame.size.height-186;
            
            if(wid>1024)
            {
                hei=121.0f;
                hh=self.view.frame.size.height-242;
                
            }else
            {
                hei=93.0f;
                hh=580.0f;
            }
            
            
            //                CGRect newFrame = CGRectMake( filteredVideoView.frame.origin.x,  filteredVideoView.frame.origin.y, filteredVideoView.frame.size.width, filteredVideoView.frame.size.height);
            //
            //                CGRect newFrameBound = CGRectMake( newVideoFrame.origin.x, newFrame.origin.y + newVideoFrame.size.height, newFrame.size.width + newFrame.origin.x, newFrame.size.height );
            //
            //
            //                UIView *parentBound = [[UIView alloc] initWithFrame:newFrameBound];
            //                parentBound.center = filteredVideoView.center;
            
            //                CGRect newFrameBound = CGRectMake( newFrame.origin.x, 105, videoCropPlayer.videoBounds.size.width + newFrame.origin.x, self->_viewPortrait.bounds.size.height - newFrame.origin.y - 15);
            
            CGRect newFrame = CGRectMake( filterView.frame.origin.x, _viewTop.bounds.size.height  + filterView.frame.origin.y, filterView.bounds.size.width, hh);
            
            CGRect newFrameBound = CGRectMake( newFrame.origin.x, 105, newFrame.size.width + newFrame.origin.x, self.view.bounds.size.height - newFrame.origin.y );
            UIView *parentBound = [[UIView alloc] initWithFrame:newFrameBound];
            parentBound.center = filterView.center;
            
            
            
            CGPoint newPoint = CGPointMake(_cropView.center.x + (touchPoint.x - touchStart.x),
                                           _cropView.center.y + (touchPoint.y - touchStart.y));;
            float midPointX = CGRectGetMidX(_cropView.bounds);
            
            
            
            // If too far right...
            if (newPoint.x > parentBound.frame.size.width  - midPointX)
                newPoint.x = parentBound.frame.size.width - midPointX;
            else if (newPoint.x < midPointX + newFrame.origin.x)  // If too far left...
                newPoint.x = midPointX + newFrame.origin.x;
            
            float midPointY = CGRectGetMidY(_cropView.bounds);
            // If too far down...
            if (newPoint.y > parentBound.frame.size.height  - midPointY)
                newPoint.y = parentBound.frame.size.height - midPointY;
            else if (newPoint.y < midPointY + newFrame.origin.y){
                midPointY = midPointY + newFrame.origin.y;
                newPoint.y = midPointY;
            }
            
            
            
//             [self updateCropCornerViewFrameRotate];
            
            
            if (isResizingLR) {
                
                
                
                if (touchPoint.y+deltaWidth > newFrame.size.height || touchPoint.y+deltaWidth + y > newFrame.size.height + newFrame.origin.y){
                    
                    return;
                }
                if (touchPoint.x+deltaWidth > newFrame.size.width || touchPoint.x+deltaWidth + x > newFrame.size.width + newFrame.origin.x){
                    return;
                }
                
                if (IsConstraint == YES) {
                    
                    CGRect currentFrame = CGRectMake(x, y, touchPoint.x+deltaWidth, touchPoint.y+deltaWidth);
                    
                    if (currentFrame.origin.x < 0){
                        return;
                    }
                    //calculate rect
                    CGSize ratiosize = filterView.frame.size;
                    
                    CGFloat aspect = ratiosize.width / ratiosize.height;
                    if (currentFrame.size.width / aspect <= currentFrame.size.height)
                    {
                        currentFrame.size = CGSizeMake(currentFrame.size.width, currentFrame.size.width / aspect);
                    }
                    else
                    {
                        currentFrame.size = CGSizeMake(currentFrame.size.height * aspect, currentFrame.size.height);
                    }
                    
                    self.cropView.frame = currentFrame;
                    TemprectCrop = currentFrame;
                    
                } else {
                    self.cropView.frame = CGRectMake(x, y, touchPoint.x+deltaWidth, touchPoint.y+deltaWidth);
                    TemprectCrop = CGRectMake(x, y, touchPoint.x+deltaWidth, touchPoint.y+deltaWidth);
                }
                
            } else if (isResizingUL) {
                
                if (y+deltaHeight < newFrame.origin.y || height-deltaHeight > newFrame.size.height || x+deltaWidth < newVideoFrame.origin.x){
                    return;
                }
                
                if (width-deltaWidth > newFrame.size.width  || width-deltaWidth + x+deltaWidth > newFrame.size.width + newFrame.origin.x){
                    return;
                }
                
                if (IsConstraint == YES) {
                    
                    CGRect currentFrame = CGRectMake(x+deltaWidth, y+deltaHeight, width-deltaWidth, height-deltaHeight);
                    
                    if (currentFrame.origin.x < 0){
                        return;
                    }
                    //calculate rect
                    CGSize ratiosize = filterView.frame.size;
                    
                    CGFloat aspect = ratiosize.width / ratiosize.height;
                    if (currentFrame.size.width / aspect <= currentFrame.size.height)
                    {
                        currentFrame.size = CGSizeMake(currentFrame.size.width, currentFrame.size.width / aspect);
                    }
                    else
                    {
                        currentFrame.size = CGSizeMake(currentFrame.size.height * aspect, currentFrame.size.height);
                    }
                    
                    self.cropView.frame = currentFrame;
                    TemprectCrop = currentFrame;
                    
                } else {
                    self.cropView.frame = CGRectMake(x+deltaWidth, y+deltaHeight, width-deltaWidth, height-deltaHeight);
                    TemprectCrop = CGRectMake(x+deltaWidth, y+deltaHeight, width-deltaWidth, height-deltaHeight);
                    
                }
                
            } else if (isResizingUR) {
                
                if (y+deltaHeight < newFrame.origin.y || height-deltaHeight > newFrame.size.height){
                    return;
                }
                if (width+deltaWidth > newFrame.size.width || width+deltaWidth + x > newFrame.size.width + newFrame.origin.x){
                    return;
                }
                
                if (IsConstraint == YES) {
                    
                    CGRect currentFrame = CGRectMake(x, y+deltaHeight, width+deltaWidth, height-deltaHeight);
                    
                    //calculate rect
                    CGSize ratiosize = filterView.frame.size;
                    
                    
                    if (currentFrame.origin.x < 0){
                        return;
                    }
                    CGFloat aspect = ratiosize.width / ratiosize.height;
                    if (currentFrame.size.width / aspect <= currentFrame.size.height)
                    {
                        currentFrame.size = CGSizeMake(currentFrame.size.width, currentFrame.size.width / aspect);
                    }
                    else
                    {
                        currentFrame.size = CGSizeMake(currentFrame.size.height * aspect, currentFrame.size.height);
                    }
                    
                    self.cropView.frame = currentFrame;
                    TemprectCrop = currentFrame;
                    
                } else {
                    
                    self.cropView.frame = CGRectMake(x, y+deltaHeight, width+deltaWidth, height-deltaHeight);
                    TemprectCrop = CGRectMake(x, y+deltaHeight, width+deltaWidth, height-deltaHeight);
                    
                }
                
            } else if (isResizingLL) {
                
                if (height+deltaHeight > newFrame.size.height || height+deltaHeight + y > newFrame.size.height + newFrame.origin.y){
                    return;
                }
                if (x+deltaWidth < newVideoFrame.origin.x){
                    return;
                }
                
                if (x+deltaWidth < newFrame.origin.x || width-deltaWidth > newFrame.size.width){
                    return;
                }
                if (IsConstraint == YES) {
                    
                    CGRect currentFrame = CGRectMake(x+deltaWidth, y, width-deltaWidth, height+deltaHeight);
                    
                    if (currentFrame.origin.x < 0){
                        return;
                    }
                    //calculate rect
                    CGSize ratiosize = filterView.frame.size;
                    
                    CGFloat aspect = ratiosize.width / ratiosize.height;
                    if (currentFrame.size.width / aspect <= currentFrame.size.height)
                    {
                        currentFrame.size = CGSizeMake(currentFrame.size.width, currentFrame.size.width / aspect);
                    }
                    else
                    {
                        currentFrame.size = CGSizeMake(currentFrame.size.height * aspect, currentFrame.size.height);
                    }
                    
                    self.cropView.frame = currentFrame;
                    TemprectCrop = currentFrame;
                    
                } else {
                    self.cropView.frame = CGRectMake(x+deltaWidth, y, width-deltaWidth, height+deltaHeight);
                    TemprectCrop = CGRectMake(x+deltaWidth, y, width-deltaWidth, height+deltaHeight);
                    
                }
                
            } else {
                // not dragging from a corner -- move the view
                //                self.viewCrop.center = CGPointMake(self.viewCrop.center.x + touchPoint.x - touchStart.x,
                //                                                   self.viewCrop.center.y + touchPoint.y - touchStart.y);
                self.cropView.center = newPoint;
                TempcenterCrop = newPoint;
                
            }
            
        }
        
       [self updateCropCornerViewFrameRotate];
    }
    
//}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    
  //  [self updateCropCornerViewFrameRotate];
    
    //if (IsLiveCamera == YES) {
        
      //  if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)){
      //      if ([filteredVideoView pointInside:[[touches anyObject] locationInView:self.viewCropL] withEvent:event]) {
    
    if ([filterView pointInside:[[touches anyObject] locationInView:self.cropView] withEvent:event]) {
        if (isResizingLR) {
            [self setNewFrame:TemprectCrop ofView:self.cropView undoFrame:OriginalrectCrop];
        } else if (isResizingUL) {
            [self setNewFrame:TemprectCrop ofView:self.cropView undoFrame:OriginalrectCrop];
            
        } else if (isResizingUR) {
            [self setNewFrame:TemprectCrop ofView:self.cropView undoFrame:OriginalrectCrop];
            
        } else if (isResizingLL) {
            [self setNewFrame:TemprectCrop ofView:self.cropView undoFrame:OriginalrectCrop];
            
        } else {
            [self setNewPoint:TempcenterCrop ofView:self.cropView undoCenter:OriginalcenterCrop];
            
        }
        
    }
    
//    [self updateCropCornerViewFrameRotate];
    
            }
            
//        }else{
//
//            if ([filteredVideoView pointInside:[[touches anyObject] locationInView:self.viewCrop] withEvent:event]) {
//                if (isResizingLR) {
//                    [self setNewFrame:TemprectCrop ofView:self.viewCrop undoFrame:OriginalrectCrop];
//                } else if (isResizingUL) {
//                    [self setNewFrame:TemprectCrop ofView:self.viewCrop undoFrame:OriginalrectCrop];
//
//                } else if (isResizingUR) {
//                    [self setNewFrame:TemprectCrop ofView:self.viewCrop undoFrame:OriginalrectCrop];
//
//                } else if (isResizingLL) {
//                    [self setNewFrame:TemprectCrop ofView:self.viewCrop undoFrame:OriginalrectCrop];
//
//                } else {
//                    [self setNewPoint:TempcenterCrop ofView:self.viewCrop undoCenter:OriginalcenterCrop];
//
//                }
//
//            }
//        }
        
//    } else {
//
//        if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)){
//            if ([self.viewVideoL pointInside:[[touches anyObject] locationInView:self.viewCropL] withEvent:event]) {
//                if (isResizingLR) {
//                    [self setNewFrame:TemprectCropL ofView:self.viewCropL undoFrame:OriginalrectCropL];
//                } else if (isResizingUL) {
//                    [self setNewFrame:TemprectCropL ofView:self.viewCropL undoFrame:OriginalrectCropL];
//
//                } else if (isResizingUR) {
//                    [self setNewFrame:TemprectCropL ofView:self.viewCropL undoFrame:OriginalrectCropL];
//
//                } else if (isResizingLL) {
//                    [self setNewFrame:TemprectCropL ofView:self.viewCropL undoFrame:OriginalrectCropL];
//
//                } else {
//                    [self setNewPoint:TempcenterCropL ofView:self.viewCropL undoCenter:OriginalcenterCropL];
//
//                }
//
//            }
//
//        }else{
//
//            if ([self.viewVideo pointInside:[[touches anyObject] locationInView:self.viewCrop] withEvent:event]) {
//                if (isResizingLR) {
//                    [self setNewFrame:TemprectCrop ofView:self.viewCrop undoFrame:OriginalrectCrop];
//                } else if (isResizingUL) {
//                    [self setNewFrame:TemprectCrop ofView:self.viewCrop undoFrame:OriginalrectCrop];
//
//                } else if (isResizingUR) {
//                    [self setNewFrame:TemprectCrop ofView:self.viewCrop undoFrame:OriginalrectCrop];
//
//                } else if (isResizingLL) {
//                    [self setNewFrame:TemprectCrop ofView:self.viewCrop undoFrame:OriginalrectCrop];
//
//                } else {
//                    [self setNewPoint:TempcenterCrop ofView:self.viewCrop undoCenter:OriginalcenterCrop];
//
//                }
//
//            }
//        }
//
//    }
    
    
//}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//    if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)){
//        if ([self.viewVideoL pointInside:[[touches anyObject] locationInView:self.viewCropL] withEvent:event]) {
//            self.viewCropL.frame = OriginalrectCropL;
//            self.viewCropL.center = OriginalcenterCropL;
//            return;
//        }
//
//    }else{
    
        if ([self.viewVideo pointInside:[[touches anyObject] locationInView:self.cropView] withEvent:event]) {
            self.cropView.frame = OriginalrectCrop;
            self.cropView.center = OriginalcenterCrop;
            return;
        //}
    }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
//    if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)){
//        return CGRectContainsPoint(_viewVideoL.frame, point);
//
//    }
//    else{
        return CGRectContainsPoint(_viewVideo.frame, point);
        
    //}
}

- (void)setNewFrame:(CGRect)newFrame ofView:(UIView *)view undoFrame:(CGRect)undoFrame
{
    // If I'm called because the gesture ended, this pushes an undo action.
    // If I'm called because the user requested an undo, this pushes a redo action.
    [[undoManager prepareWithInvocationTarget:self] setNewFrame:undoFrame ofView:view undoFrame:newFrame];
    NSLog(@"Added in stack");
    // Now actually set the transform.
    view.frame = newFrame;
    
}

- (void)setNewPoint:(CGPoint)newPoint  ofView:(UIView *)view undoCenter:(CGPoint)undoPoint
{
    // If I'm called because the gesture ended, this pushes an undo action.
    // If I'm called because the user requested an undo, this pushes a redo action.
    [[undoManager prepareWithInvocationTarget:self] setNewPoint:undoPoint ofView:view undoCenter:newPoint];
    NSLog(@"Added in stack");
    // Now actually set the transform.
    view.center = newPoint;
    
}

#pragma mark - Additional Methods

-(CGRect)croperValue:(CGRect)test
{
    CGRect newFrame;
    CGRect cropFrame;
    CGRect cropFrame2;
    
    newFrame = CGRectMake( _cropView.frame.origin.x, _cropView.frame.origin.y, _cropView.frame.size.width, _cropView.frame.size.height);
    
    
    CGRect newFrame4 = test;
    
    // CGRect newFrame4 = CGRectMake(0.0f,93.0f,1024.0f,580.0f);
    
    
    CGRect newFrame3 = CGRectMake( newFrame.origin.x - newFrame4.origin.x, newFrame.origin.y - newFrame4.origin.y - _viewTop.frame.size.height, newFrame.size.width, newFrame.size.height);
    
    cropFrame = newFrame3;
    
    cropFrame2 = newFrame4;
    
    CGAffineTransform t = CGAffineTransformMakeScale(1.0 / cropFrame2.size.width, 1.0 / cropFrame2.size.height);
    CGRect unitRect = CGRectApplyAffineTransform(cropFrame, t);
    
    
    
    CGRect MainFrame = newFrame;
    
    
    _croperRect=unitRect;
    _mainFrameRect=MainFrame;
    
    
    return _croperRect;
    
}
-(UIImage *)imageByScalingProportionallyToSize:(CGSize)targetSize resizeImage:(UIImage *)image{
    
    UIImage *sourceImage = image;
    UIImage *newImage = nil;
    
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (!CGSizeEqualToSize(imageSize, targetSize)) {
        
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor < heightFactor)
            scaleFactor = widthFactor;
        else
            scaleFactor = heightFactor;
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        
        if (widthFactor < heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        } else if (widthFactor > heightFactor) {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    
    
    // this is actually the interesting part:
    
    UIGraphicsBeginImageContextWithOptions(targetSize, NO, 0);
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if(newImage == nil) NSLog(@"could not scale image");
    
    
    return newImage ;
}






- (IBAction)fitTOScreenPressed:(id)sender {
    
  // [self setupInitialView];
    
    
    
    [_imageFrame1 removeFromSuperview];
    _imageFrame1 = nil;
    
    [_imageFrame2 removeFromSuperview];
    _imageFrame2 = nil;
    
    [_imageFrame3 removeFromSuperview];
    _imageFrame3 = nil;
    
    [_imageFrame4 removeFromSuperview];
    _imageFrame4 = nil;
    
    
    
    [_cropView setUserInteractionEnabled:YES];
    
    _originalCenterL = _viewVideoL.center;
    _originalCenter = _viewVideo.center;
    _originalRectL = _viewVideoL.frame;
    _originalRect = _viewVideo.frame;
    
    CGRect newFrame1;
    
    newFrame1   = CGRectMake( _viewVideo.frame.origin.x, _viewVideo.frame.origin.y + _viewTop.bounds.size.height, _viewVideo.frame.size.width, _viewVideo.frame.size.height);
    
    self.cropView.frame = newFrame1;
    //   self.cropView.center = _viewVideo.center;
    
    self.cropView.layer.borderColor = [UIColor yellowColor].CGColor;
    self.cropView.layer.borderWidth = 3.0f;
    
    CGRect newFrame = CGRectMake(0, 90, self.view.frame.size.width, 600);
    
    
    newFrame= CGRectMake(0, 90, self.view.frame.size.width, 580);
    
    self.viewCropL.frame = newFrame;
    self.viewCropL.center = _viewVideoL.center;
    
    self.viewCropL.layer.borderColor = [UIColor yellowColor].CGColor;
    self.viewCropL.layer.borderWidth = 3.0f;
    
    //            _viewPortrait.hidden = NO;
    //            _viewLandscape.hidden = YES;
    
    //  }
    
    _imageFrame1.translatesAutoresizingMaskIntoConstraints = NO;
    _imageFrame2.translatesAutoresizingMaskIntoConstraints = NO;
    _imageFrame3.translatesAutoresizingMaskIntoConstraints = NO;
    _imageFrame4.translatesAutoresizingMaskIntoConstraints = NO;
    //
    //        CGRect newFrame = CGRectMake( videoCropPlayer.videoBounds.origin.x, videoCropPlayer.videoBounds.origin.y + _viewTop.bounds.size.height, videoCropPlayer.videoBounds.size.width, videoCropPlayer.videoBounds.size.height);
    
    UIImage *image1 = [UIImage imageNamed:@"frame-4"];
    _imageFrame1 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 234, 20, 20)];
    _imageFrame1.image = image1;
    //    _imageFrame1.frame = CGRectMake(_viewCrop.bounds.origin.x, _viewCrop.bounds.origin.y, 20, 20);
    [_cropView addSubview:_imageFrame1];
    [_cropView bringSubviewToFront:_imageFrame1];
    //    _imageFrame1.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    _cropView.autoresizesSubviews = YES;
    _cropView.clipsToBounds = YES;
    
    UIImage *image2 = [UIImage imageNamed:@"frame-1"];
    _imageFrame2 = [[UIImageView alloc] initWithFrame:CGRectMake(_cropView.frame.origin.x, _cropView.frame.origin.y, 20, 20)];
    _imageFrame2.image = image2;
    [_cropView addSubview:_imageFrame2];
    [_cropView bringSubviewToFront:_imageFrame2];
    //    _imageFrame2.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    _cropView.autoresizesSubviews = YES;
    _cropView.clipsToBounds = YES;
    
    UIImage *image3 = [UIImage imageNamed:@"frame-3"];
    _imageFrame3 = [[UIImageView alloc] initWithFrame:CGRectMake(_cropView.frame.origin.x, _cropView.frame.origin.y, 20, 20)];
    _imageFrame3.image = image3;
    [_cropView addSubview:_imageFrame3];
    [_cropView bringSubviewToFront:_imageFrame3];
    //    _imageFrame3.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    _cropView.autoresizesSubviews = YES;
    _cropView.clipsToBounds = YES;
    
    UIImage *image4 = [UIImage imageNamed:@"frame-2"];
    _imageFrame4 = [[UIImageView alloc] initWithFrame:CGRectMake(_cropView.frame.origin.x, _cropView.frame.origin.y, 20, 20)];
    _imageFrame4.image = image4;
    [_cropView addSubview:_imageFrame4];
    [_cropView bringSubviewToFront:_imageFrame4];
    //    _imageFrame4.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    _cropView.autoresizesSubviews = YES;
    _cropView.clipsToBounds = YES;
    
    
    UIImage *imageL1 = [UIImage imageNamed:@"frame-4"];
    _imageFrameL1 = [[UIImageView alloc] initWithFrame:CGRectMake(_viewCropL.frame.origin.x, _viewCropL.frame.origin.y, 20, 20)];
    _imageFrameL1.image = imageL1;
    [_viewCropL addSubview:_imageFrameL1];
    [_viewCropL bringSubviewToFront:_imageFrameL1];
    //    _imageFrameL1.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    _viewCropL.autoresizesSubviews = YES;
    _viewCropL.clipsToBounds = YES;
    
    UIImage *imageL2 = [UIImage imageNamed:@"frame-1"];
    _imageFrameL2 = [[UIImageView alloc] initWithFrame:CGRectMake(_viewCropL.frame.origin.x, _viewCropL.frame.origin.y, 20, 20)];
    _imageFrameL2.image = imageL2;
    [_viewCropL addSubview:_imageFrameL2];
    [_viewCropL bringSubviewToFront:_imageFrameL2];
    //    _imageFrameL2.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    _viewCropL.autoresizesSubviews = YES;
    _viewCropL.clipsToBounds = YES;
    
    UIImage *imageL3 = [UIImage imageNamed:@"frame-3"];
    _imageFrameL3 = [[UIImageView alloc] initWithFrame:CGRectMake(_viewCropL.frame.origin.x, _viewCropL.frame.origin.y, 20, 20)];
    _imageFrameL3.image = imageL3;
    [_viewCropL addSubview:_imageFrameL3];
    [_viewCropL bringSubviewToFront:_imageFrameL3];
    //    _imageFrameL3.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    _viewCropL.autoresizesSubviews = YES;
    _viewCropL.clipsToBounds = YES;
    
    UIImage *imageL4 = [UIImage imageNamed:@"frame-2"];
    _imageFrameL4 = [[UIImageView alloc] initWithFrame:CGRectMake(_viewCropL.frame.origin.x, _viewCropL.frame.origin.y, 20, 20)];
    _imageFrameL4.image = imageL4;
    [_viewCropL addSubview:_imageFrameL4];
    [_viewCropL bringSubviewToFront:_imageFrameL4];
    //    _imageFrameL4.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    _viewCropL.autoresizesSubviews = YES;
    _viewCropL.clipsToBounds = YES;
    
    [self updateCropCornerViewFrameRotate];
    
    self.viewVideo.clipsToBounds = YES;
    self.viewVideoL.clipsToBounds = YES;
    
    
}



- (UIImage *) screenshot {
    
    CGSize size = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    
    CGRect rec = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    [self.view drawViewHierarchyInRect:rec afterScreenUpdates:YES];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}




- (UIImage *)maskImage1:(UIImage *)image1 withMask1:(UIImage *)maskImage1
{
    CGImageRef maskRef = maskImage1.CGImage;
    
    mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                             CGImageGetHeight(maskRef),
                             CGImageGetBitsPerComponent(maskRef),
                             CGImageGetBitsPerPixel(maskRef),
                             CGImageGetBytesPerRow(maskRef),
                             CGImageGetDataProvider(maskRef), NULL, false);
    
    masked = CGImageCreateWithMask([image1 CGImage], mask);
    //    CFRelease(mask);
    UIImage *img = [UIImage imageWithCGImage:masked];
    //    CGImageRelease(maskRef);
    CGImageRelease(mask);
    CGImageRelease(masked);
    
    mask = nil;
    masked = nil;
    //    PhotoLayout *layout = [self getCurrentLayout];
    //    if ([layout.foreground length] == 0)
    //    {
    //        return nil;
    //    }
    
    return img;
}



- (void)SubscriptionUpdate
{
    WebCommunication *webComm = [[WebCommunication alloc] initWithServiceType:1];
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"userId"] forKey:@"userId"];
    NSURL *serviceUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/subscriptionsList",kAMBaseURL]];
    [webComm callToServerRequestDictionary:dic onURL:serviceUrl WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm) {
     //   [hud hide:YES];
        if (!error)
        {
            NSLog(@"%ld, %@",(long)status_code,response);
            
            flag=@"true";
            
            if ([response[@"subId"] isKindOfClass:[NSNull class]])
            {
                // [self getSubscriptionDetail];
                [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Something went wrong" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            }
            else
            {
                if ([[response objectForKey:@"responseCode"] integerValue] != 1)
                {
                    [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Something went wrong" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                    
                }
                else
                {
                    if (![response[@"subId"] isKindOfClass:[NSNull class]])
                    {
                      //  self.subscriptionId = response[@"subId"];
                        
                        
                        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
                        [defaults setObject:response[@"subId"] forKey:@"subscriptionType"];
                        
                        
                    }
                    else
                    {
                        //self.subscriptionId = @"";
                    }
                    //  [self getAllEvents];
                    //   [self getFOV];
                }
            }
        }
        else
        {
            //  [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Something went wrong" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            
            NSLog(@"%@",error);
        }
        
    }];
    
}







@end

