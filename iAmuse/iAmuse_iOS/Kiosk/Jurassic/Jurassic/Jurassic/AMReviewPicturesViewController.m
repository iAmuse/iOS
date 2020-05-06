//
//  AMTakingPicturesViewController.m
//  Jurassic
//
//  Created by Roland Hordos on 2013-07-07.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import "AMReviewPicturesViewController.h"
#import "CTKiosk.h"
#import "AMConstants.h"
#import "PhotoSession.h"
#import "Photo.h"
#import "CTSelectSceneViewController.h"

@interface AMReviewPicturesViewController ()
{
    NSInteger currentShowingImageIndex;
      NSTimer *idleTimer;
}
@end

#define kMaxIdleTimeSeconds 60.0

@implementation AMReviewPicturesViewController

@synthesize workflow = _workflow;
//@synthesize workflow;

#pragma mark - Lifecycle

- (void)dealloc
{
    NSLog(@"%s", __FUNCTION__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    //NSLog(@"%s", __FUNCTION__);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLoad
{
    
  //   [self resetIdleTimer];
    
    _confirmButton.layer.cornerRadius = 3; // this value vary as per your desire
    _confirmButton.clipsToBounds = YES;
    
    //NSLog(@"%s", __FUNCTION__);
    [super viewDidLoad];

//    self.sharingVC = nil;
    _workflow = AMWorkflowNormalCourse;

    // Load theme assets.
    CTKiosk *kiosk = [CTKiosk sharedInstance];
  //  NSString *assetPath = [kiosk.storePath stringByAppendingPathComponent:@"header.png"];
  //  self.header.image = [UIImage imageWithContentsOfFile:assetPath];
 //   assetPath = [kiosk.storePath stringByAppendingPathComponent:@"footer.png"];
 //   self.footer.image = [UIImage imageWithContentsOfFile:assetPath];

    photo1 = nil;
    photo2 = nil;
    photo3 = nil;

    // Hide all picture views
    self.picture1View.layer.cornerRadius = 15;
    self.picture2View.layer.cornerRadius = 15;
    self.picture3View.layer.cornerRadius = 15;
    
    [self resetPictureTaking];
    
    // The photos have already arrived, show their previews in the
    long photoCount = [kiosk.currentPhotoSession.entity.photos count];
    NSLog(@"Photo count: %ld", photoCount);
    
    // Get an array of pictures sorted by date time.
    NSSortDescriptor * sort = [NSSortDescriptor sortDescriptorWithKey:@"createdOn" ascending:YES];
    NSArray * photos = [kiosk.currentPhotoSession.entity.photos sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
    
    if (photoCount > 0)
    {
        photo1 = photos[0];
        self.picture1View.image = [UIImage imageWithContentsOfFile:photo1.photoUrl];
    }
    else
    {
        photo1 = nil;
        self.picture1View.image = nil;
    }
    
    if (photoCount > 1)
    {
        photo2 = photos[1];
        self.picture2View.image = [UIImage imageWithContentsOfFile:photo2.photoUrl];
    }
    else
    {
        photo2 = nil;
        self.picture2View.image = nil;
    }
    
    if (photoCount > 2)
    {
        photo3 = photos[2];
        self.picture3View.image = [UIImage imageWithContentsOfFile:photo3.photoUrl];
    }
    else
    {
        photo3 = nil;
        self.picture3View.image = nil;
    }
    _select1Button.selected = YES;
    _select2Button.selected = YES;
    _select3Button.selected = YES;
    [selectedPhotos addObject:photo1];
    [selectedPhotos addObject:photo2];
    [selectedPhotos addObject:photo3];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return  UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

- (void)viewWillAppear:(BOOL)animated
{
    //NSLog(@"%s", __FUNCTION__);
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //NSLog(@"%s", __FUNCTION__);
    if (_workflow == AMWorkflowResetToSplash)
    {
//        [self goBack];
//        self.sharingVC = nil;
        _workflow = AMWorkflowNormalCourse;
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    //NSLog(@"%s", __FUNCTION__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Picture Selection

- (IBAction)select1Touched:(id)sender
{
//    if (photo1)
//    {
//        CTKiosk *kiosk = [CTKiosk sharedInstance];
//        [kiosk selectPhoto:photo1];
//        [self pictureSelected];
//    }
    UIButton * firstBtn = (UIButton *)sender;
    firstBtn.selected = !firstBtn.selected;
    if (firstBtn.selected)
    {
        [selectedPhotos addObject:photo1];
    }
    else
    {
        [selectedPhotos removeObject:photo1];
    }
}

- (IBAction)select2Touched:(id)sender
{
//    if (photo2)
//    {
//        CTKiosk *kiosk = [CTKiosk sharedInstance];
//        [kiosk selectPhoto:photo2];
//        [self pictureSelected];
//    }
    UIButton * secondBtn = (UIButton *)sender;
    secondBtn.selected = !secondBtn.selected;
    if (secondBtn.selected)
    {
        [selectedPhotos addObject:photo2];
    }
    else
    {
        [selectedPhotos removeObject:photo2];
    }
}

- (IBAction)select3Touched:(id)sender
{
//    if (photo3)
//    {
//        CTKiosk *kiosk = [CTKiosk sharedInstance];
//        [kiosk selectPhoto:photo3];
//        [self pictureSelected];
//    }
    UIButton * thirdBtn = (UIButton *)sender;
    thirdBtn.selected = !thirdBtn.selected;
    if (thirdBtn.selected)
    {
        [selectedPhotos addObject:photo3];
    }
    else
    {
        [selectedPhotos removeObject:photo3];
    }
}

- (IBAction)doneButtonClicked:(UIButton *)sender
{
    if ([selectedPhotos count] > 0)
    {
        CTKiosk * kiosk = [CTKiosk sharedInstance];
        [kiosk saveSelectedPhotos:selectedPhotos];

        switch ([selectedPhotos count])
        {
            case 1:
            {
                Photo * photo = [selectedPhotos objectAtIndex:0];
                [kiosk selectedPhotoFromReviewPicture:photo];
            }
                break;
            case 2:
            {
                [self performSelector:@selector(sendSelectedPhoto:) withObject:[selectedPhotos objectAtIndex:0] afterDelay:0.1];
                [self performSelector:@selector(sendSelectedPhoto:) withObject:[selectedPhotos objectAtIndex:1] afterDelay:0.6];
            }
                break;
            case 3:
            {
                [self performSelector:@selector(sendSelectedPhoto:) withObject:[selectedPhotos objectAtIndex:0] afterDelay:0.1];
                [self performSelector:@selector(sendSelectedPhoto:) withObject:[selectedPhotos objectAtIndex:1] afterDelay:0.6];
                [self performSelector:@selector(sendSelectedPhoto:) withObject:[selectedPhotos objectAtIndex:2] afterDelay:1.1];
            }
                break;
               default:
                break;
        }
        
        [self pictureSelected];
    }
    else
    {
       // Show alert to select any one image
        [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Please select atleast one image to send." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
    }
}

- (IBAction)selectToZoomClicked:(UIButton *)sender
{
    blackBackView.hidden = NO;
    clearBackView.hidden = NO;
    
    UIScrollView * scrollView = (UIScrollView *)[clearBackView viewWithTag:521];
    scrollView.layer.cornerRadius = 8.0;
    scrollView.layer.masksToBounds = YES;
    scrollView.layer.borderColor = [[UIColor grayColor] CGColor];
    scrollView.layer.borderWidth = 2.0f;
    scrollView.pagingEnabled = YES;
    //scrollView.zoomScale = 2.0f;
    scrollView.minimumZoomScale = 1.0f;
    scrollView.maximumZoomScale = 2.0f;
  
    UIImageView * imageView = (UIImageView *)[clearBackView viewWithTag:511];
    
    imageView.frame = CGRectMake(0, 0, scrollView.frame.size.width, scrollView.frame.size.height);
    imageView.transform = CGAffineTransformIdentity;
    [scrollView setContentSize:CGSizeMake(scrollView.frame.size.width, scrollView.frame.size.height)];

    NSString *string = [[NSUserDefaults standardUserDefaults] valueForKey:kAMImageRatioUserDefaultsKey];
    if (([string isEqualToString:AMRatioModeStrAspectFit])||([string length] == 0))
    {
        imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    else if ([string isEqualToString:AMRatioModeStrAspectFill])
    {
        imageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    else
    {
        imageView.contentMode = UIViewContentModeScaleToFill;
    }
    
    switch (sender.tag)
    {
        case 121:
        {
            currentShowingImageIndex = 1;
            NSLog(@"121 button clicked");
            imageView.image = [UIImage imageWithContentsOfFile:photo1.photoUrl];
        }
            break;
        case 122:
        {
            currentShowingImageIndex = 2;
            NSLog(@"122 button clicked");
            imageView.image = [UIImage imageWithContentsOfFile:photo2.photoUrl];
        }
            break;
        case 123:
        {
            currentShowingImageIndex = 3;
            NSLog(@"123 button clicked");
            imageView.image = [UIImage imageWithContentsOfFile:photo3.photoUrl];
        }
            break;
        default:
            break;
    }
    scrollView.contentSize = CGSizeMake(imageView.frame.size.width, imageView.frame.size.height);

}

- (IBAction)showNextImage:(UIButton *)sender {
    
    UIScrollView * scrollView = (UIScrollView *)[clearBackView viewWithTag:521];
    UIImageView * imageView = (UIImageView *)[clearBackView viewWithTag:511];
    
    imageView.frame = CGRectMake(0, 0, scrollView.frame.size.width, scrollView.frame.size.height);
    imageView.transform = CGAffineTransformIdentity;
    [scrollView setContentSize:CGSizeMake(scrollView.frame.size.width, scrollView.frame.size.height)];
    NSString *string = [[NSUserDefaults standardUserDefaults] valueForKey:kAMImageRatioUserDefaultsKey];
    if (([string isEqualToString:AMRatioModeStrAspectFit])||([string length] == 0))
    {
        imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    else if ([string isEqualToString:AMRatioModeStrAspectFill])
    {
        imageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    else
    {
        imageView.contentMode = UIViewContentModeScaleToFill;
    }
    if (sender.tag == 101) {
        if (currentShowingImageIndex == 1) {
            currentShowingImageIndex = 3;
            imageView.image = [UIImage imageWithContentsOfFile:photo3.photoUrl];
        }
        else if (currentShowingImageIndex == 2)
        {
            currentShowingImageIndex = 1;
            imageView.image = [UIImage imageWithContentsOfFile:photo1.photoUrl];
        }
        else
        {
            currentShowingImageIndex = 2;
            imageView.image = [UIImage imageWithContentsOfFile:photo2.photoUrl];
        }
    }
    else
    {
        if (currentShowingImageIndex == 2) {
            currentShowingImageIndex = 3;
            imageView.image = [UIImage imageWithContentsOfFile:photo3.photoUrl];
        }
        else if (currentShowingImageIndex == 1)
        {
            imageView.image = [UIImage imageWithContentsOfFile:photo2.photoUrl];
            currentShowingImageIndex = 2;
        }
        else
        {
            currentShowingImageIndex = 1;
            imageView.image = [UIImage imageWithContentsOfFile:photo1.photoUrl];
        }
    }
}

- (IBAction)hideBlackView:(UIButton *)sender
{
    blackBackView.hidden = YES;
    clearBackView.hidden = YES;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    NSLog(@"zooming");
  //  int page = scrollView.contentOffset.x / scrollView.frame.size.width;
   // UIImageView * imageView = (UIImageView *)[scrollView viewWithTag:page+1];
    UIImageView * imageView = (UIImageView *)[clearBackView viewWithTag:511];

    return imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    NSLog(@"helloscrollViewDidZoom");
    
    /// method for centring the image
    
    UIImageView * imageView = (UIImageView *)[clearBackView viewWithTag:511];
    imageView.frame = [self centeredFrameForScrollView:scrollView andUIView:imageView];
}

- (CGRect)centeredFrameForScrollView:(UIScrollView *)scroll andUIView:(UIView *)rView
{
    NSLog(@"hellocenteredFrameForScrollView");
    CGSize boundsSize = scroll.bounds.size;
    CGRect frameToCenter = rView.frame;
    // center horizontally
    if (frameToCenter.size.width < boundsSize.width)
    {
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    }
    else
    {
        frameToCenter.origin.x = 0;
    }
    // center vertically
    if (frameToCenter.size.height < boundsSize.height)
    {
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    }
    else
    {
        frameToCenter.origin.y = 0;
    }
    return frameToCenter;
}

- (void)sendSelectedPhoto:(Photo *)photo
{
    CTKiosk * kiosk = [CTKiosk sharedInstance];
    [kiosk selectedPhotoFromReviewPicture:photo];
}

- (void)pictureSelected
{
    // Don't generate any more pictures if there are more in the shoot.
    [[CTKiosk sharedInstance] pausePhotoSession];

    [self performSegueWithIdentifier:@"Sharing" sender:nil];
}

#pragma mark - Navigation

//
//  Reset the picture views and prepare for the next session.
//
- (void)resetPictureTaking
{
    self.picture3View.hidden = NO;
    self.picture2View.hidden = NO;
    self.picture1View.hidden = NO;

    self.picture1View.image = nil;
    self.picture2View.image = nil;
    self.picture3View.image = nil;
    
    selectedPhotos = [[NSMutableArray alloc] init];
}

- (void)goBack
{
    id presenter = self.presentingViewController;
    if ([presenter conformsToProtocol:@protocol(TakingPicturesCompleteDelegate)])
    {
//        [self resetPictureTaking];
        // Before we leave release our forward controller.
//        self.sharingVC = nil;
        [presenter takingPicturesViewController:self didFinishWithWorkflow:_workflow];
    }
    else if (self.navigationController)
    {
        // Go back 2 steps from here, don't leave the user on the "Face the TV" screen.
        NSArray *viewControllers = self.navigationController.viewControllers;
        for (UIViewController *anVC in viewControllers) {
            if ([anVC isKindOfClass:[CTSelectSceneViewController class] ]){
                [self.navigationController popToViewController:anVC animated:NO];
                break;
            }
        }
//        [self.navigationController popToViewController:[[self navigationController].viewControllers objectAtIndex:2] animated:NO];
    }
    else
    {
        NSLog(@"Unplanned scenario, our presenter is %@",
                NSStringFromClass([presenter class]));
    }
}

- (void)sharingViewController:(AMSharingViewController *)sharingViewController
        didFinishWithWorkflow:(NSString *)workflow
{
    // Close the modal.
    if ([workflow isEqualToString:AMWorkflowResetToSplash]) {
        _workflow = workflow;
//        self.sharingVC = nil;
        __block AMReviewPicturesViewController *this = self;
        [self dismissViewControllerAnimated:NO completion: ^{
            NSLog(@"%s", __FUNCTION__);
            id presenter = this.presentingViewController;
            if ([presenter conformsToProtocol:@protocol(TakingPicturesCompleteDelegate)]) {
//                [this resetPictureTaking];
                [presenter takingPicturesViewController:self didFinishWithWorkflow:AMWorkflowResetToSplash];
            } else {
                NSLog(@"Unplanned scenario, our presenter is %@",
                        NSStringFromClass([presenter class]));
            }
        }];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion: nil];
    }
}

- (IBAction)backButton:(id)sender
{
    // Close the camera in preparation for a different background selection.
    [[CTKiosk sharedInstance] pausePhotoSession];
    [[CTKiosk sharedInstance] removeLookAtiPadScreen];

    [self goBack];
}


- (void)resetIdleTimer {
    if (!idleTimer) {
        idleTimer = [NSTimer scheduledTimerWithTimeInterval:kMaxIdleTimeSeconds
                                                     target:self
                                                   selector:@selector(idleTimerExceeded)
                                                   userInfo:nil
                                                    repeats:NO];
    }
    else {
        if (fabs([idleTimer.fireDate timeIntervalSinceNow]) < kMaxIdleTimeSeconds-1.0) {
            [idleTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:kMaxIdleTimeSeconds]];
        }
    }
}

- (void)idleTimerExceeded {
   // idleTimer = nil;
    [idleTimer invalidate];
    
    NSLog(@"time elapased");
    
    
    
//    CTSelectSceneViewController *move = [self.storyboard instantiateViewControllerWithIdentifier:@"selectSceneViewController"];
//    [self presentViewController:move animated:YES completion:nil];
    
//    UIViewController *viewController;
//    viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"selectSceneViewController"];
//    [self.navigationController pushViewController:viewController animated:YES];
    
    
    if (self.navigationController) {
        NSArray *viewControllers = self.navigationController.viewControllers;
        for (UIViewController *anVC in viewControllers) {
            if ([anVC isKindOfClass:[CTSelectSceneViewController class] ]){
                [self.navigationController popToViewController:anVC animated:NO];
                break;
            }
        }
    }
    
    
    //   [self resetIdleTimer];
    
    
}

- (UIResponder *)nextResponder {
    [self resetIdleTimer];
    return [super nextResponder];
}


@end
