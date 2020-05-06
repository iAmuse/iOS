//
//  AMConfirmPrintViewController.h
//  Jurassic
//
//  Created by Roland Hordos on 2014-07-02.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import "AMConfirmPrintViewController.h"
#import "AMConstants.h"
#import "AMPrintKiosk.h"
#import "ABPadLockScreenViewController.h"
#import "ABPadLockScreenSetupViewController.h"

@interface AMConfirmPrintViewController ()
{
    UIView *transparentView;
    ABPadLockScreenViewController *lockScreen;
}
@end

@implementation AMConfirmPrintViewController

- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    NSLog(@"%s", __FUNCTION__);
    [super viewDidLoad];

    // Default workflow.
    self.lockPIN = kAMPrintKioskLockPIN;
    _workflow = AMWorkflowNormalCourse;

    AMPrintKiosk *kiosk = [AMPrintKiosk sharedInstance];
    NSString *assetPath = [kiosk.storePath stringByAppendingPathComponent:@"header.png"];
    self.header.image = [UIImage imageWithContentsOfFile:assetPath];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showSettingScreen2:)
                                                 name:@"showSettingScreen"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lockCancel2:)
                                                 name:@"lockCancel"
                                               object:nil];
    
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewsSwipe2:)];
    swipeUp.numberOfTouchesRequired = 2;
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    swipeUp.delaysTouchesBegan = YES;
   // [self.view addGestureRecognizer:swipeUp];
    
    
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewsSwipe2:)];
    swipeDown.numberOfTouchesRequired = 2;
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    swipeDown.delaysTouchesBegan = YES;
    //[self.view addGestureRecognizer:swipeDown];
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewsSwipe2:)];
    swipeRight.numberOfTouchesRequired = 2;
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    swipeRight.delaysTouchesBegan = YES;
    //[self.view addGestureRecognizer:swipeRight];
    
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewsSwipe2:)];
    swipeLeft.numberOfTouchesRequired = 2;
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    swipeLeft.delaysTouchesBegan = YES;
    //[self.view addGestureRecognizer:swipeLeft];
}

- (void)handleViewsSwipe2:(UISwipeGestureRecognizer *)recognizer
{
    
    NSUInteger touches = recognizer.numberOfTouches;
    if (touches == 2)
    {
        [self authorizePrint2];
    }
}

- (void)authorizePrint2 {
    
    lockScreen = [[ABPadLockScreenViewController alloc] initWithDelegate:nil complexPin:NO];
    lockScreen.showSetting = YES;
    
    
    lockScreen.modalPresentationStyle = UIModalPresentationFullScreen;
    [lockScreen cancelButtonDisabled:NO];
    lockScreen.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    
    [self presentViewController:lockScreen animated:YES completion:nil];
}

- (void)lockCancel2:(NSNotification *)notification
{
    [lockScreen dismissViewControllerAnimated:NO completion:nil];
}

- (void)showSettingScreen2:(NSNotification *)notification
{
    [lockScreen dismissViewControllerAnimated:NO completion:nil];
    
    [self performSegueWithIdentifier:@"settings" sender:self];
}


- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"%s", __FUNCTION__);
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden: YES animated:YES];
    
    // This is needed as dependent views may not yet be loaded within viewWillAppear.
    AMPrintKiosk *kiosk = [AMPrintKiosk sharedInstance];
    if (kiosk.selectedPhoto) {
//        NSString *backgroundUrl = [kiosk.storePath stringByAppendingPathComponent:kiosk.currentPhotoLayout.background];
//        self.selectedPhotoImageView.image = [UIImage imageWithContentsOfFile:backgroundUrl];
        self.selectedPhotoImageView.image = kiosk.selectedPhoto;
    } else {
        self.selectedPhotoImageView.image = [UIImage imageNamed:@"problems.jpg"];
    }
}

- (void)viewDidAppear:(BOOL)animated{
    NSLog(@"%s", __FUNCTION__);
    if (_workflow == AMWorkflowResetToSplash) {
        [self goBack];
        _workflow = AMWorkflowNormalCourse;
    } else {
        // Observe when we feel the user has left.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(userDidLeave:)
                                                     name:AMUserDidLeave
                                                   object:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    NSLog(@"%s", sel_getName(_cmd));
}

- (void)goBack {
    AMPrintKiosk *kiosk = [AMPrintKiosk sharedInstance];
    [kiosk userHeartbeat];

    [self.navigationController popViewControllerAnimated:YES];
}

- (void)printSelectedPhoto {
    AMPrintKiosk *kiosk = [AMPrintKiosk sharedInstance];
    [kiosk print:self dialogFocus:self.printButton];
}

//
// We're in view but the user walked away, tell our presenter we're done and
// they should close too.
//
- (void)userDidLeave:(NSNotification *)notification {
    NSLog(@"%s", __FUNCTION__);

    [self.navigationController popToViewController:[[self navigationController].viewControllers objectAtIndex:0] animated:YES];
}


- (IBAction)backButtonTouched:(id)sender {
    [self goBack];
}

- (IBAction)noButtonTouched:(id)sender {
    [self goBack];
}

- (IBAction)yesButtonTouched:(id)sender {
    [self authorizePrint];
}

- (IBAction)settingsButtonTouched:(id)sender {
    [self performSegueWithIdentifier:@"settings" sender:nil];
}

- (IBAction)PrintPreview:(id)sender
{
    CTKiosk *kiosk = [CTKiosk sharedInstance];
    UIImage *printImage = [kiosk printPreview:self dialogFocus:nil];
    transparentView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    transparentView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:transparentView];
    
    UIView *semiTransparentView = [[UIView alloc]initWithFrame:transparentView.frame];
    semiTransparentView.userInteractionEnabled = NO;
    [transparentView addSubview:semiTransparentView];
    
    
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, printImage.size.width, printImage.size.height)];
    imageView.image = printImage;
    imageView.userInteractionEnabled = NO;
    
    [transparentView addSubview:imageView];
    imageView.center = transparentView.center;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    if(touch.view == transparentView)
    {
        [transparentView removeFromSuperview];
    }
}


#pragma mark -
#pragma mark - PIN Pad

- (void)authorizePrint {
//???    [self performSegueWithIdentifier:@"approve" sender:nil];
//    ABPadLockScreenSetupViewController *lockScreen = [[ABPadLockScreenSetupViewController alloc] initWithDelegate:self
//                                                                                                       complexPin:NO];
    ABPadLockScreenViewController *lockScreen = [[ABPadLockScreenViewController alloc] initWithDelegate:self complexPin:NO];

    lockScreen.modalPresentationStyle = UIModalPresentationFullScreen;
    lockScreen.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;

//    //Example using an image
//    UIImageView* backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"wallpaper"]];
//    backgroundView.contentMode = UIViewContentModeScaleAspectFill;
//    backgroundView.clipsToBounds = YES;
//    [lockScreen setBackgroundView:backgroundView];

    [self presentViewController:lockScreen animated:YES completion:nil];
}

//- (IBAction)lockApp:(id)sender
//{
//    if (!self.thePin)
//    {
//        [[[UIAlertView alloc] initWithTitle:@"No Pin" message:@"Please Set a pin before trying to unlock" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
//        return;
//    }
//    
//    ABPadLockScreenViewController *lockScreen = [[ABPadLockScreenViewController alloc] initWithDelegate:self complexPin:YES];
//    [lockScreen setAllowedAttempts:3];
//    
//    lockScreen.modalPresentationStyle = UIModalPresentationFullScreen;
//    lockScreen.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
//    
//	//Example using an image
//	UIImageView* backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"wallpaper"]];
//	backgroundView.contentMode = UIViewContentModeScaleAspectFill;
//	backgroundView.clipsToBounds = YES;
//	[lockScreen setBackgroundView:backgroundView];
//    
//    [self presentViewController:lockScreen animated:YES completion:nil];
//}

#pragma mark -
#pragma mark - ABLockScreenDelegate Methods

- (BOOL)padLockScreenViewController:(ABPadLockScreenViewController *)padLockScreenViewController
                        validatePin:(NSString*)pin;
{
	NSLog(@"Validating pin %@", pin);
    
	return [pin isEqualToString:self.lockPIN];
}

- (void)unlockWasSuccessfulForPadLockScreenViewController:(ABPadLockScreenViewController *)padLockScreenViewController
{
    [padLockScreenViewController dismissViewControllerAnimated:YES completion:nil];
    [self printSelectedPhoto];
}

- (void)unlockWasUnsuccessful:(NSString *)falsePin afterAttemptNumber:(NSInteger)attemptNumber
  padLockScreenViewController:(ABPadLockScreenViewController *)padLockScreenViewController
{
    NSLog(@"Failed attempt number %ld with pin: %@", (long)attemptNumber, falsePin);
}

- (void)unlockWasCancelledForPadLockScreenViewController:(ABPadLockScreenAbstractViewController *)padLockScreenViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
//    NSLog(@"Pin entry cancelled");
}

- (void)attemptsExpiredForPadLockScreenViewController:(ABPadLockScreenViewController *)padLockScreenViewController {
//    NSLog(@"Pin entry cancelled");
    [self dismissViewControllerAnimated:YES completion:nil];
}

//#pragma mark -
//#pragma mark - ABPadLockScreenSetupViewControllerDelegate Methods
//- (void)pinSet:(NSString *)pin padLockScreenSetupViewController:(ABPadLockScreenSetupViewController *)padLockScreenViewController
//{
//    [self dismissViewControllerAnimated:YES completion:nil];
//    self.thePin = pin;
//    NSLog(@"Pin set to pin %@", self.thePin);
//}

@end
