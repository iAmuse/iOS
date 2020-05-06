//
// Created by Roland Hordos on 2013-07-02.
// Copyright (c) 2013 iAmuse Inc. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import <LRResty/LRRestyRequestPayload.h>


@interface AMJSONData : NSObject  <LRRestyRequestPayload> {
//    NSString *session_uuid;
}
//@property NSString *session_uuid;


- (void)logJSON:(NSData *)jsonData forCategory:(NSString *)category;

@end