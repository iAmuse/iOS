//
//  AMSelectContentViewController.m
//  iAmuse
//
//  Created by Roland Hordos on 2014-06-30.
//  Copyright (c) 2014 iAmuse Inc. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa/RACDisposable.h>
#import <ReactiveCocoa/ReactiveCocoa/RACScheduler.h>
#import "AMSelectContentViewController.h"
#import "iCarousel.h"
#import "Photo.h"
#import "AMConstants.h"
#import "ABPadLockScreenViewController.h"
#import "ABPadLockScreenSetupViewController.h"

@interface AMSelectContentViewController ()
{
    NSInteger placeholderIndex;
}
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@end

@implementation AMSelectContentViewController {
    RACDisposable *butlerControl;
    NSInteger nextRollingCarouselIndex;
    ABPadLockScreenViewController *lockScreen;
}

- (id)init {
    DDLogVerbose(@"%s", __FUNCTION__);
    
    //    self = [super init];  // ths will create a recursive init via "initWithNibName"
    if (self) {
        nextRollingCarouselIndex = 0;
        self.kiosk = [AMPrintKiosk sharedInstance];
        [self createAndSeedImageCache];
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)aDecoder
{
    NSLog(@"%s", __FUNCTION__);

    self = [super initWithCoder:aDecoder];
    if (self) {
        self = [self init];
    }
    return self;
}

//
// ATTN - this is not the storyboard constructor
//
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self = [self init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.lockPIN = kAMPrintKioskLockPIN;
    // Load theme assets.
    NSString *assetPath = [self.kiosk.storePath stringByAppendingPathComponent:@"header_print_select.png"];
    self.header.image = [UIImage imageWithContentsOfFile:assetPath];
    
//    _printSelectionCarousel.type = iCarouselTypeCoverFlow;
    _printSelectionCarousel.type = iCarouselTypeCoverFlow2;


    // Watch for new photos.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveNewPhotoObjectAvailable:)
                                                 name:kAMNewPhotoObjectNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveRefreshPrintContentDisplay:)
                                                 name:kAMRefreshPrintContentNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showSettingScreen2:)
                                                 name:@"showSettingScreen"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lockCancel2:)
                                                 name:@"lockCancel"
                                               object:nil];
    
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewsSwipe2:)];
    swipeUp.numberOfTouchesRequired = 2;
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    swipeUp.delaysTouchesBegan = YES;
    [self.view addGestureRecognizer:swipeUp];
    
    
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewsSwipe2:)];
    swipeDown.numberOfTouchesRequired = 2;
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    swipeDown.delaysTouchesBegan = YES;
    [self.view addGestureRecognizer:swipeDown];
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewsSwipe2:)];
    swipeRight.numberOfTouchesRequired = 2;
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    swipeRight.delaysTouchesBegan = YES;
    [self.view addGestureRecognizer:swipeRight];
    
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewsSwipe2:)];
    swipeLeft.numberOfTouchesRequired = 2;
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    swipeLeft.delaysTouchesBegan = YES;
    [self.view addGestureRecognizer:swipeLeft];

}

- (void)handleViewsSwipe2:(UISwipeGestureRecognizer *)recognizer
{
    
    NSUInteger touches = recognizer.numberOfTouches;
    if (touches == 2)
    {
        [self authorizePrint2];
    }
}

- (void)authorizePrint2 {
    
    lockScreen = [[ABPadLockScreenViewController alloc] initWithDelegate:nil complexPin:NO];
    lockScreen.showSetting = YES;
    
    
    lockScreen.modalPresentationStyle = UIModalPresentationFullScreen;
    [lockScreen cancelButtonDisabled:NO];
    lockScreen.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    
    [self presentViewController:lockScreen animated:YES completion:nil];
}

- (void)lockCancel2:(NSNotification *)notification
{
    [lockScreen dismissViewControllerAnimated:NO completion:nil];
}

- (void)showSettingScreen2:(NSNotification *)notification
{
    [lockScreen dismissViewControllerAnimated:NO completion:nil];
    
    [self performSegueWithIdentifier:@"settings" sender:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.navigationController setNavigationBarHidden: YES animated:YES];
    
    // Put the reload in here, rather than hold up the display.  This is a very
    // naturally async use case.
    [self checkForNewPhotos];
    
    // Setup a timer to roll the carousel automatically.
    butlerControl = [[RACScheduler scheduler] after:[NSDate date]
                                     repeatingEvery:kAMPrintSelectRollPaceSecs
                                         withLeeway:0
                                           schedule:^{
                                               // Start at the currently selected item.
                                               nextRollingCarouselIndex = self.printSelectionCarousel.currentItemIndex + 1;
//                                               nextRollingCarouselIndex = nextRollingCarouselIndex + 1;
                                               if (nextRollingCarouselIndex > (self.kiosk.photos.count + 1)) {
                                                   nextRollingCarouselIndex = 0;
                                               }
                                               
                                               [self.printSelectionCarousel scrollToItemAtIndex:nextRollingCarouselIndex
                                                                                       duration:kAMPrintSelectRollDurationSecs];

                                           }];

}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"%s", __FUNCTION__);
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden: YES animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (butlerControl) {
        [butlerControl dispose];
        butlerControl = nil;
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
//        _dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        _dateFormatter.dateFormat = kAMDisplayTimestampFormat;
    }
    return _dateFormatter;
}


- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    if ([self.kiosk.photos count] == 0) {
        return 1;
    }
    return [self.kiosk.photos count];
}

//
//  Keep track of images by index.  The picture at an index will not change, so
//  we can track the re-use view by tag to verify if it already has the content
//  we need.
//
- (UIView *)carousel:(iCarousel *)carousel
  viewForItemAtIndex:(NSUInteger)index
         reusingView:(UIView *)view;
{
    BOOL load = YES;
    UIImageView *itemView = nil;
    UIImage *photoImage = nil;
    
    Photo *photo = nil;
    NSString *cacheKey = nil;
    if ([self.kiosk.photos count] == 0)
    {
        if (index == 0) {
            // special placeholder
            cacheKey = kAMImageFileNameNothingToPrint;
        } else {
            // offset the index for the number of fixed placeholders
            photo = [self.kiosk.photos objectAtIndex:index - 1];
            cacheKey = photo.photoUrl;
        }
    }
    else
    {
        // offset the index for the number of fixed placeholders
        photo = [self.kiosk.photos objectAtIndex:index];
        cacheKey = photo.photoUrl;
    }
    if (view) {
        // trying to re-use a view ..
        if (view.tag == index) {
            load = NO;
        }
    }
    
    if (load) {
        // Try image cache first
        if (!imageCache) {
            [self createAndSeedImageCache];
        }
        
        photoImage = [imageCache objectForKey:cacheKey];
        if (!photoImage) {
            // We haven't loaded this image yet, do so and cache it too.
            photoImage = [self loadPhotoImage:photo];
            [imageCache setObject:photoImage forKey:cacheKey];
        }
        
        if (view) {
            if ([view isKindOfClass:UIImageView.class]) {
                ((UIImageView *)view).image = photoImage;
                view.tag = index;
            }
        } else {
            itemView = [[UIImageView alloc] initWithImage:photoImage];
            itemView.tag = index;
            itemView.contentMode = UIViewContentModeScaleAspectFit;
            
            //change width of frame
            CGRect frame = itemView.frame;
            frame.size.width = kAMSelectPrintCarouselImageWidth;
            itemView.frame = frame;
            view = itemView;
        }
    }
    
    return view;
    //    }
}

- (void)createAndSeedImageCache {
    NSUInteger count = [self.kiosk.photos count];
    imageCache = [[NSMutableDictionary alloc] initWithCapacity:count];

    // Seed a default / marketing photo.

    UIImage *photoImage = [self getPlaceholderPhoto];
    if (photoImage) {
        [imageCache setObject:photoImage forKey:kAMImageFileNameNothingToPrint];
    }

    // Now loop through each kiosk photo and add it.
    for (Photo *photo in self.kiosk.photos) {
        photoImage = [self loadPhotoImage:photo];
        [imageCache setObject:photoImage forKey:photo.photoUrl];
    }
}

- (UIImage *)loadPhotoImage:(Photo *)photo {
    UIImage *image;
//    NSString *urlStr = [self.kiosk.storePath stringByAppendingPathComponent:photo.photoUrl];
    NSString *urlStr = photo.photoUrl;

    // Verify this item before attempting to load it.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:urlStr]) {
        urlStr = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"problems.jpg"];
    }
    
    image = [UIImage imageWithContentsOfFile:urlStr];
    return image;
}

- (NSUInteger)numberOfPlaceholdersInCarousel:(iCarousel *)carousel
{
    //note: placeholder views are only displayed on some carousels if wrapping is disabled
    return 0;
}

- (CGFloat)carouselItemWidth:(iCarousel *)carousel
{
    //usually this should be slightly wider than the item views
    return kAMSelectPrintCarouselImageWidth + 20;
}

//- (BOOL)carouselShouldWrap:(iCarousel *)carousel {
//    return YES;
//}
//
- (CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value;
{
    if (option == iCarouselOptionWrap) {
        // wrap the carousel for infinite scroll
        return NO;
    } else {
        return value;
    }
}

- (void)carouselCurrentItemIndexDidChange:(iCarousel *)carousel
{
    // we stopped on an item
    // Show the description for the image.
    //    PhotoLayout *photoLayout = [self.kiosk.photoLayouts objectAtIndex:self.backgroundCarousel.currentItemIndex];
    //    [description setText:[NSString stringWithFormat:@"%@", photoLayout.desc]];
    NSString *captionText = @"";
    NSInteger selectedIndex = self.printSelectionCarousel.currentItemIndex;
    if (self.kiosk.photos.count > 0)
    {
    if (selectedIndex > 0) {
        Photo *photo = [self.kiosk.photos objectAtIndex:self.printSelectionCarousel.currentItemIndex];
        captionText = [self.dateFormatter stringFromDate:photo.createdOn];
    }
    }
    [self.caption setText:captionText];
}

- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index
{
    if (index == self.printSelectionCarousel.currentItemIndex) {
        [self performSegueWithIdentifier:@"confirm" sender:nil];
    }
}

- (void)didSelectPhoto {
    // Tell the Kiosk to start a photo session.
    NSInteger selectionIndex = self.printSelectionCarousel.currentItemIndex;
    if (self.kiosk.photos.count == 0) {
        if (selectionIndex == 0) {
            self.kiosk.selectedPhoto = [self getPlaceholderPhoto];
        } else {
            Photo *photo = [self.kiosk.photos objectAtIndex:self.printSelectionCarousel.currentItemIndex - 1];
            self.kiosk.selectedPhoto = [imageCache objectForKey:photo.photoUrl];
        }
    }
    else
    {
        Photo *photo = [self.kiosk.photos objectAtIndex:self.printSelectionCarousel.currentItemIndex];
        self.kiosk.selectedPhoto = [imageCache objectForKey:photo.photoUrl];
    }
}

//- (BOOL)backgroundCarousel:(iCarousel *)backgroundCarousel shouldSelectItemAtIndex:(NSInteger)index
//{
//    NSLog(@"%s", __FUNCTION__);
//    return YES;
//}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];
    if ([[segue identifier] isEqualToString:@"confirm"])
    {
        [self didSelectPhoto];
    }
}

- (UIImage *)getPlaceholderPhoto {
    return [UIImage imageNamed:kAMImageFileNameNothingToPrint];
}

- (IBAction)refreshButtonTouched:(id)sender {
    [self checkForNewPhotos];
}

- (void)checkForNewPhotos {
    [self.kiosk downloadPrintablePhotoMetadataFromKiosk];
    [self.printSelectionCarousel reloadData];
    
}

//
//  Receive from an arbitrary thread and recurse on main thread, as we may be
//  updating the ui.
//
- (void)receiveNewPhotoObjectAvailable:(NSNotification *)notification {
    
    if ([NSThread isMainThread]) {
        NSString *fileName = notification.object;
        if (fileName) {
            BOOL haveNew = NO;
            [self.kiosk loadPhotos];

            // Now loop through each kiosk photo and add it, if we don't already have it.
            for (Photo *photo in self.kiosk.photos) {
                NSString *cacheKey = photo.photoUrl;
                UIImage *photoImage = [imageCache objectForKey:cacheKey];
                if (!photoImage) {
                    // We don't already have this one
                    photoImage = [self loadPhotoImage:photo];
                    if (photoImage) {
                        [imageCache setObject:photoImage forKey:photo.photoUrl];
                        haveNew = YES;
                    }
                }
            }
            
            if (haveNew) {
                [self.printSelectionCarousel reloadData];
            }
        }
    } else {
        [self performSelectorOnMainThread:@selector(receiveNewPhotoAvailable:) withObject:notification waitUntilDone:YES];
    }
}

- (void)receiveRefreshPrintContentDisplay:(NSNotification *)notification {
    
    if ([NSThread isMainThread]) {
        if (!self.kiosk.userIsPresent) {
            [self.printSelectionCarousel reloadData];
        }
    } else {
        [self performSelectorOnMainThread:@selector(receiveRefreshPrintContentDisplay:) withObject:notification waitUntilDone:YES];
    }
}

#pragma mark -
#pragma mark - PIN Pad

- (void)authorizePrint {
    //???    [self performSegueWithIdentifier:@"approve" sender:nil];
    //    ABPadLockScreenSetupViewController *lockScreen = [[ABPadLockScreenSetupViewController alloc] initWithDelegate:self
    //                                                                                                       complexPin:NO];
    ABPadLockScreenViewController *lockScreen = [[ABPadLockScreenViewController alloc] initWithDelegate:self complexPin:NO];
    
    lockScreen.modalPresentationStyle = UIModalPresentationFullScreen;
    lockScreen.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    
    //    //Example using an image
    //    UIImageView* backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"wallpaper"]];
    //    backgroundView.contentMode = UIViewContentModeScaleAspectFill;
    //    backgroundView.clipsToBounds = YES;
    //    [lockScreen setBackgroundView:backgroundView];
    
    [self presentViewController:lockScreen animated:YES completion:nil];
}

//- (IBAction)lockApp:(id)sender
//{
//    if (!self.thePin)
//    {
//        [[[UIAlertView alloc] initWithTitle:@"No Pin" message:@"Please Set a pin before trying to unlock" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
//        return;
//    }
//
//    ABPadLockScreenViewController *lockScreen = [[ABPadLockScreenViewController alloc] initWithDelegate:self complexPin:YES];
//    [lockScreen setAllowedAttempts:3];
//
//    lockScreen.modalPresentationStyle = UIModalPresentationFullScreen;
//    lockScreen.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
//
//	//Example using an image
//	UIImageView* backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"wallpaper"]];
//	backgroundView.contentMode = UIViewContentModeScaleAspectFill;
//	backgroundView.clipsToBounds = YES;
//	[lockScreen setBackgroundView:backgroundView];
//
//    [self presentViewController:lockScreen animated:YES completion:nil];
//}

#pragma mark -
#pragma mark - ABLockScreenDelegate Methods

- (BOOL)padLockScreenViewController:(ABPadLockScreenViewController *)padLockScreenViewController
                        validatePin:(NSString*)pin;
{
    NSLog(@"Validating pin %@", pin);
    
    return [pin isEqualToString:self.lockPIN];
}

- (void)unlockWasSuccessfulForPadLockScreenViewController:(ABPadLockScreenViewController *)padLockScreenViewController
{
    [padLockScreenViewController dismissViewControllerAnimated:YES completion:nil];
   // [self printSelectedPhoto];
}

- (void)unlockWasUnsuccessful:(NSString *)falsePin afterAttemptNumber:(NSInteger)attemptNumber
  padLockScreenViewController:(ABPadLockScreenViewController *)padLockScreenViewController
{
    NSLog(@"Failed attempt number %ld with pin: %@", (long)attemptNumber, falsePin);
}

- (void)unlockWasCancelledForPadLockScreenViewController:(ABPadLockScreenAbstractViewController *)padLockScreenViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
    //    NSLog(@"Pin entry cancelled");
}

- (void)attemptsExpiredForPadLockScreenViewController:(ABPadLockScreenViewController *)padLockScreenViewController {
    //    NSLog(@"Pin entry cancelled");
    [self dismissViewControllerAnimated:YES completion:nil];
}



@end
