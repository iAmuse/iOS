//
//  SignUpViewController.m
//  iAmuse
//
//  Created by Ravinder on 10/21/16.
//  Copyright © 2016 iAmuse Inc. All rights reserved.
//

#import "SignUpViewController.h"
#import "AMConstants.h"
#import "PurchaseViewController.h"
#import "MBProgressHUD.h"
#import "AMStorageManager.h"
#import "EventListViewController.h"
#import "MLKMenuPopover.h"
#import "CTAppDelegate.h"
#import "PrivacyPolicyViewController.h"
#import "SignInViewController.h"
#import "InitialViewController.h"
#import "Terms&ConditionVC.h"
#import "TermsAndConditionViewController.h"

@interface SignUpViewController ()<MLKMenuPopoverDelegate>
    {
        NSArray *contentArray;
       
    }
    @property (weak, nonatomic) IBOutlet UITextField *nameTextField;
    @property (weak, nonatomic) IBOutlet UITextField *emailIDTextField;
    @property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
    @property (weak, nonatomic) IBOutlet UITextField *userTypeTextField;
@property (weak, nonatomic) IBOutlet UITextField *phoneTextField;
@property (weak, nonatomic) IBOutlet UITextField *pinTextField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameTextField;



    @end

@implementation SignUpViewController

bool checked;
    
- (void)viewDidLoad {
    [super viewDidLoad];
    
    
   
    
    [_userTypeButton setTitle:@"User Type" forState:UIControlStateNormal];
    
    _userTypeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    
    [_userTypeButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    
    _userTypeButton.contentEdgeInsets = UIEdgeInsetsMake(0, 15, 0, 0);
    
    
    
    
    _signUpButton.layer.cornerRadius = 3; // this value vary as per your desire
    _signUpButton.clipsToBounds = YES;

    self.pinTextField.delegate=self;
    
    checked = NO;
    
    //adding the border to the textfield
    
    _nameTextField.layer.borderColor = [UIColor colorWithRed:0/255.0 green:121/255.0 blue:15/255.0 alpha:1.0].CGColor;
    _nameTextField.layer.borderWidth=2.0f;
    
    _emailIDTextField.layer.borderColor = [UIColor colorWithRed:0/255.0 green:121/255.0 blue:15/255.0 alpha:1.0].CGColor;
    _emailIDTextField.layer.borderWidth = 2.0f;
    
    _passwordTextField.layer.borderColor = [UIColor colorWithRed:0/255.0 green:121/255.0 blue:15/255.0 alpha:1.0].CGColor;
    _passwordTextField.layer.borderWidth = 2.0f;
    
    _userTypeTextField.layer.borderColor = [UIColor colorWithRed:0/255.0 green:121/255.0 blue:15/255.0 alpha:1.0].CGColor;
    _userTypeTextField.layer.borderWidth = 2.0f;
    
    
    _phoneTextField.layer.borderColor = [UIColor colorWithRed:0/255.0 green:121/255.0 blue:15/255.0 alpha:1.0].CGColor;
    _phoneTextField.layer.borderWidth = 2.0f;
    
    _lastNameTextField.layer.borderColor = [UIColor colorWithRed:0/255.0 green:121/255.0 blue:15/255.0 alpha:1.0].CGColor;
    _lastNameTextField.layer.borderWidth = 2.0f;
    
    _pinTextField.layer.borderColor = [UIColor colorWithRed:0/255.0 green:121/255.0 blue:15/255.0 alpha:1.0].CGColor;
    _pinTextField.layer.borderWidth = 2.0f;
    
    _userTypeButton.layer.borderWidth=2.0f;
    _userTypeButton.layer.borderColor=[UIColor colorWithRed:0/255.0 green:121/255.0 blue:15/255.0 alpha:1.0].CGColor;
    // Do any additional setup after loading the view.
    self.navigationController.navigationBarHidden = YES;
    [self setLeftPaddingInTextField:_emailIDTextField];
    [self setLeftPaddingInTextField:_passwordTextField];
    [self setLeftPaddingInTextField:_nameTextField];
    [self setLeftPaddingInTextField:_userTypeTextField];
    [self setLeftPaddingInTextField:_phoneTextField];
    [self setLeftPaddingInTextField:_lastNameTextField];
    [self setLeftPaddingInTextField:_pinTextField];
}
    
- (void)setLeftPaddingInTextField:(UITextField *)textField
    {
        UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
        textField.leftView = paddingView;
        textField.leftViewMode = UITextFieldViewModeAlways;
    }
    
- (IBAction)selectUserType:(UIButton *)sender {
//    contentArray = @[@"Personal",@"Professional"];
    contentArray = @[@"Prefer Not to Say",@"Do-It-Yourself",@"Event Professional",@"Tradeshow",@"Tourism",@"Venue"];
    CGRect frame = sender.frame;
    frame.origin.y = frame.origin.y + frame.size.height;
    frame.size.height = 120;
    MLKMenuPopover *menu = [[MLKMenuPopover alloc] initWithFrame:frame menuItems:contentArray];
    [menu setBackgroundColor:[UIColor whiteColor]];
    menu.menuPopoverDelegate = self;
    menu.tag = sender.tag;
   
  //  menu.backgroundColor = [UIColor redColor];
   
    [menu showInView:self.contentView];
}
    
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
    
#pragma mark - MLKMenuPopover delegate methods.
    
- (void)menuPopover:(MLKMenuPopover *)menuPopover didSelectMenuItemAtIndex:(NSInteger)selectedIndex
    {
        [menuPopover dismissMenuPopover];
        self.userTypeTextField.text = contentArray[selectedIndex];
        NSString *str;
        str = contentArray[selectedIndex];
        [_userTypeButton setTitle:str forState:UIControlStateNormal];
      
        
        _userTypeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        
        [_userTypeButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        
        _userTypeButton.contentEdgeInsets = UIEdgeInsetsMake(0, 15, 0, 0);
    }
    
-(void) didDismissMenuPopover
    {
    }
    
- (IBAction)signIn:(id)sender {
  //  [self.navigationController popViewControllerAnimated:YES];
    
    SignInViewController *move = [self.storyboard instantiateViewControllerWithIdentifier:@"SignInViewController"];
    [self presentViewController:move animated:YES completion:nil];
  
    
}
    
//- (IBAction)signUpButtonTapped:(UIButton *)sender {
//
//    if([self isEmpty:_emailIDTextField.text])
//    {
//        [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"email field is blank" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
//        return;
//    }
//    else if(![self validateEmailWithString:_emailIDTextField.text])
//    {
//        [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"invalid email format" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
//        return;
//
//    }
//    else if ([self isEmpty:_passwordTextField.text])
//    {
//        [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"password field is blank" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
//        return;
//    }
//    else if ([self isEmpty:_nameTextField.text])
//    {
//        [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"name field is blank" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
//        return;
//    }
//    else if ([self isEmpty:_userTypeTextField.text])
//    {
//        [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"user type field is blank" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
//        return;
//    }
//    else if (checked==NO)
//    {
//        [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Please agree to the terms and conditions" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
//        return;
//    }
//    WebCommunication *webComm = [[WebCommunication alloc] initWithServiceType:1];
//
//    NSMutableDictionary *mutableDic = [[NSMutableDictionary alloc] initWithObjectsAndKeys:_nameTextField.text,@"userName",_emailIDTextField.text,@"emailId",_passwordTextField.text,@"password",_userTypeTextField.text,@"userType", nil];
//    NSURL *serviceUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/registrationAdminBooth",kAMBaseURL]];
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.passwordTextField resignFirstResponder];
//        [self.emailIDTextField resignFirstResponder];
//        [self.nameTextField resignFirstResponder];
//        [self.userTypeTextField resignFirstResponder];
//    });
//    CTAppDelegate *delegate = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
//    //    [MBProgressHUD showHUDAddedTo:delegate.window animated:YES];
//    [webComm callToServerRequestDictionary:mutableDic onURL:serviceUrl WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm) {
//        //        [MBProgressHUD hideHUDForView:delegate.window animated:YES];
//        if (!error)
//        {
//            NSLog(@"%ld, %@",(long)status_code,response);
//            if ([[response objectForKey:@"responseCode"] integerValue] != 1)
//            {
//                if ([response objectForKey:@"responseDescription"]) {
//                    [[[UIAlertView alloc] initWithTitle:@"Alert" message:[response objectForKey:@"responseDescription"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
//                }
//                else
//                {
//                    [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Something went wrong" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
//                }
//            }
//            else
//            {
//                [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%@", response[@"boothAdminLoginResponse"][@"userId"]] forKey:@"userId"];
//                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isLogin"];
//                [[NSUserDefaults standardUserDefaults] synchronize];
//                AMStorageManager *manager = [AMStorageManager sharedInstance];
//                NSManagedObject *fovObject = [NSEntityDescription insertNewObjectForEntityForName:@"FOVData"
//                                                                           inManagedObjectContext:manager.currentMOC];
//                if (![response[@"boothAdminLoginResponse"][@"fovLeft"] isKindOfClass:[NSNull class]])
//                {
//                    [fovObject setValue:response[@"boothAdminLoginResponse"][@"fovLeft"] forKey:@"fovLeft"];
//                    [fovObject setValue:response[@"boothAdminLoginResponse"][@"fovRight"] forKey:@"fovRight"];
//                    [fovObject setValue:response[@"boothAdminLoginResponse"][@"fovTop"] forKey:@"fovTop"];
//                    [fovObject setValue:response[@"boothAdminLoginResponse"][@"fovBottom"] forKey:@"fovBottom"];
//                }
//                if (![response[@"boothAdminLoginResponse"][@"greenScreenHeight"] isKindOfClass:[NSNull class]])
//                {
//                    [fovObject setValue:response[@"boothAdminLoginResponse"][@"greenScreenHeight"] forKey:@"greenScreenHeight"];
//                    [fovObject setValue:response[@"boothAdminLoginResponse"][@"greenScreenWidth"] forKey:@"greenScreenWidth"];
//                }
//
//                NSError *error1;
//                if (![manager.currentMOC save:&error1]) {
//                    NSLog(@"Failed to save - error: %@", [error1 localizedDescription]);
//                }
//
//                NSUserDefaults * userdefault = [NSUserDefaults standardUserDefaults];
//                NSString * deviceModePref = [userdefault stringForKey:AMDeviceModeSettingsKey];
//                if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
//                {
//                    EventListViewController *eventController = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([EventListViewController class])];
//                    [self.navigationController pushViewController:eventController animated:YES];
//                }
//                else
//                {
//                    // if ([response[@"subscriptionMasterList"] count]) {
//                    // NSString *subId = [NSString stringWithFormat:@"%@",[response[@"subscriptionMasterList"] firstObject][@"subId"]];
//                    //  if ([subId isEqualToString:@"1"])
//                    {
//                      //  PrivacyPolicyViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([PrivacyPolicyViewController class])];
//                    //    [self.navigationController pushViewController:controller animated:YES];
//
//
//
//                        PurchaseViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([PurchaseViewController class])];
//                        [self.navigationController pushViewController:controller animated:YES];
//
//                    }
//                    /*  else
//                     {
//                     EventListViewController *eventController = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([EventListViewController class])];
//                     [eventController setSubscriptionId:[response[@"subscriptionMasterList"] firstObject][@"subId"]];
//                     [self.navigationController pushViewController:eventController animated:YES];
//                     }
//                     }
//                     else
//                     {
//                     EventListViewController *eventController = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([EventListViewController class])];
//                     [eventController setSubscriptionId:@"1"];
//                     [self.navigationController pushViewController:eventController animated:YES];
//                     }*/
//
//                }
//            }
//        }
//        else
//        {
//            NSLog(@"%@",error);
//        }
//    }];
//}



- (IBAction)signUpButtonTapped:(UIButton *)sender
{
    
    if([self isEmpty:_emailIDTextField.text])
    {
        [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"email field is blank" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
    }
    else if(![self validateEmailWithString:_emailIDTextField.text])
    {
        [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"invalid email format" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
        
    }
    
    else if(!([self validatPhone:_phoneTextField.text])) {
        
        [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Please enter a valid cell phone number" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
        
    }
    
    
    else if(!([self validatPhoneCount:_phoneTextField.text])) {
        
        [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Please enter a valid cell phone number" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
        
    }
    
    
    
    
    else if ([self isEmpty:_passwordTextField.text])
    {
        [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"password field is blank" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
    }
    else if ([self isEmpty:_nameTextField.text])
    {
        [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"name field is blank" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
    }
    
    
    else if(!([self validatPin:_pinTextField.text])) {
        
        [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Please enter only numeric data for the pin" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
        
    }
    
    else if(!([self validatPinCount:_pinTextField.text])) {
        
        [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Please enter four digits pin" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
        
    }
    
    
   
    
    
    
    else if ([self isEmpty:_userTypeTextField.text])
    {
        [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"user type field is blank" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
    }
    
    
    [FIRAnalytics logEventWithName:kFIREventSignUp
                        parameters:@{
                                     kFIRParameterItemName: @"Email"
                                     }];
    
    
    
    
    WebCommunication *webComm = [[WebCommunication alloc] initWithServiceType:1];
    
    NSMutableDictionary *mutableDic = [[NSMutableDictionary alloc] initWithObjectsAndKeys:_nameTextField.text,@"userName",_emailIDTextField.text,@"emailId",_passwordTextField.text,@"password",_userTypeTextField.text,@"userType",_phoneTextField.text,@"contactNumber",_lastNameTextField.text,@"lastname",_pinTextField.text,@"pin", nil];
    NSURL *serviceUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/registrationAdminBooth",kAMBaseURL]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.passwordTextField resignFirstResponder];
        [self.emailIDTextField resignFirstResponder];
        [self.nameTextField resignFirstResponder];
        [self.userTypeTextField resignFirstResponder];
    });
    CTAppDelegate *delegate = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
        [MBProgressHUD showHUDAddedTo:delegate.window animated:YES];
    [webComm callToServerRequestDictionary:mutableDic onURL:serviceUrl WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm) {
                [MBProgressHUD hideHUDForView:delegate.window animated:YES];
        if (!error)
        {
            NSLog(@"%ld, %@",(long)status_code,response);
            if ([[response objectForKey:@"responseCode"] integerValue] != 1)
            {
                if ([response objectForKey:@"responseDescription"]) {
                    [[[UIAlertView alloc] initWithTitle:@"Alert" message:[response objectForKey:@"responseDescription"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                }
                else
                {
                    [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Something went wrong" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                }
            }
            else
            {
                [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%@", response[@"boothAdminLoginResponse"][@"userId"]] forKey:@"userId"];
                
                
                [[NSUserDefaults standardUserDefaults] setObject:response[@"boothAdminLoginResponse"][@"username"] forKey:@"username"];
                
                
                if (![response[@"boothAdminLoginResponse"][@"lastname"] isKindOfClass:[NSNull class]])
                {
                    
                    [[NSUserDefaults standardUserDefaults] setObject:response[@"boothAdminLoginResponse"][@"lastname"] forKey:@"lastname"];
                    
                }
                else
                {
                    [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"lastname"];
                }
                
                [[NSUserDefaults standardUserDefaults] setObject:response[@"boothAdminLoginResponse"][@"emailId"] forKey:@"logemailId"];
                
                
                
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isLogin"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                AMStorageManager *manager = [AMStorageManager sharedInstance];
                NSManagedObject *fovObject = [NSEntityDescription insertNewObjectForEntityForName:@"FOVData"
                                                                           inManagedObjectContext:manager.currentMOC];
                if (![response[@"boothAdminLoginResponse"][@"fovLeft"] isKindOfClass:[NSNull class]])
                {
                    [fovObject setValue:response[@"boothAdminLoginResponse"][@"fovLeft"] forKey:@"fovLeft"];
                    [fovObject setValue:response[@"boothAdminLoginResponse"][@"fovRight"] forKey:@"fovRight"];
                    [fovObject setValue:response[@"boothAdminLoginResponse"][@"fovTop"] forKey:@"fovTop"];
                    [fovObject setValue:response[@"boothAdminLoginResponse"][@"fovBottom"] forKey:@"fovBottom"];
                }
                if (![response[@"boothAdminLoginResponse"][@"greenScreenHeight"] isKindOfClass:[NSNull class]])
                {
                    [fovObject setValue:response[@"boothAdminLoginResponse"][@"greenScreenHeight"] forKey:@"greenScreenHeight"];
                    [fovObject setValue:response[@"boothAdminLoginResponse"][@"greenScreenWidth"] forKey:@"greenScreenWidth"];
                }
                
                NSError *error1;
                if (![manager.currentMOC save:&error1]) {
                    NSLog(@"Failed to save - error: %@", [error1 localizedDescription]);
                }
                
                NSUserDefaults * userdefault = [NSUserDefaults standardUserDefaults];
                NSString * deviceModePref = [userdefault stringForKey:AMDeviceModeSettingsKey];
                if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
                {
//                    EventListViewController *eventController = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([EventListViewController class])];
//                    [self.navigationController pushViewController:eventController animated:YES];
                    
                    
                    if ([response[@"subscriptionMasterList"] count]) {
                        
                        NSString *subId = [NSString stringWithFormat:@"%@",[response[@"subscriptionMasterList"] firstObject][@"subId"]];
                        
                        
                        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
                        [defaults setObject:subId forKey:@"subscriptionType"];
                        
                        if ([subId isEqualToString:@"1"])
                        {
                            UIStoryboard *storyboard;
                            storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
                            PurchaseViewController *eventController = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([PurchaseViewController class])];
                            [self.navigationController pushViewController:eventController animated:YES];
                        }
                        else
                        {
                            
                            EventListViewController *eventController = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([EventListViewController class])];
                            [self.navigationController pushViewController:eventController animated:YES];
                        }
                    }

                    
                    
                }
                else
                {
                    // if ([response[@"subscriptionMasterList"] count]) {
                    // NSString *subId = [NSString stringWithFormat:@"%@",[response[@"subscriptionMasterList"] firstObject][@"subId"]];
                    //  if ([subId isEqualToString:@"1"])
//                    {
//                      //  PrivacyPolicyViewController *eventController = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([PrivacyPolicyViewController class])];
//                         PurchaseViewController *eventController = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([PurchaseViewController class])];
//                        [self.navigationController pushViewController:eventController animated:YES];
//                    }
                    
                    if ([response[@"subscriptionMasterList"] count]) {
                        NSString *subId = [NSString stringWithFormat:@"%@",[response[@"subscriptionMasterList"] firstObject][@"subId"]];
                        
                        
                        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
                        [defaults setObject:subId forKey:@"subscriptionType"];
                        
                        if ([subId isEqualToString:@"1"])
                        {
                            PurchaseViewController *eventController = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([PurchaseViewController class])];
                            [self.navigationController pushViewController:eventController animated:YES];
                        }
                        else
                        {
                            EventListViewController *eventController = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([EventListViewController class])];
                            [eventController setSubscriptionId:subId];
                            [self.navigationController pushViewController:eventController animated:YES];
                        }
                    }
                    
                    
                    /*  else
                     {
                     EventListViewController *eventController = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([EventListViewController class])];
                     [eventController setSubscriptionId:[response[@"subscriptionMasterList"] firstObject][@"subId"]];
                     [self.navigationController pushViewController:eventController animated:YES];
                     }
                     }
                     else
                     {
                     EventListViewController *eventController = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([EventListViewController class])];
                     [eventController setSubscriptionId:@"1"];
                     [self.navigationController pushViewController:eventController animated:YES];
                     }*/
                    
                }
            }
        }
        else
        {
            NSLog(@"%@",error);
        }
    }];
}


- (BOOL)validateEmailWithString:(NSString*)email
    {
        NSString *emailFormat = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
        NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailFormat];
        return [emailTest evaluateWithObject:email];
    }
    
- (BOOL)isEmpty:(NSString *)text
    {
        if ([text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0)
        return YES;
        else
        return NO;
    }
    
- (IBAction)checkBoxButtonClicked:(id)sender {
    
    if(!checked)
    {
        [_checkBoxButton setImage:[UIImage imageNamed:@"checkbox new.png"] forState:UIControlStateNormal];
        checked = YES;
    }
    
    else if (checked)
    {
        
        [_checkBoxButton setImage:[UIImage imageNamed:@"Check box 1.png"] forState:UIControlStateNormal];
        checked = NO;
        
    }
    
    
}
- (IBAction)termsBtnClicked:(id)sender {
    
    PrivacyPolicyViewController *move = [self.storyboard instantiateViewControllerWithIdentifier:@"PrivacyPolicyViewController"];
    move.value=@"Terms";
    [self presentViewController:move animated:YES completion:nil];
}


//- (IBAction)privacyPolicyAction:(id)sender {
//    
//    
//    Terms_ConditionVC *move = [self.storyboard instantiateViewControllerWithIdentifier:@"Terms&ConditionVC"];
//    [self presentViewController:move animated:YES completion:nil];
//    
//}
- (IBAction)privacyPolicyBtnAction:(id)sender {
    
//    Terms_ConditionVC *move = [self.storyboard instantiateViewControllerWithIdentifier:@"Terms&ConditionVC"];
//    [self presentViewController:move animated:YES completion:nil];
    
    
    PrivacyPolicyViewController *move = [self.storyboard instantiateViewControllerWithIdentifier:@"PrivacyPolicyViewController"];
    move.value=@"Privacypolicy";
    [self presentViewController:move animated:YES completion:nil];
    
    
    
}

- (IBAction)backButtonAction:(id)sender {
    
    SignInViewController *move = [self.storyboard instantiateViewControllerWithIdentifier:@"SignInViewController"];
    [self presentViewController:move animated:YES completion:nil];
    
    
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *currentString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    int length = [currentString length];
    if (length > 4) {
        return NO;
    }
    return YES;
}

//-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
//{
//    /*  limit to only numeric characters  */
//    NSCharacterSet *myCharSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
//    for (int i = 0; i < [string length]; i++) {
//        unichar c = [string characterAtIndex:i];
//        if ([myCharSet characterIsMember:c]) {
//            return YES;
//        }
//    }
//
//    /*  limit the users input to only 9 characters  */
//    NSUInteger newLength = [textField.text length] + [string length] - range.length;
//    return (newLength > 9) ? NO : YES;
//}

- (BOOL)validatPin:(NSString*)pin
{
    NSString *PinRegex = @"(^[0-9]+$)";
    NSPredicate *PinTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", PinRegex];
    return [PinTest evaluateWithObject:pin];
}

- (BOOL)validatPinCount:(NSString*)Pin
{
    BOOL returnValue = false;
    
    if (Pin.length == 4)
    {
        returnValue = true;
        return returnValue;
    }
    
    return returnValue;
}

- (BOOL)validatPhone:(NSString*)pin
{
    NSString *PinRegex = @"(^[0-9]+$)";
    NSPredicate *PinTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", PinRegex];
    return [PinTest evaluateWithObject:pin];
}

- (BOOL)validatPhoneCount:(NSString*)Pin
{
    BOOL returnValue = false;
    
    if (Pin.length == 10)
    {
        returnValue = true;
        return returnValue;
    }
    
    return returnValue;
}

@end

