//
//  ViewController.m
//  iAmuseTest
//
//  Created by IPHONE-02 on 1/13/15.
//  Copyright (c) 2015 Himanshu. All rights reserved.
//

#import "ViewController.h"
#import "ScreenShotViewController.h"
#import "PhotoSession.h"
#import "Kiosk.h"
#import "AMConstants.h"

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

@interface ViewController ()<colorSelectionDelegate>

@end

@implementation ViewController
@synthesize movieFile, sourcePicture,videoCamera,stillCamera;

- (void)viewDidLoad {
    [super viewDidLoad];

//    UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:@"Select Color" style:UIBarButtonItemStylePlain target:self action:@selector(selectColor)];
//    self.navigationItem.rightBarButtonItem = anotherButton;
    
    kiosk = [CTKiosk sharedInstance];
    // Listen for orientation changes on the device if we're a camera.
    if (kiosk.deviceMode == CTKioskDeviceModeCamera) {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
               
        // Tell us when camera api events happen from the built in web server.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(resetPhotoShoot:)
                                                     name:AMCameraResetPhotoShootNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveStopPhotoSession:)
                                                     name:AMCameraStopPhotoSessionNotification
                                                   object:nil];
        
        // We want to know when the photo has actually been saved.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(newPhotoDidStore:)
                                                     name:AMCameraNewDiskPhotoNotification
                                                   object:nil];
        
    }

    [self setUp];
    // Init Camera
    
    filter = [[GPUImageChromaKeyBlendFilter alloc] init];
    [(GPUImageChromaKeyBlendFilter *)filter setSmoothing:0.1];
    
    
    if(IS_IPHONE_4_OR_LESS)
    {
        stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
        if(IS_IOS_8_OR_LATER)
        {
            [(GPUImageChromaKeyBlendFilter *)filter setColorToReplaceRed:0.0 green:1.0 blue:0.0];
            [(GPUImageChromaKeyBlendFilter *)filter setThresholdSensitivity:0.4];
        }
        else
        {
            [(GPUImageChromaKeyBlendFilter *)filter setColorToReplaceRed:0.0 green:.85 blue:0.0];
            [(GPUImageChromaKeyBlendFilter *)filter setThresholdSensitivity:0.3];
        }
    }
    else
    {
        stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetPhoto cameraPosition:AVCaptureDevicePositionBack];
        [(GPUImageChromaKeyBlendFilter *)filter setColorToReplaceRed:0.0 green:1.0 blue:0.0];
        [(GPUImageChromaKeyBlendFilter *)filter setThresholdSensitivity:0.4];
    }
    stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    stillCamera.horizontallyMirrorFrontFacingCamera = NO;
    stillCamera.horizontallyMirrorRearFacingCamera = NO;
    
    [stillCamera addTarget:filter];
    
    UIImage *inputImage = [UIImage imageNamed:@"background.png"];
    sourcePicture = [[GPUImagePicture alloc] initWithImage:inputImage smoothlyScaleOutput:YES];
    [sourcePicture addTarget:filter];
    
    [sourcePicture processImage];
    
    GPUImageView *filterView = (GPUImageView *)self.cameraView;
    [filter addTarget:filterView];
    [stillCamera startCameraCapture];
    
    
    //[self performSelector:@selector(selectColor) withObject:nil afterDelay:6.0];
    
    
}
-(void)setUp
{
    // Determine the photo layout to use for the background.
    PhotoLayout *layout = [self getCurrentLayout];
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
    CGAffineTransform currentTransform = self.view.transform;
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
        self.bgImage.image = rotatedBackgroundImage;
    } else {
        self.bgImage.image = backgroundImage;
    }
    
    //???    if (self.foregroundImage) {
    //        self.foreground = [GLKTextureLoader textureWithCGImage:[self.foregroundImage CGImage] options:nil error:NULL];
    //    } else {
    //        self.foreground = nil;
    //    }
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

- (PhotoLayout *)getCurrentLayout {
    PhotoLayout *currentLayout = nil;
    if (kiosk.currentPhotoSession && kiosk.currentPhotoSession.entity) {
        currentLayout = kiosk.currentPhotoSession.entity.layout;
    } else {
        // We might not have a session setup yet, so use the default layout for the kiosk.
        if (kiosk.entity && kiosk.entity.defaultLayout) {
            NSLog(@"Using default kiosk photo layout.");
            currentLayout = kiosk.entity.defaultLayout;
        }
    }
    
    if (currentLayout) {
        currentScale = [currentLayout.scale floatValue];
        if (currentScale == 0) {
            currentScale = 1.0;
        }
        currentXOffset = [currentLayout.xOffset floatValue] / 100;
        currentYOffset = [currentLayout.yOffset floatValue] / 100;
    } else {
        currentScale = 1.0;
        currentXOffset = 0.0;
        currentYOffset = 0.0;
    }
    return currentLayout;
}


-(UIImage *)convertViewToImage
{
    UIGraphicsBeginImageContext(self.view.bounds.size);
    [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
-(void)selectColor
{
    UIImage * imageScreenshot = [self convertViewToImage];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone"
                                                                    bundle:[NSBundle mainBundle]];
    ScreenShotViewController *screenShot = [storyboard instantiateViewControllerWithIdentifier:@"ScreenShot_iPhone"];
    screenShot.image = imageScreenshot;
    screenShot.delegate = self;
    [self presentViewController:screenShot animated:YES completion:nil];
}
- (void)colorSelected:(NSArray *)colorComponents
{
    CGFloat red = [colorComponents[0] floatValue];
    CGFloat green = [colorComponents[1] floatValue];
    CGFloat blue = [colorComponents[2] floatValue];
    CGFloat alpha = [colorComponents[3] floatValue];
    // [(GPUImageChromaKeyBlendFilter *)filter setColorToReplaceRed:red green:green blue:blue];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
