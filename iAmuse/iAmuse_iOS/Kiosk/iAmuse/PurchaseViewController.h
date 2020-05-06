//
//  PurchaseViewController.h
//  AppPerchaseDemo
//
//  Created by apple on 26/10/16.
//  Copyright © 2016 Foofi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>
#import "ViewController.h"
@interface PurchaseViewController : UIViewController <SKPaymentTransactionObserver, SKProductsRequestDelegate>

@property(assign) BOOL isShowingFromSetting;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (strong, nonatomic) SKProduct *product;
@property (strong, nonatomic) NSString *productID;
@property (strong, nonatomic) NSString *itemNumber;
@property (strong, nonatomic) NSString *itemName;
@property (strong, nonatomic) SKProductsRequest *request;
@property (weak, nonatomic) IBOutlet UIView *oneDaySubscriptionView;
@property (weak, nonatomic) IBOutlet UIButton *oneDaySubscribeBtn;
@property (weak, nonatomic) IBOutlet UIView *oneMonthSubscriptionView;
@property (weak, nonatomic) IBOutlet UIView *customUploadView;
@property (weak, nonatomic) IBOutlet UIButton *oneMonthSubscribeBtn;
@property (weak, nonatomic) IBOutlet UIView *freeView;
@property (weak, nonatomic) IBOutlet UIButton *customSubscriptionButton;
@property (weak, nonatomic) IBOutlet UIButton *freeSubscriptionButton;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;

- (void)getProductInfo;
@property (strong, nonatomic) IBOutlet UIButton *backButton;
- (IBAction)dailyPressed:(id)sender;
- (IBAction)yearlyPressed:(id)sender;
- (IBAction)monthlyPressed:(id)sender;
@property (strong, nonatomic) IBOutlet UIView *completeView;
@property (strong, nonatomic) IBOutlet UIView *popupView;
@property (strong, nonatomic) IBOutlet UILabel *lblPopupHeader;
@property (strong, nonatomic) IBOutlet UIButton *btninApp;
@property (strong, nonatomic) IBOutlet UIButton *btnPayPal;
- (IBAction)inAppPressed:(id)sender;

- (IBAction)paypalPressed:(id)sender;

@end
