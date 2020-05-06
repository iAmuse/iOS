//
//  AMTakingPicturesViewController.h
//  Jurassic
//
//  Created by Roland Hordos on 2013-07-07.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AMSharingViewController.h"
#import "Photo.h"

@class AMSharingViewController;

@interface AMReviewPicturesViewController : UIViewController <SharingCompleteDelegate, UIScrollViewDelegate >
{
    Photo * photo1;
    Photo * photo2;
    Photo * photo3;
    
    NSMutableArray * selectedPhotos;
    IBOutlet UIView * blackBackView;
    IBOutlet UIView * clearBackView;
}
@property (weak, nonatomic) IBOutlet UIButton *leftButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;
@property (strong, nonatomic) AMSharingViewController * sharingVC;
@property (nonatomic) NSString * workflow;

@property (strong, nonatomic) IBOutlet UIImageView * header;
@property (strong, nonatomic) IBOutlet UIImageView * footer;

@property (weak, nonatomic) IBOutlet UIImageView * picture1View;
@property (weak, nonatomic) IBOutlet UIImageView * picture2View;
@property (weak, nonatomic) IBOutlet UIImageView * picture3View;
@property (weak, nonatomic) IBOutlet UIButton * select1Button;
@property (weak, nonatomic) IBOutlet UIButton * select2Button;
@property (weak, nonatomic) IBOutlet UIButton * select3Button;
@property (strong, nonatomic) IBOutlet UIButton *confirmButton;

- (IBAction)backButton:(id)sender;
- (IBAction)select1Touched:(id)sender;
- (IBAction)select2Touched:(id)sender;
- (IBAction)select3Touched:(id)sender;
- (IBAction)doneButtonClicked:(UIButton *)sender;
- (IBAction)selectToZoomClicked:(UIButton *)sender;
- (IBAction)hideBlackView:(UIButton *)sender;

- (void)goBack;

@end

@protocol TakingPicturesCompleteDelegate <NSObject>
@required
- (void)takingPicturesViewController:(AMReviewPicturesViewController *)takingPicturesViewController didFinishWithWorkflow:(NSString *)workflow;
@end
