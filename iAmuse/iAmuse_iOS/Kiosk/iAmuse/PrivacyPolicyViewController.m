//
//  PrivacyPolicyViewController.m
//  iAmuse
//
//  Created by Roohul on 29/03/17.
//  Copyright © 2017 iAmuse Inc. All rights reserved.
//

#import "PrivacyPolicyViewController.h"
#import "PurchaseViewController.h"
#import "AMConstants.h"
#import "EventListViewController.h"
#import <WebKit/WebKit.h>

@interface PrivacyPolicyViewController ()<WKNavigationDelegate>

@end

@implementation PrivacyPolicyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    float height=self.view.frame.size.height-168;
    CGRect webframe=CGRectMake(0, 108, self.view.frame.size.width, height);
    
    
    WKWebViewConfiguration *theConfiguration = [[WKWebViewConfiguration alloc] init];
    WKWebView *webView = [[WKWebView alloc] initWithFrame:webframe configuration:theConfiguration];
    webView.navigationDelegate = self;
    
    
    
    
    
    if([_value isEqualToString:@"Privacypolicy"])
    {
        _headerLbl.text = @"Privacy Policy";

//        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.iamuse.com/privacy-policy"]]];
        
        
        NSURL *nsurl=[NSURL URLWithString:@"https://www.iamuse.com/privacy-policy"];
        NSURLRequest *nsrequest=[NSURLRequest requestWithURL:nsurl];
        [webView loadRequest:nsrequest];
        [self.view addSubview:webView];
        
    }
    else if ([_value isEqualToString:@"Terms"])
    {
        _headerLbl.text = @"Terms & Conditions";

//          [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.iamuse.com/terms-conditions"]]];
        
        NSURL *nsurl=[NSURL URLWithString:@"https://www.iamuse.com/terms-conditions"];
        NSURLRequest *nsrequest=[NSURLRequest requestWithURL:nsurl];
        [webView loadRequest:nsrequest];
        [self.view addSubview:webView];
    }

    else
    {
        _headerLbl.text = @"Home";

//        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://iamuse.com/"]]];
        
        NSURL *nsurl=[NSURL URLWithString:@"http://iamuse.com/"];
        NSURLRequest *nsrequest=[NSURLRequest requestWithURL:nsurl];
        [webView loadRequest:nsrequest];
        [self.view addSubview:webView];
    }

    
    _backButton.layer.cornerRadius = 3; // this value vary as per your desire
    _backButton.clipsToBounds = YES;
    
    // Do any additional setup after loading the view.
    if (_isShowingFromSetting) {
        [_nextButton setHidden:YES];
    }
//    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://iamuse.com/"]]];
    
//    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.iamuse.com/privacy-policy"]]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backButtonAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)nextAction:(id)sender {
    NSUserDefaults * userdefault = [NSUserDefaults standardUserDefaults];
    NSString * deviceModePref = [userdefault stringForKey:AMDeviceModeSettingsKey];
    if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
    {
        EventListViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([EventListViewController class])];
        [self.navigationController pushViewController:controller animated:YES];
    }
    else
    {
        PurchaseViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([PurchaseViewController class])];
        [self.navigationController pushViewController:controller animated:YES];
    }
}
- (IBAction)backBtnAction:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
   //  [self.navigationController popViewControllerAnimated:YES];
}


@end
