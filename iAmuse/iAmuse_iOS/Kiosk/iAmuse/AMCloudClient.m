//
// Created by Roland Hordos on 2013-07-01.
// Copyright (c) 2013 iAmuse Inc. All rights reserved.
//


#import <LRResty/LRRestyResponse.h>
#import <LRResty/LRResty.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreData/CoreData.h>
#import "AMCloudClient.h"
#import "AMJSONAuthData.h"
#import "AMConstants.h"
#import "IGFuture.h"
#import "AMJSONAuthPingData.h"
#import "ASIHTTPRequest.h"
#import "AMJSONActivateData.h"
#import "CTKiosk.h"


@implementation AMCloudClient

@synthesize authenticated;
@synthesize sessionUuid;

+ (AMCloudClient *)instance {
    static AMCloudClient *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
//            [_instance setValue:@FALSE forKey:@"authenticated"];
//            [foo setValue:@YES forKey:@"bar"]
            _instance.authenticated = FALSE;
        }
    }

    return _instance;
}

- (void)connect {
    /*
     Our sessions persist across even application runs.  To minimize passing
     credentials, first check if we even need to.
     */
    if (![self checkAuthentication]) {
        [self authenticate];
    }
}

- (BOOL)checkAuthentication {
    /*
     We want a dictionary back with an 'authentication' key that says
     'Authenticated' or 'Required'.

     ReST call: /auth/jsonpassword with email and password
     data: { session_uuid: session_uuid }

     Though this call will execute asynchronously, we can use a Future to
     return it's results inline.
     */

    // There's a trivial scenario where we don't have a session reference at all.
    AMCloudClient *cloud = [AMCloudClient instance];
    if (!cloud.sessionUuid) {
        return FALSE;
    }

    // We want a BOOL but suspect an actual object is required.
    NSNumber *future = (NSNumber *) [[IGFuture alloc] initWithBlock:^id {

        // ReST Call (sync)
        NSString *uri = [[NSString alloc] initWithFormat: @"%@/%@", AMCloudServiceSecureBase, AMCloudServiceRestURIPing];
        NSLog(@"URI: %@", uri);

        NSString *jsonOutStr = [[NSString alloc] initWithFormat:
                @"{'session_uuid':'%@'}", self.sessionUuid];
        NSLog(@"jsonStr: %@", jsonOutStr);

        NSURL *url = [NSURL URLWithString:uri];
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
        [request addRequestHeader:@"Content-Type" value:@"application/json"];
        [request appendPostData:[jsonOutStr
                dataUsingEncoding:NSUTF8StringEncoding]];
        [request startSynchronous];
        NSError *error = [request error];
        if (error) {
            NSLog(@"Error during the service call: %@", error);
            return [NSNumber numberWithBool:FALSE];
        }


//        AMJSONAuthPingData *jsonPayload = [AMJSONAuthPingData new];
//        jsonPayload.session_uuid = self.sessionUuid;
//        LRRestyResponse *response = [[LRResty client] post:uri payload:jsonPayload];
//
//        NSLog(@"Response Raw: %@", response);
//
        NSString *jsonStr = [request responseString];
        NSLog(@"Response %@", jsonStr);

        // parse the JSON string into a dictionary
        NSError *e = nil;
        NSDictionary *jsonData = [NSJSONSerialization
                JSONObjectWithData:[jsonStr
                        dataUsingEncoding:NSUTF8StringEncoding]
                           options:NSJSONReadingMutableContainers error:&e];

        if (!jsonData) {
            NSLog(@"Error parsing JSON: %@", e);
            return @FALSE;// [NSNumber numberWithBool:@FALSE];
        } else {
            NSString *authentication = jsonData[@"authentication"];
            BOOL authenticatedNow = [authentication
                    isEqualToString:AMAuthenticationAuthenticated];

            // If the session is no longer valid and we think we're authenticated, we need to announce that.
            AMCloudClient *cloud = [AMCloudClient instance];
            if (cloud.authenticated != authenticatedNow) {
                [cloud setValue:[NSNumber numberWithBool:authenticatedNow]
                         forKey:@"authenticated"];
            }

            return [NSNumber numberWithBool:authenticatedNow];
        }
    }];

    return [future boolValue];
}



/**
*  Failed auth response example:
*   Response {"authentication": "Required", "messages": [{"message": "Authentication: Failed", "level": "error"}], "session_uuid": null}
*
*  Success example:
*   Response {"authentication": "Authenticated", "session_uuid": "88bf89f2-bdba-4108-8198-3c73df0b42c5"}
*/
- (void)authenticate {
    /*
     We want a dictionary back with an 'authentication' key that says
     'Authenticated' along with a 'session_uuid'.

     ReST call: /auth/jsonpassword with email and password
     data: {
        email: username,
        password: password
     }
     */

    // Get Username and Password
    // TODO - use NSUserDefaults with masked password

    NSLog(@"URL: %@", AMCloudServiceAuthURL);

    // ReST Call (async)
    AMJSONAuthData *jsonPayload = [AMJSONAuthData new];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    jsonPayload.email = [defaults stringForKey:kAMUserEmailUserDefaultsKey]; //@"kiosk@jurassicforest.com";
    jsonPayload.password = [defaults stringForKey:kAMPasswordUserDefaultsKey]; //@"1VHJ6[a0e3KlLipzWs";
//test fail    jsonPayload.password = @"1VHJ6[a0e3KlLipzW";

    [[LRResty client] post:AMCloudServiceAuthURL
                   payload:jsonPayload withBlock:
            ^(LRRestyResponse *response) {
                NSString *jsonStr = [response asString];
                NSLog(@"Response %@", jsonStr);

                // parse the JSON string into a dictionary
                NSError *e = nil;
                NSDictionary *jsonData = [NSJSONSerialization
                        JSONObjectWithData:[jsonStr
                                dataUsingEncoding:NSUTF8StringEncoding]
                                   options:NSJSONReadingMutableContainers error:&e];

                if (!jsonData) {
                    NSLog(@"Error parsing JSON: %@", e);
                } else {
                    NSString *authentication = jsonData[@"authentication"];
                    BOOL authenticatedNow = [authentication
                            isEqualToString:AMAuthenticationAuthenticated];

                    AMCloudClient *cloud = [AMCloudClient instance];
                    if (authenticatedNow) {
                        self.sessionUuid = jsonData[@"session_uuid"];
                    }
                    [cloud setValue:[NSNumber numberWithBool:authenticatedNow]
                                                      forKey:@"authenticated"];

                }
            }];

}

/*
 Send the following:
    ProductCode
    DeviceRole (mode)
    UDID of Activated Device
    Location lat,long

 Receive back on success:
    kiosk.id - urlsafe key to cloud kiosk

 Assumptions:
    CTKiosk shared instance.entity has already been attempted to have
    been loaded before activate is called.  The data delegate will go
    ahead and create a new entity if nil when we get the cloud kiosk.
 */
- (void)activate:(NSManagedObjectContext *)managedObjectContext deviceId:(NSString *)deviceId {

    // Get the GPS coordinates.
    // TODO - register for notification on new location here or in Kiosk

    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    CLLocation *location = [locationManager location];
    CLLocationCoordinate2D coordinates = [location coordinate];
    NSLog(@"Lat: %f", coordinates.latitude);
    NSLog(@"Long: %f", coordinates.longitude);

    // ReST Call (async).  Use a mediator object for JSON processing.
    AMJSONActivateData *activateData = [AMJSONActivateData new];
    activateData.managedObjectContext = managedObjectContext;

    CTKiosk *ctKiosk = [CTKiosk sharedInstance];
    activateData.productCode = ctKiosk.productCode;
    activateData.deviceRole = (ctKiosk.deviceMode == CTKioskDeviceModeCamera) ? AMDeviceModeStrCamera : AMDeviceModeStrTouchScreen;
    activateData.deviceId = deviceId;
    activateData.latitude = [NSNumber numberWithDouble:coordinates.latitude];
    activateData.longitude = [NSNumber numberWithDouble:coordinates.longitude];

    NSString *uri = [[NSString alloc] initWithFormat: @"%@/%@",
                    AMCloudServiceSecureBase, AMCloudServiceRestURIActivate];
    NSLog(@"URI: %@", uri);

    [[LRResty client] post:uri
                   payload:activateData
                  delegate:activateData];

}


@end