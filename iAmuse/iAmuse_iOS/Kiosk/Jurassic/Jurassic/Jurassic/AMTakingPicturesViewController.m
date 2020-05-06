//
//  AMTakingPicturesViewController.m
//  Jurassic
//
//  Created by Roland Hordos on 2013-07-07.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import "AMTakingPicturesViewController.h"
#import "CTKiosk.h"
#import "AMConstants.h"
#import "PhotoSession.h"
#import "Photo.h"
#import "MBProgressHUD.h"
#import "CTKioskViewController.h"
#import "CTGetReadyViewController.h"
#import "CTSelectSceneViewController.h"
#import "EventListViewController.h"

@interface AMTakingPicturesViewController ()
{
    CTKiosk * kiosk;
}
@end

@implementation AMTakingPicturesViewController

@synthesize workflow = _workflow;
//@synthesize workflow;

- (void)dealloc
{
    NSLog(@"%s", __FUNCTION__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    NSLog(@"%s", __FUNCTION__);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLoad
{
    NSLog(@"%s", __FUNCTION__);
    [super viewDidLoad];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];

//    self.sharingVC = nil;
    _workflow = AMWorkflowNormalCourse;

    // Load theme assets.
    kiosk = [CTKiosk sharedInstance];
//    NSString * assetPath = [kiosk.storePath stringByAppendingPathComponent:@"header.png"];
//    self.header.image = [UIImage imageWithContentsOfFile:assetPath];
  //  assetPath = [kiosk.storePath stringByAppendingPathComponent:@"footer.png"];
//    self.footer.image = [UIImage imageWithContentsOfFile:assetPath];

    [self resetPictureTaking];
}

- (void)viewDidAppear:(BOOL)animated
{
    NSLog(@"%s", __FUNCTION__);
    [super viewDidAppear:animated];

    if (_workflow == AMWorkflowResetToSplash)
    {

    }
    else
    {
      
        
      
        
        // And when the photo actually hits our storage.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveNewPhotoNotification:)
                                                     name:AMCameraNewDiskPhotoNotification
                                                   object:nil];

        // Special scenario where by the time we get here, the photo has already
        // arrived and we miss it.
        CTKiosk * kiosk1 = [CTKiosk sharedInstance];
        if ([kiosk1.currentPhotoSession.entity.photos count] == 1)
        {
            if (!havePicture1)
            {
                havePicture1 = YES;
            }
        }
    }
    
   
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    NSLog(@"%s", __FUNCTION__);
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)receiveNewPhotoNotification:(NSNotification*)notification
{
    /*
     We expect notifications to come in out of thread they were sent.
     */
    [self performSelectorOnMainThread:@selector(newPhotoNotification:)
                           withObject:notification waitUntilDone:NO];
}

- (void)newPhotoNotification:(NSNotification*)notification
{
    /*
     We expect the notification object to be:
        An absolute file path.
     */
    NSString * fileName = notification.object;
    NSLog(@"New Photo Received: %@", fileName);

    CTKiosk * kiosk = [CTKiosk sharedInstance];
    NSLog(@"Photo count: %lu", (unsigned long)([kiosk.currentPhotoSession.entity.photos count]));

    if (!havePicture1)
    {
        // The first picture hadn't been received prior to this, take it's spot.
        havePicture1 = YES;
    }
    else if (!havePicture2)
    {
        // likewise ..
        havePicture2 = YES;
    }
    else if (!havePicture3)
    {
        // last one, let's bust out of here.
        havePicture3 = YES;
        [MBProgressHUD hideAllHUDsForView:self.view animated:NO];

        [self goForward];
    }
}

//
//  Reset the wait indicators and prepare for the next session.
//
- (void)resetPictureTaking
{
    havePicture1 = NO;
    havePicture2 = NO;
    havePicture3 = NO;
}

- (void)goBack
{
    
    
//    [[CTKiosk sharedInstance] pausePhotoSession];
//    [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
    
    
    
    
    id presenter = self.presentingViewController;
    if ([presenter conformsToProtocol:@protocol(TakingPicturesCompleteDelegate1)])
    {
        [self resetPictureTaking];
        // Before we leave release our forward controller.
//        self.sharingVC = nil;
        [presenter takingPicturesViewController:self didFinishWithWorkflow:_workflow];
    }
    else if (self.navigationController)
    {
        [self.navigationController popViewControllerAnimated:YES];
        
       
        
    }
    else
    {
        NSLog(@"Unplanned scenario, our presenter is %@",
                NSStringFromClass([presenter class]));
    }
}

//- (void)goBack
//{
//    id presenter = self.presentingViewController;
//    if ([presenter conformsToProtocol:@protocol(TakingPicturesCompleteDelegate)])
//    {
//        [self resetPictureTaking];
//        // Before we leave release our forward controller.
//        //        self.sharingVC = nil;
//        [presenter takingPicturesViewController:self didFinishWithWorkflow:_workflow];
//    }
//    else if (self.navigationController)
//    {
//        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
//        NSString * deviceModePref = [defaults stringForKey:AMDeviceModeSettingsKey];
//        if ([deviceModePref isEqualToString:AMDeviceModeStrTouchScreen])
//        {
//            NSArray *viewControllers = self.navigationController.viewControllers;
//            for (UIViewController *anVC in viewControllers) {
//                if ([anVC isKindOfClass:[CTKioskViewController class] ]){
//                    [self.navigationController popToViewController:anVC animated:NO];
//                    break;
//                }
//            }
//        }
//
//        else
//        {
//
//            NSArray *viewControllers = self.navigationController.viewControllers;
//            for (UIViewController *anVC in viewControllers) {
//                if ([anVC isKindOfClass:[CTGetReadyViewController class] ]){
//                    [self.navigationController popToViewController:anVC animated:NO];
//                    break;
//                }
//            }
//        }
//
//    }
//    else
//    {
//        NSLog(@"Unplanned scenario, our presenter is %@",
//              NSStringFromClass([presenter class]));
//    }
//}


- (void)goForward
{
    [self performSegueWithIdentifier:@"SelectPicture" sender:nil];
}

- (void)sharingViewController:(AMSharingViewController *)sharingViewController
        didFinishWithWorkflow:(NSString *)workflow
{
    // Close the modal.
    if ([workflow isEqualToString:AMWorkflowResetToSplash]) {
        _workflow = workflow;
//        self.sharingVC = nil;
        __block AMTakingPicturesViewController *this = self;
        [self dismissViewControllerAnimated:NO completion: ^{
            NSLog(@"%s", __FUNCTION__);
            id presenter = this.presentingViewController;
            if ([presenter conformsToProtocol:@protocol(TakingPicturesCompleteDelegate1)]) {
//                [this resetPictureTaking];
                [presenter takingPicturesViewController:self didFinishWithWorkflow:AMWorkflowResetToSplash];
            } else {
                NSLog(@"Unplanned scenario, our presenter is %@",
                        NSStringFromClass([presenter class]));
            }
        }];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion: nil];
    }
}

- (IBAction)backButtonAction:(id)sender
{
    
    
//    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject:@"correct" forKey:@"splashScreen"];
//
//    NSString * result = [defaults stringForKey:@"splashScreen"];
//    NSLog(@"result is %@",result);
    
    
    
    
    // Close the camera in preparation for a different background selection.
    [[CTKiosk sharedInstance] action];
 [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
    
 //    [MBProgressHUD showHUDAddedTo:self.view animated:YES];

//    [self performSelector:@selector(goBack) withObject:nil afterDelay:5];
    
    
//
//    [[NSNotificationCenter defaultCenter]
//     postNotificationName:@"touchiPad"
//     object:nil];
//
    
    
    
  
    
    [self goBack];
    
    
   

    
    
}

- (IBAction)forwardButtonAction:(id)sender
{
    [self goForward];
}

@end
