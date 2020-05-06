#import <Foundation/Foundation.h>
#import <objc/Object.h>
#import "stdio.h"
#import "Kiosk.h"
#import "PhotoSession.h"

@class Kiosk;
@class PhotoSession;

@interface LocalPhotoStore :NSObject {
	Kiosk*  _unnamed_Kiosk_;
	PhotoSession*  _unnamed_PhotoSession_;
}

-(void) storePhoto;

-(void) removePhoto;
@end
