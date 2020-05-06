//
// Created by Roland Hordos on 2013-07-02.
// Copyright (c) 2013 iAmuse Inc. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import <LRResty/LRRestyClientResponseDelegate.h>
#import "LRRestyRequestPayload.h"
#import "AMJSONData.h"


@interface AMJSONActivateData : AMJSONData <LRRestyClientResponseDelegate> {
    NSString *productCode;
    NSString *deviceRole;
    NSString *deviceId;
    NSNumber *latitude;
    NSNumber *longitude;
}
@property NSString *productCode;
@property NSString *deviceRole;
@property NSString *deviceId;
@property NSNumber *latitude;
@property NSNumber *longitude;

@property NSManagedObjectContext *managedObjectContext; // CoreData context

- (void)restClient:(LRRestyClient *)client receivedResponse:(LRRestyResponse *)res;

@end