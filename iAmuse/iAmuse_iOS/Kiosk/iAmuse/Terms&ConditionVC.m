//
//  Terms&ConditionVC.m
//  iAmuse
//
//  Created by Ajay_Mac on 09/09/19.
//  Copyright © 2019 iAmuse Inc. All rights reserved.
//

#import "Terms&ConditionVC.h"

@interface Terms_ConditionVC ()

@end

@implementation Terms_ConditionVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    _bckBtn.layer.cornerRadius = 3; // this value vary as per your desire
    _bckBtn.clipsToBounds = YES;
    
//     [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.iamuse.com/terms-conditions"]]];
    // Do any additional setup after loading the view.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)bckBtnAction:(id)sender {
    
    
     [self dismissViewControllerAnimated:YES completion:nil];
}
@end
