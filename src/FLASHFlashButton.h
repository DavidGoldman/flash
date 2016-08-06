#import "FLASHFlashController.h"

@class FLASHFlashButton, SBSlideUpAppGrabberView;

@protocol FLASHFlashButtonDelegate <NSObject>
- (void)flashButton:(FLASHFlashButton *)button becameVisible:(BOOL)visible;
- (BOOL)shouldFlashButtonSuppressHideTimer:(FLASHFlashButton *)button;
@end

// SBLockScreenHintManager requires us to make this subclass UIControl.
@interface FLASHFlashButton : UIControl<FLASHFlashlightDelegate>
@property(nonatomic, assign) BOOL flashlightOn;
@property(nonatomic, assign) BOOL visible;
@property(nonatomic, readonly, retain) SBSlideUpAppGrabberView *slideUpAppGrabberView;

- (instancetype)initWithFrame:(CGRect)frame classicIcon:(BOOL)classicIcon;
- (void)setVisible:(BOOL)visible immediately:(BOOL)immediately animated:(BOOL)animated;

- (void)colorizeWithInfo:(NSDictionary *)info;

- (void)setDelegate:(id<FLASHFlashButtonDelegate>)delegate;
- (id<FLASHFlashButtonDelegate>)delegate;
@end
