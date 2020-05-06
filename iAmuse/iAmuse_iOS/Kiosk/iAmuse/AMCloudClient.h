//
// Created by Roland Hordos on 2013-07-01.
// Copyright (c) 2013 iAmuse Inc. All rights reserved.
//
//  Maintains invisible authentication to the cloud service from persistent
//  session uuid.  Application code should use a shared instance and call
//  connect either before using or on a connection error.
//
//  TODO - build an exponential backoff function that tracks the delay for a
//  given category since application start.
//

#import <Foundation/Foundation.h>

@interface AMCloudClient : NSObject {
//    BOOL authenticated;
}
@property BOOL authenticated;
@property (retain) NSString *sessionUuid;


+ (AMCloudClient *)instance;

- (void)connect;

- (BOOL)checkAuthentication;

- (void)authenticate;

- (void)activate:(NSManagedObjectContext *)managedObjectContext deviceId:(NSString *)deviceId;

@end