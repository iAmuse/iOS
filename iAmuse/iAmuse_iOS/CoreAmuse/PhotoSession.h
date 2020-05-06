//
//  PhotoSession.h
//  iAmuse
//
//  Created by Roland Hordos on 2014-08-03.
//  Copyright (c) 2014 iAmuse Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Photo, PhotoLayout;

@interface PhotoSession : NSManagedObject

@property (nonatomic, retain) NSNumber * chosenNewsletter;
@property (nonatomic, retain) NSString * chosenPhotoUrl;
@property (nonatomic, retain) NSNumber * chosenPublic;
@property (nonatomic, retain) NSNumber * chosenPublicAgeAck;
@property (nonatomic, retain) NSString * chosenPublicScope;
@property (nonatomic, retain) NSDate * createdOn;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSNumber * failCount;
@property (nonatomic, retain) NSString * photoSessionId;
@property (nonatomic, retain) NSDate * toCloudOn;
@property (nonatomic, retain) PhotoLayout *layout;
@property (nonatomic, retain) NSSet *photos;
@property (nonatomic, retain) NSSet *selections;
@end

@interface PhotoSession (CoreDataGeneratedAccessors)

- (void)addPhotosObject:(Photo *)value;
- (void)removePhotosObject:(Photo *)value;
- (void)addPhotos:(NSSet *)values;
- (void)removePhotos:(NSSet *)values;

- (void)addSelectionsObject:(NSManagedObject *)value;
- (void)removeSelectionsObject:(NSManagedObject *)value;
- (void)addSelections:(NSSet *)values;
- (void)removeSelections:(NSSet *)values;

@end
