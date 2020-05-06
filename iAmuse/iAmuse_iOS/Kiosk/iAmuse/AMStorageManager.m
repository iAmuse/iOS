//
//  AMStorageManager.m
//  iAmuse
//
//  Created by Roland Hordos on 2014-06-30.
//  Copyright (c) 2014 iAmuse Inc. All rights reserved.
//

#import "AMStorageManager.h"
#import "AMConstants.h"
#import "NSManagedObjectContext+RKAdditions.h"
#import "AMUtility.h"
#import "NSDate+DateTools.h"
#import "Photo.h"
#import "Kiosk.h"
#import "PhotoSession.h"
#import "OutputMedia.h"
#import "FOVData.h"

// for IP address
#include <ifaddrs.h>
#include <arpa/inet.h>

// Exceptions and Errors
NSString * const AMStoreErrorDomain = @"AMStoreErrorDomain";
const NSInteger AMStoreErrorWhileSavingUpdates = 1;
const NSInteger AMStoreErrorWhileReceivingUpdates = 2;

@implementation AMStorageManager

@synthesize mocMain = _mocMain;
@synthesize mocBackground = _mocBackground;

#pragma mark - Life Cycle

+ (id)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    DDLogVerbose(@"%s", __FUNCTION__);
    self = [super init];
    if (self)
    {
        _mocMain = nil;
        _mocBackground = nil;

//        touchlytic = [Touchlytic sharedInstance];

        // We handle NSUserDefaults, so for the case where they don't exist
        // we want defaults ready to go.
        [self setupUserDefaults];
        [self bind];
    }
    return self;
}

- (void)dealloc
{
    DDLogVerbose(@"%s", __FUNCTION__);

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//
//  Setup our signaling here.
//
- (void)bind
{
    DDLogVerbose(@"%s", __FUNCTION__);

    // Merge across threads to main thread and moc when core data changes occur.
    [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *notification)
                                                  {
                                                      NSManagedObjectContext *originatingMoc = notification.object;
                                                      NSManagedObjectContext *targetMoc = self.mocMain;

                                                      // We only act on notifications affecting our store.
                                                      if (originatingMoc.persistentStoreCoordinator == targetMoc.persistentStoreCoordinator) {
                                                          if (originatingMoc != targetMoc) {
                                                              // It's for our store but it's not our (main) context,
                                                              // so merge it with our main context on our main thread.
                                                              DDLogVerbose(@"MOC main Core Data merge");
                                                              [targetMoc performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:)
                                                                                          withObject:notification waitUntilDone:NO];
                                                          }
//                                        [moc performBlock:^(){
////                                            if( context.persistentStoreCoordinator == globalContext.persistentStoreCoordinator )
//                                            [moc performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:)
//                                                                            withObject:notification waitUntilDone:NO];
////                                            [moc mergeChangesFromContextDidSaveNotification:notification];
//                                        }];
                                                      } }];
}

#pragma mark - Settings

- (void)setupUserDefaults
{
    // Register setting defaults.
    NSMutableDictionary * defaults = [[NSMutableDictionary alloc] init];
//    [defaults setObject: [NSNumber numberWithBool: YES] forKey: @"width"];
    // Device
//    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
//    {
//        [defaults setObject:AMDeviceModeStrCamera forKey:AMDeviceModeSettingsKey];
//    }
//    else
//    {
//        [defaults setObject:AMDeviceModeStrTouchScreen forKey:AMDeviceModeSettingsKey];
//    }
    // Authentication
#ifdef JURASSIC
    [defaults setObject: @"info@jurassicforest.com" forKey: kAMUserEmailUserDefaultsKey];
    [defaults setObject: @"Stego2010!" forKey: kAMPasswordUserDefaultsKey];
#else
    [defaults setObject: @"mike.tanyi@remotelyyours.com" forKey: kAMUserEmailUserDefaultsKey];
    [defaults setObject: @"Fere!Gete2" forKey: kAMPasswordUserDefaultsKey];
#endif

    // Green Screen
    [defaults setObject: [NSNumber numberWithFloat:DEFAULT_SCREEN_WIDTH] forKey: SCREEN_WIDTH_KEY];
    [defaults setObject: [NSNumber numberWithFloat:DEFAULT_SCREEN_HEIGHT] forKey: SCREEN_HEIGHT_KEY];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"FOVData" inManagedObjectContext:self.currentMOC];
    [request setEntity:entity];
    [request setReturnsObjectsAsFaults:NO];
    NSError *errorFetch = nil;
    NSArray *array = [self.currentMOC executeFetchRequest:request error:&errorFetch];
    if (array.count > 0)
    {
      //  FOVData *event = [array firstObject];
        
      //  [defaults setObject: [NSNumber numberWithFloat:[event.fovLeft floatValue]] forKey: FOV_CURTAIN_KEY_LEFT];
      //  [defaults setObject: [NSNumber numberWithFloat:[event.fovRight floatValue]] forKey: FOV_CURTAIN_KEY_RIGHT];
      //  [defaults setObject: [NSNumber numberWithFloat:[event.fovTop floatValue]] forKey: FOV_CURTAIN_KEY_TOP];
      // [defaults setObject: [NSNumber numberWithFloat:[event.fovBottom floatValue]] forKey: FOV_CURTAIN_KEY_BOTTOM];
//        [defaults setObject: [NSNumber numberWithFloat:[event.greenScreenWidth floatValue]] forKey: SCREEN_WIDTH_KEY];
//        [defaults setObject: [NSNumber numberWithFloat:[event.greenScreenHeight floatValue]] forKey: SCREEN_HEIGHT_KEY];
    }

    [defaults setObject: [NSNumber numberWithFloat:DEFAULT_FOV_CURTAIN_PERCENT_LEFT] forKey: FOV_CURTAIN_KEY_LEFT];
    [defaults setObject: [NSNumber numberWithFloat:DEFAULT_FOV_CURTAIN_PERCENT_RIGHT] forKey: FOV_CURTAIN_KEY_RIGHT];
    [defaults setObject: [NSNumber numberWithFloat:DEFAULT_FOV_CURTAIN_PERCENT_TOP] forKey: FOV_CURTAIN_KEY_TOP];
    [defaults setObject: [NSNumber numberWithFloat:DEFAULT_FOV_CURTAIN_PERCENT_BOTTOM] forKey: FOV_CURTAIN_KEY_BOTTOM];

    // Touch Screen - default user interaction timeout between touches
   // [defaults setObject:[NSNumber numberWithFloat:AMIdleFeelTimeoutDefault] forKey:AMIdleFeelTimeoutKey];

    // Camera - default the target distance to the same as the screen
    [defaults setObject: [NSNumber numberWithFloat:DEFAULT_SCREEN_DISTANCE] forKey: SCREEN_DISTANCE_KEY];
    [defaults setObject: [NSNumber numberWithFloat:DEFAULT_SCREEN_DISTANCE] forKey: TARGET_DISTANCE_KEY];
    //[defaults setObject:[NSNumber numberWithFloat:AMCameraCountdownStepIntervalDefault] forKey:kAMCameraCountdownStepIntervalKey];
    
    NSString * ipAddress = [self getIPAddressofDevice];
    if(!([ipAddress length] > 8))
    {
        ipAddress = @"";
    }
    NSUserDefaults * userdefault = [NSUserDefaults standardUserDefaults];
    NSString * deviceModePref = [userdefault stringForKey:AMDeviceModeSettingsKey];
    
    NSString * cam = [userdefault stringForKey:CAMERA_IP_KEY];
    NSString * touch = [userdefault stringForKey:TOUCHSCREEN_IP_KEY];
    
    NSLog(@"Cam: %@\nTouch: %@",cam,touch);
    
    
    if ([deviceModePref isEqualToString:AMDeviceModeStrCamera])
    {
        [defaults setObject:ipAddress forKey:CAMERA_IP_KEY]; //192.168.2.43
        [defaults setObject:DEFAULT_TOUCHSCREEN_IP forKey:TOUCHSCREEN_IP_KEY];
    }
    else
    {
        
        [defaults setObject:DEFAULT_CAMERA_IP forKey:CAMERA_IP_KEY];
        [defaults setObject:ipAddress forKey:TOUCHSCREEN_IP_KEY]; // 192.168.2.43
    }
    
    //TODO: commented for changing device
//    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
//    {
//        [defaults setObject:ipAddress forKey:CAMERA_IP_KEY];
//        [defaults setObject:DEFAULT_TOUCHSCREEN_IP forKey:TOUCHSCREEN_IP_KEY];
//    }
//    else
//    {
//        [defaults setObject:DEFAULT_CAMERA_IP forKey:CAMERA_IP_KEY];
//        [defaults setObject:ipAddress forKey:TOUCHSCREEN_IP_KEY];
//    }
    
//    [defaults setObject:DEFAULT_CAMERA_IP forKey:CAMERA_IP_KEY];
//    [defaults setObject:DEFAULT_TOUCHSCREEN_IP forKey:TOUCHSCREEN_IP_KEY];
    [defaults setObject:kAMCameraShaderDefault forKey:kAMCameraShaderKey];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];

    // Tell us when application user settings change.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                    selector:@selector(userDefaultsDidChange:)
                                        name:NSUserDefaultsDidChangeNotification
                                      object:nil];
}

- (void)userDefaultsDidChange:(NSNotification *)notification
{
    DDLogVerbose(@"%s", __FUNCTION__);
}

- (NSString *)getIPAddressofDevice
{
    NSString * address = @"error";
    struct ifaddrs * interfaces = NULL;
    struct ifaddrs * temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0)
    {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL)
        {
            if(temp_addr->ifa_addr->sa_family == AF_INET)
            {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
                {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

#pragma mark - Core Data Essentials

//
//  Depending on the current thread return the correct Core Data MOC.
//
- (NSManagedObjectContext *)currentMOC
{
    @synchronized (self) {
        if ([NSThread isMainThread])
        {
            return self.mocMain;
        }
        else
        {
            return self.mocBackground;
        }
    }
}

//
//  Returns the persistent store coordinator for the application.
//
//  If the coordinator doesn't already exist, it is created and the application's
//  store added to it.
//
- (NSPersistentStoreCoordinator *)coreDataCoordinator
{
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
        if (_coreDataCoordinator != nil) {
            return _coreDataCoordinator;
        }
        
        // Create the coordinator and store
        
        _coreDataCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Data_Model.sqlite"];
        NSError *error = nil;
        NSString *failureReason = @"There was an error creating or loading the application's saved data.";
        if (![_coreDataCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
            // Report any error we got.
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
            dict[NSLocalizedFailureReasonErrorKey] = failureReason;
            dict[NSUnderlyingErrorKey] = error;
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        
        return _coreDataCoordinator;

 /*   DDLogVerbose(@"%s", __FUNCTION__);
    @synchronized (self) {
        if (_coreDataCoordinator == nil)
        {
            // Set up the store.  If there isn't one, start with the default store.
            NSString *storeDir = [AMUtility applicationDocumentsDirectory];
            
            NSString *coreDataFileName = [NSString stringWithFormat:@"%@.%@", kAMCoreDataStoreFileName, @"sqlite"];
            NSString *storePath = [storeDir stringByAppendingPathComponent:coreDataFileName];

            DDLogVerbose(@"Store path: %@", storePath);
            NSFileManager * fileManager = [NSFileManager defaultManager];
            if (![fileManager fileExistsAtPath:storePath])
            {
                NSString * defaultStorePath = [[NSBundle mainBundle] pathForResource:@"default" ofType:@"sqlite"];
                if (defaultStorePath)
                {
                    DDLogVerbose(@"Copying default.sqlite into iamuse.sqlite.");
                    [fileManager copyItemAtPath:defaultStorePath toPath:storePath error:NULL];
                }
            }
            NSURL * storeUrl = [NSURL fileURLWithPath:storePath];

            // Handle an upgrade if one is required.
            NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                    [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];

            NSError *error = nil;
            _coreDataCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
            if (![_coreDataCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                    configuration:nil
                                                              URL:storeUrl
                                                          options:options error:&error]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kAMReinstallWithReason
                                                                    object:@"The local Data Store cannot be recovered, or is from a version too old to upgrade."];
                return nil;
            }
        }
        return _coreDataCoordinator;
    }*/
}

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.rapidid.CoreDataSample" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectContext *)mocMain
{
    @synchronized (self) {
        NSPersistentStoreCoordinator *coordinator = nil;
        if (_mocMain == nil)
        {
            coordinator = [self coreDataCoordinator];

            if (coordinator != nil)
            {
                _mocMain = [NSManagedObjectContext new];
                [_mocMain setPersistentStoreCoordinator:coordinator];
            }
        }
        return _mocMain;
    }
}

//
//  Use the same PSC.  ReactiveCoreData likes this background context.
//
- (NSManagedObjectContext *)mocBackground
{
//    @synchronized (self) {
    if (_mocBackground == nil)
    {
        NSPersistentStoreCoordinator *coordinator = [self coreDataCoordinator];
        if (coordinator != nil)
        {
//            NSError *error = nil;
//            NSPersistentStore *persistentStore = [coordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error];
//            if (!persistentStore) {
//                [[NSApplication sharedApplication] presentError:error];
//                return nil;
//            }
            _mocBackground = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            [_mocBackground setPersistentStoreCoordinator:coordinator];
            [_mocBackground setUndoManager:nil];
//            if (setAsMain) {
//                [NSManagedObjectContext setMainContext:ctx];
//            }
            [_mocBackground save:NULL];

            [[NSNotificationCenter defaultCenter]
                    addObserverForName:NSManagedObjectContextDidSaveNotification
                                object:nil
                                 queue:nil
                            usingBlock:^(NSNotification *notification)
                            {
                                // We only act on notifications affecting our store.
                                NSManagedObjectContext *originatingMoc = notification.object;
                                NSManagedObjectContext *targetMoc = self.mocBackground;

                                if (originatingMoc.persistentStoreCoordinator == targetMoc.persistentStoreCoordinator) {
                                    if (originatingMoc != targetMoc) {
                                        // It's for our store but it's not our (background) context,
                                        // so merge it.
                                        [targetMoc performBlock:^(){
                                            DDLogVerbose(@"MOC background Core Data merge");
                                            [targetMoc mergeChangesFromContextDidSaveNotification:notification];
                                        }];
                                    }
                                }
                            }];
        }
    }
    return _mocBackground;
//    }
}

//
//  Returns the managed object model for the application.
//  If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
//
- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel == nil) {
        NSString *path = [[NSBundle mainBundle] pathForResource:kAMCoreDataStoreFileName
                                                         ofType:@"momd"];
        if (path) {
            NSURL *momURL = [NSURL fileURLWithPath:path];
            managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
        } else {
            managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
        }
    }

    return managedObjectModel;
}

//
//  Save Core Data pending changes for the given context of the optional model,
//  or for the current context only.
//
//  Return void if we saved without error, or return the error.
//
- (NSError *)saveCoreData:(NSManagedObject *)model {
    DDLogVerbose(@"%s", __FUNCTION__);

    // Visitor screening.
    NSManagedObjectContext *moc = [self currentMOC];
    if (model) {
        moc = model.managedObjectContext;
        if (![model.managedObjectContext isEqual:moc]) {
            DDLogWarn(@"The caller is trying to save a model from the wrong context for this thread, flipping it to the current MOC");
            model = [moc objectWithID:model.objectID]; // vs existingObjectWithID
        }
    } else {
        moc = self.currentMOC;
    }
    // Clean.

    if ([NSThread isMainThread]) {
        [self.mocMain processPendingChanges];
    } else {
        [self.mocBackground processPendingChanges];
    }

    // This is promising for relieving merge conflicts.  The biggest challenge
    // doesn't seem so much to be the concurrency management, it's the object
    // version management.
    // https://developer.apple.com/library/mac/documentation/Cocoa/Reference/CoreDataFramework/Classes/NSManagedObjectContext_Class/NSManagedObjectContext.html#//apple_ref/doc/uid/TP30001182-BAJFCECB
    if ([model hasChanges]) {
        DDLogVerbose(@"Model has changes, calling refreshObject on MOC");
        [moc refreshObject:model mergeChanges:YES];
    }

    return [self saveCoreDataMOC:moc];
}

- (NSError *)saveCoreDataMOC:(NSManagedObjectContext *)moc {
    DDLogVerbose(@"%s", __FUNCTION__);
    if (![moc hasChanges]) return nil;

    @synchronized (self) {
        NSError *error = nil;
        if (moc != nil) {
            if ([moc hasChanges] && ![moc save:&error]) {
                [AMUtility DDLogErrorDetail:error track:NO];

                // Simply notify the user of this problem.
                NSDictionary *userInfo = @{
                        NSLocalizedDescriptionKey: NSLocalizedString(@"Could not save changes", nil),
                        NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(kAMDefaultErrorResolutionSuggestion, nil)
                };
                error = [NSError errorWithDomain:AMStoreErrorDomain
                                            code:AMStoreErrorWhileSavingUpdates
                                        userInfo:userInfo];

//                [[Touchlytic sharedInstance] trackError:error];
                [[NSNotificationCenter defaultCenter] postNotificationName:kAMPresentErrorNotification object:error];
            }
        }
        // if moc actually is nil, well there's nothing to save
        return error;
    }
}

- (NSError *)saveCoreDataMain {
    DDLogVerbose(@"%s", __FUNCTION__);
    return [self saveCoreDataMOC:self.mocMain];
}

- (NSError *)saveCoreDataBackground {
    DDLogVerbose(@"%s", __FUNCTION__);
    return [self saveCoreDataMOC:self.mocBackground];
}

- (void)processPendingChanges {
    // This is primarily intended for the background MOC as the default behaviour
    // is different from the main MOC as Apple says here:
    // https://developer.apple.com/library/mac/documentation/Cocoa/Reference/CoreDataFramework/Classes/NSManagedObjectContext_Class/NSManagedObjectContext.html#//apple_ref/doc/uid/TP30001182-BAJFHHCB
    [self.mocBackground processPendingChanges];
}

//
//  Returns Photos taken today, via their OutputMedia entries.
//
- (NSArray *)fetchPrintablePhotos {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"OutputMedia"
                                              inManagedObjectContext:self.currentMOC];
    [request setEntity:entity];

    // We only want items from today
    NSDate *beginningOfToday = [AMUtility extractDateOnly:[NSDate date]];
    NSDate *endOfToday = [beginningOfToday dateByAddingDays:1];
    NSPredicate *startDatePredicate = [NSPredicate predicateWithFormat:@"photo.toKioskOn >= %@", beginningOfToday];
    NSPredicate *endDatePredicate =  [NSPredicate predicateWithFormat:@"photo.toKioskOn <= %@", endOfToday];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[startDatePredicate, endDatePredicate]];
    [request setPredicate:predicate];

    NSSortDescriptor *sortDateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"photo.toKioskOn" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObjects:sortDateDescriptor, nil]];

    NSError *error;
    NSArray *todaysMediaSelections = [self.currentMOC executeFetchRequest:request error:&error];
    
    NSMutableArray *printablePhotos = [NSMutableArray arrayWithCapacity:todaysMediaSelections.count];
    for (OutputMedia *mediaSelection in todaysMediaSelections) {
        [printablePhotos addObject:mediaSelection.photo];
    }
    return printablePhotos;
}

- (NSArray *)fetchAllPhotosFromToday {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Photo"
                                              inManagedObjectContext:self.currentMOC];
    [request setEntity:entity];
    
    // We only want items from today
    NSDate *beginningOfToday = [AMUtility extractDateOnly:[NSDate date]];
    NSDate *endOfToday = [beginningOfToday dateByAddingDays:1];
    NSPredicate *startDatePredicate = [NSPredicate predicateWithFormat:@"toKioskOn >= %@", beginningOfToday];
    NSPredicate *endDatePredicate =  [NSPredicate predicateWithFormat:@"toKioskOn <= %@", endOfToday];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[startDatePredicate, endDatePredicate]];
    [request setPredicate:predicate];
    
    NSSortDescriptor *sortDateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"toKioskOn" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObjects:sortDateDescriptor, nil]];
    
    NSError *error;
    return [self.currentMOC executeFetchRequest:request error:&error];
}

//
//  Thread safe fetch of Photo.
//
- (Photo *)fetchPhoto:(NSString *)photoURL
{
    DDLogVerbose(@"%s", __FUNCTION__);

    NSString *entityName = @"Photo";

    NSError *error = nil;
    NSManagedObjectContext *moc = [self currentMOC];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *description = [NSEntityDescription entityForName:entityName
                                                   inManagedObjectContext:moc];
    [request setEntity:description];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"photoUrl == %@", photoURL];
    [request setPredicate:predicate];

    error = nil;
    Photo *model = nil;
    NSArray *array = [moc executeFetchRequest:request error:&error];
    if ([array count] > 0) {
        model = array[0];
    }
    return model;
}


- (Photo *)storePhoto:(NSString *)photoURL createdOn:(NSDate *)createdOn photoSession:(PhotoSession *)photoSession {

    NSString * entityName = @"Photo";

    // Visitor screening - get everyone on the current context.
    NSManagedObjectContext * moc = [self currentMOC];
    if (photoSession)
    {
        if (![photoSession.managedObjectContext isEqual:moc])
        {
            photoSession = (PhotoSession *)[moc objectWithID:photoSession.objectID]; // vs existingObjectWithID
        }
    }
    // Clean.

    @synchronized(self) {   // avoid duplicate inserts
        Photo * model = [self fetchPhoto:photoURL];
        if (!model)
        {
            // Create and store a Photo entity.
            model = (Photo *)[NSEntityDescription
                    insertNewObjectForEntityForName:entityName
                             inManagedObjectContext:self.currentMOC];

            [model setCreatedOn:createdOn];
            [model setToKioskOn:createdOn];
            [model setPhotoUrl:photoURL];
            [model setRenderVersion:AMPhotoCurrentRenderVersion];

            // Core Data relationships
            if (photoSession)
            {
                [photoSession addPhotosObject:model];
                [model setSession:photoSession];
            }

            // Commit right away to minimize merge issues.
            NSError * error = [self saveCoreData:model];
            if (error)
            {
                // error returned
                model = nil;
            }
        }
        return model;
    }
}

- (OutputMedia *)addMediaSelection:(PhotoSession *)photoSession forPhoto:(Photo *)photo {
    
    NSString * entityName = @"OutputMedia";
    
    // Visitor screening - get everyone on the current context.
    NSManagedObjectContext * moc = [self currentMOC];
    if (photoSession)
    {
        if (![photoSession.managedObjectContext isEqual:moc])
        {
            photoSession = (PhotoSession *)[moc objectWithID:photoSession.objectID]; // vs existingObjectWithID
        }
    }
    else
    {
        return nil;
    }
    
    if (photo)
    {
        if (![photo.managedObjectContext isEqual:moc])
        {
            photo = (Photo *)[moc objectWithID:photo.objectID]; // vs existingObjectWithID
        }
    }
    else
    {
        return nil;
    }
    // Clean.
    
    @synchronized(self) {   // avoid duplicate inserts
        OutputMedia * model = nil;
        
        // This photo may already be in the selected for the session if the visitor chose back and altered selections.
        NSPredicate * alreadySelectedPredicate = [NSPredicate predicateWithFormat:@"photo.photoUrl = '%@'", photo.photoUrl];
        NSArray * alreadySelected = [photoSession.selections.allObjects filteredArrayUsingPredicate:alreadySelectedPredicate];
        if (alreadySelected.count == 0)
        {
            // Create and store a model.
            model = (OutputMedia *)[NSEntityDescription
                              insertNewObjectForEntityForName:entityName
                              inManagedObjectContext:self.currentMOC];
            
            // Core Data relationships
            if (photoSession)
            {
                [photoSession addSelectionsObject:model];
                [model setSession:photoSession];
            }
            if (photo)
            {
                [photo setSelection:model];
                [model setPhoto:photo];
            }
            
            // Commit right away to minimize merge issues.
            NSError * error = [self saveCoreData:model];
            if (error)
            {
                // error returned
                model = nil;
            }
        }
        return model;
    }
}

@end
