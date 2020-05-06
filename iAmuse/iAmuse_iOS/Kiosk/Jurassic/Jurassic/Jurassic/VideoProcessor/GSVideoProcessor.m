//
//  GSVideoProcessor.m
//  GreenScreen
//
/*
Copyright (c) 2012 Erik M. Buck

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#import "GSVideoProcessor.h"

@interface GSVideoProcessor ()
@end

@implementation GSVideoProcessor

@synthesize delegate;

-(id) init {
    NSLog(@"%s", __FUNCTION__);
    self = [super init];
    if (self) {
        previewBufferQueue = NULL;
        _cameraDevice = nil;
        videoIn = nil;
        videoOut = nil;
        videoCaptureQueue = nil;
    }
    return self;
}

- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
    _cameraDevice = nil;

    videoCaptureQueue = nil;

    if (videoIn) {
        [videoIn release];
    }

    if (videoOut) {
        [videoOut release];
    }

    if (captureSession) {
        [captureSession release];
        captureSession = nil;
    }

    if (previewBufferQueue) {
        CFRelease(previewBufferQueue);
        previewBufferQueue = NULL;
    }

    [super dealloc];
}

#pragma mark Capture

- (void)captureOutput:(AVCaptureOutput *)captureOutput
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{	    
	if (connection == videoConnection) {        
        // Enqueue it for preview.  This is a shallow queue, so if image
        // processing is taking too long, we'll drop this frame for preview (this
        // keeps preview latency low).
		OSStatus err = CMBufferQueueEnqueue(previewBufferQueue, sampleBuffer);
		if (!err) {        
			dispatch_async(dispatch_get_main_queue(), ^{
				CMSampleBufferRef sbuf = (CMSampleBufferRef)CMBufferQueueDequeueAndRetain(previewBufferQueue);
				if (sbuf) {
					CVImageBufferRef pixBuf = CMSampleBufferGetImageBuffer(sbuf);
					[self.delegate pixelBufferReadyForDisplay:pixBuf];
					CFRelease(sbuf);
				}
			});
		}
	}
}

- (AVCaptureDevice *)videoDeviceWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
        if ([device position] == position)
            return device;
    
    return nil;
}

- (BOOL) setupCaptureSession
{
    NSLog(@"%s", __FUNCTION__);

    BOOL first = NO;

    if (!captureSession) {
        // Create a shallow queue for buffers going to the display for preview.
        OSStatus err = CMBufferQueueCreate(
                kCFAllocatorDefault,
                1,
                CMBufferQueueGetCallbacksForUnsortedSampleBuffers(),
                &previewBufferQueue);

        if (err) {
            [self showError:[NSError errorWithDomain:NSOSStatusErrorDomain
                                                code:err
                                            userInfo:nil]];
        }

        captureSession = [[AVCaptureSession alloc] init];
        first = YES;

        // Back Camera Device
        _cameraDevice = [self videoDeviceWithPosition:AVCaptureDevicePositionBack];
        videoIn = [[[AVCaptureDeviceInput alloc] initWithDevice:_cameraDevice error:nil] autorelease];

        // Input
        if ([captureSession canAddInput:videoIn]) {
            [captureSession addInput:videoIn];
//        captureSession.sessionPreset = AVCaptureSessionPresetMedium;    // 360 x 480
            captureSession.sessionPreset = AVCaptureSessionPresetHigh;      // 720 x 1280
//            captureSession.sessionPreset = AVCaptureSessionPresetPhoto;     // 640 x 852

            // Set max frame rate.
    //    NSError **configError = nil;
        }

        // Output
        videoOut = [[[AVCaptureVideoDataOutput alloc] init] autorelease];
        [videoOut setAlwaysDiscardsLateVideoFrames:YES];
        [videoOut setVideoSettings: @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)}];

        // Thread / Video Processing Pipeline
        videoCaptureQueue = dispatch_queue_create("Video Capture Queue", DISPATCH_QUEUE_SERIAL);
        dispatch_set_context(videoCaptureQueue, self);
        dispatch_set_finalizer_f(videoCaptureQueue, captureQueueCleanup);
        [videoOut setSampleBufferDelegate:self queue:videoCaptureQueue];
        dispatch_release(videoCaptureQueue);
    }

	if (first && [captureSession canAddOutput:videoOut]) {
		[captureSession addOutput:videoOut];
        // Need to reconnect video when we resume too.
        videoConnection = [videoOut connectionWithMediaType:AVMediaTypeVideo];
        NSLog(@"Video Connection established");
    }

	return YES;
}

static void captureQueueCleanup(void* p)
{
    NSLog(@"%s", __FUNCTION__);
//    GSVideoProcessor* processor = (GSVideoProcessor *)p; // cast to original context instance
//    [processor release];  // releases capture session if dealloc is called
}

- (void) setupAndStartCaptureSession
{
    NSLog(@"%s", __FUNCTION__);

    [self setupCaptureSession];

    if (!captureSession.isRunning) {
        [captureSession startRunning];
    }
}

- (void) stopAndTearDownCaptureSession
{
    NSLog(@"%s", __FUNCTION__);
	if (captureSession) {
        [captureSession stopRunning];

//        [[NSNotificationCenter defaultCenter] removeObserver:self
//                                                        name:AVCaptureSessionDidStopRunningNotification
//                                                      object:captureSession];

//        if (videoOut) {
//            [captureSession removeOutput:videoOut];
//            [videoOut setSampleBufferDelegate:nil queue:NULL];
//            videoOut = nil;
//        }
//
//        if (videoIn) {
//            [captureSession removeInput:videoIn];
//            videoIn = nil;
//        }
//
//        [captureSession release];
//        captureSession = nil;
    }
   
//	if (previewBufferQueue) {
//		CFRelease(previewBufferQueue);
//		previewBufferQueue = NULL;
//	}
}

//
//  Override and provide runtime multi-session safe configuration settings.  For
//  example on orientation change.
//
- (void)reconfigure {
}

#pragma mark Error Handling

- (void)showError:(NSError *)error
{
    CFRunLoopPerformBlock(
            CFRunLoopGetMain(),
            kCFRunLoopCommonModes,
            ^(void) {
                UIAlertView *alertView =
                        [[UIAlertView alloc] initWithTitle:
                                [error localizedDescription]
                                                   message:[error localizedFailureReason]
                                                  delegate:nil
                                         cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil];
                [alertView show];
            });
}

@end
