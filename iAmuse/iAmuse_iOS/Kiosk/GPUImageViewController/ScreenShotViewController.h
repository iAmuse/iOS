//
//  ScreenShotViewController.h
//  iAmuseTest
//
//  Created by IPHONE-02 on 1/13/15.
//  Copyright (c) 2015 Himanshu. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol colorSelectionDelegate <NSObject>

@required
- (void)colorSelected:(NSArray *)colorComponents;

@end

@interface ScreenShotViewController : UIViewController
{
    IBOutlet UIImageView * imageVieww;
    NSArray * colorComponents;
}
@property(nonatomic,strong)UIImage * image ;
//property of Delegate
@property (assign, nonatomic) id <colorSelectionDelegate> delegate;
@end
