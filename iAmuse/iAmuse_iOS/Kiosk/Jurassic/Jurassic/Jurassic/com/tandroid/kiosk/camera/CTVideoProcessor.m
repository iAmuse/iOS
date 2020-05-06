//
// Created by Roland Hordos on 2013-06-21.
// Copyright (c) 2013 iAmuse Inc. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "CTVideoProcessor.h"
#import "CTCamera.h"
#import "CTCameraViewController.h"
#import "GSGreenScreenEffect.h"

static CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};

@interface CTVideoProcessor () {
    const GLfloat *normalizedSquareVertices;
}

//- (BOOL)loadShaders;
//- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
//- (BOOL)linkProgram:(GLuint)prog;
//- (BOOL)validateProgram:(GLuint)prog;

@end

@implementation CTVideoProcessor

@synthesize camera;

- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
    self.camera = nil;
}

- (void)setupGL {
    normalizedSquareVertices = [self isRetina] ? [self retinaVerticies] : [self nonRetinaVerticies];
}


//- (BOOL)loadShaders
//{
//    GLuint vertShader, fragShader;
//    NSString *vertShaderPathname, *fragShaderPathname;
//
//    // Create shader program.
//    _program = glCreateProgram();
//
//    // Create and compile vertex shader.
//    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
//    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
//        NSLog(@"Failed to compile vertex shader");
//        return NO;
//    }
//
//    // Create and compile fragment shader.
//    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
//    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
//        NSLog(@"Failed to compile fragment shader");
//        return NO;
//    }
//
//    // Attach vertex shader to program.
//    glAttachShader(_program, vertShader);
//
//    // Attach fragment shader to program.
//    glAttachShader(_program, fragShader);
//
//    // Bind attribute locations.
//    // This needs to be done prior to linking.
//    glBindAttribLocation(_program, GLKVertexAttribPosition, "position");
//    glBindAttribLocation(_program, GLKVertexAttribNormal, "normal");
//
//    // Link program.
//    if (![self linkProgram:_program]) {
//        NSLog(@"Failed to link program: %d", _program);
//
//        if (vertShader) {
//            glDeleteShader(vertShader);
//            vertShader = 0;
//        }
//        if (fragShader) {
//            glDeleteShader(fragShader);
//            fragShader = 0;
//        }
//        if (_program) {
//            glDeleteProgram(_program);
//            _program = 0;
//        }
//
//        return NO;
//    }
//
//    // Get uniform locations.
//    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
//    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
//
//    // Release vertex and fragment shaders.
//    if (vertShader) {
//        glDetachShader(_program, vertShader);
//        glDeleteShader(vertShader);
//    }
//    if (fragShader) {
//        glDetachShader(_program, fragShader);
//        glDeleteShader(fragShader);
//    }
//
//    return YES;
//}
//
//- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
//{
//    GLint status;
//    const GLchar *source;
//
//    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
//    if (!source) {
//        NSLog(@"Failed to load vertex shader");
//        return NO;
//    }
//
//    *shader = glCreateShader(type);
//    glShaderSource(*shader, 1, &source, NULL);
//    glCompileShader(*shader);
//
//#if defined(DEBUG)
//    GLint logLength;
//    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
//    if (logLength > 0) {
//        GLchar *log = (GLchar *)malloc(logLength);
//        glGetShaderInfoLog(*shader, logLength, &logLength, log);
//        NSLog(@"Shader compile log:\n%s", log);
//        free(log);
//    }
//#endif
//
//    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
//    if (status == 0) {
//        glDeleteShader(*shader);
//        return NO;
//    }
//
//    return YES;
//}
//
//- (BOOL)linkProgram:(GLuint)prog
//{
//    GLint status;
//    glLinkProgram(prog);
//
//#if defined(DEBUG)
//    GLint logLength;
//    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
//    if (logLength > 0) {
//        GLchar *log = (GLchar *)malloc(logLength);
//        glGetProgramInfoLog(prog, logLength, &logLength, log);
//        NSLog(@"Program link log:\n%s", log);
//        free(log);
//    }
//#endif
//
//    glGetProgramiv(prog, GL_LINK_STATUS, &status);
//    if (status == 0) {
//        return NO;
//    }
//
//    return YES;
//}
//
//- (BOOL)validateProgram:(GLuint)prog
//{
//    GLint logLength, status;
//
//    glValidateProgram(prog);
//    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
//    if (logLength > 0) {
//        GLchar *log = (GLchar *)malloc(logLength);
//        glGetProgramInfoLog(prog, logLength, &logLength, log);
//        NSLog(@"Program validate log:\n%s", log);
//        free(log);
//    }
//
//    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
//    if (status == 0) {
//        return NO;
//    }
//
//    return YES;
//}


/*  This provides an infinite green screen boundary and a way to fix FoV that does not include green screen. */
- (void)cropAndFillFoVGreenScreen:(CVPixelBufferRef) imageBuf {
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

    // Now draw the image.
    CGContextDrawImage(context, CGRectMake(0,0,width,height), cgImage);

    // Start with an infinite green screen with no video, at the correct origin depending on rotation, etc.
    // Now draw the FoV curtains in pure green.
    // Left.
    CGFloat leftPercent = camera.fovCurtainLeftPercent;
    CGRect fillRect = CGRectMake (0, 0, width * leftPercent/100, height);
    CGContextSetFillColorWithColor (context, [[UIColor greenColor] CGColor]);
    CGContextFillRect (context, fillRect);

    // Now the right side of the FOV.
    CGFloat rightPercent = camera.fovCurtainRightPercent;
    fillRect = CGRectMake (width * (100 - rightPercent) / 100, 0, width * rightPercent / 100, height);
    CGContextSetFillColorWithColor (context, [[UIColor greenColor] CGColor]);
    CGContextFillRect (context, fillRect);

    // Top
    CGFloat topPercent = camera.fovCurtainTopPercent;
    fillRect = CGRectMake (0, height * (100 - topPercent) / 100, width, height * topPercent / 100);
    CGContextSetFillColorWithColor (context, [[UIColor greenColor] CGColor]);
    CGContextFillRect (context, fillRect);

    // Bottom
    CGFloat bottomPercent = camera.fovCurtainBottomPercent;
    fillRect =  CGRectMake (0, 0, width, height * bottomPercent/100);
    CGContextSetFillColorWithColor (context, [[UIColor greenColor] CGColor]);
    CGContextFillRect (context, fillRect);

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


//<##>
// RH - Scale the incoming video frame.
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

    // Get the max of the width and height.
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


- (void)renderWithSquareVertices:(const GLfloat*)squareVertices
                 textureVertices:(const GLfloat*)textureVertices
{
    // Update attribute values.
    glVertexAttribPointer(GLKVertexAttribPosition,
            2,
            GL_FLOAT,
            0,
            0,
            squareVertices);
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

- (BOOL)isRetina
{
    return [[UIScreen mainScreen] scale] == 2.0;
}

- (void)reconfigure {
    // The open gl texture filter rotates the output so we need to fake out the camera by rotating "back" 90 degrees.
    NSLog(@"%s", __FUNCTION__);

    if (videoConnection) {
//        NSLog(@"Supports Video Orientation: %d", videoConnection.supportsVideoOrientation);

        CTKiosk *kiosk = [CTKiosk sharedInstance];

        UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
        UIInterfaceOrientation interfaceOrientation = kiosk.camera.interfaceOrientation;

        // Does the device orientation match the interface?  If not then adjust.
        if (videoConnection.supportsVideoOrientation) {
            switch (deviceOrientation) {
                case UIDeviceOrientationLandscapeLeft:
//                    NSLog(@"Device orientation: Landscape Left (home button right)");
                    switch (interfaceOrientation) {
                        case UIInterfaceOrientationLandscapeLeft:
//                            NSLog(@"Orientations match, rotate 90 cw.");
                            videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
                            break;
                        case UIInterfaceOrientationLandscapeRight:
//                            NSLog(@"Orientation mis-match, rotate 90 ccw.");
                            videoConnection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
                            break;
                        default:
                            NSLog(@"Unhandled orientation mismatch, device:%ld, interface:%ld", (long)deviceOrientation, (long)interfaceOrientation);
                    }
                    break;
                case UIDeviceOrientationPortrait:
//                    NSLog(@"Device orientation: Portrait");
                    break;
                case UIDeviceOrientationLandscapeRight:
//                    NSLog(@"Device orientation: Landscape Right (home button left)");
                    switch (interfaceOrientation) {
                        case UIInterfaceOrientationLandscapeLeft:
//                            NSLog(@"Orientations match, rotate 90 clockwise.");
                            videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
                            break;
                        case UIInterfaceOrientationLandscapeRight:
//                            NSLog(@"Orientation mis-match, rotate 90 ccw.");
                            videoConnection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
                            break;
                        default:
                            NSLog(@"Unhandled orientation mismatch, device:%ld, interface:%ld", (long)deviceOrientation, (long)interfaceOrientation);
                    }
                    break;
                case UIDeviceOrientationPortraitUpsideDown:
//                    NSLog(@"Device orientation: Portrait Upside Down");
                    break;
                default:
                    NSLog(@"Device orientation: %ld", (long)kiosk.camera.deviceOrientation);
                    break;
            }
        }
    } else {
        NSLog(@"No video connection");
    }
}

-(UIImage *) glToUIImage {
    /*
     This works, just much harder than GKLview snapshot and no apparent savings
     in remaining transformation work.
     */

    NSInteger myDataLength = 320 * 480 * 4;

    // allocate array and read pixels into it.
    GLubyte *buffer = (GLubyte *) malloc(myDataLength);
    glReadPixels(0, 0, 320, 480, GL_RGBA, GL_UNSIGNED_BYTE, buffer);

    // gl renders "upside down" so swap top to bottom into new array.
    // there's gotta be a better way, but this works.
    GLubyte *buffer2 = (GLubyte *) malloc(myDataLength);
    for(int y = 0; y < 480; y++)
    {
        for(int x = 0; x < 320 * 4; x++)
        {
            buffer2[(479 - y) * 320 * 4 + x] = buffer[y * 4 * 320 + x];
        }
    }

    // make data provider with data.
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer2, myDataLength, NULL);

    // prep the ingredients
    int bitsPerComponent = 8;
    int bitsPerPixel = 32;
    int bytesPerRow = 4 * 320;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;

    // make the cgimage
    CGImageRef imageRef = CGImageCreate(320, 480, bitsPerComponent, bitsPerPixel, bytesPerRow,     colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);

    // then make the uiimage from that
    UIImage *myImage = [UIImage imageWithCGImage:imageRef];
    return myImage;
}


@end