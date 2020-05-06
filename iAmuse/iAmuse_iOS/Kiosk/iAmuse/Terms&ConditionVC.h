//
//  Terms&ConditionVC.h
//  iAmuse
//
//  Created by Ajay_Mac on 09/09/19.
//  Copyright © 2019 iAmuse Inc. All rights reserved.
//

#import "ViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface Terms_ConditionVC : ViewController
//@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIButton *bckBtn;
- (IBAction)bckBtnAction:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property(assign) BOOL isShowingFromSetting;

@end

NS_ASSUME_NONNULL_END
