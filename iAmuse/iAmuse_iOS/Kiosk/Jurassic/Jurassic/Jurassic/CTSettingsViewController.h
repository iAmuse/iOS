//
//  CTSettingsViewController.h
//  Jurassic
//
//  Created by Roland Hordos on 2013-05-25.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SensibleTableView/SensibleTableView.h>

@interface CTSettingsViewController : SCTableViewController

- (IBAction)doneBtnTouch:(id)sender;

@end


@protocol SettingsViewCompleteDelegate < NSObject >

@required

- (void)settingsViewController:(CTSettingsViewController *)settingsViewController didFinishSettings:(NSUserDefaults *)settings;

@end

