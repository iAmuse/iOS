//
// Created by Roland Hordos on 2013-06-21.
// Copyright (c) 2013 iAmuse Inc. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "GSVideoProcessor.h"

@class CTCamera;


@interface CTVideoProcessor : GSVideoProcessor {
    CTCamera *camera;
}

@property CTCamera *camera;

- (void)setupGL;
@end