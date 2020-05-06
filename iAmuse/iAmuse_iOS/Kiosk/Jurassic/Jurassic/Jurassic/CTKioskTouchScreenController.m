//
//  CTCameraNavController.m
//  Jurassic
//
//  Created by Roland Hordos on 2013-05-25.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import "CTKioskTouchScreenController.h"
//#import "CTKiosk.h"
#import "CTCameraViewController.h"
#import <objc/runtime.h>        // TEMP for logging classname only
#import "AMConstants.h"

@interface CTKioskTouchScreenController ()

@end

//
//
//
@implementation CTKioskTouchScreenController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
//    [self.navigationController setNavigationBarHidden: YES animated:YES];

    [super viewDidLoad];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(showSplash:)
//                                                 name:@"ShowSplash"
//                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

//    NSLog(@"Disabling auto-sleep");
//    [UIApplication sharedApplication].idleTimerDisabled = YES;
//
//    CTKiosk *kiosk = [CTKiosk sharedInstance];
//    [kiosk startup];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
        
    NSLog(@"%s", __FUNCTION__);
}

//- (void) showSplash:(NSNotification *) notification
//{
//    // Put the Kiosk View Controller to the top.
//    @try {
//        [self performSegueWithIdentifier:@"splash" sender:nil];
//    }
//    @catch (NSException * e) {
//        NSLog(@"Exception: %@", e);
//    }
//}

//- (void)sceneSelectionViewController:(CTSelectSceneViewController *)sceneSelectionViewController
//               didFinishWithWorkflow:(NSString *)workflow
//{
//    // Close the modal.
//    [self dismissViewControllerAnimated:YES completion: nil];
//}


@end
