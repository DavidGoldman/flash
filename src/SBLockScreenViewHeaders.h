#import "FLASHFlashButton.h"

@class SBSlideUpAppGrabberView;

@interface SBLockScreenScrollView : UIScrollView
@end

@interface SBLegibilitySettings : NSObject
- (CGFloat)cameraGrabberStrengthForStyle:(NSInteger)style;
@end

@interface _UILegibilitySettings : NSObject
@property(assign, nonatomic) NSInteger style;
@end

@interface SBLockScreenView : UIView<FLASHFlashButtonDelegate>
@property(retain, nonatomic) _UILegibilitySettings *legibilitySettings;
@property(retain, nonatomic) SBSlideUpAppGrabberView *cameraGrabberView;
@property(retain, nonatomic) UIView *bottomLeftGrabberView;

- (SBLegibilitySettings *)_legibilityPrototypeSettings;
- (BOOL)_shouldUseVibrancy;
- (void)_updateCornerGrabberBackground;
- (void)_updateCornerGrabberLegibilityIfNecessary;
- (void)_updateVibrantView:(id)view screenRect:(CGRect)rect backgroundView:(id)bgView;
- (void)setBottomLeftGrabberHidden:(BOOL)hidden forRequester:(id)requester;

- (BOOL)FLASH_canShowButton;
- (void)FLASH_addOrRemoveButton:(BOOL)addButton;
- (UIView *)FLASH_flashButtonWallpaperEffectView;
- (FLASHFlashButton *)FLASH_flashButton;
@end

@interface SBLockScreenViewController : UIViewController
- (SBLockScreenView *)lockScreenView;
- (SBLockScreenScrollView *)lockScreenScrollView;
@end

@interface SBLockScreenManager : NSObject
+ (instancetype)sharedInstance;
- (SBLockScreenViewController *)lockScreenViewController;
@end
