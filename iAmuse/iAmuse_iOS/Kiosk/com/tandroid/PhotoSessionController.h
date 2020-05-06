#import <Foundation/Foundation.h>
#import <objc/Object.h>
#import "stdio.h"
#import "ConsumerTouchInterface.h"
#import "SingleCameraPhotoFeature.h"
#import "PhotoSession.h"

@class ConsumerTouchInterface;
@class SingleCameraPhotoFeature;
@class PhotoSession;

@interface PhotoSessionController :NSObject {
	ConsumerTouchInterface*  _unnamed_ConsumerTouchInterface_;
	SingleCameraPhotoFeature*  _unnamed_SingleCameraPhotoFeature_;
	PhotoSession*  _unnamed_PhotoSession_;
	NSMutableArray*  _unnamed_Account_; // NSMutableArray.alloc.init
}

-(void) startPhotoSession;

-(void) copyPhotoFromRemoteDevice;

-(void) getAccountWithEmail;

-(void) uploadPhotoToCloud;

-(void) handleException;

-(void) validateEmailSimple;

-(void) estimateUploadDuration;

-(void) logToAdministrator;

-(void) pauseKioskForIntervention;
@end
