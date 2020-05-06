#import <Foundation/Foundation.h>
#import <objc/Object.h>
#import "stdio.h"
#import "PhotoLayout.h"

@class PhotoLayout;

@interface PhotoLayoutTarget :NSObject {
	@private NSObject _width;
	@private NSObject _height;
	@private NSObject _distance;
	PhotoLayout*  _each_with;
}
@end
