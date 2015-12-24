#import "FLASHFlashController.h"

@class FLASHFlashButton, SBSlideUpAppGrabberView;

@protocol FLASHFlashButtonDelegate <NSObject>
- (void)flashButton:(FLASHFlashButton *)button becameVisible:(BOOL)visible;
@end

// SBLockScreenHintManager requires us to make this subclass UIControl.
@interface FLASHFlashButton : UIControl<FLASHFlashlightDelegate>
@property(nonatomic, assign) BOOL flashlightOn;
@property(nonatomic, assign) BOOL visible;
@property(nonatomic, readonly) SBSlideUpAppGrabberView *slideUpAppGrabberView;
@property(nonatomic, assign) id<FLASHFlashButtonDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame classicIcon:(BOOL)classicIcon;
- (void)setVisible:(BOOL)visible immediately:(BOOL)immediately animated:(BOOL)animated;

- (void)colorizeWithInfo:(NSDictionary *)info;
@end
