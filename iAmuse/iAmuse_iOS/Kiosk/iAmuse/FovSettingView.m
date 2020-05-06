//
//  FovSettingView.m
//  iAmuse
//
//  Created by apple on 14/11/16.
//  Copyright © 2016 iAmuse Inc. All rights reserved.
//

#import "FovSettingView.h"
#import "AMConstants.h"

@implementation FovSettingView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

+ (FovSettingView *)newFovSettingView
{
    NSArray * topLevelObjects = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([FovSettingView class]) owner:nil options:nil];
    // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ar) name:@"UPDATEMACHINETYPE" object:nil];
    for (UIView * view in topLevelObjects)
    {
        if ([view isKindOfClass:[FovSettingView class]])
        {
            return (FovSettingView *)view;
        }
    }
    return nil;
}

- (void)showFovValues
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    float leftPercent = [defaults floatForKey:FOV_CURTAIN_KEY_LEFT];     // %
    self.fovLeftValueLabel.text = [NSString stringWithFormat:@"%.1f",leftPercent];
    float rightPercent = [defaults floatForKey:FOV_CURTAIN_KEY_RIGHT];   // %
    self.fovRightValueLabel.text = [NSString stringWithFormat:@"%.1f",rightPercent];
    float topPercent = [defaults floatForKey:FOV_CURTAIN_KEY_TOP];       // %
    self.fovTopValueLabel.text = [NSString stringWithFormat:@"%.1f",topPercent];
    float bottomPercent = [defaults floatForKey:FOV_CURTAIN_KEY_BOTTOM];
    self.fovBottomValueLabel.text = [NSString stringWithFormat:@"%.1f",bottomPercent];
}

- (IBAction)startPhotoSession:(id)sender {
    [self.delegate startCameraWithTimer];
}

- (IBAction)fovLeftValueChange:(UIButton *)sender {
    float leftPercent = [self.fovLeftValueLabel.text floatValue];
    if (sender.tag == 11)
    {
        leftPercent -= 1;
        self.fovLeftValueLabel.text = [NSString stringWithFormat:@"%.1f",leftPercent];
    }
    else
    {
        leftPercent += 1;
        self.fovLeftValueLabel.text = [NSString stringWithFormat:@"%.1f",leftPercent];
    }
    [[NSUserDefaults standardUserDefaults] setFloat:leftPercent forKey:FOV_CURTAIN_KEY_LEFT];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.delegate updateFovValuesOnCamera];
}

- (IBAction)fovBottomValueChange:(UIButton *)sender {
    float leftPercent = [self.fovBottomValueLabel.text floatValue];
    if (sender.tag == 31)
    {
        leftPercent -= 1;
    }
    else
    {
        leftPercent += 1;
    }
    self.fovBottomValueLabel.text = [NSString stringWithFormat:@"%.1f",leftPercent];
    [[NSUserDefaults standardUserDefaults] setFloat:leftPercent forKey:FOV_CURTAIN_KEY_BOTTOM];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.delegate updateFovValuesOnCamera];
}

- (IBAction)fovTopValueChange:(UIButton *)sender {
    float leftPercent = [self.fovTopValueLabel.text floatValue];
    if (sender.tag == 21)
    {
        leftPercent -= 1;
    }
    else
    {
        leftPercent += 1;
    }
    self.fovTopValueLabel.text = [NSString stringWithFormat:@"%.1f",leftPercent];
    [[NSUserDefaults standardUserDefaults] setFloat:leftPercent forKey:FOV_CURTAIN_KEY_TOP];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.delegate updateFovValuesOnCamera];
}

- (IBAction)fovRightValueChange:(UIButton *)sender {
    float leftPercent = [self.fovRightValueLabel.text floatValue];
    if (sender.tag == 41)
    {
        leftPercent -= 1;
    }
    else
    {
        leftPercent += 1;
    }
    self.fovRightValueLabel.text = [NSString stringWithFormat:@"%.1f",leftPercent];
    [[NSUserDefaults standardUserDefaults] setFloat:leftPercent forKey:FOV_CURTAIN_KEY_RIGHT];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.delegate updateFovValuesOnCamera];
}

@end
