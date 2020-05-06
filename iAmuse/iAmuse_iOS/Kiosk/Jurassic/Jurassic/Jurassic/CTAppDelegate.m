//
//  CTAppDelegate.m
//  Jurassic
//
//  The CTKiosk will tell us through the notification center when we should display the splash.
//
//  Created by Roland Hordos on 2013-05-25.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "CTAppDelegate.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "Kiosk.h"
#import "LRRestyClient+GET.h"
#import "LRResty.h"
#import "AMJSONAuthData.h"
#import "AMCloudClient.h"
#import "MBProgressHUD.h"
#import "AMConstants.h"
#import "PhotoLayout.h"
#import "PhotoSession.h"
#import "CTKioskViewController.h"
#import "CTGetReadyViewController.h"
#import "AMTakingPicturesViewController.h"
#import "CTKioskSplashViewController.h"
#import "TSMessage.h"
#import "AMUtility.h"
#import "AMStorageManager.h"
#import "ViewController.h"
#import "WebCommunication.h"
#import "NSData+Base64.h"
#import <CrashReporter/CrashReporter.h>
#import "EventListViewController.h"
#import "InitialViewController.h"
#import "BaseNavigationController.h"
#import "UIView+Toast.h"

#define kUserId @"userId"
#define MEMORY_FLUSH_AUTO

#ifdef MEMORY_FLUSH_AUTO
#import <mach/mach.h>
#import <mach/mach_host.h>
#endif
@implementation CTAppDelegate
@synthesize globalVariable;
@synthesize sharedArray;
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (_idleTimer)
    {
        // Simply wind the timer ahead again, we've felt a touch.
        [_idleTimer invalidate];
    }
}

- (natural_t)getFreeMemory:(BOOL)printLog
{
    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;
    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);
    vm_statistics_data_t vm_stat;
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS)
    {
        NSLog(@"Failed to fetch virtual memory statistics");
        return 0;
    }
    
    // stats in bytes
    natural_t mem_free = vm_stat.free_count * pagesize;
    
    if(1)
    {
        //   NSLog(@"free memory MB: %f",(float)mem_free/(1024.0*1024.0));
    }
    
    return mem_free/(1024.0*1024.0);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
//    [GIDSignIn sharedInstance].clientID = @"233319256155-hag22980ra7uq3o1mhuacjaqrvui8l6u.apps.googleusercontent.com";
    [GIDSignIn sharedInstance].clientID = @"655850534607-plvkug3chrga236j41qpu9vj7c325in6.apps.googleusercontent.com";
    [GIDSignIn sharedInstance].delegate = self;
    
    [FIRApp configure];
    
    
   
    
    sharedArray = [[NSMutableArray alloc]init];
    
    //    [self sendCrashReportToServer];
    //    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(getFreeMemory:) userInfo:nil repeats:YES];
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * deviceModePref = [defaults stringForKey:AMDeviceModeSettingsKey];
    // show the storyboard
    
    [self setInitialViewCtr];
    
   /* UIStoryboard *storyboard;
    if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
    {
        storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
        UIViewController *rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"InitialViewController"];
        self.window.rootViewController = rootViewController;
    }
    else
    {
        if((UI_USER_INTERFACE_IDIOM()) == UIUserInterfaceIdiomPhone)
        {
            storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhoneTouch" bundle:nil];
        }
        else
        {
            storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
        }
        UIViewController *rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"InitialViewController"];
        
        self.window.rootViewController = rootViewController;
    }*/
    
    /*   UIStoryboard *storyboard = [self grabStoryboard];
     
     // show the storyboard
     UIViewController *rootViewController = [storyboard instantiateInitialViewController];
     if (0)
     {
     self.window.rootViewController = rootViewController;
     }
     else
     {
     if((UI_USER_INTERFACE_IDIOM()) == UIUserInterfaceIdiomPhone)
     {
     storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
     
     if([[NSUserDefaults standardUserDefaults] boolForKey:@"isLogin"])
     {
     rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"EventListViewController"];
     }
     else
     {
     rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"SignInViewController"];
     }
     UINavigationController *navCont = [[UINavigationController alloc] initWithRootViewController:rootViewController];
     self.window.rootViewController = navCont;
     
     }
     else
     {
     storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
     //  storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
     
     rootViewController = [storyboard instantiateInitialViewController];
     
     self.window.rootViewController = rootViewController;
     
     }
     
     }
     */
    //    if((UI_USER_INTERFACE_IDIOM()) == UIUserInterfaceIdiomPhone)
    //    {
    //       [self askUserForPushNotification:application];
    //    }
    [AMUtility enableAsyncLogging];
    
    DDLogInfo(@"%@", [self appNameAndVersionNumberDisplayString]);
    
    // Prevent the screen saver from coming on.
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    // Access the storage manager at least once to initialize it, which includes
    // setting up local default settings.
    [AMStorageManager sharedInstance];
    
    // Tell us when application user settings change.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appSettingsDidChange:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
    
    // Tell us when camera api events happen from the built in web server.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveResumePhotoSession:)
                                                 name:AMCameraResumePhotoSessionNotification
                                               object:nil];
    
    // Tell us when we should be showing the Thank You screen.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showThankYou:)
                                                 name:AMShowThankYouNotification
                                               object:nil];
    // Assemble and start the Kiosk.
    kiosk = [CTKiosk sharedInstance];
    [kiosk startup:@""];
    
    [self verifyThemeAssets];
    [self verifyPhotoStore];
    
    
    //    // Notification center tells us when to show the Camera screen.
    //    [[NSNotificationCenter defaultCenter] addObserver:self
    //                                             selector:@selector(showCamera:)
    //                                                 name:AMShowCameraNotification
    //                                               object:nil];
    
    // Touch Screen moves to the Taking Picture view when the first photo is
    // available on the camera.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveTakingPictures:)
                                                 name:AMCameraNewRemotePhotoNotification
                                               object:nil];
    
    // Observe a sense that the user is in session.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didSenseUser:)
                                                 name:AMDidSenseUser
                                               object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivePresentError:)
                                                 name:kAMPresentErrorNotification
                                               object:nil];
    
    
    // With event bindings in place, let's hook up the cloud async code.
    [self prepareCloud];
    
    // Enable battery monitoring so we can disable sleep properly.
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    
    // Sense the user.
    idleTimerInvocation = nil;
    idleTimerSelector = @selector(userDidLeave);
    if ([self respondsToSelector:idleTimerSelector])
    {
        idleTimerMethodSig = [self methodSignatureForSelector:idleTimerSelector];
        if (idleTimerMethodSig != nil)
        {
            idleTimerInvocation = [NSInvocation invocationWithMethodSignature:idleTimerMethodSig];
            [idleTimerInvocation setTarget:self];
            [idleTimerInvocation setSelector:idleTimerSelector];
        }
    }
    
    // Override point for customization after application launch.
    PLCrashReporter * crashReporter = [PLCrashReporter sharedReporter];
    NSError * error;
    
    /* Check if we previously crashed */
    if ([crashReporter hasPendingCrashReport])
    {
        [[[UIAlertView alloc] initWithTitle:@"CrashReport" message:@"Application seems quit unexpectly last time. Do you want to send the report ?" delegate:self cancelButtonTitle:@"Don't Send" otherButtonTitles:@"Send",nil] show];
    }
    
    /* Enable the Crash Reporter */
    if (![crashReporter enableCrashReporterAndReturnError: &error])
        NSLog(@"Warning: Could not enable crash reporter: %@", error);
    
    if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
    {
        // For Camera Access Permission
        //        if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType: completionHandler:)])
        //        {
        //            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        //                // Will get here on both iOS 7 & 8 even though camera permissions weren't required
        //                // until iOS 8. So for iOS 7 permission will always be granted.
        //                if (!granted)
        //                {
        //                    // Permission not granted.
        //                    dispatch_async(dispatch_get_main_queue(), ^{
        //                        [[[UIAlertView alloc] initWithTitle:@"Attention" message:@"Camera Access Permission Denied. Application need camera access to function properly. Please allow the same from Settings->iAmuseCK->Camera" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];                    });
        //
        //                }
        //            }];
        //        }
    }
    
    // For Gallery Access Permission
    ALAssetsLibrary * lib = [[ALAssetsLibrary alloc] init];
    [lib enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                       usingBlock:^(ALAssetsGroup * group, BOOL * stop){
                           NSLog(@"%i",[group numberOfAssets]);}
                     failureBlock:^(NSError * error){
                         //        if (error.code == ALAssetsLibraryAccessUserDeniedError)
                         //        {
                         //            NSLog(@"user denied access, code: %i",error.code);
                         //        }
                         //        else
                         //        {
                         //            NSLog(@"Other error code: %i",error.code);
                         //        }
                     }];
    //    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    //    if (status != ALAuthorizationStatusAuthorized)
    //    {
    //        [[[UIAlertView alloc] initWithTitle:@"Attention" message:@"Please give permission to access your photo library from settings app" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
    //    }
    
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"%s", __FUNCTION__);
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"%s", __FUNCTION__);
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [kiosk pause];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [kiosk registerDeviceOnServer];
    [kiosk startServer];
    
    NSLog(@"%s", __FUNCTION__);
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [kiosk resume];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    //TODO: comment for register touch device if((UI_USER_INTERFACE_IDIOM()) == UIUserInterfaceIdiomPhone)
    
    kiosk = [CTKiosk sharedInstance];
    [kiosk registerDeviceOnServer];
    [kiosk startServer];
    
    
    
    if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType: completionHandler:)])
    {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            // Will get here on both iOS 7 & 8 even though camera permissions weren't required
            // until iOS 8. So for iOS 7 permission will always be granted.
            if (!granted)
            {
                // Permission not granted.
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Attention" message:@"Camera Access Permission Denied. Application need camera access to function properly. Please allow the same from Settings->iAmuseCK->Camera" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                    alertView.tag = 101;
                    [alertView show];
                    [self askUserForPushNotification:application];
                });
                
                
            }
            else
            {
                [self askUserForPushNotification:application];
                
            }
            
        }];
    }
    
    {
    }
    
    //    [self getAllEvents];
    NSLog(@"%s", __FUNCTION__);
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"%s", __FUNCTION__);
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // NSUserDefaultsDidChangeNotification
    
    // Save changes if there are any.
    [[AMStorageManager sharedInstance] saveCoreData:nil];
}

#pragma mark - UIAlertView Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 101) {
        if (buttonIndex == 0) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }
    }
    else if (buttonIndex == 1)
    {
        [self handleCrashReport];
        [self sendCrashReportToServer];
    }
}

#pragma mark -

- (void) handleCrashReport
{
    PLCrashReporter * crashReporter = [PLCrashReporter sharedReporter];
    NSData * crashData;
    NSError * error;
    
    /* Try loading the crash report */
    
    crashData = [crashReporter loadPendingCrashReportDataAndReturnError:&error];
    //NSLog(@"%@",[[NSString alloc] initWithData:crashData encoding:NSUTF8StringEncoding]);
    if (crashData == nil)
    {
        // NSLog(@"Could not load crash report: %@", error);
    }
    
    PLCrashReportTextFormat textFormat = PLCrashReportTextFormatiOS;
    /* Decode data */
    
    PLCrashReport * crashLog = [[PLCrashReport alloc] initWithData:crashData error:&error];
    if (crashLog == nil)
    {
        //NSLog(@"Could not decode crash file :%s",[[error localizedDescription] UTF8String]);
    }
    else
    {
        NSString * report = [PLCrashReportTextFormatter stringValueForCrashReport: crashLog withTextFormat:textFormat];
        //NSLog(@"Crash log \n\n\n%@ \n\n\n", report);
        NSString * path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString * crashfolderPath = [path stringByAppendingPathComponent:@"/CrashFileFolder"];
        
        NSError * error;
        if (![[NSFileManager defaultManager] fileExistsAtPath:crashfolderPath])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:crashfolderPath withIntermediateDirectories:YES attributes:nil error:&error];
        }
        NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"hh:mm:ss";
        [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
        NSString * time = [dateFormatter stringFromDate:[NSDate date]];
        NSString * outputPath = [crashfolderPath stringByAppendingPathComponent: [NSString stringWithFormat: @"%@-%@.crash", @"app",time] ];
        if (![report writeToFile:outputPath atomically:YES encoding:NSUTF8StringEncoding error:nil])
        {
            //NSLog(@"Failed to write crash report");
        }
        else
        {
            //NSLog(@"Saved crash report to: %@", outputPath);
        }
    }
    
    /* We could send the report from here, but we'll just print out
     * some debugging info instead */
    /*
     PLCrashReport *report = [[[PLCrashReport alloc] initWithData: crashData error: &error] autorelease];
     if (report == nil) {
     NSLog(@"Could not parse crash report");
     goto finish;
     }
     
     NSLog(@"Crashed on %@ === %@", report.systemInfo.timestamp,report.threads.description);
     NSLog(@"Crashed with signal %@ (code %@, address=0x%" PRIx64 ")", report.signalInfo.name,
     report.signalInfo.code, report.signalInfo.address);
     
     */
    
    /* Purge the report */
finish:
    [crashReporter purgePendingCrashReport];
    return;
}

- (void)sendCrashReportToServer
{
    //Crash Report
    NSString * path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString * crashfolderPath = [path stringByAppendingPathComponent:@"/CrashFileFolder"];
    NSArray * filePathsArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:crashfolderPath  error:nil];
    
    NSMutableArray * crashArray = [[NSMutableArray alloc] init];
    for(NSString * path in filePathsArray)
    {
        NSString * pathString = [NSString stringWithFormat:@"%@/%@",crashfolderPath,path];
        if ([[NSFileManager defaultManager] fileExistsAtPath:pathString])
        {
            NSData * dataFromPath = [NSData dataWithContentsOfFile:pathString];
            NSString * base64string = [dataFromPath base64EncodedString];
            
            NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
            [dic setObject:base64string forKey:@"file"];
            [crashArray addObject:dic];
        }
    }
    //    NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
    //    [dic setObject:@"test" forKey:@"file"];
    
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",
                                        kAMBaseURL, @"crashlogsupload"]];
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
    [dict setObject:crashArray forKey:@"files"];
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"isLogin"])
    {
        [dict setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"userId"] forKey:@"userId"];
    }
    else
    {
        [dict setObject:@"1" forKey:@"userId"];
    }
    WebCommunication * webComm = [WebCommunication new];
    [webComm callToServerRequestDictionary:dict onURL:url WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm)
     {
         //NSLog(@"response : %@",response);
         //NSLog(@"status_code : %ld",(long)status_code);
         
         if([[response objectForKey:@"responseDescription"] isEqualToString:@"Success"])
         {
             //NSLog(@"Crash Report has send to server successfully.");
             for(NSString * path in filePathsArray)
             {
                 NSString * pathString = [NSString stringWithFormat:@"%@/%@",crashfolderPath,path];
                 if ([[NSFileManager defaultManager] removeItemAtPath:pathString error:&error])
                 {
                     //NSLog(@"File removed from Document directory.");
                 }
             }
         }
         else
         {
             //NSLog(@"Crash Report has not been send to server due to some problem.");
         }
     }];
}

- (NSString *)appNameAndVersionNumberDisplayString
{
    NSDictionary * infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString * appDisplayName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
    NSString * majorVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString * minorVersion = [infoDictionary objectForKey:@"CFBundleVersion"];
    
    return [NSString stringWithFormat:@"%@, Version %@ (%@)", appDisplayName, majorVersion, minorVersion];
}

- (NSString *)appVersionNumberString
{
    NSDictionary * infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString * majorVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString * minorVersion = [infoDictionary objectForKey:@"CFBundleVersion"];
    
    return [NSString stringWithFormat:@"%@ (%@)", majorVersion, minorVersion];
}

- (void)appSettingsDidChange:(NSNotification *)notification
{
    NSLog(@"App settings changed.");
    if (!kiosk)
    {
        kiosk = [CTKiosk sharedInstance];
    }
    [kiosk loadPersistentSettings:NO];
}

//
// Feel for touches to keep track of idle time.
//
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self resetIdleTimer];
    
    // After hours wasted trying to get events to handle reliably from the splash
    // including overlay, movie, bumper ... a new angle.
    UIResponder *currentController = [[[[[UIApplication sharedApplication] keyWindow] subviews] objectAtIndex:0] nextResponder];
    if ([currentController isMemberOfClass:[CTKioskSplashViewController class]]) {
        // If we're not using a Nav Controller.
        // Splash screen touched.
        [(CTKioskSplashViewController *)currentController selectScene];
        //        [(UIViewController *)currentController performSegueWithIdentifier:@"photoSession" sender:nil];
    } else if ([currentController isMemberOfClass:[BaseNavigationController class]]) {
        NSArray *navStack = ((UINavigationController *)currentController).viewControllers;
        currentController = [navStack objectAtIndex:[navStack count] - 1];
        if ([currentController isMemberOfClass:[CTKioskSplashViewController class]]) {
            if([[NSUserDefaults standardUserDefaults] boolForKey:@"isLogin"])
            {
                // [(CTKioskSplashViewController *)currentController performSegueWithIdentifier:@"PurchaseScene" sender:nil];
                [self getSubscriptionDetail:currentController];
            }
            else
            {
                [(CTKioskSplashViewController *)currentController performSegueWithIdentifier:@"signin" sender:nil];
                
            }
        }
    }
}

- (void)getSubscriptionDetail:(UIResponder *)currentController
{
    WebCommunication *webComm = [[WebCommunication alloc] initWithServiceType:1];
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"userId"] forKey:@"userId"];
    NSURL *serviceUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/subscriptionsList",kAMBaseURL]];
    [MBProgressHUD showHUDAddedTo:self.window animated:YES];
    [webComm callToServerRequestDictionary:dic onURL:serviceUrl WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm) {
        [MBProgressHUD hideHUDForView:self.window animated:YES];
        if (!error)
        {
            NSLog(@"%ld, %@",(long)status_code,response);
            if ([[response objectForKey:@"responseCode"] integerValue] != 1)
            {
                [[[UIAlertView alloc] initWithTitle:@"Alert" message:[response objectForKey:@"responseDescription"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                
            }
            else
            {
                UIStoryboard *storyboard;
                NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
                NSString * deviceModePref = [defaults stringForKey:AMDeviceModeSettingsKey];
                // show the storyboard
                UIViewController *rootViewController = [storyboard instantiateInitialViewController];
                if (0)
                {
                    self.window.rootViewController = rootViewController;
                }
                else
                {
                    if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
                    {
                        //  if((UI_USER_INTERFACE_IDIOM()) == UIUserInterfaceIdiomPhone)
                        
                        storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
                    }
                    else
                    {
                        if((UI_USER_INTERFACE_IDIOM()) == UIUserInterfaceIdiomPhone)
                        {
                            storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhoneTouch" bundle:nil];
                        }
                        else
                        {
                            storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
                        }
                    }
                }
                NSString *subId = [NSString stringWithFormat:@"%@",[response objectForKey:@"subId"]];
                //                if([subId isEqualToString:@"1"])
                //                {
                //                    [(CTKioskSplashViewController *)currentController performSegueWithIdentifier:@"PurchaseScene" sender:nil];
                //                }
                //                else
                {
                    [(CTKioskSplashViewController *)currentController performSegueWithIdentifier:@"eventlist" sender:nil];
                }
                
            }
        }
        else
        {
            [[[UIAlertView alloc] initWithTitle:@"Alert" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            
            NSLog(@"%@",error);
        }
        
    }];
    
}

//
// Send a notification when the user idle time reaches the kiosk maximum.  Apply
// it for the Camera as well, for the case of an installation that leaves the
// capture mode running.
//
- (void)resetIdleTimer {
    //    NSLog(@"%s", __FUNCTION__);
    
    if (_idleTimer) {
        // Simply wind the timer ahead again, we've felt a touch.
        [_idleTimer invalidate];
    }
    
    if (idleTimerInvocation && kiosk && !(kiosk.idleFeelingTimeoutMins == 0)) {
        _idleTimer = [NSTimer scheduledTimerWithTimeInterval:kiosk.idleFeelingTimeoutMins * 60
                                                  invocation:idleTimerInvocation
                                                     repeats:NO];
    }
}


- (void)prepareCloud {
    /*
     Cloud auth is asynchronous.  Kick it off right here while the app starts.
     
     Register 'app' to receive change notifications for the 'authenticated'
     property of the 'cloud' object for new values.
     */
    AMCloudClient *cloud = [AMCloudClient instance];
    [cloud addObserver:self
            forKeyPath:@"authenticated"
               options:NSKeyValueObservingOptionNew
               context:NULL];
    
    [cloud connect];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    /*
     We listen for changes to the 'authenticated' property of the 'cloud'.
     */
    if ([keyPath isEqual:@"authenticated"]) {
        if ([change objectForKey:NSKeyValueChangeNewKey]) {
            NSLog(@"Application is authenticated to cloud.");
            
            // Online!  Is there anything we can do immediately with our new
            // connection?
            
            // Ensure we have all of the data we need.
            [self loadKioskEntity];
            
            // Update the kiosk.entity with our new session uuid
            AMCloudClient *cloud = [AMCloudClient instance];
            if (!(cloud.sessionUuid == (id)[NSNull null] || cloud.sessionUuid.length == 0)) {
                [kiosk.entity setCloudSessionKey:cloud.sessionUuid];
            }
            
            // Save the entity.
            NSError *error = nil;
            AMStorageManager *store = [AMStorageManager sharedInstance];
            if (![store.currentMOC save:&error]) {
                // TODO Handle the error.
                NSLog(@"Error saving kiosk: %@", [error localizedDescription]);
            } else {
                NSLog(@"Saved session key.");
            }
            
        } else {
            NSLog(@"Application authentication is required.");
        }
    }
}

- (void)loadKioskEntity {
    /*
     There's a single Kiosk instance we expect, as a core data object.
     Additionally the Kiosk needs to be activated, meaning at some point it hits
     the internet, verifies authentication, and received a persistent session
     uuid.
     */
    
    // Assume no persistent session exists, this would be stored in the Kiosk
    // entity.
    DDLogVerbose(@"Loading Kiosk from CoreData");
    AMStorageManager *store = [AMStorageManager sharedInstance];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Kiosk"
                                              inManagedObjectContext:store.currentMOC];
    [request setEntity:entity];
    
    NSString *productId = kiosk.productCode;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"productId == %@",
                              productId];
    [request setPredicate:predicate];
    NSError *error;
    NSArray *array = [store.currentMOC executeFetchRequest:request error:&error];
    if ([array count] > 0) {
        kiosk.entity = array[0];
    }
    
    AMCloudClient *cloud = [AMCloudClient instance];
    if (kiosk.entity && (!(kiosk.entity.cloudSessionKey == (id)[NSNull null] ||
                           kiosk.entity.cloudSessionKey.length == 0)))
    {
        [cloud setSessionUuid:kiosk.entity.cloudSessionKey];
    } else {
        // We don't have an entity yet, we need to use the cloud client to
        // connect and activate.
        if (cloud.authenticated) {
            // If activation succeeds, store the entity and return it,
            // along with the client's persistent session uuid and the urlsafe
            // version of the cloud Kiosk entity.
            
            // Do we already have an activation key?
            if (!kiosk.entity.cloudKey) {
                // Get the UDID equivalent for the activation key.  This is not unique
                // to the device but to the installation and app.  Re-install and you
                // have a new UDID.
                NSUUID *deviceId = [[UIDevice currentDevice] identifierForVendor];
                [cloud activate:store.currentMOC deviceId:[deviceId UUIDString]];
            }
        } else {
            NSLog(@"loadKioskEntity found the cloud was not authenticated "
                  "for activation, so asked to connect.");
            [cloud connect];
        }
    }
}


//
//  Ensure the customizable asset files are in place, and if not copy the default
//  equivalents from the dist resource bundle.
//
- (void)verifyThemeAssets {
    NSString *storePath = [AMUtility applicationDocumentsDirectory];
    NSArray *assetFileNames = [NSArray arrayWithObjects:@"splash.mp4", @"header.png", @"footer.png", @"nothing_to_print.png", @"splash_kiosk.png", nil];
    NSString *defaultAssetPath = nil;
    NSString *assetPath = nil;
    NSString *bundlePath = [[NSBundle mainBundle] resourcePath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    for (id assetFileName in assetFileNames) {
        assetPath = [storePath stringByAppendingPathComponent:assetFileName];
        if (![fileManager fileExistsAtPath:assetPath]) {
            defaultAssetPath = [bundlePath stringByAppendingPathComponent:assetFileName];
            // defaultAssetPath = [[NSBundle mainBundle] pathForResource:@"nothing_to_print" ofType:@"png"];
            //  NSData *data = [NSData dataWithContentsOfFile:defaultAssetPath];
            if (defaultAssetPath && [fileManager fileExistsAtPath:defaultAssetPath]) {
                NSLog(@"Copying default theme asset %@ in place.", assetFileName);
                NSError *error = nil;
                [fileManager copyItemAtPath:defaultAssetPath toPath:assetPath error:&error];
                if (error) {
                    NSLog(@"Error %@ copying asset %@", error, assetFileName);
                }
            }
        }
    }
}

- (void)verifyPhotoStore
{
    NSString * photoStore = kiosk.photoStoreDirectory;
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:photoStore])
    {
        [fileManager createDirectoryAtPath:photoStore
               withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

/*
 We expect notifications to come in out of an arbitrary thread.
 */
- (void)receiveResumePhotoSession:(NSNotification *)notification
{
    [self performSelectorOnMainThread:@selector(resumePhotoSession:) withObject:notification waitUntilDone:NO];
}

/*
 We expect to receive a notification object as an array, like:
 (entity type, key, args)
 
 Right now this is only relevant to Camera mode.  After the session is
 started or resumed, we need to segue to camera mode, reset and start the countdown.
 */
- (void)resumePhotoSession:(NSNotification *)notification
{
    NSLog(@"%s", __FUNCTION__);
    if (kiosk.deviceMode == CTKioskDeviceModeCamera)
    {
        //        NSLog(@"%s", sel_getName(_cmd));
        NSArray * master = [notification object];
        NSLog(@"Notification object: %@", master);
        NSDictionary * args = nil;
        NSString * background = nil;
        NSString * sessionId = nil;
        switch ([master count])
        {
            case 3:
                args = [master objectAtIndex:2];
                background = [args objectForKey:@"background"];
            case 2:
                sessionId = [master objectAtIndex:1];
                break;
            default:
                break;
        }
        
        // First load the layout.
        PhotoLayout * selectedPhotoLayout = nil;
        AMStorageManager * store = [AMStorageManager sharedInstance];
        NSFetchRequest * request = [[NSFetchRequest alloc] init];
        NSEntityDescription * entity = [NSEntityDescription
                                        entityForName:@"PhotoLayout"
                                        inManagedObjectContext:store.currentMOC];
        [request setEntity:entity];
        
        NSPredicate * predicate = [NSPredicate
                                   predicateWithFormat:@"background == %@", background];
        
        [request setPredicate:predicate];
        NSError * error;
        NSArray * results = [store.currentMOC executeFetchRequest:request
                                                            error:&error];
        if ([results count] > 0)
        {
            selectedPhotoLayout = results[0];
        }
        
        // Secondly look for an existing session.
        if (selectedPhotoLayout)
        {
            request = [[NSFetchRequest alloc] init];
            entity = [NSEntityDescription entityForName:@"PhotoSession"
                                 inManagedObjectContext:store.currentMOC];
            
            [request setEntity:entity];
            predicate = [NSPredicate predicateWithFormat:@"photoSessionId == %@", sessionId];
            [request setPredicate:predicate];
            
            NSError * error2;
            results = [store.currentMOC executeFetchRequest:request
                                                      error:&error2];
            if ([results count] > 0)
            {
                kiosk.currentPhotoSession = results[0];
            }
            else
            {
                [kiosk startPhotoSession:selectedPhotoLayout
                       selectedSessionId:nil];
            }
            
            [self proceedWithPhotoShoot];
        }
        else
        {
            NSLog(@"No selected layout so we cannot proceed with the photo shoot.");
//            [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Selected event is not downloaded on camera device so please download it first." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            
             [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Event has been updated in the web.Please goto eventlist and redownload the event." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            
        }
    }
}

- (void)proceedWithPhotoShoot
{
    UIResponder *currentController = [[[[[UIApplication sharedApplication] keyWindow] subviews] objectAtIndex:0] nextResponder];
    if ([currentController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navContr = (UINavigationController *)currentController;
        currentController = [navContr.viewControllers lastObject];
        if ([currentController isKindOfClass:[EventListViewController class]])
        {
            //            UIStoryboard *storyboard;
            //            if((UI_USER_INTERFACE_IDIOM()) == UIUserInterfaceIdiomPhone)
            //            {
            //                storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
            //            }
            //            else
            //            {
            //                storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
            //            }
            //            UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"CTKioskViewController"];
            //            navContr.viewControllers = @[currentController,viewController];
            //            currentController = viewController;
        }
    }
    
    if ([currentController isMemberOfClass:[CTKioskViewController class]]) {
        [(CTKioskViewController *)currentController setIsTestingCamera:NO];
        [(CTKioskViewController *)currentController showCamera];
        //        [self segueToCamera];
    } else if  ([currentController isMemberOfClass:[CTCameraViewController class]]) {
        // Simply reset the countdown.
        [[NSNotificationCenter defaultCenter] postNotificationName:AMCameraResetPhotoShootNotification object:self];
    }
    else if  ([currentController isMemberOfClass:[ViewController class]]) {
        // Simply reset the countdown.
        [[NSNotificationCenter defaultCenter] postNotificationName:AMCameraResetPhotoShootNotification object:self];
    } else if  ([currentController isMemberOfClass:[CTSettingsViewController class]]) {
        // Assumed it was left in settings mode.  Recall it and segue to the camera.
        [((UIViewController *) currentController).presentingViewController dismissViewControllerAnimated:YES completion:nil];
        NSLog(@"WARNING: Recursive call, MUST exit Settings view.");
        //        [self proceedWithPhotoShoot];
    } else {
        NSLog(@"Unplanned scenario, presently showing %@",
              NSStringFromClass([currentController class]));
    }
}

- (void)showThankYou:(NSNotification *)notification
{
    if ([NSThread isMainThread])
    {
        UIResponder * currentController = [[[[[UIApplication sharedApplication] keyWindow] subviews] objectAtIndex:0] nextResponder];
        
        if ([currentController isMemberOfClass:[CTKioskViewController class]])
        {
            [(CTKioskViewController *)currentController showThankYou];
        }
        else
        {
            NSLog(@"Unplanned scenario, presently showing %@", NSStringFromClass([currentController class]));
        }
    }
    else
    {
        [self performSelectorOnMainThread:@selector(showThankYou:)
                               withObject:nil waitUntilDone:NO];
    }
}

//- (void)segueToCamera {
//    /*
//     Performs no validation, this is required in a "show" method before the segue.
//     */
//    UIResponder *currentController = [[[[[UIApplication sharedApplication] keyWindow] subviews] objectAtIndex:0] nextResponder];
//    [(UIViewController *)currentController performSegueWithIdentifier:@"CameraView" sender:nil];
//}

- (void)receiveTakingPictures:(NSNotification *)notification
{
    /*
     We expect notifications to come in out of thread they were sent.
     */
    [self performSelectorOnMainThread:@selector(takingPictures:)
                           withObject:notification waitUntilDone:NO];
}

- (void)takingPictures:(NSNotification *)notification
{
    /*
     Ensure the Taking Pictures view is being shown, segue if necessary.  We
     want to be called every time a new image is available and update progress.
     
     We expect the notification object to be:
     A ReST entity, an array of at least 2 entries
     - type
     - key
     */
    UIResponder *currentController = [[[[[UIApplication sharedApplication] keyWindow] subviews] objectAtIndex:0] nextResponder];
    if ([currentController isMemberOfClass:[CTGetReadyViewController class]]) {
        [self segueToTakingPictures];
    } else if  ([currentController isMemberOfClass:[AMTakingPicturesViewController class]]) {
        // pass
    } else {
        NSLog(@"Unplanned scenario, presently showing %@",
              NSStringFromClass([currentController class]));
    }
}

- (void)segueToTakingPictures
{
    // Performs no validation, this is required in a "show" method before the segue.
    
    if (!kiosk.entity)
    {
        [self loadKioskEntity];
    }
    
    UIResponder * currentController = [[[[[UIApplication sharedApplication] keyWindow] subviews] objectAtIndex:0] nextResponder];
    [(UIViewController *)currentController performSegueWithIdentifier:@"PhotoShoot" sender:nil];
}

//
// Announce the event, the max interval timer has been tripped.
- (void)userDidLeave
{
    NSLog(@"%s", __FUNCTION__);
    // Announce it.
    [[NSNotificationCenter defaultCenter] postNotificationName:AMUserDidLeave object:self];
}

- (void) didSenseUser:(NSNotification *)notification
{
    [self resetIdleTimer];
}

//  Receive an NSError from an arbitrary thread (via notification.object).
- (void)receivePresentError:(NSNotification *)notification
{
    if (notification.object && [notification.object isKindOfClass:[NSError class]])
    {
        [self performSelectorOnMainThread:@selector(presentError:)
                               withObject:notification.object waitUntilDone:NO];
    }
}

//  Thread safe call to show an error via TSMessages.
- (void)presentError:(NSError *)error
{
    if ([NSThread isMainThread])
    {
        DDLogError(@"Error: (code %ld) %@ %@ %@", (long)[error code],
                   [error localizedDescription],[error localizedFailureReason],
                   [error userInfo]);
        DDLogVerbose(@"Stack: %@",[NSThread callStackSymbols]);
        
        @try {
            UIViewController * vc = [AMUtility currentViewController];
            if (vc) {
                NSTimeInterval duration = 100; //kAMErrorDisplayDurationSecs;
                NSString * title = error.localizedDescription;
                NSString * subtitle = error.localizedRecoverySuggestion;
                
                [TSMessage showNotificationInViewController:vc
                                                      title:title
                                                   subtitle:subtitle
                                                      image:nil
                                                       type:TSMessageNotificationTypeError
                                                   duration:duration
                                                   callback:nil
                                                buttonTitle:nil
                                             buttonCallback:nil
                                                 atPosition:TSMessageNotificationPositionBottom
                                       canBeDismissedByUser:YES];
                
            }
            else
            {
                [self showError:error];
            }
        }
        @catch (NSException * exception)
        {
            // Fall back to simpler ..
            [self showError:error];
        }
    }
    else
    {
        [self performSelectorOnMainThread:@selector(presentError:)
                               withObject:error waitUntilDone:NO];
    }
}

- (void)showAlert:(NSDictionary *)message
{
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:message[@"title"]
                                                     message:message[@"body"]
                                                    delegate:nil
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil];
    [alert show];
}

- (void)showError:(NSError *)error
{
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:error.domain
                                                     message:error.localizedRecoverySuggestion
                                                    delegate:nil
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil];
    [alert show];
}

- (void)setInitialViewCtr{
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * deviceModePref = [defaults stringForKey:AMDeviceModeSettingsKey];
    
    UIStoryboard *storyboard;
    if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
    {
        storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
        UIViewController *rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"InitialViewController"];
        self.window.rootViewController = rootViewController;
    }
    else
    {
        if((UI_USER_INTERFACE_IDIOM()) == UIUserInterfaceIdiomPhone)
        {
            storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhoneTouch" bundle:nil];
        }
        else
        {
            storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
        }
        UIViewController *rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"InitialViewController"];
        
        self.window.rootViewController = rootViewController;
    }
}

#pragma mark - PushNotification Handle Method

- (void)askUserForPushNotification:(UIApplication *)application
{
    // For xcode 6
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        UIUserNotificationSettings * notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeSound categories:nil];
        [application registerUserNotificationSettings:notificationSettings];
        [application registerForRemoteNotifications];
    }
    else
    {
        [application registerForRemoteNotificationTypes: UIRemoteNotificationTypeSound ];
    }
#else
    [application registerForRemoteNotificationTypes: UIRemoteNotificationTypeSound];
#endif
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString * token = [[deviceToken description] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSLog(@"didRegisterForRemoteNotificationsWithDeviceToken : %@", token);
    [[NSUserDefaults standardUserDefaults] setObject:token
                                              forKey:kAMDeviceToken];
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"isLogin"])
    {
        [dict setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"userId"] forKey:@"userId"];
    }
    else
    {
        [dict setObject:@"1" forKey:@"userId"];
    }
    [dict setObject:token forKey:kAMDeviceToken];
    WebCommunication * webComm = [WebCommunication new];
    [webComm callToServerRequestDictionary:dict onURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kAMBaseURL,kAMDeviceTokenURL]] WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm)
     {
         NSLog(@"response : %@",response);
         if(!error)
         {
             if([[response objectForKey:@"responseDescription"] isEqualToString:@"Success"])
             {
                 [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DEVICE_TOKEN_SENT];
             }
         }
         else
         {
             [[NSUserDefaults standardUserDefaults] setBool:NO forKey:DEVICE_TOKEN_SENT];
         }
     }];
    //    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err
{
    NSLog(@"Error in registration. Error: %@", err);
    double delayInSeconds = 10.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
         UIRemoteNotificationTypeSound];
    });
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSLog(@"Push notification received \n%@",userInfo);
    NSString * pushType = [userInfo objectForKey:@"type"];
    
    UIViewController* vcNow = [self topViewController:self.window.rootViewController];
    /*
     if ([vcNow isKindOfClass:[UINavigationController class]]) {
     UINavigationController *nav = (UINavigationController *)vcNow;
     vcNow = [nav.viewControllers lastObject];
     if ([vcNow isKindOfClass:[EventListViewController class]]) {
     NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
     NSString * deviceModePref = [defaults stringForKey:AMDeviceModeSettingsKey];
     if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
     {
     UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
     UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"CTKioskViewController"];
     [nav pushViewController:viewController animated:YES];
     vcNow = viewController;
     }
     }
     }
     
     */
    
    if([pushType isEqualToString:@"ImagePush"])
    {
        //        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:PENDING_SCREENSHOT_REQUEST];
        //        if([vcNow isKindOfClass:[CTKioskViewController class]])
        //        {
        //            [[NSNotificationCenter defaultCenter] postNotificationName:AMSendScreenShotServerNotification object:nil];
        //        }
        [self goToScreenShotView];
    }
    else if([pushType isEqualToString:@"RgbPush"])
    {
        
        //        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:PENDING_CONFIGUARTION_REQUEST];
        //        if([vcNow isKindOfClass:[CTKioskViewController class]])
        //        {
        //            [[NSNotificationCenter defaultCenter] postNotificationName:AMGetRGBConfigurationNotification object:nil];
        //        }
        
        MBProgressHUD * hud = [MBProgressHUD showHUDAddedTo:self.window.rootViewController.view animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        if(![[NSUserDefaults standardUserDefaults] boolForKey:HAVE_SERVER_RGB_CONFIGURATION])
        {
            hud.labelText = @"Please wait.. Loading configuration from Cloud server.";
        }
        else
        {
            hud.labelText = @"Please wait for loading RGB configuration from server.";
            hud.detailsLabelText = @"Updating RGB values.";
        }
        
        [self performSelector:@selector(loadConfigurationFromServer) withObject:nil afterDelay:4.0];
        
        //        [self loadConfigurationFromServer];
    }
    else if([pushType isEqualToString:@"ClearDevicePictures"])
    {
        [self cleanUp];
    }
    else if([pushType isEqualToString:@"EventUpdate"])
    {
        
        
        NSLog(@"push type is %@",pushType);
        
//        [self.window.rootViewController.view makeToast:@"Event updated"];
        
         NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:@"true" forKey:@"eventUpdated"];
        
        [self.window.rootViewController.view makeToast:@"Event has been updated in the web.Please goto eventlist and redownload the event."];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:AMEventConfigurationUpdateNotification object:nil];
    }
    else if ([pushType isEqualToString:@"FOVPush"])
    {
        
        MBProgressHUD * hud = [MBProgressHUD showHUDAddedTo:self.window.rootViewController.view animated:YES];
        [self performSelector:@selector(getFOV) withObject:nil afterDelay:4.0];
        
        //        [self getFOV];
        // [self getSubscriptionDetail];
        //        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //            [self getFOV];
        //        });
        
    }
    else if ([pushType isEqualToString:@"updateIP"])
    {
        [kiosk autoConfigureCameraAndTouchDevice];
    }
    
    [[NSUserDefaults standardUserDefaults]synchronize];
}

- (void)loadConfigurationFromServer
{
    //    MBProgressHUD * hud = [MBProgressHUD showHUDAddedTo:self.window.rootViewController.view animated:YES];
    //    hud.mode = MBProgressHUDModeIndeterminate;
    //    if(![[NSUserDefaults standardUserDefaults] boolForKey:HAVE_SERVER_RGB_CONFIGURATION])
    //    {
    //        hud.labelText = @"Please wait.. Loading configuration from Cloud server.";
    //    }
    //    else
    //    {
    //        hud.labelText = @"Please wait for loading RGB configuration from server.";
    //        hud.detailsLabelText = @"Updating RGB values.";
    //    }
    
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
    [dict setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"userId"] forKey:@"userId"];
    WebCommunication * webComm = [WebCommunication new];
    [webComm callToServerRequestDictionary:dict onURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kAMBaseURL,kAMGetConfigurationURL]] WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm)
     {
         [self performSelector:@selector(hideHUD) withObject:nil afterDelay:2.0];
         
         if(!error)
         {
             if([[response objectForKey:@"responseDescription"] isEqualToString:@"Success"])
             {
                 if([response objectForKey:@"rgbValue"])
                 {
                     NSArray *colorRGBInfo = [[response objectForKey:@"rgbValue"] componentsSeparatedByString:@","];
                     [[NSUserDefaults standardUserDefaults] setBool:YES forKey:HAVE_SERVER_RGB_CONFIGURATION];
                     [[NSUserDefaults standardUserDefaults] setBool:NO forKey:PENDING_CONFIGUARTION_REQUEST];
                     [[NSUserDefaults standardUserDefaults] setObject:colorRGBInfo forKey:SERVER_RGB_CONFIGURATION];
                     [[NSUserDefaults standardUserDefaults]synchronize];
                     //                     [[[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"%@",response] delegate:nil cancelButtonTitle:@"ok" otherButtonTitles: nil] show];
                     
                 }
             }
         }
         else
         {
         }
         
     }];
}

- (void)hideHUD
{
    [MBProgressHUD hideHUDForView:self.window.rootViewController.view animated:YES];
}

- (void)getSubscriptionDetail
{
    WebCommunication *webComm = [[WebCommunication alloc] initWithServiceType:1];
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"userId"] forKey:@"userId"];
    NSURL *serviceUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/subscriptionsList",kAMBaseURL]];
    [webComm callToServerRequestDictionary:dic onURL:serviceUrl WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm) {
        if (!error)
        {
            NSLog(@"%ld, %@",(long)status_code,response);
            if ([[response objectForKey:@"responseCode"] integerValue] != 1)
            {
                [[[UIAlertView alloc] initWithTitle:@"Alert" message:[response objectForKey:@"responseDescription"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                
            }
            else
            {
                NSString *subscriptionId;
                if (![response[@"subId"] isKindOfClass:[NSNull class]])
                {
                    subscriptionId = response[@"subId"];
                }
                else
                {
                    subscriptionId = @"";
                }
                [self getAllEvents:subscriptionId];
            }
        }
        else
        {
            [[[UIAlertView alloc] initWithTitle:@"Alert" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            
            NSLog(@"%@",error);
        }
        
    }];
    
}

- (void)getAllEvents:(NSString *)subId
{
    WebCommunication *webComm = [[WebCommunication alloc] initWithServiceType:1];
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"userId"] forKey:@"userId"];
    [dic setObject:subId forKey:@"subId"];
    NSURL *serviceUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/eventFetchingAdminBooth",kAMBaseURL]];
    [MBProgressHUD showHUDAddedTo:self.window.rootViewController.view animated:YES];
    
    [webComm callToServerRequestDictionary:dic onURL:serviceUrl WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm) {
        [MBProgressHUD hideHUDForView:self.window.rootViewController.view animated:NO];
        if (!error)
        {
            NSLog(@"%ld, %@",(long)status_code,response);
            if ([[response objectForKey:@"responseCode"] integerValue] != 1)
            {
                [[[UIAlertView alloc] initWithTitle:@"Alert" message:[response objectForKey:@"responseDescription"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                
            }
            else
            {
                if (![[[response objectForKey:@"adminEventPictureMappingResponse"] objectForKey:@"modifiedResult"] isKindOfClass:[NSNull class]])
                {
                    NSArray *eventArray = [[NSArray alloc]init];
                    eventArray = [[response objectForKey:@"adminEventPictureMappingResponse"] objectForKey:@"modifiedResult"];
                    if([eventArray count] == 0)
                        return;
                    NSDictionary *eventData = [eventArray firstObject];
                    if (![eventData[@"fovLeft"] isKindOfClass:[NSNull class]])
                    {
                        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                        [defaults setObject: [NSNumber numberWithInt:[eventData[@"fovLeft"] intValue]] forKey: FOV_CURTAIN_KEY_LEFT];
                        [defaults setObject: [NSNumber numberWithInt:[eventData[@"fovRight"] intValue]] forKey: FOV_CURTAIN_KEY_RIGHT];
                        [defaults setObject: [NSNumber numberWithInt:[eventData[@"fovTop"] intValue]] forKey: FOV_CURTAIN_KEY_TOP];
                        [defaults setObject: [NSNumber numberWithInt:[eventData[@"fovBottom"] intValue]] forKey: FOV_CURTAIN_KEY_BOTTOM];
                        [defaults synchronize];
                    }
                }
            }
        }
        else
        {
            [[[UIAlertView alloc] initWithTitle:@"Alert" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            
            NSLog(@"%@",error);
        }
        
    }];
    
}

- (void)goToScreenShotView
{
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:[NSBundle mainBundle]];
    UIViewController *screenShotView = [storyboard instantiateViewControllerWithIdentifier:@"ScreenShot_iPhone"];
    UIViewController *viewC = self.window.rootViewController.presentedViewController;
    if (viewC) {
        [viewC dismissViewControllerAnimated:NO completion:nil];
    }
    [self.window.rootViewController presentViewController:screenShotView animated:YES completion:nil];
}

- (UIStoryboard *)getStoryboard
{
    UIStoryboard *storyboard;
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * deviceModePref = [defaults stringForKey:AMDeviceModeSettingsKey];
    // show the storyboard
    
    if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
    {
        storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
    }
    else
    {
        if((UI_USER_INTERFACE_IDIOM()) == UIUserInterfaceIdiomPhone)
        {
            storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhoneTouch" bundle:nil];
        }
        else
        {
            storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
        }
    }
    return storyboard;
}

- (void)cleanUp
{
    //Clear from document directory.
    NSString * path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    path = [path stringByAppendingPathComponent:@"Photos"];
    NSFileManager *fileMgr = [[NSFileManager alloc] init];
    
    
    NSArray *files = [fileMgr contentsOfDirectoryAtPath:path error:nil];
    NSError *error = nil;
    
    while (files.count > 0) {
        NSArray *directoryContents = [fileMgr contentsOfDirectoryAtPath:path error:&error];
        if (error == nil) {
            for (NSString *path1 in directoryContents)
            {
                NSString *fullPath = [path stringByAppendingPathComponent:path1];
                BOOL removeSuccess = [fileMgr removeItemAtPath:fullPath error:&error];
                files = [fileMgr contentsOfDirectoryAtPath:path error:nil];
                if (!removeSuccess)
                {
                    // Error
                }
            }
        } else {
            // Error
        }
    }
    
    
    //Clear from CoreData
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Photo"];
    [fetchRequest setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    
    
    NSManagedObjectContext *moc = [[AMStorageManager sharedInstance] currentMOC];
    
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *object in fetchedObjects)
    {
        [moc deleteObject:object];
    }
    
    error = nil;
    [moc save:&error];
    
}

- (UIViewController *)topViewController:(UIViewController *)rootViewController
{
    if (rootViewController.presentedViewController == nil)
    {
        return rootViewController;
    }
    
    if ([rootViewController.presentedViewController isMemberOfClass:[UINavigationController class]])
    {
        UINavigationController * navigationController = (UINavigationController *)rootViewController.presentedViewController;
        UIViewController * lastViewController = [[navigationController viewControllers] lastObject];
        return [self topViewController:lastViewController];
    }
    
    UIViewController * presentedViewController = (UIViewController *)rootViewController.presentedViewController;
    
    return [self topViewController:presentedViewController];
}

- (UIStoryboard *)grabStoryboard
{
    
    UIStoryboard *storyboard;
    
    NSString *deviceMode = [[NSUserDefaults standardUserDefaults] valueForKey:AMDeviceModeSettingsKey];
    
    if ([deviceMode length] == 0)
    {
        return nil;
    }
    
    if ([deviceMode isEqualToString:AMDeviceModeStrCamera])
    {
        storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
    }
    else
    {
        storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
    }
    return storyboard;
}

//- (void)getAllEvents
//{
//    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
//    [dict setObject:@"1" forKey:kUserId];
//
//    
//    WebCommunication * webComm = [WebCommunication new];
//    [webComm callToServerRequestDictionary:dict onURL:[NSURL URLWithString:@"http://192.168.1.41:8080/iamuseserver/v1/iamuse/getEventList"] WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm)
//     {
//         NSLog(@"response : %@",response);
//         if(!error)
//         {
//             if([[response objectForKey:@"responseDescription"] isEqualToString:@"Success"])
//             {
//                 if([response objectForKey:@"eventList"])
//                 {
//                     
//                 }
//             }
//             [self performSelector:@selector(hideHUD) withObject:nil afterDelay:4.0];
//         }
//         else
//         {
//             [self performSelector:@selector(hideHUD) withObject:nil afterDelay:4.0];
//         }
//         
//     }];
//
//}

- (void)getFOV
{
    //    MBProgressHUD * hud = [MBProgressHUD showHUDAddedTo:self.window.rootViewController.view animated:YES];
    WebCommunication *webComm = [[WebCommunication alloc] initWithServiceType:1];
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"userId"] forKey:@"userId"];
    NSURL *serviceUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/getFov",kAMBaseURL]];
    
    [webComm callToServerRequestDictionary:dic onURL:serviceUrl WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm) {
        [MBProgressHUD hideHUDForView:self.window.rootViewController.view animated:YES];
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
                [defaults setObject: [NSNumber numberWithInt:[[response valueForKey:@"left"] intValue]] forKey: FOV_CURTAIN_KEY_LEFT];
                [defaults setObject: [NSNumber numberWithInt:[[response valueForKey:@"right"] intValue]] forKey: FOV_CURTAIN_KEY_RIGHT];
                [defaults setObject: [NSNumber numberWithInt:[[response valueForKey:@"top"] intValue]] forKey: FOV_CURTAIN_KEY_TOP];
                [defaults setObject: [NSNumber numberWithInt:[[response valueForKey:@"bottom"] intValue]] forKey: FOV_CURTAIN_KEY_BOTTOM];
                if ([[response valueForKey:@"otherIntractionTimout"] isKindOfClass:[NSNull class]] || [[response valueForKey:@"otherIntractionTimout"] isEqualToString:@""]) {
                    [defaults setObject:[NSNumber numberWithFloat:2.0] forKey:AMIdleFeelTimeoutKey];
                }
                else
                {
                    [defaults setObject:[NSNumber numberWithFloat:[[response valueForKey:@"otherIntractionTimout"] floatValue]] forKey:AMIdleFeelTimeoutKey];
                }
                if ([[response valueForKey:@"otherCountdownDelay"] isKindOfClass:[NSNull class]] || [[response valueForKey:@"otherCountdownDelay"] isEqualToString:@""])
                {
                    [defaults setObject:[NSNumber numberWithFloat:1.0] forKey:kAMCameraCountdownStepIntervalKey];
                }
                else
                {
                    [defaults setObject:[NSNumber numberWithFloat:[[response valueForKey:@"otherCountdownDelay"] floatValue]] forKey:kAMCameraCountdownStepIntervalKey];
                }
                [defaults synchronize];
            }
        }
    }];
}


- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<NSString *, id> *)options {
    return [[GIDSignIn sharedInstance] handleURL:url
                               sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                                      annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
}


- (void)signIn:(GIDSignIn *)signIn
didSignInForUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
    // Perform any operations on signed in user here.
    NSString *email = user.profile.email;
   _userId = user.userID;                  // For client-side use only!
    NSString *idToken = user.authentication.idToken; // Safe to send to the server
    NSString *fullName = user.profile.name;
    NSString *givenName = user.profile.givenName;
    NSString *familyName = user.profile.familyName;
    
     NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:fullName forKey:@"name"];
    [defaults setObject:_userId forKey:@"token"];
    [defaults setObject:email forKey:@"mail"];
     NSLog(@"Full name is %@",fullName);
    
    
   // NSUserDefaults *stddefaults = [NSUserDefaults standardUserDefaults];
    
//    NSString * username = [defaults stringForKey:@"username"];
//    
//    NSString * lastname = [defaults stringForKey:@"lastname"];
//    
//    NSString * emaill = [defaults stringForKey:@"logemailId"];
    
    
    [defaults setObject:givenName forKey:@"username"];
     [defaults setObject:familyName forKey:@"lastname"];
     [defaults setObject:email forKey:@"logemailId"];
    
    
    
    //if(!([_userId isEqualToString:@""])&& !([fullName isEqualToString:@""])&& !([email isEqualToString:@""])){
    
    if(_userId!=nil && fullName!=nil && email!=nil){

        [defaults setObject:@"yes" forKey:@"googleSignIn"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"google" object:nil];
    }
    
    else
    {
      //  [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Something went wrong!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
    }
    
    // ...
    
//    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle: nil];
//    UIViewController *rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"PurchaseViewController"];
//    self.window.rootViewController = rootViewController;
    
    
}

- (void)signIn:(GIDSignIn *)signIn
didDisconnectWithUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
    // Perform any operations when the user disconnects from app here.
    // ...
}


@end
