//
//  CTCTKioskHTTPConnection.m
//  Jurassic
//
//  This is our ReST interface to the Camera.
//
//
//  Created by Roland Hordos on 2013-05-30.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTCameraHTTPConnection.h"
#import "HTTPDynamicFileResponse.h"
#import "HTTPResponseTest.h"
#import "HTTPLogging.h"
#import "AMConstants.h"
#import "HTTPErrorResponse.h"
#import "HTTPDataResponse.h"
#import "AMPrintKiosk.h"
#import "Photo.h"
#import "AMUtility.h"

// Log levels: off, error, warn, info, verbose
// Other flags: trace
static const int httpLogLevel = HTTP_LOG_FLAG_TRACE; // HTTP_LOG_LEVEL_WARN | 


@interface CTCameraHTTPConnection ()
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@end


@implementation CTCameraHTTPConnection

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        _dateFormatter.dateFormat = kAMJSONTimestampFormat;
    }
    return _dateFormatter;
}


- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    DDLogInfo(@"method %@ and URI %@", method, path);
    
    
	// Use HTTPConnection's filePathForURI method.
	// This method takes the given path (which comes directly from the HTTP request),
	// and converts it to a full path by combining it with the configured document root.
	//
	// It also does cool things for us like support for converting "/" to "/index.html",
	// and security restrictions (ensuring we don't serve documents outside configured document root folder).
	
	NSString * filePath = [self filePathForURI:path];
	
	// Convert to relative path
	
	NSString * documentRoot = [config documentRoot];
	
	if (![filePath hasPrefix:documentRoot])
	{
		// Uh oh.
		// HTTPConnection's filePathForURI was supposed to take care of this for us.
		return nil;
	}
	
    /*
    // Route:
    //   /index.html
    //   /unittest.html
        /photosession/key?background=fileuri
    //
    */

    // First patter, consider a ReST call.
    [self extractUriEntities:path];

    NSArray * master = [self firstRestEntity];
    if (master)
    {
        NSString * entityType = [master objectAtIndex:0];
        NSLog(@"Entity Type %@", entityType);
        NSString * entityKey = nil;
        if ([master count] > 1)
        {
            entityKey = [master objectAtIndex:1];
            NSLog(@"Entity Key %@", entityKey);
        }

        if ([entityType isEqualToString:@"photosession"])
        {
            if (entityKey && args)
            {
                // This call is
                NSMutableArray * masterWithArgs = [[NSMutableArray alloc]
                        initWithArray:master];
                [masterWithArgs addObject:args];
                [[NSNotificationCenter defaultCenter]
                        postNotificationName:AMCameraResumePhotoSessionNotification
                        object:masterWithArgs];
                return [[HTTPErrorResponse alloc] initWithErrorCode:200];
            }
        }
        else if ([entityType isEqualToString:@"stop"])
        {
            NSLog(@"Send notification for STOP");

            [[NSNotificationCenter defaultCenter]
                    postNotificationName:AMCameraStopPhotoSessionNotification
                                  object:nil];
            return [[HTTPErrorResponse alloc] initWithErrorCode:200];
        }
        
        
        
        else if ([entityType isEqualToString:@"ajay"])
        {
            NSLog(@"Send notification for STOP");
            
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"checkingAction"
             object:nil];
            return [[HTTPErrorResponse alloc] initWithErrorCode:200];
        }
        
        else if ([entityType isEqualToString:@"backtoeventa"])
        {
            NSLog(@"Send notification for STOP");
            
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"gotoThankYou"
             object:nil];
            return [[HTTPErrorResponse alloc] initWithErrorCode:200];
        }
        
        
        
        else if ([entityType isEqualToString:@"subscriptionUpdate"])
        {
            NSLog(@"Send notification for subscriptionUpdate");
            
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"subscriptionUpdate"
             object:nil];
            return [[HTTPErrorResponse alloc] initWithErrorCode:200];
        }
        
        
        
      
        else if ([entityType isEqualToString:@"backtoevent"])
        {
            NSLog(@"Send notification for backToEvent");
            
            [[NSNotificationCenter defaultCenter]
             postNotificationName:AMBackToEventNotification
             object:nil];
            return [[HTTPErrorResponse alloc] initWithErrorCode:200];
        }
        else if ([entityType isEqualToString:@"removelookatipad"])
        {
            NSLog(@"Send notification for REMOVELOOKATIPAD");

            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"removeLookAtiPadNotification"
             object:nil];
            return [[HTTPErrorResponse alloc] initWithErrorCode:200];
        }
        else if ([entityType isEqualToString:@"test"])
        {
            // A simple event creation call to kick off a test notification.
            [[NSNotificationCenter defaultCenter]
                    postNotificationName:AMRunTestNotification object:nil];
            return [[HTTPErrorResponse alloc] initWithErrorCode:200];
        }
        else if ([entityType isEqualToString:@"thanks"])
        {
            [[NSNotificationCenter defaultCenter]
                    postNotificationName:AMShowThankYouNotification object:nil];
            return [[HTTPErrorResponse alloc] initWithErrorCode:200];
        }
        else if ([entityType isEqualToString:@"refresh"])
        {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:AMRefreshDataNotification object:nil];
            return [[HTTPErrorResponse alloc] initWithErrorCode:200];
        }
        else if ([entityType isEqualToString:@"printablephotos"])
        {
            // Get a list of photos that are eligible for downloading.
            NSData * responseData = nil;
            CTKiosk * kiosk = [CTKiosk sharedInstance];
            NSArray * printablePhotosMetaData = [kiosk getPrintablePhotosMetaData];
            NSMutableArray * interimJSONList = [NSMutableArray arrayWithCapacity:0];
            for (Photo * photo in printablePhotosMetaData)
            {
//                NSMutableDictionary *interimJSONDetail = [NSMutableDictionary dictionaryWithCapacity:0];
                
                if ([photo isKindOfClass:[Photo class]])
                {
                    NSString * serverFileName = [photo.photoUrl lastPathComponent];
                    NSDictionary * interimPhotoJSON = @{
                                                        @"filename": serverFileName,
                                                        @"timestamp": [self.dateFormatter stringFromDate:photo.createdOn]
                                                        };
                    [interimJSONList addObject:interimPhotoJSON];

                }
            }

            NSError * jsonError;
            responseData = [NSJSONSerialization dataWithJSONObject:interimJSONList options:NSJSONWritingPrettyPrinted error:&jsonError];
            if (jsonError)
            {
                [AMUtility DDLogErrorDetail:jsonError track:NO];
                return [[HTTPErrorResponse alloc] initWithErrorCode:500];
            }
//                responseData = [@"<html><body>Correct<body></html>" dataUsingEncoding:NSUTF8StringEncoding];

            return [[HTTPDataResponse alloc] initWithData:responseData];
        }
        else if ([entityType isEqualToString:@"photo"])
        {
            // ReST call for photos API.
            // If we're a Touch Screen this informs us the camera has a new
            // photo for us to download.
            if (entityKey)
            {
                NSLog(@"entity key name = %@",entityKey);
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:AMCameraNewRemotePhotoNotification object:master];
                return [[HTTPErrorResponse alloc] initWithErrorCode:200];
            }
        }
        else if ([entityType isEqualToString:@"photos"])
        {
            // Not a ReST call so much, but a download request for a photo.
            NSString *targetFile = [[self photoStoreDirectory]
                    stringByAppendingPathComponent:entityKey];

//            NSString *targetFile = [self filePathForURI:path];
            NSLog(@"Download request for %@", targetFile);
            return [[HTTPAsyncFileResponse alloc] initWithFilePath:targetFile
                                                     forConnection:self];
        }

    }

    // Second pattern, test the relative path directly (sans query string)
    NSString *relativePath = [filePath substringFromIndex:[documentRoot length]];
    if ([relativePath isEqualToString:@"/index.html"])
    {
        HTTPLogVerbose(@"%@[%p]: Serving up dynamic content", THIS_FILE, self);

        // Replace template fields.
        NSString *currentTime = [[NSDate date] description];

        NSMutableDictionary *replacementDict = [NSMutableDictionary dictionaryWithCapacity:5];

        [replacementDict setObject:currentTime  forKey:@"TIME"];
        [replacementDict setObject:@"A"         forKey:@"ALPHABET"];
        [replacementDict setObject:@"  QUACK  " forKey:@"QUACK"];

        HTTPLogVerbose(@"%@[%p]: replacementDict = \n%@", THIS_FILE, self, replacementDict);

        return [[HTTPDynamicFileResponse alloc] initWithFilePath:[self filePathForURI:path] forConnection:self separator:@"%%"
                         replacementDictionary:replacementDict];
    }
    else if ([relativePath isEqualToString:@"/unittest.html"])
    {
        HTTPLogVerbose(@"%@[%p]: Serving up HTTPResponseTest (unit testing)", THIS_FILE, self);

        return [[HTTPResponseTest alloc] initWithConnection:self];
    }

    NSLog(@"Unhandled URI");

    return [super httpResponseForMethod:method URI:path];
}

- (void)extractUriEntities:(NSString *)requestURI
{
    /*
     Parses the url with a really simple ReST presumption that we have an url
      that looks like:

            /entity_type/key-or-action/entity_type/key-or-action ..

      with query key value args as

            ?/& param=value
     */
    entities = [[NSMutableArray alloc] init];
    NSArray *splitQueryString = [requestURI componentsSeparatedByString:@"?"];
    NSString *queryString = nil;
    switch ([splitQueryString count])
    {
        case 0:
            return;
        case 2:
            queryString = [splitQueryString objectAtIndex:1];
            break;
        default:
            break;
    }

    NSString *segmentsString = [splitQueryString objectAtIndex:0];

    // array of segments returned sans slash
    NSArray *segments = [segmentsString componentsSeparatedByString:@"/"];
    NSInteger length = [segments count];

    NSString *entityKey = nil;
    NSString *entityType = nil;
//    NSString *lastEntityType = nil;
    uint cursor = 1;    // The first item is an empty string due to the leading slash

    while (cursor < length)
    {
        entityType = [segments[cursor] lowercaseString];

        entityKey = (cursor + 1 < length) ? segments[cursor + 1] : nil;

        if ([entityKey isEqualToString:@"undefined"])
        {
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:[NSString stringWithFormat:@"Invalid model store key value [%@]", entityKey]
                                         userInfo:nil];
        }

        if (entityKey.length == 0)
        {
            entityKey = nil;
        }

        if (entityKey)
        {
            [entities addObject:[[NSArray alloc] initWithObjects:entityType,
                            entityKey, nil]];
        }
        else
        {
            [entities addObject:[[NSArray alloc] initWithObjects:entityType, nil]];
        }

        cursor = cursor + 2;
    }

    // Parse query string parameters  ex: hello=world&foo=bar
    if (queryString)
    {
        args = [[NSMutableDictionary alloc] init];
        NSArray *arrParameters = [queryString componentsSeparatedByString:@"&"];
        for (int i = 0; i < [arrParameters count]; i++)
        {
            NSArray *arrKeyValue = [[arrParameters objectAtIndex:i] componentsSeparatedByString:@"="];
            if ([arrKeyValue count] >= 2)
            {
                NSMutableString *strKey = [NSMutableString stringWithCapacity:0];
                [strKey setString:[[[arrKeyValue objectAtIndex:0] lowercaseString] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
                NSMutableString *strValue   = [NSMutableString stringWithCapacity:0];
                [strValue setString:[[[arrKeyValue objectAtIndex:1]  stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
                if (strKey.length > 0)
                    [args setObject:strValue forKey:strKey];
            }
        }
        NSLog(@"Parameters: %@", args);
    }
    else
    {
        args = nil;
    }
}

- (NSArray *)firstRestEntity
{
    /*
     Returns an array [entityType, entityKey]
     */
    if ([entities count] > 0)
    {
        return [entities objectAtIndex:0];
    }
    return nil;
}

- (NSString *)photoStoreDirectory
{
    NSString * storePath = [NSSearchPathForDirectoriesInDomains
            (NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return [storePath
            stringByAppendingPathComponent:AMHttpPhotoStoreUriComponent];
}



@end
