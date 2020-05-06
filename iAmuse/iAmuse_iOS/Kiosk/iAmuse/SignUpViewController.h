//
//  SignUpViewController.h
//  iAmuse
//
//  Created by Ravinder on 10/21/16.
//  Copyright © 2016 iAmuse Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WebCommunication.h"


@import Firebase;

@interface SignUpViewController : UIViewController<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (strong, nonatomic) IBOutlet UIButton *checkBoxButton;
- (IBAction)checkBoxButtonClicked:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *signUpButton;
@property (strong, nonatomic) IBOutlet UIButton *userTypeButton;
@property (weak, nonatomic) IBOutlet UIButton *privacyPolicyBtnAction;

- (IBAction)privacyPolicyBtnAction:(id)sender;
- (IBAction)backButtonAction:(id)sender;

@end
