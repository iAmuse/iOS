//
//  PurchaseViewController.m
//  AppPerchaseDemo
//
//  Created by apple on 26/10/16.
//  Copyright © 2016 Foofi. All rights reserved.
//

#import "PurchaseViewController.h"
#import "WebCommunication.h"
#import "MBProgressHUD.h"
#import "AMConstants.h"
#import "EventListViewController.h"
#import "SetUpStepsViewController.h"
#import "CTSettingsViewController.h"
#import "PrivacyPolicyViewController.h"
#import "CTKiosk.h"

typedef enum : NSUInteger {
    OneDaySubscription = 101,
    OneYearSubscription = 102,
    OneMonthSubscription = 103,
} SubscriptionType;

@interface PurchaseViewController ()
{
    NSDictionary *subscriptionDetails;
    NSString *subscriptionType;
    
    
    
}
@end

@implementation PurchaseViewController
@synthesize request;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    self.completeView.hidden=YES;
    self.popupView.hidden=YES;
    
    
    UITapGestureRecognizer *singleFingerTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(handleSingleTap:)];
    [self.completeView addGestureRecognizer:singleFingerTap];

    
    
    
   // UIColor *bgcolour = [ colorWithHexString:@"F13982"];
    
    _freeView.layer.borderColor = [UIColor colorWithRed:0/255.0 green:121/255.0 blue:15/255.0 alpha:1.0].CGColor;
    _freeView.layer.borderWidth = 2.0f;
    
    _oneDaySubscriptionView.layer.borderColor = [UIColor colorWithRed:0/255.0 green:121/255.0 blue:15/255.0 alpha:1.0].CGColor;
    _oneDaySubscriptionView.layer.borderWidth = 2.0f;
    
    _oneMonthSubscriptionView.layer.borderColor = [UIColor colorWithRed:0/255.0 green:121/255.0 blue:15/255.0 alpha:1.0].CGColor;
    _oneMonthSubscriptionView.layer.borderWidth = 2.0f;
    
    _customUploadView.layer.borderColor = [UIColor colorWithRed:0/255.0 green:121/255.0 blue:15/255.0 alpha:1.0].CGColor;
    _customUploadView.layer.borderWidth = 2.0f;
    
    
    _backButton.hidden=YES;
    
    
    id thePresenter = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count - 2];

    // and test its class
    if ([thePresenter isKindOfClass:[CTSettingsViewController class]]) {
        // do this
        _nextButton.hidden=YES;
        _backButton.hidden=NO;
    }
    
    _nextButton.layer.cornerRadius = 3; // this value vary as per your desire
    _nextButton.clipsToBounds = YES;
    
    
    
    _popupView.layer.borderColor = [UIColor colorWithRed:0/255.0 green:121/255.0 blue:15/255.0 alpha:1.0].CGColor;
    _popupView.layer.borderWidth = 2.0f;
    
    
    
    
    
    
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (_isShowingFromSetting) {
        [_nextButton setHidden:YES];
    }
    [self getSubscriptionDetail];
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
                [[[UIAlertView alloc] initWithTitle:@"Alert" message:[response objectForKey:@"responseDescription"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                
            }
            else
            {
                subscriptionDetails = response;
               // NSString *subId = [subscriptionDetails objectForKey:@"subId"];
                NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
                 NSString * subId = [defaults stringForKey:@"subscriptionType"];
                if ([subId integerValue] == 1)
                {
                   // [self setBorderForSelectedSubscriptionView:self.freeView];
                    
                    _freeSubscriptionButton.hidden=NO;
                    
                    _lblTitle.text=@"Upgrade from Free trial to unlock all features!";
                   
                    
                    
                    _freeSubscriptionButton.backgroundColor=[UIColor colorWithRed:252/255.0 green:167/255.0 blue:8/255.0 alpha:1.0];
                  //  _freeSubscriptionButton.layer.borderColor = [UIColor colorWithRed:0/255.0 green:121/255.0 blue:15/255.0 alpha:1.0].CGColor;
                  //  _freeSubscriptionButton.layer.borderWidth = 2.0f;
                    
                }
                else if ([subId integerValue] == 2)
                {
                    [self.oneDaySubscribeBtn setTitle:@"Your Current Plan" forState:UIControlStateNormal];
                    _freeSubscriptionButton.hidden=YES;
                    
                     _lblTitle.text=@"Enjoy your paid version of iAmuse!";
                    
                    _oneDaySubscribeBtn.backgroundColor=[UIColor colorWithRed:252/255.0 green:167/255.0 blue:8/255.0 alpha:1.0];
                 //   _oneDaySubscribeBtn.layer.borderColor = [UIColor colorWithRed:0/255.0 green:121/255.0 blue:15/255.0 alpha:1.0].CGColor;
                 //   _oneDaySubscribeBtn.layer.borderWidth = 2.0f;
                    
                  //  [self setBorderForSelectedSubscriptionView:self.oneDaySubscriptionView];
                }
                else if ([subId integerValue] == 3)
                {
                  [self.customSubscriptionButton setTitle:@"Your Current Plan" forState:UIControlStateNormal];
                    _freeSubscriptionButton.hidden=YES;
                    
                     _lblTitle.text=@"Enjoy your paid version of iAmuse!";
                    _customSubscriptionButton.backgroundColor=[UIColor colorWithRed:252/255.0 green:167/255.0 blue:8/255.0 alpha:1.0];
                 //   _customSubscriptionButton.layer.borderColor = [UIColor colorWithRed:0/255.0 green:121/255.0 blue:15/255.0 alpha:1.0].CGColor;
                 //   _customSubscriptionButton.layer.borderWidth = 2.0f;
                    
                  //  [self.oneMonthSubscribeBtn setTitle:@"Your Current Plan" forState:UIControlStateNormal];
               //     [self setBorderForSelectedSubscriptionView:self.customUploadView];
                }
                else
                {
                    [self.oneMonthSubscribeBtn setTitle:@"Your Current Plan" forState:UIControlStateNormal];
                    _freeSubscriptionButton.hidden=YES;
                    
                     _lblTitle.text=@"Enjoy your paid version of iAmuse!";
                    
                    _oneMonthSubscribeBtn.backgroundColor=[UIColor colorWithRed:252/255.0 green:167/255.0 blue:8/255.0 alpha:1.0];
                 //   _oneMonthSubscribeBtn.layer.borderColor = [UIColor colorWithRed:0/255.0 green:121/255.0 blue:15/255.0 alpha:1.0].CGColor;
                //    _oneMonthSubscribeBtn.layer.borderWidth = 2.0f;
                    
               //     [self setBorderForSelectedSubscriptionView:self.oneMonthSubscriptionView];
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

- (void)setBorderForSelectedSubscriptionView:(UIView *)view
{
    view.layer.cornerRadius = 5.0;
    view.layer.borderColor = [UIColor colorWithRed:0 green:166/255.0 blue:20/255.0 alpha:1.0].CGColor;
    view.layer.borderWidth = 5.0;
    view.clipsToBounds = YES;
}

//- (IBAction)subscribeEvents:(UIButton *)sender {
//
//    if ((sender.tag = OneDaySubscription)) {
//        subscriptionType = @"25";
//        self.productID =
//        @"Unlock_Daily";
//    }
//    else if ((sender.tag = OneYearSubscription)) {
//        subscriptionType = @"1200";
//        self.productID =
//        @"Unlock_Yearly";
//    }
//    else
//    {
//        subscriptionType = @"150";
//        self.productID =
//        @"Unlock_Monthly";
//    }
//   // [self getProductInfo];
//}


//- (IBAction)subscribeEvents:(UIButton *)sender {
//
////    PrivacyPolicyViewController *move = [self.storyboard instantiateViewControllerWithIdentifier:@"PrivacyPolicyViewController"];
////    move.value=@"Home";
////    [self presentViewController:move animated:YES completion:nil];
//
//
//
//    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://admin.iamuse.com/"]];
//
//}





- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)getProductInfo
{
    if ([SKPaymentQueue canMakePayments])
    {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.request = [[SKProductsRequest alloc]
                                      initWithProductIdentifiers:
                                      [NSSet setWithObject:self.productID]];
       self.request.delegate = self;
        
        [request start];
    }
    else
    {
        // show alert @"Please enable In App Purchase in Settings";

    }
}

//====================================
#pragma mark SKProductsRequestDelegate
//====================================
-(void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSArray *products = response.products;
    
    if (products.count != 0)
    {
        _product = products[0];
        NSLog(@"%@   %@",_product.localizedTitle,_product.localizedDescription);
        SKPayment *payment = [SKPayment paymentWithProduct:_product];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];

    } else {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        // show alert @"Product not found";
    }
    
    products = response.invalidProductIdentifiers;
    
    for (SKProduct *product in products)
    {
        NSLog(@"Product not found: %@", product);
    }
}

#pragma mark SKPaymentTransactionObserver

-(void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
            {
                [[SKPaymentQueue defaultQueue]
                 finishTransaction:transaction];
                NSString *charlieSendString = [transaction.transactionReceipt base64EncodedStringWithOptions:0];
                
        NSData *receiptData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
                
                NSString *str = [receiptData base64EncodedStringWithOptions:0];;
                NSLog(@" string is %@",str);
                 NSLog(@"%@",charlieSendString);
                
                NSLog(@"transcation id is %@",transaction.transactionIdentifier);
                
                
                
                [self saveSubscriptionOnServer:transaction];
                NSLog(@"%@",charlieSendString);
            }
                break;
                
            case SKPaymentTransactionStateFailed:
                NSLog(@"Transaction Failed");
                NSLog(@"Transaction Failed because %ld",(long)transaction.error.code);
                 NSLog(@"Transaction Failed because %@",transaction.error);
                
                  NSLog(@"Transaction localizedDescription because %@",transaction.error.localizedDescription);
                
                
                [MBProgressHUD hideHUDForView:self.view animated:YES];

                [[SKPaymentQueue defaultQueue]
                 finishTransaction:transaction];
                break;
                
            default:
                break;
        }
    }
}

//- (void)saveSubscriptionOnServer:(SKPaymentTransaction *)transaction
//{
//    WebCommunication *webComm = [[WebCommunication alloc] initWithServiceType:1];
//
//    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//    [dic setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"userId"] forKey:@"userId"];
//    [dic setObject:[transaction.transactionReceipt base64EncodedStringWithOptions:0] forKey:@"receiptData"];
//    [dic setObject:subscriptionType forKey:@"amount"];
//    NSURL *serviceUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/fetchingTranscationDetailsIOS",kAMBaseURL]];
//    [webComm callToServerRequestDictionary:dic onURL:serviceUrl WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm) {
//        [MBProgressHUD hideHUDForView:self.view animated:YES];
//        if (!error)
//        {
//            NSLog(@"%ld, %@",(long)status_code,response);
//            if ([[response objectForKey:@"responseCode"] integerValue] != 1)
//            {
//                [[[UIAlertView alloc] initWithTitle:@"Alert" message:[response objectForKey:@"responseDescription"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
//
//            }
//            else
//            {
//                SetUpStepsViewController *eventController = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([SetUpStepsViewController class])];
//                [eventController setSubscriptionId:@""];
//                [self.navigationController pushViewController:eventController animated:YES];
//            }
//        }
//        else
//        {
//            [[[UIAlertView alloc] initWithTitle:@"Alert" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
//
//            NSLog(@"%@",error);
//        }
//
//    }];
//
//}

- (void)saveSubscriptionOnServer:(SKPaymentTransaction *)transaction
{
    WebCommunication *webComm = [[WebCommunication alloc] initWithServiceType:1];
    
    
    
    
    NSDate* datetime = [NSDate date];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]]; // Prevent adjustment to user's local time zone.
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
    NSString* dateTimeInIsoFormatForZuluTimeZone = [dateFormatter stringFromDate:datetime];
    
    NSLog(@"date is %@",dateTimeInIsoFormatForZuluTimeZone);
    
    
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"userId"] forKey:@"userId"];
//    [dic setObject:[transaction.transactionReceipt base64EncodedStringWithOptions:0] forKey:@"receiptData"];
    [dic setObject:self.itemNumber forKey:@"itemNumber"];
    [dic setObject:subscriptionType forKey:@"paymentAmount"];
     [dic setObject:dateTimeInIsoFormatForZuluTimeZone forKey:@"paymentDate"];
    [dic setObject:transaction.transactionIdentifier forKey:@"txnId"];
     [dic setObject:@"in-app purchase" forKey:@"paymentType"];
    [dic setObject:@"VERIFIED" forKey:@"statusResponse"];
    [dic setObject:self.itemName forKey:@"itemName"];
    NSURL *serviceUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@subscriptionUpdateInAppPurchase",kAMBaseURL]];
    [webComm callToServerRequestDictionary:dic onURL:serviceUrl WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        if (!error)
        {
            NSLog(@"%ld, %@",(long)status_code,response);
            if (status_code==200)
                
                
               
                
                
                
            {
                
                
                
                
                
                
                  NSLog(@"%ld, %@",(long)status_code,response);
                
                NSString *subId;
                 NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
                if([self.productID isEqualToString:@"Unlock_Daily"])
                {
                    subId=@"2";
                     [defaults setObject:subId forKey:@"subscriptionType"];
                    
                    
                    [self.oneDaySubscribeBtn setTitle:@"Your Current Plan" forState:UIControlStateNormal];
                    _freeSubscriptionButton.hidden=YES;
                    
                    _lblTitle.text=@"Enjoy your paid version of iAmuse!";
                    
                       _oneDaySubscribeBtn.backgroundColor=[UIColor colorWithRed:252/255.0 green:167/255.0 blue:8/255.0 alpha:1.0];
                    
                    
                        [self.customSubscriptionButton setTitle:@"Order Now" forState:UIControlStateNormal];
                    [self.oneMonthSubscribeBtn setTitle:@"Order Now" forState:UIControlStateNormal];
                    _customSubscriptionButton.backgroundColor=[UIColor colorWithRed:0/255.0 green:121/255.0 blue:15/255.0 alpha:1.0];
                    _oneMonthSubscribeBtn.backgroundColor=[UIColor colorWithRed:0/255.0 green:121/255.0 blue:15/255.0 alpha:1.0];
                    
                    
                }
                
                else if ([self.productID isEqualToString:@"Unlock_Monthly"])
                {
                    subId=@"3";
                     [defaults setObject:subId forKey:@"subscriptionType"];
                    
                    [self.customSubscriptionButton setTitle:@"Your Current Plan" forState:UIControlStateNormal];
                    _freeSubscriptionButton.hidden=YES;
                    
                    _lblTitle.text=@"Enjoy your paid version of iAmuse!";
                    _customSubscriptionButton.backgroundColor=[UIColor colorWithRed:252/255.0 green:167/255.0 blue:8/255.0 alpha:1.0];
                    
                    
                    [self.oneDaySubscribeBtn setTitle:@"Order Now" forState:UIControlStateNormal];
                    [self.oneMonthSubscribeBtn setTitle:@"Order Now" forState:UIControlStateNormal];
                    
                     _oneDaySubscribeBtn.backgroundColor=[UIColor colorWithRed:0/255.0 green:121/255.0 blue:15/255.0 alpha:1.0];
                    
                     _oneMonthSubscribeBtn.backgroundColor=[UIColor colorWithRed:0/255.0 green:121/255.0 blue:15/255.0 alpha:1.0];
                    
                    
                    
                }
                else
                {
                    subId=@"4";
                     [defaults setObject:subId forKey:@"subscriptionType"];
                    
                    [self.oneMonthSubscribeBtn setTitle:@"Your Current Plan" forState:UIControlStateNormal];
                    _freeSubscriptionButton.hidden=YES;
                    
                    _lblTitle.text=@"Enjoy your paid version of iAmuse!";
                    
                    _oneMonthSubscribeBtn.backgroundColor=[UIColor colorWithRed:252/255.0 green:167/255.0 blue:8/255.0 alpha:1.0];
                    
                    [self.oneDaySubscribeBtn setTitle:@"Order Now" forState:UIControlStateNormal];
                    [self.customSubscriptionButton setTitle:@"Order Now" forState:UIControlStateNormal];
                    
                      _oneDaySubscribeBtn.backgroundColor=[UIColor colorWithRed:0/255.0 green:121/255.0 blue:15/255.0 alpha:1.0];
                    
                    _customSubscriptionButton.backgroundColor=[UIColor colorWithRed:0/255.0 green:121/255.0 blue:15/255.0 alpha:1.0];
                    
                    
                    
                    
                    
                    
                }
                
                
                
                [[CTKiosk sharedInstance] subscriptionUpdate];
                
                
                
                
                
                
                
//                [[[UIAlertView alloc] initWithTitle:@"Alert" message:[response objectForKey:@"responseDescription"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                
            }
            else
            {
                
                
                 NSLog(@"%ld, %@",(long)status_code,response);
                
                
                
                [[[UIAlertView alloc] initWithTitle:@"Alert" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                
                NSLog(@"%@",error);
                
                
//                SetUpStepsViewController *eventController = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([SetUpStepsViewController class])];
//                [eventController setSubscriptionId:@""];
//                [self.navigationController pushViewController:eventController animated:YES];
            }
        }
        else
        {
            [[[UIAlertView alloc] initWithTitle:@"Alert" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            
            NSLog(@"%@",error);
        }
        
    }];
    
}






- (void)paymentQueue:(SKPaymentQueue *)queue
                    :(NSError *)error
{
    [[[UIAlertView alloc] initWithTitle:@"Alert" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

//- (IBAction)goToEventList:(id)sender {
//    EventListViewController *eventController = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([EventListViewController class])];
//    if (![subscriptionDetails[@"subId"] isKindOfClass:[NSNull class]])
//    {
//        [eventController setSubscriptionId:[subscriptionDetails objectForKey:@"subId"]];
//    }
//    else
//    {
//        [eventController setSubscriptionId:@""];
//    }
//    [self.navigationController pushViewController:eventController animated:YES];
//}


- (IBAction)goToEventList:(id)sender {
    
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * deviceModePref = [defaults stringForKey:AMDeviceModeSettingsKey];
    
    if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
    {
        UIStoryboard *storyboard;
        storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
        
        EventListViewController *eventController = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([EventListViewController class])];
        if (![subscriptionDetails[@"subId"] isKindOfClass:[NSNull class]])
        {
            [eventController setSubscriptionId:[subscriptionDetails objectForKey:@"subId"]];
        }
        else
        {
            [eventController setSubscriptionId:@""];
        }
        
        
        [self.navigationController pushViewController:eventController animated:YES];
        
    }
    
   else
   {
    
    
    
    EventListViewController *eventController = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([EventListViewController class])];
    if (![subscriptionDetails[@"subId"] isKindOfClass:[NSNull class]])
    {
        [eventController setSubscriptionId:[subscriptionDetails objectForKey:@"subId"]];
    }
    else
    {
        [eventController setSubscriptionId:@""];
    }
    [self.navigationController pushViewController:eventController animated:YES];
}
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}
- (IBAction)backButtonAction:(id)sender {
    
//    UIStoryboard *storyboard;
//
//      storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
//
//    CTSettingsViewController *eventController = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([CTSettingsViewController class])];
//    [self.navigationController pushViewController:eventController animated:YES];
//
    
    [self.navigationController popViewControllerAnimated:YES];
      [self.navigationController setNavigationBarHidden: NO animated:YES];
}

- (IBAction)dailyPressed:(id)sender {
    
    
     _lblPopupHeader.text=@"You are making a purchase of $24.99. Please choose your preferred payment option.";
    
    _completeView.hidden=NO;
    _popupView.hidden=NO;
    
    
    subscriptionType = @"25.00";
            self.productID =
            @"Unlock_Daily";
    self.itemNumber=@"2";
    self.itemName=@"Single Event";
    
  //  [self getProductInfo];
    
}

- (IBAction)yearlyPressed:(id)sender {
    
    
    
    
     [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://admin.iamuse.com/"]];
    
    
    
    
    
    
//    subscriptionType = @"1200.00";
//    self.productID =
//    @"Unlock_yearly";
//
//     self.itemNumber=@"3";
//     self.itemName=@"professional";
//
//    [self getProductInfo];
    
}

- (IBAction)monthlyPressed:(id)sender {
    
    
    
    _lblPopupHeader.text=@"You are making a purchase of $149.99. Please choose your preferred payment option.";
    
    
    _completeView.hidden=NO;
    _popupView.hidden=NO;
    
    
    subscriptionType = @"150.00";
    self.productID =
    @"Unlock_Monthly";
    
    self.itemNumber=@"3";
    self.itemName=@"professional";
    
 //   [self getProductInfo];
}


- (void)request:(SKRequest *)request didFailWithError:(NSError *)error



{
    
}
- (void)requestDidFinish:(SKRequest *)request


{
    
}




- (IBAction)inAppPressed:(id)sender {
    
    _completeView.hidden=YES;
    _popupView.hidden=YES;
    
    
    [self getProductInfo];
    
    
    
    
    
}

- (IBAction)paypalPressed:(id)sender {
    
    _completeView.hidden=YES;
    _popupView.hidden=YES;
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://admin.iamuse.com/"]];
    
  //   [[CTKiosk sharedInstance] subscriptionUpdate];
    
    
}


- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer
{
    CGPoint location = [recognizer locationInView:[recognizer.view superview]];
    
    
    _completeView.hidden=YES;
    _popupView.hidden=YES;
    
    //Do stuff here...
}




@end
