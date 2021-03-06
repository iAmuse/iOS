// ABPadLockScreenSetupView.m
//
// Copyright (c) 2014 Aron Bury - http://www.aronbury.com
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "ABPadLockScreenView.h"
#import "ABPadButton.h"
#import "ABPinSelectionView.h"

#define animationLength 0.15
#define IS_IPHONE5 ([UIScreen mainScreen].bounds.size.height==568)

@interface ABPadLockScreenView()

@property (nonatomic, assign) BOOL requiresRotationCorrection;
@property (nonatomic, strong) UIView* contentView;

- (void)setDefaultStyles;
- (void)prepareAppearance;
- (void)performLayout;
- (void)layoutTitleArea;
- (void)layoutButtonArea;

- (void)setUpButton:(UIButton *)button left:(CGFloat)left top:(CGFloat)top;
- (void)setUpPinSelectionView:(ABPinSelectionView *)selectionView left:(CGFloat)left top:(CGFloat)top;
- (void)performAnimations:(void (^)(void))animations animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;
- (CGFloat)correctWidth;
- (CGFloat)correctHeight;

@end

@implementation ABPadLockScreenView

@synthesize digitsArray = _digitsArray;

#pragma mark -
#pragma mark - Init Methods
- (id)initWithFrame:(CGRect)frame complexPin:(BOOL)complexPin
{
    self = [self initWithFrame:frame];
    if (self)
    {
        _complexPin = complexPin;
        
        if(complexPin)
        {
            _digitsTextField = [UITextField new];
            _digitsTextField.enabled = NO;
            _digitsTextField.secureTextEntry = YES;
            _digitsTextField.textAlignment = NSTextAlignmentCenter;
            _digitsTextField.borderStyle = UITextBorderStyleNone;
            _digitsTextField.layer.borderWidth = 1.0f;
            _digitsTextField.layer.cornerRadius = 5.0f;
        }
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setDefaultStyles];
        
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, MIN(frame.size.height, 568.0f))];
        _contentView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        _contentView.center = self.center;
        [self addSubview:_contentView];
        
        _requiresRotationCorrection = NO;
        
        _enterPasscodeLabel = [self standardLabel];
        _enterPasscodeLabel.text = NSLocalizedString(@"Enter Passcode", @"");
        
        _detailLabel = [self standardLabel];
        
        _buttonOne = [[ABPadButton alloc] initWithFrame:CGRectZero number:1 letters:nil];
        _buttonTwo = [[ABPadButton alloc] initWithFrame:CGRectZero number:2 letters:@"ABC"];
        _buttonThree = [[ABPadButton alloc] initWithFrame:CGRectZero number:3 letters:@"DEF"];
        
        _buttonFour = [[ABPadButton alloc] initWithFrame:CGRectZero number:4 letters:@"GHI"];
        _buttonFive = [[ABPadButton alloc] initWithFrame:CGRectZero number:5 letters:@"JKL"];
        _buttonSix = [[ABPadButton alloc] initWithFrame:CGRectZero number:6 letters:@"MNO"];
        
        _buttonSeven = [[ABPadButton alloc] initWithFrame:CGRectZero number:7 letters:@"PQRS"];
        _buttonEight = [[ABPadButton alloc] initWithFrame:CGRectZero number:8 letters:@"TUV"];
        _buttonNine = [[ABPadButton alloc] initWithFrame:CGRectZero number:9 letters:@"WXYZ"];
        
        _buttonZero = [[ABPadButton alloc] initWithFrame:CGRectZero number:0 letters:nil];
        
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cancelButton setTitle:NSLocalizedString(@"Cancel", @"") forState:UIControlStateNormal];
        
        _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_deleteButton setTitle:NSLocalizedString(@"Delete", @"") forState:UIControlStateNormal];
        _deleteButton.alpha = 0.0f;
        
        _okButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_okButton setTitle:NSLocalizedString(@"OK", @"") forState:UIControlStateNormal];
        _okButton.alpha = 0.0f;
        _okButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        
        // default to NO
        _complexPin = NO;
    }
    return self;
}

#pragma mark -
#pragma mark - Lifecycle Methods
- (void)layoutSubviews
{
    [super layoutSubviews];
    [self performLayout];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    [self prepareAppearance];
}

#pragma mark -
#pragma mark - Public Methods
- (NSArray *)buttonArray
{
    return @[self.buttonZero,
             self.buttonOne, self.buttonTwo, self.buttonThree,
             self.buttonFour, self.buttonFive, self.buttonSix,
             self.buttonSeven, self.buttonEight, self.buttonNine];
}

- (NSArray *)digitsArray
{
    if(self.isComplexPin)
    {
        return nil; //If complex, no digit views are available.
    }
    
    if (!_digitsArray)
    {
        //Simple pin code is always 4 characters.
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:4];
        
        for (NSInteger i = 0; i < 4; i++)
        {
            ABPinSelectionView *view = [[ABPinSelectionView alloc] initWithFrame:CGRectZero];
            [array addObject:view];
        }
        
        _digitsArray = [array copy];
    }
    
    return _digitsArray;
}

- (void)showCancelButtonAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion
{
    __weak ABPadLockScreenView *weakSelf = self;
    [self performAnimations:^{
        weakSelf.cancelButton.alpha = 1.0f;
        weakSelf.deleteButton.alpha = 0.0f;
    } animated:animated completion:completion];
}

- (void)showDeleteButtonAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion
{
    __weak ABPadLockScreenView *weakSelf = self;
    [self performAnimations:^{
        weakSelf.cancelButton.alpha = 0.0f;
        weakSelf.deleteButton.alpha = 1.0f;
    } animated:animated completion:completion];
}

- (void)showOKButton:(BOOL)show animated:(BOOL)animated completion:(void (^)(BOOL finished))completion
{
    __weak ABPadLockScreenView *weakSelf = self;
    [self performAnimations:^{
        weakSelf.okButton.alpha = show ? 1.0f : 0.0f;
    } animated:animated completion:completion];
}

- (void)updateDetailLabelWithString:(NSString *)string animated:(BOOL)animated completion:(void (^)(BOOL finished))completion
{
    CGFloat length = (animated) ? animationLength : 0.0;
    CGFloat labelWidth = 15; // padding
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1)
        labelWidth += [string sizeWithAttributes:@{NSFontAttributeName:self.detailLabelFont}].width;
    else
        labelWidth += [string sizeWithFont: self.detailLabelFont].width;
    
    CATransition *animation = [CATransition animation];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.type = kCATransitionFade;
    animation.duration = length;
    [self.detailLabel.layer addAnimation:animation forKey:@"kCATransitionFade"];
    
    self.detailLabel.text = string;
    
    CGFloat pinSelectionTop = self.enterPasscodeLabel.frame.origin.y + self.enterPasscodeLabel.frame.size.height + 17.5;
    
    self.detailLabel.frame = CGRectMake(([self correctWidth]/2) - 100, pinSelectionTop + 30, 200, 23);
}

- (void)lockViewAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion
{
    [self performAnimations:^{
        for (UIButton *button in [self buttonArray])
        {
            button.alpha = 0.2f;
            button.userInteractionEnabled = NO;
        }
        self.cancelButton.alpha = 0.0f;
        
        for (ABPinSelectionView *view in self.digitsArray) {
            view.alpha = 0.0f;
        }
    } animated:animated completion:completion];
}

- (void)animateFailureNotification
{
    [self _animateFailureNotificationDirection:-35];
}

- (void)_animateFailureNotificationDirection:(CGFloat)direction
{
    [UIView animateWithDuration:0.08 animations:^{
        
        CGAffineTransform transform = CGAffineTransformMakeTranslation(direction, 0);
        
        if(self.isComplexPin)
        {
            self.digitsTextField.layer.affineTransform = transform;
        }
        else
        {
            for (ABPinSelectionView *view in self.digitsArray)
            {
                view.layer.affineTransform = transform;
            }
        }
    } completion:^(BOOL finished) {
        if(fabs(direction) < 1) {
            if(self.isComplexPin)
            {
                self.digitsTextField.layer.affineTransform = CGAffineTransformIdentity;
            }
            else
            {
                for (ABPinSelectionView *view in self.digitsArray)
                {
                    view.layer.affineTransform = CGAffineTransformIdentity;
                }
            }
            return;
        }
        [self _animateFailureNotificationDirection:-1 * direction / 2];
    }];
}

- (void)resetAnimated:(BOOL)animated
{
    for (ABPinSelectionView *view in self.digitsArray)
    {
        [view setSelected:NO animated:animated completion:nil];
    }
    
    [self showCancelButtonAnimated:animated completion:nil];
    [self showOKButton:NO animated:animated completion:nil];
    
    [self updatePinTextfieldWithLength:0];
}

- (void)updatePinTextfieldWithLength:(NSUInteger)length
{
    NSAttributedString* digitsTextFieldAttrStr = [[NSAttributedString alloc] initWithString:[@"" stringByPaddingToLength:length withString:@" " startingAtIndex:0]
                                                                                 attributes:@{NSKernAttributeName: @4,
                                                                                              NSFontAttributeName: [UIFont boldSystemFontOfSize:18]}];
    [UIView transitionWithView:self.digitsTextField duration:animationLength options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.digitsTextField.attributedText = digitsTextFieldAttrStr;
    } completion:nil];
    
    
}

#pragma mark -
#pragma mark - Helper Methods
- (void)setDefaultStyles
{
    _enterPasscodeLabelFont = [UIFont systemFontOfSize:18];
    _detailLabelFont = [UIFont systemFontOfSize:14];
    
    _labelColor = [UIColor whiteColor];
}

- (void)prepareAppearance
{
    self.enterPasscodeLabel.textColor = self.labelColor;
    self.enterPasscodeLabel.font = self.enterPasscodeLabelFont;
    
    self.digitsTextField.textColor = self.labelColor;
    self.digitsTextField.layer.borderColor = self.labelColor.CGColor;
    
    [self updatePinTextfieldWithLength:0];
    
    self.detailLabel.textColor = self.labelColor;
    self.detailLabel.font = self.detailLabelFont;
    
    [self.cancelButton setTitleColor:self.labelColor forState:UIControlStateNormal];
    [self.deleteButton setTitleColor:self.labelColor forState:UIControlStateNormal];
    [self.okButton setTitleColor:self.labelColor forState:UIControlStateNormal];
}

#pragma mark -
#pragma mark - Leyout Methods
- (void)performLayout
{
    [self layoutTitleArea];
    [self layoutButtonArea];
    _requiresRotationCorrection = YES;
}

- (void)layoutTitleArea
{
    CGFloat top = 75;
    if(!IS_IPHONE5)
    {
        top = 20;
    }
    self.enterPasscodeLabel.frame = CGRectMake(([self correctWidth]/2) - 100, top, 200, 23);
    [self.contentView addSubview:self.enterPasscodeLabel];
    
    CGFloat pinSelectionTop = self.enterPasscodeLabel.frame.origin.y + self.enterPasscodeLabel.frame.size.height + 17.5;
    
    if(self.isComplexPin)
    {
        CGFloat textFieldWidth = 152;
        _digitsTextField.frame = CGRectMake((self.correctWidth / 2) - (textFieldWidth / 2), pinSelectionTop - 7.5f, textFieldWidth, 30);
        
        [self.contentView addSubview:_digitsTextField];
        
        _okButton.frame = CGRectMake(_digitsTextField.frame.origin.x + _digitsTextField.frame.size.width + 10, pinSelectionTop - 7.5f, (self.correctWidth - _digitsTextField.frame.size.width) / 2 - 10, 30);
        
        [self.contentView addSubview:_okButton];
    }
    else
    {
        CGFloat pinPadding = 25;
        CGFloat pinRowWidth = (ABPinSelectionViewWidth * 4) + (pinPadding * 3);
        
        CGFloat selectionViewLeft = ([self correctWidth]/2) - (pinRowWidth/2);
        
        for (ABPinSelectionView *view in self.digitsArray) {
            [self setUpPinSelectionView:view  left:selectionViewLeft top:pinSelectionTop];
            selectionViewLeft+=ABPinSelectionViewWidth + pinPadding;
        }
    }
    
    self.detailLabel.frame = CGRectMake(([self correctWidth]/2) - 100, pinSelectionTop + 30, 200, 23);
    [self.contentView addSubview:self.detailLabel];
}

- (void)layoutButtonArea
{
    CGFloat horizontalButtonPadding = 20;
    CGFloat verticalButtonPadding = 10;
    
    CGFloat buttonRowWidth = (ABPadButtonWidth * 3) + (horizontalButtonPadding * 2);
    
    CGFloat lefButtonLeft = ([self correctWidth]/2) - (buttonRowWidth/2) + 0.5;
    CGFloat centerButtonLeft = lefButtonLeft + ABPadButtonWidth + horizontalButtonPadding;
    CGFloat rightButtonLeft = centerButtonLeft + ABPadButtonWidth + horizontalButtonPadding;
    
    CGFloat topRowTop = self.detailLabel.frame.origin.y + self.detailLabel.frame.size.height + 15;
    
    if (!IS_IPHONE5) topRowTop = self.detailLabel.frame.origin.y + self.detailLabel.frame.size.height + 10;
    
    CGFloat middleRowTop = topRowTop + ABPadButtonHeight + verticalButtonPadding;
    CGFloat bottomRowTop = middleRowTop + ABPadButtonHeight + verticalButtonPadding;
    CGFloat zeroRowTop = bottomRowTop + ABPadButtonHeight + verticalButtonPadding;
    
    [self setUpButton:self.buttonOne left:lefButtonLeft top:topRowTop];
    [self setUpButton:self.buttonTwo left:centerButtonLeft top:topRowTop];
    [self setUpButton:self.buttonThree left:rightButtonLeft top:topRowTop];
    
    [self setUpButton:self.buttonFour left:lefButtonLeft top:middleRowTop];
    [self setUpButton:self.buttonFive left:centerButtonLeft top:middleRowTop];
    [self setUpButton:self.buttonSix left:rightButtonLeft top:middleRowTop];
    
    [self setUpButton:self.buttonSeven left:lefButtonLeft top:bottomRowTop];
    [self setUpButton:self.buttonEight left:centerButtonLeft top:bottomRowTop];
    [self setUpButton:self.buttonNine left:rightButtonLeft top:bottomRowTop];
    
    [self setUpButton:self.buttonZero left:centerButtonLeft top:zeroRowTop];
    
    CGRect deleteCancelButtonFrame = CGRectMake(rightButtonLeft, zeroRowTop + ABPadButtonHeight, ABPadButtonWidth, 20);
    if(!IS_IPHONE5)
    {
        deleteCancelButtonFrame = CGRectMake(rightButtonLeft, zeroRowTop + ABPadButtonHeight - 20, ABPadButtonWidth, 20);
    }
    
    if (!self.cancelButtonDisabled)
    {
        self.cancelButton.frame = deleteCancelButtonFrame;
        [self.contentView addSubview:self.cancelButton];
    }
    
    self.deleteButton.frame = deleteCancelButtonFrame;
    [self.contentView addSubview:self.deleteButton];
}

- (void)setUpButton:(UIButton *)button left:(CGFloat)left top:(CGFloat)top
{
    button.frame = CGRectMake(left, top, ABPadButtonWidth, ABPadButtonHeight);
    [self.contentView addSubview:button];
    [self setRoundedView:button toDiameter:75];
}

- (void)setUpPinSelectionView:(ABPinSelectionView *)selectionView left:(CGFloat)left top:(CGFloat)top
{
    selectionView.frame = CGRectMake(left,
                                     top,
                                     ABPinSelectionViewWidth,
                                     ABPinSelectionViewHeight);
    [self.contentView addSubview:selectionView];
    [self setRoundedView:selectionView toDiameter:15];
}

- (void)performAnimations:(void (^)(void))animations animated:(BOOL)animated completion:(void (^)(BOOL finished))completion
{
    CGFloat length = (animated) ? animationLength : 0.0f;
    
    [UIView animateWithDuration:length delay:0.0f options:UIViewAnimationOptionCurveEaseIn
                     animations:animations
                     completion:completion];
}

#pragma mark -
#pragma mark - Orientation height helpers
- (CGFloat)correctWidth
{
    return _contentView.bounds.size.width;
}

- (CGFloat)correctHeight
{
    return _contentView.bounds.size.height;
}

#pragma mark -
#pragma mark -  View Methods
- (UILabel *)standardLabel
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.textColor = _labelColor;
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentCenter;
    
    return label;
}

- (void)setRoundedView:(UIView *)roundedView toDiameter:(CGFloat)newSize;
{
    CGRect newFrame = CGRectMake(roundedView.frame.origin.x, roundedView.frame.origin.y, newSize, newSize);
    roundedView.frame = newFrame;
    roundedView.clipsToBounds = YES;
    roundedView.layer.cornerRadius = newSize / 2.0;
}

@end
