//
//  CTScreen.h
//  SmartPhoto Camera
//
//  Created by Roland Hordos on 2013-05-06.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "stdio.h"
#import "CTKiosk.h"

@interface CTScreen :NSObject {
    float _width;
    float _height;
}

@property float width;
@property float height;

- (id)init;

@end
