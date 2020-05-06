
// Photo Sessions start when a Photo Layout is selected in the Touch Screen consumer interface.

//  Created by Roland Hordos on 2013-05-06.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.

#import <Foundation/Foundation.h>
#import "PhotoLayout.h"

@interface CTPhotoSession :NSObject {

//	@private NSObject *_targetObjectCount;
//	@private NSObject *_targetArrangement;
	/**
	 * FLOATING, ALIGN_BOTTOM
	 */
//	@private NSObject *_targetAlignment; // TA_FLOATING
}

//@property (nonatomic) PhotoLayout *chosenPhotoLayout;
@property (nonatomic) PhotoSession *entity;


//-(void) choosePhotoLayout:(PhotoLayout *)photoLayout;

-(void) initialCountdown;

-(void) interShotCountdown;
@end
