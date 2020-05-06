
// A Photo Layout is noteworthy in it's background image, selected by a consumer who chooses it from a list of possible photos.  Works together with a CTPhotoLayoutTarget to direct the camera to specify where the target will appear in the photo.

//  Created by Roland Hordos on 2013-05-06.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.

@interface CTPhotoLayout :NSObject {
    int layoutIndex;
	NSString *backgroundImageURL;
//	@private NSObject *_width;
//	@private NSObject *_height;
//	SingleCameraPhotoFeature*  _unnamed_SingleCameraPhotoFeature_;
//	NSMutableArray*  _each_with; // NSMutableArray.alloc.init
}

@property int layoutIndex;
@property NSString *backgroundImageURL;

@end
