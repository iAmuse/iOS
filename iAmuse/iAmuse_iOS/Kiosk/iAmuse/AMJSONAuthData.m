//
// Created by Roland Hordos on 2013-06-27.
// Copyright (c) 2013 iAmuse Inc. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "AMJSONAuthData.h"
#import "LRRestyRequest.h"


@implementation AMJSONAuthData {
}

@synthesize email, password;


/**
 The data to be used in the request body.
 */
- (NSData *)dataForRequest {

    if (!email || !password) {
        return nil;
    }

    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:email,
                                                                    @"email",password, @"password", nil];
    NSError *writeError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&writeError];
    if (writeError) {
        NSLog(@"JSON assembly error");
        return nil;
    }

//    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
// CAUTION, will log to device log    NSLog(@"JSON Output: %@", jsonString);

    return jsonData;
}


@end