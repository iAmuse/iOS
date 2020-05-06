//
//  CTSettingsViewController.m
//  Jurassic
//
//  Created by Roland Hordos on 2013-05-25.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import "CTSettingsViewController.h"
#import "CTAppDelegate.h"
#import "AMConstants.h"
#import "CTKioskViewController.h"
#import "AMUtility.h"
#import "PurchaseViewController.h"
#import "PrivacyPolicyViewController.h"
#import "WebCommunication.h"
#import "ViewController.h"
// for IP address
#include <ifaddrs.h>
#include <arpa/inet.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import "AMStorageManager.h"

@interface CTSettingsViewController ()

@end

@implementation CTSettingsViewController

- (void)viewDidLoad
{
    [self.navigationController setNavigationBarHidden: NO animated:YES];

    [super viewDidLoad];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configureDeviceNotification:) name:@"AutoConfigureDeviceNotification" object:nil];
  //  [[[UIAlertView alloc] initWithTitle:@"iAmuse" message:@"Here you can configure camera and touch devices" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    //UIStoryboard * storyboard = self.storyboard;
   // NSString * storyboardName = [storyboard valueForKey:@"name"];
    
    NSUserDefaults * usdefault = [NSUserDefaults standardUserDefaults];
    NSString * deviceModePref1 = [usdefault stringForKey:AMDeviceModeSettingsKey];
    if ([deviceModePref1 isEqualToString:AMDeviceModeStrCamera])
    {
        [self setDefaultsForIPhoneSettings];
    }
    else if([deviceModePref1 isEqualToString:AMDeviceModeStrTouchScreen])
    {
        [self setDefaultsForIPadSettings];
    }
    else
    {
        [self setDefaultsForPrintSettings];
    }
//    if ([storyboardName isEqualToString:@"MainStoryboard_iPhone"])
//    {
//        [self setDefaultsForIPhoneSettings];
//
//    }
//    else if ([storyboardName isEqualToString:@"MainStoryboard_iPad"])
//    {
//        [self setDefaultsForIPadSettings];
//    }
//    else
//    {
//        [self setDefaultsForPrintSettings];
//    }
}

- (void)configureDeviceNotification:(NSNotification *)notification
{
    [self.tableViewModel reloadBoundValues];
}

- (void)loadConfigurationFromServer
{
    CTAppDelegate *delegate = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
    MBProgressHUD * hud = [MBProgressHUD showHUDAddedTo:delegate.window.rootViewController.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    if(![[NSUserDefaults standardUserDefaults] boolForKey:HAVE_SERVER_RGB_CONFIGURATION])
    {
        hud.labelText = @"Please wait.. Loading configuration from Cloud server.";
    }
    else
    {
        hud.labelText = @"Please wait for loading RGB configuration from server.";
        hud.detailsLabelText = @"Updating RGB values.";
    }
    
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
    [dict setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"userId"] forKey:@"userId"];
    WebCommunication * webComm = [WebCommunication new];
    [webComm callToServerRequestDictionary:dict onURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kAMBaseURL,kAMGetConfigurationURL]] WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm)
     {
         [self performSelector:@selector(hideHUD) withObject:nil afterDelay:2.0];
         
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
                     [[[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"%@",response] delegate:nil cancelButtonTitle:@"ok" otherButtonTitles: nil] show];
                     [self.tableViewModel reloadBoundValues];

                 }
             }
         }
         else
         {
         }
         
     }];
}

- (void)hideHUD
{
    CTAppDelegate *delegate = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
    [MBProgressHUD hideHUDForView:delegate.window.rootViewController.view animated:YES];
}

- (void)setDefaultsForIPhoneSettings
{
    // Use key binding for app version.
    
    
/*    SCLabelCell * privacyCell = [SCLabelCell cellWithText:@"Privacy Policy" boundObject:nil labelTextPropertyName:@"Privacy Policy"];
    
    
    SCTableViewSection * privacySection = [SCTableViewSection sectionWithHeaderTitle:@"Privacy Policy"];
    
    [self.tableViewModel addSection:privacySection];
    [privacySection addCell:privacyCell];
    
    privacySection.cellActions.didSelect = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            PrivacyPolicyViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([PrivacyPolicyViewController class])];
            [controller setIsShowingFromSetting:YES];
            [self.navigationController pushViewController:controller animated:YES];

        });
    };*/
    
    SCLabelCell * configurationCell = [SCLabelCell cellWithText:@"Refresh (Autoconfigure)" boundObject:nil labelTextPropertyName:@"Config Device"];
    
    
    SCTableViewSection * configurationSection = [SCTableViewSection sectionWithHeaderTitle:@"Device Configuration"];
    
    [self.tableViewModel addSection:configurationSection];
    [configurationSection addCell:configurationCell];

    CTKiosk *kiosk = [CTKiosk sharedInstance];
    configurationSection.cellActions.didSelect = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        kiosk.autoConfigureCount = 0;
        [self autoConfigureCameraAndTouchDevice];
    };

    NSUserDefaults * userdefault = [NSUserDefaults standardUserDefaults];
    NSString *mode = [userdefault objectForKey:@"cameraMode"];
    if (mode != nil) {
        mode = [userdefault objectForKey:@"cameraMode"];
    }
    else
    {
        mode = @"Front";
    }
    SCLabelCell * cameraModeCell = [SCLabelCell cellWithText:mode boundObject:nil labelTextPropertyName:mode];
    
    
    SCTableViewSection * cameraModeSection = [SCTableViewSection sectionWithHeaderTitle:@"Camera Mode"];
    
    [self.tableViewModel addSection:cameraModeSection];
    [cameraModeSection addCell:cameraModeCell];
    
    cameraModeSection.cellActions.didSelect = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        if ([cell.textLabel.text isEqualToString:@"Front"]) {
            cell.textLabel.text = @"Rear";
            [userdefault setObject:@"Rear" forKey:@"cameraMode"];
        }
        else
        {
            cell.textLabel.text = @"Front";
            [userdefault setObject:@"Front" forKey:@"cameraMode"];
        }
        [userdefault synchronize];
    };
    
    
   
    
    
    
    
    SCLabelCell * previewCell = [SCLabelCell cellWithText:@"Camera Setup" boundObject:nil labelTextPropertyName:@"Camera Setup"];
    
    
    SCTableViewSection * previewSection = [SCTableViewSection sectionWithHeaderTitle:@""];
    
    [self.tableViewModel addSection:previewSection];
    [previewSection addCell:previewCell];
    previewSection.cellActions.didSelect = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        
        UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:[NSBundle mainBundle]];
    ViewController    *cameraView = [storyboard instantiateViewControllerWithIdentifier:@"Camera_GPUImage"];
        
        cameraView.thresholdValue = 0.4f;
        
        [cameraView setIsTestingCamera:YES];
        [self presentViewController:cameraView animated:NO completion:nil];
    };
    
    
    
    
    
    
    
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString * subId = [defaults stringForKey:@"subscriptionType"];
    NSString *type;
    if ([subId integerValue] == 1)
    {
        // [self setBorderForSelectedSubscriptionView:self.freeView];
        type=@"Free Trial";
        
        
    }
    else if ([subId integerValue] == 2)
    {
        type =@"Single Event";
        //  [self setBorderForSelectedSubscriptionView:self.oneDaySubscriptionView];
    }
    else if ([subId integerValue] == 3)
    {
        type =@"Professional pay-as-you-go";
        //  [self.oneMonthSubscribeBtn setTitle:@"Your Current Plan" forState:UIControlStateNormal];
        //     [self setBorderForSelectedSubscriptionView:self.customUploadView];
    }
    else
    {
        type =@"Professional Yearly";
        //     [self setBorderForSelectedSubscriptionView:self.oneMonthSubscriptionView];
    }

    
   
    
    
    
//    SCLabelCell * subCell = [SCLabelCell cellWithText:@"Subscription" boundObject:nil labelTextPropertyName:@"Subscription"];
//
//
//    SCTableViewSection * subSection = [SCTableViewSection sectionWithHeaderTitle:@""];
//
//    [self.tableViewModel addSection:subSection];
//    [subSection addCell:subCell];
//    subSection.cellActions.didSelect = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
//    {
//
//     UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
//
//        PurchaseViewController *eventController = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([PurchaseViewController class])];
//        [self.navigationController pushViewController:eventController animated:YES];
//
//        [self.navigationController setNavigationBarHidden: YES animated:YES];
//    };
    /*
    SCTableViewSection * rgbSection = [SCTableViewSection sectionWithHeaderTitle:@"RGB Values"];
    NSArray *arr = [userdefault objectForKey:SERVER_RGB_CONFIGURATION];
    NSString *str;
    if (arr.count) {
        str = [NSString stringWithFormat:@"%@, %@, %@",arr[0],arr[1],arr[2]];
    }
    SCLabelCell * rgbCell = [SCLabelCell cellWithText:str boundObject:nil labelTextPropertyName:mode];

    [self.tableViewModel addSection:rgbSection];
    [rgbSection addCell:rgbCell];
    
    rgbSection.cellActions.didSelect = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        [self loadConfigurationFromServer];
    };
    
     */
     
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
    NSString * appVersionStr = [AMUtility appVersion];
    
    
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
    
    NSLog(@"build is %@",build);
    
    
    
    
//    [dict setValue:appVersionStr forKey:@"Version"];
//    SCLabelCell * appVersionDef = [SCLabelCell cellWithText:@"App Version" boundObject:appVersionStr labelTextPropertyName:@"Version"];
    
    
    [dict setValue:build forKey:@"Version"];
    SCLabelCell * appVersionDef = [SCLabelCell cellWithText:@"App Version" boundObject:build labelTextPropertyName:@"Version"];
    
    SCTableViewSection * section = [SCTableViewSection sectionWithHeaderTitle:@"Application"];
    
    
    
    [self.tableViewModel addSection:section];
    [section addCell:appVersionDef];
    
    NSString * deviceModePref = [userdefault stringForKey:AMDeviceModeSettingsKey];

    SCLabelCell * deviceModeCell = [SCLabelCell cellWithText:@"Device Mode" boundObject:deviceModePref labelTextPropertyName:@"Device Mode"];
    
    SCTableViewSection * deviceModeSection = [SCTableViewSection sectionWithHeaderTitle:@"Device"];
    [self.tableViewModel addSection:deviceModeSection];
    [deviceModeSection addCell:deviceModeCell];

    
    // Persistent User Defaults with Editor
    NSMutableString * userDefaultsSetupStr = [[NSMutableString alloc] init];
    
    
    // First give it the layout with dictionary keys.
    
    /*
    [userDefaultsSetupStr appendString:[NSString stringWithFormat:@"Account:(%@,%@):from iamuse-kiosk.appspot.com;", kAMUserEmailUserDefaultsKey, kAMPasswordUserDefaultsKey]];
     */
   // [userDefaultsSetupStr appendString:[NSString stringWithFormat:@"Device:(%@,%@,%@,%@):timeout in minutes;", AMDeviceModeSettingsKey, AMIdleFeelTimeoutKey,@"Mirror Effect",@"Position"]];
    
  //  [userDefaultsSetupStr appendString:[NSString stringWithFormat:@"Configuration:(%@,%@):Set Device configuration;", @"",@"Auto Device configuration"]];

  
 //   [userDefaultsSetupStr appendString:[NSString stringWithFormat:@"Digital FoV Curtain:(%@,%@,%@,%@):measured in %% of screen width or height;", FOV_CURTAIN_KEY_LEFT, FOV_CURTAIN_KEY_RIGHT, FOV_CURTAIN_KEY_TOP, FOV_CURTAIN_KEY_BOTTOM]];
    
    NSString * msgString;
    NSString * ipofDevice = [kiosk getIPAddressofDevice];
    if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
    {
        msgString = [NSString stringWithFormat:@"-> please input < %@ > ip in ipad with respect to camera address", ipofDevice];
    }
    else
    {
        msgString = [NSString stringWithFormat:@"-> please input < %@ > ip in iphone with respect to touch panel address", ipofDevice];
    }
    //    [userDefaultsSetupStr appendString:[NSString stringWithFormat:@"Kiosk:(%@,%@,%@,%@,%@,%@,%@):measurements in meters and seconds",
    //                                                                  TOUCHSCREEN_IP_KEY, PRINT_KIOSK_IP_KEY, CAMERA_IP_KEY, SCREEN_DISTANCE_KEY, TARGET_DISTANCE_KEY, kAMCameraCountdownStepIntervalKey, kAMCameraShaderKey]];
    
    // for removing "Shader" from setting screen kAMCameraShaderKey is removed
    // msgString is added for IP of devices
    //[userDefaultsSetupStr appendString:[NSString stringWithFormat:@"Kiosk %@:(%@,%@,%@,%@):", msgString,TOUCHSCREEN_IP_KEY, PRINT_KIOSK_IP_KEY, CAMERA_IP_KEY,kAMCameraCountdownStepIntervalKey]];
    [userDefaultsSetupStr appendString:[NSString stringWithFormat:@"Kiosk %@:(%@,%@):", msgString,TOUCHSCREEN_IP_KEY, CAMERA_IP_KEY]];

    SCUserDefaultsDefinition *userDefaultsDef = [SCUserDefaultsDefinition definitionWithUserDefaultsKeyNamesString:userDefaultsSetupStr];
    
    // Account
    /*
    SCPropertyDefinition *accountNameDef = [userDefaultsDef propertyDefinitionWithName:kAMUserEmailUserDefaultsKey];
    accountNameDef.type = SCPropertyTypeTextField;
    SCPropertyDefinition *passwordDef = [userDefaultsDef propertyDefinitionWithName:kAMPasswordUserDefaultsKey];
    passwordDef.type = SCPropertyTypeTextField;
    passwordDef.attributes = [SCTextFieldAttributes attributesWithPlaceholder:nil
                                                              secureTextEntry:YES
                                                           autocorrectionType:UITextAutocorrectionTypeNo
                                                       autocapitalizationType:UITextAutocapitalizationTypeNone];
     */
    
    
    
    
    
    
    
    
    // Device
    SCPropertyDefinition *deviceModeDef = [userDefaultsDef propertyDefinitionWithName:AMDeviceModeSettingsKey];
    deviceModeDef.type = SCPropertyTypeSelection;
    
    NSUserDefaults * usdefault = [NSUserDefaults standardUserDefaults];
    NSString * deviceModePref1 = [usdefault stringForKey:AMDeviceModeSettingsKey];
    if ([deviceModePref1 isEqualToString:AMDeviceModeStrCamera])
    {
        deviceModeDef.attributes = [SCSelectionAttributes attributesWithItems:[NSArray arrayWithObjects: AMDeviceModeStrCamera, nil] allowMultipleSelection:NO allowNoSelection:NO];
    }
    else
    {
        deviceModeDef.attributes = [SCSelectionAttributes attributesWithItems:[NSArray arrayWithObjects:AMDeviceModeStrTouchScreen, AMDeviceModeStrCamera, nil] allowMultipleSelection:NO allowNoSelection:NO];
    }
    
    SCPropertyDefinition *mirrorEffect = [userDefaultsDef propertyDefinitionWithName:@"Mirror Effect"];
    mirrorEffect.type = SCPropertyTypeSelection;
    
    if ([deviceModePref1 isEqualToString:AMDeviceModeStrCamera])
    {
        mirrorEffect.attributes = [SCSelectionAttributes attributesWithItems:[NSArray arrayWithObjects: @"Yes",@"No", nil] allowMultipleSelection:NO allowNoSelection:NO];
    }

    SCPropertyDefinition *positionEffect = [userDefaultsDef propertyDefinitionWithName:@"Position"];
    positionEffect.type = SCPropertyTypeSelection;
    
    if ([deviceModePref1 isEqualToString:AMDeviceModeStrCamera])
    {
        positionEffect.attributes = [SCSelectionAttributes attributesWithItems:[NSArray arrayWithObjects: @"Yes",@"No", nil] allowMultipleSelection:NO allowNoSelection:NO];
    }

    
    
    SCPropertyDefinition *idleFeelTimeoutMinsDef = [userDefaultsDef propertyDefinitionWithName:AMIdleFeelTimeoutKey];
    idleFeelTimeoutMinsDef.type = SCPropertyTypeNumericTextField;
    
    // Touch Screen
    SCPropertyDefinition *touchScreenIPDef = [userDefaultsDef propertyDefinitionWithName:TOUCHSCREEN_IP_KEY];
    touchScreenIPDef.type = SCPropertyTypeTextField;
    
    SCPropertyDefinition *printKioskIPDef = [userDefaultsDef propertyDefinitionWithName:PRINT_KIOSK_IP_KEY];
    printKioskIPDef.type = SCPropertyTypeTextField;
    
    // Camera
    SCPropertyDefinition *cameraIPDef = [userDefaultsDef propertyDefinitionWithName:CAMERA_IP_KEY];
    cameraIPDef.type = SCPropertyTypeTextField;
    
    SCPropertyDefinition *countdownStepDef = [userDefaultsDef propertyDefinitionWithName:kAMCameraCountdownStepIntervalKey];
    countdownStepDef.type = SCPropertyTypeNumericTextField;
    /*
     SCPropertyDefinition *shaderDef = [userDefaultsDef propertyDefinitionWithName:kAMCameraShaderKey];
     shaderDef.type = SCPropertyTypeSelection;
     shaderDef.attributes = [SCSelectionAttributes attributesWithItems:@[@"white30step50", @"white30step50power4", @"white50step50", @"white50step80power2", @"white50step80power3", @"white50step80power4", @"white50step80power9", @"white50step100power4", @"white70step50power4", @"wacky"] allowMultipleSelection:NO allowNoSelection:NO];
     */
    // Green Screen
    
    SCPropertyDefinition *fovCurtainLeftDef = [userDefaultsDef propertyDefinitionWithName:FOV_CURTAIN_KEY_LEFT];
    fovCurtainLeftDef.type = SCPropertyTypeNumericTextField;
    
    SCPropertyDefinition *fovCurtainRightDef = [userDefaultsDef propertyDefinitionWithName:FOV_CURTAIN_KEY_RIGHT];
    fovCurtainRightDef.type = SCPropertyTypeNumericTextField;
    
    SCPropertyDefinition *fovCurtainTopDef = [userDefaultsDef propertyDefinitionWithName:FOV_CURTAIN_KEY_TOP];
    fovCurtainTopDef.type = SCPropertyTypeNumericTextField;
    
    SCPropertyDefinition *fovCurtainBottomDef = [userDefaultsDef propertyDefinitionWithName:FOV_CURTAIN_KEY_BOTTOM];
    fovCurtainBottomDef.type = SCPropertyTypeNumericTextField;
    
    //    screenWidthDef.cellActions.willConfigure = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    //    {
    //        // set the value here
    //        [cell.boundObject setValue:@"6" forKey:@"width"];
    //    };
    
    
    //    section = [SCTableViewSection sectionWithHeaderTitle:@"Video Processor"];
    //    [self.tableViewModel addSection:section];
    //
    //    section = [SCTableViewSection sectionWithHeaderTitle:@"Product"];
    //    [self.tableViewModel addSection:section];
    //
    //    section = [SCTableViewSection sectionWithHeaderTitle:@"Cloud"];
    //    [self.tableViewModel addSection:section];
    //
    //    section = [SCTableViewSection sectionWithHeaderTitle:@"Installation"];
    //    [self.tableViewModel addSection:section];
    
    //    passwordDef.attributes = [SCTextFieldAttributes attributesWithPlaceholder:nil secureTextEntry:YES autocorrectionType:UITextAutocorrectionTypeNo autocapitalizationType:UITextAutocapitalizationTypeNone];
    
    //    SCPropertyDefinition *volumeDef = [userDefaultsDef propertyDefinitionWithName:@"volume"];
    //    volumeDef.type = SCPropertyTypeSlider;
    //    volumeDef.attributes = [SCSliderAttributes attributesWithMinimumValue:0 maximumValue:100];
    
    //    SCPropertyDefinition *ringtoneDef = [userDefaultsDef propertyDefinitionWithName:@"ringtone"];
    //    ringtoneDef.type = SCPropertyTypeSelection;
    //    ringtoneDef.attributes = [SCSelectionAttributes attributesWithItems:[NSArray arrayWithObjects:@"Ring 1", @"Ring 2", @"Ring 3", nil] allowMultipleSelection:NO allowNoSelection:YES];
    
    // Have STV generate everything for us!
    [self.tableViewModel generateSectionsForUserDefaultsDefinition:userDefaultsDef];
    
    // Listen for changes and update live data.
    section.cellActions.valueChanged = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        if(self.tableViewModel.valuesAreValid)
            NSLog(@"Data is valid!\n");
        else
            NSLog(@"Data is invalid!\n");
    };
    
    
    
    
    SCLabelCell * SubModeCell = [SCLabelCell cellWithText:@"Subscription Type" boundObject:type labelTextPropertyName:@"Subscription Type"];
    
    SCTableViewSection * subModeSection = [SCTableViewSection sectionWithHeaderTitle:@"Subscription"];
    [self.tableViewModel addSection:subModeSection];
    [subModeSection addCell:SubModeCell];
    
    subModeSection.cellActions.didSelect = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
        
        PurchaseViewController *eventController = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([PurchaseViewController class])];
        [self.navigationController pushViewController:eventController animated:YES];
        
        [self.navigationController setNavigationBarHidden: YES animated:YES];
    };
    
    
    
    
    
    NSUserDefaults *stddefaults = [NSUserDefaults standardUserDefaults];
    
    NSString * username = [stddefaults stringForKey:@"username"];
    
     NSString * lastname = [stddefaults stringForKey:@"lastname"];
    
     NSString * email = [stddefaults stringForKey:@"logemailId"];
    
    NSString *display = [NSString stringWithFormat:@"You are currently logged in as %@ %@ (%@)",username,lastname,email];
    
//    SCLabelCell * usernameModeCell = [SCLabelCell cellWithText:display boundObject:@"You are currently logged in as" labelTextPropertyName:@"You are currently logged in as"];
//
//    SCTableViewSection * usernameModeSection = [SCTableViewSection sectionWithHeaderTitle:@""];
//    [self.tableViewModel addSection:usernameModeSection];
//    [usernameModeSection addCell:usernameModeCell];
    
    
    
    
    
    SCLabelCell * logoutCell = [SCLabelCell cellWithText:@"Logout" boundObject:nil labelTextPropertyName:@"Logout"];
    
    
    SCTableViewSection * logoutSection = [SCTableViewSection sectionWithHeaderTitle:display];
    
    [self.tableViewModel addSection:logoutSection];
    [logoutSection addCell:logoutCell];
    
    logoutSection.cellActions.didSelect = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"iAmuse" message:@"Are you sure you want to logout?" delegate:self cancelButtonTitle:@"Yes"otherButtonTitles:@"No", nil];
        [alert show];
    };
    
    
    
    
  
    
    

}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
//    if (buttonIndex == 0) {
//        [self cleanUp];
//        [self logoutServiceCall];
//    }
    
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

//- (void)setRootViewController
//{
//    UIStoryboard *storyboard;
//    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
//    NSString * deviceModePref = [defaults stringForKey:AMDeviceModeSettingsKey];
//    CTAppDelegate *delegate = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
//    // show the storyboard
//    UIViewController *rootViewController = [storyboard instantiateInitialViewController];
//    if (0)
//    {
//        delegate.window.rootViewController = rootViewController;
//    }
//    else
//    {
//        if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
//        {
//            //  if((UI_USER_INTERFACE_IDIOM()) == UIUserInterfaceIdiomPhone)
//
//            storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
//
//            if([[NSUserDefaults standardUserDefaults] boolForKey:@"isLogin"])
//            {
//                rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"EventListViewController"];
//            }
//            else
//            {
//                rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"SignInViewController"];
//            }
//            UINavigationController *navCont = [[UINavigationController alloc] initWithRootViewController:rootViewController];
//            delegate.window.rootViewController = navCont;
//
//        }
//        else
//        {
//            if((UI_USER_INTERFACE_IDIOM()) == UIUserInterfaceIdiomPhone)
//            {
//                storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhoneTouch" bundle:nil];
//            }
//            else
//            {
//                storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
//            }
//            rootViewController = [storyboard instantiateInitialViewController];
//
//            delegate.window.rootViewController = rootViewController;
//            // [self getSubscriptionDetail];
//        }
//    }
//}

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
                rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"SignInViewController"];
            }
           // rootViewController = [storyboard instantiateInitialViewController];
            UINavigationController *navCont = [[UINavigationController alloc] initWithRootViewController:rootViewController];
            delegate.window.rootViewController = navCont;
            // [self getSubscriptionDetail];
        }
    }
}


- (void)setDefaultsForPrintSettings
{
    // Use key binding for app version.
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
    NSString * appVersionStr = [AMUtility appVersion];
    [dict setValue:appVersionStr forKey:@"Version"];
    SCLabelCell * appVersionDef = [SCLabelCell cellWithText:@"Version" boundObject:appVersionStr labelTextPropertyName:@"Version"];
    
    SCTableViewSection * section = [SCTableViewSection sectionWithHeaderTitle:@"Application"];
    [self.tableViewModel addSection:section];
    [section addCell:appVersionDef];
    
    
    // Persistent User Defaults with Editor
    NSMutableString * userDefaultsSetupStr = [[NSMutableString alloc] init];
    
    
    // First give it the layout with dictionary keys.
    [userDefaultsSetupStr appendString:[NSString stringWithFormat:@"Print Image Ratio:(%@,%@):;", @"Ratio",@"Print Mode"]];
    
//    [userDefaultsSetupStr appendString:[NSString stringWithFormat:@"Account:(%@,%@):from iamuse-kiosk.appspot.com;", kAMUserEmailUserDefaultsKey, kAMPasswordUserDefaultsKey]];
   
   
  
    CTKiosk *kiosk = [CTKiosk sharedInstance];
    NSString * msgString;
    NSString * ipofDevice = [kiosk getIPAddressofDevice];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        msgString = [NSString stringWithFormat:@"-> please input < %@ > ip in ipad with respect to camera address", ipofDevice];
    }
    else
    {
        msgString = [NSString stringWithFormat:@"-> please input < %@ > ip in iphone with respect to touch panel address", ipofDevice];
    }
    //    [userDefaultsSetupStr appendString:[NSString stringWithFormat:@"Kiosk:(%@,%@,%@,%@,%@,%@,%@):measurements in meters and seconds",
    //                                                                  TOUCHSCREEN_IP_KEY, PRINT_KIOSK_IP_KEY, CAMERA_IP_KEY, SCREEN_DISTANCE_KEY, TARGET_DISTANCE_KEY, kAMCameraCountdownStepIntervalKey, kAMCameraShaderKey]];
    
    // for removing "Shader" from setting screen kAMCameraShaderKey is removed
    // msgString is added for IP of devices
    [userDefaultsSetupStr appendString:[NSString stringWithFormat:@"Kiosk %@:(%@,%@,%@):", msgString,TOUCHSCREEN_IP_KEY, PRINT_KIOSK_IP_KEY, CAMERA_IP_KEY]];
    
    SCUserDefaultsDefinition *userDefaultsDef = [SCUserDefaultsDefinition definitionWithUserDefaultsKeyNamesString:userDefaultsSetupStr];
    
    
    // Account
    /*
    SCPropertyDefinition *accountNameDef = [userDefaultsDef propertyDefinitionWithName:kAMUserEmailUserDefaultsKey];
    accountNameDef.type = SCPropertyTypeTextField;
    SCPropertyDefinition *passwordDef = [userDefaultsDef propertyDefinitionWithName:kAMPasswordUserDefaultsKey];
    passwordDef.type = SCPropertyTypeTextField;
    passwordDef.attributes = [SCTextFieldAttributes attributesWithPlaceholder:nil
                                                              secureTextEntry:YES
                                                           autocorrectionType:UITextAutocorrectionTypeNo
                                                       autocapitalizationType:UITextAutocapitalizationTypeNone];
     */
    

    
    //Ratio
    SCPropertyDefinition *ratioModeDef = [userDefaultsDef propertyDefinitionWithName:@"Ratio"];
    ratioModeDef.type = SCPropertyTypeSelection;
    ratioModeDef.attributes = [SCSelectionAttributes attributesWithItems:[NSArray arrayWithObjects:@"Aspect Fit", @"Aspect Fill",@"Scale to Fill", nil] allowMultipleSelection:NO allowNoSelection:NO];
    
    
    
    SCPropertyDefinition *printModeDef = [userDefaultsDef propertyDefinitionWithName:@"Print Mode"];
    printModeDef.type = SCPropertyTypeSelection;
    printModeDef.attributes = [SCSelectionAttributes attributesWithItems:[NSArray arrayWithObjects:@"Original Mode", @"Edge To Edge Mode", nil] allowMultipleSelection:NO allowNoSelection:NO];
    
    
    
    SCPropertyDefinition *idleFeelTimeoutMinsDef = [userDefaultsDef propertyDefinitionWithName:AMIdleFeelTimeoutKey];
    idleFeelTimeoutMinsDef.type = SCPropertyTypeNumericTextField;
    
    // Touch Screen
    SCPropertyDefinition *touchScreenIPDef = [userDefaultsDef propertyDefinitionWithName:TOUCHSCREEN_IP_KEY];
    touchScreenIPDef.type = SCPropertyTypeTextField;
    
    SCPropertyDefinition *printKioskIPDef = [userDefaultsDef propertyDefinitionWithName:PRINT_KIOSK_IP_KEY];
    printKioskIPDef.type = SCPropertyTypeTextField;
    
    // Camera
    SCPropertyDefinition *cameraIPDef = [userDefaultsDef propertyDefinitionWithName:CAMERA_IP_KEY];
    cameraIPDef.type = SCPropertyTypeTextField;
    
       /*
     SCPropertyDefinition *shaderDef = [userDefaultsDef propertyDefinitionWithName:kAMCameraShaderKey];
     shaderDef.type = SCPropertyTypeSelection;
     shaderDef.attributes = [SCSelectionAttributes attributesWithItems:@[@"white30step50", @"white30step50power4", @"white50step50", @"white50step80power2", @"white50step80power3", @"white50step80power4", @"white50step80power9", @"white50step100power4", @"white70step50power4", @"wacky"] allowMultipleSelection:NO allowNoSelection:NO];
     */
    // Green Screen
    
    
    //    screenWidthDef.cellActions.willConfigure = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    //    {
    //        // set the value here
    //        [cell.boundObject setValue:@"6" forKey:@"width"];
    //    };
    
    
    //    section = [SCTableViewSection sectionWithHeaderTitle:@"Video Processor"];
    //    [self.tableViewModel addSection:section];
    //
    //    section = [SCTableViewSection sectionWithHeaderTitle:@"Product"];
    //    [self.tableViewModel addSection:section];
    //
    //    section = [SCTableViewSection sectionWithHeaderTitle:@"Cloud"];
    //    [self.tableViewModel addSection:section];
    //
    //    section = [SCTableViewSection sectionWithHeaderTitle:@"Installation"];
    //    [self.tableViewModel addSection:section];
    
    //    passwordDef.attributes = [SCTextFieldAttributes attributesWithPlaceholder:nil secureTextEntry:YES autocorrectionType:UITextAutocorrectionTypeNo autocapitalizationType:UITextAutocapitalizationTypeNone];
    
    //    SCPropertyDefinition *volumeDef = [userDefaultsDef propertyDefinitionWithName:@"volume"];
    //    volumeDef.type = SCPropertyTypeSlider;
    //    volumeDef.attributes = [SCSliderAttributes attributesWithMinimumValue:0 maximumValue:100];
    
    //    SCPropertyDefinition *ringtoneDef = [userDefaultsDef propertyDefinitionWithName:@"ringtone"];
    //    ringtoneDef.type = SCPropertyTypeSelection;
    //    ringtoneDef.attributes = [SCSelectionAttributes attributesWithItems:[NSArray arrayWithObjects:@"Ring 1", @"Ring 2", @"Ring 3", nil] allowMultipleSelection:NO allowNoSelection:YES];
    
    // Have STV generate everything for us!
    [self.tableViewModel generateSectionsForUserDefaultsDefinition:userDefaultsDef];
    
    // Listen for changes and update live data.
    section.cellActions.valueChanged = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        if(self.tableViewModel.valuesAreValid)
            NSLog(@"Data is valid!\n");
        else
            NSLog(@"Data is invalid!\n");
    };
}

- (void)autoConfigureCameraAndTouchDevice
{
    CTAppDelegate *delegate = (CTAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    MBProgressHUD * hud = [MBProgressHUD showHUDAddedTo:delegate.window animated:YES];
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
                
                NSString *cameraIP = [response valueForKey:@"cameraIP"];
                NSString *touchIP = [response valueForKey:@"touchIP"];
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
                [self.tableViewModel reloadBoundValues];
                CTKiosk *kiosk = [CTKiosk sharedInstance];
                [kiosk startServer];
            }
        }
        }
    }];
    
    
    /*
     NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
     NSString * deviceModePref = [defaults stringForKey:AMDeviceModeSettingsKey];
     NSString *ipadd = [self getIPAddressofDevice];
     if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
     {
     [defaults setObject:ipadd forKey:CAMERA_IP_KEY];
     [defaults setObject:@"" forKey:TOUCHSCREEN_IP_KEY];
     }
     else
     {
     [defaults setObject:ipadd forKey:TOUCHSCREEN_IP_KEY];
     [defaults setObject:@"" forKey:CAMERA_IP_KEY];
     }
     [defaults synchronize];
     [[NSNotificationCenter defaultCenter] postNotificationName:@"AutoConfigureDeviceNotification" object:nil];
     NSString * networkTouchScreenAddress = [defaults stringForKey:TOUCHSCREEN_IP_KEY];
     NSString * networkCameraAddress = [defaults stringForKey:CAMERA_IP_KEY];
     if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
     {
     deviceMode = CTKioskDeviceModeCamera;
     httpServerPort = AMHttpCameraApiPort;
     
     // Need a connection to the touch panel.
     
     // if ([networkTouchScreenAddress length] == 0)
     {
     
     NSArray *arr = [networkCameraAddress componentsSeparatedByString:@"."];
     
     if (arr.count > 3) {
     UIViewController *visibleController = [self visibleViewController];
     hud = [MBProgressHUD showHUDAddedTo:visibleController.view animated:YES];
     hud.mode = MBProgressHUDModeIndeterminate;
     hud.labelText = @"auto configuring device";
     [[[UIApplication sharedApplication] keyWindow] setUserInteractionEnabled:NO];
     
     self.isGetConnectionDeviceAddress = NO;
     NSInteger range = [arr[3] integerValue];
     for (int i = 0; i < 256; i++) {
     if (self.isGetConnectionDeviceAddress == YES) {
     break;
     }
     if (i == range) {
     continue;
     }
     NSString * action = @"stop";
     NSURL *networkUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@.%@.%@.%d:%d/%@",arr[0],arr[1],arr[2],i,AMHttpTouchScreenApiPort,action]];
     dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
     {
     // Background work
     [self sendConnectionRequestToDevice:networkUrl andIPAddress:[NSString stringWithFormat:@"%@.%@.%@.%d",arr[0],arr[1],arr[2],i] andRange:i];
     dispatch_async(dispatch_get_main_queue(), ^(void)
     {
     // Main thread work (UI usually)
     });
     });
     }
     
     }
     }
     //        else
     //        {
     //            networkTouchScreenBaseURL = [NSURL URLWithString:[NSString
     //                                                              stringWithFormat:@"http://%@:%d",
     //                                                              networkTouchScreenAddress, AMHttpTouchScreenApiPort]];
     //            DDLogInfo(@"Touch Panel URL %@", networkTouchScreenBaseURL);
     //        }
     }
     else
     {
     deviceMode = CTKioskDeviceModeTouchScreen;
     httpServerPort = AMHttpTouchScreenApiPort;
     
     // Need a connection to the camera.
     // Prepare the connection to the network camera.
     // if ([networkCameraAddress length] == 0)
     {
     
     NSArray *arr = [networkTouchScreenAddress componentsSeparatedByString:@"."];
     
     if (arr.count > 3) {
     UIViewController *visibleController = [self visibleViewController];
     hud = [MBProgressHUD showHUDAddedTo:visibleController.view animated:YES];
     hud.mode = MBProgressHUDModeIndeterminate;
     hud.labelText = @"auto configuring device";
     [[[UIApplication sharedApplication] keyWindow] setUserInteractionEnabled:NO];
     self.isGetConnectionDeviceAddress = NO;
     NSInteger range = [arr[3] integerValue];
     for (int i = 0; i < 256; i++) {
     if (self.isGetConnectionDeviceAddress == YES) {
     break;
     }
     if (i == range) {
     continue;
     }
     NSString * action = @"stop";
     
     NSURL *networkUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@.%@.%@.%d:%d/%@",arr[0],arr[1],arr[2],i,AMHttpCameraApiPort,action]];
     dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
     {
     // Background work
     [self sendConnectionRequestToDevice:networkUrl andIPAddress:[NSString stringWithFormat:@"%@.%@.%@.%d",arr[0],arr[1],arr[2],i] andRange:i];
     dispatch_async(dispatch_get_main_queue(), ^(void)
     {
     // Main thread work (UI usually)
     });
     });
     }
     }
     
     }
     //        else
     //        {
     //            networkCameraBaseURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%d",
     //                                                         networkCameraAddress, AMHttpCameraApiPort]];
     //            DDLogInfo(@"Touch Panel URL %@", networkTouchScreenBaseURL);
     //        }
     
     }
     */
}

- (void)setDefaultsForIPadSettings
{
  /*  SCLabelCell * subscriptionCell = [SCLabelCell cellWithText:@"Subscription" boundObject:nil labelTextPropertyName:@"Subscription"];
    
    
    SCTableViewSection * subscriptionSection = [SCTableViewSection sectionWithHeaderTitle:@"Subscription"];
    
    [self.tableViewModel addSection:subscriptionSection];
    [subscriptionSection addCell:subscriptionCell];
    
    subscriptionSection.cellActions.didSelect = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        PurchaseViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"PurchaseViewController"];
        [controller setIsShowingFromSetting:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController pushViewController:controller animated:YES];
        });
    };
    
    SCLabelCell * privacyCell = [SCLabelCell cellWithText:@"Privacy Policy" boundObject:nil labelTextPropertyName:@"Privacy Policy"];
    
    SCTableViewSection * privacySection = [SCTableViewSection sectionWithHeaderTitle:@"Privacy Policy"];
    
    [self.tableViewModel addSection:privacySection];
    [privacySection addCell:privacyCell];
    
    privacySection.cellActions.didSelect = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            PrivacyPolicyViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([PrivacyPolicyViewController class])];
            [controller setIsShowingFromSetting:YES];
            [self.navigationController pushViewController:controller animated:YES];
        });
    };
*/
    SCLabelCell * configurationCell = [SCLabelCell cellWithText:@"Refresh (Autoconfigure)" boundObject:nil labelTextPropertyName:@"Config Device"];
    
    SCTableViewSection * configurationSection = [SCTableViewSection sectionWithHeaderTitle:@"Device Configuration"];
    
    [self.tableViewModel addSection:configurationSection];
    [configurationSection addCell:configurationCell];
    
    CTKiosk *kiosk = [CTKiosk sharedInstance];
    configurationSection.cellActions.didSelect = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        kiosk.autoConfigureCount = 0;
        [self autoConfigureCameraAndTouchDevice];
    };

    // Use key binding for app version.
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
    NSString * appVersionStr = [AMUtility appVersion];
    
    
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
    
    NSLog(@"build is %@",build);
    
    
//    [dict setValue:appVersionStr forKey:@"Version"];
//    SCLabelCell * appVersionDef = [SCLabelCell cellWithText:@"App Version" boundObject:appVersionStr labelTextPropertyName:@"Version"];
    
    [dict setValue:build forKey:@"Version"];
    SCLabelCell * appVersionDef = [SCLabelCell cellWithText:@"App Version" boundObject:build labelTextPropertyName:@"Version"];
    
    SCTableViewSection * section = [SCTableViewSection sectionWithHeaderTitle:@"Application"];
    [self.tableViewModel addSection:section];
    [section addCell:appVersionDef];
    
    NSUserDefaults * userdefault = [NSUserDefaults standardUserDefaults];
    NSString * deviceModePref = [userdefault stringForKey:AMDeviceModeSettingsKey];
    
    SCLabelCell * deviceModeCell = [SCLabelCell cellWithText:@"Device Mode" boundObject:deviceModePref labelTextPropertyName:@"Device Mode"];
    
    SCTableViewSection * deviceModeSection = [SCTableViewSection sectionWithHeaderTitle:@"Device"];
    [self.tableViewModel addSection:deviceModeSection];
    [deviceModeSection addCell:deviceModeCell];

    
    // Persistent User Defaults with Editor
    NSMutableString * userDefaultsSetupStr = [[NSMutableString alloc] init];
    
    
    // First give it the layout with dictionary keys.
    //[userDefaultsSetupStr appendString:[NSString stringWithFormat:@"Print Image Ratio:(%@):;", @"Ratio"]];
    
//    [userDefaultsSetupStr appendString:[NSString stringWithFormat:@"Account:(%@,%@):from iamuse-kiosk.appspot.com;", kAMUserEmailUserDefaultsKey, kAMPasswordUserDefaultsKey]];
  //  [userDefaultsSetupStr appendString:[NSString stringWithFormat:@"Device:(%@,%@):timeout in minutes;", AMDeviceModeSettingsKey, AMIdleFeelTimeoutKey]];
  //  [userDefaultsSetupStr appendString:[NSString stringWithFormat:@"Device:(%@)", AMDeviceModeSettingsKey]];

    NSString * msgString;
    NSString * ipofDevice = [kiosk getIPAddressofDevice];
   
    if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
    {
        msgString = [NSString stringWithFormat:@"-> please input < %@ > ip in ipad with respect to camera address", ipofDevice];
    }
    else
    {
        msgString = [NSString stringWithFormat:@"-> please input < %@ > ip in iphone with respect to touch panel address", ipofDevice];
    }
    //    [userDefaultsSetupStr appendString:[NSString stringWithFormat:@"Kiosk:(%@,%@,%@,%@,%@,%@,%@):measurements in meters and seconds",
    //                                                                  TOUCHSCREEN_IP_KEY, PRINT_KIOSK_IP_KEY, CAMERA_IP_KEY, SCREEN_DISTANCE_KEY, TARGET_DISTANCE_KEY, kAMCameraCountdownStepIntervalKey, kAMCameraShaderKey]];
    
    // for removing "Shader" from setting screen kAMCameraShaderKey is removed
    // msgString is added for IP of devices
  //  [userDefaultsSetupStr appendString:[NSString stringWithFormat:@"Kiosk %@:(%@,%@,%@):", msgString,TOUCHSCREEN_IP_KEY, PRINT_KIOSK_IP_KEY, CAMERA_IP_KEY]];
    [userDefaultsSetupStr appendString:[NSString stringWithFormat:@"Kiosk %@:(%@,%@):", msgString,TOUCHSCREEN_IP_KEY, CAMERA_IP_KEY]];

    SCUserDefaultsDefinition *userDefaultsDef = [SCUserDefaultsDefinition definitionWithUserDefaultsKeyNamesString:userDefaultsSetupStr];
    
    // Account
    /*
    SCPropertyDefinition *accountNameDef = [userDefaultsDef propertyDefinitionWithName:kAMUserEmailUserDefaultsKey];
    accountNameDef.type = SCPropertyTypeTextField;
    SCPropertyDefinition *passwordDef = [userDefaultsDef propertyDefinitionWithName:kAMPasswordUserDefaultsKey];
    passwordDef.type = SCPropertyTypeTextField;
    passwordDef.attributes = [SCTextFieldAttributes attributesWithPlaceholder:nil
                                                              secureTextEntry:YES
                                                           autocorrectionType:UITextAutocorrectionTypeNo
                                                       autocapitalizationType:UITextAutocapitalizationTypeNone];
     */
    
    // Device
    SCPropertyDefinition *deviceModeDef = [userDefaultsDef propertyDefinitionWithName:AMDeviceModeSettingsKey];
    deviceModeDef.type = SCPropertyTypeSelection;
    
    if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
    {
        deviceModeDef.attributes = [SCSelectionAttributes attributesWithItems:[NSArray arrayWithObjects: AMDeviceModeStrCamera, nil] allowMultipleSelection:NO allowNoSelection:NO];
    }
    else
    {
        deviceModeDef.attributes = [SCSelectionAttributes attributesWithItems:[NSArray arrayWithObjects:AMDeviceModeStrTouchScreen, AMDeviceModeStrCamera, nil] allowMultipleSelection:NO allowNoSelection:NO];
    }
    
    //Ratio
//    SCPropertyDefinition *ratioModeDef = [userDefaultsDef propertyDefinitionWithName:@"Ratio"];
//    ratioModeDef.type = SCPropertyTypeSelection;
//    ratioModeDef.attributes = [SCSelectionAttributes attributesWithItems:[NSArray arrayWithObjects:@"Aspect Fit", @"Aspect Fill",@"Scale to Fill", nil] allowMultipleSelection:NO allowNoSelection:NO];
//    
//    SCPropertyDefinition *idleFeelTimeoutMinsDef = [userDefaultsDef propertyDefinitionWithName:AMIdleFeelTimeoutKey];
//    idleFeelTimeoutMinsDef.type = SCPropertyTypeNumericTextField;
    
    // Touch Screen
    SCPropertyDefinition *touchScreenIPDef = [userDefaultsDef propertyDefinitionWithName:TOUCHSCREEN_IP_KEY];
    touchScreenIPDef.type = SCPropertyTypeTextField;
    
    SCPropertyDefinition *printKioskIPDef = [userDefaultsDef propertyDefinitionWithName:PRINT_KIOSK_IP_KEY];
    printKioskIPDef.type = SCPropertyTypeTextField;
    
    // Camera
    SCPropertyDefinition *cameraIPDef = [userDefaultsDef propertyDefinitionWithName:CAMERA_IP_KEY];
    cameraIPDef.type = SCPropertyTypeTextField;
    
   
    
   
    
  
    /*
     SCPropertyDefinition *shaderDef = [userDefaultsDef propertyDefinitionWithName:kAMCameraShaderKey];
     shaderDef.type = SCPropertyTypeSelection;
     shaderDef.attributes = [SCSelectionAttributes attributesWithItems:@[@"white30step50", @"white30step50power4", @"white50step50", @"white50step80power2", @"white50step80power3", @"white50step80power4", @"white50step80power9", @"white50step100power4", @"white70step50power4", @"wacky"] allowMultipleSelection:NO allowNoSelection:NO];
     */
    // Green Screen
    
    //    screenWidthDef.cellActions.willConfigure = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    //    {
    //        // set the value here
    //        [cell.boundObject setValue:@"6" forKey:@"width"];
    //    };
    
    
    //    section = [SCTableViewSection sectionWithHeaderTitle:@"Video Processor"];
    //    [self.tableViewModel addSection:section];
    //
    //    section = [SCTableViewSection sectionWithHeaderTitle:@"Product"];
    //    [self.tableViewModel addSection:section];
    //
    //    section = [SCTableViewSection sectionWithHeaderTitle:@"Cloud"];
    //    [self.tableViewModel addSection:section];
    //
    //    section = [SCTableViewSection sectionWithHeaderTitle:@"Installation"];
    //    [self.tableViewModel addSection:section];
    
    //    passwordDef.attributes = [SCTextFieldAttributes attributesWithPlaceholder:nil secureTextEntry:YES autocorrectionType:UITextAutocorrectionTypeNo autocapitalizationType:UITextAutocapitalizationTypeNone];
    
    //    SCPropertyDefinition *volumeDef = [userDefaultsDef propertyDefinitionWithName:@"volume"];
    //    volumeDef.type = SCPropertyTypeSlider;
    //    volumeDef.attributes = [SCSliderAttributes attributesWithMinimumValue:0 maximumValue:100];
    
    //    SCPropertyDefinition *ringtoneDef = [userDefaultsDef propertyDefinitionWithName:@"ringtone"];
    //    ringtoneDef.type = SCPropertyTypeSelection;
    //    ringtoneDef.attributes = [SCSelectionAttributes attributesWithItems:[NSArray arrayWithObjects:@"Ring 1", @"Ring 2", @"Ring 3", nil] allowMultipleSelection:NO allowNoSelection:YES];
    
    // Have STV generate everything for us!
    [self.tableViewModel generateSectionsForUserDefaultsDefinition:userDefaultsDef];
    
    // Listen for changes and update live data.
    section.cellActions.valueChanged = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        if(self.tableViewModel.valuesAreValid)
            NSLog(@"Data is valid!\n");
        else
            NSLog(@"Data is invalid!\n");
    };
    
    
    
    
    
   
    
    
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString * subId = [defaults stringForKey:@"subscriptionType"];
    NSString *type;
    if ([subId integerValue] == 1)
    {
        // [self setBorderForSelectedSubscriptionView:self.freeView];
        type=@"Free Trial";
        
        
    }
    else if ([subId integerValue] == 2)
    {
        type =@"Single Event";
        //  [self setBorderForSelectedSubscriptionView:self.oneDaySubscriptionView];
    }
    else if ([subId integerValue] == 3)
    {
        type =@"Professional pay-as-you-go";
        //  [self.oneMonthSubscribeBtn setTitle:@"Your Current Plan" forState:UIControlStateNormal];
        //     [self setBorderForSelectedSubscriptionView:self.customUploadView];
    }
    else
    {
        type =@"Professional Yearly";
        //     [self setBorderForSelectedSubscriptionView:self.oneMonthSubscriptionView];
    }
    
    
    SCLabelCell * SubModeCell = [SCLabelCell cellWithText:@"Subscription Type" boundObject:type labelTextPropertyName:@"Subscription Type"];
    
    SCTableViewSection * subModeSection = [SCTableViewSection sectionWithHeaderTitle:@"Subscription"];
    [self.tableViewModel addSection:subModeSection];
    [subModeSection addCell:SubModeCell];
    
    
    subModeSection.cellActions.didSelect = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
        
        PurchaseViewController *eventController = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([PurchaseViewController class])];
        [self.navigationController pushViewController:eventController animated:YES];
        
        [self.navigationController setNavigationBarHidden: YES animated:YES];
    };
    
    
    
    
    
    
    
    
//    SCLabelCell * subscriptionCell = [SCLabelCell cellWithText:@"Subscription" boundObject:nil labelTextPropertyName:@"Subscription"];
//
//
//    SCTableViewSection * subscriptionSection = [SCTableViewSection sectionWithHeaderTitle:@""];
//
//    [self.tableViewModel addSection:subscriptionSection];
//    [subscriptionSection addCell: subscriptionCell];
//    subscriptionSection.cellActions.didSelect = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
//    {
//
//        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
//
//        PurchaseViewController *eventController = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([PurchaseViewController class])];
//        [self.navigationController pushViewController:eventController animated:YES];
//
//        [self.navigationController setNavigationBarHidden: YES animated:YES];
//    };
    
    
    NSUserDefaults *stddefaults = [NSUserDefaults standardUserDefaults];
    
    NSString * username = [stddefaults stringForKey:@"username"];
    
    NSString * lastname = [stddefaults stringForKey:@"lastname"];
    
    NSString * email = [stddefaults stringForKey:@"logemailId"];
    
    NSString *display = [NSString stringWithFormat:@"You are currently logged in as %@ %@ (%@)",username,lastname,email];
    
    
    
//    SCLabelCell * usernameModeCell = [SCLabelCell cellWithText:@"You are currently logged in as" boundObject:username labelTextPropertyName:@"You are currently logged in as"];
//
//    SCTableViewSection * usernameModeSection = [SCTableViewSection sectionWithHeaderTitle:@""];
//    [self.tableViewModel addSection:usernameModeSection];
//    [usernameModeSection addCell:usernameModeCell];
    
    
   
    
    SCLabelCell * logoutCell = [SCLabelCell cellWithText:@"Logout" boundObject:nil labelTextPropertyName:@"Logout"];
    
    
    SCTableViewSection * logoutSection = [SCTableViewSection sectionWithHeaderTitle:display];
    
    [self.tableViewModel addSection:logoutSection];
    [logoutSection addCell:logoutCell];
    
    logoutSection.cellActions.didSelect = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"iAmuse" message:@"Are you sure you want to logout?" delegate:self cancelButtonTitle:@"Yes"otherButtonTitles:@"No", nil];
        [alert show];
    };
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    CTKiosk *kiosk = [CTKiosk sharedInstance];
    if(![[self.storyboard valueForKey:@"name"] isEqualToString:@"PrintStoryboard_iPad"])
    {
        if ([[NSUserDefaults standardUserDefaults]  boolForKey:@"isLogin"]) {
            [kiosk registerDeviceOnServer];
        }
    }
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * networkAddress;
    NSString * otherDeviceAddress;

    NSString * deviceIPs = [NSString stringWithFormat:@"%@", [kiosk getIPAddressofDevice]];
    
    NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",
                                        kAMBaseURL, @"saveDeviceIP"]];
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
    NSString * deviceModePref = [defaults stringForKey:AMDeviceModeSettingsKey];
    if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
    {
        [dict setObject:@"iPhone" forKey:@"deviceType"];
        networkAddress = [defaults stringForKey:CAMERA_IP_KEY];
        otherDeviceAddress = [defaults stringForKey:TOUCHSCREEN_IP_KEY];
        
       [defaults setObject:networkAddress forKey:@"SaveCameraIP"];
        [defaults setObject:otherDeviceAddress forKey:@"SaveTouchIP"];
               
        
        
    }
    else
    {
        [dict setObject:@"iPad" forKey:@"deviceType"];
        networkAddress = [defaults stringForKey:TOUCHSCREEN_IP_KEY];
        otherDeviceAddress = [defaults stringForKey:CAMERA_IP_KEY];
        
              [defaults setObject:networkAddress forKey:@"SaveTouchIP"];
               [defaults setObject:otherDeviceAddress forKey:@"SaveCameraIP"];
        
        
    }
    deviceIPs = [NSString stringWithFormat:@"%@__%@__%@", deviceIPs, networkAddress, otherDeviceAddress];
    [dict setObject:deviceIPs forKey:@"deviceIP"];
    
    WebCommunication * webComm = [WebCommunication new];
    [webComm callToServerRequestDictionary:dict onURL:url WithBlock:^(NSDictionary *response, NSInteger status_code, NSError *error, WebCommunication *webComm)
     {
         NSLog(@"response : %@",response);
         
         if([[response objectForKey:@"responseDescription"] isEqualToString:@"Success"])
         {
             //NSLog(@"Success.");
         }
         else
         {
             //NSLog(@"Fail.");
         }
     }];
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
                 [self dismissViewControllerAnimated:YES completion: ^{
                     [self setRootViewController];
                 }];
             }
             else
             {
                 [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isLogin"];
                 [[NSUserDefaults standardUserDefaults] synchronize];
                 [self.navigationController popViewControllerAnimated:YES];
                 [self setRootViewController];
             }
         }
         else
         {
             
         }
     }];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doneBtnTouch:(id)sender
{
    NSLog(@"%s", __FUNCTION__);

    // This path can be different depending on the startup state of the device.
//    UIResponder *currentController = [[[[[UIApplication sharedApplication] keyWindow] subviews] objectAtIndex:0] nextResponder];
//    if ([currentController conformsToProtocol:@protocol(SettingsViewCompleteDelegate)]) {
//        id <SettingsViewCompleteDelegate> presenter = self.presentingViewController;
    id presenter = self.presentingViewController;
    if ([presenter conformsToProtocol:@protocol(SettingsViewCompleteDelegate)])
    {
        [presenter settingsViewController:self didFinishSettings:nil];
    }
    else if ([presenter isKindOfClass:[UINavigationController class]])
    {
        [self dismissViewControllerAnimated:YES completion: nil];
        
        CTKiosk * kiosk = [CTKiosk sharedInstance];
        [kiosk loadPersistentSettings:YES];

    }
    else
    {
        NSLog(@"Unplanned scenario, presenter is %@",
                NSStringFromClass([presenter class]));
    }

//    CTKiosk *kiosk = [CTKiosk sharedInstance];
//    if (kiosk.deviceMode == CTKioskDeviceModeCamera) {
//    }
}

@end
