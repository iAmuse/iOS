//
//  InitialViewController.m
//  iAmuse
//
//  Created by apple on 27/12/16.
//  Copyright © 2016 iAmuse Inc. All rights reserved.
//

#import "InitialViewController.h"
#import "AMConstants.h"
#import "CTAppDelegate.h"
#import "BaseNavigationController.h"
#import "WebCommunication.h"
#import "MBProgressHUD.h"
#import "EventListViewController.h"
#import <AVFoundation/AVFoundation.h>



#import "CTKioskViewController.h"
#import "AMUtility.h"


#include <ifaddrs.h>
#include <arpa/inet.h>

#import <SystemConfiguration/CaptiveNetwork.h>
#import "AMStorageManager.h"


@interface InitialViewController ()
    
    @end

@implementation InitialViewController
    
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //    [[[UIAlertView alloc] initWithTitle:@"DeviceMode" message:@"Select device mode" delegate:self cancelButtonTitle:@"Camera" otherButtonTitles:@"Touch", nil] show];
    
    NSString *ipAdddddddd = [self getIPAddress];
    
}


- (NSString *)getIPAddress {
    
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
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

    
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
    {
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        if (buttonIndex == 0) {
            [defaults setObject:AMDeviceModeStrCamera forKey:AMDeviceModeSettingsKey];
        }
        else
        {
            [defaults setObject:AMDeviceModeStrTouchScreen forKey:AMDeviceModeSettingsKey];
        }
        [defaults synchronize];
        [self setRootViewController];
    }
    
//- (void)setRootViewController
//    {
//        UIStoryboard *storyboard;
//        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
//        NSString * deviceModePref = [defaults stringForKey:AMDeviceModeSettingsKey];
//        CTAppDelegate *delegate = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
//        // show the storyboard
//        UIViewController *rootViewController = [storyboard instantiateInitialViewController];
//        if (0)
//        {
//            delegate.window.rootViewController = rootViewController;
//        }
//        else
//        {
//            if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
//            {
//                //  if((UI_USER_INTERFACE_IDIOM()) == UIUserInterfaceIdiomPhone)
//
//                storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
//
//                if([[NSUserDefaults standardUserDefaults] boolForKey:@"isLogin"])
//                {
//                    rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"EventListViewController"];
//                }
//                else
//                {
//                    rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"SignInViewController"];
//                }
//                UINavigationController *navCont = [[UINavigationController alloc] initWithRootViewController:rootViewController];
//                delegate.window.rootViewController = navCont;
//
//            }
//            else
//            {
//                if((UI_USER_INTERFACE_IDIOM()) == UIUserInterfaceIdiomPhone)
//                {
//                    storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhoneTouch" bundle:nil];
//                }
//                else
//                {
//                    storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
//                }
//                rootViewController = [storyboard instantiateInitialViewController];
//
//                delegate.window.rootViewController = rootViewController;
//                // [self getSubscriptionDetail];
//            }
//        }
//    }



- (void)setRootViewController
{
    UIStoryboard *storyboard;
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * deviceModePref = [defaults stringForKey:AMDeviceModeSettingsKey];
    CTAppDelegate *delegate = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
    // show the storyboard
    UIViewController *rootViewController = [storyboard instantiateInitialViewController];
    if (0)
    {
        delegate.window.rootViewController = rootViewController;
    }
    else
    {
        if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
        {
            //  if((UI_USER_INTERFACE_IDIOM()) == UIUserInterfaceIdiomPhone)
            
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
            delegate.window.rootViewController = navCont;
            
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
            rootViewController = [storyboard instantiateInitialViewController];
            
            delegate.window.rootViewController = rootViewController;
            // [self getSubscriptionDetail];
        }
    }
}













- (void)getSubscriptionDetail
    {
        WebCommunication *webComm = [[WebCommunication alloc] initWithServiceType:1];
        
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        [dic setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"userId"] forKey:@"userId"];
        NSURL *serviceUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/subscriptionsList",kAMBaseURL]];
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [webComm callToServerRequestDictionary:dic onURL:serviceUrl WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            if (!error)
            {
                NSLog(@"%ld, %@",(long)status_code,response);
                if ([[response objectForKey:@"responseCode"] integerValue] != 1)
                {
//                    [[[UIAlertView alloc] initWithTitle:@"Alert" message:[response objectForKey:@"responseDescription"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                    
                    [self getSubscriptionDetail];
                    
                }
                else
                {
                    UIStoryboard *storyboard;
                    if((UI_USER_INTERFACE_IDIOM()) == UIUserInterfaceIdiomPhone)
                    {
                        storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhoneTouch" bundle:nil];
                    }
                    else
                    {
                        storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
                    }
                    NSString *subId = [NSString stringWithFormat:@"%@",[response objectForKey:@"subId"]];
                    CTAppDelegate *delegate = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
                    //                if([subId isEqualToString:@"1"])
                    //                {
                    //                    UIViewController * rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"PurchaseViewController"];
                    //                    BaseNavigationController *nav = [[BaseNavigationController alloc] initWithRootViewController:rootViewController];
                    //                    delegate.window.rootViewController = nav;
                    //                }
                    //                else
                    {
                        EventListViewController *eventController = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([EventListViewController class])];
                        [eventController setSubscriptionId:subId];
                        BaseNavigationController *nav = [[BaseNavigationController alloc] initWithRootViewController:eventController];
                        delegate.window.rootViewController = nav;
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
    
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
    
- (IBAction)selectDeviceMode:(UIButton *)sender {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    if (sender.tag == 101) {
        [defaults setObject:AMDeviceModeStrCamera forKey:AMDeviceModeSettingsKey];
       // [self autoConfigureCameraAndTouchDevice];
        
    }
    else
    {
        [defaults setObject:AMDeviceModeStrTouchScreen forKey:AMDeviceModeSettingsKey];
    }
    [defaults synchronize];
    [self setRootViewController];
    NSString * deviceModePref = [defaults stringForKey:AMDeviceModeSettingsKey];
    if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
    {
        // For Camera Access Permission
        if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType: completionHandler:)])
        {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                // Will get here on both iOS 7 & 8 even though camera permissions weren't required
                // until iOS 8. So for iOS 7 permission will always be granted.
                if (!granted)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[[UIAlertView alloc] initWithTitle:@"Attention" message:@"Camera Access Permission Denied. Application need camera access to function properly. Please allow the same from Settings->iAmuseCK->Camera" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];                    });
                }
            }];
        }
    }
    CTKiosk *kiosk = [CTKiosk sharedInstance];
    [kiosk startServer];
}
    
    //- (NSUInteger)supportedInterfaceOrientations
    //{
    //   return  UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
    //}

- (void)autoConfigureCameraAndTouchDevice
{
    SCTableViewController *app;
    
    CTAppDelegate *delegate = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    MBProgressHUD * hud = [MBProgressHUD showHUDAddedTo:delegate.window animated:YES];
    WebCommunication *webComm = [[WebCommunication alloc] initWithServiceType:1];
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"userId"] forKey:@"userId"];
    NSURL *serviceUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/getIP",kAMBaseURL]];
    
    
    
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
                
                //                if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
                //                {
                //                    [defaults setObject:cameraIP forKey:CAMERA_IP_KEY];
                //                }
                //                else
                //                {
                //                    [defaults setObject:touchIP forKey:TOUCHSCREEN_IP_KEY];
                //                }
                [defaults synchronize];
                [app.tableViewModel reloadBoundValues];
                CTKiosk *kiosk = [CTKiosk sharedInstance];
                [kiosk startServer];
            }
        }
    }];
}






    
    @end

