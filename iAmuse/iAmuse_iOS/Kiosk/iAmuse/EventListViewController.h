//
//  EventListViewController.h
//  iAmuse
//
//  Created by apple on 24/10/16.
//  Copyright © 2016 iAmuse Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SensibleTableView/SensibleTableView.h>
@import GoogleSignIn;

@interface EventListViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *eventTable;
@property (strong, nonatomic) NSDictionary *eventData;
@property (weak, nonatomic) IBOutlet UILabel *uploadingImagesLabel;
@property (strong, nonatomic) NSString *subscriptionId;

@property (weak, nonatomic) IBOutlet UILabel *lblSubscriptionType;
- (IBAction)gotoTouchScreen:(id)sender;
- (IBAction)gotoCameraMode:(id)sender;

@end
