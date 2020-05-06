//
//  Kiosk.h
//  iAmuse
//
//  Created by Roland Hordos on 2014-08-03.
//  Copyright (c) 2014 iAmuse Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PhotoLayout;

@interface Kiosk : NSManagedObject

@property (nonatomic, retain) NSDate * activatedOn;
@property (nonatomic, retain) NSString * cloudKey;
@property (nonatomic, retain) NSString * cloudSessionKey;
@property (nonatomic, retain) NSString * contactLabel1;
@property (nonatomic, retain) NSString * contactLabel2;
@property (nonatomic, retain) NSString * deviceID;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * productId;
@property (nonatomic, retain) NSString * projectCode;
@property (nonatomic, retain) NSString * publicUsageLabel;
@property (nonatomic, retain) PhotoLayout *defaultLayout;
@property (nonatomic, retain) NSSet *photoLayouts;
@end

@interface Kiosk (CoreDataGeneratedAccessors)

- (void)addPhotoLayoutsObject:(PhotoLayout *)value;
- (void)removePhotoLayoutsObject:(PhotoLayout *)value;
- (void)addPhotoLayouts:(NSSet *)values;
- (void)removePhotoLayouts:(NSSet *)values;

@end
