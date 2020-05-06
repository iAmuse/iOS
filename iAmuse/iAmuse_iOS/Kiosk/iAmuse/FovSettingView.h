//
//  FovSettingView.h
//  iAmuse
//
//  Created by apple on 14/11/16.
//  Copyright © 2016 iAmuse Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FovValueChangeDelegate <NSObject>

- (void)updateFovValuesOnCamera;
- (void)startCameraWithTimer;

@end

@interface FovSettingView : UIView

@property (weak, nonatomic) id <FovValueChangeDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *fovLeftValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *fovBottomValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *fovTopValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *fovRightValueLabel;

- (IBAction)fovLeftValueChange:(UIButton *)sender;
- (IBAction)fovBottomValueChange:(UIButton *)sender;
- (IBAction)fovTopValueChange:(UIButton *)sender;
- (IBAction)fovRightValueChange:(UIButton *)sender;
+ (FovSettingView *)newFovSettingView;
- (void)showFovValues;
- (IBAction)startPhotoSession:(id)sender;

@end
