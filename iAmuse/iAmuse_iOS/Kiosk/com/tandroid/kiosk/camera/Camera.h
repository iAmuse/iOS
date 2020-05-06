#import <Foundation/Foundation.h>
#import <objc/Object.h>
#import "stdio.h"
#import "Kiosk.h"

@class Kiosk;

@interface Camera :NSObject {
	@private NSObject _distanceToScreen;
	@private NSObject _optimalDistanceToObject;
	@private NSObject _xOffset;
	@private NSObject _yOffset;
	Kiosk*  _unnamed_Kiosk_;
}

-(void) overlayCountdown;

-(void) takePhoto;
@end
