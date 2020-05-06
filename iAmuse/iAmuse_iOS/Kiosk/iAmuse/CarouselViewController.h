//
//  CarouselViewController.h
//  iAmuse
//
//  Created by MAC MOJAVE on 17/06/19.
//  Copyright © 2019 iAmuse Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AMSharingViewController.h"
#import "Photo.h"
#import "iCarousel.h"

@class AMSharingViewController;

NS_ASSUME_NONNULL_BEGIN

@interface CarouselViewController : UIViewController<SharingCompleteDelegate, UIScrollViewDelegate,iCarouselDataSource, iCarouselDelegate >

{
    Photo * photo1;
    Photo * photo2;
    Photo * photo3;
    
    NSMutableArray * selectedPhotos;
    IBOutlet UIView * blackBackView;
    IBOutlet UIView * clearBackView;
}

@property (strong, nonatomic) IBOutlet UIButton *carouselConfirmButton;

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

// Changes by Ajay

@property (strong, nonatomic) IBOutlet UIView *popupView;
@property (strong, nonatomic) IBOutlet UILabel *countdownLabel;

@property (strong, nonatomic) IBOutlet UIView *popupBackgroundView;


@property (strong, nonatomic) IBOutlet iCarousel *backgroundCarousel;
@property (nonatomic) BOOL wrap;
@property (strong, nonatomic) IBOutlet UIView *completeView;


- (IBAction)backButton:(id)sender;
- (IBAction)select1Touched:(id)sender;
- (IBAction)select2Touched:(id)sender;
- (IBAction)select3Touched:(id)sender;
- (IBAction)doneButtonClicked:(UIButton *)sender;
- (IBAction)selectToZoomClicked:(UIButton *)sender;
- (IBAction)hideBlackView:(UIButton *)sender;
- (IBAction)homeButtonTouched:(id)sender;

- (void)goBack;

@end

@protocol TakingPicturesCompleteDelegate <NSObject>
@required
- (void)takingPicturesViewController:(CarouselViewController *)takingPicturesViewController didFinishWithWorkflow:(NSString *)workflow;


@end

NS_ASSUME_NONNULL_END
