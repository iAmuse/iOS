
// Photo Sessions start when a Photo Layout is selected in the Touch Screen consumer interface.

//  Created by Roland Hordos on 2013-05-06.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.

#import "CTPhotoSession.h"
#import "PhotoLayout.h"

@implementation CTPhotoSession

@synthesize entity;
//@synthesize chosenPhotoLayout;

-(id) init {
    self = [super init];
    
    if (self) {
//        chosenPhotoLayout = nil;
    }
    
    return self;
}

//-(void) choosePhotoLayout:(PhotoLayout *)photoLayout
//{
//	chosenPhotoLayout = photoLayout;
//}

-(void) initialCountdown {
	[NSException raise:@"Not yet implemented" format:@""];
}

-(void) interShotCountdown {
	[NSException raise:@"Not yet implemented" format:@""];
}
@end
