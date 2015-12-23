@class SBSlideUpAppGrabberView;

#import "FLASHFlashController.h"

// SBLockScreenHintManager requires us to make this subclass UIControl.
@interface FLASHFlashButton : UIControl<UIGestureRecognizerDelegate, FLASHFlashlightDelegate>
@property(nonatomic, assign) BOOL flashlightOn;
@property(nonatomic, assign) BOOL visible;
@property(nonatomic, readonly) SBSlideUpAppGrabberView *slideUpAppGrabberView;

- (instancetype)initWithFrame:(CGRect)frame classicIcon:(BOOL)classicIcon;
- (void)setVisible:(BOOL)visible immediately:(BOOL)immediately animated:(BOOL)animated;

- (void)colorizeWithInfo:(NSDictionary *)info;
@end
