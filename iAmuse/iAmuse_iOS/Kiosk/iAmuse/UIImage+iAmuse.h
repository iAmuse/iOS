//
//  UIImage+iAmuse.h
//  iAmuse
//
//  Created by Roland Hordos on 2014-05-21.
//  Copyright (c) 2014 iAmuse Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (iAmuse)

- (UIImage*)imageByAspectFill:(CGSize)targetSize;
- (UIImage*)imageByAspectFit:(CGSize)targetSize;
- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize;

@end
