//
//  CTCameraViewController.m
//  Jurassic
//
//  Created by Roland Hordos on 2013-05-25.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import "CTCameraViewController.h"

// OpenGL and dependent video imports.
#import <QuartzCore/CAEAGLLayer.h>
#import "GSVideoProcessor.h"
#import "CTVideoProcessor.h"
#import "AMConstants.h"
#import "Kiosk.h"
#import "PhotoSession.h"
#import "GSGreenScreenEffect.h"

static void CTKioskShowAlert(NSString *message)
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

#define VIDEO_ROTATION_RADIANS (M_PI * 270 / 180.0)

//GLint uniforms[NUM_UNIFORMS];

static CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};

@interface CTCameraViewController () <GSVideoProcessorDelegate> {
}
//@property (strong, nonatomic) GLKTextureInfo *background;
// RH - The video texture cache will be used to manage video frames converted to textures.
@property (nonatomic, readwrite, assign) CVOpenGLESTextureCacheRef videoTextureCache;

- (void)startCamera;
- (void)stopCamera;

@end

@implementation CTCameraViewController

@synthesize videoTextureCache = videoTextureCache_;

- (id)init {
    NSLog(@"%s", __FUNCTION__);
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    videoTextureCache_ = nil;
    glFinish();
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"%s", __FUNCTION__);

    kiosk = [CTKiosk sharedInstance];

    // Listen for orientation changes on the device if we're a camera.
    if (kiosk.deviceMode == CTKioskDeviceModeCamera) {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
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

        // We want to know when the photo has actually been saved.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(newPhotoDidStore:)
                                                     name:AMCameraNewDiskPhotoNotification
                                                   object:nil];

    }
}

- (void)viewWillLayoutSubviews {
    NSLog(@"%s", __FUNCTION__);
    [self updateOrientation];

    // The view may have been flipped due to the GLKView coordinate system being inverted to the UIView.
    if (kiosk && kiosk.camera && kiosk.camera.videoProcessor) {
        [kiosk.camera.videoProcessor reconfigure];
    }

    // Off-board gestures
    // Removed from Storyboard
    if (!tap) {
        tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(screenTap:)];
        tap.numberOfTapsRequired = 1;
        tap.delegate = self;
        [self.view addGestureRecognizer:tap];
    }
}

// Cannot rely on viewDidUnload, is not symmetrical with viewDidLoad and is
// deprecated

//
//  Prepare the view controller with the shared kiosk camera resources.
//
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSLog(@"%s", __FUNCTION__);

    if (kiosk.camera && kiosk.camera.glContext) {

        // TODO - move this into property getter
        kiosk.hasExternalCameraDisplay = ([[UIScreen screens] count] > 1);
        if (kiosk.hasExternalCameraDisplay) {
            NSLog(@"External Camera Display attached.");
        }

//        self.preferredFramesPerSecond = 5;

        [self startCamera];
        [self resetPhotoShoot:nil];

        // Initialize rotated label to use for countdown.
        if (!lblInstruction) {
            // Roughly we want to be bottom center with width approx 250 and height approx 50.
            CGRect parentBounds = self.view.bounds;
            int ourWidth = 250;
            int ourMarginBottom = 20;
            int ourHeight = 45;
            CGRect ourBounds = CGRectMake((parentBounds.size.width - ourWidth) / 2, ourMarginBottom, ourWidth, ourHeight);
            double rotationRads = 0;

            lblInstruction = [[UILabel alloc] initWithFrame:ourBounds];
            lblInstruction.numberOfLines = 1;
            lblInstruction.text = @"";
            lblInstruction.backgroundColor = [UIColor blackColor];
            lblInstruction.layer.cornerRadius = 10;
            lblInstruction.alpha = 1;
            lblInstruction.textColor = [UIColor whiteColor];

            //    lblInstruction.highlightedTextColor = [UIColor blackColor];
            lblInstruction.textAlignment = NSTextAlignmentCenter;
            lblInstruction.font = [UIFont systemFontOfSize:40];

            if (rotationRads != 0) {
                lblInstruction.transform = CGAffineTransformMakeRotation(rotationRads);
            }

            [self.view addSubview:lblInstruction];
        }

        kiosk.camera.runOnce = FALSE;
    } else {
        NSLog(@"No Camera has been configured, cannot start the screen properly.");
    }
    
}

- (void)viewDidAppear:(BOOL)animated
{
    NSLog(@"%s", __FUNCTION__);
    [super viewDidAppear:(BOOL) animated];
    if (!kiosk.camera) {
        // Send the user to configure device mode in the settings, only a
        // device setup as a camera should get the Camera View Controller.
//        [self performSegueWithIdentifier:@"cameraSettings" sender:nil];
        CTKioskShowAlert(@"This device must be configured as a Camera in Settings.");
        [self returnToSplash];
    }
}

//
//  Detach the view from the Camera output.
//
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:(BOOL)animated];    // Call the super class implementation.

    NSLog(@"%s", __FUNCTION__);
    
    // Disconnect from the Camera Output.

    // Make the view's context the current GL.
//    GLKView *view = (GLKView *)self.view;
//    [EAGLContext setCurrentContext:view.context];
//
//    // Stop using the camera's continuous glContext.
//    ((GLKView *)self.view).context = nil;
//    [EAGLContext setCurrentContext:nil];

    [self stopCamera];

//    self.background = nil;
}

- (void)didReceiveMemoryWarning
{
    NSLog(@"%s", __FUNCTION__);
    [super didReceiveMemoryWarning];

    // Dispose of any resources that can be recreated.
    if (kiosk.camera) {
        [kiosk.camera freeMemory];
    }

    // TODO flush texture cache (loaded backgrounds) with CVOpenGLESTextureCacheFlush
    // TODO consider kCVOpenGLESTextureCacheMaximumTextureAgeKey
}

//
//  Ideally all of this is moved into the Camera, unless it directly connects
//  the Camera output to this view.
//
- (void)startCamera
{
    NSLog(@"%s", __FUNCTION__);
    @try {
        [self updateOrientation];

        // Connect the view to the Camera Output.
        GLKView *view = (GLKView *)self.view;
//        NSAssert([view isKindOfClass:[GLKView class]],  @"View controller's view is not a GLKView type.");

        if (view.context != kiosk.camera.glContext)
        {
            view.context = kiosk.camera.glContext;
            view.layer.opaque = YES;

            CAEAGLLayer *eaglLayer = (CAEAGLLayer *)view.layer;
            eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
                    kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                    nil];
        }

        // Determine the photo layout to use for the background.
        PhotoLayout *currentLayout = [self getCurrentLayout];
        [kiosk.camera start:view layout:currentLayout];
        videoTextureCache_ = kiosk.camera.videoTextureCache;

    //    //Setup transparent background with source based transparency blending (source being camera).
    //    glClearColor(0.0f, /* Red */ 0.0f, /* Green */ 0.0f, /* Blue */ 0.0f /* Alpha */);
    //    glEnable(GL_BLEND);
    //    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    //
        // Setup video processor and start capturing video
        kiosk.camera.videoProcessor.delegate = self;
        [kiosk.camera.videoProcessor setupAndStartCaptureSession];
    }
    @catch (NSException *ex) {
        [[NSNotificationCenter defaultCenter]postNotificationName:kAMPresentErrorNotification
                                                           object:ex];

    }
}

- (void)stopCamera
{
    NSLog(@"%s", __FUNCTION__);
    if(countdownTimer) {
        [countdownTimer invalidate];
        countdownTimer = nil;
    }
    shotsRemaining = 0;

    [kiosk.camera stop];
    kiosk.camera.videoProcessor.delegate = nil;
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

    if (currentLayout)
    {
        currentScale = [currentLayout.scale floatValue];
        if (currentScale == 0) {
            currentScale = 1.0;
        }
        currentXOffset = [currentLayout.xOffset floatValue] / 100;
        currentYOffset = [currentLayout.yOffset floatValue] / 100;
    }
    else
    {
        currentScale = 1.0;
        currentXOffset = 0.0;
        currentYOffset = 0.0;
    }
    return currentLayout;
}

/**
* Notification selector.  Note that this is often called with "Unknown" orientation.
*
* Only concerned with Camera.
*/
- (void)deviceOrientationDidChange:(NSNotification *)notification {
    NSLog(@"%s", __FUNCTION__);
    if (kiosk.deviceMode == CTKioskDeviceModeCamera) {
        UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];

        // We only need to handle landscape and portrait.
        if (orientation == UIDeviceOrientationFaceUp ||
                orientation == UIDeviceOrientationFaceDown ||
                orientation == UIDeviceOrientationUnknown ||
                kiosk.camera.deviceOrientation == orientation) {
            return;
        }

        // Update the state variable, an optimization to avoid thrashing.
        kiosk.camera.deviceOrientation = orientation;

        // Optionally delay the reacting calls.
        [self performSelector:@selector(updateOrientation) withObject:nil afterDelay:0];
    }
}

//
//  This is necessary as we find that the device event is not always reliably
//  there when we need it, so we have a way to directly verify orientation.
//
- (void)updateOrientation {
//    if (kiosk.camera && self.view.window) { // we are visible
    if (kiosk.camera) { // we may or may not be visible at this point
        kiosk.camera.deviceOrientation = [[UIDevice currentDevice] orientation];
        kiosk.camera.interfaceOrientation = [self interfaceOrientation];

        if (kiosk.camera.videoProcessor) {
            [kiosk.camera.videoProcessor reconfigure];
        }
    }
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    // This method runs at the frame rate.
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    // This method runs at the frame rate.
}

#pragma mark - Misplaced video processing

/*  This provides an infinite green screen boundary and a way to fix FoV that does not include green screen. */
- (void)cropAndFillFoVGreenScreen:(CVPixelBufferRef) imageBuf {
    // Lock it while we work.
    CVPixelBufferLockBaseAddress(imageBuf,0);
    
    // Profile the frame.
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuf);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuf);
    size_t width = CVPixelBufferGetWidth(imageBuf);
    size_t height = CVPixelBufferGetHeight(imageBuf);
//    NSLog(@"cropAndFillFoVGreenScreen AR %lu:%lu", width, height);

    // Need the frame buffer data in the form of an image.
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(
                                                 baseAddress,
                                                 width, height,
                                                 8, // bits per component of a pixel
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    // Get a CG version of the current context.
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    
    // Push a working context onto the context stack.
    CGContextSaveGState(context);

    // 2014-05 - FLIP LEFT TO RIGHT
    // First flip the frame horizontally.  The user should see themselves move left
    // on the screen when they move left, as a mirror image.
    // Flip the long way, vertical then 180.
    // Rotating 180 means putting the origin on the opposite corner.
    CGContextTranslateCTM(context, width, height);
    CGContextRotateCTM(context, M_PI);

    CGAffineTransform flip = CGAffineTransformMake(-1, 0, 0, 1, width, 0);
    CGContextConcatCTM(context, flip);

    // Now draw the image.
    CGContextDrawImage(context, CGRectMake(0,0,width,height), cgImage);

    // Start with an infinite green screen with no video, at the correct origin depending on rotation, etc.
    // Now draw the FoV curtains in pure green.

    // Correct the adjusted coordinates for OpenGL coords.
    //  2014-05 - FLIP LEFT TO RIGHT
//    CGFloat leftPercent = kiosk.camera.fovCurtainTopPercent;
//    CGFloat rightPercent = kiosk.camera.fovCurtainBottomPercent;
//    CGFloat topPercent = kiosk.camera.fovCurtainLeftPercent;
//    CGFloat bottomPercent = kiosk.camera.fovCurtainRightPercent;
    // Reverted.
    CGFloat leftPercent = kiosk.camera.fovCurtainTopPercent;
    CGFloat rightPercent = kiosk.camera.fovCurtainBottomPercent;
    CGFloat topPercent = kiosk.camera.fovCurtainRightPercent;
    CGFloat bottomPercent = kiosk.camera.fovCurtainLeftPercent;

    // Left.
    CGRect fillRect = CGRectMake (0, 0, width * leftPercent/100, height);
    CGContextSetFillColorWithColor (context, [[UIColor greenColor] CGColor]);
    CGContextFillRect (context, fillRect);

    // Now the right side of the FOV.
    fillRect = CGRectMake (width * (100 - rightPercent) / 100, 0, width * rightPercent / 100, height);
    CGContextSetFillColorWithColor (context, [[UIColor greenColor] CGColor]);
    CGContextFillRect (context, fillRect);

    // Top
    fillRect = CGRectMake (0, height * (100 - topPercent) / 100, width, height * topPercent / 100);
    CGContextSetFillColorWithColor (context, [[UIColor greenColor] CGColor]);
    CGContextFillRect (context, fillRect);
    
    // Bottom
    fillRect =  CGRectMake (0, 0, width, height * bottomPercent/100);
    CGContextSetFillColorWithColor (context, [[UIColor greenColor] CGColor]);
    CGContextFillRect (context, fillRect);

//EXPERIMENT - OVERLAY FOREGROUND MASK

    if (kiosk.camera.foregroundImage) {
        CGContextDrawImage(context, CGRectMake(0,0,width,height), [kiosk.camera.foregroundImage CGImage]);
    }

//EXPERIMENT END

    // Pop the stack and replace (not restore?) the current context with the top one.
    CGContextRestoreGState(context);
    
    // .. then unlock the buffer, we're done.
    CVPixelBufferUnlockBaseAddress(imageBuf,0);
    
    CGImageRelease(cgImage);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    return;
}

/*  In case we have to use the camera video in portrait, we'll need to rotate it before the green screen filter gets it. */
- (void)rotateVideoFrame:(CVPixelBufferRef) imageBuf {
    
    // Lock it while we work.
    CVPixelBufferLockBaseAddress(imageBuf,0);
    
    // Profile the frame.
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuf);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuf);
    size_t width = CVPixelBufferGetWidth(imageBuf);
    size_t height = CVPixelBufferGetHeight(imageBuf);
    
    // Need the frame buffer data in the form of an image.
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(
                                                 baseAddress,
                                                 width, height,
                                                 8, // bits per component of a pixel
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    

    // Get a CG version of the current context.
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    
    // Push a working context onto the context stack.
    CGContextSaveGState(context);
    
    
    //Create a context of the appropriate size
//    UIGraphicsBeginImageContext (size);
//    CGContextRef currentContext = UIGraphicsGetCurrentContext ();
    
    //Build a rect of appropriate size at origin 0,0
    CGRect fillRect = CGRectMake (0, 0, width/2, height/2);
    
    //Set the fill color
    CGContextSetFillColorWithColor (context, [[UIColor greenColor] CGColor]);
    
    //Fill the color
    CGContextFillRect (context, fillRect);
    
    // Manipulate the context coordinate system.
    // Rotate 90 degrees.
	CGContextTranslateCTM(context, width/2, height/2); //????
//	CGContextTranslateCTM(context, 0, 0);
	
	// Rotate the image context ???
	CGContextRotateCTM(context, M_PI_2);
//	CGContextRotateCTM(context, VIDEO_ROTATION_RADIANS);

    // Now draw into this context with the image.  The results should be translated and rotated.
    CGContextDrawImage(context, CGRectMake(0,0,width/2.0,height), cgImage);
    
    
//    UIGraphicsBeginImageContext(backgroundImageRaw.size);
//    CGContextRef context=(UIGraphicsGetCurrentContext());
//    //    CGContextTranslateCTM(context, backgroundImageRaw.size.width/2, backgroundImageRaw.size.height/2);
//    //    CGContextTranslateCTM(context, backgroundImageRaw.size.height, backgroundImageRaw.size.width/2);
//    CGContextRotateCTM (context, M_PI/2) ; //???
//    [backgroundImageRaw drawAtPoint:CGPointMake(0, 0)];
//    UIImage *backgroundImage=UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();

    // TODO - RH - Fill should be transparent.
//    CGContextSetFillColorWithColor(context, [[UIColor greenColor] CGColor]);
//    CGContextFillRect(context, CGRectMake(0, 0, 100, 100));
    
    // TODO - RH - How do we efficiently remove the excess on shrinking, the most common operation?

    // Pop the stack and replace (not restore?) the current context with the top one.
    CGContextRestoreGState(context);
    
    // .. then unlock the buffer, we're done.
    CVPixelBufferUnlockBaseAddress(imageBuf,0);
    
    CGImageRelease(cgImage);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    return;
}

//
// Scale the incoming video frame.
//
- (void)scaleVideoFrame:(CVPixelBufferRef) imageBuf {
    
    // Lock it while we work.
    CVPixelBufferLockBaseAddress(imageBuf,0);
    
    // Profile the frame.
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuf);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuf);
    size_t width = CVPixelBufferGetWidth(imageBuf);
    size_t height = CVPixelBufferGetHeight(imageBuf);
    
    // Need the frame buffer data in the form of an image.
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(
                                                 baseAddress,
                                                 width, height,
                                                 8, // bits per component of a pixel
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGContextSaveGState(context);
    
    CGContextSetFillColorWithColor(context, [[UIColor greenColor] CGColor]);
    CGContextFillRect(context, CGRectMake(0, 0, 400, 400));
    
    CGContextRestoreGState(context);
    
    // .. then unlock the buffer, we're done.
    CVPixelBufferUnlockBaseAddress(imageBuf,0);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    return;
}

// Determine the normalized (0 to 1) X and Y scaling factors and centered offset required to convert to
// a given output X and Y.
- (CGRect)textureSamplingRectForCroppingTextureWithAspectRatio:(CGSize)textureAspectRatio
                                                 toAspectRatio:(CGSize)croppingAspectRatio
{
	CGRect normalizedSamplingRect = CGRectZero;
	CGSize cropScaleAmount = CGSizeMake(croppingAspectRatio.width / textureAspectRatio.width,
                                        croppingAspectRatio.height / textureAspectRatio.height);
//    NSLog(@"textureAspectRatio AR %f:%f", textureAspectRatio.width, textureAspectRatio.height);
//    NSLog(@"croppingAspectRatio AR %f:%f", croppingAspectRatio.width, croppingAspectRatio.height);

    // Get the max of the width and height.
    // TODO - why?
	CGFloat maxScale = fmax(cropScaleAmount.width, cropScaleAmount.height);
	CGSize scaledTextureSize = CGSizeMake(textureAspectRatio.width * maxScale, textureAspectRatio.height * maxScale);
	
	if (cropScaleAmount.height > cropScaleAmount.width) {
		normalizedSamplingRect.size.width = croppingAspectRatio.width / scaledTextureSize.width;
		normalizedSamplingRect.size.height = 1.0;
	} else {
		normalizedSamplingRect.size.height = croppingAspectRatio.height / scaledTextureSize.height;
		normalizedSamplingRect.size.width = 1.0;
	}
    
	// Center crop
	normalizedSamplingRect.origin.x =  (1.0 - normalizedSamplingRect.size.width) / 2;
	normalizedSamplingRect.origin.y =  (1.0 - normalizedSamplingRect.size.height) / 2;
	
	return normalizedSamplingRect;
}


// Here we have an image space buffer from the video processor, before it's displayed.
- (void)pixelBufferReadyForDisplay:(CVPixelBufferRef)videoFrameBuffer
{
    if (!videoFrameBuffer) {
        return;
    }

//    NSParameterAssert(videoFrameBuffer);
//    NSAssert(nil != videoTextureCache_, @"nil texture cache");

    // Crop it for the installation Green Screen bounds we have to work with, required where the camera
    // FoV is not completely within the physical Green Screen.
    [self cropAndFillFoVGreenScreen:videoFrameBuffer];

    size_t videoFrameWidth = CVPixelBufferGetWidth(videoFrameBuffer);
    size_t videoFrameHeight = CVPixelBufferGetHeight(videoFrameBuffer);
//    NSLog(@"Frame AR %lu:%lu", videoFrameWidth, videoFrameHeight);

    // Tweak OpenGL for any runtime settings that may change.
    CVOpenGLESTextureRef videoFrameAsTexture = NULL;
    CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(
                                                                kCFAllocatorDefault,
                                                                videoTextureCache_,
                                                                videoFrameBuffer,
                                                                NULL,
                                                                GL_TEXTURE_2D,
                                                                GL_RGBA,
                                                                (int)videoFrameWidth,
                                                                (int)videoFrameHeight,
                                                                GL_BGRA,//GL_RGBA,
                                                                GL_UNSIGNED_BYTE,
                                                                0,
                                                                &videoFrameAsTexture);


    if (err) {
        NSLog(@"CVOpenGLESTextureCacheCreateTextureFromImage (error: %d)", err);
        return;
    }

    if (videoFrameAsTexture != NULL) {
        // If we're on a retina device, double the density.
        CGSize realAspectRatio = self.view.bounds.size;
        if ([self isRetina]) {
            realAspectRatio = CGSizeMake(self.view.bounds.size.height * 2, self.view.bounds.size.width * 2);
    //        realAspectRatio = CGSizeMake(self.view.bounds.size.width * 2, self.view.bounds.size.height * 2);
        }

        // Scale the video to native resolution.
        CGRect textureSamplingRect = [self textureSamplingRectForCroppingTextureWithAspectRatio:
                                      CGSizeMake(videoFrameWidth, videoFrameHeight)       // from the default video resolution
                                      toAspectRatio:realAspectRatio];                     // to the target video resolution

        // Offset the video in percentage plus or minus from zero.
        // Positive X moves the video target left.
        // Positive Y moves the video target up.
    //    float scaleFactor = 0.5;
    //    float xOffset = 0.30;
    //    float yOffset = -0.06;
        float scaleFactor = currentScale;
        float xOffset = currentXOffset;
        float yOffset = currentYOffset;
    //????
        // Scale the video target object as follows:
        // * To Enlarge:
        // ** TODO divide the width and height by scale factor        (ex: to double the size divide by 2)
        // ** TODO skootch the x and y by 1/scale factor              (ex: to double the size x , y = y * 0.5
        // ** TODO multiply the offset percentage by the scale factor (ex: to double the size ...)
        // ** to double:          x and y += 0.25
        // ** to increase by 50%: x and y += 0.15
        // ** to 10% of size:     x and y corr = -4.5,  x and y offset * ?
        // ** to 15% of size:     x and y corr = -3,    x and y offset * ?
        // ** to 25% of size:     x and y corr = -1.5,  x and y offset * ?
        // ** to 35% of size:     x and y corr = -1.0,  x and y offset * ?
        // ** to 50% of size:     x and y corr = -0.5,  x and y offset * 2
        // ** to 75% of size:     x and y corr = -0.15, x and y offset * ??
        // ** to 85% of size:     x and y corr = -0.1,  x and y offset * ??
        // ** to 90% of size:     x and y corr = -0.05, x and y offset * ??
        textureSamplingRect.size.width = textureSamplingRect.size.width / scaleFactor;
        textureSamplingRect.size.height = textureSamplingRect.size.height / scaleFactor;

        float xScalingCorrection = 0;
        float yScalingCorrection = 0;
        if (scaleFactor > 1) {
            // This scaling pushes the image to the right and down, correct it with positive values.
            textureSamplingRect.origin.x += 0.25;
            textureSamplingRect.origin.y += 0.25;
        } else {
            // This scaling pulls the image to the left and up, correct it with negative values.
            xScalingCorrection = scaleFactor - 1;
            yScalingCorrection = scaleFactor - 1;
            //        xScalingCorrection = -0.05;
            //        yScalingCorrection = -0.05;
            // The x and y target offsets will need to be scaled as well.
            // The same distance at full height will be double the distance at half height.
            xOffset *= 1/scaleFactor;
            yOffset *= 1/scaleFactor;
        }

        // Rendering is 90 degrees off, apparently by the OpenGL axes
        textureSamplingRect.origin.y += xScalingCorrection + xOffset;
        textureSamplingRect.origin.x += yScalingCorrection + yOffset;
    //    textureSamplingRect.origin.x += xScalingCorrection + xOffset;
    //    textureSamplingRect.origin.y += yScalingCorrection + yOffset;

        // The texture vertices are set up such that we flip the texture vertically.
        // This is so that our top left origin buffers match OpenGL's bottom left texture coordinate system.
        GLfloat textureVertices[] =
        {
            CGRectGetMinX(textureSamplingRect), CGRectGetMaxY(textureSamplingRect),
            CGRectGetMaxX(textureSamplingRect), CGRectGetMaxY(textureSamplingRect),
            CGRectGetMinX(textureSamplingRect), CGRectGetMinY(textureSamplingRect),
            CGRectGetMaxX(textureSamplingRect), CGRectGetMinY(textureSamplingRect),
        };

        // Tell OpenGL to use the video frame.
        glBindTexture(CVOpenGLESTextureGetTarget(videoFrameAsTexture),
                      CVOpenGLESTextureGetName(videoFrameAsTexture));

        // Configure the texture filter merging operation.
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

        // Draw the video frame (texture) directly on the screen.  No blending
        // computation required as this is the first texture / image / layer.
        glDisable(GL_BLEND);
        [kiosk.camera.greenScreenEffect prepareToDraw];
        [kiosk.camera render:textureVertices];

        // Unbind the texture, flush the texture cache, and release it's memory.
        glBindTexture(CVOpenGLESTextureGetTarget(videoFrameAsTexture), 0);
        CVOpenGLESTextureCacheFlush(videoTextureCache_, 0);
        CFRelease(videoFrameAsTexture);

        // Rescale the background as natively as possible.  Minimize cropping while retaining aspect ratio.
        textureSamplingRect = [self textureSamplingRectForCroppingTextureWithAspectRatio:CGSizeMake(videoFrameWidth, videoFrameHeight)       // from the default video resolution
                                                                           toAspectRatio:realAspectRatio];                     // to the target video resolution

        GLfloat backgroundTextureVertices[] =
        {
            //  2014-05 FLIP LEFT TO RIGHT
//            CGRectGetMinX(textureSamplingRect), CGRectGetMinY(textureSamplingRect),
//            CGRectGetMaxX(textureSamplingRect), CGRectGetMinY(textureSamplingRect),
//            CGRectGetMinX(textureSamplingRect), CGRectGetMaxY(textureSamplingRect),
//            CGRectGetMaxX(textureSamplingRect), CGRectGetMaxY(textureSamplingRect),
            // Reverted
            CGRectGetMinX(textureSamplingRect), CGRectGetMaxY(textureSamplingRect),
            CGRectGetMaxX(textureSamplingRect), CGRectGetMaxY(textureSamplingRect),
            CGRectGetMinX(textureSamplingRect), CGRectGetMinY(textureSamplingRect),
            CGRectGetMaxX(textureSamplingRect), CGRectGetMinY(textureSamplingRect),
        };

        // Now draw the background, it's the base effect.
        glEnable(GL_BLEND);                                 // Enable color computation from buffer.
        glBlendFunc(GL_ONE_MINUS_DST_ALPHA, GL_DST_ALPHA);  // Blending applies to the destination first.

        [kiosk.camera.effect prepareToDraw];
        [kiosk.camera render:backgroundTextureVertices];

        //TEMP EXPERIMENT
        // try to flip the image left to right
//        glScalef(1, -1, 1);
        //END EXPERIMENT

        glFlush();

        // Draw the merged buffer via the View.
        GLKView *glkView = (GLKView *)self.view;

        if (kiosk.camera.recordNextCompositeFrame) {
            // We've been asked to record a frame.
            kiosk.camera.recordNextCompositeFrame = NO;

            // This works but is like a screenshot AND requires additional
            // processing to rotate it.
            [kiosk.camera setCompositeImage:[(GLKView *) self.view snapshot]
                          incomingTransform:self.view.transform];

            // Use the live graphics context to rotate.
    //        UIImage *glSnap = [self glToUIImage];
    //        kiosk.camera.recentCompositeFrame = glSnap;

    // =-=-=-=-=-
    //        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    //        CGContextRef context = CGBitmapContextCreate(
    //                baseAddress,
    //                width, height,
    //                8, // bits per component of a pixel
    //                bytesPerRow,
    //                colorSpace,
    //                kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    //
    //
    //        // Get a CG version of the current context.
    //        CGImageRef cgImage = CGBitmapContextCreateImage(context);

    // =-=-=-=-
    //        UIImage *image = [UIImage imageNamed:@"testImage.png"];
    //        CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
    //
    //        CGContextTranslateCTM(context, 0, image.size.height);
    //        CGContextScaleCTM(context, 1.0, -1.0);
    //
    //        CGContextDrawImage(context, imageRect, image.CGImage);
    // =--=-=--

            // Save the metadata for this frame as well.
            CFDictionaryRef frameInfo = CVBufferGetAttachments(videoFrameBuffer, kCVAttachmentMode_ShouldPropagate);
//            if (kiosk.camera.recentCompositeFrameInfo) {
//                CFRelease(kiosk.camera.recentCompositeFrameInfo);
//                kiosk.camera.recentCompositeFrameInfo = nil;
//            }
            // TODO - cannot release this the next time through (threading?!) so
            // release when we're done saving?
            kiosk.camera.recentCompositeFrameInfo = CFDictionaryCreateMutableCopy(NULL, 0, frameInfo);

            [[NSNotificationCenter defaultCenter] postNotificationName:AMCameraNewCompositeFrameNotification object:nil];
        }

        [glkView.context presentRenderbuffer:GL_RENDERBUFFER];
    }
}


- (BOOL)isRetina
{
    return [[UIScreen mainScreen] scale] == 2.0;
}

- (void)screenTap:(UITapGestureRecognizer *)gesture {
    NSLog(@"%s", __FUNCTION__);

    [self stopPhotoSession];
}

- (void)returnToSplash {
//    id presenter = self.presentingViewController;
//    if ([presenter conformsToProtocol:@protocol(CameraSessionDelegate)]) {
//        [presenter cameraViewController:self didFinishSession:nil];
//    }
    [self dismissViewControllerAnimated:YES completion: nil];
}

- (void)doUpdateTimer {

    CGFloat countdownSequenceFloat = (CGFloat)countdownSequence;
    CGFloat backgroundAlpha = countdownSequenceFloat / 10.0;
//    NSLog(@"background alpha %f", backgroundAlpha);

    lblInstruction.backgroundColor  = [UIColor colorWithRed:0.0
                                                      green:0.0
                                                       blue:0.0
                                                      alpha:backgroundAlpha];

    // Depending on the sequence, display something different.
    switch (countdownSequence)
    {
        case 0:
            // switch shoot to inactive in photo session
            // take photo
            // save photo
            lblInstruction.text = @"";
            [self takePicture];
            countdownSequence = 10;
            shotsRemaining --;
            if (shotsRemaining <= 0) {
                [countdownTimer invalidate];
                countdownTimer = nil;
            }
            break;
        case 1:
        case 2:
        case 3:
        case 4:
        case 5:
            lblInstruction.text = [NSString stringWithFormat:@"%d", countdownSequence];
            break;
        case 10:
//            [kiosk.camera turnOnTorch];
            [kiosk.camera prepareForPicture];
        default:
            lblInstruction.text = [NSString stringWithFormat:@"Picture %d of %d",
//                                                             countdownSequence,
                                                             (AMNumberOfPicturesPerSession - shotsRemaining + 1),
                                                             AMNumberOfPicturesPerSession];
            break;
            
    }
    
    // Count .. down!
    countdownSequence --;
    
    [self.view setNeedsDisplay];
}

- (void)takePicture {
    /*
     Called during photo shoot when the end of a countdown segment occurs.  Pass it along to the camera.
     */
    [kiosk.camera takePicture];
}

- (void)resetPhotoShoot:(NSNotification *)notification {
    NSLog(@"%s", __FUNCTION__);

    // Initialize Countdown Timer
    shotsRemaining = AMNumberOfPicturesPerSession;
    countdownSequence = 10;
    countdownTimerSelector = @selector(doUpdateTimer);

    if ([self respondsToSelector:countdownTimerSelector]) {
        // create and initialize timer
        countdownTimerMethodSig = [self methodSignatureForSelector:countdownTimerSelector];
        if (countdownTimerMethodSig != nil) {
            countdownTimerInvocation = [NSInvocation invocationWithMethodSignature:countdownTimerMethodSig];
            [countdownTimerInvocation setTarget:self];
            [countdownTimerInvocation setSelector:countdownTimerSelector];

            countdownInterval = kiosk.camera.countdownStepSeconds;
            countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 invocation:countdownTimerInvocation repeats:YES];
        }
        else {
            NSLog(@"Timer method signature is nil");
        }
    }
    else {
        NSLog(@"Timer will not respond to selector");
    }
}

- (void)receiveStopPhotoSession:(NSNotification *)notification {
    /*
     We expect notifications to come in out of the http server thread.
     */
    [self performSelectorOnMainThread:@selector(stopPhotoSession) withObject:nil waitUntilDone:NO];
}


//- (void)receiveStartPhotoSession:(NSNotification *)notification {
//    /*
//     We expect notifications to come in out of the http server thread.
//     */
//    [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
//}


- (void)stopPhotoSession {
    NSLog(@"%s", __FUNCTION__);
    [self returnToSplash];
}


//- (void)start {
//    NSLog(@"%s", __FUNCTION__);
//    [self returnToSplash];
//}


- (void)newPhotoDidStore:(NSNotification *)notification {
    NSLog(@"%s", __FUNCTION__);
    // We expect this notification to come in from the main thread.

    // If there are no remaining shots to take, return to the splash screen.
    if (shotsRemaining <= 0) {
        [self returnToSplash];
    }
}

- (void)settingsViewController:(CTSettingsViewController *)settingsViewController didFinishSettings:(NSUserDefaults *)settings {
    /*
     Delegate for modal view to tell presenting controller it's done, close me.
     */
    NSLog(@"%s", __FUNCTION__);

    [self dismissViewControllerAnimated:YES completion: nil];
    [kiosk loadPersistentSettings:YES];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

@end
