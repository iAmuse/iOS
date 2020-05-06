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
#import "AMPrintAppDelegate.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "AMPrintKiosk.h"
#import "Kiosk.h"
#import "LRRestyClient+GET.h"
#import "LRResty.h"
#import "AMConstants.h"
#import "PhotoLayout.h"
#import "PhotoSession.h"
#import "TSMessage.h"
#import "AMUtility.h"
#import "AMStorageManager.h"
#import "AMPrintKiosk.h"


@implementation AMPrintAppDelegate

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if (idleTimer) {
        // Simply wind the timer ahead again, we've felt a touch.
        [idleTimer invalidate];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [AMUtility enableAsyncLogging];

    DDLogInfo(@"%@", [AMUtility appNameAndVersionNumberDisplayString]);

    // Prevent the screen saver from coming on.
    [UIApplication sharedApplication].idleTimerDisabled = YES;

    // Enable battery monitoring so we can disable sleep properly.
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;

    // Access the storage manager at least once to initialize it, which includes
    // setting up local default settings.
    [AMStorageManager sharedInstance];

    // Register notifications.
    // Tell us when application user settings change.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appSettingsDidChange:)
                                                 name:NSUserDefaultsDidChangeNotification
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

    // Assemble and start the Kiosk.
    kiosk = [AMPrintKiosk sharedInstance];
    [kiosk startup];

    [self verifyThemeAssets];
    [self verifyPhotoStore];
    
    // Sense the user.
    idleTimerInvocation = nil;
    idleTimerSelector = @selector(userDidLeave);
    if ([self respondsToSelector:idleTimerSelector]) {
        idleTimerMethodSig = [self methodSignatureForSelector:idleTimerSelector];
        if (idleTimerMethodSig != nil) {
            idleTimerInvocation = [NSInvocation invocationWithMethodSignature:idleTimerMethodSig];
            [idleTimerInvocation setTarget:self];
            [idleTimerInvocation setSelector:idleTimerSelector];
        }
    }

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    DDLogVerbose(@"%s", __FUNCTION__);
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    DDLogVerbose(@"%s", __FUNCTION__);
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [kiosk pause];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    DDLogVerbose(@"%s", __FUNCTION__);
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [kiosk resume];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    DDLogVerbose(@"applicationDidBecomeActive");
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    DDLogVerbose(@"%s", __FUNCTION__);
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // NSUserDefaultsDidChangeNotification

    // Save changes if there are any.
    [[AMStorageManager sharedInstance] saveCoreData:nil];
}

- (void) appSettingsDidChange:(NSNotification*)notification
{
    DDLogVerbose(@"App settings changed.");
    if (!kiosk) {
        kiosk = [AMPrintKiosk sharedInstance];
    }
    
    [kiosk loadPersistentSettings];
}

//
// Feel for touches to keep track of idle time.
//
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self resetIdleTimer];
}

//
// Send a notification when the user idle time reaches the kiosk maximum.  Apply
// it for the Camera as well, for the case of an installation that leaves the
// capture mode running.
//
- (void)resetIdleTimer {
    DDLogVerbose(@"%s", __FUNCTION__);

    if (idleTimer) {
        // Simply wind the timer ahead again, we've felt a touch.
        [idleTimer invalidate];
    }

    if (idleTimerInvocation && kiosk && kiosk.idleFeelingTimeoutMins != 0) {
        idleTimer = [NSTimer scheduledTimerWithTimeInterval:kiosk.idleFeelingTimeoutMins * 60
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
            DDLogVerbose(@"Application is authenticated to cloud.");

            // Online!  Is there anything we can do immediately with our new
            // connection?

            // Ensure we have all of the data we need.
            [self loadKioskEntity];

//            // Update the kiosk.entity with our new session uuid
//            AMCloudClient *cloud = [AMCloudClient instance];
//            if (!(cloud.sessionUuid == (id)[NSNull null] || cloud.sessionUuid.length == 0)) {
//                [kiosk.entity setCloudSessionKey:cloud.sessionUuid];
//            }
//
//            // Save the entity.
//            NSError *error = nil;
//            if (![managedObjectContext save:&error]) {
//                // TODO Handle the error.
//                DDLogVerbose(@"Error saving kiosk: %@", [error localizedDescription]);
//            } else {
//                DDLogVerbose(@"Saved session key.");
//            }

        } else {
            DDLogVerbose(@"Application authentication is required.");
        }
    }
}

- (void)loadKioskEntity {
    DDLogVerbose(@"Loading Kiosk from CoreData");

    AMStorageManager *store = [AMStorageManager sharedInstance];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Kiosk"
                                              inManagedObjectContext:store.currentMOC];
    [request setEntity:entity];

//    NSString *productId = kiosk.productCode;
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"productId == %@",
//                    productId];
//    [request setPredicate:predicate];
    NSError *error;
    NSArray *array = [store.currentMOC executeFetchRequest:request error:&error];
    if ([array count] > 0) {
        kiosk.entity = array[0];
    }
}

//
//  Ensure the customizable asset files are in place, and if not copy the default
//  equivalents from the dist resource bundle.
//
- (void)verifyThemeAssets {
    NSString *storePath = [AMUtility applicationDocumentsDirectory];
    NSArray *assetFileNames = [NSArray arrayWithObjects:@"header.png", @"header_print_select.png", kAMImageFileNameNothingToPrint, nil];
    NSString *defaultAssetPath = nil;
    NSString *assetPath = nil;
    NSString *bundlePath = [[NSBundle mainBundle] resourcePath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    for (id assetFileName in assetFileNames) {
        assetPath = [storePath stringByAppendingPathComponent:assetFileName];
        if (![fileManager fileExistsAtPath:assetPath]) {
            defaultAssetPath = [bundlePath stringByAppendingPathComponent:assetFileName];
            
            if (defaultAssetPath && [fileManager fileExistsAtPath:defaultAssetPath]) {
                DDLogVerbose(@"Copying default theme asset %@ in place.", assetFileName);
                NSError *error = nil;
                [fileManager copyItemAtPath:defaultAssetPath toPath:assetPath error:&error];
                if (error) {
                    DDLogVerbose(@"Error %@ copying asset %@", error, assetFileName);
                }
            }
        }
    }
}

- (void)verifyPhotoStore {
    NSString *photoStore = kiosk.photoStoreDirectory;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:photoStore]) {
        [fileManager createDirectoryAtPath:photoStore
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];
    }
    
}

//
//  We've sensed the user has left, announce this.
//
- (void)userDidLeave {
    DDLogVerbose(@"%s", __FUNCTION__);
    
    if (kiosk) {
        kiosk.userIsPresent = NO;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:AMUserDidLeave object:self];
}

- (void) didSenseUser:(NSNotification*)notification {
    kiosk.userIsPresent = YES;
    [self resetIdleTimer];
}


//
//  Receive an NSError from an arbitrary thread (via notification.object).
//
- (void)receivePresentError:(NSNotification*)notification {
    if (notification.object && [notification.object isKindOfClass:[NSError class]]) {
        [self performSelectorOnMainThread:@selector(presentError:)
                               withObject:notification.object waitUntilDone:NO];
    }
}

//
//  Thread safe call to show an error via TSMessages.
//
- (void)presentError:(NSError *)error {
    if ([NSThread isMainThread]) {
        DDLogError(@"Error: (code %ld) %@ %@ %@",
                   (long)[error code],
                   [error localizedDescription],
                   [error localizedFailureReason],
                   [error userInfo]);
        DDLogVerbose(@"Stack: %@",[NSThread callStackSymbols]);
        
        @try {
            UIViewController *vc = [AMUtility currentViewController];
            if (vc) {
                NSTimeInterval duration = 100; //kAMErrorDisplayDurationSecs;
                NSString *title = error.localizedDescription;
                NSString *subtitle = error.localizedRecoverySuggestion;
                
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
                
            } else {
                [self showError:error];
            }
        }
        @catch (NSException *exception) {
            // Fall back to simpler ..
            [self showError:error];
        }
    } else {
        [self performSelectorOnMainThread:@selector(presentError:)
                               withObject:error waitUntilDone:NO];
    }
}

//
//  Unsafe UIAlert to trivially show a message.
//
- (void)showAlert:(NSDictionary *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:message[@"title"]
                                                    message:message[@"body"]
                                                   delegate:nil
                                          cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

//
//  Unsafe UIAlert to trivially show an error.
//
- (void)showError:(NSError *)error {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:error.domain
                                                    message:error.localizedRecoverySuggestion
                                                   delegate:nil
                                          cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}


@end
