//
// Created by Roland Hordos on 2013-06-27.
// Copyright (c) 2013 iAmuse Inc. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "LRRestyRequestPayload.h"
#import "AMJSONData.h"

@interface AMJSONAuthData : AMJSONData {
    NSString *email;
    NSString *password;
}
@property NSString *email;
@property NSString *password;

@end