//
//  SignInViewController.h
//  iAmuse
//
//  Created by Ravinder on 10/21/16.
//  Copyright © 2016 iAmuse Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WebCommunication.h"

@import GoogleSignIn;

@interface SignInViewController : UIViewController<GIDSignInUIDelegate>

@property (strong, nonatomic) IBOutlet UIButton *checkBoxButton;
- (IBAction)checkBoxButtonClicked:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *signInButton;
@property (strong, nonatomic) IBOutlet UIButton *signInWithGoogleButton;
@property (strong, nonatomic) IBOutlet UIButton *googleButton;

@property (weak, nonatomic) IBOutlet GIDSignInButton *signInButton1;

@end
