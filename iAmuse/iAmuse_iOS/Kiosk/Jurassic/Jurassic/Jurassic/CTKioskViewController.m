//
//  CTKioskViewController.m
//  Jurassic
//
//  Used by the camera as it's interim controller when it's not busy capturing and processing video.
//
//  Created by Roland Hordos on 2013-05-25.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import "CTKioskViewController.h"
#import "AMConstants.h"
#import "ViewController.h"
#import "WebCommunication.h"
#import "MBProgressHUD.h"
#import "ScreenShotViewController.h"
#import "ABPadLockScreenViewController.h"
#import "AMUtility.h"
#import "EventListViewController.h"
#import "CTAppDelegate.h"
#import "AMThanksViewController.h"
#import "BackgroundImageViewController.h"

#define kUserId @"userId"

@interface CTKioskViewController ()
{
    NSArray *gestures;
    ABPadLockScreenViewController *lockScreen;
    ScreenShotViewController * screenShotView;
    ViewController * cameraView;
    
}

@end


@implementation CTKioskViewController
  extern NSString *picComplete;
- (id)init
{
    NSLog(@"%s", __FUNCTION__);
    self = [super init];
    if (self)
    {
        
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"%s", __FUNCTION__);

    if(thankYouCountdownTimer)
    {
        [thankYouCountdownTimer invalidate];
        thankYouCountdownTimer = nil;
    }
}

- (void)viewDidLoad
{
    NSLog(@"%s", __FUNCTION__);
    [super viewDidLoad];
    
    
    [NSTimer scheduledTimerWithTimeInterval:10.0
                                     target:self
                                   selector:@selector(subscriptionUpdate:)
                                   userInfo:nil
                                    repeats:YES];
   
    
    
   
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hello:)
                                                 name:@"testing"
                                               object:nil];
    
    
    
    [[AMStorageManager sharedInstance] init];
    
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewsSwipe:)];
    swipeUp.numberOfTouchesRequired = 2;
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    swipeUp.delaysTouchesBegan = YES;
    [self.view addGestureRecognizer:swipeUp];
    
    
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewsSwipe:)];
    swipeDown.numberOfTouchesRequired = 2;
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    swipeDown.delaysTouchesBegan = YES;
    [self.view addGestureRecognizer:swipeDown];
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewsSwipe:)];
    swipeRight.numberOfTouchesRequired = 2;
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    swipeRight.delaysTouchesBegan = YES;
    [self.view addGestureRecognizer:swipeRight];
    
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewsSwipe:)];
    swipeLeft.numberOfTouchesRequired = 2;
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    swipeLeft.delaysTouchesBegan = YES;
    [self.view addGestureRecognizer:swipeLeft];
    
    //showSettingScreen1 in placeof to hide lock screen handleViewsSwipe
    
    
    
    UISwipeGestureRecognizer *swipeUpa = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewsSwipe:)];
    swipeUpa.numberOfTouchesRequired = 3;
    swipeUpa.direction = UISwipeGestureRecognizerDirectionUp;
    swipeUpa.delaysTouchesBegan = YES;
    [self.view addGestureRecognizer:swipeUpa];
    
    
    UISwipeGestureRecognizer *swipeDowna = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewsSwipe:)];
    swipeDowna.numberOfTouchesRequired = 3;
    swipeDowna.direction = UISwipeGestureRecognizerDirectionDown;
    swipeDowna.delaysTouchesBegan = YES;
    [self.view addGestureRecognizer:swipeDowna];
    
    UISwipeGestureRecognizer *swipeRighta = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewsSwipe:)];
    swipeRighta.numberOfTouchesRequired = 3;
    swipeRighta.direction = UISwipeGestureRecognizerDirectionRight;
    swipeRighta.delaysTouchesBegan = YES;
    [self.view addGestureRecognizer:swipeRighta];
    
    UISwipeGestureRecognizer *swipeLefta = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewsSwipe:)];
    swipeLefta.numberOfTouchesRequired = 3;
    swipeLefta.direction = UISwipeGestureRecognizerDirectionLeft;
    swipeLefta.delaysTouchesBegan = YES;
    [self.view addGestureRecognizer:swipeLefta];


    cameraVC = nil;
    
    
    
    
    
    
    
    
    
       
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(showSplash:)
//                                                 name:@"ShowSplash"
//                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showSettingScreen:)
                                                 name:@"OpenSettingSceneNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showSettingScreen:)
                                                 name:@"showSettingScreen"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lockCancel:)
                                                 name:@"lockCancel"
                                               object:nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(updateEventNotification:)
//                                                 name:AMEventConfigurationUpdateNotification
//                                               object:nil];
    
    

    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                selector:@selector(deviceOrientationDidChange:)
                                    name:UIDeviceOrientationDidChangeNotification
                                  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                    selector:@selector(loadConfigurationFromServerNotification:)
                        name:AMGetRGBConfigurationNotification
                      object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                        selector:@selector(sendNewScreenShotImageNotification:)
                            name:AMSendScreenShotServerNotification
                          object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                    selector:@selector(receivedStopPhotoSession)
//                                        name:@"removeLookAtiPadNotification"
//                                      object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backToEventScene:)
                                                 name:AMBackToEventNotification
                                               object:nil];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backToThankYou:)
                                                 name:@"gotoThankYou"
                                               object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(subscriptionUpdate:)
                                                 name:@"subscriptionUpdate"
                                               object:nil];

    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ajay:)
                                                 name:@"touchiPad"
                                               object:nil];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateFOVNotification:)
                                                 name:@"FOV_UPDATED"
                                               object:nil];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hideLookatiPad)
                                                 name:@"PicturesComplete"
                                               object:nil];
    

}

- (void)updateFOVNotification:(NSNotification *)notification
{
    //[self getFOV];
}


-(void)hello:(NSNotification *)notification
{
    
    NSLog(@"raina");
    
}


- (void)getFOV
{
    WebCommunication *webComm = [[WebCommunication alloc] initWithServiceType:1];
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"userId"] forKey:@"userId"];
    NSURL *serviceUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/getFov",kAMBaseURL]];
    
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
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject: [NSNumber numberWithInt:[[response valueForKey:@"left"] intValue]] forKey: FOV_CURTAIN_KEY_LEFT];
                [defaults setObject: [NSNumber numberWithInt:[[response valueForKey:@"right"] intValue]] forKey: FOV_CURTAIN_KEY_RIGHT];
                [defaults setObject: [NSNumber numberWithInt:[[response valueForKey:@"top"] intValue]] forKey: FOV_CURTAIN_KEY_TOP];
                [defaults setObject: [NSNumber numberWithInt:[[response valueForKey:@"bottom"] intValue]] forKey: FOV_CURTAIN_KEY_BOTTOM];
                [defaults synchronize];
            }
        }
    }];
}



- (void)updateEventNotification:(NSNotification *)notification
{
    if (![[NSThread currentThread] isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}


- (void)backToEventScene:(NSNotification *)notification {
    if (![[NSThread currentThread] isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.navigationController popViewControllerAnimated:YES];
//                    CTAppDelegate *delegate = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
//                    [delegate setInitialViewCtr];
            
            

//            UIStoryboard *storyboard;
//            storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
//            AMThanksViewController *eventController = [storyboard instantiateViewControllerWithIdentifier:@"thanksVC"];
//            [self.navigationController pushViewController:eventController animated:YES];

            
            
            
            [self performSelector:@selector(receivedStopPhotoSession) withObject:nil afterDelay:0];
            
        });
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
                CTAppDelegate *delegate = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
                [delegate setInitialViewCtr];
    }
}





- (void)backToThankYou:(NSNotification *)notification {
    if (![[NSThread currentThread] isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            //            [self.navigationController popViewControllerAnimated:YES];
            //                    CTAppDelegate *delegate = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
            //                    [delegate setInitialViewCtr];
            
            
            
            UIStoryboard *storyboard;
            storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
            AMThanksViewController *eventController = [storyboard instantiateViewControllerWithIdentifier:@"thanksVC"];
            [self.navigationController pushViewController:eventController animated:YES];
            
            
            
            
            //         [self performSelector:@selector(receivedStopPhotoSession) withObject:nil afterDelay:0];
            
        });
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
        CTAppDelegate *delegate = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
        [delegate setInitialViewCtr];
    }
}







- (void)ajay:(NSNotification *)notification {
    
    NSLog(@"raina");
    
    
//    UIStoryboard *storyboard;
//    storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
//    AMThanksViewController *eventController = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([AMThanksViewController class])];
//    [self.navigationController pushViewController:eventController animated:YES];
//
//
//
    
    
    
    
    
   
    
    
    [self performSelector:@selector(receivedStopPhotoSession) withObject:nil afterDelay:0];
    
    
}




- (void)handleViewsSwipe:(UISwipeGestureRecognizer *)recognizer
{
    
    NSUInteger touches = recognizer.numberOfTouches;
    if (touches == 3)
    {
        NSLog(@"happy");
    //    [self authorizePrint];



//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(theNameIsRaj:)
//                                                     name:@"settingsButton"
//                                                   object:nil];
//
//
//        lockScreen = [[ABPadLockScreenViewController alloc] initWithDelegate:nil complexPin:NO];
//        // lockScreen.showSetting = YES;
//
//
//        lockScreen.modalPresentationStyle = UIModalPresentationFullScreen;
//        [lockScreen cancelButtonDisabled:NO];
//        lockScreen.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
//
//        [self presentViewController:lockScreen animated:YES completion:nil];
//





    }
    
    else if (touches==2)
    {
        
        [[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(showSettingScreen1:)
    name:@"showEvent"
    object:nil];


        lockScreen = [[ABPadLockScreenViewController alloc] initWithDelegate:nil complexPin:NO];
       // lockScreen.showSetting = YES;


        lockScreen.modalPresentationStyle = UIModalPresentationFullScreen;
        [lockScreen cancelButtonDisabled:NO];
        lockScreen.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;

        [self presentViewController:lockScreen animated:YES completion:nil];
        

        
        
//        NSLog(@"hello");
//        UIViewController *viewController;
//        viewController = [self .storyboard instantiateViewControllerWithIdentifier:@"EventListViewController"];
//        [self.navigationController pushViewController:viewController animated:YES];
    }
    
    
}


- (void)showSettingScreen1:(NSNotification *)notification
{
    
    

    
    [lockScreen dismissViewControllerAnimated:NO completion:nil];

//    UIViewController *viewController;
//    viewController = [self .storyboard instantiateViewControllerWithIdentifier:@"EventListViewController"];
//    [self.navigationController pushViewController:viewController animated:YES];
    
    
    NSArray *viewControllers = self.navigationController.viewControllers;
    
    
    
    
    
    NSLog(@"arrayWithoutDuplicates values is %@",viewControllers);
    for (UIViewController *anVC in viewControllers) {
        if ([anVC isKindOfClass:[EventListViewController class] ]){
            [self.navigationController popToViewController:anVC animated:NO];
            break;
        }
    }
    
    
    

    //  [self performSegueWithIdentifier:@"settings" sender:self];
  //  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"OpenSettingSceneNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"showEvent" object:nil];
  //  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"lockCancel" object:nil];

}

- (void)authorizePrint {
    
    
//
//    EventListViewController *move = [self.storyboard instantiateViewControllerWithIdentifier:@"EventListViewController"];
//    [self presentViewController:move animated:YES completion:nil];


   
    lockScreen = [[ABPadLockScreenViewController alloc] initWithDelegate:nil complexPin:NO];
    lockScreen.showSetting = YES;


    lockScreen.modalPresentationStyle = UIModalPresentationFullScreen;
    [lockScreen cancelButtonDisabled:NO];
    lockScreen.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    
    
//    if (([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) && (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone))
//    {
//        [lockScreen.view setFrame:CGRectMake(0, 0, 100, 100)];
//    }
    
    [self presentViewController:lockScreen animated:YES completion:nil];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Disable sleep mode if the camera is plugged into power.
    // TODO - may need to enable this logic for App Store acceptance.
    if ([UIDevice currentDevice].batteryState == UIDeviceBatteryStateUnplugged)
    {
        NSLog(@"Device is on battery");
//        [UIApplication sharedApplication].idleTimerDisabled = NO;
    }
    else
    {
        NSLog(@"Device is plugged into power");
    }
    NSLog(@"Disabling automatic sleep");
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    NSLog(@"%s", __FUNCTION__);
    
    NSLog(@"memory leaks here");
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    cameraView = nil;
    cameraVC = nil;
    
    NSLog(@"%s", __FUNCTION__);
    
    if(![[NSUserDefaults standardUserDefaults] boolForKey:HAVE_SERVER_RGB_CONFIGURATION] || [[NSUserDefaults standardUserDefaults] boolForKey:PENDING_CONFIGUARTION_REQUEST])
    {
        //[self loadConfigurationFromServer];
        haveToLoadRGBFromServer = YES;
    }
    if([[NSUserDefaults standardUserDefaults] boolForKey:PENDING_SCREENSHOT_REQUEST])
    {
        double delayInSeconds = 0.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self goToScreenShotView];
        });
    }
    showing = YES;
//    [self updateOrientation];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                            selector:@selector(AllImagesClickedNotification)
                                name:@"AllImagesClickedNotification"
                              object:nil];
    
    
   
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedStopPhotoSession)
                                                 name:@"removeLookAtiPadNotification"
                                               object:nil];
    
    
}

- (void)AllImagesClickedNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AllImagesClickedNotification" object:nil];
    
    viewAbovefaddedView.hidden = NO;
    viewAbovefaddedView.userInteractionEnabled = YES;
    [self.view bringSubviewToFront:viewAbovefaddedView];
    viewAbovefaddedView.alpha = 0.01f;
    
//    [UIView animateWithDuration:8.0
//                     animations:^{
//                         faddedView.alpha = 0.0f;}
//                     completion:^(BOOL finished){
//                     viewAbovefaddedView.hidden = YES;
//                     }];
    
    [UIView animateWithDuration:1.0
                     animations:^{
                         viewAbovefaddedView.alpha = 1.0f;}
                     completion:^(BOOL finished){ }];
    
    if (screenShotView)
    {
        [screenShotView dismissViewControllerAnimated:NO completion:nil];
        screenShotView = nil;
    }
    
  //  [self performSelector:@selector(receivedStopPhotoSession) withObject:nil afterDelay:10];
}



- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch * touch = [[event allTouches] anyObject];
    
    if ([[touch.view class] isSubclassOfClass:[UIView class]])
    {
        UIView * blackView = (UIView *)touch.view;
        if ([blackView isEqual:viewAbovefaddedView])
        {
//            viewAbovefaddedView.hidden = YES;
        }
    }
}

- (void)loadConfigurationFromServer
{
    MBProgressHUD * hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
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
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
    [dict setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"userId"] forKey:@"userId"];
    WebCommunication * webComm = [WebCommunication new];
    [webComm callToServerRequestDictionary:dict onURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kAMBaseURL,kAMGetConfigurationURL]] WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm)
     {
         NSLog(@"response : %@",response);
         if(!error)
         {
            if([[response objectForKey:@"responseDescription"] isEqualToString:@"Success"])
            {
                if([response objectForKey:@"rgbValue"])
                {
                    self.colorRGBInfo = [[response objectForKey:@"rgbValue"] componentsSeparatedByString:@","];
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:HAVE_SERVER_RGB_CONFIGURATION];
                    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:PENDING_CONFIGUARTION_REQUEST];
                    [[NSUserDefaults standardUserDefaults] setObject:self.colorRGBInfo forKey:SERVER_RGB_CONFIGURATION];
                    [[NSUserDefaults standardUserDefaults]synchronize];
                }
            }
            [self performSelector:@selector(hideHUD) withObject:nil afterDelay:4.0];
         }
         else
         {
            [self performSelector:@selector(hideHUD) withObject:nil afterDelay:4.0];
         }
         
     }];
}

- (void)hideHUD
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)goToScreenShotView
{
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:[NSBundle mainBundle]];
    screenShotView = [storyboard instantiateViewControllerWithIdentifier:@"ScreenShot_iPhone"];
    
    [self presentViewController:screenShotView animated:YES completion:nil];
}

// to hide look at ipad image on iphone/camera device
- (void)receivedStopPhotoSession
{
    if (!viewAbovefaddedView.hidden)
    {
      //  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"removeLookAtiPadNotification" object:nil];
//        CTAppDelegate *appDel = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
//
//        NSUserDefaults * naming = [NSUserDefaults standardUserDefaults];
//        NSString * result = [naming stringForKey:@"PicComplete"];
//
//        if([result isEqualToString:@"correct"])
//
//
//        {
//            NSString *anotherValue = @"incorrect";
//            [naming setObject: anotherValue forKey:@"PicComplete"];
//            [naming synchronize];
        
        [self performSelectorOnMainThread:@selector(hideLookatiPad) withObject:nil waitUntilDone:NO];
            //picComplete=@"incorrect";
    }
    }
//}

- (void)hideLookatiPad
{
    
   // [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PicturesComplete" object:nil];

    viewAbovefaddedView.hidden = YES;
    
    if (screenShotView)
    {
        [screenShotView dismissViewControllerAnimated:NO completion:nil];
        screenShotView = nil;
    }
    
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:@"removeLookAtiPadNotification" object:nil];
    if (haveToLoadRGBFromServer)
    {
        [self loadConfigurationFromServer];
        haveToLoadRGBFromServer = NO;
    }
    }

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    NSLog(@"%s", __FUNCTION__);
    showing = NO;
}

- (void)viewWillLayoutSubviews
{
    /*
     Be careful, this is called a lot including when the view is on it's way out!
     */
    NSLog(@"%s", __FUNCTION__);

    CGRect targetBounds = self.view.bounds;
    if (!introTouchLayer)
    {
        introTouchLayer = [[UIImageView alloc] initWithFrame:targetBounds];
//        introTouchLayer.contentMode = UIViewContentModeScaleToFill;
        CTKiosk * kiosk = [CTKiosk sharedInstance];
        NSString * assetPath = [kiosk.storePath stringByAppendingPathComponent:[NSString stringWithFormat:@"Events/%@/camera",kiosk.eventId]];
        NSString * loacalassetPath = [kiosk.storePath stringByAppendingPathComponent:@"nothing_to_print.png"];
        UIImage *image = [UIImage imageWithContentsOfFile:assetPath];
        if (image) {
            introTouchLayer.image = image;
        }
        else
        {
            introTouchLayer.image = [UIImage imageWithContentsOfFile:loacalassetPath];
        }
        introTouchLayer.alpha = 1.0f;
        introTouchLayer.contentMode = UIViewContentModeScaleAspectFill;
        [self.view addSubview:introTouchLayer];
        NSString * thankuassetPath = [kiosk.storePath stringByAppendingPathComponent:[NSString stringWithFormat:@"Events/%@/lookat",kiosk.eventId]];
        backgroundImage.image = [UIImage imageWithContentsOfFile:thankuassetPath];
        // A single tap allows a test mode jump to the Camera vc.
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(splashScreenTap:)];
        tap.numberOfTapsRequired = 1;
        tap.delegate = self;
        [introTouchLayer addGestureRecognizer:tap];

        // A double tap tests the thank you screen.
        UITapGestureRecognizer * doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(screenDoubleTap:)];
        doubleTap.numberOfTapsRequired = 2;
        doubleTap.delegate = self;
        [introTouchLayer addGestureRecognizer:doubleTap];

        // Single must yield temporarily to allow double test.
        [tap requireGestureRecognizerToFail:doubleTap];

        UIView * dummyView = [[UIView alloc] initWithFrame:targetBounds];
        [dummyView addGestureRecognizer:tap];
        [dummyView addGestureRecognizer:doubleTap];
        [self.view addSubview:dummyView];

        [self.view addSubview:settingsGear];
        [self.view bringSubviewToFront:settingsGear];
        settingsGear.layer.zPosition = MAXFLOAT;
        
        
        [self.view addSubview:self.clearButton];
        [self.view bringSubviewToFront:self.clearButton];
        self.clearButton.layer.zPosition = MAXFLOAT;

        
    }

    if (showing)
    {
        [introTouchLayer setFrame: targetBounds];
    }
    UITextField * textfield = [[UITextField alloc] initWithFrame:CGRectMake(10, 10, 200, 40)];
    textfield.delegate = self;
    textfield.backgroundColor = [UIColor whiteColor];
    textfield.font = [UIFont systemFontOfSize:16.0f];
    textfield.textColor = [UIColor blackColor];
    //[self.view addSubview:textfield];
    //[self.view bringSubviewToFront:textfield];
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSLog(@"%@", textField.text);
    textFieldValue = [textField.text floatValue];
    [textField resignFirstResponder];
    return YES;
}

/**
* Notification selector.  Note that this is often called with "Unknown" orientation.
*/
- (void)deviceOrientationDidChange:(NSNotification *)notification
{
    if (UIDeviceOrientationIsPortrait([[UIDevice currentDevice] orientation]))
    {
        [self.settingButton setImage:[UIImage imageNamed:@"Gear.png"] forState:UIControlStateNormal];
    }
    else
    {
        [self.settingButton setImage:nil forState:UIControlStateNormal];
    }
    
    
//    NSLog(@"%s", __FUNCTION__);
//    UIView *logView = self.view;
//    NSLog(@"Our view %s: x, y, height, width: %f, %f, %f, %f",
//            [NSStringFromClass([logView class]) UTF8String],
//            logView.bounds.origin.x, logView.bounds.origin.y,
//            logView.bounds.size.height, logView.bounds.size.width);
//
//    logView = [UIApplication sharedApplication].keyWindow.rootViewController.view;
//    NSLog(@"Our view %s: x, y, height, width: %f, %f, %f, %f",
//            [NSStringFromClass([logView class]) UTF8String],
//            logView.bounds.origin.x, logView.bounds.origin.y,
//            logView.bounds.size.height, logView.bounds.size.width);
//
//    CGPoint relativeOrigin = [self.view convertPoint:self.view.bounds.origin toView:[UIApplication sharedApplication].keyWindow.rootViewController.view];
//    NSLog(@"Origin relative to root view controller: x%f, y%f", relativeOrigin.x, relativeOrigin.y);
//
//    NSLog(@"Interface Orientation: %d", [self interfaceOrientation]);
//    NSLog(@"Device Orientation: %d", [[UIDevice currentDevice] orientation]);

    UIDeviceOrientation newDeviceOrientation = [[UIDevice currentDevice] orientation];

    // We only need to handle landscape and portrait.
    if (newDeviceOrientation == UIDeviceOrientationFaceUp ||
            newDeviceOrientation == UIDeviceOrientationFaceDown ||
            newDeviceOrientation == UIDeviceOrientationUnknown ||
            newDeviceOrientation == deviceOrientation)
    {
        return;
    }

    // Update the state variable, an optimization to avoid thrashing.
    deviceOrientation = newDeviceOrientation;
    
    


    // Optionally delay the reacting calls.
//    [self performSelector:@selector(updateOrientation) withObject:nil afterDelay:0];
}

/**
* This is necessary as we find that the device event is not always reliably there when we need it, so we have a way to
* directly verify orientation of our views and data for a given device orientation.
*
* 2013-07-18 - no longer needed after removal of should..orient and supported orientations code.
*/
//- (void)updateOrientation {
//    NSLog(@"TEMP DEBUG %s", __FUNCTION__);
//    if (self.view.window && showing) { // we are visible
//        UIView *targetView = self.view;
//        CGAffineTransform currentTransform = targetView.transform;
////        CGAffineTransform currentTransform = introOverlayLayer.transform;
////        NSLog(@"Incoming view is transformed as: a:%f b:%f c:%f d:%f tx:%f ty:%f",
////            currentTransform.a, currentTransform.b, currentTransform.c, currentTransform.d,
////            currentTransform.tx, currentTransform.ty);
//
//        deviceOrientation = [[UIDevice currentDevice] orientation];
//        interfaceOrientation = [self interfaceOrientation];
//
//        // Does the device orientation match the interface?  If not then adjust.
//        switch (deviceOrientation) {
//            case UIDeviceOrientationLandscapeLeft:
//                NSLog(@"Device orientation: Landscape Left (home button right)");
//                switch (interfaceOrientation) {
//                    case UIInterfaceOrientationLandscapeLeft:
//                        NSLog(@"Orientations match.");
//                        if (currentTransform.b >= 0 && currentTransform.c < 0) {
//                            NSLog(@"Transformed correctly to LL");
//                        } else {
//                            NSLog(@"Transformed incorrectly to LL, rotate 180");
//                            targetView.transform = CGAffineTransformRotate(targetView.transform, M_PI );
//                        }
//                        break;
//                    case UIInterfaceOrientationLandscapeRight:
//                        NSLog(@"Orientation mis-match.");
//                        if (currentTransform.b >= 0 && currentTransform.c < 0) {
//                            NSLog(@"Transformed correctly to LL");
//                        } else {
//                            NSLog(@"Currently transformed down");
////                            targetView.transform = CGAffineTransformMakeRotation( M_PI );
//                            targetView.transform = CGAffineTransformRotate(targetView.transform, M_PI );
//                        }
//                        break;
//                    case UIInterfaceOrientationPortrait:break;
//                    case UIInterfaceOrientationPortraitUpsideDown:break;
//                    default:
//                        NSLog(@"Unhandled orientation scenario, device:%d, interface:%d", deviceOrientation, interfaceOrientation);
//                }
//                break;
//            case UIDeviceOrientationPortrait:
//                NSLog(@"Device orientation: Portrait");
//                break;
//            case UIDeviceOrientationLandscapeRight:
//                NSLog(@"Device orientation: Landscape Right (home button left)");
//                switch (interfaceOrientation) {
//                    case UIInterfaceOrientationLandscapeLeft:
//                        NSLog(@"Orientation mis-match.");
//                        if (currentTransform.b >= 0 && currentTransform.c < 0) {
//                            NSLog(@"Transformed incorrectly to LL, rotate 180");
//                            targetView.transform = CGAffineTransformRotate(targetView.transform, M_PI );
//                        } else {
//                            NSLog(@"Transformed correctly to LR");
//                        }
//                        break;
//                    case UIInterfaceOrientationLandscapeRight:
//                        NSLog(@"Orientations match.");
//                        if (currentTransform.b >= 0 && currentTransform.c < 0) {
//                            NSLog(@"Transformed incorrectly to LL, rotate 180");
//                            targetView.transform = CGAffineTransformRotate(targetView.transform, M_PI );
//                        } else {
//                            NSLog(@"Transformed correctly to LR");
//                        }
//                        break;
//                    case UIInterfaceOrientationPortrait:break;
//                    case UIInterfaceOrientationPortraitUpsideDown:break;
//                    default:
//                        NSLog(@"Unhandled orientation scenario, device:%d, interface:%d", deviceOrientation, interfaceOrientation);
//                }
//                break;
//            case UIDeviceOrientationPortraitUpsideDown:
//                NSLog(@"Device orientation: Portrait Upside Down");
//                break;
//            default:
//                NSLog(@"Device orientation: %d", deviceOrientation);
//                break;
//        }
//
//        currentTransform = self.view.transform;
////        currentTransform = introOverlayLayer.transform;
////        NSLog(@"Outgoing view is transformed as: a:%f b:%f c:%f d:%f tx:%f ty:%f",
////                currentTransform.a, currentTransform.b, currentTransform.c, currentTransform.d,
////                currentTransform.tx, currentTransform.ty);
//    }
//}

- (void)splashScreenTap:(UITapGestureRecognizer *)gesture
{
//    
//
//    
//    
////    [self goToScreenShotView];
//    
//    
//    CGPoint p = [gesture locationInView:self.view];
//    if ((p.x >= self.settingButton.frame.origin.x) && (p.x <= self.settingButton.frame.origin.x + self.settingButton.frame.size.width) && (p.y >= self.settingButton.frame.origin.y) && (p.y <= self.settingButton.frame.origin.y + self.settingButton.frame.size.height))
//    {
//        
//        
//        EventListViewController *move = [self.storyboard instantiateViewControllerWithIdentifier:@"EventListViewController"];
//        
//        [self presentViewController:move animated:YES completion:nil];
//        
//        
//        [self performSegueWithIdentifier:@"showSetting" sender:self];
//        return;
//    }
//    
//    
//    // The splash screen has been touched.  Transition to the Photo Session use
//    // case and stop the splash.
//    _isTestingCamera = YES;
//    [self showCamera];
//    // Stopped using seque as it always created a new vc instance, likely due
//    // to the unusual view swapping we do with the Open GL texture filtering.
//    //[self performSegueWithIdentifier:@"CameraView" sender:nil];
}

- (void)screenDoubleTap:(UITapGestureRecognizer *)gesture
{
    NSLog(@"%s", __FUNCTION__);

   // [self showThankYou];
}

- (IBAction)clearPhotos:(id)sender
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

- (IBAction)showSettings:(id)sender {
    
    [self performSegueWithIdentifier:@"showSetting" sender:self];
}

- (void)thankYouCountdownTimerTick
{
    thankYouCountdownSequence --;

    // Depending on the sequence, display something different.
    switch (thankYouCountdownSequence)
    {
        case 0:
            // end of the countdown, kill the timer
            [thankYouCountdownTimer invalidate];
            thankYouCountdownTimer = nil;
            [self hideThankYou];
            break;
        default:
            break;
    }
}

//  Display a large Thank You label for a period.
- (void)showThankYou
{
    viewAbovefaddedView.hidden = YES;

    // Initialize rotated label to use for countdown.
    if (!lblThankYou)
    {
        lblThankYou = [[UILabel alloc] initWithFrame:self.view.bounds];
        lblThankYou.numberOfLines = 1;
        lblThankYou.text = @"Thank You";
        lblThankYou.textColor = [UIColor blackColor];
        lblThankYou.textAlignment = NSTextAlignmentCenter;
        lblThankYou.font = [UIFont systemFontOfSize:80];
        lblThankYou.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;

        [self.view addSubview:lblThankYou];
    }
    lblThankYou.backgroundColor = [UIColor whiteColor];
    lblThankYou.alpha = 1.0;

    // Setup a countdown timer to shut us off.
    thankYouCountdownSequence = kAMCameraThankYouDurationSecs;
    thankYouCountdownInterval = 1;

    // Reset it if it's already counting down.
    if (thankYouCountdownTimer)
    {
        [thankYouCountdownTimer invalidate];
        thankYouCountdownTimer = nil;
    }

    thankYouCountdownTimerSelector = @selector(thankYouCountdownTimerTick);
    if ([self respondsToSelector:thankYouCountdownTimerSelector])
    {
        thankYouCountdownTimerMethodSig = [self methodSignatureForSelector:thankYouCountdownTimerSelector];
        if (thankYouCountdownTimerMethodSig != nil)
        {
            thankYouCountdownTimerInvocation = [NSInvocation invocationWithMethodSignature:thankYouCountdownTimerMethodSig];
            [thankYouCountdownTimerInvocation setTarget:self];
            [thankYouCountdownTimerInvocation setSelector:thankYouCountdownTimerSelector];
            thankYouCountdownTimer = [NSTimer scheduledTimerWithTimeInterval:thankYouCountdownInterval invocation:thankYouCountdownTimerInvocation repeats:YES];
        }
    }
}

- (void)hideThankYou
{
    lblThankYou.backgroundColor = [UIColor clearColor];
    lblThankYou.alpha = 0.0;
    
    if (haveToLoadRGBFromServer)
    {
        [self loadConfigurationFromServer];
        haveToLoadRGBFromServer = NO;
    }
}

- (void)showCamera
{
    NSLog(@"%s", __FUNCTION__);
    
//    // Manually show the same vc each time.
//    if (!cameraVC) {
//        cameraVC = [[CTCameraViewController alloc] init];
//        cameraVC.delegate = self;
//    }
//    [self presentViewController:cameraVC animated:YES completion:nil];
    
    if (!viewAbovefaddedView.hidden)
    {
        viewAbovefaddedView.hidden = YES;
    }

    if (!cameraView)
    {
        UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:[NSBundle mainBundle]];
        cameraView = [storyboard instantiateViewControllerWithIdentifier:@"Camera_GPUImage"];
        
    }
    
    if (textFieldValue > 0.0)
    {
        cameraView.thresholdValue = textFieldValue;
    }
    else
    {
        cameraView.thresholdValue = 0.4f;
    }
    textFieldValue = 0.0f;
    [cameraView setIsTestingCamera:_isTestingCamera];
    [self presentViewController:cameraView animated:NO completion:nil];
}

- (void)showSplash:(NSNotification *)notification
{
    NSLog(@"%s", __FUNCTION__);
    // Put the Kiosk View Controller to the top.
    @try
    {
        [self performSegueWithIdentifier:@"splash" sender:nil];
    }
    @catch (NSException * e)
    {
        NSLog(@"Exception: %@", e);
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
//    if ([[segue identifier] isEqualToString:@"CameraView"])
//    {
//        CTCameraViewController *cameraViewController = [segue destinationViewController];
//        cameraViewController.
//        detailViewController.sighting = [self.dataController objectInListAtIndex:[self.tableView indexPathForSelectedRow].row];
//    }

//    if ([[segue identifier] isEqualToString:@"ShowAddSightingView"])
//    {
//        AddSightingViewController *addSightingViewController = [[[segue destinationViewController] viewControllers] objectAtIndex:0];
//        addSightingViewController.delegate = self;
//    }
}

- (void)cameraViewController:(CTCameraViewController *)cameraViewController didFinishSession:(CTPhotoSession *)session
{
    /*
     Delegate for modal view to tell presenting controller it's done, close me.
     */
    NSLog(@"%s", __FUNCTION__);

    [self dismissViewControllerAnimated:YES completion: nil];
}

- (void)settingsViewController:(CTSettingsViewController *)settingsViewController didFinishSettings:(NSUserDefaults *)settings
{
    /*
     Delegate for modal view to tell presenting controller it's done, close me.
     */
    NSLog(@"%s", __FUNCTION__);

    [self dismissViewControllerAnimated:YES completion: nil];
    
    CTKiosk * kiosk = [CTKiosk sharedInstance];
    [kiosk loadPersistentSettings:YES];
}

#pragma mark GLK Delegate

- (void)glkViewControllerUpdate:(GLKViewController *)controller
{
    
}

- (void)glkViewController:(GLKViewController *)controller willPause:(BOOL)pause
{
    NSLog(@"%s", __FUNCTION__);
}

#pragma mark - Gesture Delegate

//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
//       shouldReceiveTouch:(UITouch *)touch
//{
//    return YES;
//}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
        shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)sendNewScreenShotImageNotification:(NSNotification *)notification
{
    [self goToScreenShotView];
}
- (void)lockCancel:(NSNotification *)notification
{
    [lockScreen dismissViewControllerAnimated:NO completion:nil];
}

- (void)showSettingScreen:(NSNotification *)notification
{
    [lockScreen dismissViewControllerAnimated:NO completion:nil];

    [self performSegueWithIdentifier:@"showSetting" sender:self];
}

- (void)loadConfigurationFromServerNotification:(NSNotification *)notification
{
    if (viewAbovefaddedView.hidden)
    {
        [self loadConfigurationFromServer];
    }
    else
    {
        haveToLoadRGBFromServer = YES;
    }
}


//
//- (void)theNameIsRaj:(NSNotification *)notification
//{
//    [lockScreen dismissViewControllerAnimated:NO completion:nil];
//    NSLog(@"testing success");
//    
//    //[self performSegueWithIdentifier:@"settings" sender:self];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"OpenSettingSceneNotification" object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"showSettingScreen" object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"lockCancel" object:nil];
//    
//}




- (void)subscriptionUpdate:(NSNotification *)notification {
    
    
    NSLog(@"Notification received");
    
    
    NSLog(@"Notification received aaaaaa");
    
    
    
    
    WebCommunication *webComm = [[WebCommunication alloc] initWithServiceType:1];
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"userId"] forKey:@"userId"];
    NSURL *serviceUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/subscriptionsList",kAMBaseURL]];
    [webComm callToServerRequestDictionary:dic onURL:serviceUrl WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm) {
        //   [hud hide:YES];
        if (!error)
        {
            NSLog(@"%ld, %@",(long)status_code,response);
            
            
            
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
                        NSLog(@"subscription is %@",response[@"subId"]);
                        
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


