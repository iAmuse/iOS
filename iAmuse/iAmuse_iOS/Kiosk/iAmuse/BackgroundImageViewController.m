//
//  BackgroundImageViewController.m
//  iAmuse
//
//  Created by Ajay_Mac on 10/09/19.
//  Copyright © 2019 iAmuse Inc. All rights reserved.
//

#import "BackgroundImageViewController.h"
#import "CTKiosk.h"
#import "Kiosk.h"

@interface BackgroundImageViewController ()

@end

@implementation BackgroundImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    
    CTKiosk *kiosk = [CTKiosk sharedInstance];
  //  NSString *assetPath = [kiosk.storePath stringByAppendingPathComponent:@"header.png"];
  //  self.header.image = [UIImage imageWithContentsOfFile:assetPath];
   // assetPath = [kiosk.storePath stringByAppendingPathComponent:@"footer.png"];
  //  self.footer.image = [UIImage imageWithContentsOfFile:assetPath];
    PhotoLayout *layout = [kiosk currentPhotoLayout];
    NSString * thankuassetPath = [kiosk.storePath stringByAppendingPathComponent:[NSString stringWithFormat:@"Events/%@/thankyou",layout.eventId]];
    _backgroundImage.image = [UIImage imageWithContentsOfFile:thankuassetPath];
    
    
    
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

@end
