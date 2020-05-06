//
//  SignInViewController.m
//  iAmuse
//
//  Created by Ravinder on 10/21/16.
//  Copyright © 2016 iAmuse Inc. All rights reserved.
//

#import "SignInViewController.h"
#import "CTAppDelegate.h"
#import "AMConstants.h"
#import "PurchaseViewController.h"
#import "MBProgressHUD.h"
#import "AMStorageManager.h"
#import "EventListViewController.h"
#import "PrivacyPolicyViewController.h"
#import "InitialViewController.h"

#import <Crashlytics/Crashlytics.h>


@interface SignInViewController ()
    @property (weak, nonatomic) IBOutlet UITextField *emailIDTextField;
    @property (weak, nonatomic) IBOutlet UITextField *passwordTextField;


    
    @end

@implementation SignInViewController

bool checked;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    
//    UIButton* button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//    button.frame = CGRectMake(20, 50, 100, 30);
//    [button setTitle:@"Crash" forState:UIControlStateNormal];
//    [button addTarget:self action:@selector(crashButtonTapped:)
//     forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:button];
//    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleGoogle:)
                                                 name:@"google"
                                               object:nil];
    
    
    _signInButton1.style = kGIDSignInButtonStyleWide;
    _signInButton1.colorScheme = kGIDSignInButtonColorSchemeDark;
    
    [GIDSignIn sharedInstance].uiDelegate = self;
    
    
    _signInButton.layer.cornerRadius = 3; // this value vary as per your desire
    _signInButton.clipsToBounds = YES;
    
    
    _googleButton.layer.cornerRadius = 3; // this value vary as per your desire
    _googleButton.clipsToBounds = YES;
    
    
    _signInWithGoogleButton.layer.cornerRadius = 3; // this value vary as per your desire
    _signInWithGoogleButton.clipsToBounds = YES;
    
    checked = NO;
    //adding the border to the textfield
    
    _emailIDTextField.layer.borderColor = [UIColor colorWithRed:0/255.0 green:121/255.0 blue:15/255.0 alpha:1.0].CGColor;
    _emailIDTextField.layer.borderWidth = 2.0;
    
    _passwordTextField.layer.borderColor = [UIColor colorWithRed:0/255.0 green:121/255.0 blue:15/255.0 alpha:1.0].CGColor;
    _passwordTextField.layer.borderWidth=2.0;
    
    // Do any additional setup after loading the view.
    self.navigationController.navigationBarHidden = YES;
    [self setLeftPaddingInTextField:_emailIDTextField];
    [self setLeftPaddingInTextField:_passwordTextField];
    // NSAssert(NO, @"Shiv");
}
    
- (void)setLeftPaddingInTextField:(UITextField *)textField
    {
        UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
        textField.leftView = paddingView;
        textField.leftViewMode = UITextFieldViewModeAlways;
    }
    
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
    
-(BOOL)shouldAutorotate
    {
        return NO;
    }
    
-(UIInterfaceOrientationMask)supportedInterfaceOrientations
    {
        if((UI_USER_INTERFACE_IDIOM()) == UIUserInterfaceIdiomPhone)
        {
            return UIInterfaceOrientationMaskPortrait;
        }
        else
        {
            return UIInterfaceOrientationLandscapeLeft | UIInterfaceOrientationLandscapeRight;
        }
    }
    


// new code by ajay
- (IBAction)signInButtonTapped:(UIButton *)sender {

    if([self isEmpty:_emailIDTextField.text])
    {
        [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"email field is blank" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
    }
    else if(![self validateEmailWithString:_emailIDTextField.text])
    {
        [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Invalid email format" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;

    }
    else if ([self isEmpty:_passwordTextField.text])
    {
        [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"password field is blank" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
    }
    
    
   
//    [FIRAnalytics logEventWithName:kFIREventSelectContent
//                        parameters:@{
//                                     kFIRParameterItemID:[NSString stringWithFormat:@"id-%@", @"test"],
//                                     kFIRParameterItemName:_emailIDTextField,
//                                     kFIRParameterContentType:@"Login"
//                                     }];
    
    
    [FIRAnalytics logEventWithName:kFIREventLogin
                        parameters:@{
                                     kFIRParameterItemName: @"Email"
                                     }];
    
    
    
    
    WebCommunication *webComm = [[WebCommunication alloc] initWithServiceType:1];

    NSMutableDictionary *mutableDic = [[NSMutableDictionary alloc] init];
    [mutableDic setObject:_emailIDTextField.text forKey:@"emailId"];
    [mutableDic setObject:_passwordTextField.text forKey:@"password"];
    NSURL *serviceUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@loginAdminBooth",kAMBaseURL]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.passwordTextField resignFirstResponder];
        [self.emailIDTextField resignFirstResponder];
    });
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [webComm callToServerRequestDictionary:mutableDic onURL:serviceUrl WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        if (!error)
        {
            NSLog(@"%ld, %@",(long)status_code,response);
            if (![response[@"responseCode"] isKindOfClass:[NSNull class]])
            {
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
                    [[NSUserDefaults standardUserDefaults] setObject:response[@"boothAdminLoginResponse"][@"userId"] forKey:@"userId"];
                    
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
                        if ([response[@"subscriptionMasterList"] count]) {
                            
                            NSString *subId = [NSString stringWithFormat:@"%@",[response[@"subscriptionMasterList"] firstObject][@"subId"]];
                        
                        
                            NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
                            
                            if ([subId isEqualToString:@"3"] && ![[response[@"subscriptionMasterList"] firstObject][@"is_annual"] isKindOfClass:[NSNull class]])
                             {
                                 [defaults setObject:@"4" forKey:@"subscriptionType"];
                             }
                            
                            else
                            {
                            
                            [defaults setObject:subId forKey:@"subscriptionType"];
                            
                            }
                            
                            
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
                        if ([response[@"subscriptionMasterList"] count]) {
                            NSString *subId = [NSString stringWithFormat:@"%@",[response[@"subscriptionMasterList"] firstObject][@"subId"]];
                            
                            NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
                            
                            
                            
                            
                            
                            
                            
                            if ([subId isEqualToString:@"3"] && ![[response[@"subscriptionMasterList"] firstObject][@"is_annual"] isKindOfClass:[NSNull class]])
                            {
                                [defaults setObject:@"4" forKey:@"subscriptionType"];
                            }
                            
                            else
                            {
                                
                                [defaults setObject:subId forKey:@"subscriptionType"];
                                
                            }
                            
                            NSLog(@"subid is %@",subId);
                            
                            
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
                        else
                        {
                            EventListViewController *eventController = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([EventListViewController class])];
                            [eventController setSubscriptionId:@"1"];
                            [self.navigationController pushViewController:eventController animated:YES];
                        }

                    }

                }
            }
        }
        else
        {
            NSLog(@"%@",error);
            [[[UIAlertView alloc] initWithTitle:@"Alert" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];

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
        [_checkBoxButton setImage:[UIImage imageNamed:@"check.png"] forState:UIControlStateNormal];
        checked = YES;
    }
    
    else if (checked)
    {
        [_checkBoxButton setImage:[UIImage imageNamed:@"uncheck.png"] forState:UIControlStateNormal];
        checked = NO;
    }
    
}
- (IBAction)termsBtnClicked:(id)sender {
    
    PrivacyPolicyViewController *move = [self.storyboard instantiateViewControllerWithIdentifier:@"PrivacyPolicyViewController"];
    [self presentViewController:move animated:YES completion:nil];
    
//    UIViewController *viewController;
//
//    viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PrivacyPolicyViewController"];
//    [self.navigationController pushViewController:viewController animated:YES];
    
    
}


- (void)handleGoogle:(NSNotification *)notification
{
    NSLog(@"Ajay");
     [[NSNotificationCenter defaultCenter] removeObserver:self name:@"google" object:nil];
    
    CTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    //NSString *token = appDelegate.userId;
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * result = [defaults stringForKey:@"name"];
     NSString * result1 = [defaults stringForKey:@"token"];
     NSString * result2 = [defaults stringForKey:@"mail"];
     NSLog(@"name is %@",result);
    NSLog(@"token is %@",result1);
    NSLog(@"email is is %@",result2);
    NSString *name = [NSString stringWithFormat:@"%@",appDelegate.fullName];
//     NSLog(@"name is %@",name);
    NSString *email = appDelegate.email;
    NSLog(@"email is %@",email);
    
    if(result==nil || [result isEqualToString:@""])
    {
        result=@"";
        result1=@"";
        result2=@"";
    }
    
    NSMutableDictionary *mutableDic = [[NSMutableDictionary alloc] init];
    [mutableDic setObject:result1 forKey:@"accesstoken"];
    [mutableDic setObject:result forKey:@"username"];
    [mutableDic setObject:result2 forKey:@"emailId"];
    
    
    WebCommunication *webComm = [[WebCommunication alloc] initWithServiceType:1];
    
    
    
    NSURL *serviceUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"http://iamuses.eastus.cloudapp.azure.com:8080/iamuseserver_internal/v1/iamuse/signInGmail"]];
    
//     NSURL *serviceUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"http://192.168.2.33:8000/iamuseserver_internal/v1/iamuse/signInGmail"]];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [webComm callToServerRequestDictionary:mutableDic onURL:serviceUrl WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        if (!error)
        {
            NSLog(@"%ld, %@",(long)status_code,response);
            if (![response[@"responseCode"] isKindOfClass:[NSNull class]])
            {
               // if ([[response objectForKey:@"responseCode"] integerValue] != 1)
                if ([response[@"boothAdminLoginResponse"] isKindOfClass:[NSNull class]])
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
                    [[NSUserDefaults standardUserDefaults] setObject:response[@"boothAdminLoginResponse"][@"userId"] forKey:@"userId"];
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
                        if ([response[@"subscriptionMasterList"] count]) {
                            
                            NSString *subId = [NSString stringWithFormat:@"%@",[response[@"subscriptionMasterList"] firstObject][@"subId"]];
                            
                            
                            if ([subId isEqualToString:@"3"] && ![[response[@"subscriptionMasterList"] firstObject][@"is_annual"] isKindOfClass:[NSNull class]])
                            {
                                [defaults setObject:@"4" forKey:@"subscriptionType"];
                            }
                            
                            else
                            {
                                
                                [defaults setObject:subId forKey:@"subscriptionType"];
                                
                            }
                            
                            
                            
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
                        if ([response[@"subscriptionMasterList"] count]) {
                            NSString *subId = [NSString stringWithFormat:@"%@",[response[@"subscriptionMasterList"] firstObject][@"subId"]];
                            
                            
                            if ([subId isEqualToString:@"3"] && ![[response[@"subscriptionMasterList"] firstObject][@"is_annual"] isKindOfClass:[NSNull class]])
                            {
                                [defaults setObject:@"4" forKey:@"subscriptionType"];
                            }
                            
                            else
                            {
                                
                                [defaults setObject:subId forKey:@"subscriptionType"];
                                
                            }
                            
                            
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
                        else
                        {
                            EventListViewController *eventController = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([EventListViewController class])];
                            [eventController setSubscriptionId:@"1"];
                            [self.navigationController pushViewController:eventController animated:YES];
                        }
                        
                    }
                    
                }
            }
        }
        else
        {
            NSLog(@"%@",error);
            [[[UIAlertView alloc] initWithTitle:@"Alert" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            
        }
        
    }];

    
}


-(NSString *)checkValueAgainstNull : (NSString *) forKey inDictionary : (NSDictionary *) dict{
    if ([dict[forKey] isKindOfClass:[NSNull class]])
    {
        return @"";
    }
    else return dict[forKey];
}


//- (IBAction)crashButtonTapped:(id)sender {
//    [[Crashlytics sharedInstance] crash];
//}



@end

