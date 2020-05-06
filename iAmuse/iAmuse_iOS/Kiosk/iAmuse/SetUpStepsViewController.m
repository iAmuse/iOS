//
//  SetUpStepsViewController.m
//  iAmuse
//
//  Created by apple on 28/12/16.
//  Copyright © 2016 iAmuse Inc. All rights reserved.
//

#import "SetUpStepsViewController.h"
#import "EventListViewController.h"

@interface SetUpStepsViewController ()

@end

@implementation SetUpStepsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)nextAction:(id)sender {
    EventListViewController *eventController = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([EventListViewController class])];
    [eventController setSubscriptionId:@""];
    [self.navigationController pushViewController:eventController animated:YES];
}

@end
