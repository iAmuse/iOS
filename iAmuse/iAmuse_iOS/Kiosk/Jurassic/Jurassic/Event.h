//
//  Event.h
//  iAmuse
//
//  Created by apple on 03/11/16.
//  Copyright © 2016 iAmuse Inc. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface Event : NSManagedObject

@property (nonatomic, retain) NSString * createdDate;
@property (nonatomic, retain) NSNumber * eventId;
@property (nonatomic, retain) NSString * eventLocation;
@property (nonatomic, retain) NSString * eventName;
@property (nonatomic, retain) NSString * eventStart;
@property (nonatomic, retain) NSString * updatedDate;
@property (nonatomic, retain) NSString * isDownload;
@property (nonatomic, retain) NSString * fovBottom;
@property (nonatomic, retain) NSString * fovTop;
@property (nonatomic, retain) NSString * fovLeft;
@property (nonatomic, retain) NSString * fovRight;
@property (nonatomic, retain) NSString * greenScreenCountdownDelay;
@property (nonatomic, retain) NSString * greenScreenDistance;
@property (nonatomic, retain) NSString * greenScreenHeight;
@property (nonatomic, retain) NSString * greenScreenWidth;
@property (nonatomic, retain) NSString * otherCountdownDelay;
@property (nonatomic, retain) NSString * otherIntractionTimout;
@property (nonatomic, retain) NSString * thankyouImage;
@property (nonatomic, retain) NSString * lookatTouchImage;
@property (nonatomic, retain) NSString * cameraImage;
@property (nonatomic, retain) NSString * watermarkImage;
@property (nonatomic, retain) NSString * watermarkImageUrl;
@property (nonatomic, assign) BOOL isSubscribed;

@end
