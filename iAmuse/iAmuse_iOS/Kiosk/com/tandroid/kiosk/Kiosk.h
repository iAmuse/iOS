#import <Foundation/Foundation.h>
#import <objc/Object.h>
#import "stdio.h"
#import "ControlPanel.h"
#import "Screen.h"
#import "SingleCameraPhotoFeature.h"
#import "Camera.h"
#import "ConsumerTouchInterface.h"
#import "LocalPhotoStore.h"

@class ControlPanel;
@class Screen;
@class SingleCameraPhotoFeature;
@class Camera;
@class ConsumerTouchInterface;
@class LocalPhotoStore;

@interface Kiosk :NSObject {
	@private NSObject _productId;
	@private NSObject _projectId;
	@private NSObject _installationId;
	@private NSObject _openTime;
	@private NSObject _closeTime;
	@private NSObject _timezone;
	ControlPanel*  _unnamed_ControlPanel_;
	Screen*  _unnamed_Screen_;
	SingleCameraPhotoFeature*  _configured_for;
	Camera*  _unnamed_Camera_;
	ConsumerTouchInterface*  _unnamed_ConsumerTouchInterface_;
	LocalPhotoStore*  _unnamed_LocalPhotoStore_;
}

-(void) startup;

-(void) shutdown;
@end
