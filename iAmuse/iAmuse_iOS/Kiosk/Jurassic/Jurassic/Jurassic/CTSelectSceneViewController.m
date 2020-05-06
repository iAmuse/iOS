//
//  CTSelectSceneViewController.m
//  Jurassic
//
//  Created by Roland Hordos on 2013-06-01.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import "CTSelectSceneViewController.h"
#import "CTKiosk.h"
#import "PhotoLayout.h"
#import "ABPadLockScreenViewController.h"
#import "PhotoSession.h"
#import "CTGetReadyViewController.h"
#import "AMConstants.h"
#import "AMTakingPicturesViewController.h"
#import "M13Checkbox.h"
#import "CTAppDelegate.h"

@interface CTSelectSceneViewController ()
{
    ABPadLockScreenViewController *lockScreen;
     UIImageView *checkImage1;
}
@end

@implementation CTSelectSceneViewController

@synthesize backgroundCarousel, wrap, settingsTapRecognizer;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    //NSLog(@"%s", __FUNCTION__);

    if(self = [super initWithCoder:aDecoder])
    {
        wrap = NO;
        imageCache = nil;
        self.kiosk = [CTKiosk sharedInstance];
    }
    
    return self;
}

- (void)dealloc
{
    //NSLog(@"%s", __FUNCTION__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations
{
    return  UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

- (void)viewDidLoad
{
    checkImage1 =[[UIImageView alloc]init];
    
//    CTAppDelegate *appDel = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
//    NSLog(@"offset values in selectscene is %@",appDel.sharedArray);
    
    
    _backButton.hidden=YES;
    
    _backButton.layer.cornerRadius = 3; // this value vary as per your desire
    _backButton.clipsToBounds = YES;
    
    //NSLog(@"%s", __FUNCTION__);

    self.getReadyVC = nil;
    backgroundCarousel.type = iCarouselTypeCoverFlow;

    [super viewDidLoad];
    
    
   
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateEventNotification:)
                                                 name:@"UpdateEventNotification"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showSettingScreen1:)
                                                 name:@"OpenSettingSceneNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showSettingScreen1:)
                                                 name:@"showSettingScreen"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lockCancel1:)
                                                 name:@"lockCancel"
                                               object:nil];
    
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewsSwipe1:)];
    swipeUp.numberOfTouchesRequired = 2;
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    swipeUp.delaysTouchesBegan = YES;
    [self.view addGestureRecognizer:swipeUp];
    
    
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewsSwipe1:)];
    swipeDown.numberOfTouchesRequired = 2;
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    swipeDown.delaysTouchesBegan = YES;
    [self.view addGestureRecognizer:swipeDown];
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewsSwipe1:)];
    swipeRight.numberOfTouchesRequired = 2;
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    swipeRight.delaysTouchesBegan = YES;
    [self.view addGestureRecognizer:swipeRight];
    
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewsSwipe1:)];
    swipeLeft.numberOfTouchesRequired = 2;
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    swipeLeft.delaysTouchesBegan = YES;
    [self.view addGestureRecognizer:swipeLeft];
    //showSettingScreen1 in placeof to hide lock screen handleViewsSwipe1
    
    
    
    
    UISwipeGestureRecognizer *swipeUpa = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewsSwipe1:)];
    swipeUpa.numberOfTouchesRequired = 3;
    swipeUpa.direction = UISwipeGestureRecognizerDirectionUp;
    swipeUpa.delaysTouchesBegan = YES;
    [self.view addGestureRecognizer:swipeUpa];
    
    
    UISwipeGestureRecognizer *swipeDowna = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewsSwipe1:)];
    swipeDowna.numberOfTouchesRequired = 3;
    swipeDowna.direction = UISwipeGestureRecognizerDirectionDown;
    swipeDowna.delaysTouchesBegan = YES;
    [self.view addGestureRecognizer:swipeDowna];
    
    UISwipeGestureRecognizer *swipeRighta = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewsSwipe1:)];
    swipeRighta.numberOfTouchesRequired = 3;
    swipeRighta.direction = UISwipeGestureRecognizerDirectionRight;
    swipeRighta.delaysTouchesBegan = YES;
    [self.view addGestureRecognizer:swipeRighta];
    
    UISwipeGestureRecognizer *swipeLefta = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewsSwipe1:)];
    swipeLefta.numberOfTouchesRequired = 3;
    swipeLefta.direction = UISwipeGestureRecognizerDirectionLeft;
    swipeLefta.delaysTouchesBegan = YES;
    [self.view addGestureRecognizer:swipeLefta];
    

//    self.kiosk = [CTKiosk sharedInstance];

    // Default workflow.
    _workflow = AMWorkflowNormalCourse;

    // Load theme assets.
    NSString * assetPath = [self.kiosk.storePath stringByAppendingPathComponent:@"header.png"];
    self.header.image = [UIImage imageWithContentsOfFile:assetPath];
    assetPath = [self.kiosk.storePath stringByAppendingPathComponent:@"footer.png"];
    self.footer.image = [UIImage imageWithContentsOfFile:assetPath];

    // Flip the carousel to the middle of the deck.
//    NSInteger startIndex = [self.kiosk.photoLayouts count] / 2;
    // Change of plans, move back to beginning.  We move off the first item to
    // enable the eventing for prepping an image.
    NSInteger startIndex = 1;
    [backgroundCarousel scrollToItemAtIndex:startIndex duration:1.0f];
    if ([self.kiosk.photoLayouts count] == 1) {
        PhotoLayout *photoLayout = [self.kiosk.photoLayouts objectAtIndex:0];
        [description setText:[NSString stringWithFormat:@"%@", photoLayout.desc]];
    }
   
}

- (void)handleViewsSwipe1:(UISwipeGestureRecognizer *)recognizer
{
    
    NSUInteger touches = recognizer.numberOfTouches;
    if (touches == 3)
    {
        //[self authorizePrint1];
    }
    
    else if(touches == 2)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(showSettingScreen2:)
                                                     name:@"showEvent"
                                                   object:nil];
        
        
        lockScreen = [[ABPadLockScreenViewController alloc] initWithDelegate:nil complexPin:NO];
        // lockScreen.showSetting = YES;
        
        
        lockScreen.modalPresentationStyle = UIModalPresentationFullScreen;
        [lockScreen cancelButtonDisabled:NO];
        lockScreen.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        
        [self presentViewController:lockScreen animated:YES completion:nil];
        
        
        
//        id presenter = self.presentingViewController;
//        if ([presenter conformsToProtocol:@protocol(SceneSelectionCompleteDelegate)])
//        {
//            [presenter sceneSelectionViewController:self didFinishWithWorkflow:AMWorkflowGoBack];
//        }
//        else if (self.navigationController)
//        {
//            [[CTKiosk sharedInstance] backToEventScene];
//            [self.navigationController popViewControllerAnimated:YES];
//            //    [self dismissViewControllerAnimated:YES completion:nil];
//        }
//        else
//        {
//            NSLog(@"Unplanned scenario, our presenter is %@", NSStringFromClass([presenter class]));
//        }
    }
}


- (void)showSettingScreen2:(NSNotification *)notification
{
    [lockScreen dismissViewControllerAnimated:NO completion:nil];
    
    id presenter = self.presentingViewController;
    if ([presenter conformsToProtocol:@protocol(SceneSelectionCompleteDelegate)])
    {
        [presenter sceneSelectionViewController:self didFinishWithWorkflow:AMWorkflowGoBack];
    }
    else if (self.navigationController)
    {
        [[CTKiosk sharedInstance] backToEventScene];
        [self.navigationController popViewControllerAnimated:YES];
        //    [self dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        NSLog(@"Unplanned scenario, our presenter is %@", NSStringFromClass([presenter class]));
    }
    
    //  [self performSegueWithIdentifier:@"settings" sender:self];
    //  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"OpenSettingSceneNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"showSettingScreen" object:nil];
    //  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"lockCancel" object:nil];
    
}





- (void)authorizePrint1 {
    
    lockScreen = [[ABPadLockScreenViewController alloc] initWithDelegate:nil complexPin:NO];
    lockScreen.showSetting = YES;
    
    
    lockScreen.modalPresentationStyle = UIModalPresentationFullScreen;
    [lockScreen cancelButtonDisabled:NO];
    lockScreen.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    
    [self presentViewController:lockScreen animated:YES completion:nil];
}

- (void)updateEventNotification:(NSNotification *)notification
{
    [backgroundCarousel reloadData];
}

- (void)lockCancel1:(NSNotification *)notification
{
    [lockScreen dismissViewControllerAnimated:NO completion:nil];
}

- (void)showSettingScreen1:(NSNotification *)notification
{
    [lockScreen dismissViewControllerAnimated:NO completion:nil];
    
    [self performSegueWithIdentifier:@"settings" sender:self];
}

- (void)viewDidAppear:(BOOL)animated
{
//    NSLog(@"%s", __FUNCTION__);
    [self.navigationController setNavigationBarHidden: YES animated:YES];
    [super viewDidAppear:animated];

    if (_workflow == AMWorkflowResetToSplash)
    {
    //    [self goBack];
        _workflow = AMWorkflowNormalCourse;
    }
    else
    {
        // Observe when we feel the user has left.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(userDidLeave:)
                                                     name:AMUserDidLeave
                                                   object:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    return [self.kiosk.photoLayouts count];
}

//
//  Keep track of images by index.  The picture at an index will not change, so
//  we can track the re-use view by tag to verify if it already has the content
//  we need.
//
- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view
{
//    NSLog(@"%s", __FUNCTION__);
//    @synchronized (self) {
//        NSNumber *key = [NSNumber numberWithUnsignedInteger:index];
    BOOL load = YES;
    UIImageView * itemView = nil;
    
    UIImage * backgroundImage = nil;
    
    PhotoLayout * photoLayout = [self.kiosk getPhotoLayoutAtIndex:index];
    if (view)
    {
        // trying to re-use a view ..
        if (view.tag == index)
        {
            load = NO;
        }
    }

    if (load)
    {
        // Try image cache first
        if (!imageCache)
        {
            [self createAndSeedImageCache];
        }

        backgroundImage = [imageCache objectForKey:photoLayout.background];
        if (!backgroundImage)
        {
            // We haven't loaded this image yet, do so and cache it too.
            backgroundImage = [self loadBackgroundImage:photoLayout];
            [imageCache setObject:backgroundImage forKey:photoLayout.background];
        }

        if (view)
        {
            if ([view isKindOfClass:UIImageView.class])
            {
                ((UIImageView *)view).image = backgroundImage;
                view.tag = index;
            }
        }
        else
        {
          //  itemView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 600.0f, 600.0f)];
            itemView = [[UIImageView alloc] initWithImage:backgroundImage];
            
            UIImage *checking = [UIImage imageNamed:@"zoomProfile.png"];
            
            float x=[photoLayout.xOffset floatValue];
            float y=[photoLayout.yOffset floatValue];
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSString * imageHeight = [defaults stringForKey:@"imageHeight"];
            
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//            NSArray *arrayOfImages = [userDefaults objectForKey:@"imgHeightCheck"];
//            NSArray *arrayOfText = [userDefaults objectForKey:@"imgWidthCheck"];
            
//            NSString * imageHe = [arrayOfImages objectAtIndex:self.backgroundCarousel.currentItemIndex];
//            NSString * imageWi = [arrayOfText objectAtIndex:self.backgroundCarousel.currentItemIndex];
            
//            NSString * imageHe = [arrayOfImages objectAtIndex:index];
//            NSString * imageWi = [arrayOfText objectAtIndex:index];
            
//            float imgwidth =[imageHe floatValue];
//            float imgheight = [imageWi floatValue];
          
           
//             CTAppDelegate *appDel = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
//
//             NSString * imageHei = [appDel.sharedArray objectAtIndex:self.backgroundCarousel.currentItemIndex];
// NSLog(@"ready height is %@",imageHei);
            
          //  x= x*(500.00/1023);
         //   y=y*(300.00/[imageHeight floatValue]);
            
            float width =[photoLayout.cameraWidth floatValue];
            float height = [photoLayout.cameraHieght floatValue];
            
          //  UIImage *overlayIamge = [self drawImage:checking inImage:backgroundImage atPoint:CGPointMake(x, y)];
            
//            UIImage *overlayIamge =[self drawImage:checking inImage:backgroundImage atPoint:CGPointMake(x, y) atWidth:width atHeight:height];
            
//            UIImage *overlayIamge = [self drawImage:checking inImage:backgroundImage atPoint:CGPointMake(x, y) atWidth:width atHeight:height atimgWidth:imgwidth atimgHeight:imgheight];
            
          //  itemView = [[UIImageView alloc] initWithImage:overlayIamge];
            
            itemView.tag = index;
            itemView.contentMode = UIViewContentModeScaleAspectFill;

            //change width of frame
            CGRect frame = itemView.frame;
            frame.size.width = kAMSelectSceneCarouselImageWidth;
            NSUserDefaults * userdefault = [NSUserDefaults standardUserDefaults];
            NSString * deviceModePref = [userdefault stringForKey:AMDeviceModeSettingsKey];
            if (![deviceModePref isEqualToString:AMDeviceModeStrCamera])
            {
                if((UI_USER_INTERFACE_IDIOM()) != UIUserInterfaceIdiomPhone)
                {
                    if (frame.size.height > 440) {
                        frame.size.height = 440;
                    }
                }
                else
                {
                    CGFloat value;
                    if (self.view.frame.size.width > self.view.frame.size.height) {
                        value = self.view.frame.size.height;
                    }
                    else
                    {
                        value = self.view.frame.size.width;
                    }
                    frame.size.height = value - 140;
                }
            }
            
            itemView.frame = frame;
            view = itemView;
            
            
           
            
            
            
            
            
            
             PhotoLayout *photoLayout = [self.kiosk.photoLayouts objectAtIndex:self.backgroundCarousel.currentItemIndex];
            NSLog(@"pholayout in select scene is %@",photoLayout);
            NSLog(@"current item index is %d",self.backgroundCarousel.currentItemIndex);
            
//            UIImageView *checkImage;
//             CTAppDelegate *appDel = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
//            NSLog(@"index values is %lu",(unsigned long)index);
//            checkImage = [[UIImageView alloc] initWithFrame:CGRectMake(-80, -150, 800.0f, 800.0f)];
//            checkImage.image = [UIImage imageNamed:@"Right mark.png"];
//            checkImage.contentMode = UIViewContentModeCenter;
//            [view addSubview:checkImage];
            
        }
    }
    return view;
//    }
}

- (void)createAndSeedImageCache
{
    NSUInteger count = [self.kiosk.photoLayouts count];
    imageCache = [[NSMutableDictionary alloc] initWithCapacity:count];

    for (PhotoLayout * photoLayout in self.kiosk.photoLayouts)
    {
        UIImage * backgroundImage = [self loadBackgroundImage:photoLayout];
        [imageCache setObject:backgroundImage forKey:photoLayout.background];
    }
}

- (UIImage *)loadBackgroundImage:(PhotoLayout *)photoLayout
{
    UIImage *backgroundImage;
    NSString *backgroundUrl = [self.kiosk.storePath stringByAppendingPathComponent: photoLayout.background];

    // Verify this item before attempting to load it.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:backgroundUrl]) {
        backgroundUrl = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"problems.jpg"];
    }

    backgroundImage = [UIImage imageWithContentsOfFile:backgroundUrl];
    return backgroundImage;
}

- (NSUInteger)numberOfPlaceholdersInCarousel:(iCarousel *)carousel
{
    //note: placeholder views are only displayed on some carousels if wrapping is disabled
    return 0;
}

- (CGFloat)carouselItemWidth:(iCarousel *)carousel
{
    //usually this should be slightly wider than the item views
    return kAMSelectSceneCarouselImageWidth + 20;
}

//- (BOOL)carouselShouldWrap:(iCarousel *)carousel
- (CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value;
{
    self.kiosk.startingTimeStamp = [NSDate date];
    if (option == iCarouselOptionWrap)
    {
        // wrap the carousel for infinite scroll
        return wrap;
    } else {
        return value;
    }
}

- (void)carouselCurrentItemIndexDidChange:(iCarousel *)carousel
{
    // we stopped on an item
    // Show the description for the image.
    PhotoLayout *photoLayout = [self.kiosk.photoLayouts objectAtIndex:self.backgroundCarousel.currentItemIndex];
    NSLog(@"the current index testing is %d",backgroundCarousel.currentItemIndex);
    
    [description setText:[NSString stringWithFormat:@"%@", photoLayout.desc]];
    self.kiosk.startingTimeStamp = [NSDate date];
    
//    UIImageView *checkImage;
//
//
//
//    float x=[photoLayout.xOffset floatValue];
//    float y=[photoLayout.yOffset floatValue];
//    float width =[photoLayout.cameraWidth floatValue];
//    float height = [photoLayout.cameraHieght floatValue];
//
//
//
// //   checkImage = [[UIImageView alloc] initWithFrame:CGRectMake(x,y, width, height)];
//    //        checkImage.image = [UIImage imageNamed:@"Right mark.png"];
////    checkImage.image = [UIImage imageNamed:@"people200.png"];
//    //   checkImage.contentMode = UIViewContentModeScaleAspectFit;//UIViewContentModeCenter;
//    checkImage.contentMode = UIViewContentModeCenter;
////    [self.view addSubview:checkImage];
//
//    [self.backgroundCarousel addSubview:checkImage1];
//
//    checkImage1.image = [UIImage imageNamed:@"people200.png"];
//
//    [checkImage1 setFrame:CGRectMake(x+20, y, width, height)];
//    checkImage1.contentMode = UIViewContentModeCenter;
    
}

- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index
{
//    NSLog(@"%s", __FUNCTION__);
    if (index == self.backgroundCarousel.currentItemIndex)
    {
      //  [self getReady];
        
        NSLog(@"index %d",index);
        CTGetReadyViewController *obj;
        obj.indexValue =index;
        
//         NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//        [userDefaults setObject:index forKey:@"index"];
        
         CTAppDelegate *appDel = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
        appDel.globalIndexValue=index;
        [self performSegueWithIdentifier:@"getReady" sender:nil];
        
        
        
        
//        CTAppDelegate *app = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
//        [app.idleTimer invalidate];
//        [self takePictures];
        
        
        
        
        
        
        
        
        
//        CTAppDelegate *app = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
//        [app.idleTimer invalidate];
//       
//        
//        CTKiosk *kiosk =[CTKiosk sharedInstance];
//        [kiosk startPhotoSession:nil selectedSessionId:nil];
//        
      
        
        
        
    }
}

- (void)didSelectPhotoLayout
{
    // Tell the Kiosk to start a photo session.
    self.kiosk.currentPhotoLayout = [self.kiosk.photoLayouts objectAtIndex:self.backgroundCarousel.currentItemIndex];
}

//- (BOOL)backgroundCarousel:(iCarousel *)backgroundCarousel shouldSelectItemAtIndex:(NSInteger)index
//{
//    NSLog(@"%s", __FUNCTION__);
//    return YES;
//}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];
    if ([[segue identifier] isEqualToString:@"getReady"])
    {
        [self didSelectPhotoLayout];
    }
}

- (void)getReady
{
    // The user has made a selection, step forward.
    [self didSelectPhotoLayout];

    if (!self.getReadyVC)
    {
//        self.getReadyVC = (CTGetReadyViewController *) [self.storyboard instantiateViewControllerWithIdentifier:@"getReadyViewController"];
        self.getReadyVC = [self.storyboard instantiateViewControllerWithIdentifier:@"getReadyViewController"];
        [self.getReadyVC setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
    }
    [self presentViewController:self.getReadyVC animated:YES completion:NULL];
}

- (void)goBack
{
    
 
    
    id presenter = self.presentingViewController;
    if ([presenter conformsToProtocol:@protocol(SceneSelectionCompleteDelegate)])
    {
        [presenter sceneSelectionViewController:self didFinishWithWorkflow:_workflow];
    }
    else
    {
        NSLog(@"Unplanned scenario, our presenter is %@",
                NSStringFromClass([presenter class]));
    }
}

//
// We're in view, tell our presenter we're done and they should close too.
//
- (void)userDidLeave:(NSNotification *)notification
{
    return;
    UIResponder *currentController = [[[[[UIApplication sharedApplication] keyWindow] subviews] objectAtIndex:0] nextResponder];
    if ([currentController isMemberOfClass:[CTSelectSceneViewController class]])
    {
        _workflow = AMWorkflowResetToSplash;
        [self goBack];
        _workflow = AMWorkflowNormalCourse;
    }
    else if (self.navigationController)
    {
        NSArray *viewControllers = self.navigationController.viewControllers;
        for (UIViewController *anVC in viewControllers) {
            if ([anVC isKindOfClass:[CTSelectSceneViewController class] ]){
//                [[[UIAlertView alloc] initWithTitle:@"back" message:@"selectscene" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles: nil] show];
                [self.navigationController popToViewController:anVC animated:NO];
                break;
            }
        }
//        [self.navigationController popToViewController:[
//                [self navigationController].viewControllers objectAtIndex:1] animated:NO];
    }
    else
    {
        NSLog(@"Unplanned scenario, presently showing %@",
                NSStringFromClass([currentController class]));
    }
}

//
// Delegate for modal view to tell presenting controller i'm done, close me.
//
- (void)getReadyViewController:(CTGetReadyViewController *)getReadyViewController
         didFinishWithWorkflow:(NSString *)workflow
{
    // Close the modal.
    if ([workflow isEqualToString:AMWorkflowResetToSplash])
    {
        _workflow = workflow;
        [self dismissViewControllerAnimated:NO completion: nil];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion: nil];
    }
}

- (IBAction)resetTouched:(id)sender
{
    id presenter = self.presentingViewController;
    if ([presenter conformsToProtocol:@protocol(SceneSelectionCompleteDelegate)])
    {
        [presenter sceneSelectionViewController:self didFinishWithWorkflow:AMWorkflowGoBack];
    }
    else if (self.navigationController)
    {
        [[CTKiosk sharedInstance] backToEventScene];
        [self.navigationController popViewControllerAnimated:YES];
    //    [self dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        NSLog(@"Unplanned scenario, our presenter is %@", NSStringFromClass([presenter class]));
    }
}

- (IBAction)settingsTouched:(id)sender
{
    [self performSegueWithIdentifier:@"settings" sender:nil];
}

- (void)takePictures
{
    // Tell the Kiosk to start a photo session.
    CTKiosk * kiosk = [CTKiosk sharedInstance];
    [kiosk startPhotoSession:nil selectedSessionId:nil];
    
//    AMTakingPicturesViewController *move = [self.storyboard instantiateViewControllerWithIdentifier:@"takePicturesVC"];
//    [self presentViewController:move animated:YES completion:nil];
    
    [self performSegueWithIdentifier:@"takingpictures" sender:nil];
}

- (IBAction)takePicturesTap:(id)sender
{
    [self didSelectPhotoLayout];
    [self takePictures];
}

-(UIImage*) drawImage:(UIImage*) fgImage
              inImage:(UIImage*) bgImage
              atPoint:(CGPoint)  point
              atWidth:(float) width
             atHeight:(float) height
              atimgWidth:(float) imgwidth
             atimgHeight:(float) imgheight
{
    
    
//    CTAppDelegate *appDel = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
//
//    NSString * imageHe = [appDel.sharedArray objectAtIndex:self.backgroundCarousel.currentItemIndex];
//    NSLog(@"method height is %@",imageHe);
    
//    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//    NSArray *arrayOfImages = [userDefaults objectForKey:@"imgHeightCheck"];
//    NSArray *arrayOfText = [userDefaults objectForKey:@"imgWidthCheck"];
//
//     NSString * imageHe = [arrayOfImages objectAtIndex:self.backgroundCarousel.currentItemIndex];
//     NSString * imageWi = [arrayOfText objectAtIndex:self.backgroundCarousel.currentItemIndex];
    
   // NSLog(@"method height is %@",imageHe);
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
     NSUserDefaults *defaults1 = [NSUserDefaults standardUserDefaults];
    NSString * imageHeight = [defaults stringForKey:@"imageHeight"];
    NSString *imageWidth =[defaults1 stringForKey:@"imageWidth"];
     NSString * subId = [defaults stringForKey:@"subscriptionType"];
//    float imgHeight = [imageHeight floatValue];
//    float imgWidth = [imageWidth floatValue];
    
    
//    float imgHeight = [imageHe floatValue];
//    float imgWidth = [imageWi floatValue];
    
    
    NSLog(@"ready height is %@",imageHeight);
    UIGraphicsBeginImageContextWithOptions(bgImage.size, FALSE, 0.0);
  
    [bgImage drawInRect:CGRectMake( 0, 0, bgImage.size.width, bgImage.size.height)];
    //  [bgImage drawInRect:CGRectMake( 0, 0, 315, 537)];
    
  
  //  [fgImage drawInRect:CGRectMake( 0, 0, fgImage.size.width, fgImage.size.height)];
//[fgImage drawInRect:CGRectMake((bgImage.size.width/imgWidth)* point.x, point.y, width,(bgImage.size.height/imgHeight)*height)];
    
    
    
//     if ([subId integerValue] == 1)
//     {
//         [fgImage drawInRect:CGRectMake(point.x+550,point.y+350, width,height)];
//     }
//    else
//    {
//    [fgImage drawInRect:CGRectMake((bgImage.size.width/imgWidth)* point.x,(bgImage.size.height/imgHeight)* point.y, width,(bgImage.size.height/imgHeight)*height)];
    
 //   [fgImage drawInRect:CGRectMake((bgImage.size.width/imgwidth)* point.x,(bgImage.size.height/imgheight)* point.y, (bgImage.size.width/imgwidth)*width,(bgImage.size.height/imgheight)*height)];
    
    [fgImage drawInRect:CGRectMake((bgImage.size.width/imgwidth)* point.x,(bgImage.size.height/imgheight)* point.y, (bgImage.size.width/bgImage.size.height)*width,(bgImage.size.width/bgImage.size.height)*height)];
    
    
 //   }
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}


@end
