#import <Foundation/Foundation.h>
#import <objc/Object.h>
#import "stdio.h"
#import "Kiosk.h"
#import "PhotoSessionController.h"

@class Kiosk;
@class PhotoSessionController;

@interface ConsumerTouchInterface :NSObject {
	Kiosk*  _unnamed_Kiosk_;
	PhotoSessionController*  _unnamed_PhotoSessionController_;
}

-(void) adminLock;

-(void) adminUnlock;

-(void) resetToSplash;

-(void) startPhotoSession;

-(void) selectLayout;

-(void) getInPosition;

-(void) reviewPhotoShoot;

-(void) bestPhotoSelected;

-(void) requestEmail;

-(void) adminInterventionRequired;

-(void) showThankYouAndSupportOptions;
@end
