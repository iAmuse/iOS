//
//  AMUtility.h
//  iAmuse
//
//  Created by Roland Hordos on 2014-06-27.
//  Copyright (c) 2014 iAmuse Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AMUtility : NSObject

+ (void)enableAsyncLogging;

+ (void)DDLogErrorDetail:(NSError *)error track:(BOOL)track;

+ (NSString *)appVersion;
+ (NSString *)appNameAndVersionNumberDisplayString;
+ (NSString *)applicationDocumentsDirectory;

-(BOOL)deviceIdiomIsPhone;

//
//  Depending on the current state, returns the UIViewController for the view
//  presently being shown.
//
+ (UIViewController *)currentViewController;

//
//  Convenience function for date from numeric year, month, and day.
//
+ (NSDate *)dateWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day;

//
//  Truncate the time off of the incoming date and time, returning an NSDate at
//  midnight.
//
+ (NSDate *)extractDateOnly:(NSDate *)dateTime;

+ (UIImage *) imageWithView:(UIView *)view;
+ (UIImage *)captureView:(UIView *)view ;

@end
