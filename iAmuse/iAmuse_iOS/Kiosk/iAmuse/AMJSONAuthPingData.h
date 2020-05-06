//
// Created by Roland Hordos on 2013-07-02.
// Copyright (c) 2013 iAmuse Inc. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import <LRResty/LRRestyRequestPayload.h>
#import "AMJSONData.h"


@interface AMJSONAuthPingData : AMJSONData {
    NSString *session_uuid;
}
@property NSString *session_uuid;
@end