#import <Foundation/Foundation.h>
#import <objc/Object.h>
#import "stdio.h"
#import "SingleCameraPhotoFeature.h"

@class SingleCameraPhotoFeature;

@interface PhotoSessionTemplate :NSObject {
	@private NSObject _targetObjectCount;
	@private NSObject _targetArrangement;
	/**
	 * FLOATING, ALIGN_BOTTOM
	 */
	@private NSObject _targetAlignment; // TA_FLOATING
	@private NSObject _shotCountMax; // FEATURE_MAX_SHOTS
	@private NSObject _getIntoPositionWait; // 30
	SingleCameraPhotoFeature*  _unnamed_SingleCameraPhotoFeature_;
}

-(void) createPhoto;

-(void) initialCountdown;

-(void) interShotCountdown;
@end
