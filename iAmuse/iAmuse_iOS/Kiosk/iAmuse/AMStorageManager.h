//
//  AMStorageManager.h
//  iAmuse
//
//  Created by Roland Hordos on 2014-06-30.
//  Copyright (c) 2014 iAmuse Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Photo.h"
#import "OutputMedia.h"

@interface AMStorageManager : NSObject {
    // Core Data
    NSPersistentStoreCoordinator *_coreDataCoordinator;
    NSManagedObjectModel *managedObjectModel;
}

@property (nonatomic, strong, readonly, getter = mocMain) NSManagedObjectContext *mocMain;
@property (nonatomic, strong, readonly) NSManagedObjectContext *mocBackground;
@property (nonatomic, strong) NSString *fov_left;
@property (nonatomic, strong) NSString *fov_right;
@property (nonatomic, strong) NSString *fov_top;
@property (nonatomic, strong) NSString *fov_bottom;

+ (id)sharedInstance;

- (NSManagedObjectContext *)currentMOC;
- (NSError *)saveCoreData:(NSManagedObject *)model;
- (NSError *)saveCoreDataMOC:(NSManagedObjectContext *)moc;
- (NSError *)saveCoreDataMain;
- (NSError *)saveCoreDataBackground;
- (void)processPendingChanges;

- (Photo *)fetchPhoto:(NSString *)photoURL;
- (NSArray *)fetchPrintablePhotos;
- (NSArray *)fetchAllPhotosFromToday;

- (Photo *)storePhoto:(NSString *)photoURL createdOn:(NSDate *)createdOn photoSession:(PhotoSession *)photoSession;
- (OutputMedia *)addMediaSelection:(PhotoSession *)photoSession forPhoto:(Photo *)photo;

@end
