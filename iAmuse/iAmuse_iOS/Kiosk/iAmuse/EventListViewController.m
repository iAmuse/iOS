//
//  EventListViewController.m
//  iAmuse
//
//  Created by apple on 24/10/16.
//  Copyright © 2016 iAmuse Inc. All rights reserved.
//

#import "EventListViewController.h"
#import "EventTableViewCell.h"
#import "AMConstants.h"
#import "MBProgressHUD.h"
#import "AMStorageManager.h"
#import "PhotoLayout.h"
#import "CTKiosk.h"
#import "CTSelectSceneViewController.h"
#import "Event.h"
#import "WebCommunication.h"
#import "CTAppDelegate.h"
#import "ABPadLockScreenViewController.h"
#import "SignInViewController.h"
#import "InitialViewController.h"

#import "CTAppDelegate.h"
#import "CTKioskViewController.h"
#import "AMUtility.h"

// for IP address
#include <ifaddrs.h>
#include <arpa/inet.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import "AMStorageManager.h"


@interface EventListViewController (){
    NSArray *eventArray;
    NSInteger downloadedImageCount;
    AMStorageManager *storage;
    CTKiosk *kiosk;
    UIAlertView *alertView;
    BOOL isAlertShown, isUpdatingEvents;
    NSString *hudTitle;
    MBProgressHUD *hud;
    ABPadLockScreenViewController *lockScreen;
    
    EventTableViewCell *cell;
    NSString *str;
    NSString *updateStr;
    NSMutableArray *imgHeightCheck;
    NSMutableArray *imgWidthCheck;
}
    @end

@implementation EventListViewController
    
- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
//    NSDate *UTCDate = [NSDate date];
//    NSLog(@"date is %@",UTCDate);
    
    NSDate* datetime = [NSDate date];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]]; // Prevent adjustment to user's local time zone.
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
    NSString* dateTimeInIsoFormatForZuluTimeZone = [dateFormatter stringFromDate:datetime];
    
    NSLog(@"date is %@",dateTimeInIsoFormatForZuluTimeZone);
    
    
    imgHeightCheck =[[NSMutableArray alloc]init];
     imgWidthCheck =[[NSMutableArray alloc]init];
    
    
    
    
    
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    
    
    NSString * testing = [defaults stringForKey:@"eventUpdated"];
    if([testing isEqualToString:@"true"] )
    {
        
        
        [self manuallyDeleteEventsAfterEventUpdate];
        
      
        
        
        
      //  updateStr =@"notupdated";
        
    }
    
    
    [defaults setObject:@"false" forKey:@"eventUpdated"];
    
     updateStr =@"notupdated";
    
    
    [self autoConfigureCameraAndTouchDevice];
    
//  //  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//
//    NSString * subId = [defaults stringForKey:@"subscriptionType"];
//
//    if ([subId integerValue] == 1)
//    {
//        // [self setBorderForSelectedSubscriptionView:self.freeView];
//        _lblSubscriptionType.text=@"Free Trial";
//
//
//    }
//    else if ([subId integerValue] == 2)
//    {
//       _lblSubscriptionType.text=@"Single Event";
//        //  [self setBorderForSelectedSubscriptionView:self.oneDaySubscriptionView];
//    }
//    else if ([subId integerValue] == 3)
//    {
//       _lblSubscriptionType.text=@"Professional pay-as-you-go";
//        //  [self.oneMonthSubscribeBtn setTitle:@"Your Current Plan" forState:UIControlStateNormal];
//        //     [self setBorderForSelectedSubscriptionView:self.customUploadView];
//    }
//    else
//    {
//        _lblSubscriptionType.text=@"Professional Yearly";
//        //     [self setBorderForSelectedSubscriptionView:self.oneMonthSubscriptionView];
//    }
    
    
    str = @"hello";
    
   // [self refreshAction];
    //[self.view updateConstraints];
    [self.view layoutIfNeeded];
    [self.view layoutSubviews];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBarHidden = YES;
    CTAppDelegate *delegate = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
    [MBProgressHUD hideAllHUDsForView:delegate.window animated:NO];
    self.uploadingImagesLabel.hidden = YES;
    storage = [AMStorageManager sharedInstance];
    NSUserDefaults * userdefault = [NSUserDefaults standardUserDefaults];
    NSString * deviceModePref = [userdefault stringForKey:AMDeviceModeSettingsKey];
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"loading event";
    //  if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
    {
        [self getSubscriptionDetail];
    }
    
    // [self getAllEvents];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateEventNotification:)
                                                 name:AMEventConfigurationUpdateNotification
                                               object:nil];
    
    //    [[NSNotificationCenter defaultCenter] addObserver:self
    //                                             selector:@selector(updateFOVNotification:)
    //                                                 name:@"FOV_UPDATED"
    //                                               object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePendingImageCount:) name:@"UpdatePendingImageCountNotification" object:nil];
    
    kiosk = [CTKiosk sharedInstance];
    [kiosk checkPendingImageForUploading:YES];
    [kiosk registerDeviceOnServer];
    
 //    [self autoConfigureCameraAndTouchDevice];
    
}
    
- (void)updateFOVNotification:(NSNotification *)notification
    {
        //[self getFOV];
    }
    
- (void)updateEventNotification:(NSNotification *)notification
    {
        isUpdatingEvents = YES;
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.labelText = @"updating event";
        updateStr=@"updated";
        [self getSubscriptionDetail];

        [self performSelector:@selector(hideloader) withObject:nil afterDelay:5];



        
 




        NSError *error = nil;
        NSString * eventpath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        eventpath = [eventpath stringByAppendingPathComponent:@"Events"];
        NSFileManager *fileMgr1 = [[NSFileManager alloc] init];


        NSArray *files1 = [fileMgr1 contentsOfDirectoryAtPath:eventpath error:nil];
        NSError *error1 = nil;

        while (files1.count > 0) {
            NSArray *directoryContents = [fileMgr1 contentsOfDirectoryAtPath:eventpath error:&error1];
            if (error1 == nil) {
                for (NSString *path1 in directoryContents)
                {
                    NSString *fullPath = [eventpath stringByAppendingPathComponent:path1];
                    BOOL removeSuccess = [fileMgr1 removeItemAtPath:fullPath error:&error1];
                    files1 = [fileMgr1 contentsOfDirectoryAtPath:eventpath error:nil];
                    if (!removeSuccess)
                    {
                        // Error
                    }
                }
            } else {
                // Error
            }
        }

        //Clear from CoreData
        NSFetchRequest *eventfetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Event"];
        [eventfetchRequest setIncludesPropertyValues:NO]; //only fetch the managedObjectID

        NSManagedObjectContext *moc = [[AMStorageManager sharedInstance] currentMOC];

        NSArray *fetchedObjects = [moc executeFetchRequest:eventfetchRequest error:&error];
        for (NSManagedObject *object in fetchedObjects)
        {
            [moc deleteObject:object];
        }
        error = nil;
        [moc save:&error];

        NSFetchRequest *photofetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"PhotoLayout"];
        [photofetchRequest setIncludesPropertyValues:NO]; //only fetch the managedObjectID

        NSManagedObjectContext *moc1 = [[AMStorageManager sharedInstance] currentMOC];

        NSArray *fetchedObjects1 = [moc1 executeFetchRequest:photofetchRequest error:&error];
        for (NSManagedObject *object in fetchedObjects1)
        {
            [moc1 deleteObject:object];
        }
        error = nil;
        [moc1 save:&error];













        NSIndexPath *indexPath;
        EventTableViewCell *cell;
        [cell.downloadBtn setHidden:NO];
        [cell.downloadBtn setTag:indexPath.section];
        [cell.downloadBtn addTarget:self action:@selector(downloadBtnAction:) forControlEvents:UIControlEventTouchUpInside];


    }




//- (void)updateEventNotification:(NSNotification *)notification
//{
//    isUpdatingEvents = YES;
//    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//    hud.mode = MBProgressHUDModeIndeterminate;
//    hud.labelText = @"updating event";
//    updateStr=@"updated";
//    [self getSubscriptionDetail];
//
//    [self performSelector:@selector(hideloader) withObject:nil afterDelay:5];
//
//
//
//
//    NSLog(@"update is %@",updateStr);
//
//
//
//
//
//    NSError *error = nil;
//    NSString * eventpath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
//    eventpath = [eventpath stringByAppendingPathComponent:@"Events"];
//    NSFileManager *fileMgr1 = [[NSFileManager alloc] init];
//
//
//    NSArray *files1 = [fileMgr1 contentsOfDirectoryAtPath:eventpath error:nil];
//    NSError *error1 = nil;
//
//    while (files1.count > 0) {
//        NSArray *directoryContents = [fileMgr1 contentsOfDirectoryAtPath:eventpath error:&error1];
//        if (error1 == nil) {
//          //  for (NSString *path1 in directoryContents)
//         //   {
//            NSString *eventid= @"232";
//            NSString *fullPath = [NSString stringWithFormat:@"%@%@",eventpath,eventid];//[eventpath stringByAppendingPathComponent:path1];
//                BOOL removeSuccess = [fileMgr1 removeItemAtPath:fullPath error:&error1];
//                files1 = [fileMgr1 contentsOfDirectoryAtPath:eventpath error:nil];
//                if (!removeSuccess)
//                {
//                    // Error
//                }
//        //    }
//        } else {
//            // Error
//        }
//    }
//
//    //Clear from CoreData
////    NSFetchRequest *eventfetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Event"];
////    [eventfetchRequest setIncludesPropertyValues:NO]; //only fetch the managedObjectID
////
////    NSManagedObjectContext *moc = [[AMStorageManager sharedInstance] currentMOC];
////
////    NSArray *fetchedObjects = [moc executeFetchRequest:eventfetchRequest error:&error];
////    for (NSManagedObject *object in fetchedObjects)
////    {
////        [moc deleteObject:object];
////    }
////    error = nil;
////    [moc save:&error];
//
//
//
//    NSFetchRequest *request = [[NSFetchRequest alloc] init];
//    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:storage.currentMOC];
//    [request setEntity:entity];
//    [request setReturnsObjectsAsFaults:NO];
//    NSString *eveid =@"151";
//    [request setPredicate:[NSPredicate predicateWithFormat:@"eventId == %@", eveid]];
//    NSError *errorFetch = nil;
//     NSManagedObjectContext *moc = [[AMStorageManager sharedInstance] currentMOC];
//    NSArray *fetchedObjects = [moc executeFetchRequest:request error:&error];
//    for (NSManagedObject *object in fetchedObjects)
//     {
//      [moc deleteObject:object];
//     }
//
//
//
//    NSFetchRequest *photofetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"PhotoLayout"];
//    [photofetchRequest setIncludesPropertyValues:NO]; //only fetch the managedObjectID
//
//    NSManagedObjectContext *moc1 = [[AMStorageManager sharedInstance] currentMOC];
//
//    NSArray *fetchedObjects1 = [moc1 executeFetchRequest:photofetchRequest error:&error];
//    for (NSManagedObject *object in fetchedObjects1)
//    {
//        [moc1 deleteObject:object];
//    }
//    error = nil;
//    [moc1 save:&error];
//
//
//
//
//
//
//
//
//
//
//
//
//
////    NSIndexPath *indexPath;
////    EventTableViewCell *cell;
////    [cell.downloadBtn setHidden:NO];
////    [cell.downloadBtn setTag:indexPath.section];
////    [cell.downloadBtn addTarget:self action:@selector(downloadBtnAction:) forControlEvents:UIControlEventTouchUpInside];
//
//
//}





- (void)hideloader
    {
        [hud hide:YES];
    }
    
- (void)viewWillAppear:(BOOL)animated
    {
        [super viewWillAppear:animated];
        
        
          NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        NSString * subId = [defaults stringForKey:@"subscriptionType"];
        
        if ([subId integerValue] == 1)
        {
            // [self setBorderForSelectedSubscriptionView:self.freeView];
            _lblSubscriptionType.text=@"Free Trial";
            
            
        }
        else if ([subId integerValue] == 2)
        {
            _lblSubscriptionType.text=@"Single Event";
            //  [self setBorderForSelectedSubscriptionView:self.oneDaySubscriptionView];
        }
        else if ([subId integerValue] == 3)
        {
            _lblSubscriptionType.text=@"Professional pay-as-you-go";
            //  [self.oneMonthSubscribeBtn setTitle:@"Your Current Plan" forState:UIControlStateNormal];
            //     [self setBorderForSelectedSubscriptionView:self.customUploadView];
        }
        else
        {
            _lblSubscriptionType.text=@"Professional Yearly";
            //     [self setBorderForSelectedSubscriptionView:self.oneMonthSubscriptionView];
        }
        
        
        
        
        
        
        self.navigationController.navigationBarHidden = YES;
        [self getRGB];
        [self SubscriptionUpdate];
    }
    
- (void)viewWillDisappear:(BOOL)animated
    {
        [super viewWillDisappear:animated];
    }
    
- (void)getRGB
    {
        NSMutableDictionary * dict = [NSMutableDictionary dictionary];
        [dict setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"userId"] forKey:@"userId"];
        WebCommunication * webComm = [WebCommunication new];
        [webComm callToServerRequestDictionary:dict onURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kAMBaseURL,kAMGetConfigurationURL]] WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm)
         {
             
             if(!error)
             {
                 if([[response objectForKey:@"responseDescription"] isEqualToString:@"Success"])
                 {
                     if([response objectForKey:@"rgbValue"])
                     {
                         NSArray *colorRGBInfo = [[response objectForKey:@"rgbValue"] componentsSeparatedByString:@","];
                         [[NSUserDefaults standardUserDefaults] setBool:YES forKey:HAVE_SERVER_RGB_CONFIGURATION];
                         [[NSUserDefaults standardUserDefaults] setBool:NO forKey:PENDING_CONFIGUARTION_REQUEST];
                         [[NSUserDefaults standardUserDefaults] setObject:colorRGBInfo forKey:SERVER_RGB_CONFIGURATION];
                         [[NSUserDefaults standardUserDefaults]synchronize];
                         //                     [[[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"%@",response] delegate:nil cancelButtonTitle:@"ok" otherButtonTitles: nil] show];
                         
                     }
                 }
             }
             else
             {
             }
             
         }];
    }
    
- (void)getFOV
    {
        WebCommunication *webComm = [[WebCommunication alloc] initWithServiceType:1];
        
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        [dic setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"userId"] forKey:@"userId"];
        NSURL *serviceUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/getFov",kAMBaseURL]];
        
        [webComm callToServerRequestDictionary:dic onURL:serviceUrl WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm) {
            if (!error)
            {
                NSLog(@"%ld, %@",(long)status_code,response);
                
                 if ([[response valueForKey:@"left"] isKindOfClass:[NSNull class]])
                     {
                         //[self getFOV];
                         
                         [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Something went wrong" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                         
                     }
                
             else
             {
                
                
                if ([[response objectForKey:@"responseCode"] integerValue] != 1)
                {
//                    [[[UIAlertView alloc] initWithTitle:@"Alert" message:[response objectForKey:@"responseDescription"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                    [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Something went wrong" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                    
                //    [self getFOV];
                    
                }
                else
                {
                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                    [defaults setObject: [NSNumber numberWithInt:[[self checkValueAgainstNull:@"left" inDictionary:response] intValue]] forKey: FOV_CURTAIN_KEY_LEFT];
                    [defaults setObject: [NSNumber numberWithInt:[[self checkValueAgainstNull:@"right" inDictionary:response] intValue]] forKey: FOV_CURTAIN_KEY_RIGHT];
                    
                    [defaults setObject: [NSNumber numberWithInt:[[self checkValueAgainstNull:@"top" inDictionary:response] intValue]] forKey: FOV_CURTAIN_KEY_TOP];
                    [defaults setObject: [NSNumber numberWithInt:[[self checkValueAgainstNull:@"bottom" inDictionary:response] intValue]] forKey: FOV_CURTAIN_KEY_BOTTOM];
                    if ([[response valueForKey:@"otherIntractionTimout"] isKindOfClass:[NSNull class]] || [[response valueForKey:@"otherIntractionTimout"] isEqualToString:@""]) {
                        [defaults setObject:[NSNumber numberWithFloat:2.0] forKey:AMIdleFeelTimeoutKey];
                    }
                    else
                    {
                        [defaults setObject:[NSNumber numberWithFloat:[[response valueForKey:@"otherIntractionTimout"] floatValue]] forKey:AMIdleFeelTimeoutKey];
                    }
                    if ([[response valueForKey:@"otherCountdownDelay"] isKindOfClass:[NSNull class]] || [[response valueForKey:@"otherCountdownDelay"] isEqualToString:@""])
                    {
                        [defaults setObject:[NSNumber numberWithFloat:1.0] forKey:kAMCameraCountdownStepIntervalKey];
                    }
                    else
                    {
                        [defaults setObject:[NSNumber numberWithFloat:[[response valueForKey:@"otherCountdownDelay"] floatValue]] forKey:kAMCameraCountdownStepIntervalKey];
                    }
                    [defaults synchronize];
                }
            }
            }
        }];
    }
    
    
- (void)updatePendingImageCount:(NSNotification *)notification
    {
        if ([notification.object isEqualToString:@"Pending"]) {
            [self.uploadingImagesLabel setHidden:NO];
            [self.uploadingImagesLabel setText:[NSString stringWithFormat:@"Uploading %ld images",(unsigned long)kiosk.photos.count]];
        }
        else
        {
            [self.uploadingImagesLabel setHidden:YES];
        }
    }
    
- (void)getSubscriptionDetail
    {
        WebCommunication *webComm = [[WebCommunication alloc] initWithServiceType:1];
        
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        [dic setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"userId"] forKey:@"userId"];
        NSURL *serviceUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/subscriptionsList",kAMBaseURL]];
        [webComm callToServerRequestDictionary:dic onURL:serviceUrl WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm) {
            [hud hide:YES];
            if (!error)
            {
                NSLog(@"%ld, %@",(long)status_code,response);
                
                if ([response[@"subId"] isKindOfClass:[NSNull class]])
                {
                   // [self getSubscriptionDetail];
                    [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Something went wrong" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                }
                else
                {
                if ([[response objectForKey:@"responseCode"] integerValue] != 1)
                {
                     [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Something went wrong" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                    
                }
                else
                {
                    if (![response[@"subId"] isKindOfClass:[NSNull class]])
                    {
                        self.subscriptionId = response[@"subId"];
                    }
                    else
                    {
                        self.subscriptionId = @"";
                    }
                    [self getAllEvents];
                    [self getFOV];
                }
            }
            }
            else
            {
                //  [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Something went wrong" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                
                NSLog(@"%@",error);
            }
            
        }];
        
    }
//- (IBAction)refreshAction:(id)sender {
    -(void) refreshAction
    {
    if(self.subscriptionId)
    {
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.labelText = @"loading event";
        [self getSubscriptionDetail];
    }
}
    
- (void)getAllEvents
    {
        [self.view layoutSubviews];
        WebCommunication *webComm = [[WebCommunication alloc] initWithServiceType:1];
        
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        [dic setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"userId"] forKey:@"userId"];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        NSString * subId = [defaults stringForKey:@"subscriptionType"];
        NSString *Id;
        if ([subId integerValue] == 4)
        {
            Id=@"3";
        }
        else
        {
            Id=subId;
        }
        //[dic setObject:Id forKey:@"subId"];
        [dic setObject:self.subscriptionId forKey:@"subId"];
        NSURL *serviceUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/eventFetchingAdminBooth",kAMBaseURL]];
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        NSLog(@"dictionary values are %@",dic);
        
        [webComm callToServerRequestDictionary:dic onURL:serviceUrl WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm) {
            
            
            NSString *fetPassword = [[response objectForKey:@"pin"]objectForKey:@"modifiedResult"];
            NSLog(@"fet password is %@",fetPassword);
            
            //   if (!isUpdatingEvents)
            {
                [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
            }
            if (!error)
            {
                NSLog(@"%ld, response is%@",(long)status_code,response);
                
                if ([[response objectForKey:@"adminEventPictureMappingResponse"]  isKindOfClass:[NSNull class]])
                {
                    //[self getAllEvents];
                    [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Something went wrong" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                }
           else
           {
                
                if ([[response objectForKey:@"responseCode"] integerValue] != 1)
                {
                    [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Something went wrong" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                    
                   // [self getAllEvents];
                    
                }
                else
                {
                    if (![[[response objectForKey:@"adminEventPictureMappingResponse"] objectForKey:@"modifiedResult"] isKindOfClass:[NSNull class]])
                    {
                        eventArray = nil;
                        eventArray = [[NSArray alloc]init];
                        //                    [[[UIAlertView alloc] initWithTitle:@"Alert" message:[response description] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                        
                        eventArray = [[response objectForKey:@"adminEventPictureMappingResponse"] objectForKey:@"modifiedResult"];
                        
                        NSArray *pass =[eventArray valueForKey:@"pin"];
                        NSLog(@"pin %@",pass);
                        
                        
                        NSString *newp = [pass objectAtIndex:0];
                        NSLog(@"bep %@",newp);
                        
                        NSArray *offsetx =[eventArray valueForKey:@"adminBoothEventPicture"];
                        NSLog(@"offset values are %@",offsetx);
                        
                        NSArray *offsetxx = [offsetx valueForKey:@"scaleXOffset"];
                         NSLog(@"offsetxx values are %@",offsetxx);
                        
                        
                        
                        int countr =[offsetxx count];
                        NSLog(@"offset count is %d",countr);
                        
                        CTAppDelegate *appDel = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
//                        appDel.sharedArray = [offsetx valueForKey:@"scaleXOffset"];
                 //         appDel.sharedArray = [offsetx valueForKey:@"scaleXOffset"];
                        
                       
                        
                        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
                        
                        if (newp == (id)[NSNull null] || newp.length == 0 )
                        {
                            [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Please configure the pin the web" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                        }
                        
                        else
                        {
                            [defaults setObject:newp forKey:@"pin"];
                        }
                        
                        
                        [defaults setObject:newp forKey:@"pin"];
                        
                        NSString *password = [defaults valueForKey:@"pin"];
                        NSLog(@"password is %@",password);
                        
                        
                        
                       // NSString *yourString = @"comment,comment,comment";
//                        NSArray *strArray = [pass componentsSeparatedByString:@","];
//                        NSString *newPass = [strArray objectAtIndex:0];
                      //  NSLog(@"new pass is %@",newPass);
                       
                        if (isUpdatingEvents) {
                            for (int i = 0; i < [eventArray count]; i++)
                            {
                                NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:1];
                              //  [self isEventExistInDatabase:path andUpdate:YES];
                            }
                        }
                        isUpdatingEvents = NO;
                        [self.eventTable reloadData];
                    }
                    else
                    {
                        eventArray = nil;
                        eventArray = [[NSArray alloc]init];
                        [self.eventTable reloadData];
                    }
                }
            }
            }
            else
            {
                [[[UIAlertView alloc] initWithTitle:@"Alert" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                
                NSLog(@"%@",error);
                isUpdatingEvents = NO;
            }
            
        }];
        
    }

#pragma mark - TableViewDatasource methods.

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
     return eventArray.count; // in your case, there are 3 cells
}

    
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
    {
      //  return eventArray.count;
        return 1;
    }

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 10; // you can have your own choice, of course
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
    {
        static NSString *simpleTableIdentifier = @"EventTableViewCell";
        EventTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        //
        
  //      [cell.contentView.layer setBorderColor:[UIColor greenColor].CGColor];
        [cell.contentView.layer setBorderWidth:1.0f];
        
     //   [cell.contentView.layer setBorderColor :(__bridge CGColorRef _Nullable)([UIColor colorWithRed:200/255.0 green:0/255.0 blue:67/255.0 alpha:1.0])];
        
   cell.contentView.layer.borderColor = [UIColor colorWithRed:0/255.0 green:121/255.0 blue:15/255.0 alpha:1.0].CGColor;
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
       // cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.lblEvent.text = eventArray[indexPath.section][@"eventName"];
        
       //  [cell.downloadBtn setHidden:YES]; // greeshma
        
        // Old code: functionality for download button
        // commented: Ajay
        
//         [cell.downloadBtn setHidden:YES];
//        cell.downloadBtn.backgroundColor = [UIColor redColor];
        [cell.downloadBtn setHidden:NO];
        if ([self isEventExistInDatabase:indexPath andUpdate:NO]) {
            [cell.downloadBtn setHidden:YES];
            
           // [self cleanUp];
            
//            [cell.downloadBtn setTag:indexPath.section];
//            [cell.downloadBtn addTarget:self action:@selector(downloadBtnAction:) forControlEvents:UIControlEventTouchUpInside];
           
            
        
            
        }
        else
        {
            
            [cell.downloadBtn setTag:indexPath.section];
            [cell.downloadBtn addTarget:self action:@selector(downloadBtnAction:) forControlEvents:UIControlEventTouchUpInside];
            
          //    cell.downloadBtn.backgroundColor = [UIColor redColor];
            
//            [cell.downloadBtn setTag:indexPath.section];
//            [cell.downloadBtn addTarget:self action:@selector(downloadBtnAction:) forControlEvents:UIControlEventTouchUpInside];
            //        if(!alertView.isVisible && !isAlertShown)
            //        {
            //            alertView = [[UIAlertView alloc] initWithTitle:@"iAmuse" message:@"Click Event to download settings to this device" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            //            [alertView show];
            //            isAlertShown = YES;
            //        }
        }
        return cell;
    }



    
- (BOOL)isEventExistInDatabase:(NSIndexPath *)indexPath andUpdate:(BOOL)update
    {
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:storage.currentMOC];
        [request setEntity:entity];
        [request setPredicate:[NSPredicate predicateWithFormat:@"eventId == %@", eventArray[indexPath.section][@"eid"]]];
        [request setReturnsObjectsAsFaults:NO];
        NSError *errorFetch = nil;
        NSArray *array = [storage.currentMOC executeFetchRequest:request error:&errorFetch];
        if (array.count > 0)
        {
            if (update) {
                //check event has been updated?
                Event *event = [array firstObject];
                NSString *date = [[eventArray objectAtIndex:indexPath.section] objectForKey:@"updatedDate"];
                if (![date isKindOfClass:[NSNull class]]) {
                    if (![date isEqualToString:event.updatedDate])
                    {
                        //                    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                        //                    hud.mode = MBProgressHUDModeIndeterminate;
                        //                    hud.labelText = @"updating event";
                        [self updateExistingEvent:event atIndexPath:indexPath];
                        [self updateEvent:indexPath.section];
                    }
                }
                if (![[[[[eventArray objectAtIndex:indexPath.section] objectForKey:@"adminBoothEventPicture"] firstObject] objectForKey:@"defaultId"] isKindOfClass:[NSNull class]]) {
                    
                    NSFetchRequest *request = [[NSFetchRequest alloc] init];
                    NSEntityDescription *entity = [NSEntityDescription entityForName:@"PhotoLayout" inManagedObjectContext:storage.currentMOC];
                    [request setEntity:entity];
                    [request setPredicate:[NSPredicate predicateWithFormat:@"eventId == %@", eventArray[indexPath.section][@"eid"]]];
                    
                    [request setReturnsObjectsAsFaults:NO];
                    NSError *errorFetch = nil;
                    NSArray *array = [storage.currentMOC executeFetchRequest:request error:&errorFetch];
                    if (array.count > 0)
                    {
                        PhotoLayout *layout = [array firstObject];
                        NSString *date = [[[[eventArray objectAtIndex:indexPath.section] objectForKey:@"adminBoothEventPicture"] firstObject] objectForKey:@"updatedDate"];
                        
                        if (![date isKindOfClass:[NSNull class]]) {
                            if (![date isEqualToString:layout.updatedDate])
                            {
                                [self updateEvent:indexPath.section];
                                //   [self updateExistingEvent:event atIndexPath:indexPath];
                            }
                        }
                    }
                    
                }
                if ([event.isDownload isEqualToString:@"0"]) {
                    [self resumeDownloadForEvent:event];
                    return NO;
                }
            }
            return YES;
        }
        return NO;
    }
    
- (void)resumeDownloadForEvent:(Event *)event
    {
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"PhotoLayout" inManagedObjectContext:storage.currentMOC];
        [request setEntity:entity];
        [request setPredicate:[NSPredicate predicateWithFormat:@"eventId == %@ && isDownload == 0", event.eventId]];
        [request setReturnsObjectsAsFaults:NO];
        NSError *errorFetch = nil;
        NSArray *array = [storage.currentMOC executeFetchRequest:request error:&errorFetch];
        downloadedImageCount = 0;
        if ([array count]) {
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            [[[UIApplication sharedApplication] keyWindow] setUserInteractionEnabled:NO];
            
        }
        
        int count = 0;
        for(PhotoLayout *photo in array)
        {
            count++;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSLog(@"Downloading Started");
                NSString *urlToDownload = photo.backUrl;
                urlToDownload = [urlToDownload stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
                
                NSURL  *url = [NSURL URLWithString:urlToDownload];
                NSData *urlData = [NSData dataWithContentsOfURL:url];
                
                if ( urlData )
                {
                    downloadedImageCount++;
                    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                    NSString  *documentsDirectory = [paths lastObject];
                    
                    NSString * eventfolderPath = [documentsDirectory stringByAppendingPathComponent:@"/Events"];
                    
                    NSError * error;
                    if (![[NSFileManager defaultManager] fileExistsAtPath:eventfolderPath])
                    {
                        [[NSFileManager defaultManager] createDirectoryAtPath:eventfolderPath withIntermediateDirectories:YES attributes:nil error:&error];
                    }
                    
                    NSString  *eventPath = [eventfolderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",photo.eventId]];
                    if (![[NSFileManager defaultManager] fileExistsAtPath:eventPath])
                    {
                        [[NSFileManager defaultManager] createDirectoryAtPath:eventPath withIntermediateDirectories:YES attributes:nil error:&error];
                    }
                    NSString  *filePath = [NSString stringWithFormat:@"%@/%@", eventPath,[NSString stringWithFormat:@"%@",photo.order]];
                    [urlData writeToFile:filePath atomically:YES];
                    
                    [self updateDownloadStatusOfPhoto:photo isBackGround:YES];
                    
                    if (count == [array count])
                    {
                        NSError *error;
                        if (![storage.currentMOC save:&error]) {
                            NSLog(@"Failed to save - error: %@", [error localizedDescription]);
                        }
                    }
                    
                    
                    if (photo.maskImageUrl != nil)
                    {
                        NSString *urlToDownload = photo.maskImageUrl;
                        urlToDownload = [urlToDownload stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
                        NSURL  *url = [NSURL URLWithString:urlToDownload];
                        NSData *urlData = [NSData dataWithContentsOfURL:url];
                        if (urlData) {
                            
                            NSString  *maskfilePath = [NSString stringWithFormat:@"%@/%@", eventPath,[NSString stringWithFormat:@"%@_mask",photo.order]];
                            [urlData writeToFile:maskfilePath atomically:YES];
                            [self updateDownloadStatusOfPhoto:photo isBackGround:NO];
                            if (count == [array count])
                            {
                                NSError *error;
                                if (![storage.currentMOC save:&error]) {
                                    NSLog(@"Failed to save - error: %@", [error localizedDescription]);
                                }
                            }
                        }
                        else
                        {
                            [self updateForegroundStatus:photo];
                        }
                    }
                    NSLog(@"File Saved !");
                    if (downloadedImageCount == [array count]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
                            [[[UIApplication sharedApplication] keyWindow] setUserInteractionEnabled:YES];
                            [self.eventTable reloadData];
                            NSLog(@"images downloaded");
                            [self updateDownloadStatusOfEvent:photo.eventId];
                        });
                    }
                }
                else
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
                        [[[UIApplication sharedApplication] keyWindow] setUserInteractionEnabled:YES];
                    });
                }
            });
        }
        
    }
    
- (void)updateExistingEvent:(Event *)eventObject atIndexPath:(NSIndexPath *)indexPath
    {
        NSDictionary *eventData = [eventArray objectAtIndex:indexPath.section];
        
        [eventObject setValue:[self checkValueAgainstNull:@"createdDate" inDictionary:eventData] forKey:@"createdDate"];
        [eventObject setValue:[self checkValueAgainstNull:@"eid" inDictionary:eventData] forKey:@"eventId"];
        [eventObject setValue:[self checkValueAgainstNull:@"eventLocation" inDictionary:eventData] forKey:@"eventLocation"];
        [eventObject setValue:[self checkValueAgainstNull:@"eventName" inDictionary:eventData] forKey:@"eventName"];
        [eventObject setValue:[self checkValueAgainstNull:@"eventStart" inDictionary:eventData] forKey:@"eventStart"];
        [eventObject setValue:[self checkValueAgainstNull:@"updatedDate" inDictionary:eventData] forKey:@"updatedDate"];
        [eventObject setValue:[eventData objectForKey:@"isSubscribed"] forKey:@"isSubscribed"];
        
        
//        [eventObject setValue:[eventData objectForKey:@"isName"] forKey:@"isName"];
//        [eventObject setValue:[eventData objectForKey:@"isPhone"] forKey:@"isPhone"];
        
//        [eventObject setValue:@"0" forKey:@"isPhone"];
//        [eventObject setValue:@"0" forKey:@"isName"];
        
        //[eventObject setValue:@"0" forKey:@"isDownload"];
        
        if (![eventData[@"fovLeft"] isKindOfClass:[NSNull class]])
        {
            [eventObject setValue:eventData[@"fovLeft"] forKey:@"fovLeft"];
            [eventObject setValue:eventData[@"fovRight"] forKey:@"fovRight"];
            [eventObject setValue:eventData[@"fovTop"] forKey:@"fovTop"];
            [eventObject setValue:eventData[@"fovBottom"] forKey:@"fovBottom"];
            //        [eventObject setValue:eventData[@"greenScreenCountdownDelay"] forKey:@"greenScreenCountdownDelay"];
            //        [eventObject setValue:eventData[@"greenScreenDistance"] forKey:@"greenScreenDistance"];
            //        [eventObject setValue:eventData[@"greenScreenHeight"] forKey:@"greenScreenHeight"];
            //        [eventObject setValue:eventData[@"greenScreenWidth"] forKey:@"greenScreenWidth"];
            //        [eventObject setValue:eventData[@"otherCountdownDelay"] forKey:@"otherCountdownDelay"];
            //        [eventObject setValue:eventData[@"otherIntractionTimout"] forKey:@"otherIntractionTimout"];
        }
        if (![eventData[@"cameraTVScreenSaver"] isKindOfClass:[NSNull class]])
        {
            [eventObject setValue:[NSString stringWithFormat:@"/Events/%@/camera",eventData[@"eid"]] forKey:@"cameraImage"];
        }
        if (![eventData[@"waterMarkImage"] isKindOfClass:[NSNull class]])
        {
            [eventObject setValue:[NSString stringWithFormat:@"/Events/%@/watermark",eventData[@"eid"]] forKey:@"watermarkImage"];
            [eventObject setValue:[baseurl stringByAppendingString:[eventData objectForKey:@"waterMarkImage"]] forKey:@"watermarkImageUrl"];
        }
        if (![eventData[@"lookAtTouchScreen"] isKindOfClass:[NSNull class]])
        {
            [eventObject setValue:[NSString stringWithFormat:@"/Events/%@/lookat",eventData[@"eid"]] forKey:@"lookatTouchImage"];
        }
        if (![eventData[@"thankYouScreen"] isKindOfClass:[NSNull class]])
        {
            [eventObject setValue:[NSString stringWithFormat:@"/Events/%@/thankyou",eventData[@"eid"]] forKey:@"thankyouImage"];
        }
        
        NSError *error;
        if (![storage.currentMOC save:&error]) {
            NSLog(@"Failed to save - error: %@", [error localizedDescription]);
        }
        
        //    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        //    hud.mode = MBProgressHUDModeIndeterminate;
        //    hud.labelText = @"updating event";
        
        
        /*
         dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
         NSLog(@"Downloading Started");
         
         NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
         NSString  *documentsDirectory = [paths lastObject];
         
         NSString * eventfolderPath = [documentsDirectory stringByAppendingPathComponent:@"/Events"];
         
         NSError * error;
         if (![[NSFileManager defaultManager] fileExistsAtPath:eventfolderPath])
         {
         [[NSFileManager defaultManager] createDirectoryAtPath:eventfolderPath withIntermediateDirectories:YES attributes:nil error:&error];
         }
         
         NSString  *eventPath = [eventfolderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",eventData[@"eid"]]];
         if (![[NSFileManager defaultManager] fileExistsAtPath:eventPath])
         {
         [[NSFileManager defaultManager] createDirectoryAtPath:eventPath withIntermediateDirectories:YES attributes:nil error:&error];
         }
         
         if (![eventData[@"cameraTVScreenSaver"] isKindOfClass:[NSNull class]])
         {
         NSString *urlToDownload = [baseurl stringByAppendingString:[eventData objectForKey:@"cameraTVScreenSaver"]];
         urlToDownload = [urlToDownload stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
         NSURL  *url = [NSURL URLWithString:urlToDownload];
         NSData *urlData = [NSData dataWithContentsOfURL:url];
         if (urlData) {
         
         NSString  *maskfilePath = [NSString stringWithFormat:@"%@/camera", eventPath];
         [urlData writeToFile:maskfilePath atomically:YES];
         }
         }
         if (![eventData[@"thankYouScreen"] isKindOfClass:[NSNull class]])
         {
         NSString *urlToDownload = [baseurl stringByAppendingString:[eventData objectForKey:@"thankYouScreen"]];
         urlToDownload = [urlToDownload stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
         NSURL  *url = [NSURL URLWithString:urlToDownload];
         NSData *urlData = [NSData dataWithContentsOfURL:url];
         if (urlData)
         {
         NSString  *maskfilePath = [NSString    stringWithFormat:@"%@/thankyou", eventPath];
         [urlData writeToFile:maskfilePath atomically:YES];
         }
         
         }
         if (![eventData[@"lookAtTouchScreen"] isKindOfClass:[NSNull class]])
         {
         NSString *urlToDownload = [baseurl stringByAppendingString:[eventData objectForKey:@"lookAtTouchScreen"]];
         urlToDownload = [urlToDownload stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
         NSURL  *url = [NSURL URLWithString:urlToDownload];
         NSData *urlData = [NSData dataWithContentsOfURL:url];
         if (urlData)
         {
         NSString  *maskfilePath = [NSString    stringWithFormat:@"%@/lookat", eventPath];
         [urlData writeToFile:maskfilePath atomically:YES];
         }
         
         }
         if (![eventData[@"waterMarkImage"] isKindOfClass:[NSNull class]])
         {
         NSString *urlToDownload = [baseurl stringByAppendingString:[eventData objectForKey:@"waterMarkImage"]];
         urlToDownload = [urlToDownload stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
         NSURL  *url = [NSURL URLWithString:urlToDownload];
         NSData *urlData = [NSData dataWithContentsOfURL:url];
         if (urlData)
         {
         NSString  *maskfilePath = [NSString    stringWithFormat:@"%@/watermark", eventPath];
         [urlData writeToFile:maskfilePath atomically:YES];
         }
         }
         
         dispatch_sync(dispatch_get_main_queue(), ^{
         [MBProgressHUD hideHUDForView:self.view animated:YES];
         
         });
         });
         */
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"PhotoLayout" inManagedObjectContext:storage.currentMOC];
        [request setEntity:entity];
        [request setPredicate:[NSPredicate predicateWithFormat:@"eventId == %@", eventArray[indexPath.section][@"eid"]]];
        [request setReturnsObjectsAsFaults:NO];
        NSError *errorFetch = nil;
        NSArray *array = [storage.currentMOC executeFetchRequest:request error:&errorFetch];
        
        NSString * path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *pth = [NSString stringWithFormat:@"/Events/%@/",eventArray[indexPath.section][@"eid"]];
        path = [path stringByAppendingPathComponent:pth];
        NSFileManager *fileMgr = [[NSFileManager alloc] init];
        BOOL success = [fileMgr removeItemAtPath:path error:&error];
        if (success) {
        }
        else
        {
            NSLog(@"Could not delete file -:%@ ",[error localizedDescription]);
        }
        
        for(NSManagedObject *managedObject in array)
        {
            PhotoLayout *layout = (PhotoLayout *)managedObject;
            //Clear from document directory.
            NSString * path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            NSString *pth = [NSString stringWithFormat:@"/Events/%@/%@/",eventArray[indexPath.section][@"eid"],layout.order];
            path = [path stringByAppendingPathComponent:pth];
            NSFileManager *fileMgr = [[NSFileManager alloc] init];
            NSError *error;
            BOOL success = [fileMgr removeItemAtPath:path error:&error];
            if (success) {
            }
            else
            {
                NSLog(@"Could not delete file -:%@ ",[error localizedDescription]);
            }
            [storage.currentMOC deleteObject:managedObject];
        }
        if ([storage.currentMOC save:&error] == NO) {
            //        NSAssert(NO, @"Save should not fail\n%@", [error localizedDescription]);
            abort();
        }
        
        
        return;
        
        int count = 0;
        for (NSDictionary *photos in [eventData objectForKey:@"adminBoothEventPicture"])
        {
            NSManagedObject *photoLayoutObject = [NSEntityDescription insertNewObjectForEntityForName:@"PhotoLayout"
                                                                               inManagedObjectContext:storage.currentMOC];
            [photoLayoutObject setValue:[NSString stringWithFormat:@"/Events/%@/%@",photos[@"eId"],photos[@"picId"]] forKey:@"background"];
            [photoLayoutObject setValue:[baseurl stringByAppendingString:[photos objectForKey:@"picName"]] forKey:@"backUrl"];
            if (![photos[@"updatedDate"] isKindOfClass:[NSNull class]])
            {
                [photoLayoutObject setValue:photos[@"updatedDate"] forKey:@"updatedDate"];
            }
            if (![photos[@"imageMask"] isKindOfClass:[NSNull class]])
            {
                [photoLayoutObject setValue:[NSString stringWithFormat:@"/Events/%@/%@_mask",photos[@"eId"],photos[@"picId"]] forKey:@"foreground"];
                [photoLayoutObject setValue:[baseurl stringByAppendingString:[photos objectForKey:@"imageMask"]] forKey:@"maskImageUrl"];
                
            }
            if (![photos[@"defaultId"] isKindOfClass:[NSNull class]])
            {
                [photoLayoutObject setValue:photos[@"defaultId"] forKey:@"defaultId"];
            }
            
            [photoLayoutObject setValue:[NSNumber numberWithDouble:0.0] forKey:@"bottomCurtain"];
            if (![photos[@"picTitle"] isKindOfClass:[NSNull class]])
            [photoLayoutObject setValue:photos[@"picTitle"] forKey:@"desc"];
            else
            [photoLayoutObject setValue:@"" forKey:@"desc"];
            
            [photoLayoutObject setValue:photos[@"picId"] forKey:@"order"];
            [photoLayoutObject setValue:photos[@"eId"] forKey:@"eventId"];
            [photoLayoutObject setValue:@"1" forKey:@"isDownload"];
            if (![photos[@"scaleZOffset"] isKindOfClass:[NSNull class]])
            [photoLayoutObject setValue:[NSNumber numberWithDouble:[photos[@"scaleZOffset"] doubleValue]] forKey:@"scale"];
            else
            [photoLayoutObject setValue:[NSNumber numberWithDouble:1.0] forKey:@"scale"];
            
            [photoLayoutObject setValue:[self getXOffsetInRatio:photos] forKey:@"xOffset"];
            [photoLayoutObject setValue:[self getYOffsetInRatio:photos] forKey:@"yOffset"];
            [photoLayoutObject setValue:[self getWidthInRatio:photos] forKey:@"cameraWidth"];
            [photoLayoutObject setValue:[self getHeightInRatio:photos] forKey:@"cameraHieght"];
            
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:photos[@"imageHeight"] forKey:@"imageHeight"];
             [defaults setObject:photos[@"imageWidth"] forKey:@"imageWidth"];
            
          //  [photoLayoutObject setValue:photos[@"imageHeight"] forKey:@"imageHeight"];
            
            NSError *error1;
            if (![storage.currentMOC save:&error1]) {
                NSLog(@"Failed to save - error: %@", [error1 localizedDescription]);
            }
            
            
            downloadedImageCount = 0;
            //  [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSLog(@"Downloading Started");
                NSString *urlToDownload = [baseurl stringByAppendingString:[photos objectForKey:@"picName"]];
                urlToDownload = [urlToDownload stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
                
                NSURL  *url = [NSURL URLWithString:urlToDownload];
                NSData *urlData = [NSData dataWithContentsOfURL:url];
                downloadedImageCount++;
                if ( urlData )
                {
                    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                    NSString  *documentsDirectory = [paths lastObject];
                    
                    NSString * eventfolderPath = [documentsDirectory stringByAppendingPathComponent:@"/Events"];
                    
                    NSError * error;
                    if (![[NSFileManager defaultManager] fileExistsAtPath:eventfolderPath])
                    {
                        [[NSFileManager defaultManager] createDirectoryAtPath:eventfolderPath withIntermediateDirectories:YES attributes:nil error:&error];
                    }
                    
                    NSString  *eventPath = [eventfolderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",photos[@"eId"]]];
                    if (![[NSFileManager defaultManager] fileExistsAtPath:eventPath])
                    {
                        [[NSFileManager defaultManager] createDirectoryAtPath:eventPath withIntermediateDirectories:YES attributes:nil error:&error];
                    }
                    NSString  *filePath = [NSString stringWithFormat:@"%@/%@", eventPath,[NSString stringWithFormat:@"%@",photos[@"picId"]]];
                    [urlData writeToFile:filePath atomically:YES];
                    
                    [self updateDownloadStatusOfPhoto:photos isBackGround:YES];
                    
                    if (count == [[eventData objectForKey:@"adminBoothEventPicture"] count])
                    {
                        NSError *error;
                        if (![storage.currentMOC save:&error]) {
                            NSLog(@"Failed to save - error: %@", [error localizedDescription]);
                        }
                    }
                    
                    
                    if (![photos[@"imageMask"] isKindOfClass:[NSNull class]])
                    {
                        NSString *urlToDownload = [baseurl stringByAppendingString:[photos objectForKey:@"imageMask"]];
                        urlToDownload = [urlToDownload stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
                        NSURL  *url = [NSURL URLWithString:urlToDownload];
                        NSData *urlData = [NSData dataWithContentsOfURL:url];
                        if (urlData) {
                            NSString  *maskfilePath = [NSString stringWithFormat:@"%@/%@", eventPath,[NSString stringWithFormat:@"%@_mask",photos[@"picId"]]];
                            [urlData writeToFile:maskfilePath atomically:YES];
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                                [self updateDownloadStatusOfPhoto:photos isBackGround:NO];
                                if (count == [[eventData objectForKey:@"adminBoothEventPicture"] count])
                                {
                                    NSError *error;
                                    if (![storage.currentMOC save:&error]) {
                                        NSLog(@"Failed to save - error: %@", [error localizedDescription]);
                                    }
                                }
                            });
                            
                        }
                        else
                        {
                            [self updateForegroundStatus:photos];
                        }
                    }
                    
                    NSLog(@"File Saved !");
                    if (downloadedImageCount == [[eventData objectForKey:@"adminBoothEventPicture"] count]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [hud hide:YES];
                            [self.eventTable reloadData];
                            NSLog(@"images downloaded");
                            [self updateDownloadStatusOfEvent:photos[@"eId"]];
                            [[[UIApplication sharedApplication] keyWindow] setUserInteractionEnabled:YES];
                        });
                    }
                }
                
            });
            //        [hud hide:YES];
        }
        
    }
    
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
    {
        
        
        [self autoConfigureCameraAndTouchDevice];
        
//        [self refreshAction];

        if ([[eventArray[indexPath.section] objectForKey:@"adminBoothEventPicture"] count] == 0) {
            [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"No backgrounds in this event to download" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            return;
        }
        // greeshma
        
//        hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//        hud.mode = MBProgressHUDModeIndeterminate;
//        hud.labelText = @"loading event";
//
        //  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ // greeshma
              
     //   [self downloadBtnAction:indexPath];//greeshma
        
              
  //             dispatch_async(dispatch_get_main_queue(), ^{ // greeshma
        
        
        
//        [cell.downloadBtn sendActionsForControlEvents:UIControlEventTouchUpInside];
        
//        if([updateStr isEqualToString:@"updated"])
//        {
//            [cell.downloadBtn setHidden:NO];
//        [cell.downloadBtn setTag:indexPath.section];
//        [cell.downloadBtn addTarget:self action:@selector(downloadBtnAction:) forControlEvents:UIControlEventTouchUpInside];
//
//            [cell.downloadBtn sendActionsForControlEvents:UIControlEventTouchUpInside];
//        }
//
//        else{
//            [cell.downloadBtn setHidden:YES];
        
        if ([self isEventExistInDatabase:indexPath andUpdate:NO]) { // should comment - greeshma
            
            
            
          
            
            
            
            [MBProgressHUD showHUDAddedTo:self.view animated:YES]; // should comment - greeshma
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:storage.currentMOC];
            [request setEntity:entity];
            [request setReturnsObjectsAsFaults:NO];
            [request setPredicate:[NSPredicate predicateWithFormat:@"eventId == %@", eventArray[indexPath.section][@"eid"]]];
            NSError *errorFetch = nil;
            NSArray *array = [storage.currentMOC executeFetchRequest:request error:&errorFetch];
            if (array.count) {
                [kiosk setEventId:eventArray[indexPath.section][@"eid"]];
                [kiosk startup:eventArray[indexPath.section][@"eid"]];
                [kiosk setIsSubscribed:[eventArray[indexPath.section][@"isSubscribed"] boolValue]];
                
                [kiosk setIsPhone:[eventArray[indexPath.section][@"isPhone"] boolValue]];
                [kiosk setIsName:[eventArray[indexPath.section][@"isName"] boolValue]];
                
//                [kiosk setIsPhone:1];
//                [kiosk setIsName:1];
               
                
                UIViewController *vviewController;
                NSUserDefaults * userdefault = [NSUserDefaults standardUserDefaults];
                NSString * deviceModePref = [userdefault stringForKey:AMDeviceModeSettingsKey];
                
                if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
                {
                    vviewController = [self.storyboard instantiateViewControllerWithIdentifier:@"CTKioskViewController"];
                }
                else
                {
             //       CTSelectSceneViewController *move = [self.storyboard instantiateViewControllerWithIdentifier:@"selectSceneViewController"];
             //       [self presentViewController:move animated:YES completion:nil];
                    
                    
                    vviewController = [self.storyboard instantiateViewControllerWithIdentifier:@"selectSceneViewController"];
                }
                [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
                [self.navigationController pushViewController:vviewController animated:YES];
            }
              
//              }); // greeshma
//
//          });// greeshma
        
         } // should complete - greeshma
    //    }
    }





//- (void)downloadBtnAction:(UIButton *)sender

//- (void)downloadBtnAction:(UIButton *)sender
//{
//    // save event in database
//    NSDictionary *eventData = [eventArray objectAtIndex:sender.tag];
//    if ([[eventData objectForKey:@"adminBoothEventPicture"] count] == 0) {
//        [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"No backgrounds in this event to download" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
//        return;
//    }
//    NSManagedObject *eventObject = [NSEntityDescription insertNewObjectForEntityForName:@"Event"
//                                                                 inManagedObjectContext:storage.currentMOC];
//    [eventObject setValue:[self checkValueAgainstNull:@"createdDate" inDictionary:eventData] forKey:@"createdDate"];
//    [eventObject setValue:[self checkValueAgainstNull:@"eid" inDictionary:eventData] forKey:@"eventId"];
//    [eventObject setValue:[self checkValueAgainstNull:@"eventLocation" inDictionary:eventData] forKey:@"eventLocation"];
//    [eventObject setValue:[self checkValueAgainstNull:@"eventName" inDictionary:eventData] forKey:@"eventName"];
//    [eventObject setValue:[self checkValueAgainstNull:@"eventStart" inDictionary:eventData] forKey:@"eventStart"];
//    [eventObject setValue:[self checkValueAgainstNull:@"updatedDate" inDictionary:eventData] forKey:@"updatedDate"];
//    [eventObject setValue:@"0" forKey:@"isDownload"];
//    [eventObject setValue:[eventData objectForKey:@"isSubscribed"] forKey:@"isSubscribed"];
//
//    if (![eventData[@"fovLeft"] isKindOfClass:[NSNull class]])
//    {
//        [eventObject setValue:eventData[@"fovLeft"] forKey:@"fovLeft"];
//        [eventObject setValue:eventData[@"fovRight"] forKey:@"fovRight"];
//        [eventObject setValue:eventData[@"fovTop"] forKey:@"fovTop"];
//        [eventObject setValue:eventData[@"fovBottom"] forKey:@"fovBottom"];
//        //        [eventObject setValue:eventData[@"greenScreenCountdownDelay"] forKey:@"greenScreenCountdownDelay"];
//        //        [eventObject setValue:eventData[@"greenScreenDistance"] forKey:@"greenScreenDistance"];
//        //        [eventObject setValue:eventData[@"greenScreenHeight"] forKey:@"greenScreenHeight"];
//        //        [eventObject setValue:eventData[@"greenScreenWidth"] forKey:@"greenScreenWidth"];
//        //        [eventObject setValue:eventData[@"otherCountdownDelay"] forKey:@"otherCountdownDelay"];
//        //        [eventObject setValue:eventData[@"otherIntractionTimout"] forKey:@"otherIntractionTimout"];
//    }
//    if (![eventData[@"cameraTVScreenSaver"] isKindOfClass:[NSNull class]])
//    {
//        [eventObject setValue:[NSString stringWithFormat:@"/Events/%@/camera",eventData[@"eid"]] forKey:@"cameraImage"];
//    }
//    if (![eventData[@"waterMarkImage"] isKindOfClass:[NSNull class]])
//    {
//        [eventObject setValue:[NSString stringWithFormat:@"/Events/%@/watermark",eventData[@"eid"]] forKey:@"watermarkImage"];
//        [eventObject setValue:[baseurl stringByAppendingString:[eventData objectForKey:@"waterMarkImage"]] forKey:@"watermarkImageUrl"];
//    }
//    if (![eventData[@"lookAtTouchScreen"] isKindOfClass:[NSNull class]])
//    {
//        [eventObject setValue:[NSString stringWithFormat:@"/Events/%@/lookat",eventData[@"eid"]] forKey:@"lookatTouchImage"];
//    }
//    if (![eventData[@"thankYouScreen"] isKindOfClass:[NSNull class]])
//    {
//        [eventObject setValue:[NSString stringWithFormat:@"/Events/%@/thankyou",eventData[@"eid"]] forKey:@"thankyouImage"];
//    }
//    NSError *error;
//    if (![storage.currentMOC save:&error]) {
//        NSLog(@"Failed to save - error: %@", [error localizedDescription]);
//    }
//
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        NSLog(@"Downloading Started");
//
//        NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//        NSString  *documentsDirectory = [paths lastObject];
//
//        NSString * eventfolderPath = [documentsDirectory stringByAppendingPathComponent:@"/Events"];
//
//        NSError * error;
//        if (![[NSFileManager defaultManager] fileExistsAtPath:eventfolderPath])
//        {
//            [[NSFileManager defaultManager] createDirectoryAtPath:eventfolderPath withIntermediateDirectories:YES attributes:nil error:&error];
//        }
//
//        NSString  *eventPath = [eventfolderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",eventData[@"eid"]]];
//        if (![[NSFileManager defaultManager] fileExistsAtPath:eventPath])
//        {
//            [[NSFileManager defaultManager] createDirectoryAtPath:eventPath withIntermediateDirectories:YES attributes:nil error:&error];
//        }
//
//        if (![eventData[@"cameraTVScreenSaver"] isKindOfClass:[NSNull class]])
//        {
//            NSString *urlToDownload = [baseurl stringByAppendingString:[eventData objectForKey:@"cameraTVScreenSaver"]];
//            urlToDownload = [urlToDownload stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
//            NSURL  *url = [NSURL URLWithString:urlToDownload];
//            NSData *urlData = [NSData dataWithContentsOfURL:url];
//            if (urlData) {
//
//                NSString  *maskfilePath = [NSString stringWithFormat:@"%@/camera", eventPath];
//                [urlData writeToFile:maskfilePath atomically:YES];
//            }
//        }
//        if (![eventData[@"thankYouScreen"] isKindOfClass:[NSNull class]])
//        {
//            NSString *urlToDownload = [baseurl stringByAppendingString:[eventData objectForKey:@"thankYouScreen"]];
//            urlToDownload = [urlToDownload stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
//            NSURL  *url = [NSURL URLWithString:urlToDownload];
//            NSData *urlData = [NSData dataWithContentsOfURL:url];
//            if (urlData)
//            {
//                NSString  *maskfilePath = [NSString    stringWithFormat:@"%@/thankyou", eventPath];
//                [urlData writeToFile:maskfilePath atomically:YES];
//            }
//
//        }
//        if (![eventData[@"lookAtTouchScreen"] isKindOfClass:[NSNull class]])
//        {
//            NSString *urlToDownload = [baseurl stringByAppendingString:[eventData objectForKey:@"lookAtTouchScreen"]];
//            urlToDownload = [urlToDownload stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
//            NSURL  *url = [NSURL URLWithString:urlToDownload];
//            NSData *urlData = [NSData dataWithContentsOfURL:url];
//            if (urlData)
//            {
//                NSString  *maskfilePath = [NSString    stringWithFormat:@"%@/lookat", eventPath];
//                [urlData writeToFile:maskfilePath atomically:YES];
//            }
//
//        }
//        if (![eventData[@"waterMarkImage"] isKindOfClass:[NSNull class]])
//        {
//            NSString *urlToDownload = [baseurl stringByAppendingString:[eventData objectForKey:@"waterMarkImage"]];
//            urlToDownload = [urlToDownload stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
//            NSURL  *url = [NSURL URLWithString:urlToDownload];
//            NSData *urlData = [NSData dataWithContentsOfURL:url];
//            if (urlData)
//            {
//                NSString  *maskfilePath = [NSString    stringWithFormat:@"%@/watermark", eventPath];
//                [urlData writeToFile:maskfilePath atomically:YES];
//            }
//        }
//    });
//
//    downloadedImageCount = 0;
//
//    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//    hud.mode = MBProgressHUDModeIndeterminate;
//    hud.labelText = @"downloading event";
//    [[[UIApplication sharedApplication] keyWindow] setUserInteractionEnabled:NO];
//
//    int count = 0;
//    for (NSDictionary *photos in [eventData objectForKey:@"adminBoothEventPicture"])
//    {
//        count++;
//        NSManagedObject *photoLayoutObject = [NSEntityDescription insertNewObjectForEntityForName:@"PhotoLayout"
//                                                                           inManagedObjectContext:storage.currentMOC];
//        [photoLayoutObject setValue:[NSString stringWithFormat:@"/Events/%@/%@",photos[@"eId"],photos[@"picId"]] forKey:@"background"];
//        [photoLayoutObject setValue:[baseurl stringByAppendingString:[photos objectForKey:@"picName"]] forKey:@"backUrl"];
//        if (![photos[@"updatedDate"] isKindOfClass:[NSNull class]])
//        {
//            [photoLayoutObject setValue:photos[@"updatedDate"] forKey:@"updatedDate"];
//        }
//
//        if (![photos[@"imageMask"] isKindOfClass:[NSNull class]])
//        {
//            [photoLayoutObject setValue:[NSString stringWithFormat:@"/Events/%@/%@_mask",photos[@"eId"],photos[@"picId"]] forKey:@"foreground"];
//            [photoLayoutObject setValue:[baseurl stringByAppendingString:[photos objectForKey:@"imageMask"]] forKey:@"maskImageUrl"];
//
//        }
//
//        if (![photos[@"defaultId"] isKindOfClass:[NSNull class]])
//        {
//            [photoLayoutObject setValue:photos[@"defaultId"] forKey:@"defaultId"];
//        }
//        [photoLayoutObject setValue:[NSNumber numberWithDouble:0.0] forKey:@"bottomCurtain"];
//        if (![photos[@"picTitle"] isKindOfClass:[NSNull class]])
//            [photoLayoutObject setValue:photos[@"picTitle"] forKey:@"desc"];
//        else
//            [photoLayoutObject setValue:@"" forKey:@"desc"];
//        [photoLayoutObject setValue:photos[@"picId"] forKey:@"order"];
//        [photoLayoutObject setValue:photos[@"eId"] forKey:@"eventId"];
//        [photoLayoutObject setValue:@"0" forKey:@"isDownload"];
//        if (![photos[@"scaleZOffset"] isKindOfClass:[NSNull class]])
//            [photoLayoutObject setValue:[NSNumber numberWithDouble:[photos[@"scaleZOffset"] doubleValue]] forKey:@"scale"];
//        else
//            [photoLayoutObject setValue:[NSNumber numberWithDouble:1.0] forKey:@"scale"];
//
//        [self.eventTable layoutIfNeeded];
//        [photoLayoutObject setValue:[self getXOffsetInRatio:photos] forKey:@"xOffset"];
//        [photoLayoutObject setValue:[self getYOffsetInRatio:photos] forKey:@"yOffset"];
//        [photoLayoutObject setValue:[self getWidthInRatio:photos] forKey:@"cameraWidth"];
//        [photoLayoutObject setValue:[self getHeightInRatio:photos] forKey:@"cameraHieght"];
//
//        NSError *error1;
//        if (![storage.currentMOC save:&error1]) {
//            NSLog(@"Failed to save - error: %@", [error1 localizedDescription]);
//        }
//
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            NSLog(@"Downloading Started");
//            NSString *urlToDownload = [baseurl stringByAppendingString:[photos objectForKey:@"picName"]];
//            urlToDownload = [urlToDownload stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
//
//            NSURL  *url = [NSURL URLWithString:urlToDownload];
//            NSData *urlData = [NSData dataWithContentsOfURL:url];
//            downloadedImageCount++;
//            if ( urlData )
//            {
//                NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//                NSString  *documentsDirectory = [paths lastObject];
//
//                NSString * eventfolderPath = [documentsDirectory stringByAppendingPathComponent:@"/Events"];
//
//                NSError * error;
//                if (![[NSFileManager defaultManager] fileExistsAtPath:eventfolderPath])
//                {
//                    [[NSFileManager defaultManager] createDirectoryAtPath:eventfolderPath withIntermediateDirectories:YES attributes:nil error:&error];
//                }
//
//                NSString  *eventPath = [eventfolderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",photos[@"eId"]]];
//                if (![[NSFileManager defaultManager] fileExistsAtPath:eventPath])
//                {
//                    [[NSFileManager defaultManager] createDirectoryAtPath:eventPath withIntermediateDirectories:YES attributes:nil error:&error];
//                }
//                NSString  *filePath = [NSString stringWithFormat:@"%@/%@", eventPath,[NSString stringWithFormat:@"%@",photos[@"picId"]]];
//                [urlData writeToFile:filePath atomically:YES];
//
//                [self updateDownloadStatusOfPhoto:photos isBackGround:YES];
//
//                if (count == [[eventData objectForKey:@"adminBoothEventPicture"] count])
//                {
//                    NSError *error;
//                    if (![storage.currentMOC save:&error]) {
//                        NSLog(@"Failed to save - error: %@", [error localizedDescription]);
//                    }
//                }
//
//
//                if (![photos[@"imageMask"] isKindOfClass:[NSNull class]])
//                {
//                    NSString *urlToDownload = [baseurl stringByAppendingString:[photos objectForKey:@"imageMask"]];
//                    urlToDownload = [urlToDownload stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
//                    NSURL  *url = [NSURL URLWithString:urlToDownload];
//                    NSData *urlData = [NSData dataWithContentsOfURL:url];
//                    if (urlData) {
//                        NSString  *maskfilePath = [NSString stringWithFormat:@"%@/%@", eventPath,[NSString stringWithFormat:@"%@_mask",photos[@"picId"]]];
//                        [urlData writeToFile:maskfilePath atomically:YES];
//                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//                            [self updateDownloadStatusOfPhoto:photos isBackGround:NO];
//                            if (count == [[eventData objectForKey:@"adminBoothEventPicture"] count])
//                            {
//                                NSError *error;
//                                if (![storage.currentMOC save:&error]) {
//                                    NSLog(@"Failed to save - error: %@", [error localizedDescription]);
//                                }
//                            }
//                        });
//
//                    }
//                    else
//                    {
//                        [self updateForegroundStatus:photos];
//                    }
//                }
//
//                NSLog(@"File Saved !");
//                if (downloadedImageCount == [[eventData objectForKey:@"adminBoothEventPicture"] count])
//                {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [hud hide:YES];
//                        [self.eventTable reloadData];
//                        NSLog(@"images downloaded");
//                        [self updateDownloadStatusOfEvent:photos[@"eId"]];
//                        [[[UIApplication sharedApplication] keyWindow] setUserInteractionEnabled:YES];
//
//
//                        //-----
//
//                        NSFetchRequest *request = [[NSFetchRequest alloc] init];
//                        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:storage.currentMOC];
//                        [request setEntity:entity];
//                        [request setReturnsObjectsAsFaults:NO];
//                        [request setPredicate:[NSPredicate predicateWithFormat:@"eventId == %@", eventArray[sender.tag][@"eid"]]];
//                        NSError *errorFetch = nil;
//                        NSArray *array = [storage.currentMOC executeFetchRequest:request error:&errorFetch];
//                        if (array.count) {
//                            [kiosk setEventId:eventArray[sender.tag][@"eid"]];
//                            [kiosk startup:eventArray[sender.tag][@"eid"]];
//                            [kiosk setIsSubscribed:[eventArray[sender.tag][@"isSubscribed"] boolValue]];
//
//                            UIViewController *viewController;
//                            NSUserDefaults * userdefault = [NSUserDefaults standardUserDefaults];
//                            NSString * deviceModePref = [userdefault stringForKey:AMDeviceModeSettingsKey];
//
//                            if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
//                            {
//                                viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"CTKioskViewController"];
//                            }
//                            else
//                            {
//                                viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"selectSceneViewController"];
//
//
//                            }
//                            [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
//                            [self.navigationController pushViewController:viewController animated:YES];
//
//
//                        }
//
//
//                        //-----
//
//                    });
//                }
//            }
//
//        });
//    }
//}
//





- (void)downloadBtnAction:(UIButton *)sender
{
    
    [self autoConfigureCameraAndTouchDevice];
   NSUserDefaults *usrdefaults = [NSUserDefaults standardUserDefaults];
    
    NSString * cameraRegister = [usrdefaults stringForKey:@"cameraIP"];
    NSString * touchRegister = [usrdefaults stringForKey:@"touchIP"];
    
    
    NSLog(@"camera %@ touch %@",cameraRegister,touchRegister);
    
    
    if(cameraRegister.length==0 || touchRegister.length==0)
    {
        [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Please login from the other device before downloading the event" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
    
   else
   {
    
  //  NSString*  download  =   @"http://stark.eastus.cloudapp.azure.com:8000";
  //  NSString*  download  =   @"http://192.168.2.33:8000";
    NSString*  download  =   @"http://star-k.eastus.cloudapp.azure.com:8000";
       
 //       NSString*  download  =   @"http://192.168.2.14:8080";
       
   //     NSString*  download  =   @"http://iamuses.eastus.cloudapp.azure.com:8080";
    
    // save event in database
    NSDictionary *eventData = [eventArray objectAtIndex:sender.tag];
    if ([[eventData objectForKey:@"adminBoothEventPicture"] count] == 0) {
        [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"No backgrounds in this event to download" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
    }
    
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"Downloading Event";
    [[[UIApplication sharedApplication] keyWindow] setUserInteractionEnabled:NO];
    
    NSManagedObject *eventObject = [NSEntityDescription insertNewObjectForEntityForName:@"Event"
                                                                 inManagedObjectContext:storage.currentMOC];
    [eventObject setValue:[self checkValueAgainstNull:@"createdDate" inDictionary:eventData] forKey:@"createdDate"];
    [eventObject setValue:[self checkValueAgainstNull:@"eid" inDictionary:eventData] forKey:@"eventId"];
    [eventObject setValue:[self checkValueAgainstNull:@"eventLocation" inDictionary:eventData] forKey:@"eventLocation"];
    [eventObject setValue:[self checkValueAgainstNull:@"eventName" inDictionary:eventData] forKey:@"eventName"];
    [eventObject setValue:[self checkValueAgainstNull:@"eventStart" inDictionary:eventData] forKey:@"eventStart"];
    [eventObject setValue:[self checkValueAgainstNull:@"updatedDate" inDictionary:eventData] forKey:@"updatedDate"];
    [eventObject setValue:@"0" forKey:@"isDownload"];
    [eventObject setValue:[eventData objectForKey:@"isSubscribed"] forKey:@"isSubscribed"];
    
//    [eventObject setValue:[eventData objectForKey:@"isName"] forKey:@"isName"];
//    [eventObject setValue:[eventData objectForKey:@"isPhone"] forKey:@"isPhone"];
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self checkValueAgainstNull:@"eid" inDictionary:eventData] forKey:@"event"];
    
    NSString *val = [defaults stringForKey:@"event"];
    
    NSLog(@"event id is %@",val);
    
    if (![eventData[@"fovLeft"] isKindOfClass:[NSNull class]])
    {
        [eventObject setValue:eventData[@"fovLeft"] forKey:@"fovLeft"];
        [eventObject setValue:eventData[@"fovRight"] forKey:@"fovRight"];
        [eventObject setValue:eventData[@"fovTop"] forKey:@"fovTop"];
        [eventObject setValue:eventData[@"fovBottom"] forKey:@"fovBottom"];
       
    }
    
    if (![eventData[@"cameraTVScreenSaver"] isKindOfClass:[NSNull class]])
    {
        [eventObject setValue:[NSString stringWithFormat:@"/Events/%@/camera",eventData[@"eid"]] forKey:@"cameraImage"];
    }
    if (![eventData[@"waterMarkImage"] isKindOfClass:[NSNull class]])
    {
        [eventObject setValue:[NSString stringWithFormat:@"/Events/%@/watermark",eventData[@"eid"]] forKey:@"watermarkImage"];
        [eventObject setValue:[download stringByAppendingString:[eventData objectForKey:@"waterMarkImage"]] forKey:@"watermarkImageUrl"];
    }
    if (![eventData[@"lookAtTouchScreen"] isKindOfClass:[NSNull class]])
    {
        [eventObject setValue:[NSString stringWithFormat:@"/Events/%@/lookat",eventData[@"eid"]] forKey:@"lookatTouchImage"];
    }
    if (![eventData[@"thankYouScreen"] isKindOfClass:[NSNull class]])
    {
        [eventObject setValue:[NSString stringWithFormat:@"/Events/%@/thankyou",eventData[@"eid"]] forKey:@"thankyouImage"];
    }
    NSError *error;
    if (![storage.currentMOC save:&error]) {
        NSLog(@"Failed to save - error: %@", [error localizedDescription]);
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"Downloading Started");
        
        NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString  *documentsDirectory = [paths lastObject];
        
        NSString * eventfolderPath = [documentsDirectory stringByAppendingPathComponent:@"/Events"];
        
        NSError * error;
        if (![[NSFileManager defaultManager] fileExistsAtPath:eventfolderPath])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:eventfolderPath withIntermediateDirectories:YES attributes:nil error:&error];
        }
        
        NSString  *eventPath = [eventfolderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",eventData[@"eid"]]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:eventPath])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:eventPath withIntermediateDirectories:YES attributes:nil error:&error];
        }
        
        if (![eventData[@"cameraTVScreenSaver"] isKindOfClass:[NSNull class]])
        {
            NSString *urlToDownload = [download stringByAppendingString:[eventData objectForKey:@"cameraTVScreenSaver"]];
            urlToDownload = [urlToDownload stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
            NSURL  *url = [NSURL URLWithString:urlToDownload];
            NSData *urlData = [NSData dataWithContentsOfURL:url];
            if (urlData) {
                
                NSString  *maskfilePath = [NSString stringWithFormat:@"%@/camera", eventPath];
                [urlData writeToFile:maskfilePath atomically:YES];
            }
        }
        if (![eventData[@"thankYouScreen"] isKindOfClass:[NSNull class]])
        {
            NSString *urlToDownload = [download stringByAppendingString:[eventData objectForKey:@"thankYouScreen"]];
            urlToDownload = [urlToDownload stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
            NSURL  *url = [NSURL URLWithString:urlToDownload];
            NSData *urlData = [NSData dataWithContentsOfURL:url];
            if (urlData)
            {
                NSString  *maskfilePath = [NSString    stringWithFormat:@"%@/thankyou", eventPath];
                [urlData writeToFile:maskfilePath atomically:YES];
            }
            
        }
        if (![eventData[@"lookAtTouchScreen"] isKindOfClass:[NSNull class]])
        {
            NSString *urlToDownload = [download stringByAppendingString:[eventData objectForKey:@"lookAtTouchScreen"]];
            urlToDownload = [urlToDownload stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
            NSURL  *url = [NSURL URLWithString:urlToDownload];
            NSData *urlData = [NSData dataWithContentsOfURL:url];
            if (urlData)
            {
                NSString  *maskfilePath = [NSString    stringWithFormat:@"%@/lookat", eventPath];
                [urlData writeToFile:maskfilePath atomically:YES];
            }
            
        }
        if (![eventData[@"waterMarkImage"] isKindOfClass:[NSNull class]])
        {
            NSString *urlToDownload = [download stringByAppendingString:[eventData objectForKey:@"waterMarkImage"]];
            urlToDownload = [urlToDownload stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
            NSURL  *url = [NSURL URLWithString:urlToDownload];
            NSData *urlData = [NSData dataWithContentsOfURL:url];
            if (urlData)
            {
                NSString  *maskfilePath = [NSString    stringWithFormat:@"%@/watermark", eventPath];
                [urlData writeToFile:maskfilePath atomically:YES];
            }
        }
        
        
        downloadedImageCount = 0;
        
       
        
        int count = 0;
        for (NSDictionary *photos in [eventData objectForKey:@"adminBoothEventPicture"])
        {
            count++;
            NSManagedObject *photoLayoutObject = [NSEntityDescription insertNewObjectForEntityForName:@"PhotoLayout"
                                                                               inManagedObjectContext:storage.currentMOC];
            [photoLayoutObject setValue:[NSString stringWithFormat:@"/Events/%@/%@",photos[@"eId"],photos[@"picId"]] forKey:@"background"];
            [photoLayoutObject setValue:[download stringByAppendingString:[photos objectForKey:@"picName"]] forKey:@"backUrl"];
            if (![photos[@"updatedDate"] isKindOfClass:[NSNull class]])
            {
                [photoLayoutObject setValue:photos[@"updatedDate"] forKey:@"updatedDate"];
            }
            
            if (![photos[@"imageMask"] isKindOfClass:[NSNull class]])
            {
                [photoLayoutObject setValue:[NSString stringWithFormat:@"/Events/%@/%@_mask",photos[@"eId"],photos[@"picId"]] forKey:@"foreground"];
                [photoLayoutObject setValue:[download stringByAppendingString:[photos objectForKey:@"imageMask"]] forKey:@"maskImageUrl"];
                
            }
            
            if (![photos[@"defaultId"] isKindOfClass:[NSNull class]])
            {
                [photoLayoutObject setValue:photos[@"defaultId"] forKey:@"defaultId"];
            }
            [photoLayoutObject setValue:[NSNumber numberWithDouble:0.0] forKey:@"bottomCurtain"];
            if (![photos[@"picTitle"] isKindOfClass:[NSNull class]])
                [photoLayoutObject setValue:photos[@"picTitle"] forKey:@"desc"];
            else
                [photoLayoutObject setValue:@"" forKey:@"desc"];
            [photoLayoutObject setValue:photos[@"picId"] forKey:@"order"];
            [photoLayoutObject setValue:photos[@"eId"] forKey:@"eventId"];
            [photoLayoutObject setValue:@"0" forKey:@"isDownload"];
            if (![photos[@"scaleZOffset"] isKindOfClass:[NSNull class]])
                [photoLayoutObject setValue:[NSNumber numberWithDouble:[photos[@"scaleZOffset"] doubleValue]] forKey:@"scale"];
            else
                [photoLayoutObject setValue:[NSNumber numberWithDouble:1.0] forKey:@"scale"];
            
            [self.eventTable layoutIfNeeded];
            [photoLayoutObject setValue:[self getXOffsetInRatio:photos] forKey:@"xOffset"];
            [photoLayoutObject setValue:[self getYOffsetInRatio:photos] forKey:@"yOffset"];
            [photoLayoutObject setValue:[self getWidthInRatio:photos] forKey:@"cameraWidth"];
            [photoLayoutObject setValue:[self getHeightInRatio:photos] forKey:@"cameraHieght"];
            
            
//            [photoLayoutObject setValue:photos[@"imageHeight"] forKey:@"imageHeight"];
//            [photoLayoutObject setValue:photos[@"imageWidth"] forKey:@"imageWidth"];
            
            NSString *imgHeig=photos[@"imageHeight"];
            NSString *imgWid=photos[@"imageWidth"];
            
            [imgWidthCheck addObject:imgWid];
             [imgHeightCheck addObject:imgHeig];
            NSLog(@"img hei array values are %@",imgHeightCheck);
            
            
            CTAppDelegate *appDel = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
            //                        appDel.sharedArray = [offsetx valueForKey:@"scaleXOffset"];
          //  appDel.sharedArray = imgHeightCheck;
            
            
             NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:photos[@"imageHeight"] forKey:@"imageHeight"];
            [defaults setObject:photos[@"imageWidth"] forKey:@"imageWidth"];
            
            
            [defaults setObject:imgHeightCheck forKey:@"imgHeightCheck"];
             [defaults setObject:imgWidthCheck forKey:@"imgWidthCheck"];
            
            NSString * deviceModePref = [defaults stringForKey:@"imageWidth"];
            NSLog(@"device Width is %@",deviceModePref);
            
            
          //  [photoLayoutObject setValue:photos[@"imageHeight"] forKey:@"imageHeight"];
            
            NSError *error1;
            if (![storage.currentMOC save:&error1]) {
                NSLog(@"Failed to save - error: %@", [error1 localizedDescription]);
            }
        
            NSString *urlToDownload = [download stringByAppendingString:[photos objectForKey:@"picName"]];
            urlToDownload = [urlToDownload stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
            
            NSURL  *url = [NSURL URLWithString:urlToDownload];
            NSData *urlData = [NSData dataWithContentsOfURL:url];
            downloadedImageCount++;
            if ( urlData )
            {
                NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString  *documentsDirectory = [paths lastObject];
                
                NSString * eventfolderPath = [documentsDirectory stringByAppendingPathComponent:@"/Events"];
                
                NSError * error;
                if (![[NSFileManager defaultManager] fileExistsAtPath:eventfolderPath])
                {
                    [[NSFileManager defaultManager] createDirectoryAtPath:eventfolderPath withIntermediateDirectories:YES attributes:nil error:&error];
                }
                
                NSString  *eventPath = [eventfolderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",photos[@"eId"]]];
                if (![[NSFileManager defaultManager] fileExistsAtPath:eventPath])
                {
                    [[NSFileManager defaultManager] createDirectoryAtPath:eventPath withIntermediateDirectories:YES attributes:nil error:&error];
                }
                NSString  *filePath = [NSString stringWithFormat:@"%@/%@", eventPath,[NSString stringWithFormat:@"%@",photos[@"picId"]]];
                [urlData writeToFile:filePath atomically:YES];
                
                [self updateDownloadStatusOfPhoto:photos isBackGround:YES];
                
                if (count == [[eventData objectForKey:@"adminBoothEventPicture"] count])
                {
                    NSError *error;
                    if (![storage.currentMOC save:&error]) {
                        NSLog(@"Failed to save - error: %@", [error localizedDescription]);
                    }
                }
                
                
                if (![photos[@"imageMask"] isKindOfClass:[NSNull class]])
                {
                    NSString *urlToDownload = [download stringByAppendingString:[photos objectForKey:@"imageMask"]];
                    urlToDownload = [urlToDownload stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
                    NSURL  *url = [NSURL URLWithString:urlToDownload];
                    NSData *urlData = [NSData dataWithContentsOfURL:url];
                    if (urlData) {
                        NSString  *maskfilePath = [NSString stringWithFormat:@"%@/%@", eventPath,[NSString stringWithFormat:@"%@_mask",photos[@"picId"]]];
                        [urlData writeToFile:maskfilePath atomically:YES];
                        [self updateDownloadStatusOfPhoto:photos isBackGround:NO];
                        if (count == [[eventData objectForKey:@"adminBoothEventPicture"] count])
                        {
                            NSError *error;
                            if (![storage.currentMOC save:&error]) {
                                NSLog(@"Failed to save - error: %@", [error localizedDescription]);
                            }
                        }
                    }
                        else
                        {
                            [self updateForegroundStatus:photos];
                        }
                    }
                        NSLog(@"File Saved !");
                        if (downloadedImageCount == [[eventData objectForKey:@"adminBoothEventPicture"] count])
                        {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hide:YES];
            [self.eventTable reloadData];
            NSLog(@"images downloaded");
            //    [self updateDownloadStatusOfEvent:photos[@"eId"]];
            [[[UIApplication sharedApplication] keyWindow] setUserInteractionEnabled:YES];
            
            
            //-----
            
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:storage.currentMOC];
            [request setEntity:entity];
            [request setReturnsObjectsAsFaults:NO];
            [request setPredicate:[NSPredicate predicateWithFormat:@"eventId == %@", eventArray[sender.tag][@"eid"]]];
            NSError *errorFetch = nil;
            NSArray *array = [storage.currentMOC executeFetchRequest:request error:&errorFetch];
                  if (array.count) {
            [kiosk setEventId:eventArray[sender.tag][@"eid"]];
            [kiosk startup:eventArray[sender.tag][@"eid"]];
            [kiosk setIsSubscribed:[eventArray[sender.tag][@"isSubscribed"] boolValue]];
                      
                      [kiosk setIsPhone:[eventArray[sender.tag][@"isPhone"] boolValue]];
                      [kiosk setIsName:[eventArray[sender.tag][@"isName"] boolValue]];
             
                      
                      
                      
//                      [kiosk setIsName:1];
//                      [kiosk setIsPhone:1];
                      
                      
                      
                      [self autoConfigureCameraAndTouchDevice];
                      
        
            
            UIViewController *viewController;
            NSUserDefaults * userdefault = [NSUserDefaults standardUserDefaults];
            NSString * deviceModePref = [userdefault stringForKey:AMDeviceModeSettingsKey];
            
            if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
            {
                viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"CTKioskViewController"];
            }
            else
            {
                viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"selectSceneViewController"];
                
                
            }
            [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
            [self.navigationController pushViewController:viewController animated:YES];
            
            
                 }
            
            
            //-----
            
        });
        
        
        
        }
            }
        }
    });
   
        
    
 //   if (downloadedImageCount == [[eventData objectForKey:@"adminBoothEventPicture"] count])
 //   {
    

    }


}




- (IBAction)backBtnAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
    
-(NSString *)checkValueAgainstNull : (NSString *) forKey inDictionary : (NSDictionary *) dict{
    if ([dict[forKey] isKindOfClass:[NSNull class]])
    {
        return @"";
    }
    else return dict[forKey];
}
    

    
- (void)updateEvent:(NSInteger)index
    {
        
        
        // save event in database
        NSDictionary *eventData = [eventArray objectAtIndex:index];
        if ([[eventData objectForKey:@"adminBoothEventPicture"] count] == 0) {
            [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"No backgrounds in this event to download" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            return;
        }
        NSManagedObject *eventObject = [NSEntityDescription insertNewObjectForEntityForName:@"Event"
                                                                     inManagedObjectContext:storage.currentMOC];
        [eventObject setValue:[self checkValueAgainstNull:@"createdDate" inDictionary:eventData] forKey:@"createdDate"];
        [eventObject setValue:[self checkValueAgainstNull:@"eid" inDictionary:eventData] forKey:@"eventId"];
        [eventObject setValue:[self checkValueAgainstNull:@"eventLocation" inDictionary:eventData] forKey:@"eventLocation"];
        [eventObject setValue:[self checkValueAgainstNull:@"eventName" inDictionary:eventData] forKey:@"eventName"];
        [eventObject setValue:[self checkValueAgainstNull:@"eventStart" inDictionary:eventData] forKey:@"eventStart"];
        [eventObject setValue:[self checkValueAgainstNull:@"updatedDate" inDictionary:eventData] forKey:@"updatedDate"];
        [eventObject setValue:[eventData objectForKey:@"isSubscribed"] forKey:@"isSubscribed"];
        
//        [eventObject setValue:[eventData objectForKey:@"isPhone"] forKey:@"isPhone"];
//        [eventObject setValue:[eventData objectForKey:@"isName"] forKey:@"isName"];
        
        NSString *pin =[eventData objectForKey:@"pin"];
        
        
        
        
//        [eventObject setValue:@"0" forKey:@"isPhone"];
//        [eventObject setValue:@"0" forKey:@"isName"];
        
        //[eventObject setValue:@"0" forKey:@"isDownload"];
        
        if (![eventData[@"fovLeft"] isKindOfClass:[NSNull class]])
        {
            [eventObject setValue:eventData[@"fovLeft"] forKey:@"fovLeft"];
            [eventObject setValue:eventData[@"fovRight"] forKey:@"fovRight"];
            [eventObject setValue:eventData[@"fovTop"] forKey:@"fovTop"];
            [eventObject setValue:eventData[@"fovBottom"] forKey:@"fovBottom"];
            //        [eventObject setValue:eventData[@"greenScreenCountdownDelay"] forKey:@"greenScreenCountdownDelay"];
            //        [eventObject setValue:eventData[@"greenScreenDistance"] forKey:@"greenScreenDistance"];
            //        [eventObject setValue:eventData[@"greenScreenHeight"] forKey:@"greenScreenHeight"];
            //        [eventObject setValue:eventData[@"greenScreenWidth"] forKey:@"greenScreenWidth"];
            //        [eventObject setValue:eventData[@"otherCountdownDelay"] forKey:@"otherCountdownDelay"];
            //        [eventObject setValue:eventData[@"otherIntractionTimout"] forKey:@"otherIntractionTimout"];
        }
        if (![eventData[@"cameraTVScreenSaver"] isKindOfClass:[NSNull class]])
        {
            [eventObject setValue:[NSString stringWithFormat:@"/Events/%@/camera",eventData[@"eid"]] forKey:@"cameraImage"];
        }
        if (![eventData[@"waterMarkImage"] isKindOfClass:[NSNull class]])
        {
            [eventObject setValue:[NSString stringWithFormat:@"/Events/%@/watermark",eventData[@"eid"]] forKey:@"watermarkImage"];
            [eventObject setValue:[baseurl stringByAppendingString:[eventData objectForKey:@"waterMarkImage"]] forKey:@"watermarkImageUrl"];
        }
        if (![eventData[@"lookAtTouchScreen"] isKindOfClass:[NSNull class]])
        {
            [eventObject setValue:[NSString stringWithFormat:@"/Events/%@/lookat",eventData[@"eid"]] forKey:@"lookatTouchImage"];
        }
        if (![eventData[@"thankYouScreen"] isKindOfClass:[NSNull class]])
        {
            [eventObject setValue:[NSString stringWithFormat:@"/Events/%@/thankyou",eventData[@"eid"]] forKey:@"thankyouImage"];
        }
        NSError *error;
        if (![storage.currentMOC save:&error]) {
            NSLog(@"Failed to save - error: %@", [error localizedDescription]);
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"Downloading Started");
            
            NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString  *documentsDirectory = [paths lastObject];
            
            NSString * eventfolderPath = [documentsDirectory stringByAppendingPathComponent:@"/Events"];
            
            NSError * error;
            if (![[NSFileManager defaultManager] fileExistsAtPath:eventfolderPath])
            {
                [[NSFileManager defaultManager] createDirectoryAtPath:eventfolderPath withIntermediateDirectories:YES attributes:nil error:&error];
            }
            
            NSString  *eventPath = [eventfolderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",eventData[@"eid"]]];
            if (![[NSFileManager defaultManager] fileExistsAtPath:eventPath])
            {
                [[NSFileManager defaultManager] createDirectoryAtPath:eventPath withIntermediateDirectories:YES attributes:nil error:&error];
            }
            
            if (![eventData[@"cameraTVScreenSaver"] isKindOfClass:[NSNull class]])
            {
                NSString *urlToDownload = [baseurl stringByAppendingString:[eventData objectForKey:@"cameraTVScreenSaver"]];
                urlToDownload = [urlToDownload stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
                NSURL  *url = [NSURL URLWithString:urlToDownload];
                NSData *urlData = [NSData dataWithContentsOfURL:url];
                if (urlData) {
                    
                    NSString  *maskfilePath = [NSString stringWithFormat:@"%@/camera", eventPath];
                    [urlData writeToFile:maskfilePath atomically:YES];
                }
            }
            if (![eventData[@"thankYouScreen"] isKindOfClass:[NSNull class]])
            {
                NSString *urlToDownload = [baseurl stringByAppendingString:[eventData objectForKey:@"thankYouScreen"]];
                urlToDownload = [urlToDownload stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
                NSURL  *url = [NSURL URLWithString:urlToDownload];
                NSData *urlData = [NSData dataWithContentsOfURL:url];
                if (urlData)
                {
                    NSString  *maskfilePath = [NSString    stringWithFormat:@"%@/thankyou", eventPath];
                    [urlData writeToFile:maskfilePath atomically:YES];
                }
                
            }
            if (![eventData[@"lookAtTouchScreen"] isKindOfClass:[NSNull class]])
            {
                NSString *urlToDownload = [baseurl stringByAppendingString:[eventData objectForKey:@"lookAtTouchScreen"]];
                urlToDownload = [urlToDownload stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
                NSURL  *url = [NSURL URLWithString:urlToDownload];
                NSData *urlData = [NSData dataWithContentsOfURL:url];
                if (urlData)
                {
                    NSString  *maskfilePath = [NSString    stringWithFormat:@"%@/lookat", eventPath];
                    [urlData writeToFile:maskfilePath atomically:YES];
                }
                
            }
            if (![eventData[@"waterMarkImage"] isKindOfClass:[NSNull class]])
            {
                NSString *urlToDownload = [baseurl stringByAppendingString:[eventData objectForKey:@"waterMarkImage"]];
                urlToDownload = [urlToDownload stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
                NSURL  *url = [NSURL URLWithString:urlToDownload];
                NSData *urlData = [NSData dataWithContentsOfURL:url];
                if (urlData)
                {
                    NSString  *maskfilePath = [NSString    stringWithFormat:@"%@/watermark", eventPath];
                    [urlData writeToFile:maskfilePath atomically:YES];
                }
            }
        });
        
        downloadedImageCount = 0;
        
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.labelText = @"Downloading event";
        [[[UIApplication sharedApplication] keyWindow] setUserInteractionEnabled:NO];
        
        int count = 0;
        for (NSDictionary *photos in [eventData objectForKey:@"adminBoothEventPicture"])
        {
            count++;
            NSManagedObject *photoLayoutObject = [NSEntityDescription insertNewObjectForEntityForName:@"PhotoLayout"
                                                                               inManagedObjectContext:storage.currentMOC];
            [photoLayoutObject setValue:[NSString stringWithFormat:@"/Events/%@/%@",photos[@"eId"],photos[@"picId"]] forKey:@"background"];
            [photoLayoutObject setValue:[baseurl stringByAppendingString:[photos objectForKey:@"picName"]] forKey:@"backUrl"];
            if (![photos[@"updatedDate"] isKindOfClass:[NSNull class]])
            {
                [photoLayoutObject setValue:photos[@"updatedDate"] forKey:@"updatedDate"];
            }
            
            if (![photos[@"imageMask"] isKindOfClass:[NSNull class]])
            {
                [photoLayoutObject setValue:[NSString stringWithFormat:@"/Events/%@/%@_mask",photos[@"eId"],photos[@"picId"]] forKey:@"foreground"];
                [photoLayoutObject setValue:[baseurl stringByAppendingString:[photos objectForKey:@"imageMask"]] forKey:@"maskImageUrl"];
                
            }
            
            if (![photos[@"defaultId"] isKindOfClass:[NSNull class]])
            {
                [photoLayoutObject setValue:photos[@"defaultId"] forKey:@"defaultId"];
            }
            [photoLayoutObject setValue:[NSNumber numberWithDouble:0.0] forKey:@"bottomCurtain"];
            if (![photos[@"picTitle"] isKindOfClass:[NSNull class]])
            [photoLayoutObject setValue:photos[@"picTitle"] forKey:@"desc"];
            else
            [photoLayoutObject setValue:@"" forKey:@"desc"];
            [photoLayoutObject setValue:photos[@"picId"] forKey:@"order"];
            [photoLayoutObject setValue:photos[@"eId"] forKey:@"eventId"];
            [photoLayoutObject setValue:@"0" forKey:@"isDownload"];
            if (![photos[@"scaleZOffset"] isKindOfClass:[NSNull class]])
            [photoLayoutObject setValue:[NSNumber numberWithDouble:[photos[@"scaleZOffset"] doubleValue]] forKey:@"scale"];
            else
            [photoLayoutObject setValue:[NSNumber numberWithDouble:1.0] forKey:@"scale"];
            
            [self.eventTable layoutIfNeeded];
            [photoLayoutObject setValue:[self getXOffsetInRatio:photos] forKey:@"xOffset"];
            [photoLayoutObject setValue:[self getYOffsetInRatio:photos] forKey:@"yOffset"];
            [photoLayoutObject setValue:[self getWidthInRatio:photos] forKey:@"cameraWidth"];
            [photoLayoutObject setValue:[self getHeightInRatio:photos] forKey:@"cameraHieght"];
            
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:photos[@"imageHeight"] forKey:@"imageHeight"];
            [defaults setObject:photos[@"imageWidth"] forKey:@"imageWidth"];
            
       //     [photoLayoutObject setValue:photos[@"imageHeight"] forKey:@"imageHeight"];
            
            
            NSError *error1;
            if (![storage.currentMOC save:&error1]) {
                NSLog(@"Failed to save - error: %@", [error1 localizedDescription]);
            }
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSLog(@"Downloading Started");
                NSString *urlToDownload = [baseurl stringByAppendingString:[photos objectForKey:@"picName"]];
                urlToDownload = [urlToDownload stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
                
                NSURL  *url = [NSURL URLWithString:urlToDownload];
                NSData *urlData = [NSData dataWithContentsOfURL:url];
                downloadedImageCount++;
                if ( urlData )
                {
                    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                    NSString  *documentsDirectory = [paths lastObject];
                    
                    NSString * eventfolderPath = [documentsDirectory stringByAppendingPathComponent:@"/Events"];
                    
                    NSError * error;
                    if (![[NSFileManager defaultManager] fileExistsAtPath:eventfolderPath])
                    {
                        [[NSFileManager defaultManager] createDirectoryAtPath:eventfolderPath withIntermediateDirectories:YES attributes:nil error:&error];
                    }
                    
                    NSString  *eventPath = [eventfolderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",photos[@"eId"]]];
                    if (![[NSFileManager defaultManager] fileExistsAtPath:eventPath])
                    {
                        [[NSFileManager defaultManager] createDirectoryAtPath:eventPath withIntermediateDirectories:YES attributes:nil error:&error];
                    }
                    NSString  *filePath = [NSString stringWithFormat:@"%@/%@", eventPath,[NSString stringWithFormat:@"%@",photos[@"picId"]]];
                    [urlData writeToFile:filePath atomically:YES];
                    
                    [self updateDownloadStatusOfPhoto:photos isBackGround:YES];
                    
                    if (count == [[eventData objectForKey:@"adminBoothEventPicture"] count])
                    {
                        NSError *error;
                        if (![storage.currentMOC save:&error]) {
                            NSLog(@"Failed to save - error: %@", [error localizedDescription]);
                        }
                    }
                    
                    
                    if (![photos[@"imageMask"] isKindOfClass:[NSNull class]])
                    {
                        NSString *urlToDownload = [baseurl stringByAppendingString:[photos objectForKey:@"imageMask"]];
                        urlToDownload = [urlToDownload stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
                        NSURL  *url = [NSURL URLWithString:urlToDownload];
                        NSData *urlData = [NSData dataWithContentsOfURL:url];
                        if (urlData) {
                            NSString  *maskfilePath = [NSString stringWithFormat:@"%@/%@", eventPath,[NSString stringWithFormat:@"%@_mask",photos[@"picId"]]];
                            [urlData writeToFile:maskfilePath atomically:YES];
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                                [self updateDownloadStatusOfPhoto:photos isBackGround:NO];
                                if (count == [[eventData objectForKey:@"adminBoothEventPicture"] count])
                                {
                                    NSError *error;
                                    if (![storage.currentMOC save:&error]) {
                                        NSLog(@"Failed to save - error: %@", [error localizedDescription]);
                                    }
                                }
                            });
                            
                        }
                        else
                        {
                            [self updateForegroundStatus:photos];
                        }
                    }
                    
                    NSLog(@"File Saved !");
                    if (downloadedImageCount == [[eventData objectForKey:@"adminBoothEventPicture"] count]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [hud hide:YES];
                            [self.eventTable reloadData];
                            NSLog(@"images downloaded");
                            [self updateDownloadStatusOfEvent:photos[@"eId"]];
                            [[[UIApplication sharedApplication] keyWindow] setUserInteractionEnabled:YES];
                            UIViewController *vc = [self visibleViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
                            if (![vc isKindOfClass:[EventListViewController class]]) {
                                [kiosk setEventId:eventArray[index][@"eid"]];
                                [kiosk startup:eventArray[index][@"eid"]];
                            }
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateEventNotification" object:nil];
                        });
                    }
                }
                
            });
        }
    }
    
- (UIViewController *)visibleViewController:(UIViewController *)rootViewController
    {
        if (rootViewController.presentedViewController == nil)
        {
            return rootViewController;
        }
        if ([rootViewController.presentedViewController isKindOfClass:[UINavigationController class]])
        {
            UINavigationController *navigationController = (UINavigationController *)rootViewController.presentedViewController;
            UIViewController *lastViewController = [[navigationController viewControllers] lastObject];
            
            return [self visibleViewController:lastViewController];
        }
        
        UIViewController *presentedViewController = (UIViewController *)rootViewController.presentedViewController;
        
        return [self visibleViewController:presentedViewController];
    }
    
- (void)updateForegroundStatus:(id)dict
    {
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"PhotoLayout" inManagedObjectContext:storage.currentMOC];
        [request setEntity:entity];
        if ([dict isKindOfClass:[NSDictionary class]]) {
            [request setPredicate:[NSPredicate predicateWithFormat:@"eventId == %@ && order == %@", dict[@"eId"],dict[@"picId"]]];
        }
        else
        {
            PhotoLayout *photo = (PhotoLayout *)dict;
            [request setPredicate:[NSPredicate predicateWithFormat:@"eventId == %@ && order == %@", photo.eventId,photo.order]];
        }
        [request setReturnsObjectsAsFaults:NO];
        NSError *errorFetch = nil;
        
        
        NSArray *array = [storage.currentMOC executeFetchRequest:request error:&errorFetch];
        if (array.count > 0)
        {
            PhotoLayout *event = [array firstObject];
            [event setValue:@"0" forKey:@"isDownloadMaskImage"];
            [event setValue:@"" forKey:@"foreground"];
            [event setValue:@"" forKey:@"maskImageUrl"];
        }
        NSError *error;
        if (![storage.currentMOC save:&error]) {
            NSLog(@"Failed to save - error: %@", [error localizedDescription]);
        }
    }
    
- (void)updateDownloadStatusOfPhoto:(id)dict isBackGround:(BOOL)isBackGround
    {
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"PhotoLayout" inManagedObjectContext:storage.currentMOC];
        [request setEntity:entity];
        if ([dict isKindOfClass:[NSDictionary class]]) {
            [request setPredicate:[NSPredicate predicateWithFormat:@"eventId == %@ && order == %@", dict[@"eId"],dict[@"picId"]]];
        }
        else
        {
            PhotoLayout *photo = (PhotoLayout *)dict;
            [request setPredicate:[NSPredicate predicateWithFormat:@"eventId == %@ && order == %@", photo.eventId,photo.order]];
        }
        [request setReturnsObjectsAsFaults:NO];
        NSError *errorFetch = nil;
        
        
        NSArray *array = [storage.currentMOC executeFetchRequest:request error:&errorFetch];
        if (array.count > 0)
        {
            PhotoLayout *event = [array firstObject];
            if (isBackGround) {
                [event setValue:@"1" forKey:@"isDownload"];
            }
            else
            {
                [event setValue:@"1" forKey:@"isDownloadMaskImage"];
            }
        }
    }
    
- (void)updateDownloadStatusOfEvent:(NSNumber *)eventId
    {
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:storage.currentMOC];
        [request setEntity:entity];
        [request setPredicate:[NSPredicate predicateWithFormat:@"eventId == %@", eventId]];
        [request setReturnsObjectsAsFaults:NO];
        NSError *errorFetch = nil;
        NSArray *array = [storage.currentMOC executeFetchRequest:request error:&errorFetch];
        if (array.count > 0)
        {
            Event *event = [array firstObject];
            [event setValue:@"1" forKey:@"isDownload"];
            NSError *error;
            if (![storage.currentMOC save:&error]) {
                NSLog(@"Failed to save - error: %@", [error localizedDescription]);
            }
            
        }
    }
    
- (void)lockCancel1:(NSNotification *)notification
    {
        [lockScreen dismissViewControllerAnimated:NO completion:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"OpenSettingSceneNotification" object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"showSettingScreen" object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"lockCancel" object:nil];
        
    }
    
- (void)showSettingScreen1:(NSNotification *)notification
    {
        [lockScreen dismissViewControllerAnimated:NO completion:nil];
        
        [self performSegueWithIdentifier:@"settings" sender:self];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"OpenSettingSceneNotification" object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"showSettingScreen" object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"lockCancel" object:nil];
        
    }
    
- (IBAction)showSetting:(id)sender {
    //    [self goToScreenShotView];
    //    return;
    //  [self performSegueWithIdentifier:@"settings" sender:self];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(showSettingScreen1:)
//                                                 name:@"OpenSettingSceneNotification"
//                                               object:nil];
//
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(showSettingScreen1:)
//                                                 name:@"showSettingScreen"
//                                               object:nil];
//
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(lockCancel1:)
//                                                 name:@"lockCancel"
//                                               object:nil];
//
//    lockScreen = [[ABPadLockScreenViewController alloc] initWithDelegate:nil complexPin:NO];
//    lockScreen.showSetting = YES;
//
//
//    lockScreen.modalPresentationStyle = UIModalPresentationFullScreen;
//    [lockScreen cancelButtonDisabled:NO];
//    lockScreen.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
//
//    [self presentViewController:lockScreen animated:YES completion:nil];
    
    
    
    [self performSegueWithIdentifier:@"settings" sender:self];
    
    
}
    
    
- (void)goToScreenShotView
    {
        UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:[NSBundle mainBundle]];
        UIViewController *screenShotView = [storyboard instantiateViewControllerWithIdentifier:@"ScreenShot_iPhone"];
        
        CTAppDelegate *appDelegate = (CTAppDelegate *)[[UIApplication sharedApplication]delegate];
        [appDelegate.window.rootViewController presentViewController:screenShotView animated:YES completion:nil];
    }
    
    
- (NSNumber *)getWidthInRatio:(NSDictionary *)photoLayout
    {
        CGFloat value;
        if (self.view.frame.size.width > self.view.frame.size.height) {
            value = self.view.frame.size.width;
        }
        else
        {
            value = self.view.frame.size.height;
        }
        if ([photoLayout[@"scalingWidth"] isKindOfClass:[NSNull class]])
        {
            return [NSNumber numberWithDouble:value];
        }
        double xOffset = [photoLayout[@"scalingWidth"] doubleValue];
        int width = [photoLayout[@"imageWidth"] intValue];
        
        if(width==0)
        {
            width=2732;
        }
        
        double per = (xOffset * value)/width;
        return [NSNumber numberWithDouble:per];
    }
    
- (NSNumber *)getHeightInRatio:(NSDictionary *)photoLayout
    {
        CGFloat value = 0.0;
        if (self.view.frame.size.width < self.view.frame.size.height) {
            value = self.view.frame.size.width;
        }
        else
        {
            value = self.view.frame.size.height;
        }
        if ([photoLayout[@"scalingHeight"] isKindOfClass:[NSNull class]])
        {
            return [NSNumber numberWithDouble:value];
        }
        int width = [photoLayout[@"imageHeight"] intValue];
        double xOffset = [photoLayout[@"scalingHeight"] doubleValue];
        
        double per = (xOffset * value)/width;
        return [NSNumber numberWithDouble:per];
    }
    
- (NSNumber *)getXOffsetInRatio:(NSDictionary *)photoLayout
    {
        if ([photoLayout[@"scaleXOffset"] isKindOfClass:[NSNull class]])
        {
            return 0;
        }
        double xOffset = [photoLayout[@"scaleXOffset"] doubleValue];
        int width = [photoLayout[@"imageWidth"] intValue];
        CGFloat value = 0.0;
        if (self.view.frame.size.width > self.view.frame.size.height) {
            value = self.view.frame.size.width;
        }
        else
        {
            value = self.view.frame.size.height;
        }
        double per = (xOffset * value)/width;
        return [NSNumber numberWithDouble:per];
    }
    
- (NSNumber *)getYOffsetInRatio:(NSDictionary *)photoLayout
    {
        if ([photoLayout[@"scaleYOffset"] isKindOfClass:[NSNull class]])
        {
            return 0;
        }
        double yOffset = [photoLayout[@"scaleYOffset"] doubleValue];
        int width = [photoLayout[@"imageHeight"] intValue];
        CGFloat value = 0.0;
        if (self.view.frame.size.width < self.view.frame.size.height) {
            value = self.view.frame.size.width;
        }
        else
        {
            value = self.view.frame.size.height;
        }
        
        double per = (yOffset * value)/width;
        return [NSNumber numberWithDouble:per];
    }
    
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)logoutTouched:(id)sender {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"iAmuse" message:@"Are you sure you want to logout?" delegate:self cancelButtonTitle:@"Yes"otherButtonTitles:@"No", nil];
    [alert show];
    
//    [self goToScreenShotView];
    
    
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        NSString * testing = [defaults stringForKey:@"googleSignIn"];
        if ([testing isEqualToString:@"yes"])
        {
           [[GIDSignIn sharedInstance] signOut];
            [defaults setObject:@"no" forKey:@"googleSignIn"];
            [self cleanUp];
            [self logoutServiceCall];
        }
        else{
        [self cleanUp];
        [self logoutServiceCall];
        }
    }
}

- (void)cleanUp
{
    //Clear from document directory.
    NSString * path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    path = [path stringByAppendingPathComponent:@"Photos"];
    NSFileManager *fileMgr = [[NSFileManager alloc] init];
    
    
    NSArray *files = [fileMgr contentsOfDirectoryAtPath:path error:nil];
    NSError *error = nil;
    
    while (files.count > 0) {
        NSArray *directoryContents = [fileMgr contentsOfDirectoryAtPath:path error:&error];
        if (error == nil) {
            for (NSString *path1 in directoryContents)
            {
                NSString *fullPath = [path stringByAppendingPathComponent:path1];
                BOOL removeSuccess = [fileMgr removeItemAtPath:fullPath error:&error];
                files = [fileMgr contentsOfDirectoryAtPath:path error:nil];
                if (!removeSuccess)
                {
                    // Error
                }
            }
        } else {
            // Error
        }
    }
    
    NSString * eventpath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    eventpath = [eventpath stringByAppendingPathComponent:@"Events"];
    NSFileManager *fileMgr1 = [[NSFileManager alloc] init];
    
    
    NSArray *files1 = [fileMgr1 contentsOfDirectoryAtPath:eventpath error:nil];
    NSError *error1 = nil;
    
    while (files1.count > 0) {
        NSArray *directoryContents = [fileMgr1 contentsOfDirectoryAtPath:eventpath error:&error1];
        if (error1 == nil) {
            for (NSString *path1 in directoryContents)
            {
                NSString *fullPath = [eventpath stringByAppendingPathComponent:path1];
                BOOL removeSuccess = [fileMgr1 removeItemAtPath:fullPath error:&error1];
                files1 = [fileMgr1 contentsOfDirectoryAtPath:eventpath error:nil];
                if (!removeSuccess)
                {
                    // Error
                }
            }
        } else {
            // Error
        }
    }
    
    //Clear from CoreData
    NSFetchRequest *eventfetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Event"];
    [eventfetchRequest setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSManagedObjectContext *moc = [[AMStorageManager sharedInstance] currentMOC];
    
    NSArray *fetchedObjects = [moc executeFetchRequest:eventfetchRequest error:&error];
    for (NSManagedObject *object in fetchedObjects)
    {
        [moc deleteObject:object];
    }
    error = nil;
    [moc save:&error];
    
    NSFetchRequest *photofetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"PhotoLayout"];
    [photofetchRequest setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSManagedObjectContext *moc1 = [[AMStorageManager sharedInstance] currentMOC];
    
    NSArray *fetchedObjects1 = [moc1 executeFetchRequest:photofetchRequest error:&error];
    for (NSManagedObject *object in fetchedObjects1)
    {
        [moc1 deleteObject:object];
    }
    error = nil;
    [moc1 save:&error];
    
}


- (void)logoutServiceCall
{
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",
                                        kAMBaseURL, @"logOut"]];
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * deviceModePref = [defaults stringForKey:AMDeviceModeSettingsKey];
    if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
    {
        [dict setObject:@"Camera device" forKey:@"deviceType"];
    }
    else
    {
        [dict setObject:@"Guest Touchscreen" forKey:@"deviceType"];
    }
    [dict setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"userId"] forKey:@"userId"];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    WebCommunication * webComm = [WebCommunication new];
    [webComm callToServerRequestDictionary:dict onURL:url WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm)
	     {
         [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
         NSLog(@"response : %@",response);
         
         if([[response objectForKey:@"responseDescription"] isEqualToString:@"Success"])
         {
             if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
             {
                 
                 
                 [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isLogin"];
                 [[NSUserDefaults standardUserDefaults] synchronize];
                 [self.navigationController popViewControllerAnimated:YES];
                 [self setRootViewController];
                 
                 
                 
//                 [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isLogin"];
//                 [[NSUserDefaults standardUserDefaults] synchronize];
//
//                 [self dismissViewControllerAnimated:YES completion: ^{
//                     [self setRootViewController];
//                 }];
             }
             else
             {
                 
                 
                 
                 
                 
                 
                 [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isLogin"];
                 [[NSUserDefaults standardUserDefaults] synchronize];
                 
         //        SignInViewController *next = [self.storyboard instantiateViewControllerWithIdentifier:@"SignInViewController"];
                 
        //         [self presentViewController:next animated:YES completion:nil];
                 
           //      [self dismissViewControllerAnimated:YES completion:nil];
                 
                [self.navigationController pushViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"SignInViewController"] animated:YES];
                 
            //     [self.navigationController popViewControllerAnimated:YES];
           //      [self setRootViewController];
             }
         }
         else
         {
             
         }
	     }];
    
}

- (void)setRootViewController
{
    UIStoryboard *storyboard;
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * deviceModePref = [defaults stringForKey:AMDeviceModeSettingsKey];
    CTAppDelegate *delegate = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
    // show the storyboard
    UIViewController *rootViewController = [storyboard instantiateInitialViewController];
    if (0)
    {
        delegate.window.rootViewController = rootViewController;
    }
    else
    {
        if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
        {
            //  if((UI_USER_INTERFACE_IDIOM()) == UIUserInterfaceIdiomPhone)

            storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];

            if([[NSUserDefaults standardUserDefaults] boolForKey:@"isLogin"])
            {
                rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"EventListViewController"];
            }
            else
            {
                rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"SignInViewController"];
            }
            UINavigationController *navCont = [[UINavigationController alloc] initWithRootViewController:rootViewController];
            delegate.window.rootViewController = navCont;

        }
        else
        {
            if((UI_USER_INTERFACE_IDIOM()) == UIUserInterfaceIdiomPhone)
            {
                storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhoneTouch" bundle:nil];
            }
            else
            {
                storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
            }
            rootViewController = [storyboard instantiateInitialViewController];

            delegate.window.rootViewController = rootViewController;
            // [self getSubscriptionDetail];
        }
    }
}




- (IBAction)swapTouched:(id)sender {
    
    
 //   [self autoConfigureCameraAndTouchDevice];
    
    
//    if (self.navigationController) {
//        NSArray *viewControllers = self.navigationController.viewControllers;
//        for (UIViewController *anVC in viewControllers) {
//            if ([anVC isKindOfClass:[InitialViewController class] ]){
//                [self.navigationController popToViewController:anVC animated:NO];
//                break;
//            }
//        }
//    }
    
    UIViewController *viewController;
    viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"InitialViewController"];
    [self.navigationController pushViewController:viewController animated:YES];
    
}


- (void)autoConfigureCameraAndTouchDevice
{
    SCTableViewController *app;
    
    CTAppDelegate *delegate = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
    
   // MBProgressHUD * hud = [MBProgressHUD showHUDAddedTo:delegate.window animated:YES];
    WebCommunication *webComm = [[WebCommunication alloc] initWithServiceType:1];
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"userId"] forKey:@"userId"];
    NSURL *serviceUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/getIP",kAMBaseURL]];
    
    
    
    [webComm callToServerRequestDictionary:dic onURL:serviceUrl WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm) {
        [MBProgressHUD hideHUDForView:delegate.window animated:YES];
        if (!error)
        {
            
            if ([[response objectForKey:CAMERA_IP_KEY]  isKindOfClass:[NSNull class]])
            {
                [self autoConfigureCameraAndTouchDevice];
            }
            
        else
        {
            
            
            NSLog(@"%ld, %@",(long)status_code,response);
            if ([[response objectForKey:@"responseCode"] integerValue] != 1)
            {
                [[[UIAlertView alloc] initWithTitle:@"Alert" message:[response objectForKey:@"responseDescription"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                
            }
            else
            {
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                
                NSString * deviceModePref = [defaults stringForKey:AMDeviceModeSettingsKey];
                
                NSLog(@"the autoconfigure %@ ",response);
                
                NSString *cameraIP = [response valueForKey:@"cameraIP"];
                NSString *touchIP = [response valueForKey:@"touchIP"];
                
                [defaults setObject:cameraIP forKey:@"cameraIP"];
                [defaults setObject:touchIP forKey:@"touchIP"];
                
                [defaults setObject:cameraIP forKey:CAMERA_IP_KEY];
                [defaults setObject:touchIP forKey:TOUCHSCREEN_IP_KEY];
                
                
                
                NSString *saveCamera =[defaults stringForKey:@"SaveCameraIP"];
                                            NSString *saveTouch =[defaults stringForKey:@"SaveTouchIP"];
                                            
                                            if(cameraIP==nil || [cameraIP isEqualToString:@""])
                                            {
                                            
                                            [defaults setObject:saveCamera forKey:CAMERA_IP_KEY];
                                            }
                                            
                                            else if (touchIP==nil || [touchIP isEqualToString:@""])
                                            {
                                            [defaults setObject:saveTouch forKey:TOUCHSCREEN_IP_KEY];
                                            }
                
                
                
                //                if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
                //                {
                //                    [defaults setObject:cameraIP forKey:CAMERA_IP_KEY];
                //                }
                //                else
                //                {
                //                    [defaults setObject:touchIP forKey:TOUCHSCREEN_IP_KEY];
                //                }
                [defaults synchronize];
                [app.tableViewModel reloadBoundValues];
                CTKiosk *kiosk = [CTKiosk sharedInstance];
                [kiosk startServer];
            }
        }
        }
    }];
}




- (IBAction)gotoTouchScreen:(id)sender {
    
     NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    
     [defaults setObject:AMDeviceModeStrTouchScreen forKey:AMDeviceModeSettingsKey];
    
    [defaults synchronize];
    
    [self setRootController];
    
    
    CTKiosk *kiosk = [CTKiosk sharedInstance];
    [kiosk startServer];
    
    
//    NSString *camip=[defaults valueForKey:CAMERA_IP_KEY];
//     NSString *touip=[defaults valueForKey:TOUCHSCREEN_IP_KEY];
//
//    [defaults setObject:camip forKey:TOUCHSCREEN_IP_KEY];
//    [defaults setObject:AMDeviceModeStrTouchScreen forKey:AMDeviceModeSettingsKey];
//    kiosk = [CTKiosk sharedInstance];
//   // [kiosk checkPendingImageForUploading:YES];
//    [kiosk registerDeviceOnServer];
//   // [defaults setObject:touchIP forKey:TOUCHSCREEN_IP_KEY];
    
    
    
}

- (IBAction)gotoCameraMode:(id)sender {
    
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:AMDeviceModeStrCamera forKey:AMDeviceModeSettingsKey];
    
    [defaults synchronize];
    
    [self setRootController];
    
    
    CTKiosk *kiosk = [CTKiosk sharedInstance];
    [kiosk startServer];
    
//    NSString *camip=[defaults valueForKey:CAMERA_IP_KEY];
//    NSString *touip=[defaults valueForKey:TOUCHSCREEN_IP_KEY];
//
//
//    //[defaults setObject:cameraIP forKey:CAMERA_IP_KEY];
//    [defaults setObject:touip forKey:CAMERA_IP_KEY];
//
//    [defaults setObject:AMDeviceModeStrCamera forKey:AMDeviceModeSettingsKey];
//    kiosk = [CTKiosk sharedInstance];
//    //[kiosk checkPendingImageForUploading:YES];
 //   [kiosk registerDeviceOnServer];

    
    
    
}


- (void)setRootController
{
    UIStoryboard *storyboard;
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * deviceModePref = [defaults stringForKey:AMDeviceModeSettingsKey];
    CTAppDelegate *delegate = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
    // show the storyboard
    UIViewController *rootViewController = [storyboard instantiateInitialViewController];
    if (0)
    {
        delegate.window.rootViewController = rootViewController;
    }
    else
    {
        if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
        {
            //  if((UI_USER_INTERFACE_IDIOM()) == UIUserInterfaceIdiomPhone)
            
            storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
            
            if([[NSUserDefaults standardUserDefaults] boolForKey:@"isLogin"])
            {
                rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"EventListViewController"];
            }
            else
            {
                rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"SignInViewController"];
            }
            UINavigationController *navCont = [[UINavigationController alloc] initWithRootViewController:rootViewController];
            delegate.window.rootViewController = navCont;
            
        }
        else
        {
            if((UI_USER_INTERFACE_IDIOM()) == UIUserInterfaceIdiomPhone)
            {
                storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhoneTouch" bundle:nil];
            }
            else
            {
                
                storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
            }
            rootViewController = [storyboard instantiateInitialViewController];
            
            delegate.window.rootViewController = rootViewController;
            // [self getSubscriptionDetail];
        }
    }
}



-(void)manuallyDeleteEventsAfterEventUpdate

{
    
    
    isUpdatingEvents = YES;
 //   hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
 //   hud.mode = MBProgressHUDModeIndeterminate;
 //   hud.labelText = @"updating event";
 //   updateStr=@"updated";
    [self getSubscriptionDetail];
    
 //   [self performSelector:@selector(hideloader) withObject:nil afterDelay:5];

    
    
    //[self getSubscriptionDetail];
    
    NSError *error = nil;
    NSString * eventpath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    eventpath = [eventpath stringByAppendingPathComponent:@"Events"];
    NSFileManager *fileMgr1 = [[NSFileManager alloc] init];
    
    
    NSArray *files1 = [fileMgr1 contentsOfDirectoryAtPath:eventpath error:nil];
    NSError *error1 = nil;
    
    while (files1.count > 0) {
        NSArray *directoryContents = [fileMgr1 contentsOfDirectoryAtPath:eventpath error:&error1];
        if (error1 == nil) {
            for (NSString *path1 in directoryContents)
            {
                NSString *fullPath = [eventpath stringByAppendingPathComponent:path1];
                BOOL removeSuccess = [fileMgr1 removeItemAtPath:fullPath error:&error1];
                files1 = [fileMgr1 contentsOfDirectoryAtPath:eventpath error:nil];
                if (!removeSuccess)
                {
                    // Error
                }
            }
        } else {
            // Error
        }
    }
    
    //Clear from CoreData
    NSFetchRequest *eventfetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Event"];
    [eventfetchRequest setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSManagedObjectContext *moc = [[AMStorageManager sharedInstance] currentMOC];
    
    NSArray *fetchedObjects = [moc executeFetchRequest:eventfetchRequest error:&error];
    for (NSManagedObject *object in fetchedObjects)
    {
        [moc deleteObject:object];
    }
    error = nil;
    [moc save:&error];
    
    NSFetchRequest *photofetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"PhotoLayout"];
    [photofetchRequest setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSManagedObjectContext *moc1 = [[AMStorageManager sharedInstance] currentMOC];
    
    NSArray *fetchedObjects1 = [moc1 executeFetchRequest:photofetchRequest error:&error];
    for (NSManagedObject *object in fetchedObjects1)
    {
        [moc1 deleteObject:object];
    }
    error = nil;
    [moc1 save:&error];
    
    
    
    
    
    
    
    
    
    
    
    
    
    NSIndexPath *indexPath;
    EventTableViewCell *cell;
    [cell.downloadBtn setHidden:NO];
    [cell.downloadBtn setTag:indexPath.section];
    [cell.downloadBtn addTarget:self action:@selector(downloadBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    

    
}


- (void)SubscriptionUpdate
{
    WebCommunication *webComm = [[WebCommunication alloc] initWithServiceType:1];
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"userId"] forKey:@"userId"];
    NSURL *serviceUrl = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/subscriptionsList",kAMBaseURL]];
    [webComm callToServerRequestDictionary:dic onURL:serviceUrl WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm) {
        [hud hide:YES];
        if (!error)
        {
            NSLog(@"%ld, %@",(long)status_code,response);
            
            if ([response[@"subId"] isKindOfClass:[NSNull class]])
            {
                // [self getSubscriptionDetail];
                [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Something went wrong" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            }
            else
            {
                if ([[response objectForKey:@"responseCode"] integerValue] != 1)
                {
                    [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Something went wrong" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                    
                }
                else
                {
                    if (![response[@"subId"] isKindOfClass:[NSNull class]])
                    {
                        self.subscriptionId = response[@"subId"];
                        
                        
                        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
                        [defaults setObject:self.subscriptionId forKey:@"subscriptionType"];
                        
                        
                    }
                    else
                    {
                        self.subscriptionId = @"";
                    }
                  //  [self getAllEvents];
                 //   [self getFOV];
                }
            }
        }
        else
        {
            //  [[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Something went wrong" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            
            NSLog(@"%@",error);
        }
        
    }];
    
}



@end

