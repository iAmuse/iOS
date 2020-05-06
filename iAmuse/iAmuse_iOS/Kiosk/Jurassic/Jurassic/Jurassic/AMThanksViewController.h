//
//  AMThanksViewController.h
//  Jurassic
//
//  Created by Roland Hordos on 2013-07-08.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AMThanksViewController : UIViewController


- (IBAction)doneTouched:(id)sender;
@property (weak, nonatomic) IBOutlet UIImageView *header;
@property (weak, nonatomic) IBOutlet UIImageView *footer;
@property (weak, nonatomic) IBOutlet UILabel *support1;
@property (weak, nonatomic) IBOutlet UILabel *resetLbl;
@property (weak, nonatomic) IBOutlet UILabel *support2;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;

@end

@protocol ThanksCompleteDelegate <NSObject>
@required
- (void)thanksViewController:(AMThanksViewController *)thanksViewController
        didFinishWithWorkflow:(NSString *)workflow;
@end
