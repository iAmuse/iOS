//
//  AMSelectContentViewController.h
//  iAmuse
//
//  Created by Roland Hordos on 2014-06-30.
//  Copyright (c) 2014 iAmuse Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AMPrintKiosk.h"
#import "iCarousel.h"

@class iCarousel;

@interface AMSelectContentViewController : UIViewController <iCarouselDataSource, iCarouselDelegate>
{
    NSMutableDictionary * imageCache;
}

@property (weak, nonatomic) IBOutlet iCarousel * printSelectionCarousel;
@property AMPrintKiosk * kiosk;
@property (weak, nonatomic) IBOutlet UIImageView * header;
@property (weak, nonatomic) IBOutlet UILabel * caption;
@property (nonatomic, strong) NSString *lockPIN;

- (IBAction)refreshButtonTouched:(id)sender;
- (void)receiveNewPhotoObjectAvailable:(NSNotification *)notification;
- (void)receiveRefreshPrintContentDisplay:(NSNotification *)notification;

@end
