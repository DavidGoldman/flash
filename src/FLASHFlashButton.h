#import "FLASHFlashController.h"

// SBLockScreenHintManager requires us to make this subclass UIControl.
@interface FLASHFlashButton : UIControl<UIGestureRecognizerDelegate, FLASHFlashlightDelegate>
@property(nonatomic, assign) BOOL flashlightOn;
@property(nonatomic, assign) BOOL visible;

- (instancetype)initWithFrame:(CGRect)frame;
- (void)setVisible:(BOOL)visible immediately:(BOOL)immediately animated:(BOOL)animated;
@end
