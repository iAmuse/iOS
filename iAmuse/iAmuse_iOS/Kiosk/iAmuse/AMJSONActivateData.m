//
// Created by Roland Hordos on 2013-07-02.
// Copyright (c) 2013 iAmuse Inc. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <CoreData/CoreData.h>
#import <LRResty/LRRestyResponse.h>
#import "AMJSONActivateData.h"
#import "AMCloudClient.h"
#import "AMConstants.h"
#import "CTKiosk.h"
#import "Kiosk.h"


@implementation AMJSONActivateData

@synthesize productCode;
@synthesize deviceRole;
@synthesize deviceId;
@synthesize latitude;
@synthesize longitude;

@synthesize managedObjectContext;

/**
 The data to be used in the request body.
 */
- (NSData *)dataForRequest {
    /*
     This is used to add a JSON payload to the LRResty client call.
     */

    if (!productCode || !deviceRole || !deviceId) {
        return nil;
    }

    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:productCode, @"productCode",
                    deviceRole, @"deviceRole",
                    deviceId, @"deviceId",
                    latitude, @"latitude",
                    longitude, @"longitude",
                    nil];
    NSError *writeError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&writeError];
    if (writeError) {
        NSLog(@"JSON assembly error");
        return nil;
    }

    [self logJSON:jsonData forCategory:@"Activate"];

    return jsonData;
}

- (void)restClient:(LRRestyClient *)client receivedResponse:(LRRestyResponse *)res
{
    /*
     This is the delegate method that receives the data and optionally
     maps it locally into a CoreData entity.

        interim = {"Kiosk": {"id": self.key.urlsafe(),
                    "type": self.__class__.__name__,
                    "productCode": self.product_code,
                    "projectCode": self.project_code}}

     */

    NSString *jsonStr = [res asString];
    NSLog(@"Response %@", jsonStr);

    // parse the JSON string into a dictionary
    NSError *e = nil;
    NSDictionary *jsonData = [NSJSONSerialization
            JSONObjectWithData:[jsonStr
                    dataUsingEncoding:NSUTF8StringEncoding]

            options:NSJSONReadingMutableContainers error:&e];

    if (jsonData && [jsonData objectForKey:@"Kiosk"]) {
        // The shared kiosk needs an entity by now or we have to create one.
        CTKiosk *kiosk = [CTKiosk sharedInstance];
        if (!kiosk.entity) {
            // Create and configure a new instance of the Kiosk entity.
            kiosk.entity = (Kiosk *)[NSEntityDescription
                    insertNewObjectForEntityForName:@"Kiosk"
                             inManagedObjectContext:managedObjectContext];

            // Set initial default layout.
            if (kiosk.photoLayouts) {
//                PhotoLayout *defaultLayout = [kiosk.photoLayouts objectAtIndex:0];
                PhotoLayout *defaultLayout = nil;
                return;
                [kiosk.entity setDefaultLayout:defaultLayout];
            }
        }

        jsonData = [jsonData objectForKey:@"Kiosk"];
        NSString *cloudKey = [jsonData objectForKey:@"id"];
        NSString *productId = [jsonData objectForKey:@"productCode"];
        NSString *projectCode = [jsonData objectForKey:@"projectCode"];

        if (jsonData) {
            [kiosk.entity setActivatedOn:[NSDate date]];
            // The cloud key is the true activation key, and maps directly to the
            // urlsafe key for the Kiosk cloud entity.
            if (!(cloudKey == (id)[NSNull null] || cloudKey.length == 0)) {
                [kiosk.entity setCloudKey:cloudKey];
            }
            if (!(productId == (id)[NSNull null] || productId.length == 0)) {
                [kiosk.entity setProductId:productId];
            }
            if (!(projectCode == (id)[NSNull null] || projectCode.length == 0)) {
                [kiosk.entity setProjectCode:projectCode];
            }
        }

        AMCloudClient *cloud = [AMCloudClient instance];
        if (!(cloud.sessionUuid == (id)[NSNull null] || cloud.sessionUuid.length == 0)) {
            [kiosk.entity setCloudSessionKey:cloud.sessionUuid];
        }

        // Save the entity.
        NSError *error = nil;
        if (![managedObjectContext save:&error]) {
            // TODO Handle the error.
            NSLog(@"Error saving kiosk: %@", [error localizedDescription]);
        }
    } else {
        NSLog(@"Error parsing JSON: %@", e);
    }
}

@end
