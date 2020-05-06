//
//  CTSelectSceneViewController.h
//  Jurassic
//
//  Created by Roland Hordos on 2013-06-01.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iCarousel.h"
#import "CTGetReadyViewController.h"

@class CTKiosk;

@interface CTSelectSceneViewController : UIViewController < iCarouselDataSource,
iCarouselDelegate, GetReadyCompleteDelegate, TakingPicturesCompleteDelegate1 >
{
    NSString * _workflow;
    NSMutableDictionary * imageCache;
    __weak IBOutlet UILabel * description;
}

@property (strong, nonatomic) CTGetReadyViewController * getReadyVC;
@property (strong, nonatomic) IBOutlet UIImageView * header;
@property (strong, nonatomic) IBOutlet UIImageView * footer;

@property (strong, nonatomic) AMTakingPicturesViewController *takePicturesVC;

@property CTKiosk * kiosk;  // Master object, highest level that assembles the entire Kiosk application.
@property (weak, nonatomic) IBOutlet iCarousel * backgroundCarousel;  // https://github.com/nicklockwood/iCarousel
@property (nonatomic) BOOL wrap;
@property (weak, nonatomic) IBOutlet UITapGestureRecognizer * settingsTapRecognizer;
@property (strong, nonatomic) IBOutlet UIButton *backButton;

- (IBAction)resetTouched:(id)sender;
- (IBAction)settingsTouched:(id)sender;

- (void) goBack;
- (void) userDidLeave:(NSNotification *)notification;

@end

@protocol SceneSelectionCompleteDelegate <NSObject>
@required
- (void)sceneSelectionViewController:(CTSelectSceneViewController *)sceneSelectionViewController didFinishWithWorkflow:(NSString *)workflow;
@end

