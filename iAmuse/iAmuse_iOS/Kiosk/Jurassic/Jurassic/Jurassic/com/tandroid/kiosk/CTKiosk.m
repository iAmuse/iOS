//
//  CTKiosk.m
//  SmartPhoto Camera
//
//  Created by Roland Hordos on 2013-05-06.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import "EXTScope.h"
#import <CoreData/CoreData.h>
#import <ASIHTTPRequest/ASIHTTPRequest.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "CTKiosk.h"
#import "CTBackgroundScreen.h"
#import "AFJSONRequestOperation.h"
#import "AMConstants.h"
#import "PhotoLayout.h"
#import "PhotoSession.h"
#import "CTCameraHTTPConnection.h"
#import "Photo.h"
#import "ASIFormDataRequest.h"
#import "Kiosk.h"
#import "TSMessage.h"
#import "UIImage+iAmuse.h"
#import "AMUtility.h"
#import "AMStorageManager.h"
#import "NSData+Base64.h"
#import "WebCommunication.h"
#import "CTAppDelegate.h"
#import "CTKioskViewController.h"
#import "UIView+Toast.h"
#import "CTSelectSceneViewController.h"

#define kAcceptAndContentType_JSON  @"application/json"
#define kUserId @"userId"
#define kImage @"image"
// for IP address
#include <ifaddrs.h>
#include <arpa/inet.h>
#import <SystemConfiguration/CaptiveNetwork.h>

static void CTKioskShowMessage(NSString *message)
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

static void CTKioskShowAlert(NSString *message)
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

static void CTKioskShowAlertWithError(NSError *error)
{
    CTKioskShowAlert([error localizedDescription]);
}

// Class extension for private setters on readonly properties.
@interface CTKiosk ()
@property (nonatomic) CTKioskDeviceMode deviceMode;
@end

@implementation CTKiosk

@synthesize entity;
@synthesize productCode = _productCode;
@synthesize deviceMode;
@synthesize idleFeelingTimeoutMins;
@synthesize camera;
//@synthesize photoLayouts;
@synthesize currentPhotoLayout;
@synthesize currentPhotoSession;

+ (id)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}


-(id) init {
    NSLog(@"%s", __FUNCTION__);
    self = [super init];
    
    if (self) {
        _productCode = kAMProductCode;
        // TODO - load mode from configuration set by control panel / settings.
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *deviceModePref = [defaults stringForKey:AMDeviceModeSettingsKey];
        if ([deviceModePref isEqualToString:AMDeviceModeStrCamera]) {
            deviceMode = CTKioskDeviceModeCamera;
        } else {
            deviceMode = CTKioskDeviceModeTouchScreen;
        }

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(newDiskPhoto:)
                                                     name:AMCameraNewDiskPhotoNotification
                                                   object:nil];

        // Touch Screen wants to know when it should pull a photo down from
        // the camera.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(newRemoteCameraPhoto:)
                                                     name:AMCameraNewRemotePhotoNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(runTest:)
                                                     name:AMRunTestNotification
                                                   object:nil];

        if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
        {
            camera = [[CTCamera alloc] init];

            physicalBackgroundScreen = [[CTBackgroundScreen alloc] init];

            // Be ready for new photos.
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(newCameraRollPhoto:)
                                                         name:AMCameraNewCameraRollPhotoNotification
                                                       object:nil];

            // Load settings for camera and screen.
//            [self loadPersistentSettings:NO];
           // [self autoConfigureCameraAndTouchDevice];
            
             //greeshma
            
            NSString *userIdValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
            if(userIdValue == nil)
            {
                [self loadPersistentSettings:NO];
            }else
            {
                [self autoConfigureCameraAndTouchDevice];
            }
            
        }
        else
        {
            currentPhotoSession = nil;
            
            self.hasExternalCameraDisplay = FALSE;

            // Load settings.
//            [self loadPersistentSettings:NO];
           // [self autoConfigureCameraAndTouchDevice];
            
            //greeshma
            
            NSString *userIdValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
            if(userIdValue == nil)
            {
                [self loadPersistentSettings:NO];
                
            }else
            {
                [self autoConfigureCameraAndTouchDevice];
                
                
                
                
            }

        }
        

        // Create and assemble our Bonjour aware HTTP server on a fixed port with our custom HTTP connection.
        httpServer = [[HTTPServer alloc] init];
        [httpServer setConnectionClass:[CTCameraHTTPConnection class]];
        [httpServer setType:@"_http._tcp."];        // broadcast presence via Bonjour.
        [httpServer setPort:httpServerPort];

        // Serve files from our Photo Store directory
        NSString * webPath = [self photoStoreDirectory];

//        DDLogInfo(@"Setting http server doc root to %@", webPath);
        [httpServer setDocumentRoot:webPath];
        
    }
    
    return self;
}

- (void)dealloc
{
//    DDLogVerbose(@"%s", __FUNCTION__);
}

- (void)startup:(NSString *)eventId
{
    _storePath = [AMUtility applicationDocumentsDirectory];

    [self startServer];

    // If this is a Camera device, assemble and start a camera.
//    if (deviceMode == CTKioskDeviceModeCamera && self.deviceIdiomIsPhone)
    if (deviceMode == CTKioskDeviceModeCamera)
    {
        if (!camera)
        {
            camera = [[CTCamera alloc] init];
        }
        [self loadPhotoLayouts:eventId];
    }
    else
    {
        // We expect the data to reflect the "relative" file system.  We want the
        // layout files to be in the Documents area, but we'll put them there if they
        // don't exist, taken out of the resource bundle.  If not in the resource
        // bundle either, we don't load them.
        [self loadPhotoLayouts:eventId];
        [self showSplash];
    }
}

- (void)pause
{
    if (httpServer && httpServer.isRunning)
    {
        [httpServer stop];
    }

    if (deviceMode == CTKioskDeviceModeCamera)
    {
        [camera pause];
    }
}

- (void)resume
{
    if (httpServer && !httpServer.isRunning)
    {
        [self startServer];
    }

    if (deviceMode == CTKioskDeviceModeCamera)
    {
        [camera resume];
    }
}

- (void)shutdown
{
    if (httpServer && httpServer.isRunning)
    {
        [httpServer stop];
    }
}

- (BOOL)startServer
{
    // Start the HTTP API service.
    [httpServer stop];
//    if ([httpServer isRunning])
//    {
//        return YES;
//    }
    NSError *error;
    if([httpServer start:&error])
    {
//        DDLogInfo(@"Started HTTP Server on port %hu", [httpServer listeningPort]);
        return TRUE;
    }
    else
    {
//        DDLogError(@"Error starting HTTP Server: %@", error);
        return FALSE;
    }
}

//
//  Necessary for repeatable collection item fetching by index, we need to treat
//  the collection as sorted prior to indexing.
//
//  Note: an NSFetchedResultsController may be more resource-smart here.
//
- (PhotoLayout *)getPhotoLayoutAtIndex:(NSInteger)index {
//    NSSortDescriptor *alphaSort = [NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES];
//??    NSArray *children = [[self.photoLayouts allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:alphaSort]];
    return [self.photoLayouts objectAtIndex:index];
}

- (void)userHeartbeat
{
    [[NSNotificationCenter defaultCenter] postNotificationName:AMDidSenseUser object:self];
}

- (void)autoConfigureCameraAndTouchDevice
{
    CTAppDelegate *delegate = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];

//    MBProgressHUD * hud = [MBProgressHUD showHUDAddedTo:delegate.window animated:YES];
    WebCommunication *webComm = [[WebCommunication alloc] initWithServiceType:1];

    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"userId"] forKey:@"userId"];
    NSURL *serviceUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/getIP",kAMBaseURL]];
    
    // response
    
//    {
//        cameraIP = "192.168.2.43";
//        responseCode = 1;
//        responseDescription = Success;
//        touchIP = "192.168.2.102";
//    }
    
    [webComm callToServerRequestDictionary:dic onURL:serviceUrl WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm) {
        [MBProgressHUD hideHUDForView:delegate.window animated:YES];
        if (!error)
        {
            NSLog(@"%ld, %@",(long)status_code,response);
            if ([[response objectForKey:@"responseCode"] integerValue] != 1)
            {
                [[[UIAlertView alloc] initWithTitle:@"Alert" message:[response objectForKey:@"responseDescription"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                
            }
            else
            {
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                
                NSString * deviceModePref = [defaults stringForKey:AMDeviceModeSettingsKey];
                
                NSString *cameraIP = [response valueForKey:@"cameraIP"];
                NSString *touchIP = [response valueForKey:@"touchIP"];
                [defaults setObject:cameraIP forKey:CAMERA_IP_KEY];
                [defaults setObject:touchIP forKey:TOUCHSCREEN_IP_KEY];

                if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
                {
                    [defaults setObject:[self getIPAddressofDevice] forKey:CAMERA_IP_KEY];
                    [defaults setObject:touchIP forKey:TOUCHSCREEN_IP_KEY];
                }
                else
                {
                    [defaults setObject:[self getIPAddressofDevice] forKey:TOUCHSCREEN_IP_KEY];
                    [defaults setObject:cameraIP forKey:CAMERA_IP_KEY];
                }
                [defaults synchronize];
            }
            
             [self loadPersistentSettings:NO];
        }
    }];
    
    
/*
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * deviceModePref = [defaults stringForKey:AMDeviceModeSettingsKey];
    NSString *ipadd = [self getIPAddressofDevice];
    if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
    {
        [defaults setObject:ipadd forKey:CAMERA_IP_KEY];
        [defaults setObject:@"" forKey:TOUCHSCREEN_IP_KEY];
    }
    else
    {
        [defaults setObject:ipadd forKey:TOUCHSCREEN_IP_KEY];
        [defaults setObject:@"" forKey:CAMERA_IP_KEY];
    }
    [defaults synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AutoConfigureDeviceNotification" object:nil];
    NSString * networkTouchScreenAddress = [defaults stringForKey:TOUCHSCREEN_IP_KEY];
    NSString * networkCameraAddress = [defaults stringForKey:CAMERA_IP_KEY];
    if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
    {
        deviceMode = CTKioskDeviceModeCamera;
        httpServerPort = AMHttpCameraApiPort;
        
        // Need a connection to the touch panel.
        
       // if ([networkTouchScreenAddress length] == 0)
        {
            
            NSArray *arr = [networkCameraAddress componentsSeparatedByString:@"."];
            
            if (arr.count > 3) {
                UIViewController *visibleController = [self visibleViewController];
                hud = [MBProgressHUD showHUDAddedTo:visibleController.view animated:YES];
                hud.mode = MBProgressHUDModeIndeterminate;
                hud.labelText = @"auto configuring device";
                [[[UIApplication sharedApplication] keyWindow] setUserInteractionEnabled:NO];

                self.isGetConnectionDeviceAddress = NO;
                NSInteger range = [arr[3] integerValue];
                for (int i = 0; i < 256; i++) {
                    if (self.isGetConnectionDeviceAddress == YES) {
                        break;
                    }
                    if (i == range) {
                        continue;
                    }
                    NSString * action = @"stop";
                    NSURL *networkUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@.%@.%@.%d:%d/%@",arr[0],arr[1],arr[2],i,AMHttpTouchScreenApiPort,action]];
                    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
                               {
                                   // Background work
                                   [self sendConnectionRequestToDevice:networkUrl andIPAddress:[NSString stringWithFormat:@"%@.%@.%@.%d",arr[0],arr[1],arr[2],i] andRange:i];
                                   dispatch_async(dispatch_get_main_queue(), ^(void)
                                                  {
                                                      // Main thread work (UI usually)
                                                  });
                               });
                }

            }
        }
//        else
//        {
//            networkTouchScreenBaseURL = [NSURL URLWithString:[NSString
//                                                              stringWithFormat:@"http://%@:%d",
//                                                              networkTouchScreenAddress, AMHttpTouchScreenApiPort]];
//            DDLogInfo(@"Touch Panel URL %@", networkTouchScreenBaseURL);
//        }
    }
    else
    {
        deviceMode = CTKioskDeviceModeTouchScreen;
        httpServerPort = AMHttpTouchScreenApiPort;
        
        // Need a connection to the camera.
        // Prepare the connection to the network camera.
       // if ([networkCameraAddress length] == 0)
        {
           
            NSArray *arr = [networkTouchScreenAddress componentsSeparatedByString:@"."];
            
            if (arr.count > 3) {
                UIViewController *visibleController = [self visibleViewController];
                hud = [MBProgressHUD showHUDAddedTo:visibleController.view animated:YES];
                hud.mode = MBProgressHUDModeIndeterminate;
                hud.labelText = @"auto configuring device";
                [[[UIApplication sharedApplication] keyWindow] setUserInteractionEnabled:NO];
                self.isGetConnectionDeviceAddress = NO;
                NSInteger range = [arr[3] integerValue];
                for (int i = 0; i < 256; i++) {
                    if (self.isGetConnectionDeviceAddress == YES) {
                        break;
                    }
                    if (i == range) {
                        continue;
                    }
                    NSString * action = @"stop";
                    
                    NSURL *networkUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@.%@.%@.%d:%d/%@",arr[0],arr[1],arr[2],i,AMHttpCameraApiPort,action]];
                    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
                                   {
                                       // Background work
                                       [self sendConnectionRequestToDevice:networkUrl andIPAddress:[NSString stringWithFormat:@"%@.%@.%@.%d",arr[0],arr[1],arr[2],i] andRange:i];
                                       dispatch_async(dispatch_get_main_queue(), ^(void)
                                                      {
                                                          // Main thread work (UI usually)
                                                      });
                                   });
                }
            }

        }
//        else
//        {
//            networkCameraBaseURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%d",
//                                                         networkCameraAddress, AMHttpCameraApiPort]];
//            DDLogInfo(@"Touch Panel URL %@", networkTouchScreenBaseURL);
//        }
        
    }
*/
}

- (void)sendConnectionRequestToDevice:(NSURL *)url andIPAddress:(NSString *)ipadd andRange:(int)range
{
    
    NSURLRequest * request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];
    NSString *ipAddr = ipadd;
    AFJSONRequestOperation * operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                    success:^(NSURLRequest * request, NSHTTPURLResponse *response, id JSON) {
                        [hud hide:YES];
                        [[[UIApplication sharedApplication] keyWindow] setUserInteractionEnabled:YES];

                        NSLog(@"other device response:%@",response);
                        self.isGetConnectionDeviceAddress = YES;
                        _autoConfigureCount = 5;
                        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
                        NSString * deviceModePref = [defaults stringForKey:AMDeviceModeSettingsKey];
                        if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
                        {
                            [defaults setObject:ipAddr forKey:TOUCHSCREEN_IP_KEY];
                        }
                        else
                        {
                            [defaults setObject:ipAddr forKey:CAMERA_IP_KEY];
                        }
                        [defaults synchronize];
                        if (![self startServer]) {
                            [self startServer];
                        }                        dispatch_async(dispatch_get_main_queue(), ^(void)
                                       {
                                           [[NSNotificationCenter defaultCenter] postNotificationName:@"AutoConfigureDeviceNotification" object:nil];

                                       });

                        
                    }
                                                                                         failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                                                             if (range == 255) {
                                                                                                    [hud hide:YES];
                                                                                                 [[[UIApplication sharedApplication] keyWindow] setUserInteractionEnabled:YES];
                                            self.isGetConnectionDeviceAddress = NO;
                                                                                                 _autoConfigureCount++;                                                 if (_autoConfigureCount < 5) {
                                                                                                     [self autoConfigureCameraAndTouchDevice];
                                                                                                 }}
                                                                                         }];
    [operation start];

}

- (UIViewController *)visibleViewController {
    CTAppDelegate *delegate = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
    UIViewController *rootViewController = delegate.window.rootViewController;
    return [self getVisibleViewControllerFrom:rootViewController];
}

- (UIViewController *) getVisibleViewControllerFrom:(UIViewController *) vc {
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [self getVisibleViewControllerFrom:[((UINavigationController *) vc) visibleViewController]];
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        return [self getVisibleViewControllerFrom:[((UITabBarController *) vc) selectedViewController]];
    } else {
        if (vc.presentedViewController) {
            return [self getVisibleViewControllerFrom:vc.presentedViewController];
        } else {
            return vc;
        }
    }
}

-(void)loadPersistentSettings:(BOOL)showAlert
{
    
    
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * deviceModePref = [defaults stringForKey:AMDeviceModeSettingsKey];

    // Has the device mode changed?
    if (([deviceModePref isEqualToString:AMDeviceModeStrCamera] && (deviceMode != CTKioskDeviceModeCamera)) ||
         ([deviceModePref isEqualToString:AMDeviceModeStrTouchScreen] && (deviceMode != CTKioskDeviceModeTouchScreen)))
    {
       // CTKioskShowMessage(@"Device mode has changed. Please shutdown the app and restart.");
    }

    if ([deviceModePref isEqualToString:AMDeviceModeStrCamera]) // Camera
    {
        deviceMode = CTKioskDeviceModeCamera;
        httpServerPort = AMHttpCameraApiPort;

        // Need a connection to the touch panel.
        NSString * networkTouchScreenAddress = [defaults stringForKey:TOUCHSCREEN_IP_KEY];
        if ([networkTouchScreenAddress length] == 0)
        {
            UIViewController *visibleController = [self visibleViewController];
            if ([visibleController isKindOfClass:[CTKioskViewController class]])
            if([[NSUserDefaults standardUserDefaults] boolForKey:@"isLogin"])
            {
                if (!alert_forIP.isVisible)
                {
                    alert_forIP = [[UIAlertView alloc] initWithTitle:@"Setup"
                                                             message:@"Camera mode requires a network Guest Touchscreen Address."
                                                            delegate:self
                                                   cancelButtonTitle:@"Configure"
                                                   otherButtonTitles:nil];
                    alert_forIP.tag = 101;
                    [alert_forIP show];
                }
            }
            else
            {
                if([[NSUserDefaults standardUserDefaults] boolForKey:@"isLogin"])
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [visibleController.view makeToast:@"Camera mode requires a network Guest Touchscreen Address."];

                    });
                }
            }

            //CTKioskShowAlert(@"Camera mode requires a network Touch Panel "
            //        "Address.");
        }
        else
        {
            networkTouchScreenBaseURL = [NSURL URLWithString:[NSString
                    stringWithFormat:@"http://%@:%d",
                                     networkTouchScreenAddress, AMHttpTouchScreenApiPort]];
            if (![self startServer]) {
                [self startServer];
            }
            DDLogInfo(@"Touch Panel URL %@", networkTouchScreenBaseURL);
        }
    }
    else
    { // Touch screen code
        deviceMode = CTKioskDeviceModeTouchScreen;
        httpServerPort = AMHttpTouchScreenApiPort;

        // Need a connection to the camera.
        // Prepare the connection to the network camera.
        NSString * networkCameraAddress = [defaults stringForKey:CAMERA_IP_KEY]; //Camera Address
        
       
        
//        if([networkCameraAddress isEqualToString:@""])
//        {
//            networkCameraAddress = @"192.168.2.43";
//        }
        
        if ([networkCameraAddress length] == 0)
        {
            UIViewController *visibleController = [self visibleViewController];
            if ([visibleController isKindOfClass:[CTSelectSceneViewController class]])
            {
                if([[NSUserDefaults standardUserDefaults] boolForKey:@"isLogin"])
                {
                if (!alert_forIP.isVisible)
                {
                    alert_forIP = [[UIAlertView alloc] initWithTitle:@"Setup"
                                                             message:@"Guest Touchscreen mode requires a network Camera Address."
                                                            delegate:self
                                                   cancelButtonTitle:@"Configure"
                                                   otherButtonTitles:nil];
                    alert_forIP.tag = 101;
                    [alert_forIP show];
                }
                }
            }
            else
            {
                if([[NSUserDefaults standardUserDefaults] boolForKey:@"isLogin"])
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [visibleController.view makeToast:@"Guest Touchscreen mode requires a network Camera Address."];
//                        
                    });
                }
            }
           // CTKioskShowAlert(@"Touch Screen mode requires a network Camera Address.");
        }
        else
        {
            networkCameraBaseURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%d",
                            networkCameraAddress, AMHttpCameraApiPort]];
            if (![self startServer]) {
                [self startServer];
            }
            DDLogInfo(@"Touch Panel URL %@", networkTouchScreenBaseURL);
        }
        
        // Optional Print Kiosk connection
        NSString * networkPrintKioskAddress = [defaults stringForKey:PRINT_KIOSK_IP_KEY];
        if ([networkPrintKioskAddress length] != 0)
        {
            networkPrintKioskBaseURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%d",
                            networkPrintKioskAddress, AMHttpPrintKioskApiPort]];
            DDLogInfo(@"Print Kiosk URL %@", networkPrintKioskBaseURL);
        }
    }

    if (camera)
    {
        camera.distanceToScreen = [defaults floatForKey:SCREEN_DISTANCE_KEY];           // m
        camera.optimalDistanceToTarget = [defaults floatForKey:TARGET_DISTANCE_KEY];    // m
        camera.fovCurtainLeftPercent = [defaults floatForKey:FOV_CURTAIN_KEY_LEFT];     // %
        camera.fovCurtainRightPercent = [defaults floatForKey:FOV_CURTAIN_KEY_RIGHT];   // %
        camera.fovCurtainTopPercent = [defaults floatForKey:FOV_CURTAIN_KEY_TOP];       // %
        camera.fovCurtainBottomPercent = [defaults floatForKey:FOV_CURTAIN_KEY_BOTTOM]; // %
        camera.countdownStepSeconds = [defaults floatForKey:kAMCameraCountdownStepIntervalKey]; // seconds
        camera.shader = [defaults stringForKey:kAMCameraShaderKey];
    }

    [self setIdleFeelingTimeoutMins:[defaults floatForKey:AMIdleFeelTimeoutKey]];
    
    if (physicalBackgroundScreen)
    {
        physicalBackgroundScreen.width = [defaults floatForKey:SCREEN_WIDTH_KEY];       // m
        physicalBackgroundScreen.height = [defaults floatForKey:SCREEN_HEIGHT_KEY];     // m
    }
}


//
//  Returns valid, enabled, sorted photo layouts with at least an available
//  background.
//
- (void)loadPhotoLayouts:(NSString *)eventId
{
    DDLogVerbose(@"Loading PhotoLayouts from CoreData");

    AMStorageManager * store = [AMStorageManager sharedInstance];
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    NSEntityDescription * entity1 = [NSEntityDescription entityForName:@"PhotoLayout"
                                            inManagedObjectContext:store.currentMOC];
    [request setEntity:entity1];

    // We only want items with an order specified (non NIL)
    NSPredicate * orderExistsPredicate = [NSPredicate predicateWithFormat:@"order != nil"];
    [request setPredicate:orderExistsPredicate];
    //[request setReturnsObjectsAsFaults:NO];
    // fetch photolayout of particular event
    [request setPredicate:[NSPredicate predicateWithFormat:@"eventId = %@",eventId]];
    [request setReturnsObjectsAsFaults:NO];
    // And if the order exists we sort by it.
   // NSSortDescriptor * sortOrderDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];

    // In case of duplicate order we also sort by name.
   // NSSortDescriptor * sortFileNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"background" ascending:YES];

   // [request setSortDescriptors:[NSArray arrayWithObjects:sortOrderDescriptor, sortFileNameDescriptor, nil]];

    NSError * error;
    
    self.photoLayouts = [NSMutableArray arrayWithArray:[store.currentMOC executeFetchRequest:request error:&error]];

    // Post condition - validate the loaded candidate layouts.
    // TODO: commented for debug
  //  [self verifyPhotoLayouts];
}

- (void)importDefaultPhotoLayouts
{
    AMStorageManager * store = [AMStorageManager sharedInstance];

    for (int i=1; i < 7; i++)
    {

        // Create and setup a default instance of a PhotoLayout entity.
        PhotoLayout *photoLayout  = (PhotoLayout *)[NSEntityDescription
                insertNewObjectForEntityForName:@"PhotoLayout"
                         inManagedObjectContext:store.currentMOC];

        // Suffix the default url with the loop counter index.
        NSString *url = [NSString stringWithFormat:@"layout%d.jpg", i];


        [photoLayout setOrder:[NSNumber numberWithInt:i]];
        [photoLayout setBackground:url];
        [photoLayout setScale:@1.0];
        [photoLayout setXOffset:@0.0];
        [photoLayout setYOffset:@0.0];
    }

    // Then store them all.
    NSError *error = [store saveCoreData:nil];
    if (error) {
        DDLogError(@"Error saving photo layouts: %@", [error localizedDescription]);
    }
}

//
//  Throw out any layouts that are not valid.
//
//  If a background file cannot be found in the documents area, it is looked for
//  in the resource bundle.  If it cannot be seen from there, a simple message
//  is broadcast and it is removed from the list of eligible layouts.
//
- (void)verifyPhotoLayouts
{
    if (!self.photoLayouts)
    {
        return;
    }

    NSString * bundlePath = [[NSBundle mainBundle] resourcePath];
    NSString * layoutUrl;
    NSString * layoutBundleUrl;
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSMutableArray * fixups = [NSMutableArray arrayWithCapacity:0];

    // Loop through the loaded photo layouts.
    for (PhotoLayout * photoLayout in self.photoLayouts)
    {
        NSError * error = nil;
        layoutUrl = [_storePath stringByAppendingPathComponent:photoLayout.background];
        if (![fileManager fileExistsAtPath:layoutUrl])
        {
            // Layout background isn't there.  Copy from the bundle if we have it.
            layoutBundleUrl = [bundlePath stringByAppendingPathComponent:photoLayout.background];
            NSLog(@"%@",layoutBundleUrl);
            if ([fileManager fileExistsAtPath:layoutBundleUrl])
            {
                DDLogVerbose(@"Copying default layout %@ in place.", photoLayout.background);

                [fileManager copyItemAtPath:layoutBundleUrl toPath:layoutUrl error:&error];
                if (error)
                {
                    [AMUtility DDLogErrorDetail:error track:NO];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kAMPresentErrorNotification  object:error];
                }
                else
                {
                    // proceed to the foreground image if there is one
//                    if (photoLayout.foreground)
//                    {
//                        layoutUrl = [_storePath stringByAppendingPathComponent:photoLayout.foreground];
//                        layoutBundleUrl = [bundlePath stringByAppendingPathComponent:photoLayout.foreground];
//                        [fileManager copyItemAtPath:layoutBundleUrl toPath:layoutUrl error:nil];
//                    }
                }
            }
            else
            {
                // Remove the missing background from the list.  We can't modify
                // the list mid-enumeration so keep a list of fixups.
                [fixups addObject:photoLayout];

                // And broadcast an error notification.
                NSDictionary *userInfo = @{
                        NSLocalizedDescriptionKey:[NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Missing background image", nil), photoLayout.background],
                        NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Verify the filename in the data store PhotoLayout table.", nil)
                };
                NSError * error = [NSError errorWithDomain:kAMInstallationErrorDomain
                                            code:kAMInstallationErrorBadBackground
                                        userInfo:userInfo];
                [[NSNotificationCenter defaultCenter]postNotificationName:kAMPresentErrorNotification object:error];
            }
        }
    }

    // Consider fixups.
    [self.photoLayouts removeObjectsInArray:fixups];
}

- (NSString *)photoStoreDirectory
{
    NSString * path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return [path stringByAppendingPathComponent:@"Photos"];
}
    
-(BOOL)deviceIdiomIsPhone
{
    return (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone);
}

-(void) showSplash
{
    // It seems proper to let the view controller do this via the app delegate
    // rather than tight-couple to the app instance.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ShowSplash" object:self];
}

- (UIUserInterfaceIdiom)deviceType
{
    return UI_USER_INTERFACE_IDIOM();
}

-(CTPhotoSession *)startPhotoSession:(PhotoLayout *)selectedPhotoLayout
                   selectedSessionId:(NSString *)sessionId
{
    AMStorageManager * store = [AMStorageManager sharedInstance];

    if (selectedPhotoLayout == nil)
    {
        selectedPhotoLayout = [self currentPhotoLayout];
    }
    if([selectedPhotoLayout.cameraHieght intValue] <= 0 || [selectedPhotoLayout.cameraWidth intValue] <= 0)
    {
    //    [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Seems like event is not configured right in web panel. Please configure and publish again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
     //   return nil;
    }
    // Common for both device modes
    currentPhotoSession = [[CTPhotoSession alloc] init];
    // Create and setup a default instance of a PhotoSession entity.
    currentPhotoSession.entity = (PhotoSession *)[NSEntityDescription
            insertNewObjectForEntityForName:@"PhotoSession"
                     inManagedObjectContext:store.currentMOC];

    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
    NSString * photoSessionId = (sessionId) ? sessionId : [NSString
            stringWithFormat:@"%f", timeInterval];
    [currentPhotoSession.entity setPhotoSessionId:photoSessionId];
    [currentPhotoSession.entity setCreatedOn:[NSDate date]];

    // Core Data relationships
    [selectedPhotoLayout addSessionsObject:currentPhotoSession.entity];
    [currentPhotoSession.entity setLayout:selectedPhotoLayout];

    DDLogInfo(@"Kiosk: New Photo Session started.");

    if (deviceMode == CTKioskDeviceModeCamera)
    {
        // If you're a camera you've been poked by the touch screen to join
        // the same session.  This means creating an entity on your device
        // and setting the same photo session id.  This way we'll always
        // track sessions across devices.
    }
    else
    {
        // Kiosk Mode
        // The Get Ready screen is being shown to the user.  We need to tell the camera to get ready too, starting a new Photo Session.  Assumptions:
        // 1) This may be an existing user but we don't know yet.  Solution: create an incrementing session counter, start a new anonymous session which will subsequently be linked to an e-mail account.
        // 2) We don't need to clean up the previous session, leave it's data in place but overwrite it in memory.
        
        // Then prompt the camera to join the same session (same id).
        [self startNetworkCameraPhotoSession];
    }

    NSError * error = [store saveCoreData:nil];
    if (error)
    {
        DDLogVerbose(@"Error saving new photo session: %@", [error localizedDescription]);
        return nil;
    }
    else
    {
        return currentPhotoSession;
    }
}

- (void)startNetworkCameraPhotoSession
{
    if (networkCameraBaseURL)//http://192.168.43.76:8079

    {
        NSURL * url = [NSURL URLWithString:[NSString
                stringWithFormat:@"%@/photosession/%@?background=%@",
                                 networkCameraBaseURL,
                                 currentPhotoSession.entity.photoSessionId,
                                 currentPhotoSession.entity.layout.background
                                            ]];  //http://192.168.43.76:8079/photosession/1550143313.827072?background=/Events/82/367


        // NSURLRequest * request = [NSURLRequest requestWithURL:url];
        NSURLRequest * request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];
        
          NSLog(@"Network Camera Request console: %@", request);

        AFJSONRequestOperation * operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
        success:^(NSURLRequest * request, NSHTTPURLResponse *response, id JSON)
                                              {
            DDLogVerbose(@"Network Camera Response: %@", JSON);
                                                  
                                                  
            NSLog(@"Network Camera JSON: %@", JSON);
            NSLog(@"Network Camera Response_ console: %@", response);
                                                  
        }
        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
                                              {
        //    DDLogVerbose(@"%@", [error userInfo]);
//            NSString * message = [NSString stringWithFormat:@"There was a network issue connecting < %@ > \n Error Description: %@",request.URL, [error userInfo]];
//            [[[UIAlertView alloc] initWithTitle:@"StartPhotoSession" message:@"There was a network issue" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            [[self visibleViewController].view makeToast:@"There was a network issue"];
        }];
        
        [operation start];
    }
    else
    {
        UIViewController *visibleController = [self visibleViewController];
        dispatch_async(dispatch_get_main_queue(), ^{
            [visibleController.view makeToast:@"Touch Screen requires a network Camera Address in Settings."];
            
        });

      //  CTKioskShowAlert(@"Touch Screen requires a network Camera Address in "
           //     "Settings.");
    }
}

- (void)networkCameraThankYou
{
    if (networkCameraBaseURL)
    {
        NSString * action = @"thanks";
        NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",
                                            networkCameraBaseURL, action]];

        //NSURLRequest * urlRequest = [NSURLRequest requestWithURL:url];
        NSURLRequest * urlRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];
        AFJSONRequestOperation * requestOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:urlRequest
        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
      //  DDLogVerbose(@"Camera %@ response: %@", action, JSON);
        }
        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
      //   DDLogVerbose(@"Camera %@ error: %@", action, [error userInfo]);
//         NSString * message = [NSString stringWithFormat:@"There was a network issue connecting < %@ > \n Error Description: %@",request.URL, [error userInfo]];
            
//        [[[UIAlertView alloc] initWithTitle:@"CameraThankYou" message:@"There was a network issue" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            [[self visibleViewController].view makeToast:@"There was a network issue"];

        }];
        [requestOperation start];
    }
}

- (void)pausePhotoSession
{
    /*
     If we're a touch screen we need to pass this along to the camera device over the network.
     */
    if (deviceMode == CTKioskDeviceModeTouchScreen && networkCameraBaseURL)
    {
        NSString * action = @"stop";
        NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",
                        networkCameraBaseURL, action]];

        //NSURLRequest * urlRequest = [NSURLRequest requestWithURL:url];
        NSURLRequest * urlRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];

        AFJSONRequestOperation * requestOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:urlRequest
        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
     //   DDLogVerbose(@"Camera %@ response: %@", action, JSON);
        }
        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
     //   DDLogVerbose(@"Camera %@ error: %@", action, [error userInfo]);
       // NSString * message = [NSString stringWithFormat:@"There was a network issue connecting < %@ > \n Error Description: %@",request.URL, [error userInfo]];

//        [[[UIAlertView alloc] initWithTitle:@"Network Timeout" message:@"We were unable to connect to the other iAmuse device. Check your network settings and restart the application." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            
            
            
          
            
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"Network Timeout"
                                         message:@"Unable to connect to other iAmuse device.Click Refresh in Settings on both devices or restart app, Check Troubleshooting for more info."
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            
            
            UIAlertAction* yesButton = [UIAlertAction
                                        actionWithTitle:@"Troubleshooting"
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action) {
                                            [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://support.iamuse.com/portal/kb/iamuse-setup/troubleshooting/network-connection-issues"]];
                                            NSLog(@"troubleshooting");
                                            //Handle your yes please button action here
                                        }];
            
            UIAlertAction* noButton = [UIAlertAction
                                       actionWithTitle:@"Cancel"
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction * action) {
                                           //Handle no, thanks button
                                       }];
            
            [alert addAction:yesButton];
            [alert addAction:noButton];
            
            
            
            
            
            
            
            
            UIWindow *keyWindow = [[UIApplication sharedApplication]keyWindow];
            UIViewController *mainController = [keyWindow rootViewController];
      //      [mainController presentViewController:alert animated:YES completion:nil];
            
        }];
        [requestOperation start];
    }
    else
    {
        UIViewController *visibleController = [self visibleViewController];
        dispatch_async(dispatch_get_main_queue(), ^{
     //       [visibleController.view makeToast:@"Touch Screen requires a network Camera Address in Settings."];
            
        });
//        CTKioskShowAlert(@"Touch Screen requires a network Camera Address in "
//                "Settings.");
    }
}







- (void)gotoThankYou
{
    /*
     If we're a touch screen we need to pass this along to the camera device over the network.
     */
    if (deviceMode == CTKioskDeviceModeTouchScreen && networkCameraBaseURL)
    {
        NSString * action = @"gotoThankYou";
        NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",
                                            networkCameraBaseURL, action]];
        
        //NSURLRequest * urlRequest = [NSURLRequest requestWithURL:url];
        NSURLRequest * urlRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];
        
        AFJSONRequestOperation * requestOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:urlRequest
                                                                                                    success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                                                                        //   DDLogVerbose(@"Camera %@ response: %@", action, JSON);
                                                                                                    }
                                                                                                    failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                                                                        //   DDLogVerbose(@"Camera %@ error: %@", action, [error userInfo]);
                                                                                                        // NSString * message = [NSString stringWithFormat:@"There was a network issue connecting < %@ > \n Error Description: %@",request.URL, [error userInfo]];
                                                                                                        
//                                                                                                        [[[UIAlertView alloc] initWithTitle:@"Network Timeout" message:@"We were unable to connect to the other iAmuse device. Check your network settings and restart the application." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        UIAlertController * alert = [UIAlertController
                                                                                                                                     alertControllerWithTitle:@"Network Timeout"
                                                                                                                                     message:@"Unable to connect to other iAmuse device.Click Refresh in Settings on both devices or restart app, Check Troubleshooting for more info."
                                                                                                                                     preferredStyle:UIAlertControllerStyleAlert];
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        UIAlertAction* yesButton = [UIAlertAction
                                                                                                                                    actionWithTitle:@"Troubleshooting"
                                                                                                                                    style:UIAlertActionStyleDefault
                                                                                                                                    handler:^(UIAlertAction * action) {
                                                                                                                                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://support.iamuse.com/portal/kb/iamuse-setup/troubleshooting/network-connection-issues"]];
                                                                                                                                        NSLog(@"troubleshooting");
                                                                                                                                        //Handle your yes please button action here
                                                                                                                                    }];
                                                                                                        
                                                                                                        UIAlertAction* noButton = [UIAlertAction
                                                                                                                                   actionWithTitle:@"Cancel"
                                                                                                                                   style:UIAlertActionStyleDefault
                                                                                                                                   handler:^(UIAlertAction * action) {
                                                                                                                                       //Handle no, thanks button
                                                                                                                                   }];
                                                                                                        
                                                                                                        [alert addAction:yesButton];
                                                                                                        [alert addAction:noButton];
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        UIWindow *keyWindow = [[UIApplication sharedApplication]keyWindow];
                                                                                                        UIViewController *mainController = [keyWindow rootViewController];
                                                                                                        [mainController presentViewController:alert animated:YES completion:nil];
                                                                                                    }];
        [requestOperation start];
    }
    else
    {
        UIViewController *visibleController = [self visibleViewController];
        dispatch_async(dispatch_get_main_queue(), ^{
        //    [visibleController.view makeToast:@"Touch Screen requires a network Camera Address in Settings."];
            
        });
        //        CTKioskShowAlert(@"Touch Screen requires a network Camera Address in "
        //                "Settings.");
    }
}









- (void)action
{
    /*
     If we're a touch screen we need to pass this along to the camera device over the network.
     */
    if (deviceMode == CTKioskDeviceModeTouchScreen && networkCameraBaseURL)
    {
        NSString * action = @"ajay";
        NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",
                                            networkCameraBaseURL, action]];
        
        //NSURLRequest * urlRequest = [NSURLRequest requestWithURL:url];
        NSURLRequest * urlRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];
        
        AFJSONRequestOperation * requestOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:urlRequest
                                                                                                    success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                                                                        //   DDLogVerbose(@"Camera %@ response: %@", action, JSON);
                                                                                                    }
                                                                                                    failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                                                                        //   DDLogVerbose(@"Camera %@ error: %@", action, [error userInfo]);
                                                                                                        // NSString * message = [NSString stringWithFormat:@"There was a network issue connecting < %@ > \n Error Description: %@",request.URL, [error userInfo]];
                                                                                                        
//                                                                                                        [[[UIAlertView alloc] initWithTitle:@"Network Timeout" message:@"We were unable to connect to the other iAmuse device. Check your network settings and restart the application." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        UIAlertController * alert = [UIAlertController
                                                                                                                                     alertControllerWithTitle:@"Network Timeout"
                                                                                                                                     message:@"Unable to connect to other iAmuse device.Click Refresh in Settings on both devices or restart app, Check Troubleshooting for more info."
                                                                                                                                     preferredStyle:UIAlertControllerStyleAlert];
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        UIAlertAction* yesButton = [UIAlertAction
                                                                                                                                    actionWithTitle:@"Troubleshooting"
                                                                                                                                    style:UIAlertActionStyleDefault
                                                                                                                                    handler:^(UIAlertAction * action) {
                                                                                                                                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://support.iamuse.com/portal/kb/iamuse-setup/troubleshooting/network-connection-issues"]];
                                                                                                                                        NSLog(@"troubleshooting");
                                                                                                                                        //Handle your yes please button action here
                                                                                                                                    }];
                                                                                                        
                                                                                                        UIAlertAction* noButton = [UIAlertAction
                                                                                                                                   actionWithTitle:@"Cancel"
                                                                                                                                   style:UIAlertActionStyleDefault
                                                                                                                                   handler:^(UIAlertAction * action) {
                                                                                                                                       //Handle no, thanks button
                                                                                                                                   }];
                                                                                                        
                                                                                                        [alert addAction:yesButton];
                                                                                                        [alert addAction:noButton];
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        UIWindow *keyWindow = [[UIApplication sharedApplication]keyWindow];
                                                                                                        UIViewController *mainController = [keyWindow rootViewController];
                                                                                                        [mainController presentViewController:alert animated:YES completion:nil];
                                                                                                    }];
        [requestOperation start];
    }
    else
    {
        UIViewController *visibleController = [self visibleViewController];
        dispatch_async(dispatch_get_main_queue(), ^{
       //     [visibleController.view makeToast:@"Touch Screen requires a network Camera Address in Settings."];
            
        });
        //        CTKioskShowAlert(@"Touch Screen requires a network Camera Address in "
        //                "Settings.");
    }
}


//- (void)showThanks
//{
//    /*
//     If we're a touch screen we need to pass this along to the camera device over the network.
//     */
//    if (deviceMode == CTKioskDeviceModeTouchScreen && networkCameraBaseURL)
//    {
//        NSString * action = @"gotoThankYou";
//        NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",
//                                            networkCameraBaseURL, action]];
//
//        //NSURLRequest * urlRequest = [NSURLRequest requestWithURL:url];
//        NSURLRequest * urlRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];
//
//        AFJSONRequestOperation * requestOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:urlRequest
//                                                                                                    success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
//                                                                                                        //   DDLogVerbose(@"Camera %@ response: %@", action, JSON);
//                                                                                                    }
//                                                                                                    failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
//                                                                                                        //   DDLogVerbose(@"Camera %@ error: %@", action, [error userInfo]);
//                                                                                                        //                                                                                                        NSString * message = [NSString stringWithFormat:@"There was a network issue connecting < %@ > \n Error Description: %@",request.URL, [error userInfo]];
//                                                                                                        [[[UIAlertView alloc] initWithTitle:@"Network Timeout" message:@"We were unable to connect to the other iAmuse device. Check your network settings and restart the application." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
//                                                                                                    }];
//        [requestOperation start];
//    }
//    else
//    {
//        UIViewController *visibleController = [self visibleViewController];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [visibleController.view makeToast:@"Touch Screen requires a network Camera Address in Settings."];
//
//        });
//        //        CTKioskShowAlert(@"Touch Screen requires a network Camera Address in "
//        //                         "Settings.");
//    }
//}









- (void)backToEventScene
{
    /*
     If we're a touch screen we need to pass this along to the camera device over the network.
     */
    if (deviceMode == CTKioskDeviceModeTouchScreen && networkCameraBaseURL)
    {
        
        
        
        
        NSString * action = @"backToEvent";
        NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",
                                            networkCameraBaseURL, action]];
        
        //NSURLRequest * urlRequest = [NSURLRequest requestWithURL:url];
        NSURLRequest * urlRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];
        
        AFJSONRequestOperation * requestOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:urlRequest
                                                                                                    success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                                                                        //   DDLogVerbose(@"Camera %@ response: %@", action, JSON);
                                                                                                    }
                                                                                                    failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                                                                        //   DDLogVerbose(@"Camera %@ error: %@", action, [error userInfo]);
//                                                                                                        NSString * message = [NSString stringWithFormat:@"There was a network issue connecting < %@ > \n Error Description: %@",request.URL, [error userInfo]];
//                                                                                                        [[[UIAlertView alloc] initWithTitle:@"Network Timeout" message:@"We were unable to connect to the other iAmuse device. Check your network settings and restart the application." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        UIAlertController * alert = [UIAlertController
                                                                                                                                     alertControllerWithTitle:@"Network Timeout"
                                                                                                                                     message:@"Unable to connect to other iAmuse device.Click Refresh in Settings on both devices or restart app, Check Troubleshooting for more info."
                                                                                                                                     preferredStyle:UIAlertControllerStyleAlert];
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        UIAlertAction* yesButton = [UIAlertAction
                                                                                                                                    actionWithTitle:@"Troubleshooting"
                                                                                                                                    style:UIAlertActionStyleDefault
                                                                                                                                    handler:^(UIAlertAction * action) {
                                                                                                                                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://support.iamuse.com/portal/kb/iamuse-setup/troubleshooting/network-connection-issues"]];
                                                                                                                                        NSLog(@"troubleshooting");
                                                                                                                                        //Handle your yes please button action here
                                                                                                                                    }];
                                                                                                        
                                                                                                        UIAlertAction* noButton = [UIAlertAction
                                                                                                                                   actionWithTitle:@"Cancel"
                                                                                                                                   style:UIAlertActionStyleDefault
                                                                                                                                   handler:^(UIAlertAction * action) {
                                                                                                                                       //Handle no, thanks button
                                                                                                                                   }];
                                                                                                        
                                                                                                        [alert addAction:yesButton];
                                                                                                        [alert addAction:noButton];
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        UIWindow *keyWindow = [[UIApplication sharedApplication]keyWindow];
                                                                                                        UIViewController *mainController = [keyWindow rootViewController];
//                                                                                                        [mainController presentViewController:alert animated:YES completion:nil];
                                                                                                    }];
        [requestOperation start];
    }
    else
    {
        UIViewController *visibleController = [self visibleViewController];
        dispatch_async(dispatch_get_main_queue(), ^{
            [visibleController.view makeToast:@"Touch Screen requires a network Camera Address in Settings."];
            
        });
//        CTKioskShowAlert(@"Touch Screen requires a network Camera Address in "
//                         "Settings.");
    }
}






-(void)subscriptionUpdate
{
    /*
     If we're a touch screen we need to pass this along to the camera device over the network.
     */
    if (deviceMode == CTKioskDeviceModeTouchScreen && networkCameraBaseURL)
    {
        
        
        
        
        NSString * action = @"subscriptionUpdate";
        NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",
                                            networkCameraBaseURL, action]];
        
        //NSURLRequest * urlRequest = [NSURLRequest requestWithURL:url];
        NSURLRequest * urlRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];
        
        AFJSONRequestOperation * requestOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:urlRequest
                                                                                                    success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                                                                        //   DDLogVerbose(@"Camera %@ response: %@", action, JSON);
                                                                                                    }
                                                                                                    failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        NSLog(@"error is %@",error.localizedDescription);
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        //   DDLogVerbose(@"Camera %@ error: %@", action, [error userInfo]);
                                                                                                        //                                                                                                        NSString * message = [NSString stringWithFormat:@"There was a network issue connecting < %@ > \n Error Description: %@",request.URL, [error userInfo]];
                                                                                                        //                                                                                                        [[[UIAlertView alloc] initWithTitle:@"Network Timeout" message:@"We were unable to connect to the other iAmuse device. Check your network settings and restart the application." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        UIAlertController * alert = [UIAlertController
                                                                                                                                     alertControllerWithTitle:@"Network Timeout"
                                                                                                                                     message:@"Unable to connect to other iAmuse device.Click Refresh in Settings on both devices or restart app, Check Troubleshooting for more info."
                                                                                                                                     preferredStyle:UIAlertControllerStyleAlert];
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        UIAlertAction* yesButton = [UIAlertAction
                                                                                                                                    actionWithTitle:@"Troubleshooting"
                                                                                                                                    style:UIAlertActionStyleDefault
                                                                                                                                    handler:^(UIAlertAction * action) {
                                                                                                                                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://support.iamuse.com/portal/kb/iamuse-setup/troubleshooting/network-connection-issues"]];
                                                                                                                                        NSLog(@"troubleshooting");
                                                                                                                                        //Handle your yes please button action here
                                                                                                                                    }];
                                                                                                        
                                                                                                        UIAlertAction* noButton = [UIAlertAction
                                                                                                                                   actionWithTitle:@"Cancel"
                                                                                                                                   style:UIAlertActionStyleDefault
                                                                                                                                   handler:^(UIAlertAction * action) {
                                                                                                                                       //Handle no, thanks button
                                                                                                                                   }];
                                                                                                        
                                                                                                        [alert addAction:yesButton];
                                                                                                        [alert addAction:noButton];
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        UIWindow *keyWindow = [[UIApplication sharedApplication]keyWindow];
                                                                                                        UIViewController *mainController = [keyWindow rootViewController];
                                                                                                        //                                                                                                        [mainController presentViewController:alert animated:YES completion:nil];
                                                                                                    }];
        [requestOperation start];
    }
    else
    {
        UIViewController *visibleController = [self visibleViewController];
        dispatch_async(dispatch_get_main_queue(), ^{
            [visibleController.view makeToast:@"Touch Screen requires a network Camera Address in Settings."];
            
        });
        //        CTKioskShowAlert(@"Touch Screen requires a network Camera Address in "
        //                         "Settings.");
    }
}








- (void)backToThankYou
{
    /*
     If we're a touch screen we need to pass this along to the camera device over the network.
     */
    if (deviceMode == CTKioskDeviceModeTouchScreen && networkCameraBaseURL)
    {
        
        
        
        
        NSString * action = @"backToEventa";
        NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",
                                            networkCameraBaseURL, action]];
        
        //NSURLRequest * urlRequest = [NSURLRequest requestWithURL:url];
        NSURLRequest * urlRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];
        
        AFJSONRequestOperation * requestOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:urlRequest
                                                                                                    success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                                                                        //   DDLogVerbose(@"Camera %@ response: %@", action, JSON);
                                                                                                    }
                                                                                                    failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                                                                        //   DDLogVerbose(@"Camera %@ error: %@", action, [error userInfo]);
                                                                                                        //                                                                                                        NSString * message = [NSString stringWithFormat:@"There was a network issue connecting < %@ > \n Error Description: %@",request.URL, [error userInfo]];
//                                                                                                        [[[UIAlertView alloc] initWithTitle:@"Network Timeout" message:@"We were unable to connect to the other iAmuse device. Check your network settings and restart the application." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                                                                                                        
                                                                                                        UIAlertController * alert = [UIAlertController
                                                                                                                                     alertControllerWithTitle:@"Network Timeout"
                                                                                                                                     message:@"Unable to connect to other iAmuse device.Click Refresh in Settings on both devices or restart app, Check Troubleshooting for more info."
                                                                                                                                     preferredStyle:UIAlertControllerStyleAlert];
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        UIAlertAction* yesButton = [UIAlertAction
                                                                                                                                    actionWithTitle:@"Troubleshooting"
                                                                                                                                    style:UIAlertActionStyleDefault
                                                                                                                                    handler:^(UIAlertAction * action) {
                                                                                                                     [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://support.iamuse.com/portal/kb/iamuse-setup/troubleshooting/network-connection-issues"]];
                                                                                                                                        NSLog(@"troubleshooting");
                                                                                                                                        //Handle your yes please button action here
                                                                                                                                    }];
                                                                                                        
                                                                                                        UIAlertAction* noButton = [UIAlertAction
                                                                                                                                   actionWithTitle:@"Cancel"
                                                                                                                                   style:UIAlertActionStyleDefault
                                                                                                                                   handler:^(UIAlertAction * action) {
                                                                                                                                       //Handle no, thanks button
                                                                                                                                   }];
                                                                                                        
                                                                                                        [alert addAction:yesButton];
                                                                                                        [alert addAction:noButton];
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        
                                                                                                        UIWindow *keyWindow = [[UIApplication sharedApplication]keyWindow];
                                                                                                        UIViewController *mainController = [keyWindow rootViewController];
                                                                                                        [mainController presentViewController:alert animated:YES completion:nil];
                                                                                                    }];
        [requestOperation start];
    }
    else
    {
        UIViewController *visibleController = [self visibleViewController];
        dispatch_async(dispatch_get_main_queue(), ^{
    //        [visibleController.view makeToast:@"Touch Screen requires a network Camera Address in Settings."];
            
        });
        //        CTKioskShowAlert(@"Touch Screen requires a network Camera Address in "
        //                         "Settings.");
    }
}







- (void)removeLookAtiPadScreen
{
    if (networkCameraBaseURL)
    {
        NSString * action = @"removelookatipad";
        NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",
                                           networkCameraBaseURL, action]];
        
        //NSURLRequest * urlRequest = [NSURLRequest requestWithURL:url];
        NSURLRequest * urlRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];

        AFJSONRequestOperation * requestOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:urlRequest
        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
      //  DDLogVerbose(@"Camera %@ response: %@", action, JSON);
        }
        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
      //  DDLogVerbose(@"Camera %@ error: %@", action, [error userInfo]);
       // NSString * message = [NSString stringWithFormat:@"There was a network issue connecting < %@ > \n Error Description: %@",request.URL, [error userInfo]];
//        [[[UIAlertView alloc] initWithTitle:@"HideLookAtiPad" message:@"There was a network issue" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            [[self visibleViewController].view makeToast:@"There was a network issue"];

        }];
        [requestOperation start];
    }
    else
    {
        UIViewController *visibleController = [self visibleViewController];
        dispatch_async(dispatch_get_main_queue(), ^{
            [visibleController.view makeToast:@"Touch Screen requires a network Camera Address in Settings."];
            
        });
//        CTKioskShowAlert(@"Touch Screen requires a network Camera Address in "
//                         "Settings.");
    }
}

- (void)newCameraRollPhoto:(NSNotification *)notification
{
    DDLogVerbose(@"%s", __FUNCTION__);
}

- (void)newDiskPhoto:(NSNotification *)notification
{
    /*
     There's a new photo file on the disk.  We need to store the CoreData
     entity for it.

     If we're a Camera then we also need to let the Touch Screen know there's
      a photo to download.

     If we're a Touch Screen and the photo session has an e-mail address
     we need to upload it to the cloud.
     */
    DDLogVerbose(@"%s", __FUNCTION__);

    NSString *fileName = notification.object;
    if (deviceMode == CTKioskDeviceModeCamera)
    {
        NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/photo/%@", networkTouchScreenBaseURL, fileName]];

        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        AFJSONRequestOperation *requestOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            DDLogVerbose(@"Network Camera Response: %@", JSON);
        }
        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
           DDLogVerbose(@"%@", [error userInfo]);
        }];
        [requestOperation start];
    }
    else
    {
        UIImage * newPhoto = [[UIImage alloc] initWithContentsOfFile:fileName];
        // Write to camera roll
        // TEMPORARY Custom feature request giving other print and
        // distribution options to the attendant.
        UIImageWriteToSavedPhotosAlbum(newPhoto, nil, nil, nil);
    }
}

- (void)checkPendingImageForUploading:(BOOL)isUploadPending
{
    AMStorageManager * store = [AMStorageManager sharedInstance];
    NSFetchRequest * coreDataRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription * entityDescription = [NSEntityDescription entityForName:@"Photo" inManagedObjectContext:store.currentMOC];
    [coreDataRequest setEntity:entityDescription];
    
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"failCount >= %@", [NSNumber numberWithInt:1]];
    [coreDataRequest setPredicate:predicate];
    NSError * error;
    NSArray * array = [store.currentMOC executeFetchRequest:coreDataRequest error:&error];
    self.photos = [[NSMutableArray alloc] init];
    for (Photo * photo in array)
    {
        if(photo.failCount > 0)
        {
            [self.photos addObject:photo];
        }
    }
    if([self.photos count] > 0)
    {
        if (isUploadPending) {
            [[[UIAlertView alloc] initWithTitle:@"" message:@"Images are pending to upload." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Upload", nil] show];
            return;
        }
        else
        {
            self.isUploadingPendingPhotos = YES;
            Photo * firstPhoto = [self.photos objectAtIndex:0];
            NSMutableArray * newPhotoArray = [[NSMutableArray alloc] init];
            for (Photo * photo in self.photos)
            {
                if ([photo.session isEqual:firstPhoto.session])
                {
                    [newPhotoArray addObject:photo];
                }
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:AMUpdatePendingImageCountNotification object:@"Pending"];
            [self sendPhotosToServer:newPhotoArray withPhotoSession:firstPhoto.session];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 101) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"OpenSettingSceneNotification" object:nil];
    }
    else
    {
        if (buttonIndex == 1) {
            self.isUploadingPendingPhotos = YES;
            Photo * firstPhoto = [self.photos objectAtIndex:0];
            NSMutableArray * newPhotoArray = [[NSMutableArray alloc] init];
            for (Photo * photo in self.photos)
            {
                if ([photo.session isEqual:firstPhoto.session])
                {
                    [newPhotoArray addObject:photo];
                }
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:AMUpdatePendingImageCountNotification object:@"Pending"];
            [self sendPhotosToServer:newPhotoArray withPhotoSession:firstPhoto.session];
        }
    }
}

- (void)newRemoteCameraPhoto:(NSNotification *)notification
{
    /*
    Touch Screen:
     If we're a touch screen this means we need to kick off a download from
     the camera of a new photo.  Track it in Core Data.
     */
    DDLogVerbose(@"%s", __FUNCTION__);
    if (deviceMode == CTKioskDeviceModeTouchScreen)
    {
        AMStorageManager * store = [AMStorageManager sharedInstance];
        NSString * targetFileName = [notification.object objectAtIndex:1];
        DDLogVerbose(@"Download %@ from camera.", targetFileName);

        NSURL * url = [NSURL URLWithString:[NSString
                stringWithFormat:@"%@/Photos/%@", networkCameraBaseURL,
                                 targetFileName]];

        NSString * targetFile = [[self photoStoreDirectory] stringByAppendingPathComponent:targetFileName];

        DDLogVerbose(@"Downloading %@ to %@", url, targetFile);

        __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
        request.downloadDestinationPath = targetFile;
        [request setCompletionBlock:^{
            // Use when fetching binary data
//            NSData *responseData = [request responseData];
            DDLogVerbose(@"New image saved to disk at %@", targetFile);

            // Create and store a Photo entity.
            Photo *photo = (Photo *)[NSEntityDescription
                    insertNewObjectForEntityForName:@"Photo"
                             inManagedObjectContext:store.currentMOC];

            [photo setCreatedOn:[NSDate date]];
            [photo setToKioskOn:[NSDate date]];
            [photo setPhotoUrl:targetFile];
            [photo setRenderVersion:AMPhotoCurrentRenderVersion];

            // Core Data relationships
            CTKiosk *kiosk = [CTKiosk sharedInstance];
            [kiosk.currentPhotoSession.entity addPhotosObject:photo];
            [photo setSession:kiosk.currentPhotoSession.entity];
            [photo setEventId:kiosk.currentPhotoSession.entity.layout.eventId];
            if (kiosk.currentPhotoSession.entity.layout.defaultId != nil || ![kiosk.currentPhotoSession.entity.layout.defaultId isKindOfClass:[NSNull class]])
            {
                [photo setDefaultId:kiosk.currentPhotoSession.entity.layout.defaultId];
            }

            [photo setLayoutId:kiosk.currentPhotoSession.entity.layout.order];
            // Then store.
            NSError *error = [store saveCoreData:photo];
            if (error) {
                DDLogVerbose(@"Error saving new photo entity: %@", [error localizedDescription]);
            }

            [[NSNotificationCenter defaultCenter]
                    postNotificationName:AMCameraNewDiskPhotoNotification
                                  object:targetFile];

        }];
        @weakify(request);
        [request setFailedBlock:^{
            @strongify(request);
            NSError *error = [request error];
            DDLogVerbose(@"Download error %@", error);
        }];
        [request startAsynchronous];

    }
}

- (void)notifyPrintKioskOfNewSelection
{
    if (networkPrintKioskBaseURL)
    {
        NSString * action = @"refresh";
        NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",
                                           networkPrintKioskBaseURL, action]];
        
        NSURLRequest * urlRequest = [NSURLRequest requestWithURL:url];
        AFJSONRequestOperation * requestOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:urlRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
             // DDLogVerbose(@"Camera %@ response: %@", action, JSON);
            }
            failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            // DDLogVerbose(@"Camera %@ error: %@", action, [error userInfo]);
            }];
        [requestOperation start];
    }
}


//-(void) choosePhotoLayout:(CTPhotoLayout *)photoLayout
//{
//    // Assumes a current session exists.
//    NSAssert(currentPhotoSession, @"Current Photo Session must exist.");
//
//    [currentPhotoSession choosePhotoLayout:photoLayout];
//
//    // TODO - tell the network CTCamera too.
//    DDLogInfo(@"Kiosk: New Photo Layout chosen.");
//
//    // The next likely step is to receive the results of the photo shoot and present them to the user.
//}

//- (NSString *)storePath {
//    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
//}

- (void)runTest:(NSNotification *)notification
{
    // Known photo session and photo data to load then upload.
    PhotoSession *photoSession = nil;
    NSString *photoSessionId = @"1373272383.342832";
    NSString *fileName = @"/Users/rolandhordos/Library/Application Support/iPhone Simulator/6.1/Applications/8B614E77-B25F-4796-B886-20696789CE82/Documents/Photos/photo-1373272481.263337.jpg";

    // Load the session.
    AMStorageManager *store = [AMStorageManager sharedInstance];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *sessionEntity = [NSEntityDescription
            entityForName:@"PhotoSession"
   inManagedObjectContext:store.currentMOC];
    [request setEntity:sessionEntity];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"photoSessionId == %@",
                                                              photoSessionId];
    [request setPredicate:predicate];
    NSError *error;
    NSArray *array = [store.currentMOC executeFetchRequest:request
                                                          error:&error];
    if ([array count] > 0) {
        photoSession = array[0];
    }

    [photoSession setEmail:@"rolandhordos@me.com"];
    [photoSession setChosenPhotoUrl:fileName];
    if (photoSession.email && photoSession.chosenPhotoUrl) {

        CTKiosk *kiosk = [CTKiosk sharedInstance];
        NSURL *url = [NSURL URLWithString:[NSString
                stringWithFormat:@"%@/kiosk/%@/photo",
                                 AMCloudServiceSecureBase,
                                 kiosk.entity.cloudKey]];

        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];

        // Upload a file on disk
        NSString *serverFileName = [fileName lastPathComponent];
        [request setFile:fileName withFileName:serverFileName
          andContentType:@"image/jpeg"
                  forKey:@"photo"];

        [request addPostValue:photoSession.photoSessionId
                       forKey:@"photoSessionId"];
        [request addPostValue:[photoSession.chosenPublic stringValue]
                       forKey:@"publicUseAck"];
        [request addPostValue:serverFileName
                       forKey:@"fileName"];
        [request addPostValue:AMPhotoCurrentRenderVersion
                       forKey:@"renderVersion"];
        [request addPostValue:photoSession.email
                       forKey:@"email"];
        [request addPostValue:photoSession.chosenPublic
                       forKey:@"share"];

        // Account for a slow and intermittent connection.
        [request setTimeOutSeconds:3600];   // take up to an hour
        [request setNumberOfTimesToRetryOnTimeout:3];
        @weakify(request);
        [request setCompletionBlock:^{
            @strongify(request);
            NSString *responseString = [request responseString];
            DDLogVerbose(@"Uploading photo response: %@", responseString);
        }];
        [request setFailedBlock:^{
            @strongify(request);
            NSError *error = [request error];
            DDLogVerbose(@"Eror uploading photo %@", error);
        }];
        [request startAsynchronous];
    }
}

- (void)selectPhoto:(Photo *)photo
{
    AMStorageManager * store = [AMStorageManager sharedInstance];

    // If the photo session has an email address, we upload the image to
    // the cloud and let it do the emailing.
    PhotoSession * photoSession = currentPhotoSession.entity;

    // TODO - remove this legacy pre-multi-select relationship
    [photoSession setChosenPhotoUrl:photo.photoUrl];
    
    NSError * saveError = nil;
    if ([store.currentMOC save:&saveError])
    {
        DDLogVerbose(@"New Photo entity stored.");
    }
    else
    {
        DDLogVerbose(@"Error saving new photo entity: %@",[saveError localizedDescription]);
    }

    // Add it to the  multi-select list.
    if ([store addMediaSelection:photoSession forPhoto:photo])
    {
        // Notify the Print Kiosk if we have one.
        [self notifyPrintKioskOfNewSelection];
    }
}

- (void)saveSelectedPhotos:(NSMutableArray *)photos
{
    AMStorageManager * store = [AMStorageManager sharedInstance];
    
    // If the photo session has an email address, we upload the image to
    // the cloud and let it do the emailing.
    PhotoSession * photoSession = currentPhotoSession.entity;
    
    // TODO - remove this legacy pre-multi-select relationship
    NSString * finalUrl;
    switch ([photos count])
    {
        case 1:
        {
            Photo * photo = [photos objectAtIndex:0];
            finalUrl = photo.photoUrl;
        }
            break;
        case 2:
        {
            Photo * photoFirst = [photos objectAtIndex:0];
            NSString * firstUrl = photoFirst.photoUrl;
            Photo * photoSecond = [photos objectAtIndex:1];
            NSString * secondUrl = photoSecond.photoUrl;
            
            finalUrl = [firstUrl stringByAppendingString:[NSString stringWithFormat:@"##%@",secondUrl]];
        }
            break;
        case 3:
        {
            Photo * photoFirst = [photos objectAtIndex:0];
            NSString * firstUrl = photoFirst.photoUrl;
            Photo * photoSecond = [photos objectAtIndex:1];
            NSString * secondUrl = photoSecond.photoUrl;
            Photo * photoThird = [photos objectAtIndex:2];
            NSString * thirdUrl = photoThird.photoUrl;

            finalUrl = [firstUrl stringByAppendingString:[NSString stringWithFormat:@"##%@##%@",secondUrl, thirdUrl]];
        }
            break;
        default:
            break;
    }
    [photoSession setChosenPhotoUrl:finalUrl];

    NSError * saveError = nil;
    if ([store.currentMOC save:&saveError])
    {
        DDLogVerbose(@"New Photo entity stored.");
    }
    else
    {
        DDLogVerbose(@"Error saving new photo entity: %@",[saveError localizedDescription]);
    }
}

- (void)selectedPhotoFromReviewPicture:(Photo *)selectedPhoto
{
    AMStorageManager * store = [AMStorageManager sharedInstance];
    PhotoSession * photoSession = currentPhotoSession.entity;

    // Add it to the  multi-select list.
    if ([store addMediaSelection:photoSession forPhoto:selectedPhoto])
    {
        // Notify the Print Kiosk if we have one.
        [self notifyPrintKioskOfNewSelection];
    }
}

- (void)setEmailAddress:(NSString *)emailAddress
{
    PhotoSession * photoSession = currentPhotoSession.entity;
    [photoSession setEmail:emailAddress];

    NSError * saveError = nil;
    AMStorageManager * store = [AMStorageManager sharedInstance];
    if ([store.currentMOC save:&saveError])
    {
        DDLogVerbose(@"New Photo entity stored.");
    }
    else
    {
        DDLogVerbose(@"Error saving new photo entity: %@",
                [saveError localizedDescription]);
    }
}

- (void)setName:(NSString *)name
{
    PhotoSession * photoSession = currentPhotoSession.entity;
    [photoSession setName:name];
    
    NSError * saveError = nil;
    AMStorageManager * store = [AMStorageManager sharedInstance];
    if ([store.currentMOC save:&saveError])
    {
        DDLogVerbose(@"New Photo entity stored.");
    }
    else
    {
        DDLogVerbose(@"Error saving new photo entity: %@",
                     [saveError localizedDescription]);
    }
}

- (void)setNumber:(NSString *)number
{
    PhotoSession * photoSession = currentPhotoSession.entity;
    [photoSession setNumber:number];
    
    NSError * saveError = nil;
    AMStorageManager * store = [AMStorageManager sharedInstance];
    if ([store.currentMOC save:&saveError])
    {
        DDLogVerbose(@"New Photo entity stored.");
    }
    else
    {
        DDLogVerbose(@"Error saving new photo entity: %@",
                     [saveError localizedDescription]);
    }
}

- (void)sharePhotoPubliclyOfAge:(BOOL)okayToShare
{
    // If the photo session has an email address, we upload the image to
    // the cloud and let it do the emailing.
    PhotoSession *photoSession = currentPhotoSession.entity;

    [photoSession setChosenPublic:[NSNumber numberWithBool:okayToShare]];
    [photoSession setChosenPublicAgeAck:[NSNumber numberWithBool:okayToShare]];

    NSError *saveError = nil;
    AMStorageManager *store = [AMStorageManager sharedInstance];
    if ([store.currentMOC save:&saveError]) {
        DDLogVerbose(@"New Photo entity stored.");
    } else {
        DDLogVerbose(@"Error saving new photo entity: %@",
                [saveError localizedDescription]);
    }
}

- (void)chooseNewsletter:(BOOL)value {
    
    // If the photo session has an email address, we upload the image to
    // the cloud and let it do the emailing.
    PhotoSession *photoSession = currentPhotoSession.entity;
    
    [photoSession setChosenNewsletter:[NSNumber numberWithBool:value]];
    
    NSError *saveError = nil;
    AMStorageManager *store = [AMStorageManager sharedInstance];
    if ([store.currentMOC save:&saveError]) {
        DDLogVerbose(@"New Photo entity stored.");
    } else {
        DDLogVerbose(@"Error saving new photo entity: %@",
              [saveError localizedDescription]);
    }
}


- (void)emailPhoto {

    /*
    // If the photo session has an email address, we upload the image to
    // the cloud and let it do the emailing.
    PhotoSession *photoSession = currentPhotoSession.entity;
    NSString *absoluteFileName = photoSession.chosenPhotoUrl;
    if (photoSession.email && photoSession.chosenPhotoUrl) {

        // We also need the Photo entity
        Photo *photo = nil;
        AMStorageManager *store = [AMStorageManager sharedInstance];
        NSFetchRequest *coreDataRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Photo"
                                                             inManagedObjectContext:store.currentMOC];
        [coreDataRequest setEntity:entityDescription];

        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"session == %@ AND photoUrl == %@", photoSession, absoluteFileName];
//            NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[]]
        [coreDataRequest setPredicate:predicate];
        NSError *error;
        NSArray *array = [store.currentMOC executeFetchRequest:coreDataRequest error:&error];
        if ([array count] > 0) {
            photo = array[0];
        } else {
            DDLogVerbose(@"Missing photo entity, aborting.");
            return;
        }

        // Upload the chosen photo to the cloud.
        
        NSURL *url = [NSURL URLWithString:[NSString
                stringWithFormat:@"%@/kiosk/%@/photo",
                                 AMCloudServiceSecureBase,
                                 self.entity.cloudKey]];
        
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
        
        NSString *serverFileName = [absoluteFileName lastPathComponent];
        DDLogVerbose(@"Uploading %@ to Cloud ..", serverFileName);
        
        [request setFile:absoluteFileName withFileName:serverFileName
          andContentType:@"image/jpeg"
                  forKey:@"photo"];
     
        [request addPostValue:photoSession.photoSessionId
                       forKey:@"photoSessionId"];
        [request addPostValue:[photoSession.chosenPublic stringValue]
                       forKey:@"publicUseAck"];
        [request addPostValue:[photoSession.chosenNewsletter stringValue]
                       forKey:@"newsletterOptIn"];
        [request addPostValue:serverFileName
                       forKey:@"fileName"];
        [request addPostValue:AMPhotoCurrentRenderVersion
                       forKey:@"renderVersion"];
        [request addPostValue:photoSession.email
                       forKey:@"email"];
        [request addPostValue:photoSession.chosenPublic
                       forKey:@"share"];
        @weakify(request);
        [request setCompletionBlock:^{
            @strongify(request);
            NSString *responseString = [request responseString];
            DDLogVerbose(@"Upload response is %@", responseString);

            // Result is a successful upload.  Mark this in the photo entity.
            NSDate *date = [NSDate date];
            [photo setToCloudOn:date];
            [photoSession setToCloudOn:date];

            // Then store.
            NSError *saveError = nil;
            if ([store.currentMOC save:&saveError]) {
                DDLogVerbose(@"New Photo entity stored.");
            } else {
                DDLogVerbose(@"Error saving new photo entity: %@",
                        [saveError localizedDescription]);
            }
        }];
        [request setFailedBlock:^{
            @strongify(request);
            NSError *uploadError = [request error];
            DDLogVerbose(@"Eror uploading photo %@", uploadError);

            // Mark the failure count in the photo session and save.
            NSNumber *newFailCount = [NSNumber numberWithInt:[photoSession.failCount intValue] + 1];
            [photoSession setFailCount:newFailCount];

            NSNumber *photoFailCount = [NSNumber numberWithInt:[photo.failCount intValue] + 1];
            [photo setFailCount:photoFailCount];

            NSError *saveError = nil;
            if ([store.currentMOC save:&saveError]) {
                DDLogVerbose(@"New Photo entity stored.");
            } else {
                DDLogVerbose(@"Error saving new photo entity: %@", [saveError localizedDescription]);
            }
        }];
        [request startAsynchronous];
    }
     */
    
    [self sendImageWithEmail];
}

- (void)sendImageWithEmail
{
    PhotoSession * photoSession = currentPhotoSession.entity;
    
//    NSString * absoluteFileName = photoSession.chosenPhotoUrl;
    if (photoSession.email && photoSession.chosenPhotoUrl)
    {
//        // We also need the Photo entity
//        Photo * photo = nil;
//        AMStorageManager * store = [AMStorageManager sharedInstance];
//        NSFetchRequest * coreDataRequest = [[NSFetchRequest alloc] init];
//        NSEntityDescription * entityDescription = [NSEntityDescription entityForName:@"Photo" inManagedObjectContext:store.currentMOC];
//        [coreDataRequest setEntity:entityDescription];
//        
//        NSPredicate * predicate = [NSPredicate predicateWithFormat:@"session == %@ AND photoUrl == %@", photoSession, absoluteFileName];
//        //            NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[]]
//        [coreDataRequest setPredicate:predicate];
//        NSError * error;
//        NSArray * array = [store.currentMOC executeFetchRequest:coreDataRequest error:&error];
//        if ([array count] > 0)
//        {
//            photo = array[0];
//        }
//        else
//        {
//            DDLogVerbose(@"Missing photo entity, aborting.");
//            return;
//        }
//        [self sendToServer:photo withPhotoSession:photoSession];
        
        
        
        // We also need the Photo entity
        NSMutableArray * photos = [[NSMutableArray alloc] init];
        AMStorageManager * store = [AMStorageManager sharedInstance];
        NSFetchRequest * coreDataRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription * entityDescription = [NSEntityDescription entityForName:@"Photo" inManagedObjectContext:store.currentMOC];
        [coreDataRequest setEntity:entityDescription];

        NSArray * subStrings = [photoSession.chosenPhotoUrl componentsSeparatedByString:@"##"];
        
        for (NSString * imageUrl in subStrings)
        {
            NSError * error;
            NSPredicate * predicate = [NSPredicate predicateWithFormat:@"session == %@ AND photoUrl == %@", photoSession, imageUrl];
            [coreDataRequest setPredicate:predicate];
            
            NSArray * array = [store.currentMOC executeFetchRequest:coreDataRequest error:&error];
            if ([array count] > 0)
            {
                [photos addObject:array[0]];
                
            }
//            else
//            {
//                DDLogVerbose(@"Missing photo entity, aborting.");
//                return;
//            }
        }
        for (Photo * photo in photos)
        {
            photo.failCount = [NSNumber numberWithInt:1];
        }
        NSError * error = [store saveCoreData:nil];
        if (error)
        {
            DDLogVerbose(@"Error saving new photo session: %@", [error localizedDescription]);
        }
        
        
//        [self sendPhotosToServer:photos withPhotoSession:photoSession];
    }
}

- (void)sendPhotosToServer:(NSMutableArray *)photos withPhotoSession:(PhotoSession *)photoSession
{
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",
                                        kAMBaseURL, kAMImageWithEmailUploadURL]];
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
    AMStorageManager * store = [AMStorageManager sharedInstance];
    
    NSMutableArray * images = [[NSMutableArray alloc] init];
    for (Photo * photo in photos)
    {
        NSString * absoluteFileName = photo.photoUrl;
        NSString * serverFileName = [absoluteFileName lastPathComponent];
        NSString * targetFile = [[self photoStoreDirectory] stringByAppendingPathComponent:serverFileName];
        
        UIImage * image = [UIImage imageWithContentsOfFile:targetFile];
        NSData * imgdata =  UIImageJPEGRepresentation(image,0.83);
        NSString * base64string = [imgdata base64EncodedString];

        NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
        [dic setObject:base64string forKey:@"image"];
        [dic setObject:photo.eventId forKey:@"eventId"];
        [dic setObject:photo.layoutId forKey:@"picId"];
        if (photo.defaultId) {
            [dic setObject:photo.defaultId forKey:@"defaultId"];
        }
        [images addObject:dic];
    }
    if(images)
    {
        [dict setObject:images forKey:@"images"];
        [dict setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"userId"] forKey:kUserId];
        [dict setObject:photoSession.email forKey:@"emailId"];
        if (photoSession.name) {
            [dict setObject:photoSession.name forKey:@"guestName"];
        }
        if (photoSession.number) {
            [dict setObject:photoSession.number forKey:@"guestMobileNumber"];

        }
        NSDate *date2 = [NSDate date];
        NSTimeInterval secondsBetween = [date2 timeIntervalSinceDate:self.startingTimeStamp];
        
        [dict setObject:[NSString stringWithFormat:@"%f",(secondsBetween/60.0)] forKey:@"sessionTime"];
        [dict setObject:photoSession.photoSessionId forKey:@"photoSessionId"];
        [dict setObject:[photoSession.chosenPublic stringValue] forKey:@"publicUseAck"];
        [dict setObject:[photoSession.chosenNewsletter stringValue] forKey:@"newsletterOptIn"];
  //       [dict setObject:[NSNumber numberWithInt:1] forKey:@"newsletterOptIn"];
//        [dict setObject:serverFileName forKey:@"fileName"];
        [dict setObject:AMPhotoCurrentRenderVersion forKey:@"renderVersion"];
        [dict setObject:photoSession.chosenPublic forKey:@"share"];
       // NSString * timestamp = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970] * 1000];

        NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeZone:timeZone];
        [dateFormatter setDateFormat:@"E, MMM d yyyy HH:mm:ss ZZZZZ"];
        NSString *localDateString = [dateFormatter stringFromDate:[NSDate date]];
        [dict setObject:localDateString forKey:@"imageTimestamp"];
        [timer invalidate];
        timer = nil;
        WebCommunication * webComm = [WebCommunication new];
        [webComm callToServerRequestDictionary:dict onURL:url WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm)
         {

             if (self.photos.count > 0) {
                 [[NSNotificationCenter defaultCenter] postNotificationName:AMUpdatePendingImageCountNotification object:@"Uploaded"];
                 self.photos = [[NSMutableArray alloc] init];
             }
             NSLog(@"response : %@",response);
             if([[response objectForKey:@"responseDescription"] isEqualToString:@"Success"])
             {
                 [[self visibleViewController].view makeToast:@"Successfully sent Email!"];

                 DDLogVerbose(@"Upload response is %@", response);
                 // Result is a successful upload.  Mark this in the photo entity.
                 if (self.delegate)
                 {
                     [self.delegate imagesSendingSuccessfull];
                 }
                 
                 NSDate * date = [NSDate date];
                 for (Photo * photo in photos)
                 {
                     [photo setToCloudOn:date];
                 }
                 [photoSession setToCloudOn:date];
                 
                 // Mark the failure count in the photo session and save.
                 NSNumber * newFailCount = [NSNumber numberWithInt:0];
                 for (Photo * photo in photos)
                 {
                     [photo setFailCount:newFailCount];
                 }
                 [photoSession setFailCount:newFailCount];
                 
                 
                 // Then store.
                 NSError * saveError = nil;
                 if ([store.currentMOC save:&saveError])
                 {
                     DDLogVerbose(@"New Photo entity stored.");
                 }
                 else
                 {
                     DDLogVerbose(@"Error saving new photo entity: %@",
                                  [saveError localizedDescription]);
                 }

                 //as the action of upload is complete even with failure,
                 //uplpading process has finished, reset status
                 self.isUploadingPendingPhotos = NO;

                 if (!self.isUploadingPendingPhotos) {
                     [self handlePendingImageUploadingRequest];
                 }
//                 if (!self.isUploadingPendingPhotos) {
//                     [self checkPendingImageForUploading:NO];
//                 }
             }
             else
             {
                 NSError * uploadError = error;
                 DDLogVerbose(@"Eror uploading photo %@", uploadError);
                 
                 if (self.delegate)
                 {
                     [self.delegate imagesSendingNotSucessfull];
                 }
                 // Mark the failure count in the photo session and save.
//                 [[self visibleViewController].view makeToast:@"Unable to upload photos."];

                // CTKioskShowAlert(@"Unable to upload photos.");
     
                 //No need to increase the fail count if uploading fails.
                 
                 NSNumber * newFailCount = [NSNumber numberWithInt:[photoSession.failCount intValue] + 1];
                 [photoSession setFailCount:newFailCount];
                 
                 for (Photo * photo in photos)
                 {
                     NSNumber * photoFailCount = [NSNumber numberWithInt:[photo.failCount intValue] + 1];
                     [photo setFailCount:photoFailCount];
                 }
                 
                 NSError * saveError = nil;
                 if ([store.currentMOC save:&saveError])
                 {
                     DDLogVerbose(@"New Photo entity stored.");
                 }
                 else
                 {
                     DDLogVerbose(@"Error saving new photo entity: %@", [saveError localizedDescription]);
                 }
                 //as the action of upload is complete even with failure,
                 //uplpading process has finished, reset status
                 self.isUploadingPendingPhotos = NO;
                 
                 if (!self.isUploadingPendingPhotos) {
                     
//                     [self performSelector:@selector(handlePendingImageUploadingRequest) withObject:nil];
//                     [self performSelectorInBackground:@selector(handlePendingImageUploadingRequest) withObject:nil];
                 }

             }
         }];
    }
}

- (void)sendToServer:(Photo *)photo withPhotoSession:(PhotoSession *)photoSession
{
    AMStorageManager * store = [AMStorageManager sharedInstance];
    NSString * absoluteFileName = photoSession.chosenPhotoUrl;
    NSString * serverFileName = [absoluteFileName lastPathComponent];
    NSString * targetFile = [[self photoStoreDirectory] stringByAppendingPathComponent:serverFileName];

    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",
                                       kAMBaseURL, kAMImageWithEmailUploadURL]];
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
    UIImage * image = [UIImage imageWithContentsOfFile:targetFile];
    if(image)
    {
        NSData * imgdata =  UIImageJPEGRepresentation(image,0.83);
        NSString * base64string = [imgdata base64EncodedString];
        [dict setObject:base64string forKey:kImage];
        [dict setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"userId"] forKey:kUserId];
        [dict setObject:photoSession.email forKey:@"emailId"];
        [dict setObject:photoSession.photoSessionId forKey:@"photoSessionId"];
        [dict setObject:[photoSession.chosenPublic stringValue] forKey:@"publicUseAck"];
        [dict setObject:[photoSession.chosenNewsletter stringValue] forKey:@"newsletterOptIn"];
        [dict setObject:serverFileName forKey:@"fileName"];
        [dict setObject:AMPhotoCurrentRenderVersion forKey:@"renderVersion"];
        [dict setObject:photoSession.chosenPublic forKey:@"share"];
        
        WebCommunication * webComm = [WebCommunication new];
        [webComm callToServerRequestDictionary:dict onURL:url WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm)
         {
             NSLog(@"response : %@",response);
             if([[response objectForKey:@"responseDescription"] isEqualToString:@"Success"])
             {
                 DDLogVerbose(@"Upload response is %@", response);
                 // Result is a successful upload.  Mark this in the photo entity.
                 NSDate * date = [NSDate date];
                 [photo setToCloudOn:date];
                 [photoSession setToCloudOn:date];
                 
                 // Mark the failure count in the photo session and save.
                 NSNumber *newFailCount = [NSNumber numberWithInt:0];
                 [photoSession setFailCount:newFailCount];
                 NSNumber *photoFailCount = [NSNumber numberWithInt:0];
                 [photo setFailCount:photoFailCount];

                 
                 // Then store.
                 NSError *saveError = nil;
                 if ([store.currentMOC save:&saveError])
                 {
                     DDLogVerbose(@"New Photo entity stored.");
                 }
                 else
                 {
                     DDLogVerbose(@"Error saving new photo entity: %@",
                                  [saveError localizedDescription]);
                 }
                 [self handlePendingImageUploadingRequest];
             }
             else
             {
                 NSError * uploadError = error;
                 DDLogVerbose(@"Eror uploading photo %@", uploadError);
                 
                 
                 // Mark the failure count in the photo session and save.
                 NSNumber *newFailCount = [NSNumber numberWithInt:[photoSession.failCount intValue] + 1];
                 [photoSession setFailCount:newFailCount];
                 
                 NSNumber *photoFailCount = [NSNumber numberWithInt:[photo.failCount intValue] + 1];
                 [photo setFailCount:photoFailCount];
                 
                 NSError * saveError = nil;
                 if ([store.currentMOC save:&saveError])
                 {
                     DDLogVerbose(@"New Photo entity stored.");
                 }
                 else
                 {
                     DDLogVerbose(@"Error saving new photo entity: %@", [saveError localizedDescription]);
                 }
             }
         }];
    }
}

- (void)handlePendingImageUploadingRequest
{
    // commented by rupesh for multi-image selection
    
//    Photo * photo = nil;
//    AMStorageManager * store = [AMStorageManager sharedInstance];
//    NSFetchRequest * coreDataRequest = [[NSFetchRequest alloc] init];
//    NSEntityDescription * entityDescription = [NSEntityDescription entityForName:@"Photo" inManagedObjectContext:store.currentMOC];
//    [coreDataRequest setEntity:entityDescription];
//    
//    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"failCount >= %@", [NSNumber numberWithInt:1]];
//    [coreDataRequest setPredicate:predicate];
//    NSError * error;
//    NSArray * array = [store.currentMOC executeFetchRequest:coreDataRequest error:&error];
//    if ([array count] > 0)
//    {
//        photo = array[0];
//    }
//    else
//    {
//        DDLogVerbose(@"Missing photo entity, aborting.");
//        return;
//    }
//    if(photo.failCount > 0)
//    {
//        PhotoSession * photoSession  = photo.session;
//        [self sendToServer:photo withPhotoSession:photoSession];
//    }
    
    AMStorageManager * store = [AMStorageManager sharedInstance];
    NSFetchRequest * coreDataRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription * entityDescription = [NSEntityDescription entityForName:@"Photo" inManagedObjectContext:store.currentMOC];
    [coreDataRequest setEntity:entityDescription];
    
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"failCount >= %@", [NSNumber numberWithInt:1]];
    [coreDataRequest setPredicate:predicate];
    NSError * error;
    NSArray * array = [store.currentMOC executeFetchRequest:coreDataRequest error:&error];
    NSMutableArray * photoArray = [[NSMutableArray alloc] init];
    for (Photo * photo in array)
    {
        if(photo.failCount > 0)
        {
            [photoArray addObject:photo];
        }
    }
    if([photoArray count] > 0)
    {
        Photo * firstPhoto = [photoArray objectAtIndex:0];
        NSMutableArray * newPhotoArray = [[NSMutableArray alloc] init];
        for (Photo * photo in photoArray)
        {
            if ([photo.session isEqual:firstPhoto.session])
            {
                [newPhotoArray addObject:photo];
            }
        }
        self.isUploadingPendingPhotos = YES;
        [self sendPhotosToServer:newPhotoArray withPhotoSession:firstPhoto.session];
    }
    else
    {
        self.isUploadingPendingPhotos = NO;
        NSLog(@"All photos uploaded");
    }
}

- (void)print:(UIViewController *)viewController dialogFocus:(UIButton *)dialogFocus
{
    DDLogVerbose(@"%s", __FUNCTION__);

    PhotoSession *photoSession = currentPhotoSession.entity;
    NSString *absoluteFileName = photoSession.chosenPhotoUrl;
    if (photoSession.chosenPhotoUrl)
    {
        // Scale the photo to 1.4wx1.0h (i.e. 4x6, 5x7).
        UIImage *photoToPrint = nil;
        UIImage *rawPhoto = [UIImage imageWithContentsOfFile:absoluteFileName];
        if (rawPhoto)
        {
            // Make a size that will include a header and footer.
            CGFloat heightFix = (CGFloat)(rawPhoto.size.width / 1.4);
            CGSize printSize = CGSizeMake(rawPhoto.size.width, heightFix);
            NSString *ratioModePref = [[NSUserDefaults standardUserDefaults] stringForKey:AMRatioModeSettingsKey];

            if (([ratioModePref isEqualToString:@"Aspect Fit"])||([ratioModePref length] == 0))
            {
                photoToPrint = [rawPhoto imageByAspectFit:printSize];
            }
            else if([ratioModePref isEqualToString:@"Aspect Fill"])
            {
                photoToPrint = [rawPhoto imageByAspectFill:printSize];
            }
            else
            {
                photoToPrint = [rawPhoto imageByScalingAndCroppingForSize:printSize];
            }
        }

        UIPrintInteractionController *printController = [UIPrintInteractionController sharedPrintController];
//        if  (printController && [UIPrintInteractionController canPrintURL:self.myPDFData] ) {
        if  (printController && photoToPrint && UIPrintInteractionController.isPrintingAvailable)
        {
            printController.delegate = self;

            // Do we have a default printer?  This will be the last one that was
            // successfully used.
            NSString *defaultPrinterId = [[NSUserDefaults standardUserDefaults] objectForKey:kAMDefaultPrinterId];

            // Setup print info to answer as many questions as possible.
            UIPrintInfo *printInfo = [UIPrintInfo printInfo];
            if (defaultPrinterId) {
                printInfo.printerID = defaultPrinterId;
            }
            printInfo.outputType = UIPrintInfoOutputPhoto;
            printInfo.jobName = photoSession.email ? photoSession.email : @"Anonymous";
            printInfo.duplex = UIPrintInfoDuplexNone;

            printController.printInfo = printInfo;
            printController.showsPageRange = NO;

            printController.printingItem = photoToPrint;

            void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) = ^(UIPrintInteractionController *pic, BOOL completed, NSError *error) {
//                self.content = nil;
                if (!completed && error)
                {
                    DDLogVerbose(@"FAILED! due to error in domain %@ with error code %ld",
                            error.domain, (long)error.code);

                    [TSMessage showNotificationInViewController:viewController
                                                          title:@"Print Error"
                            subtitle:[NSString stringWithFormat:@"There was a %@ error while printing for %@", [error localizedDescription], printInfo.jobName] image:nil
                                                           type:TSMessageNotificationTypeError
                                                       duration:60 callback:nil buttonTitle:nil buttonCallback:nil
                                                     atPosition:TSMessageNotificationPositionBottom canBeDismissedByUser:YES];
                }
                else
                {
                    if (completed)
                    {
                        [TSMessage showNotificationInViewController:viewController
                                                            title:@"Print Complete"
                                                           subtitle:[NSString stringWithFormat:@"Successful Print for %@", printInfo.jobName] image:nil
                                                               type:TSMessageNotificationTypeSuccess
                                                           duration:5 callback:nil buttonTitle:nil buttonCallback:nil
                                                         atPosition:TSMessageNotificationPositionBottom canBeDismissedByUser:YES];

                        // Remember the successful printer
                        [[NSUserDefaults standardUserDefaults] setObject:printController.printInfo.printerID
                                                                  forKey:kAMDefaultPrinterId];
                    }
                    // else // this may have been cancelled

                    DDLogVerbose(@"Selected Printer ID: %@", printController.printInfo.printerID);
                }
            };
//            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
//                [printController presentFromBarButtonItem:self.printButton animated:YES
//                                        completionHandler:completionHandler];
//            } else {
            [printController presentFromRect:dialogFocus.frame inView:viewController.view animated:YES completionHandler:completionHandler];
//            [printController presentAnimated:YES completionHandler:completionHandler];
//            }
        
        }
    }
}

- (NSArray *)getPrintablePhotosMetaData
{
    AMStorageManager * store = [AMStorageManager sharedInstance];
    return [store fetchPrintablePhotos];
}

- (UIImage *)printPreview:(UIViewController *)viewController dialogFocus:(UIButton *)dialogFocus
{
    DDLogVerbose(@"%s", __FUNCTION__);
    UIImage *photoToPrint = nil;

    PhotoSession *photoSession = currentPhotoSession.entity;
    NSString *absoluteFileName = photoSession.chosenPhotoUrl;
    if (photoSession.chosenPhotoUrl)
    {
        // Scale the photo to 1.4wx1.0h (i.e. 4x6, 5x7).
        UIImage *rawPhoto = [UIImage imageWithContentsOfFile:absoluteFileName];
        if (rawPhoto)
        {
            // Make a size that will include a header and footer.
            CGFloat heightFix = (CGFloat)(rawPhoto.size.width / 1.4);
            CGSize printSize = CGSizeMake(rawPhoto.size.width, heightFix);
            NSString *ratioModePref = [[NSUserDefaults standardUserDefaults] stringForKey:AMRatioModeSettingsKey];
            
            if (([ratioModePref isEqualToString:@"Aspect Fit"])||([ratioModePref length] == 0))
            {
                photoToPrint = [rawPhoto imageByAspectFit:printSize];
            }
            else if([ratioModePref isEqualToString:@"Aspect Fill"])
            {
                photoToPrint = [rawPhoto imageByAspectFill:printSize];
            }
            else
            {
                photoToPrint = [rawPhoto imageByScalingAndCroppingForSize:printSize];
            }
        }
    }
    return photoToPrint;
}

- (void)registerDeviceOnServer
{
    WebCommunication *webComm = [[WebCommunication alloc] initWithServiceType:1];
//    {
//        deviceName = "Demo\U2019s iPad OS";
//        operationgSystemVersion = "9.3.5";
//    }
    NSMutableDictionary *currentDeviceInformation = [[NSMutableDictionary alloc] init];
    [currentDeviceInformation setObject:[UIDevice currentDevice].name forKey:@"deviceName"] ;
    [currentDeviceInformation setObject:[UIDevice currentDevice].systemVersion forKey:@"operationgSystemVersion"];
    NSUserDefaults * userdefault = [NSUserDefaults standardUserDefaults];
    NSString * deviceModePref = [userdefault stringForKey:AMDeviceModeSettingsKey];
    if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
    {    
        [currentDeviceInformation setObject:@"Camera device" forKey:@"deviceType"];
        
        [userdefault setObject:@"register" forKey:@"registerCamera"];
    }
    else
    {
        [currentDeviceInformation setObject:@"Guest Touchscreen" forKey:@"deviceType"];
        [userdefault setObject:@"register" forKey:@"registerTouch"];
    }
    BOOL isGuidedAccess = UIAccessibilityIsGuidedAccessEnabled();
    [currentDeviceInformation setObject:[NSString stringWithFormat:@"%i", isGuidedAccess] forKey:@"guidedAccessEnabled"];
    if ([self GetCurrentWifiHotSpotName] != nil) {
        [currentDeviceInformation setObject:[self GetCurrentWifiHotSpotName] forKey:@"wirelessNetwork"];
        [currentDeviceInformation setObject:[self getIPAddressofDevice] forKey:@"ipAddress"];
        [currentDeviceInformation setObject:[self getSubnetMaskofDevice] forKey:@"subNetMask"];
    }
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    CGSize screenSize = CGSizeMake(screenBounds.size.width * screenScale, screenBounds.size.height * screenScale);
    [currentDeviceInformation setObject:[NSString stringWithFormat:@"%.0fpx*%.0fpx",screenSize.width,screenSize.height] forKey:@"deteactedResolution"];
    NSDictionary *memory = [self getFreeDiskspace];
    NSNumber *fileSystemSizeInBytes = [memory objectForKey: NSFileSystemSize];
    NSNumber *freeFileSystemSizeInBytes = [memory objectForKey:NSFileSystemFreeSize];
    uint64_t totalSpace = 0;
    uint64_t totalFreeSpace = 0;
    totalSpace = [fileSystemSizeInBytes unsignedLongLongValue];
    totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
    totalSpace = ((totalSpace/1024ll)/1024ll);
    totalFreeSpace = ((totalFreeSpace/1024ll)/1024ll);
    
    [currentDeviceInformation setObject:[NSString stringWithFormat:@"%.2fGB used %.2fGB available",(totalSpace-totalFreeSpace)/1024.0,totalFreeSpace/1024.0] forKey:@"deviceStorage"];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"userId"])
    {
        [currentDeviceInformation setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"userId"] forKey:@"userId"];
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kAMDeviceToken]) {
        [currentDeviceInformation setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kAMDeviceToken] forKey:@"deviceToken"];
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kAMOldDeviceToken] != nil) {
            [currentDeviceInformation setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kAMOldDeviceToken] forKey:@"oldDeviceToken"];
        }
        else
        {
            [currentDeviceInformation setObject:@"" forKey:@"oldDeviceToken"];
        }
        [[NSUserDefaults standardUserDefaults] setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kAMDeviceToken] forKey:kAMOldDeviceToken];
        [[NSUserDefaults standardUserDefaults] synchronize];

    }
    
    NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"E, MMM d yyyy HH:mm:ss ZZZZZ"];
    NSString *localDateString = [dateFormatter stringFromDate:[NSDate date]];
    [currentDeviceInformation setObject:localDateString forKey:@"deviceTimestamp"];

    NSString* Identifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    [currentDeviceInformation setObject:Identifier forKey:@"deviceUUID"];

    NSURL *serviceUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/deviceRegisterService",kAMBaseURL]];
    
    [webComm callToServerRequestDictionary:currentDeviceInformation onURL:serviceUrl WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm) {
        if (!error)
        {
            NSLog(@"%ld, %@",(long)status_code,response);
            if ([[response objectForKey:@"responseCode"] integerValue] == 0)
            {
                // [[[UIAlertView alloc] initWithTitle:@"Alert" message:[response objectForKey:@"responseDescription"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            }
            else
            {
                
            }
        }
        else
        {
            NSLog(@"%@",error);
        }
        
    }];
}

//currentDeviceInformation variable contains following details
//{
//    deteactedResolution = "768px*1024px";
//    deviceName = "Demo\U2019s iPad OS";
//    deviceStorage = "8.19GB used 4.70GB available";
//    deviceTimestamp = "Fri, Feb 1 2019 01:30:54 -06:00";
//    deviceToken = c29443bdc329e20f760f05d103ab1d40b1c1e7d7cfcaa34dfe8c967fded7cdd5;
//    deviceType = "Camera device";
//    deviceUUID = "431741BB-EF44-4CE7-B876-C3671E6ECC73";
//    guidedAccessEnabled = 0;
//    ipAddress = "192.168.2.43";
//    oldDeviceToken = c29443bdc329e20f760f05d103ab1d40b1c1e7d7cfcaa34dfe8c967fded7cdd5;
//    operationgSystemVersion = "9.3.5";
//    subNetMask = "255.255.255.0";
//    wirelessNetwork = LAPTOPNETWORK;
//}




-(NSDictionary *)getFreeDiskspace {
    uint64_t totalSpace = 0;
    uint64_t totalFreeSpace = 0;
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    
    if (dictionary) {
        return dictionary;
        NSNumber *fileSystemSizeInBytes = [dictionary objectForKey: NSFileSystemSize];
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        totalSpace = [fileSystemSizeInBytes unsignedLongLongValue];
        totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
        NSLog(@"Memory Capacity of %llu MiB with %llu MiB Free memory available.", ((totalSpace/1024ll)/1024ll), ((totalFreeSpace/1024ll)/1024ll));
    } else {
        NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);
    }
    return [NSDictionary dictionary];
    // return ((totalSpace/1024ll)/1024ll);
}


- (NSString *)GetCurrentWifiHotSpotName {
    NSString *wifiName = nil;
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    for (NSString *ifnam in ifs) {
        NSDictionary *info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info[@"SSID"]) {
            wifiName = info[@"SSID"];
        }
    }
    return wifiName;
}

- (NSString *)getIPAddressofDevice
{
    NSString * address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0)
    {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL)
        {
            if(temp_addr->ifa_addr->sa_family == AF_INET)
            {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
                {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

- (NSString *)getSubnetMaskofDevice
{
    NSString * netmask = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0)
    {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL)
        {
            if(temp_addr->ifa_addr->sa_family == AF_INET)
            {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
                {
                    // Get NSString from C String
                    netmask = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_netmask)->sin_addr)];
                    
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return netmask;
}

- (void)methodCreated
{
    NSLog(@"hey");
}

@end
