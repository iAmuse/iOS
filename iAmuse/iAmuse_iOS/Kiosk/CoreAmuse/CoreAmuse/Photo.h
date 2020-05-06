//
//  Photo.h
//  iAmuse
//
//  Created by Roland Hordos on 2014-08-03.
//  Copyright (c) 2014 iAmuse Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PhotoSession;

@interface Photo : NSManagedObject

@property (nonatomic, retain) NSDate * createdOn;
@property (nonatomic, retain) NSNumber * failCount;
@property (nonatomic, retain) NSString * photoUrl;
@property (nonatomic, retain) NSString * renderVersion;
@property (nonatomic, retain) NSNumber * eventId;
@property (nonatomic, retain) NSNumber * layoutId;
@property (nonatomic, retain) NSDate * toCloudOn;
@property (nonatomic, retain) NSDate * toKioskOn;
@property (nonatomic, retain) NSManagedObject *selection;
@property (nonatomic, retain) PhotoSession *session;
@property (nonatomic, retain) NSNumber * defaultId;

@end
