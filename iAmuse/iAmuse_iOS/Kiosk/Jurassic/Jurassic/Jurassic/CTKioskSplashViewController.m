//
//  CTKioskSplashViewController.m
//  Jurassic
//
//  Created by Roland Hordos on 2013-06-01.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "CTKioskSplashViewController.h"
#import "CTKiosk.h"
#import "AMUtility.h"

@interface CTKioskSplashViewController ()

@end

@implementation CTKioskSplashViewController

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    NSLog(@"%s", __FUNCTION__);
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        selectSceneVC = nil;
//    }
//    return self;
//}
//
- (void)dealloc
{
    NSLog(@"%s", __FUNCTION__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    DDLogVerbose(@"Disabling sleep mode");
    [UIApplication sharedApplication].idleTimerDisabled = YES;

    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [super viewDidLoad];
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString *temp2 = [defaults stringForKey:@"event"];
    
    CTKiosk * kiosk = [CTKiosk sharedInstance];
    NSString * assetPath = [kiosk.storePath stringByAppendingPathComponent:[NSString stringWithFormat:@"Events/%@/camera",temp2]];
    NSString * loacalassetPath = [kiosk.storePath stringByAppendingPathComponent:@"nothing_to_print.png"];
    UIImage *image = [UIImage imageWithContentsOfFile:assetPath];
    if (image) {
//        _imgViewTouch.image = image;
        
        _imgViewTouch.image = [UIImage imageNamed:@"screen_saver_Touch.jpg"];
        
        
    }
    else
    {
        
        
        
       // _imgViewTouch.image = [UIImage imageWithContentsOfFile:loacalassetPath];
        
        
//         _imgViewTouch.image = [UIImage imageNamed:@"touch ipad.jpeg"];
        
        _imgViewTouch.image = [UIImage imageNamed:@"screen_saver_Touch.jpg"];
    }
    _imgViewTouch.alpha = 1.0f;
    _imgViewTouch.contentMode = UIViewContentModeScaleAspectFill;
    
    
    
    
    

    self.selectSceneVC = nil;
}

//- (void)viewWillAppear:(BOOL)animated
//{
//    [super viewWillAppear:animated];
//    NSLog(@"%s", __FUNCTION__);
//    [self showSplash];
//}
//
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    DDLogVerbose(@"%s", __FUNCTION__);
    
 //   [self showSplash];
  //  [self showImage];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    NSLog(@"%s", __FUNCTION__);
    [moviePlayer pause];
//    [moviePlayer stop];   // kicks off 'finish' event
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    NSLog(@"%s", __FUNCTION__);
    // Dispose of any resources that can be recreated.
}

- (void)showSplash
{
    // Create and assemble the media player.
    if (!moviePlayer)
    {
//        NSBundle *bundle = [NSBundle mainBundle];

        CTKiosk *kiosk = [CTKiosk sharedInstance];
        NSString *splashPath = [kiosk.storePath stringByAppendingPathComponent:@"splash.mp4"];
        NSURL *splashURL = [NSURL fileURLWithPath:splashPath];
        moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:splashURL];
        moviePlayer.controlStyle = MPMovieControlStyleNone;

        // Loop the movie, no simple component model way to do this but we love the notification model too.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerPlaybackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:moviePlayer];
        
        [moviePlayer prepareToPlay];
        [moviePlayer.view setFrame: self.view.bounds];  // player's frame must match ours
        [self.view addSubview: moviePlayer.view];
        
        // Intro touch layer.
        introOverlayLayer = [[UIImageView alloc] initWithFrame:moviePlayer.view.bounds];
        NSString *assetPath = [kiosk.storePath stringByAppendingPathComponent:@"splash_kiosk.png"];
        DDLogVerbose(@"Loading splash overlay from %@", assetPath);
        introOverlayLayer.image = [UIImage imageWithContentsOfFile:assetPath];
        introOverlayLayer.alpha = 0.8f;
        introOverlayLayer.contentMode = UIViewContentModeScaleAspectFit;

//        UIImage *image = [[UIImageView alloc] initWithFrame:moviePlayer.view.bounds];
//        introTouchBumper.image = [UIImage imageNamed:@"alpha-10.png"];
//        introTouchBumper.alpha = 0.8f;
//        introTouchBumper.center = introTouchBumper.superview.center;
//        introTouchBumper.contentMode = UIViewContentModeScaleToFill;

//        // Pickup the gestures.  Couldn't use UITapGestureRecognizer likely because it's already in use for the movie controls.
//        // Then couldn't rely on the intro graphic overlay as transparent pixels pass the touch through.
//        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(splashScreenTap:)];
//        tap.numberOfTapsRequired = 1;
//        [introOverlayLayer addGestureRecognizer:tap];
//        [introTouchBumper addGestureRecognizer:tap];
//
        [moviePlayer.view addSubview:introOverlayLayer];
//        [moviePlayer.view addSubview:introTouchBumper];

//        UIView *dummyView = [[UIView alloc] initWithFrame:moviePlayer.view.bounds];
//        [dummyView addGestureRecognizer:tap];
//        [moviePlayer.view addSubview:dummyView];
    }
    
    [moviePlayer play];
}

- (void)playerPlaybackDidFinish:(NSNotification*)notification
{
    // This acts as a timing point to change our instructional message to the consumer.  Loop the
    // movie and change the instruction.
//    DDLogVerbose(@"Looping movie ..");
    [notification.object play];
}

- (void)viewWillLayoutSubviews {
    // We're probably about to autorotate, so set the movie and overlay text bounds appropriately.
    NSLog(@"%s", __FUNCTION__);
//    NSLog(@"height, width: %f, %f", self.view.bounds.size.height, self.view.bounds.size.width);
//    NSLog(@"left, top: %f, %f", self.view.bounds.origin.x, self.view.bounds.origin.y);

    if (moviePlayer) {
        CGRect targetBounds = self.view.bounds;

        [moviePlayer.view setFrame: targetBounds];
        [introOverlayLayer setFrame:targetBounds];
    }
}

//- (void)splashScreenTap:(UITapGestureRecognizer *)gesture {
//    // The splash screen has been touched.  Transition to the Photo Session use case and stop the movie.
//    [self selectScene];
//}

- (void)selectScene {
    // The user has made a selection, step forward.
//    if (!self.selectSceneVC) {
//        self.selectSceneVC = (CTSelectSceneViewController *) [self.storyboard instantiateViewControllerWithIdentifier:@"selectSceneViewController"];
//        [self.selectSceneVC setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
////        [selectSceneVC setModalPresentationStyle:UIModalPresentationFullScreen];
//
////        [selectSceneViewController setModalPresentationStyle:UIModalPresentationFullScreen];
//    }
//    [self presentViewController:self.selectSceneVC animated:YES completion:NULL];
    
    [self performSegueWithIdentifier:@"photoSession" sender:nil];
}

//
// Delegate for modal view to tell presenting controller i'm done, close me.
//
- (void)sceneSelectionViewController:(CTSelectSceneViewController *)sceneSelectionViewController
               didFinishWithWorkflow:(NSString *)workflow
{
    NSLog(@"%s", __FUNCTION__);
    [self dismissViewControllerAnimated:YES completion: nil];
}



@end
