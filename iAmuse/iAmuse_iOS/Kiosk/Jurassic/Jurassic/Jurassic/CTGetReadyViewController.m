//
//  CTGetReadyViewController.m
//  Jurassic
//
//  Created by Roland Hordos on 2013-06-02.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import "CTGetReadyViewController.h"
#import "CTKiosk.h"
#import "PhotoSession.h"
#import "AMConstants.h"
#import "M13Checkbox.h"
#import "CTSelectSceneViewController.h"
#import "CTAppDelegate.h"

@interface CTGetReadyViewController ()

@end

@implementation CTGetReadyViewController

- (void)dealloc
{
    NSLog(@"%s", __FUNCTION__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    NSLog(@"%s", __FUNCTION__);
    [super viewDidLoad];

      CTAppDelegate *appDel = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSLog(@"index values is %d",appDel.globalIndexValue);
    
//    UIImageView *checkImage;
//
//
//    checkImage = [[UIImageView alloc] initWithFrame:CGRectMake(143.5,188.5, 100, 100)];
//    checkImage.image = [UIImage imageNamed:@"Right mark.png"];
//    checkImage.contentMode = UIViewContentModeCenter;
//    [self.view addSubview:checkImage];
    
   
    
  
    
    self.takePicturesVC = nil;

    // Default workflow.
    _workflow = AMWorkflowNormalCourse;

    CTKiosk *kiosk = [CTKiosk sharedInstance];
//    NSString *assetPath = [kiosk.storePath stringByAppendingPathComponent:@"header.png"];
//    self.header.image = [UIImage imageWithContentsOfFile:assetPath];
//    assetPath = [kiosk.storePath stringByAppendingPathComponent:@"footer.png"];
  //  self.footer.image = [UIImage imageWithContentsOfFile:assetPath];
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"%s", __FUNCTION__);
    [super viewWillAppear:animated];

    // This is needed as dependent views may not yet be loaded within viewWillAppear.
    CTKiosk * kiosk = [CTKiosk sharedInstance];
    if (kiosk.currentPhotoLayout)
    {
        NSString *backgroundUrl = [kiosk.storePath stringByAppendingPathComponent:kiosk.currentPhotoLayout.background];
        
//        NSNumber *xoffset = kiosk.currentPhotoLayout.xOffset;
//        NSLog(@"xoffset number is %@",xoffset);
        
       
//
        self.selectedLayoutView.image = [UIImage imageWithContentsOfFile:backgroundUrl];
        
        if(self.selectedLayoutView.image==nil)
        {
            [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Event has been updated in the web.Please goto eventlist and redownload the event." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
        
        UIImage *bgImage =[UIImage imageWithContentsOfFile:backgroundUrl];
        
        
        
        
        float x=[kiosk.currentPhotoLayout.xOffset floatValue];
        float y=[kiosk.currentPhotoLayout.yOffset floatValue];
        float width =[kiosk.currentPhotoLayout.cameraWidth floatValue];
        float height = [kiosk.currentPhotoLayout.cameraHieght floatValue];
        
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//        NSArray *arrayOfImages = [userDefaults objectForKey:@"imgHeightCheck"];
//        NSArray *arrayOfText = [userDefaults objectForKey:@"imgWidthCheck"];
        
        //            NSString * imageHe = [arrayOfImages objectAtIndex:self.backgroundCarousel.currentItemIndex];
        //            NSString * imageWi = [arrayOfText objectAtIndex:self.backgroundCarousel.currentItemIndex];
        
        
        CTAppDelegate *appDel = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
        NSLog(@"index values is %d",appDel.globalIndexValue);
        
//        NSString * imageHe = [arrayOfImages objectAtIndex:appDel.globalIndexValue];
//        NSString * imageWi = [arrayOfText objectAtIndex:appDel.globalIndexValue];
//
//        float imgwidth =[imageHe floatValue];
//        float imgheight = [imageWi floatValue];

        
        
        UIImage *checking = [UIImage imageNamed:@"zoomProfile.png"];
        
     //   UIImage *overlayIamge =[self drawImage:checking inImage:bgImage atPoint:CGPointMake(x, y) atWidth:width atHeight:height];
        
      //  UIImage *overlayIamge = [self drawImage:checking inImage:bgImage atPoint:CGPointMake(x, y) atWidth:width atHeight:height atimgWidth:imgwidth atimgHeight:imgheight];
        
     //   self.selectedLayoutView.contentMode=UIViewContentModeScaleAspectFill;

    //    self.selectedLayoutView.image =overlayIamge;
        
        NSLog(@"y is %f",y);
        NSLog(@"x is %f",x);
         UIImageView *checkImage;
//        x=(x*737)/width;
//        y=(y*451)/width;
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString * imageHeight = [defaults stringForKey:@"imageHeight"];
        NSString *imageWidth =[defaults stringForKey:@"imageWidth"];
        float imgHeight = [imageHeight floatValue];
        float imgWidth = [imageWidth floatValue];
        NSLog(@"ready height is %@",imageHeight);
        
        y=y*(451.00/[imageHeight floatValue])+188.5;
//        width=width*(737.00/imgWidth);
          width=width*(500/imgWidth);
        height =height*(250/imgHeight);
        
        NSLog(@"y after is %f",y);
        NSLog(@"x  after is %f",x);
        
        checkImage = [[UIImageView alloc] initWithFrame:CGRectMake(x*(737.00/1023)+143.5,y, width, height)];
//        checkImage.image = [UIImage imageNamed:@"Right mark.png"];
   //    checkImage.image = [UIImage imageNamed:@"people200.png"];
     //   checkImage.contentMode = UIViewContentModeScaleAspectFit;//UIViewContentModeCenter;
          checkImage.contentMode = UIViewContentModeScaleAspectFill;
        [self.view addSubview:checkImage];
        
        
    }
//    if (kiosk.currentPhotoSession && kiosk.currentPhotoSession.entity) {
//        NSString *backgroundUrl = [kiosk.storePath stringByAppendingPathComponent:kiosk.currentPhotoSession.entity.layout.background];
//        self.selectedPhotoImageView.image = [UIImage imageWithContentsOfFile:backgroundUrl];
//    }
}

- (void)viewDidAppear:(BOOL)animated
{
    NSLog(@"%s", __FUNCTION__);
    if (_workflow == AMWorkflowResetToSplash)
    {
        [self goBack];
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
//    NSLog(@"%s", __FUNCTION__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    NSLog(@"%s", sel_getName(_cmd));
}

- (void)takePictures
{
    // Tell the Kiosk to start a photo session.
    CTKiosk * kiosk = [CTKiosk sharedInstance];
    [kiosk startPhotoSession:nil selectedSessionId:nil];

    [self performSegueWithIdentifier:@"PhotoShoot" sender:nil];

//    if (!self.takePicturesVC) {
//        self.takePicturesVC = [self.storyboard instantiateViewControllerWithIdentifier:@"takePicturesVC"];
//        [self.takePicturesVC setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
//    }
//    [self presentViewController:self.takePicturesVC animated:YES completion:NULL];
}

- (IBAction)takePicturesTap:(id)sender
{
    CTAppDelegate *app = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
    [app.idleTimer invalidate];
    [self takePictures];
}

- (IBAction)backButtonTap:(id)sender
{
    _workflow = AMWorkflowGoBack;
    [self goBack];
    _workflow = AMWorkflowNormalCourse;
}

- (void)goBack
{
    CTKiosk * kiosk = [CTKiosk sharedInstance];
    [kiosk userHeartbeat];

    // Close the camera in preparation for a different background selection.
    [kiosk pausePhotoSession];

    id presenter = self.presentingViewController;
    if ([presenter conformsToProtocol:@protocol(GetReadyCompleteDelegate)])
    {
        [presenter getReadyViewController:nil didFinishWithWorkflow:_workflow];
    }
    else if (self.navigationController)
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        NSLog(@"Unplanned scenario, our presenter is %@",
                NSStringFromClass([presenter class]));
    }
}

//
// We're in view but the user walked away, tell our presenter we're done and
// they should close too.
//
- (void)userDidLeave:(NSNotification *)notification
{
    return;
    NSLog(@"%s", __FUNCTION__);

    id presenter = self.presentingViewController;
    if ([presenter conformsToProtocol:@protocol(GetReadyCompleteDelegate)])
    {
        [presenter getReadyViewController:self didFinishWithWorkflow:AMWorkflowResetToSplash];
    }
    else if (self.navigationController)
    {
        NSArray *viewControllers = self.navigationController.viewControllers;
        for (UIViewController *anVC in viewControllers) {
            if ([anVC isKindOfClass:[CTSelectSceneViewController class] ]){
//                [[[UIAlertView alloc] initWithTitle:@"back" message:@"getready" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles: nil] show];

                [self.navigationController popToViewController:anVC animated:NO];
                break;
            }
        }
//        [self.navigationController popToViewController:[
//        [self navigationController].viewControllers objectAtIndex:1] animated:NO];
    }
    else
    {
        NSLog(@"Unplanned scenario, our presenter is %@",
                NSStringFromClass([presenter class]));
    }
}

- (void)takingPicturesViewController:(AMTakingPicturesViewController *)takingPicturesViewController didFinishWithWorkflow:(NSString *)workflow
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


-(UIImage*) drawImage:(UIImage*) fgImage
              inImage:(UIImage*) bgImage
              atPoint:(CGPoint)  point
              atWidth:(float) width
             atHeight:(float) height
           atimgWidth:(float) imgwidth
          atimgHeight:(float) imgheight
{
    
    
    CTKiosk * kiosk = [CTKiosk sharedInstance];
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString * imageHeight = [defaults stringForKey:@"imageHeight"];
    NSString *imageWidth =[defaults stringForKey:@"imageWidth"];
    NSString * subId = [defaults stringForKey:@"subscriptionType"];
    float imgHeight = [imageHeight floatValue];
    float imgWidth = [imageWidth floatValue];
    NSLog(@"ready height is %@",imageHeight);
    UIGraphicsBeginImageContextWithOptions(bgImage.size, FALSE, 0.0);
    
    [bgImage drawInRect:CGRectMake( 0, 0, bgImage.size.width, bgImage.size.height)];
    
    
    
    //  [fgImage drawInRect:CGRectMake( 0, 0, fgImage.size.width, fgImage.size.height)];
    
    
    
    
//    if ([subId integerValue] == 1)
//    {
//        [fgImage drawInRect:CGRectMake(point.x+550,point.y+350, width,height)];
//    }
//    else
//    {
   //     [fgImage drawInRect:CGRectMake((bgImage.size.width/imgWidth)* point.x,(bgImage.size.height/imgHeight)* point.y, width,(bgImage.size.height/imgheight)*height)];
    
  //  [fgImage drawInRect:CGRectMake((bgImage.size.width/imgwidth)* point.x,(bgImage.size.height/imgheight)* point.y, (bgImage.size.width/imgwidth)*width,(bgImage.size.height/imgheight)*height)];
    
    
    
    
    
//     [fgImage drawInRect:CGRectMake((bgImage.size.width/imgwidth)* point.x,(bgImage.size.height/imgheight)* point.y, (bgImage.size.width/imgwidth)*width,(bgImage.size.height/imgheight)*height)];
    
//     [fgImage drawInRect:CGRectMake((bgImage.size.width/imgwidth)* point.x,(bgImage.size.height/imgheight)* point.y, (bgImage.size.width/bgImage.size.height)*width,(bgImage.size.width/bgImage.size.height)*height)];
    
//    [fgImage drawInRect:CGRectMake((bgImage.size.width/1023)* point.x,(bgImage.size.height/469)* point.y, (bgImage.size.width/bgImage.size.height)*width,(bgImage.size.width/bgImage.size.height)*height)];
    
    
    
    
    
    
//    [self.selectedLayoutView setFrame:CGRectMake((maskFrame.origin.x + (maskFrame.size.width / 2)) - fovCenter.x, (maskFrame.origin.y + (maskFrame.size.height / 2)) - fovCenter.y, self.selectedLayoutView.frame.size.width, self.selectedLayoutView.frame.size.height)];

    
    
    
    
  //  [fgImage drawInRect:CGRectMake((maskFrame.origin.x + (maskFrame.size.width / 2)) - fovCenter.x, (maskFrame.origin.y + (maskFrame.size.height / 2)) - fovCenter.y, self.selectedLayoutView.frame.size.width, self.selectedLayoutView.frame.size.height)];
    
    
    
    
    
    [fgImage drawInRect:CGRectMake(119,19, 360,202)];
    
  //  [fgImage drawInRect:CGRectMake(point.x, point.y, width, height)];
    
//    [fgImage drawInRect:CGRectMake((bgImage.size.width/imgwidth)* 409,(bgImage.size.height/imgheight)* 102, (imgwidth/imgheight)*width,(imgwidth/imgheight)*height)];
    
// [fgImage drawInRect:CGRectMake((bgImage.size.width/width)* point.x,(bgImage.size.height/height)* point.y, (imgwidth/bgImage.size.height)*width,(imgwidth/bgImage.size.height)*height)];
    
    
    
    
//    }
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}



@end
