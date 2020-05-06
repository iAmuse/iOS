//
//  CTCTKioskHTTPConnection.h
//  Jurassic
//
//  Extends Cocoa HTTP Server connection to tie in application server layer.
//
//  Created by Roland Hordos on 2013-05-30.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTTPConnection.h"

@interface CTCameraHTTPConnection : HTTPConnection
{
    NSMutableArray * entities;
    NSMutableDictionary * args;
}

@end
