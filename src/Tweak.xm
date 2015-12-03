#import "Macros.h"
#import "BCBerryView.h"
#import "FLASHFlashButton.h"
#import "FLASHFlashController.h"
#import "SBCCFlashlightSetting.h"
#import "SBLockScreenViewHeaders.h"

const NSInteger kFlashButtonTag = 0x666c7368;
const CGFloat kButtonPadding = 0;
const CGFloat kButtonSize = 50;

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
- (void)FLASH_addOrRemoveButton:(BOOL)addButton {
  UIView *foregroundLockHUDView = MSHookIvar<UIView *>(self, "_foregroundLockHUDView");
  UIView *button = (UIView *) [foregroundLockHUDView viewWithTag:kFlashButtonTag];

  if (addButton) {
    if (!button) {
      // This can be called from within an animation block, so we have to be careful as we don't
      // want the init occurring with an animation.
      [UIView performWithoutAnimation:^{
          FLASHFlashButton *fb = [[FLASHFlashButton alloc] initWithFrame:CGRectZero];
          fb.tag = kFlashButtonTag;
          [foregroundLockHUDView addSubview:fb];
          [fb release];
      }];
    }
  } else {
    [button removeFromSuperview];
  }
}

- (void)setBottomLeftGrabberView:(UIView *)view {
  %orig;
  NSMutableSet *requesters = MSHookIvar<NSMutableSet *>(self, "_bottomLeftGrabberHiddenRequesters");
  [self FLASH_addOrRemoveButton:(!view && requesters.count == 0)];
}
- (void)setBottomLeftGrabberHidden:(BOOL)hidden forRequester:(id)requester {
  %orig;
  NSMutableSet *requesters = MSHookIvar<NSMutableSet *>(self, "_bottomLeftGrabberHiddenRequesters");
  [self FLASH_addOrRemoveButton:(!self.bottomLeftGrabberView && requesters.count == 0)];
}
- (void)_layoutBottomLeftGrabberView {
  %orig;

  UIView *foregroundLockHUDView = MSHookIvar<UIView *>(self, "_foregroundLockHUDView");
  UIView *button = (UIView *) [foregroundLockHUDView viewWithTag:kFlashButtonTag];
  if (button) {
    CGRect frame = foregroundLockHUDView.bounds;
    CGRect newFrame = CGRectMake(CGRectGetMinX(frame) + kButtonPadding,
                                 CGRectGetMaxY(frame) - kButtonPadding - kButtonSize,
                                 kButtonSize, kButtonSize);
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
