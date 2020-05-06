//
//  CTKioskSplashViewController.h
//  Jurassic
//
//  Created by Roland Hordos on 2013-06-01.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "CTSelectSceneViewController.h"

@class MPMoviePlayerController;

@interface CTKioskSplashViewController : UIViewController <SceneSelectionCompleteDelegate >
{
    @private
    MPMoviePlayerController * moviePlayer;   // Used for splash movie
    UIImageView * introOverlayLayer;           // Used for introduction graphic overlay above movie.
}
@property (strong, nonatomic) CTSelectSceneViewController * selectSceneVC;
@property (weak, nonatomic) IBOutlet UIImageView *imgViewTouch;

- (void)selectScene;

@end
