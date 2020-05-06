//
//  OutputMedia.h
//  iAmuse
//
//  Created by Roland Hordos on 2014-08-03.
//  Copyright (c) 2014 iAmuse Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Photo, PhotoSession;

@interface OutputMedia : NSManagedObject

@property (nonatomic, retain) Photo *photo;
@property (nonatomic, retain) PhotoSession *session;

@end
