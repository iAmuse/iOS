//
//  AMSharingViewController.m
//  Jurassic
//
//  Created by Roland Hordos on 2013-07-08.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import <M13Checkbox/M13Checkbox.h>
#import "AMSharingViewController.h"
#import "CTKiosk.h"
#import "Kiosk.h"
#import "AMThanksViewController.h"
#import "AMConstants.h"
#import "AMTakingPicturesViewController.h"
#import "MBProgressHUD.h"
#import "PrivacyPolicyViewController.h"
#import "EventListViewController.h"
#import "CTSelectSceneViewController.h"

@interface AMSharingViewController () <SendImagesToServerProtocol>
{
    CGRect nameFieldFrame, emailFieldFrame, numberFieldFrame, infoLabelFrame, checkButtonFrame, newsLetterFrame, sendButtonFrame, tAndCFrame;
    
    bool checked;
     bool checked1;
     NSTimer *idleTimer;
    
    bool name;
    bool phone;
    
    
    
    NSTimer *countdownTimer;
    int secondsCount;
    
    int seconds;
    
}
@end

#define IdleTimeSeconds 30.0

@implementation AMSharingViewController

- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}

- (void)viewDidLoad
{
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"testing" object:nil];
    [self resetIdleTimer];
     indicatorBackView.hidden = YES;
    _popupView.hidden = YES;
    _completeView.hidden=YES;
    
    //_countdownLabel.text=@"10";
   
    
    
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    _nameField.leftView = paddingView;
    _nameField.leftViewMode = UITextFieldViewModeAlways;
    
    
    
     UIView *paddingViewa = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    _mobileField.leftView = paddingViewa;
    _mobileField.leftViewMode = UITextFieldViewModeAlways;

    
    
    
    
     UIView *paddingViewb = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    _emailField.leftView = paddingViewb;
    _emailField.leftViewMode = UITextFieldViewModeAlways;

    
    
    NSMutableAttributedString *attString =
    [[NSMutableAttributedString alloc]
     initWithString: @"    Email*"];
    
    [attString addAttribute: NSForegroundColorAttributeName
                      value: [UIColor redColor]
                      range: NSMakeRange(9,1)];
    
    
//    [attString addAttribute: NSFontAttributeName
//                      value:  [UIFont fontWithName:@"Helvetica" size:30]
//                      range: NSMakeRange(5,1)];
    
    
    
    _emailField.attributedPlaceholder  = attString;
    
    
    
    
//    UIColor *color = [UIColor redColor];
//    _emailField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"E-mail" attributes:@{NSForegroundColorAttributeName: color}];
    
    checked =NO;
    checked1 =NO;
    
    name=YES;
    phone=NO;
    
    _backButtonRounded.layer.cornerRadius = 3; // this value vary as per your desire
    _backButtonRounded.clipsToBounds = YES;
    
    
    _sendButton.layer.cornerRadius = 3; // this value vary as per your desire
    _sendButton.clipsToBounds = YES;
    
    
    _emailField.layer.borderColor = [UIColor colorWithRed:0/255.0 green:121/255.0 blue:15/255.0 alpha:1.0].CGColor;
    _emailField.layer.borderWidth = 2.0;
    
    _nameField.layer.borderColor = [UIColor colorWithRed:0/255.0 green:121/255.0 blue:15/255.0 alpha:1.0].CGColor;
    _nameField.layer.borderWidth = 2.0;
    
    _mobileField.layer.borderColor = [UIColor colorWithRed:0/255.0 green:121/255.0 blue:15/255.0 alpha:1.0].CGColor;
    _mobileField.layer.borderWidth = 2.0;
    
    
  //  _emailField.layer.borderColor = [[UIColor greenColor]CGColor];
 //   _emailField.layer.borderWidth = 1.0;
    
 //   _nameField.layer.borderColor = [[UIColor greenColor]CGColor];
 //   _nameField.layer.borderWidth = 1.0;
    
 //   _mobileField.layer.borderColor = [[UIColor greenColor]CGColor];
 //   _mobileField.layer.borderWidth = 1.0;
    
    
    NSLog(@"%s", __FUNCTION__);
    [super viewDidLoad];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
//    thanksVC = nil;
    _workflow = AMWorkflowNormalCourse;
    
    // Load theme assets.
    CTKiosk * kiosk = [CTKiosk sharedInstance];
    if (!kiosk.isSubscribed) {
        self.checkButton.hidden = self.newsletterOptInLabel.hidden = YES;
    }
    
    if (!kiosk.isName) {
        
        _nameField.hidden=YES;
        _imgUserIcon.hidden=YES;
        //self.checkButton.hidden = self.newsletterOptInLabel.hidden = YES;
        
        [self.mobileField becomeFirstResponder];
        
    }
    
    if (!kiosk.isPhone) {
       // self.checkButton.hidden = self.newsletterOptInLabel.hidden = YES;
        _nameField.hidden=YES;
        _imgUserIcon.hidden=YES;
        
        
      //  _mobileField.placeholder = @""
        
        NSAttributedString *str = [[NSAttributedString alloc] initWithString:@"   Name" attributes:@{ NSForegroundColorAttributeName : [UIColor lightGrayColor] }];
        self.mobileField.attributedPlaceholder = str;
        
        _imgCallIcon.image = [UIImage imageNamed:@"User icon.png"];
        
         [_mobileField setKeyboardType:UIKeyboardTypeAlphabet];
        
        [self.mobileField becomeFirstResponder];
        
        
        
    }
    
    
    if( (!kiosk.isName) && (!kiosk.isPhone) ){
        
        _nameField.hidden=YES;
        _imgUserIcon.hidden=YES;
        
        _mobileField.hidden=YES;
        _imgCallIcon.hidden=YES;
        //self.checkButton.hidden = self.newsletterOptInLabel.hidden = YES;
        
        [self.emailField becomeFirstResponder];
    }
    
    
    NSString * assetPath = [kiosk.storePath stringByAppendingPathComponent:@"header.png"];
    self.header.image = [UIImage imageWithContentsOfFile:assetPath];
    assetPath = [kiosk.storePath stringByAppendingPathComponent:@"footer.png"];
    self.footer.image = [UIImage imageWithContentsOfFile:assetPath];

    // Load custom labels.
    self.publicUsageLabel.text = kiosk.entity.publicUsageLabel;

    // Custom switch for public sharing question, and newsletter opt in.

    //Create custom checkbox right beside the take pictures button and the same height.
    int margin = 20;
    float height = 50;
    CGRect publicUsageLabelRect = self.publicUsageLabel.frame;
    CGRect newsletterLabelRect = self.newsletterOptInLabel.frame;

    M13Checkbox *publicUsageCheckbox = [[M13Checkbox alloc] initWithFrame:CGRectMake(publicUsageLabelRect.origin.x + publicUsageLabelRect.size.width + margin,
            publicUsageLabelRect.origin.y + (publicUsageLabelRect.size.height / 2) - (height / 2), 100, height)
                                                                    title:@""
                                                              checkHeight:height];
    [publicUsageCheckbox addTarget:self action:@selector(publicUsageChanged:) forControlEvents:UIControlEventValueChanged];
  //  [self.view addSubview:publicUsageCheckbox];

    M13Checkbox *newsletterOptInCheckbox = [[M13Checkbox alloc] initWithFrame:CGRectMake(newsletterLabelRect.origin.x + newsletterLabelRect.size.width + margin,
            newsletterLabelRect.origin.y + 5, 100, height)
                                                         title:@""
                                                   checkHeight:height];
    [newsletterOptInCheckbox addTarget:self action:@selector(newsletterToggleChanged:) forControlEvents:UIControlEventValueChanged];
    newsletterOptInCheckbox.checkState = M13CheckboxStateUnchecked;
    [kiosk chooseNewsletter:NO];
 //   [self.view addSubview:newsletterOptInCheckbox];

    //[self.emailField becomeFirstResponder];
    
  //  [MBProgressHUD showHUDAddedTo:indicatorBackView animated:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:self.view.window];
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:self.view.window];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
     _nameField.frame = nameFieldFrame;
     _emailField.frame = emailFieldFrame;
     _mobileField.frame = numberFieldFrame;
     _infoLabel.frame = infoLabelFrame;
     _checkButton.frame = checkButtonFrame;
     _newsletterOptInLabel.frame = newsLetterFrame;
     _sendButton.frame = sendButtonFrame;
     _tAndCButton.frame = tAndCFrame;

}

- (void)keyboardWillShow:(NSNotification *)notification
{
   // [self.view removeConstraints:self.view.constraints];

//    CGFloat mainScreenWidth = self.view.frame.size.width;
//    
//    _nameField.frame = CGRectMake((mainScreenWidth - 2*_nameField.frame.size.width - 30)/2, _nameField.frame.origin.y, _nameField.frame.size.width, _nameField.frame.size.height);
//    _emailField.frame = CGRectMake(_nameField.frame.origin.x + _nameField.frame.size.width + 30, _nameField.frame.origin.y, _nameField.frame.size.width, _nameField.frame.size.height);
//    _mobileField.frame = CGRectMake((mainScreenWidth - 2*_nameField.frame.size.width - 30)/2, _nameField.frame.origin.y+ _nameField.frame.size.height+20, _nameField.frame.size.width, _nameField.frame.size.height);
//    _infoLabel.frame = CGRectMake(_nameField.frame.origin.x + _nameField.frame.size.width + 30, _nameField.frame.origin.y+ _nameField.frame.size.height, _nameField.frame.size.width, 2*_nameField.frame.size.height);
//    
//    _checkButton.frame = CGRectMake(_nameField.frame.origin.x, _mobileField.frame.origin.y+ _mobileField.frame.size.height+20, _checkButton.frame.size.width, _checkButton.frame.size.height);
//    _newsletterOptInLabel.frame = CGRectMake(_checkButton.frame.origin.x + _checkButton.frame.size.width + 20, _checkButton.frame.origin.y, _newsletterOptInLabel.frame.size.width, _newsletterOptInLabel.frame.size.height);
//
//    _sendButton.frame = CGRectMake(_sendButton.frame.origin.x, _tAndCButton.frame.origin.y+ _tAndCButton.frame.size.height+15, _sendButton.frame.size.width, _sendButton.frame.size.height);
//    _tAndCButton.frame = CGRectMake(_tAndCButton.frame.origin.x, _sendButton.frame.origin.y, _tAndCButton.frame.size.width, _tAndCButton.frame.size.height);

}

- (void)dismissKeyboard
{
    
    NSLog(@"ajay");
    
    [self resetIdleTimer];
    
    _popupView.hidden = YES;
    _completeView.hidden = YES;
    _completeView.alpha = 0;
    //    _completeView.userInteractionEnabled = YES;
    [countdownTimer invalidate];

    
    [_emailField resignFirstResponder];
    [_nameField resignFirstResponder];
    [_mobileField resignFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    nameFieldFrame = _nameField.frame;
    emailFieldFrame = _emailField.frame;
    numberFieldFrame = _mobileField.frame;
    infoLabelFrame = _infoLabel.frame;
    checkButtonFrame = _checkButton.frame;
    newsLetterFrame = _newsletterOptInLabel.frame;
    sendButtonFrame = _sendButton.frame;
    tAndCFrame = _tAndCButton.frame;

    if (_workflow == AMWorkflowResetToSplash)
    {
        // Before we leave release our forward controller.
//        thanksVC = nil;
//        [self reset];
        _workflow = AMWorkflowNormalCourse;
    }
    else
    {
        // Print Button - keep disabled
        // TODO - lookup setting to see if printing is enabled
//        self.printButton.enabled = NO;
//        self.printButton.alpha = 0.25;

        // Send Button - reset each run
        BOOL valid = [self validateEmail:self.emailField.text];
        if (valid)
        {
            self.sendButton.enabled = valid;
            self.sendButton.alpha = 1;
        }
    }
//    [self.nameField becomeFirstResponder];
  //  self.emailField.text = @"";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doneButtonTouched:(id)sender
{
    NSLog(@"%s", __FUNCTION__);
    if (self.sendButton.enabled)
    {
        [self send];
    }
    [self thankVisitor];
}

- (IBAction)mobilEditDidEnd:(id)sender {
    CTKiosk * kiosk = [CTKiosk sharedInstance];
    [kiosk setNumber:self.mobileField.text];
}

- (IBAction)nameEditDidEnd:(id)sender {
    CTKiosk * kiosk = [CTKiosk sharedInstance];
    [kiosk setName:self.nameField.text];
}

- (IBAction)emailEditDidEnd:(id)sender
{
    NSLog(@"%s", __FUNCTION__);

    BOOL valid = [self validateEmail:self.emailField.text];
    if (valid)
    {
        CTKiosk * kiosk = [CTKiosk sharedInstance];
        [kiosk setEmailAddress:self.emailField.text];
    }
    self.sendButton.enabled = valid;
}

- (BOOL)validateEmail:(NSString *)candidate
{
    NSString * emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate * emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    
    return [emailTest evaluateWithObject:candidate];
}

- (IBAction)emailTouchOutside:(id)sender
{
    NSLog(@"%s", __FUNCTION__);
}

- (IBAction)screenTouched:(id)sender
{
    [self.emailField resignFirstResponder];
}

- (IBAction)backButtonTouched:(id)sender
{
    [idleTimer invalidate];
    [countdownTimer invalidate];
    
    
    [self.navigationController popViewControllerAnimated:YES];
    
}

- (IBAction)termsAndConditionAction:(UIButton *)sender {
    PrivacyPolicyViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([PrivacyPolicyViewController class])];
    [controller setIsShowingFromSetting:YES];
    [self.navigationController pushViewController:controller animated:YES];

}

- (IBAction)publicUsageChanged:(id)sender
{
//    NSLog(@"Public Sharing Toggled %ld", (long)self.publicUsageCheckBox.selectedSegmentIndex);
    [self.emailField resignFirstResponder];

    CTKiosk *kiosk = [CTKiosk sharedInstance];
    [kiosk sharePhotoPubliclyOfAge:((M13Checkbox *)sender).checkState == M13CheckboxStateChecked];
}

- (IBAction)newsletterToggleChanged:(UIButton *)sender
{
//    sender.selected = !sender.selected;
////    NSLog(@"Newsletter Toggled %ld", (long)self.newsletterCheckBox.selectedSegmentIndex);
//    CTKiosk *kiosk = [CTKiosk sharedInstance];
//    if (sender.selected) {
//      //  [_checkButton setImage:[UIImage imageNamed:@"checkbox new.png"] forState:UIControlStateNormal];
//        [kiosk chooseNewsletter:M13CheckboxStateChecked];
//    }
//    else
//    {
//    //    [_checkButton setImage:[UIImage imageNamed:@"Check box 1.png"] forState:UIControlStateNormal];
//        [kiosk chooseNewsletter:M13CheckboxStateUnchecked];
//    }
    
    
    CTKiosk *kiosk = [CTKiosk sharedInstance];
    
    
    if(!checked)
    {
        [_checkButton setImage:[UIImage imageNamed:@"checkbox new.png"] forState:UIControlStateNormal];
    //    [kiosk chooseNewsletter:M13CheckboxStateChecked];
        checked=YES;
    }
    else if (checked)
    {
        [_checkButton setImage:[UIImage imageNamed:@"Check box 1.png"] forState:UIControlStateNormal];
     //   [kiosk chooseNewsletter:M13CheckboxStateUnchecked];
        checked=NO;
    }
    
    
    
    
}

- (IBAction)sendButtonTouched:(id)sender
{
    
//    [[NSNotificationCenter defaultCenter]
//     postNotificationName:@"removeLookAtiPadNotification"
//     object:nil];
    
    if ([self.emailField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0)
    {
        [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Email field is blank" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
    }
    else if (![self validateEmail:self.emailField.text])
    {
        [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Email is not valid" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
    }
    CTKiosk *kiosk = [CTKiosk sharedInstance];
    
    
      if (!kiosk.isPhone) {
          
          [kiosk setName:self.mobileField.text];
      }
    
      else{
    [kiosk setName:self.nameField.text];
    [kiosk setNumber:self.mobileField.text];
      }
    indicatorBackView.hidden = NO;
    [self.view bringSubviewToFront:indicatorBackView];
    
    
    
//    [FIRAnalytics logEventWithName:kFIREventShare
//                        parameters:@{
//                                     kFIRParameterContentType: @"photos",
//                                     kFIRParameterItemID:@""
//                                     }];
    
    
    
    [self performSelector:@selector(sendButtonTapped) withObject:nil afterDelay:0.1];
      
}

- (void)sendButtonTapped
{
    [self send];
    [self thankVisitor];
}

- (void)send
{
    BOOL valid = [self validateEmail:self.emailField.text];
    CTKiosk * kiosk = [CTKiosk sharedInstance];
    [kiosk setEmailAddress:self.emailField.text];

    self.sendButton.enabled = NO;
    self.sendButton.alpha = 0.25;

    //kiosk.delegate = self;
    [kiosk emailPhoto];

    if (!kiosk.isUploadingPendingPhotos) {
        NSLog(@"Upload pending photos");
        [kiosk handlePendingImageUploadingRequest];
    }
    else
    {
        NSLog(@"Already uploading pending photos");
    }
}

- (void)imagesSendingSuccessfull
{
    CTKiosk * kiosk = [CTKiosk sharedInstance];
    kiosk.delegate = nil;
    [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
    [self thankVisitor];
}

- (void)imagesSendingNotSucessfull
{
    CTKiosk * kiosk = [CTKiosk sharedInstance];
    kiosk.delegate = nil;
    [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
    [self thankVisitor];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    /*
     This delegate method is required to detect the keyboard button.
     */
 //   if (textField == self.emailField)
    {
        [textField resignFirstResponder];

        return NO;
    }
    return YES;
}

//-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
//{
//    if(textField== _mobileField)
//    {
//
//        NSCharacterSet *myCharSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
//        for (int i = 0; i < [string length]; i++)
//        {
//            unichar c = [string characterAtIndex:i];
//            if (![myCharSet characterIsMember:c])
//            {
//                return NO;
//            }
//        }
//
//        return YES;
//    }
//
//    return YES;
//}

- (NSUInteger)supportedInterfaceOrientations
{
    return  UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

- (IBAction)printButtonTouched:(id)sender
{
    NSLog(@"%s", __FUNCTION__);
    
    CTKiosk *kiosk = [CTKiosk sharedInstance];
    [kiosk print:self dialogFocus:self.printButton];
    
}

- (void)thankVisitor
{
//    if (!thanksVC) {
//        thanksVC = (AMThanksViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"thanksVC"];
//        [thanksVC setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
//    }
//    [self presentViewController:thanksVC animated:YES completion:NULL];
    
    [idleTimer invalidate];
    [countdownTimer invalidate];

    indicatorBackView.hidden = YES;
    
    [self performSegueWithIdentifier:@"Thanks" sender:nil];
}

- (void)reset
{
    id presenter = self.presentingViewController;
    if ([presenter conformsToProtocol:@protocol(SharingCompleteDelegate)])
    {
        [presenter sharingViewController:self didFinishWithWorkflow:_workflow];
    }
    else
    {
        NSLog(@"Unplanned scenario, our presenter is %@",
                NSStringFromClass([presenter class]));
    }
    NSLog(@"END Reset");
}

- (void)thanksViewController:(AMThanksViewController *)thanksViewController didFinishWithWorkflow:(NSString *)workflow
{
    // Close the modal.
    if ([workflow isEqualToString:AMWorkflowResetToSplash])
    {
        _workflow = workflow;
        __block AMSharingViewController *this = self;
        [self dismissViewControllerAnimated:NO completion: ^{
            NSLog(@"%s", __FUNCTION__);
            id presenter = this.presentingViewController;
            if ([presenter conformsToProtocol:@protocol(SharingCompleteDelegate)])
            {
                [presenter sharingViewController:self didFinishWithWorkflow:AMWorkflowResetToSplash];
                // We needed to break the call chain here due to continual
                // access violations.
//                [presenter setWorkflow:AMWorkflowResetToSplash];

//                [self dismissViewControllerAnimated:NO completion: nil];
            }
            else
            {
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

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
//    // test if our control subview is on-screen
//    if (self.controlSubview.superview != nil) {
//        if ([touch.view isDescendantOfView:self.controlSubview]) {
//            // we touched our control surface
//            return NO; // ignore the touch
//        }
//    }
    if ([touch.view isMemberOfClass:[M13Checkbox class]])
    {
        return NO;
    }
    return YES; // handle the touch
}

- (IBAction)homeButtonTouched:(id)sender {
    
//    CTSelectSceneViewController *move = [self.storyboard instantiateViewControllerWithIdentifier:@"selectSceneViewController"];
//
//    [self presentViewController:move animated:YES completion:nil];
    
//    UIViewController *viewController;
//    viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"selectSceneViewController"];
//    [self.navigationController pushViewController:viewController animated:YES];
    
//    if (self.navigationController) {
//        NSArray *viewControllers = self.navigationController.viewControllers;
//        for (UIViewController *anVC in viewControllers) {
//            if ([anVC isKindOfClass:[CTSelectSceneViewController class] ]){
//                [self.navigationController popToViewController:anVC animated:NO];
//                break;
//            }
//        }
//    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"iAmuse" message:@"Are you sure you want to end the session?" delegate:self cancelButtonTitle:@"Yes"otherButtonTitles:@"No", nil];
    [alert show];

    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [_emailField resignFirstResponder];
        [_nameField resignFirstResponder];
        [_mobileField resignFirstResponder];
        
//        if (self.navigationController) {
//            NSArray *viewControllers = self.navigationController.viewControllers;
//            for (UIViewController *anVC in viewControllers) {
//                if ([anVC isKindOfClass:[CTSelectSceneViewController class] ]){
//                    [self.navigationController popToViewController:anVC animated:NO];
//                    break;
//                }
//            }
//        }
        
        
        [idleTimer invalidate];
        [countdownTimer invalidate];
        
        [[CTKiosk sharedInstance] backToEventScene];
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
                    break;
                }
            }
        }

        
        
        
    }
}


- (IBAction)settingsButtonTouched:(id)sender {
    
    
    
}

- (void)resetIdleTimer {
   
    
    if (!idleTimer) {
        idleTimer = [NSTimer scheduledTimerWithTimeInterval:IdleTimeSeconds
                                                     target:self
                                                   selector:@selector(idleTimerExceeded)
                                                   userInfo:nil
                                                    repeats:YES];
    }
    else {
        if (fabs([idleTimer.fireDate timeIntervalSinceNow]) < IdleTimeSeconds-1.0) {
            [idleTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:IdleTimeSeconds]];
        }
    }
}

- (void)idleTimerExceeded {
   if( idleTimer != nil)
   {
       
       
     //  [idleTimer invalidate];
   // inactiveTimer = nil;
   }
    NSLog(@"time elapased");
   // [self textchanges];
   [self.view endEditing:YES];
//    UILabel *label;
//label=[[UILabel alloc]initWithFrame:CGRectMake(10, 10, 50, 50)];
//[label setText:@"Label"];
//    [label setTextColor:[UIColor blackColor]];
//    [self.view addSubview:label];
    
    
    _popupView.hidden = NO;
    _countdownLabel.text = @"Redirecting in 10";
    _completeView.hidden = NO;
    _completeView.alpha = 0.5;
    
   
    
 //   _completeView.userInteractionEnabled=NO;
    [self resetIdleTimer];
    [self setTimer];
  
  
    
    //    CTSelectSceneViewController *move = [self.storyboard instantiateViewControllerWithIdentifier:@"selectSceneViewController"];
    //    [self presentViewController:move animated:YES completion:nil];
    
//    UIViewController *viewController;
//    viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"selectSceneViewController"];
//    [self.navigationController pushViewController:viewController animated:YES];
    
    
//    if (self.navigationController) {
//        NSArray *viewControllers = self.navigationController.viewControllers;
//        for (UIViewController *anVC in viewControllers) {
//            if ([anVC isKindOfClass:[CTSelectSceneViewController class] ]){
//                [self.navigationController popToViewController:anVC animated:NO];
//                break;
//            }
//        }
//    }
    
   
    
    //   [self resetIdleTimer];
    
    
}

-(void)textchanges
{
    [_emailField resignFirstResponder];
    [_nameField resignFirstResponder];
    [_mobileField resignFirstResponder];
}

//- (UIResponder *)nextResponder {
//
//
//     [self resetIdleTimer];
//
//    _popupView.hidden = YES;
//    _completeView.hidden = YES;
//    _completeView.alpha = 0;
////    _completeView.userInteractionEnabled = YES;
//    [countdownTimer invalidate];
//
//
//    return [super nextResponder];
//}

- (void)setTimer
{
    secondsCount=10;
    countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerRun) userInfo:nil repeats:YES];
}

- (void)timerRun
{
   
   
    
    secondsCount = secondsCount-1;
    int min = secondsCount/60;
     seconds = secondsCount - (min*60);
    NSString *timerOutput = [NSString stringWithFormat:@"Redirecting in %2d",seconds];
    _countdownLabel.text = timerOutput;
    
    
    
    
    
    if(seconds==-1)
    {
        // NSLog(@"hello");
        
        
        
        _countdownLabel.text = @"0";
        [countdownTimer invalidate];
        countdownTimer=nil;
        
        [idleTimer invalidate];
        
//        if (self.navigationController) {
//            NSArray *viewControllers = self.navigationController.viewControllers;
//            for (UIViewController *anVC in viewControllers) {
//                if ([anVC isKindOfClass:[CTSelectSceneViewController class] ]){
//                    [self.navigationController popToViewController:anVC animated:NO];
//                    break;
//                }
//            }
//        }
        
        
        [[CTKiosk sharedInstance] backToEventScene];
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
                    break;
                }
            }
        }

        
        
    }
}

//- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//    [super touchesBegan:touches withEvent:event];
//    NSLog(@"noon");
//    UITouch *touch = [[event allTouches] anyObject];
//     CGPoint location = [touch locationInView:self.view];
//
//    [self resetIdleTimer];
//
//    _popupView.hidden = YES;
//    _completeView.hidden = YES;
//    _completeView.alpha = 0;
//    //    _completeView.userInteractionEnabled = YES;
//    [countdownTimer invalidate];
//
//
//
//}


- (IBAction)checkBtnConsentAction:(id)sender {
    
    
    
    
    CTKiosk *kiosk = [CTKiosk sharedInstance];
    
    
    if(!checked1)
    {
        [_checkBtnConsent setImage:[UIImage imageNamed:@"checkbox new.png"] forState:UIControlStateNormal];
        [kiosk chooseNewsletter:M13CheckboxStateChecked];
        checked1=YES;
    }
    else if (checked1)
    {
        [_checkBtnConsent setImage:[UIImage imageNamed:@"Check box 1.png"] forState:UIControlStateNormal];
        [kiosk chooseNewsletter:M13CheckboxStateUnchecked];
        checked1=NO;
    }
    
    
    
    
    
    
    
}
- (IBAction)termsClick:(id)sender {
    
    
    
    PrivacyPolicyViewController *move = [self.storyboard instantiateViewControllerWithIdentifier:@"PrivacyPolicyViewController"];
    move.value=@"Terms";
    [self presentViewController:move animated:YES completion:nil];
    
    
    
}
@end
