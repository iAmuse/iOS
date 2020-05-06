//
//  PhotoLayout.h
//  iAmuse
//
//  Created by Roland Hordos on 2014-08-03.
//  Copyright (c) 2014 iAmuse Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Kiosk, PhotoSession;

@interface PhotoLayout : NSManagedObject

@property (nonatomic, retain) NSString * background;
@property (nonatomic, retain) NSDecimalNumber * bottomCurtain;
@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSString * foreground;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * backUrl;
@property (nonatomic, retain) NSString * isDownload;
@property (nonatomic, retain) NSString * maskImageUrl;
@property (nonatomic, retain) NSString * isDownloadMaskImage;
@property (nonatomic, retain) NSNumber * eventId;
@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) NSNumber * defaultId;
@property (nonatomic, retain) NSNumber * scale;
@property (nonatomic, retain) NSNumber * xOffset;
@property (nonatomic, retain) NSNumber * yOffset;
@property (nonatomic, retain) NSNumber * cameraWidth;
@property (nonatomic, retain) NSNumber * cameraHieght;
@property (nonatomic, retain) Kiosk *kiosk;
@property (nonatomic, retain) Kiosk *layoutKiosk;
@property (nonatomic, retain) NSSet *sessions;
@property (nonatomic, retain) NSString * updatedDate;

@end

@interface PhotoLayout (CoreDataGeneratedAccessors)

- (void)addSessionsObject:(PhotoSession *)value;
- (void)removeSessionsObject:(PhotoSession *)value;
- (void)addSessions:(NSSet *)values;
- (void)removeSessions:(NSSet *)values;

@end
