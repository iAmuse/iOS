#import <Foundation/Foundation.h>
#import <objc/Object.h>
#import "stdio.h"
#import "Kiosk.h"
#import "PhotoSessionController.h"
#import "ControlPanel.h"
#import "PhotoSessionTemplate.h"
#import "PhotoLayout.h"

@class Kiosk;
@class PhotoSessionController;
@class ControlPanel;
@class PhotoSessionTemplate;
@class PhotoLayout;

@interface SingleCameraPhotoFeature :NSObject {
	@private NSObject _fEATURE_MAX_SHOTS; // 3
	Kiosk*  _configured_for;
	PhotoSessionController*  _unnamed_PhotoSessionController_;
	ControlPanel*  _unnamed_ControlPanel_;
	PhotoSessionTemplate*  _unnamed_PhotoSessionTemplate_;
	PhotoLayout*  _unnamed_PhotoLayout_;
}
@end
