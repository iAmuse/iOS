//
//  AMTakingPicturesViewController.h
//  Jurassic
//
//  Created by Roland Hordos on 2013-07-07.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AMSharingViewController.h"

@class AMSharingViewController;

@interface AMTakingPicturesViewController : UIViewController <SharingCompleteDelegate> {
    BOOL havePicture1;
    BOOL havePicture2;
    BOOL havePicture3;
}
@property (strong, nonatomic) AMSharingViewController *sharingVC;
@property (nonatomic) NSString *workflow;
@property (strong, nonatomic) IBOutlet UIImageView *header;
@property (strong, nonatomic) IBOutlet UIImageView *footer;

- (IBAction)backButtonAction:(id)sender;
- (IBAction)forwardButtonAction:(id)sender;

- (void)goBack;
//- (void)close;

@end

@protocol TakingPicturesCompleteDelegate1 <NSObject>
@required
- (void)takingPicturesViewController:(AMTakingPicturesViewController *)takingPicturesViewController didFinishWithWorkflow:(NSString *)workflow;
@end
