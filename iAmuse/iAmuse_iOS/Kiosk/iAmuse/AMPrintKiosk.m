//
//  AMPrintKiosk.m
//  iAmuse
//
//  Created by Roland Hordos on 2014-06-30.
//  Copyright (c) 2014 iAmuse Inc. All rights reserved.
//

#import "AMPrintKiosk.h"
#import "EXTScope.h"
#import <CoreData/CoreData.h>
#import "APLPrintPageRenderer.h"
#import <ASIHTTPRequest/ASIHTTPRequest.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <LRResty/LRResty.h>
#import "CTBackgroundScreen.h"
#import "AFJSONRequestOperation.h"
#import "AMConstants.h"
#import "PhotoLayout.h"
#import "PhotoSession.h"
#import "CTCameraHTTPConnection.h"
#import "Photo.h"
#import "ASIFormDataRequest.h"
#import "Kiosk.h"
#import "TSMessage.h"
#import "UIImage+iAmuse.h"
#import "AMUtility.h"
#import "AMStorageManager.h"
#import "NSDate+DateTools.h"


static void CTKioskShowMessage(NSString *message)
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

static void CTKioskShowAlert(NSString *message)
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

static void CTKioskShowAlertWithError(NSError *error)
{
    CTKioskShowAlert([error localizedDescription]);
}

//
//  Like it's cousin the CTKiosk, AMPrintKiosk models the Print Kiosk as a whole.
//

// Class extension for private setters on readonly properties.
@interface AMPrintKiosk ()
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@end

@implementation AMPrintKiosk

+ (id)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

-(id) init {
    DDLogVerbose(@"%s", __FUNCTION__);
    self = [super init];

    if (self) {
        
        self.dateFormatter = [[NSDateFormatter alloc] init];
        self.dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        self.dateFormatter.dateFormat = kAMJSONTimestampFormat;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(newDiskPhoto:)
                                                     name:AMCameraNewDiskPhotoNotification
                                                   object:nil];

        // Touch Screen wants to know when it should pull a photo down from
        // the camera.
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(newRemoteCameraPhoto:)
//                                                     name:AMCameraNewRemotePhotoNotification
//                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(refreshPrintablePhotosList:)
                                                     name:AMRefreshDataNotification
                                                   object:nil];
    }

    return self;
}

- (void)dealloc {
    DDLogVerbose(@"%s", __FUNCTION__);
}

- (void)startup {
    // Load settings.
    _storePath = [AMUtility applicationDocumentsDirectory];
    [self loadPersistentSettings];
    
    // Create and assemble our Bonjour aware HTTP server on a fixed port with our custom HTTP connection.
    if (!httpServer) {
        httpServer = [[HTTPServer alloc] init];
        [httpServer setConnectionClass:[CTCameraHTTPConnection class]];
        [httpServer setType:@"_http._tcp."];        // broadcast presence via Bonjour.
        [httpServer setPort:httpServerPort];
        
        // Serve files from our Photo Store directory
        NSString *webPath = [self photoStoreDirectory];
        
        DDLogInfo(@"Setting http server doc root to %@", webPath);

        [httpServer setDocumentRoot:webPath];
    }

    [self startServer];
}

- (void)pause {
    if (httpServer && httpServer.isRunning) {
        [httpServer stop];
    }

    // TODO - what about active print jobs?
}

- (void)resume {
    if (httpServer && !httpServer.isRunning) {
        [self startServer];
    }

    // TODO - sync missing photos on the day
}

- (void)shutdown {
    if (httpServer && httpServer.isRunning) {
        [httpServer stop];
    }
}

- (BOOL)startServer
{
    // Start the HTTP API service.

    NSError *error;
    if([httpServer start:&error])
    {
        DDLogInfo(@"Started HTTP Server on port %hu", [httpServer listeningPort]);
        [self loadPhotos];
        return TRUE;
    }
    else
    {
        DDLogError(@"Error starting HTTP Server: %@", error);
        return FALSE;
    }
}

-(void) loadPersistentSettings
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    httpServerPort = AMHttpPrintKioskApiPort;

    // Need a connection to the touch panel.
    NSString * networkTouchScreenAddress = [defaults stringForKey:TOUCHSCREEN_IP_KEY];
    if ([networkTouchScreenAddress length] == 0)
    {
        CTKioskShowAlert(@"Please enter a network Touch Panel address.");
    }
    else
    {
        networkTouchScreenBaseURL = [NSURL URLWithString:[NSString
                stringWithFormat:@"http://%@:%d",
                                 networkTouchScreenAddress, AMHttpTouchScreenApiPort]];
        DDLogInfo(@"Touch Panel URL %@", networkTouchScreenBaseURL);
    }

    [self setIdleFeelingTimeoutMins:[defaults floatForKey:AMIdleFeelTimeoutKey]];
}

- (void)userHeartbeat {
    [[NSNotificationCenter defaultCenter] postNotificationName:AMDidSenseUser object:self];
}

//
//  Returns valid, enabled, sorted photo layouts with at least an available
//  background.
//
- (void)loadPhotos {
    DDLogVerbose(@"Loading Photos from CoreData");

    AMStorageManager *store = [AMStorageManager sharedInstance];
    self.photos = [NSMutableArray arrayWithArray:[store fetchAllPhotosFromToday]];
}

//
//  Ask across the network for new photos.
//
//  Use the /printablephotos rest call, where we expect a metadata array returned,
//  something like this:
//  [
//{
//    "filename" : "photo-1404594865.195777.jpg",
//    "timestamp": ""
//},
//{
//    "filename" : "photo-1404594874.752460.jpg"
//    "timestamp": ""
//},
//{
//    "filename" : "photo-1404594885.841702.jpg"
//    "timestamp": ""
//}
//]
//
- (void)downloadPrintablePhotoMetadataFromKiosk {
    DDLogVerbose(@"Asking Kiosk for list of printable photos");
    
    if (!networkTouchScreenBaseURL)
        return;

    NSString *urlStr = [NSString stringWithFormat:@"%@/printablephotos", networkTouchScreenBaseURL];

    [[LRResty client] get:urlStr
                withBlock:^(LRRestyResponse *response) {
                    
                    if(response.status == 200) {
                        NSLog(@"Successful response %@", [response asString]);
                        NSError *jsonError;
                        NSArray *jsonData = [NSJSONSerialization
                                JSONObjectWithData:[[response asString]
                                        dataUsingEncoding:NSUTF8StringEncoding]
                                           options:NSJSONReadingMutableContainers error:&jsonError];

                        if (!jsonData)
                        {
                            NSLog(@"Error parsing JSON: %@", jsonError);
                        }
                        else
                        {
                            // Proceed to downloading each of the available files.
                            for (NSDictionary *photoMetadata in jsonData) {
                                NSString *filename = photoMetadata[@"filename"];
                                NSDate *createdOn = [NSDate date];

                                if (filename) {
                                    NSString *timestampStr = photoMetadata[@"timestamp"];
                                    if (timestampStr) {
                                        createdOn = [self.dateFormatter dateFromString:timestampStr];
                                    }

                                    [self downloadPhotoFromKiosk:filename createdOn:createdOn];
                                }
                            }
                        }
                    }
                }];
}

- (NSString *)photoStoreDirectory {
    NSString *path = [NSSearchPathForDirectoriesInDomains
            (NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return [path stringByAppendingPathComponent:@"Photos"];
}

- (void)newCameraRollPhoto:(NSNotification *)notification {
    DDLogVerbose(@"%s", __FUNCTION__);
}

- (void)refreshPrintablePhotosList:(NSNotification *)notification {
    DDLogVerbose(@"%s", __FUNCTION__);
    
    [self downloadPrintablePhotoMetadataFromKiosk];
    [self loadPhotos];

    [[NSNotificationCenter defaultCenter] postNotificationName:kAMRefreshPrintContentNotification
                                                        object:nil];
    
}

//
//  There's a new photo file on the disk.  We need to store the CoreData entity
//  for it.
//
- (void)newDiskPhoto:(NSNotification *)notification {
    DDLogVerbose(@"%s", __FUNCTION__);

    NSString *fileName = notification.object;
    // TODO - does coredata Photo exist?
}

//
//  Kick off a download from the touch screen controller of a new photo.  Track it in Core Data.
//
- (void)newRemoteCameraPhoto:(NSNotification *)notification {
    DDLogVerbose(@"%s", __FUNCTION__);

    AMStorageManager *store = [AMStorageManager sharedInstance];
    NSString *targetFileName = [notification.object objectAtIndex:1];
    DDLogVerbose(@"Download %@ from Touch Screen.", targetFileName);

    NSURL *url = [NSURL URLWithString:[NSString
            stringWithFormat:@"%@/Photos/%@",
                             networkTouchScreenBaseURL,
                             targetFileName]];

    NSString *targetFile = [[self photoStoreDirectory]
            stringByAppendingPathComponent:targetFileName];

    DDLogVerbose(@"Downloading %@ to %@", url, targetFile);

    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    request.downloadDestinationPath = targetFile;
    [request setCompletionBlock:^{
        // Use when fetching binary data
//            NSData *responseData = [request responseData];
        DDLogVerbose(@"New image saved to disk at %@", targetFile);

        // Create and store a Photo entity.
        Photo *photo = (Photo *)[NSEntityDescription
                insertNewObjectForEntityForName:@"Photo"
                         inManagedObjectContext:store.currentMOC];

        [photo setCreatedOn:[NSDate date]];
        [photo setToKioskOn:[NSDate date]];
        [photo setPhotoUrl:targetFile];
        [photo setRenderVersion:AMPhotoCurrentRenderVersion];

//        // Core Data relationships
//        CTKiosk *kiosk = [CTKiosk sharedInstance];
//        [kiosk.currentPhotoSession.entity addPhotosObject:photo];
//        [photo setSession:kiosk.currentPhotoSession.entity];

        // Then store.
        NSError *error = [store saveCoreData:photo];
        if (error) {
            DDLogVerbose(@"Error saving new photo entity: %@", [error localizedDescription]);
        }

        [[NSNotificationCenter defaultCenter]
                postNotificationName:AMCameraNewDiskPhotoNotification
                              object:targetFile];
    }];
    @weakify(request);
    [request setFailedBlock:^{
        @strongify(request);
        NSError *error = [request error];
        DDLogVerbose(@"Download error %@", error);
    }];
    [request startAsynchronous];
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)print:(UIViewController *)viewController dialogFocus:(UIView *)dialogFocus {
    DDLogVerbose(@"%s", __FUNCTION__);

//    _selectedPhoto = [self imageWithImage:_selectedPhoto scaledToSize:CGSizeMake(_selectedPhoto.size.width * 2, _selectedPhoto.size.height * 2)];
    
    if (_selectedPhoto) {
        // Scale the photo to 1.4wx1.0h (i.e. 4x6, 5x7).
        UIImage *photoToPrint = nil;
        UIImage *rawPhoto = _selectedPhoto;//[UIImage imageWithContentsOfFile:absoluteFileName];
        if (rawPhoto) {
            // Make a size that will include a header and footer.
            CGFloat heightFix = (CGFloat)(rawPhoto.size.width / 1.4);
            CGSize printSize = CGSizeMake(rawPhoto.size.width, heightFix);

            NSString *ratioModePref = [[NSUserDefaults standardUserDefaults] stringForKey:AMRatioModeSettingsKey];
            if (([ratioModePref isEqualToString:@"Aspect Fit"])||([ratioModePref length] == 0))
            {
                photoToPrint = [rawPhoto imageByAspectFit:printSize];
            }
            else if([ratioModePref isEqualToString:@"Aspect Fill"])
            {
                photoToPrint = [rawPhoto imageByAspectFill:printSize];
            }
            else
            {
                photoToPrint = [rawPhoto imageByScalingAndCroppingForSize:printSize];
            }
        }

        UIPrintInteractionController *printController = [UIPrintInteractionController sharedPrintController];
//        if  (printController && [UIPrintInteractionController canPrintURL:self.myPDFData] ) {
        if  (printController && photoToPrint && UIPrintInteractionController.isPrintingAvailable) {
            printController.delegate = self;
            printController.printFormatter.contentInsets = UIEdgeInsetsZero;
            printController.printFormatter.perPageContentInsets = UIEdgeInsetsZero;

            // Do we have a default printer?  This will be the last one that was
            // successfully used.
            NSString *defaultPrinterId = [[NSUserDefaults standardUserDefaults] objectForKey:kAMDefaultPrinterId];

            // Setup print info to answer as many questions as possible.
            UIPrintInfo *printInfo = [UIPrintInfo printInfo];
            if (defaultPrinterId) {
                printInfo.printerID = defaultPrinterId;
            }
//??            printInfo.jobName = photoSession.email ? photoSession.email : @"Anonymous";
            printInfo.duplex = UIPrintInfoDuplexNone;

            printInfo.orientation = UIPrintInfoOrientationLandscape;
        
            printInfo.outputType = UIPrintInfoOutputPhoto;

            
            if (![[[NSUserDefaults standardUserDefaults] valueForKey:@"Print Mode"] isEqualToString:@"Original Mode"])
            {
                printInfo.outputType = UIPrintInfoOutputGeneral;
                APLPrintPageRenderer *rnd = [[APLPrintPageRenderer alloc]init];
                
                rnd.imageToRender = _selectedPhoto;
                printController.printPageRenderer = rnd;

            }
            

            printController.printInfo = printInfo;
            printController.showsPageRange = NO;

            printController.printingItem = photoToPrint;

            void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) = ^(UIPrintInteractionController *pic, BOOL completed, NSError *error) {
//                self.content = nil;
                if (!completed && error) {
                    DDLogVerbose(@"FAILED! due to error in domain %@ with error code %ld",
                    error.domain, (long)error.code);

                    [TSMessage showNotificationInViewController:viewController
                                                          title:@"Print Error"
                                                       subtitle:[NSString stringWithFormat:@"There was a %@ error while printing for %@", [error localizedDescription], printInfo.jobName] image:nil
                                                           type:TSMessageNotificationTypeError
                                                       duration:60 callback:nil buttonTitle:nil buttonCallback:nil
                                                     atPosition:TSMessageNotificationPositionBottom canBeDismissedByUser:YES];
                } else {
                    if (completed) {
                        [TSMessage showNotificationInViewController:viewController
                                                              title:@"Print Complete"
                                                           subtitle:[NSString stringWithFormat:@"Successful Print for %@", printInfo.jobName] image:nil
                                                               type:TSMessageNotificationTypeSuccess
                                                           duration:5 callback:nil buttonTitle:nil buttonCallback:nil
                                                         atPosition:TSMessageNotificationPositionBottom canBeDismissedByUser:YES];

                        // Remember the successful printer
                        [[NSUserDefaults standardUserDefaults] setObject:printController.printInfo.printerID
                                                                  forKey:kAMDefaultPrinterId];
                    }
                            // else // this may have been cancelled

                            DDLogVerbose(@"Selected Printer ID: %@", printController.printInfo.printerID);
                }
            };

            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                [printController presentFromRect:dialogFocus.frame inView:viewController.view animated:YES
                               completionHandler:completionHandler];
                
//                [printController presentFromBarButtonItem:self.printBtn animated:YES
//                                                         completionHandler:completionHandler];
                
                
            }
            else
            {
                [printController presentAnimated:YES completionHandler:completionHandler];
            }
            
        }
    }
}

- (void)downloadPhotoFromKiosk:(NSString *)photoRelativeURL createdOn:(NSDate *)createdOn {

    DDLogVerbose(@"Download %@ from kiosk.", photoRelativeURL);
    BOOL haveFile = NO;

    if (!createdOn) {
        createdOn = [NSDate date];
    }

    AMStorageManager *store = [AMStorageManager sharedInstance];

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/Photos/%@",
                                       networkTouchScreenBaseURL,
                                       photoRelativeURL]];
    
    NSString *targetFile = [[self photoStoreDirectory] stringByAppendingPathComponent:photoRelativeURL];

    // Only download if it's not already here.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:targetFile]) {
        haveFile = YES;
    }

    Photo *photo = [store fetchPhoto:photoRelativeURL];
    if (haveFile)
    {
        DDLogVerbose(@"Skipping download, we already have it.");
        // Make sure it's stored in core data as well.
        if (!photo)
        {
            DDLogVerbose(@".. but it did not have photo object in the store, fixing ..");
            photo = [store storePhoto:targetFile createdOn:createdOn photoSession:nil ];
            if (photo)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:kAMNewPhotoObjectNotification
                                                                    object:targetFile];
            } else {
                //                DDLogVerbose(@"Error saving new photo entity: %@", [error localizedDescription]);
                DDLogVerbose(@"Error saving new photo entity: %@", photoRelativeURL);
            }
        }
    } else {
        DDLogVerbose(@"Downloading %@ to %@", url, targetFile);

        __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
        request.downloadDestinationPath = targetFile;
        [request setCompletionBlock:^{
            // Use when fetching binary data
            //            NSData *responseData = [request responseData];
            DDLogVerbose(@"New image saved to disk at %@", targetFile);

//            [[NSNotificationCenter defaultCenter] postNotificationName:AMCameraNewDiskPhotoNotification
//                                                                object:targetFile];
//
            // Store new file object.
            Photo *photo = [store storePhoto:targetFile createdOn:createdOn photoSession:nil];
            if (!photo) {
//                DDLogVerbose(@"Error saving new photo entity: %@", [error localizedDescription]);
                DDLogVerbose(@"Error saving new photo entity: %@", photoRelativeURL);
            }

            [[NSNotificationCenter defaultCenter]
                    postNotificationName:kAMNewPhotoObjectNotification
                                  object:targetFile];
        }];
        @weakify(request);
        [request setFailedBlock:^{
            @strongify(request);
            NSError *error = [request error];
            DDLogVerbose(@"Download error %@", error);
        }];
        [request startAsynchronous];
    }
}

@end
