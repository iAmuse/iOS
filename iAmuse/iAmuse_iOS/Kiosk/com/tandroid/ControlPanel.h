#import <Foundation/Foundation.h>
#import <objc/Object.h>
#import "stdio.h"
#import "Kiosk.h"

@class Kiosk;

@interface ControlPanel :NSObject {
	Kiosk*  _unnamed_Kiosk_;
	NSMutableArray*  _unnamed_SingleCameraPhotoFeature_; // NSMutableArray.alloc.init
}

-(void) configurePhotoSession;

-(void) addPhotoLayout;

-(void) updatePhotoLayout;

-(void) deletePhotoLayout;
@end
