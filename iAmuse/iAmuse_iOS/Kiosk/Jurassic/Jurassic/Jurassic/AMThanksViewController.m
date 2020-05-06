//
//  AMThanksViewController.m
//  Jurassic
//
//  Created by Roland Hordos on 2013-07-08.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import "AMThanksViewController.h"
#import "CTKiosk.h"
#import "Kiosk.h"
#import "AMConstants.h"
#import "RACScheduler.h"
#import "EXTScope.h"
#import "CTSelectSceneViewController.h"
#import "CTAppDelegate.h"
#import "EventListViewController.h"
#import "CTKioskViewController.h"

#define MEMORY_FLUSH_AUTO

#ifdef MEMORY_FLUSH_AUTO
#import <mach/mach.h>
#import <mach/mach_host.h>
#endif

@interface AMThanksViewController ()
{
    
  
    NSInteger timeoutForReset;
    CTAppDelegate *appDelegate;
    NSTimer *resetTimer;
    NSNumber *temp;
   
}

@end

@implementation AMThanksViewController
 extern NSString *picComplete;
- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}

- (void)viewDidLoad
{
    NSLog(@"%s", __FUNCTION__);
    [super viewDidLoad];
    
     [[CTKiosk sharedInstance] backToThankYou];
    
    
//    NSLog(@"temp is %@",temp);
//
//    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
//    NSNumber * temp1 = [defaults objectForKey:@"temp"];
//
//    NSLog(@"%@",temp1);
//
//    id thePresenter = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count - 2];
//
//    // and test its class
//    if ([thePresenter isKindOfClass:[CTKioskViewController class]]) {
//        // do this
//
//
//          CTKiosk *kiosk = [CTKiosk sharedInstance];
//         PhotoLayout *layout = [kiosk currentPhotoLayout];
//        NSString * thankuassetPath = [kiosk.storePath stringByAppendingPathComponent:[NSString stringWithFormat:@"Events/%@/thankyou",[kiosk eventId]]];
//        _backgroundImage.image = [UIImage imageWithContentsOfFile:thankuassetPath];
//
//
//    }
//

    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
       NSString *temp2 = [defaults stringForKey:@"event"];
    
    
    

    NSLog(@"Send notification for REMOVELOOKATIPAD");
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"removeLookAtiPadNotification"
     object:nil];
    
    CTAppDelegate *appDel = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDel.globalVariable = @"incorrect";
    NSLog(@"%@", appDel.globalVariable);
    
    // Load theme assets.
    CTKiosk *kiosk = [CTKiosk sharedInstance];
    NSString *assetPath = [kiosk.storePath stringByAppendingPathComponent:@"header.png"];
    self.header.image = [UIImage imageWithContentsOfFile:assetPath];
    assetPath = [kiosk.storePath stringByAppendingPathComponent:@"footer.png"];
    self.footer.image = [UIImage imageWithContentsOfFile:assetPath];
    PhotoLayout *layout = [kiosk currentPhotoLayout];
    
//    NSString *val = [kiosk eventId];
//    NSLog(@"val is %@",val);

    
    NSString * thankuassetPath = [kiosk.storePath stringByAppendingPathComponent:[NSString stringWithFormat:@"Events/%@/thankyou",layout.eventId]];
    
    NSString *thankYou =[kiosk.storePath stringByAppendingPathComponent:[NSString stringWithFormat:@"Events/%@/thankyou",temp2]];
   defaults = [NSUserDefaults standardUserDefaults];
    
    
    id thePresenter = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count - 2];
    
    if (![thePresenter isKindOfClass:[CTKioskViewController class]]) {
        
        _backgroundImage.image = [UIImage imageWithContentsOfFile:thankuassetPath];
    
    [defaults setObject:thankuassetPath forKey:@"temp"];
        [defaults setObject:@"touch" forKey:@"action"];
    }
    
    else{
    
//    //NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject: layout.eventId forKey:@"temp"];
    _backgroundImage.image = [UIImage imageWithContentsOfFile:thankYou];
        [defaults setObject:@"camera" forKey:@"action"];
    }
    // Load support fields.
    self.support1.text = kiosk.entity.contactLabel1;
    self.support2.text = kiosk.entity.contactLabel2;
    
    NSString * temp1 = [defaults stringForKey:@"temp"];
  //  NSString *temp2 = [defaults stringForKey:@"event"];
    
    NSLog(@"event value is %@",temp2);
    NSLog(@"thank you path is %@",thankYou);
    
    
    
}

- (NSUInteger)supportedInterfaceOrientations
{
    return  UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    
    
    id thePresenter = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count - 2];

    // and test its class
    if ([thePresenter isKindOfClass:[CTKioskViewController class]]) {


        NSLog(@"successful");
        
        
    //     [self performSelector:@selector(gotoTouchIpad) withObject:nil afterDelay:3];
        
//        timeoutForReset = 25;
//        resetTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(gotoTouchIpad) userInfo:nil repeats:YES];
//        
        
        
        double delayInSeconds = 3.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self performSelector:@selector(gotoTouchIpad) withObject:nil afterDelay:0];
        });
        

    }
    else{
    
    CTKiosk * kiosk = [CTKiosk sharedInstance];
    [kiosk networkCameraThankYou];
    
    
    
    
    timeoutForReset = 3;
    resetTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(showCountDown) userInfo:nil repeats:YES];
        
        
        
        

    //[self performSelector:@selector(showCountDown) withObject:nil afterDelay:1.0];
//    float resetIntervalSetting = 15;
//
//    @weakify(self);
//    [[RACScheduler mainThreadScheduler] after:[NSDate dateWithTimeIntervalSinceNow:resetIntervalSetting]
//                           schedule:^
//    {
//        @strongify(self);
//        [self reset];
//    }];
}
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [resetTimer invalidate];
    resetTimer = nil;
}

- (void)showCountDown
{
    if (timeoutForReset > 0) {
        timeoutForReset--;
        [self.resetLbl setText:[NSString stringWithFormat:@"%ld",(long)timeoutForReset]];
    }
    else
    {
 
        @weakify(self);
        [[RACScheduler mainThreadScheduler] after:[NSDate dateWithTimeIntervalSinceNow:0]
                               schedule:^
        {
            @strongify(self);
            [self reset];
            
            
        }];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (void)reset {
//
//
//    [self getFreeMemory:YES];
//    CTAppDelegate *appDel = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
//    appDel.globalVariable = @"correct";
//    picComplete = @"correct";
//    NSString *valueToSave = @"correct";
//    NSUserDefaults * naming = [NSUserDefaults standardUserDefaults];
//    [naming setObject:valueToSave forKey:@"PicComplete"];
//    [naming synchronize];
//
//
//
//    NSUserDefaults * naming1 = [NSUserDefaults standardUserDefaults];
//    NSString * result = [naming stringForKey:@"PicComplete"];
//
//  //  [[NSNotificationCenter defaultCenter] postNotificationName:@"PicturesComplete" object:nil];
//
//
//
//    id presenter = self.presentingViewController;
//    if ([presenter conformsToProtocol:@protocol(ThanksCompleteDelegate)]) {
//        [presenter thanksViewController:self didFinishWithWorkflow:AMWorkflowResetToSplash];
//    } else if (self.navigationController) {
//        NSArray *viewControllers = self.navigationController.viewControllers;
//        for (UIViewController *anVC in viewControllers) {
//            if ([anVC isKindOfClass:[CTSelectSceneViewController class] ]){
//                [self.navigationController popToViewController:anVC animated:NO];
//                break;
//            }
//        }
//    } else {
//        NSLog(@"Unplanned scenario, our presenter is %@",
//                NSStringFromClass([presenter class]));
//    }
//}


- (void)reset {


   // [[NSNotificationCenter defaultCenter] postNotificationName:@"testing" object:nil];
    
    
    [self getFreeMemory:YES];
   // [[CTKiosk sharedInstance] backToEventScene];
  //  [[CTKiosk sharedInstance]  ]
    
//    [[CTKiosk sharedInstance] backToThankYou];

    
    
   // [self.navigationController popViewControllerAnimated:YES];
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * deviceModePref = [defaults stringForKey:AMDeviceModeSettingsKey];
    if ([deviceModePref isEqualToString:AMDeviceModeStrTouchScreen])
    {
        NSArray *viewControllers = self.navigationController.viewControllers;
                for (UIViewController *anVC in viewControllers) {
                    if ([anVC isKindOfClass:[CTSelectSceneViewController class] ]){
                        [self.navigationController popToViewController:anVC animated:NO];
                        break;
    }
}


    }

    else
    {
        
       

    NSArray *viewControllers = self.navigationController.viewControllers;
    for (UIViewController *anVC in viewControllers) {
        if ([anVC isKindOfClass:[EventListViewController class] ]){
            [self.navigationController popToViewController:anVC animated:NO];

//       UIStoryboard *storyboard;
//        storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
//        CTKioskViewController *eventController = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([CTKioskViewController class])];
//        [self.navigationController pushViewController:eventController animated:YES];



            break;
        }
    }
}
}


//- (void)reset {
//
//
//    [self getFreeMemory:YES];
//    [[CTKiosk sharedInstance] backToEventScene];
////     [self.navigationController popViewControllerAnimated:YES];
//    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
//    NSString * deviceModePref = [defaults stringForKey:AMDeviceModeSettingsKey];
//    if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
//    {
//
//         [self.navigationController popViewControllerAnimated:YES];
////        UIStoryboard *storyboard;
////                storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
////                CTKioskViewController *eventController = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([CTKioskViewController class])];
////                [self.navigationController pushViewController:eventController animated:YES];
//               // break;
//     //       }
//    //    }
//
//
//    }
//
//    else
//    {
//
//        NSArray *viewControllers = self.navigationController.viewControllers;
//                        for (UIViewController *anVC in viewControllers) {
//                            if ([anVC isKindOfClass:[CTSelectSceneViewController class] ]){
//                                [self.navigationController popToViewController:anVC animated:NO];
//                                break;
//
//                //       UIStoryboard *storyboard;
//                //        storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
//                //        CTKioskViewController *eventController = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([CTKioskViewController class])];
//                //        [self.navigationController pushViewController:eventController animated:YES];
//
//
//
//             //   break;
//            }
//        }
//    }
//}


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
    
    if(printLog)
    {
        NSLog(@"free memory MB: %f",(float)mem_free/(1024.0*1024.0));
    }
    
    return mem_free/(1024.0*1024.0);
}

- (IBAction)likeOnFB:(id)sender {
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"http://www.facebook.com"]] ) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.facebook.com"]];
    }
}

- (IBAction)doneTouched:(id)sender {
    [self reset];
}


- (void)gotoTouchIpad
{
    
    
//    UIStoryboard *storyboard;
//    storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
//    CTKioskViewController *eventController = [storyboard instantiateViewControllerWithIdentifier:@"CTKioskViewController"];
//    [self.navigationController pushViewController:eventController animated:YES];
    
  
    
    
    NSArray *viewControllers = self.navigationController.viewControllers;
    
  

    
    
    NSLog(@"arrayWithoutDuplicates values is %@",viewControllers);
    for (UIViewController *anVC in viewControllers) {
        if ([anVC isKindOfClass:[CTKioskViewController class] ]){
            [self.navigationController popToViewController:anVC animated:NO];
            break;
        }
    }
    
}


@end
