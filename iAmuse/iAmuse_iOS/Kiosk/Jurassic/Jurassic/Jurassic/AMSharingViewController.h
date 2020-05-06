//
//  AMSharingViewController.h
//  Jurassic
//
//  Created by Roland Hordos on 2013-07-08.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AMThanksViewController.h"

@import Firebase;

@class AMThanksViewController;

@interface AMSharingViewController : UIViewController <UITextFieldDelegate,
                                                       ThanksCompleteDelegate>
{
//    AMThanksViewController *thanksVC;
    NSString * _workflow;
    __weak IBOutlet UIView * indicatorBackView;
}

@property (weak, nonatomic) IBOutlet UIButton *tAndCButton;
@property (strong, nonatomic) IBOutlet UIImageView *header;
@property (strong, nonatomic) IBOutlet UIImageView *footer;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UIButton *checkButton;

@property (weak, nonatomic) IBOutlet UIButton *checkBtnConsent;
- (IBAction)checkBtnConsentAction:(id)sender;
@property (weak, nonatomic) IBOutlet UIImageView *imgUserIcon;
@property (weak, nonatomic) IBOutlet UIImageView *imgCallIcon;

- (IBAction)termsClick:(id)sender;


@property (weak, nonatomic) IBOutlet UISegmentedControl *publicUsageCheckBox;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (strong, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *mobileField;
@property (weak, nonatomic) IBOutlet UIButton *printButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (strong, nonatomic) IBOutlet UILabel *publicUsageLabel;
@property (weak, nonatomic) IBOutlet UILabel *newsletterOptInLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *newsletterCheckBox;

@property(nonatomic, readonly, nullable) UIResponder *shareResponder;
@property (strong, nonatomic) IBOutlet UIView *completeView;
@property (strong, nonatomic) IBOutlet UILabel *countdownLabel;
@property (strong, nonatomic) IBOutlet UIView *popupView;

- (IBAction)publicUsageChanged:(id)sender;
- (IBAction)newsletterToggleChanged:(UIButton *)sender;

- (IBAction)sendButtonTouched:(id)sender;
- (IBAction)printButtonTouched:(id)sender;
- (IBAction)doneButtonTouched:(id)sender;
- (IBAction)mobilEditDidEnd:(id)sender;
- (IBAction)nameEditDidEnd:(id)sender;
- (IBAction)emailEditDidEnd:(id)sender;
- (IBAction)emailTouchOutside:(id)sender;
- (IBAction)screenTouched:(id)sender;
- (IBAction)backButtonTouched:(id)sender;
- (IBAction)termsAndConditionAction:(UIButton *)sender;
@property (strong, nonatomic) IBOutlet UIButton *sendButtonrounded;
@property (strong, nonatomic) IBOutlet UIButton *backButtonRounded;

@end

@protocol SharingCompleteDelegate <NSObject>
@required
- (void)sharingViewController:(AMSharingViewController *)sharingViewController
        didFinishWithWorkflow:(NSString *)workflow;
- (void)setWorkflow:(NSString *)value;
@end

