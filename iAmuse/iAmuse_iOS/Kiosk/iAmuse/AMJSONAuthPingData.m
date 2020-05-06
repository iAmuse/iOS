//
// Created by Roland Hordos on 2013-07-02.
// Copyright (c) 2013 iAmuse Inc. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "AMJSONAuthPingData.h"


@implementation AMJSONAuthPingData

@synthesize session_uuid;


/**
 The data to be used in the request body.
 */
- (NSData *)dataForRequest {

    if (!session_uuid) {
        return nil;
    }

    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:session_uuid, @"session_uuid", nil];
    NSError *writeError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&writeError];
    if (writeError) {
        NSLog(@"JSON assembly error");
        return nil;
    }

//    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    return jsonData;
}


@end