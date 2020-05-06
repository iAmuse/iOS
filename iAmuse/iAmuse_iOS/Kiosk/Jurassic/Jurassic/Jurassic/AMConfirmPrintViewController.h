//
//  CTGetReadyViewController.h
//  Jurassic
//
//  Created by Roland Hordos on 2013-06-02.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ABPadLockScreen/ABPadLockScreenViewController.h>
#import "AMTakingPicturesViewController.h"

@interface AMConfirmPrintViewController : UIViewController <ABPadLockScreenViewControllerDelegate> {
    NSString *_workflow;
}

@property (strong, nonatomic) IBOutlet UIImageView *header;
@property (strong, nonatomic) IBOutlet UIImageView *selectedPhotoImageView;
@property (nonatomic, strong) NSString *lockPIN;
@property (weak, nonatomic) IBOutlet UIButton *printButton;

- (IBAction)backButtonTouched:(id)sender;
- (IBAction)noButtonTouched:(id)sender;
- (IBAction)yesButtonTouched:(id)sender;
- (IBAction)settingsButtonTouched:(id)sender;
- (IBAction)PrintPreview:(id)sender;

@end
