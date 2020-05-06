//
//  FOVData.h
//  iAmuse
//
//  Created by apple on 11/11/16.
//  Copyright © 2016 iAmuse Inc. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface FOVData : NSManagedObject

@property (nonatomic, retain) NSString * fovBottom;
@property (nonatomic, retain) NSString * fovTop;
@property (nonatomic, retain) NSString * fovLeft;
@property (nonatomic, retain) NSString * fovRight;
@property (nonatomic, retain) NSString * greenScreenWidth;
@property (nonatomic, retain) NSString * greenScreenHeight;

@end
