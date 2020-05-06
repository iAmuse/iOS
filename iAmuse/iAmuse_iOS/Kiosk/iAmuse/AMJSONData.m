//
// Created by Roland Hordos on 2013-07-02.
// Copyright (c) 2013 iAmuse Inc. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "AMJSONData.h"


@implementation AMJSONData

//@synthesize session_uuid;

/**
 The MIME type that will be used in the Content-Type header
 */
- (NSString *)contentTypeForRequest {
    return @"application/json";
}


- (void)logJSON:(NSData *)jsonData forCategory:(NSString *)category {

    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSLog(@"JSON Output: %@ %@", category, jsonString);
}

- (NSData *)dataForRequest {
    return nil;
}

@end