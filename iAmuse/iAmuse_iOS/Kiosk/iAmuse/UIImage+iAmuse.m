//
//  UIImage+iAmuse.m
//  iAmuse
//
//  Created by Roland Hordos on 2014-05-21.
//  Copyright (c) 2014 iAmuse Inc. All rights reserved.
//

#import "UIImage+iAmuse.h"

@implementation UIImage (iAmuse)

#pragma mark -
#pragma mark Scale and crop image

//
//  Scale to a target size, and Aspect Fill so no blank space appears.
//
//  Thank you to Jane Sales for the start.
//  - http://stackoverflow.com/questions/603907/uiimage-resize-then-crop
//
- (UIImage*)imageByAspectFill:(CGSize)targetSize
{
    UIImage *sourceImage = self;
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (!CGSizeEqualToSize(imageSize, targetSize)) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor)
        {
            // We are width bound.
            scaleFactor = widthFactor;
        }
        else
        {
            // We are height bound.
            scaleFactor = heightFactor;
        }
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        if (widthFactor > heightFactor)
        {
            thumbnailPoint.y = (CGFloat)((targetHeight - scaledHeight) * 0.5);
        }
        else
        {
            if (widthFactor < heightFactor)
            {
                thumbnailPoint.x = (CGFloat)((targetWidth - scaledWidth) * 0.5);
            }
        }
    }
    
    UIGraphicsBeginImageContext(targetSize); // this will crop
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    if(newImage == nil)
    {
        NSLog(@"could not scale image");
    }
    
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    
    return newImage;
}

//
//  Scale to a target size, with Aspect Fit so no content is lost.
//
//  Thank you to Jane Sales for the start.
//  - http://stackoverflow.com/questions/603907/uiimage-resize-then-crop
//
- (UIImage*)imageByAspectFit:(CGSize)targetSize
{
    UIImage *sourceImage = self;
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);

    if (!CGSizeEqualToSize(imageSize, targetSize)) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;

        if (widthFactor > heightFactor)
        {
            // We are height bound.
            scaleFactor = heightFactor;
        }
        else
        {
            // We are width bound.
            scaleFactor = widthFactor;
        }

        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;

        // center the image
        if (widthFactor > heightFactor)
        {
            thumbnailPoint.x = (CGFloat)((targetWidth - scaledWidth) * 0.5);
        }
        else
        {
            if (widthFactor < heightFactor)
            {
                // We need more height adjustment than width, which means leaving
                // a blank area for part of the height to aspect fit.
                thumbnailPoint.y = (CGFloat)((targetHeight - scaledHeight) * 0.5);
            }
        }
    }

    UIGraphicsBeginImageContext(targetSize); // this will crop

    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;

    [sourceImage drawInRect:thumbnailRect];

    newImage = UIGraphicsGetImageFromCurrentImageContext();

    if(newImage == nil)
    {
        NSLog(@"could not scale image");
    }

    //pop the context to get back to the default
    UIGraphicsEndImageContext();

    return newImage;
}

- (UIImage*)imageByScaleToFill:(CGSize)targetSize
{
    UIImage *newImage = nil;
  
    UIImageView *imgView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, targetSize.width, targetSize.height)];
    imgView.image = self;
    imgView.contentMode = UIViewContentModeScaleToFill;
    
    UIGraphicsBeginImageContext(imgView.frame.size); // this will crop
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [imgView.layer renderInContext:ctx];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize
{
    UIImage *newImage = self;
    //CGSize imageSize = sourceImage.size;
    
    CGSize tempSize = targetSize;
    //CGContextRef context = UIGraphicsGetCurrentContext();
    //UIGraphicsBeginImageContext(targetSize);
    UIGraphicsBeginImageContextWithOptions(targetSize, YES, 0.8);
    [self drawInRect:CGRectMake((targetSize.width - tempSize.width) / 2.0, (targetSize.height - tempSize.height) / 2.0, tempSize.width, tempSize.height)];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
