//
//  AMUtility.m
//  iAmuse
//
//  Created by Roland Hordos on 2014-06-27.
//  Copyright (c) 2014 iAmuse Inc. All rights reserved.
//

#import "AMUtility.h"
#import "DDTTYLogger.h"

@implementation AMUtility

#pragma mark - Logging

+ (void)enableAsyncLogging
{
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
}

+ (void)DDLogErrorDetail:(NSError *)error track:(BOOL)track
{
//    if (track) {
//        [[Touchlytic sharedInstance] trackError:error];
//    } else {
    DDLogError(@"Error: (code %ld) %@ %@ %@",
        (long) [error code],
        [error localizedDescription],
        [error localizedFailureReason],
        [error userInfo]);
//    }
}

+ (NSString *)appVersion
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *majorVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *minorVersion = [infoDictionary objectForKey:@"CFBundleVersion"];

    return [NSString stringWithFormat:@"%@ (%@)", majorVersion, minorVersion];
}

+ (NSString *)appNameAndVersionNumberDisplayString
{
    NSDictionary * infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString * appDisplayName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
    NSString * majorVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString * minorVersion = [infoDictionary objectForKey:@"CFBundleVersion"];

    return [NSString stringWithFormat:@"%@, Version %@ (%@)", appDisplayName, majorVersion, minorVersion];
}

+ (NSString *)applicationDocumentsDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

-(BOOL)deviceIdiomIsPhone
{
    return (UI_USER_INTERFACE_IDIOM()== UIUserInterfaceIdiomPhone);
}

+ (UIViewController *)currentViewController
{
    UIResponder *currentController = [[[[[UIApplication sharedApplication] keyWindow] subviews] objectAtIndex:0] nextResponder];
    if ([currentController isMemberOfClass:[UINavigationController class]])
    {
        NSArray *navStack = ((UINavigationController *)currentController).viewControllers;
        currentController = [navStack objectAtIndex:[navStack count] - 1];
    }

    if ([currentController isKindOfClass:[UIViewController class]])
        return (UIViewController *)currentController;
    return nil;
}


#pragma mark - Dates

+ (NSDate *)dateWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day
{
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setYear:year];
    [components setMonth:month];
    [components setDay:day];
    return [calendar dateFromComponents:components];
}

+ (NSDate *)extractDateOnly:(NSDate *)dateTime
{
    NSCalendar * calendar = [NSCalendar currentCalendar];
    NSDateComponents * components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                               fromDate:dateTime];
    return [calendar dateFromComponents:components];
}

+ (UIImage *)imageWithView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return img;
}

+ (UIImage *)captureView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextFillRect(ctx, view.bounds);
    [view.layer renderInContext:ctx];
    UIImage * newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}
@end
