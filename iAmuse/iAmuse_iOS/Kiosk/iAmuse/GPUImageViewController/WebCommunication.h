//
//  WebCommunication.h
//  iAmuse
//
//  Created by Himanshu on 2/5/15.
//  Copyright (c) 2015 iAmuse Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WebCommunication;

@protocol webCommunicationDelegate <NSObject>

//Declare Protocol method. it is called when data downloading is finished
- (void)dataDidFinishedWithDictionary:(NSDictionary *)responseDict AndServiceType:(NSInteger)serviceType;
- (void) DataDidFailWithError:(NSError *)error;

@end

typedef void(^ResponseBlock)(NSDictionary * response, NSInteger status_code, NSError *error, WebCommunication * webComm);

@interface WebCommunication : NSObject

@property (nonatomic, assign) NSInteger service_type;
@property (nonatomic, assign) NSInteger statusCode;

//property of Delegate
@property (assign, nonatomic) id <webCommunicationDelegate> delegate;

@property (copy, nonatomic) ResponseBlock returnBlock;
// URLConnection and Downloading Properties
@property (nonatomic, retain) NSMutableData * responseData;

//initialization
- (id) initWithServiceType:(NSInteger)serviceType;

#pragma mark - Methods For Service Call
//Service Request//
- (void) callToServerRequestDictionary:(NSMutableDictionary *)requestDataDict onURL:(NSURL *)url WithBlock:(ResponseBlock)block;
@end
