//
//  WebCommunication.m
//  iAmuse
//
//  Created by Himanshu on 2/5/15.
//  Copyright (c) 2015 iAmuse Inc. All rights reserved.
//

#import "WebCommunication.h"

#define kAcceptAndContentType_JSON  @"application/json"
#define kServiceRequestTypePost  @"POST"
#define kServiceRequestTypeGet   @"GET"

@implementation WebCommunication

@synthesize responseData;
@synthesize delegate;

- (id) initWithServiceType:(NSInteger)serviceType
{
    if((self = [super init]))
    {
        _service_type = serviceType;
    }
    return self;
}

#pragma mark - Methods for Webservice Calling

//Service Request//
- (void) callToServerRequestDictionary:(NSMutableDictionary *)requestDataDict onURL:(NSURL *)url WithBlock:(ResponseBlock)block
{
    self.returnBlock = block;
    
    NSError * error;
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:requestDataDict options:NSJSONWritingPrettyPrinted error:&error];
    NSString *requestJsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    [self CallToServerURL:url AndData:jsonData];
}

#pragma mark - method for calling server

- (void) CallToServerURL:(NSURL *)serverURL AndData:(NSData *)jsonData
{
    //NSLog(@"json string : %@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
    //NSLog(@"serverURL : %@", [serverURL absoluteString]);
    
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:serverURL];
    [request setHTTPMethod:kServiceRequestTypePost];
    [request setValue:kAcceptAndContentType_JSON forHTTPHeaderField:@"Content-Type"];
    [request setValue:kAcceptAndContentType_JSON forHTTPHeaderField:@"Accept"];
    [request setValue:@"DrEgBqmYbTXJqi2/a/H9O9YLYcRNjNTNn89BKpui1Y8" forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:jsonData];
    
    // create Asynchronous connection
    NSURLConnection * urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if (urlConnection)	
        self.responseData = [[NSMutableData alloc] init];
}

#pragma mark - NSURLConnectionDelegate Method (Asynchronous Connection)

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse*)response;
    
    [self setStatusCode:[httpResponse statusCode]];
    //set the Length of response data is 0
    [self.responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    //Received Data is append with responseData
    [self.responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error is : %@",[error description]);
        self.returnBlock(nil, self.statusCode, error, self);
        
        //        if([self.delegate respondsToSelector:@selector(DataDidFailWithError:)])
        //            [self.delegate DataDidFailWithError:error];
    }
    // Failed
    connection          =   nil;
    self.responseData   =   nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // Succeed
    //	NSLog(@"Connection successful... received %lu bytes of data", (unsigned long)[self.responseData length]);
    
    
    if (self.returnBlock)
    {
        NSLog(@"self.response string : %@",[[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding]);
        NSDictionary * responseDict = [NSJSONSerialization JSONObjectWithData:self.responseData options:NSJSONReadingMutableContainers error:nil];
        
        //        NSLog(@"response : %@",responseDict);
        self.returnBlock(responseDict, self.statusCode, nil, self);
    }
    
    // Cleanup
    connection          =   nil;
    self.responseData   =   nil;
}

-(NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return nil; // Don't cache
}

@end
