#import <Foundation/Foundation.h>
#import <objc/Object.h>
#import "stdio.h"
#import "Screen.h"

@class Screen;

@interface BackgroundScreen :Screen {
	/**
	 * In cm.
	 */
	@private NSObject _height; // 220
	@private NSObject _width;
}
@end
