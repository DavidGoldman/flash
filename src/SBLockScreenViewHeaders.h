#import "FLASHFlashButton.h"

@class SBSlideUpAppGrabberView;

@interface SBLockScreenScrollView : UIScrollView
@end

@interface SBLegibilitySettings : NSObject
// iOS 8 - 9
- (CGFloat)cameraGrabberStrengthForStyle:(NSInteger)style;
// iOS 10
- (CGFloat)appIconGrabberStrengthForStyle:(NSInteger)style;
@end

@interface _UILegibilitySettings : NSObject
@property(assign, nonatomic) NSInteger style;
@end

// iOS 10
@interface SBDashBoardMainPageView : UIView<FLASHFlashButtonDelegate>
@property(retain, nonatomic) _UILegibilitySettings *legibilitySettings;
@property(retain, nonatomic) SBSlideUpAppGrabberView *slideUpAppGrabberView; 
@property(assign, nonatomic) BOOL slideUpAppGrabberViewVisible;

- (SBLegibilitySettings *)_legibilityPrototypeSettings;
- (void)_updateSlideToAppGrabberBackgroundView;
- (void)_updateSlideUpAppGrabberViewForLegibilitySettings;

- (BOOL)FLASH_canShowButton;
- (void)FLASH_addOrRemoveButton:(BOOL)addButton;
- (UIView *)FLASH_flashButtonWallpaperEffectView;
- (FLASHFlashButton *)FLASH_flashButton;
@end

// Only on iOS 10
@interface SBDashBoardVibrancyUtility : NSObject
+ (void)updateVibrantView:(UIView *)vibrantView backgroundView:(UIView *)backgroundView;
@end

// iOS 8 - 9
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
