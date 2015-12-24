#import "Macros.h"
#import "BCBerryView.h"
#import "FLASHFlashButton.h"
#import "FLASHFlashController.h"
#import "FLASHPrefsManager.h"
#import "SBCCFlashlightSetting.h"
#import "SBLockScreenViewHeaders.h"
#import "SBSlideUpAppGrabberView.h"
#import "SBWallpaperEffectView.h"

static const NSInteger kFlashButtonTag = 0x666c7368;
static const CGFloat kButtonSize = 50;

static const NSInteger kWallpaperVariantStaticWallpaper = 0;
static const NSInteger kWallpaperStyleSemiLightTintedBlur = 10;

static NSString * const kFlashGrabberRequester = @"FLASH";

%hook SBCCFlashlightSetting
- (id)init {
  self = %orig;
  [[FLASHFlashController sharedFlashController] onFlashlightSettingInit:self];
  return self;
}
- (void)dealloc {
  [[FLASHFlashController sharedFlashController] onFlashlightSettingDealloc:self];
  %orig;
}
%end

%hook SBLockScreenView

%new
- (FLASHFlashButton *)FLASH_flashButton {
  UIView *foregroundLockHUDView = MSHookIvar<UIView *>(self, "_foregroundLockHUDView");
  return (FLASHFlashButton *) [foregroundLockHUDView viewWithTag:kFlashButtonTag];
}

%new
- (UIView *)FLASH_flashButtonWallpaperEffectView {
  UIView *view = objc_getAssociatedObject(self, @selector(FLASH_flashButtonWallpaperEffectView));
  if (!view) {
    SBWallpaperEffectView *effectView =
      [[%c(SBWallpaperEffectView) alloc] initWithWallpaperVariant:kWallpaperVariantStaticWallpaper];
    effectView.style = kWallpaperStyleSemiLightTintedBlur;
    objc_setAssociatedObject(self, @selector(FLASH_flashButtonWallpaperEffectView), effectView,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return [effectView autorelease];
  }
  return view;
}

%new
- (BOOL)FLASH_canShowButton {
  FLASHPrefsManager *prefsManager = [FLASHPrefsManager sharedInstance];
  if (!prefsManager.enabled) {
    return NO;
  }

  NSMutableSet *requesters = MSHookIvar<NSMutableSet *>(self, "_bottomLeftGrabberHiddenRequesters");
  if (prefsManager.overrideHandoff) {
    NSUInteger count = requesters.count;
    if ([requesters containsObject:kFlashGrabberRequester]) {
      --count;
    }
    return (count == 0);
  }
  return (!self.bottomLeftGrabberView && requesters.count == 0);
}

%new
- (void)FLASH_addOrRemoveButton:(BOOL)addButton {
  FLASHFlashButton *button = [self FLASH_flashButton];

  if (addButton) {
    if (!button) {
      UIView *foregroundLockHUDView = MSHookIvar<UIView *>(self, "_foregroundLockHUDView");

      // This can be called from within an animation block, so we have to be careful as we don't
      // want the init occurring with an animation.
      [UIView performWithoutAnimation:^{
          BOOL classicIcon = ![FLASHPrefsManager sharedInstance].ghostedIcon;
          FLASHFlashButton *fb = [[FLASHFlashButton alloc] initWithFrame:CGRectZero
                                                             classicIcon:classicIcon];
          fb.tag = kFlashButtonTag;
          fb.delegate = self;
          [foregroundLockHUDView addSubview:fb];
          [self _updateCornerGrabberBackground];
          [self _updateCornerGrabberLegibilityIfNecessary];
          [fb release];
      }];
    }
  } else {
    [button removeFromSuperview];
    [self setBottomLeftGrabberHidden:NO forRequester:kFlashGrabberRequester];
  }
}

%new
- (void)flashButton:(FLASHFlashButton *)button becameVisible:(BOOL)visible {
  if ([FLASHPrefsManager sharedInstance].overrideHandoff) {
    [self setBottomLeftGrabberHidden:visible forRequester:kFlashGrabberRequester];
  }
}

- (void)_updateCornerGrabberBackground {
  %orig;

  // Mimic this method's impl for our button.
  if ([self _shouldUseVibrancy]) {
    FLASHFlashButton *button = [self FLASH_flashButton];
    UIView *vibrantView = button.slideUpAppGrabberView;
    if (vibrantView) {
      CGRect screenRect = [vibrantView.superview convertRect:vibrantView.frame toView:nil];
      [self _updateVibrantView:vibrantView
                    screenRect:screenRect
                backgroundView:[self FLASH_flashButtonWallpaperEffectView]];
    }
  }
}

- (void)_updateCornerGrabberLegibilityIfNecessary {
  %orig;

  // Mimic this method's impl for our button.
  FLASHFlashButton *button = [self FLASH_flashButton];
  SBSlideUpAppGrabberView *vibrantView = button.slideUpAppGrabberView;
  if (!vibrantView) {
    return;
  }
  if ([self _shouldUseVibrancy]) {
    vibrantView.vibrancyAllowed = YES;
  } else {
    vibrantView.vibrancyAllowed = NO;
    _UILegibilitySettings *ls = self.legibilitySettings;
    CGFloat strength = [[self _legibilityPrototypeSettings] cameraGrabberStrengthForStyle:ls.style];
    [vibrantView setStrength:strength];
    [vibrantView updateForChangedSettings:ls];
  }
}

- (void)setBottomLeftGrabberView:(UIView *)view {
  %orig;
  [self FLASH_addOrRemoveButton:[self FLASH_canShowButton]];
}
- (void)setBottomLeftGrabberHidden:(BOOL)hidden forRequester:(id)requester {
  %orig;
  if (![requester isEqual:kFlashGrabberRequester]) {
    [self FLASH_addOrRemoveButton:[self FLASH_canShowButton]];
  }
}
- (void)_layoutBottomLeftGrabberView {
  %orig;

  FLASHFlashButton *button = [self FLASH_flashButton];
  if (button) {
    UIView *foregroundLockHUDView = MSHookIvar<UIView *>(self, "_foregroundLockHUDView");
    CGRect frame = foregroundLockHUDView.bounds;
    CGFloat x;
    UIApplication *app = [UIApplication sharedApplication];
    if (app.userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionLeftToRight) {
      x = CGRectGetMinX(frame);
    } else {
      x = CGRectGetMaxX(frame) - kButtonSize;
    }
    CGRect newFrame = CGRectMake(x, CGRectGetMaxY(frame) - kButtonSize, kButtonSize, kButtonSize);
    button.frame = newFrame;
  }
}

%end

// Hacky support for BerryC8 by hooking hitTest:withEvent:, preventing it from receiving events that
// are inside a visible FLASHFlashButton.
//
// This is definitely not the most optimal solution - a proper one would probably need to hook into
// SBLockScreenHintManager in order to add _general_ support for our FLASHFlashButton.
%hook BCBerryView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
  if ([[FLASHFlashController sharedFlashController] berryView:self
                                          shouldIgnoreHitTest:point
                                                    withEvent:event]) {
    return nil;
  }
  return %orig;
}
%end

%ctor {
  %init;
}
