//
//  PrivacyPolicyViewController.h
//  iAmuse
//
//  Created by Roohul on 29/03/17.
//  Copyright © 2017 iAmuse Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PrivacyPolicyViewController : UIViewController

//@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property(assign) BOOL isShowingFromSetting;
- (IBAction)nextAction:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *backButton;
@property (strong,nonatomic) NSString *value;
@property (weak, nonatomic) IBOutlet UILabel *headerLbl;

@end
