//
//  NHViewController.m
//  SmartPhoto Camera
//
//  Created by Roland Hordos on 2013-05-06.
//  Copyright (c) 2013 Tandroid. All rights reserved.
//

#import "NHViewController.h"

// OpenGL and dependent video imports.
#import <GLKit/GLKit.h>
#import <QuartzCore/CAEAGLLayer.h>
// 3rd party demo quality imports
#import "GSVideoProcessor.h"
#import "GSGreenScreenEffect.h"
#import "GSVideoProcessor.h"
#import <objc/runtime.h>   // TEMP for class_getname for logging



#define BUFFER_OFFSET(i) ((char *)NULL + (i))

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};

GLfloat gCubeVertexData[216] = 
{
    // Data layout for each line below is:
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,
    0.5f, -0.5f, -0.5f,        1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, -0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, -0.5f,          1.0f, 0.0f, 0.0f,
    0.5f, 0.5f, 0.5f,         1.0f, 0.0f, 0.0f,
    
    0.5f, 0.5f, -0.5f,         0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,
    0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,
    0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 1.0f, 0.0f,
    
    -0.5f, 0.5f, -0.5f,        -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, -0.5f,       -1.0f, 0.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 0.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, -0.5f,       -1.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        -1.0f, 0.0f, 0.0f,
    
    -0.5f, -0.5f, -0.5f,       0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         0.0f, -1.0f, 0.0f,
    
    0.5f, 0.5f, 0.5f,          0.0f, 0.0f, 1.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    0.5f, -0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    0.5f, -0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 0.0f, 1.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, 0.0f, 1.0f,
    
    0.5f, -0.5f, -0.5f,        0.0f, 0.0f, -1.0f,
    -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,
    0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f,
    0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f,
    -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 0.0f, -1.0f
};

@interface NHViewController () <GSVideoProcessorDelegate> {
    GLuint _program;
    
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    float _rotation;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    
    const GLfloat *normalizedSquareVertices;
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;
// TODO - CAUTION - 3rd party demo quality
@property (strong, nonatomic) GSGreenScreenEffect *greenScreenEffect;
@property (strong, nonatomic) GLKTextureInfo *background;
@property (nonatomic, readwrite, strong) GSVideoProcessor *videoProcessor;
// RH - The video texture cache will be used to manage video frames converted to textures.
@property (nonatomic, readwrite, assign) CVOpenGLESTextureCacheRef videoTextureCache;
// END TODO


- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
@end

@implementation NHViewController


@synthesize lblTestCmp = lblTestCmp_;

// TODO - CAUTION - 3rd party demo quality
// RH - apparently required due to clumsy use of "delegate" pattern in GLVideoProcessor ..
@synthesize videoProcessor = videoProcessor_;
@synthesize videoTextureCache = videoTextureCache_;
@synthesize effect = effect_;
//???@synthesize baseEffect = baseEffect_;
// END TODO


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // All we need to do is start the Kiosk here.
    if (!kiosk) {
        kiosk = [[CTKiosk alloc] init];
    }
    
    // Initialize Video Processor with Green Screen effect
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
//rh - unnecessary for non 3D rendering?    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self setupGL];
    
    
    // Initialize Countdown Timer
    countdownSequence = 10;
	countdownTimerSelector = @selector(doUpdateTimer);
    
	if ([self respondsToSelector:countdownTimerSelector]) {
		NSLog(@"responds to selector");
        
		// create and initialize timer
		countdownTimerMethodSig = [self methodSignatureForSelector:countdownTimerSelector];
		
		NSLog(@"before nsinvocation created");
		
		if (countdownTimerMethodSig != nil) {
			NSLog(@"countdownTimerMethodSig is non nil");
			countdownTimerInvocation = [NSInvocation invocationWithMethodSignature:countdownTimerMethodSig];
			[countdownTimerInvocation setTarget:self];
			[countdownTimerInvocation setSelector:countdownTimerSelector];
            //			[countdownTimerInvocation retainArguments];
			NSLog(@"after nsinvocation created");
			
			NSObject *testObject = [countdownTimerInvocation target];
			NSLog(@"invocation target: %@", testObject);
			
			testObject = [countdownTimerInvocation methodSignature];
			NSLog(@"invocation method sig: %@", testObject);
			
			countdownInterval = 2.0;
			countdownTimer = [NSTimer scheduledTimerWithTimeInterval:countdownInterval invocation:countdownTimerInvocation repeats:YES];
            
			NSLog(@"have timer");
			
			if ([countdownTimer isValid]) {
				
				NSLog(@"timer is valid");
                
				NSDate *countdownTimerFireDate = [countdownTimer fireDate];
				NSLog(@"fire date is %@", countdownTimerFireDate);
				
                //				[countdownTimer retain];
                //				[countdownTimer fire];
				
				// get the current run loop for debug
				NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
				if (runLoop != nil) {
					
					NSLog(@"have current run loop");
                    //					[runLoop addTimer:countdownTimer forMode:NSDefaultRunLoopMode];
					
					NSLog(@"timer time interval %f", [countdownTimer timeInterval]);
				}
				else {
					NSLog(@"could not get current run loop");
				}
			}
		}
		else {
			NSLog(@"method signature is nil");
		}
	}
	else {
		NSLog(@"does not respond to selector");
	}
	   
    // Initialize rotated label to use for countdown.
//    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 50, 70)];
    lblTestCmp = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 200, 200)];
    lblTestCmp.numberOfLines = 2;
    lblTestCmp.text = @"";
    lblTestCmp.backgroundColor = [UIColor clearColor];
    lblTestCmp.textColor = [UIColor whiteColor];
    
//    lblTestCmp.highlightedTextColor = [UIColor blackColor];
    lblTestCmp.textAlignment = NSTextAlignmentCenter;
    lblTestCmp.font = [UIFont systemFontOfSize:40];
    
    //rotate label 90 degrees
    lblTestCmp.transform = CGAffineTransformMakeRotation( M_PI/2 );
    
    [self.view addSubview:lblTestCmp];
}

- (void)dealloc
{    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }

    // Dispose of any resources that can be recreated.
}


- (void)setupGL
{
    NSAssert(self.effect == nil, @"Why are we running setupGL more than once?");

    [EAGLContext setCurrentContext:self.context];
    
    // Primary layer provides video camera feed with green screen effect as realtime texture filter.
    // Uses defaults: NOt relying on the contents being the same after drawing, and 32 bit RGBA format.
// TODO - RH - more unnecessary code basically used for commentary    CAEAGLLayer *cameraLayer = (CAEAGLLayer *)self.view.layer;
    
    // Use external 3d GreenScreen.  CAUTION:  demo/article quality only
    self.greenScreenEffect = [[GSGreenScreenEffect alloc] init];
    
//rh - orig - named shader files loaded by GreenScreen effect    [self loadShaders];
    
    // Also establish a base OpenGL environment.
    self.effect = [[GLKBaseEffect alloc] init];
    
/*rh - orig gl project - Lighting not required
    self.effect.light0.enabled = GL_TRUE;
    self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 0.4f, 0.4f, 1.0f);
*/
        
    // Set a background image.
    // TODO - RH - move into Photo class.
    self.background = [GLKTextureLoader textureWithCGImage:[[UIImage imageNamed:@"initial_1.jpg"]
                                                            CGImage] options:nil error:NULL];
    self.effect.texture2d0.name = self.background.name;
    self.effect.texture2d0.target = self.background.target;
    
    // Setup transparent background with source based transparency blending (source being camera).
    glClearColor(0.0f, // Red
                 0.0f, // Green
                 0.0f, // Blue
                 0.0f);// Alpha

    glEnable(GL_DEPTH_TEST);    // TODO - RH - orig project - necessary?
    
    // Configure video texture filter.
    
    normalizedSquareVertices = [self isRetina] ? [self retinaVerticies] : [self nonRetinaVerticies];
    
    CVReturn err = CVOpenGLESTextureCacheCreate(
                                                kCFAllocatorDefault,
                                                NULL,
                                                (__bridge CVEAGLContext)((__bridge void *)self.context),
                                                NULL,
                                                &videoTextureCache_);
    
    if (err) {
        NSLog(@"Could not prepare Video real time filter due to %d", err);
    } else {
        // Setup video processor
        self.videoProcessor = [[GSVideoProcessor alloc] init];
        self.videoProcessor.delegate = self;
        [self.videoProcessor setupAndStartCaptureSession];
    }
    
    // TODO - RH - Remove this unnecessary 3D rendering code.
    /*
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(gCubeVertexData), gCubeVertexData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
    
    glBindVertexArrayOES(0);
    */
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    // TODO - RH - move into proper session management structure i.e. PhotoSession class?
    [self.videoProcessor stopAndTearDownCaptureSession];
    
    
    // TODO - RH - unnecessary 3D code?
    /*
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
     */
    
    self.effect = nil;
    self.greenScreenEffect = nil;
    self.videoProcessor.delegate = nil;
    self.videoProcessor = nil;
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    // This method runs at the frame rate.
    
    /* TODO - RH - Remove demo code
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    
    self.effect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -4.0f);
    baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, _rotation, 0.0f, 1.0f, 0.0f);
    
    // Compute the model view matrix for the object rendered with GLKit
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -1.5f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    self.effect.transform.modelviewMatrix = modelViewMatrix;
    
    // Compute the model view matrix for the object rendered with ES2
    modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 1.5f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
    
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    _rotation += self.timeSinceLastUpdate * 0.5f;
     */
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    // This method runs at the frame rate.

    /* TODO - RH - Remove demo code
    
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glBindVertexArrayOES(_vertexArray);
    
    // Render the object with GLKit
    [self.effect prepareToDraw];
    
    glDrawArrays(GL_TRIANGLES, 0, 36);
    
    // Render the object again with ES2
    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
    
    glDrawArrays(GL_TRIANGLES, 0, 36);
    */
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, GLKVertexAttribPosition, "position");
    glBindAttribLocation(_program, GLKVertexAttribNormal, "normal");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}


#pragma mark - Orientation support and Autorotation control.

// Version 1 only supports a single camera device orientation, locked to Landscape.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}
- (BOOL) shouldAutorotate {
    return NO;
}


// iOS6-specific device control
- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationLandscapeRight;
}
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationLandscapeRight;
}


#pragma mark - Misplaced video processing


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
    
    // TODO - RH do we really need to do this?  It is likely very expensive ..
    CGContextSaveGState(context);

    // TODO - RH - Fill should be transparent.
//    CGContextSetFillColorWithColor(context, [[UIColor blackColor] CGColor]);
//    CGContextFillRect(context, CGRectMake(0, 0, 400, 400));
    
    // TODO - RH - How do we efficiently remove the excess on shrinking, the most common operation?
    
    // TODO - RH - Is this the mose efficient way to modify the memory, can it be done in place?
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

//<##>
// Here we have an image space buffer from the video processor, before it's displayed.
- (void)pixelBufferReadyForDisplay:(CVPixelBufferRef)videoFrameBuffer
{
    // Scale it based upon the photo layout.
//TODO - RH - requires fill problem to be solved    [self scaleVideoFrame:pixelBuffer];
    
    NSParameterAssert(videoFrameBuffer);
    NSAssert(nil != videoTextureCache_, @"nil texture cache");
   	
    size_t videoFrameWidth = CVPixelBufferGetWidth(videoFrameBuffer);
    size_t videoFrameHeight = CVPixelBufferGetHeight(videoFrameBuffer);
    
    CVOpenGLESTextureRef videoFrameAsTexture = NULL;
    CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(
                                                                kCFAllocatorDefault,
                                                                videoTextureCache_,
                                                                videoFrameBuffer,
                                                                NULL,
                                                                GL_TEXTURE_2D,
                                                                GL_RGBA,
                                                                videoFrameWidth,
                                                                videoFrameHeight,
                                                                GL_BGRA,
                                                                GL_UNSIGNED_BYTE,
                                                                0,
                                                                &videoFrameAsTexture);
    
    
    if (!videoFrameAsTexture || err) {
        NSLog(@"CVOpenGLESTextureCacheCreateTextureFromImage (error: %d)", err);
        return;
    }
    
    // If we're on a retina device, double the density.
    CGSize realAspectRatio = self.view.bounds.size;
    if ([self isRetina]) {
        realAspectRatio = CGSizeMake(self.view.bounds.size.height * 2, self.view.bounds.size.width * 2);
    }
    
    // RH - Scale the video to native resolution.
    CGRect textureSamplingRect = [self textureSamplingRectForCroppingTextureWithAspectRatio:
        CGSizeMake(videoFrameWidth, videoFrameHeight)       // from the default video resolution
        toAspectRatio:realAspectRatio];                     // to the target video resolution

    // Offset the video in percentage plus or minus from zero.
    // Positive X moves the video target left.
    // Positive Y moves the video target up.
    float scaleFactor = 0.5;
    float xOffset = 0.15;
    float yOffset = -0.06;
//    float scaleFactor = 1f;
//    float xOffset = 0;
//    float yOffset = 0;

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

    textureSamplingRect.origin.x += xScalingCorrection + xOffset;
    textureSamplingRect.origin.y += yScalingCorrection + yOffset;
    
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
    
    // Draw the video frame (texture) directly on the screen.  No blending computation required as this is
    // the first texture / image / layer.
    glDisable(GL_BLEND);
    [self.greenScreenEffect prepareToDraw];
    [self renderWithSquareVertices:normalizedSquareVertices
                   textureVertices:textureVertices];
    
    // Unbind the texture, flush the texture cache, and release it's memory.
    glBindTexture(CVOpenGLESTextureGetTarget(videoFrameAsTexture), 0);
    CVOpenGLESTextureCacheFlush(videoTextureCache_, 0);
    CFRelease(videoFrameAsTexture);

    // Rescale the background as natively as possible.  Minimize cropping while retaining aspect ratio.
    textureSamplingRect = [self textureSamplingRectForCroppingTextureWithAspectRatio:
        CGSizeMake(videoFrameWidth, videoFrameHeight)       // from the default video resolution
        toAspectRatio:realAspectRatio];                     // to the target video resolution
    
    GLfloat backgroundTextureVertices[] =
    {
        CGRectGetMinX(textureSamplingRect), CGRectGetMaxY(textureSamplingRect),
        CGRectGetMaxX(textureSamplingRect), CGRectGetMaxY(textureSamplingRect),
        CGRectGetMinX(textureSamplingRect), CGRectGetMinY(textureSamplingRect),
        CGRectGetMaxX(textureSamplingRect), CGRectGetMinY(textureSamplingRect),
    };
    
    // Now draw the background, it's the base effect.
    glEnable(GL_BLEND);                                 // Enable color computation from buffer.
    glBlendFunc(GL_ONE_MINUS_DST_ALPHA, GL_DST_ALPHA);  // Blending applies to the destination first.
    [self.effect prepareToDraw];
    [self renderWithSquareVertices:normalizedSquareVertices
                   textureVertices:backgroundTextureVertices];
    
    glFlush();
    
    // Draw the merged buffer via the View.
    GLKView *glkView = (GLKView *)self.view;
    [glkView.context presentRenderbuffer:GL_RENDERBUFFER];
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


#pragma mark - Countdown Code
- (void)doUpdateTimer {
	NSLog(@"timer fired");
	
    NSString *countdownSequenceStr = [NSString stringWithFormat:@"%d", countdownSequence];
    
    NSLog(@"Countdown sequence: %@", countdownSequenceStr);
    
//	lblTestCmp.text = @"set from timer";

    // Depending on the sequence, display something different.
    switch (countdownSequence)
    {
        case 0:
            // switch shoot to inactive in photo session
            // take photo
            // save photo
            lblTestCmp.text = @"";
            countdownSequence = 10;
            break;
        case 1:
        case 2:
        case 3:
            lblTestCmp.text = countdownSequenceStr;
            break;
        case 4:
            lblTestCmp.text = @"in";
            break;
        case 5:
            lblTestCmp.text = @"Picture";
            break;
        default:
            lblTestCmp.text = @"Get Ready!  In Position?";
            break;
            
    }
    
    // Count .. down!
    countdownSequence --;
    
}




@end
