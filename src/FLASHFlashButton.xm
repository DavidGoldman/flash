#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "FLASHFlashButton.h"

#import "FLASHFlashController.h"
#import "Macros.h"

#import "SBFLockScreenMetrics.h"
#import "SBLockScreenViewHeaders.h"
#import "SBSlideUpAppGrabberView.h"
#import "UIImage+Private.h"

static const CGFloat kOnAlpha = 1;
static const CGFloat kOffAlpha = 0.6;

static const NSTimeInterval kHideTimerInterval = 3;
static const NSTimeInterval kAnimationDuration = 0.35;

static NSString * const kColorFlowSecondaryColorKey = @"SecondaryColor";

static UIGestureRecognizer * getLockScreenScrollViewPanGestureRecognizer() {
  SBLockScreenViewController *vc =
      [[%c(SBLockScreenManager) sharedInstance] lockScreenViewController];
  if ([vc respondsToSelector:@selector(lockScreenScrollView)]) {
    return [vc lockScreenScrollView].panGestureRecognizer;  
  }
  return nil;
}

@interface FLASHFlashButton()
@property(nonatomic, weak) id<FLASHFlashButtonDelegate> delegate;
@end

@implementation FLASHFlashButton {
  UIImageView *_flashImageView;
  SBSlideUpAppGrabberView *_slideUpAppGrabberView;
  NSTimer *_hideTimer;
}

- (instancetype)initWithFrame:(CGRect)frame classicIcon:(BOOL)classicIcon {
  self = [super initWithFrame:frame];
  if (self) {
    UITapGestureRecognizer *tapGestureRecogizer =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleTap:)];
    [self addGestureRecognizer:tapGestureRecogizer];
    [getLockScreenScrollViewPanGestureRecognizer() requireGestureRecognizerToFail:tapGestureRecogizer];

    NSBundle *bundle = [NSBundle bundleWithPath:kPrefsBundlePath];
    if (classicIcon) {
      UIImage *icon = [UIImage imageNamed:@"Flash" inBundle:bundle];
      _flashImageView = [[UIImageView alloc] initWithImage:icon];
      _flashImageView.alpha = kOffAlpha;
      [self addSubview:_flashImageView];
    } else {
      UIImage *icon = [UIImage imageNamed:@"FlashGhosted" inBundle:bundle];
      _slideUpAppGrabberView = [[%c(SBSlideUpAppGrabberView) alloc] initWithAdditionalTopPadding:NO
                                                                            invertVerticalInsets:NO];
      if ([_slideUpAppGrabberView respondsToSelector:@selector(setGrabberImage:)]) {
        [_slideUpAppGrabberView setGrabberImage:icon];
        [_slideUpAppGrabberView sizeToFit];
      } else {
        CGSize iconSize = icon.size;
        CGRect frame = CGRectMake(0, 0, iconSize.width, iconSize.height);

        CALayer *maskLayer = [CALayer layer];
        maskLayer.frame = frame;
        maskLayer.contents = (id)icon.CGImage;
        _slideUpAppGrabberView.layer.mask = maskLayer;
        _slideUpAppGrabberView.frame = frame;
      }
      _slideUpAppGrabberView.vibrancyAllowed = YES;
      _slideUpAppGrabberView.alpha = kOffAlpha;
      _slideUpAppGrabberView.userInteractionEnabled = NO;
      [self addSubview:_slideUpAppGrabberView];
    }

    _visible = NO;
    self.alpha = 0;
  }
  return self;
}


- (void)didMoveToWindow {
  [super didMoveToWindow];
  if (self.window) {
    [[FLASHFlashController sharedFlashController] addDelegate:self];
  } else {
    [[FLASHFlashController sharedFlashController] removeDelegate:self];
  }
}

- (void)layoutSubviews {
  [super layoutSubviews];

  UIView *iconView = [self _iconView];
  const CGFloat cornerInset = [%c(SBFLockScreenMetrics) slideUpGrabberInset];
  const CGSize imageSize = iconView.frame.size;
  CGRect bounds = self.bounds;
  CGFloat x;
  UIApplication *app = [UIApplication sharedApplication];
  if (app.userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionLeftToRight) {
    x = CGRectGetMinX(bounds) + cornerInset;
  } else {
    x = CGRectGetMaxX(bounds) - cornerInset - imageSize.width;
  }
  CGRect frame = CGRectMake(x, CGRectGetMaxY(bounds) - cornerInset - imageSize.height,
                            imageSize.width, imageSize.height);
  iconView.frame = frame;
}

- (void)_handleTap:(UIGestureRecognizer *)sender {
  [[FLASHFlashController sharedFlashController] flashButtonTapped:self];
}

- (UIView *)_iconView {
  return (_flashImageView) ? _flashImageView : _slideUpAppGrabberView;
}

- (SBSlideUpAppGrabberView *)slideUpAppGrabberView {
  return _slideUpAppGrabberView;
}

#pragma mark - Timering

- (void)_addTimer {
  if (!_hideTimer && ![self.delegate shouldFlashButtonSuppressHideTimer:self]) {
    _hideTimer = [NSTimer scheduledTimerWithTimeInterval:kHideTimerInterval
                                                  target:self
                                                selector:@selector(_timerDidFire:)
                                                userInfo:nil
                                                 repeats:NO];
  }
}

- (void)_removeTimer {
  if (_hideTimer) {
    [_hideTimer invalidate];
    _hideTimer = nil;
  }
}

- (void)_timerDidFire:(NSTimer *)timer {
  [self setVisible:NO immediately:YES animated:YES];
}

#pragma mark - Visibility

- (void)setVisible:(BOOL)visible {
  [self setVisible:visible immediately:NO animated:YES];
}

// Here's the behavior that we want:
//
// - setVisible (immediately or not) starts a hide timer that is cancelled and re-created when we
//   setVisible again.
// - Immediate hide does it immediately, no questions asked.
// - Non-immediate hide waits for the hide timer to fire then does it.
//
// Note that a scheduled hide is always animated and that the immediately argument is useless
// if visible is YES.
- (void)setVisible:(BOOL)visible immediately:(BOOL)immediately animated:(BOOL)animated {
  if (_visible != visible) {
    if (visible) { // Set visible, refresh timer.
      _visible = visible;
      [self _removeTimer];
      [self _addTimer];
      [self _visibilityChangedAnimated:animated];
    } else if (immediately) { // Immediate Hide, removeTimer.
      _visible = visible;
      [self _removeTimer];
      [self _visibilityChangedAnimated:animated];
    } else { // Non-immediate Hide. Schedule.
      [self _addTimer];
    }
  } else if (visible) { // Still visible, refresh timer.
    [self _removeTimer];
    [self _addTimer];
  }
}

// Changes the visiblity and notifies the delegate. When setting to visible, it notifies the
// delegate immediately. Otherwise, it notifies the delegate when the button is no longer visible
// (i.e. animation completes).
- (void)_visibilityChangedAnimated:(BOOL)animated {
  BOOL visible = _visible;
  if (animated) {
    void (^completionBlock)(BOOL) = nil;
    if (visible) {
      [self _notifyDelegate];
    } else {
      completionBlock = ^(BOOL finished) {
          if (_visible == visible) {
            [self _notifyDelegate];
          }
      };
    }

    UIViewAnimationOptions options = UIViewAnimationOptionAllowUserInteraction |
        UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut |
        UIViewAnimationOptionTransitionNone;
    [UIView animateWithDuration:kAnimationDuration
                          delay:0
                        options:options
                     animations:^{
                         self.alpha = (visible) ? 1 : 0;
                     }
                     completion:completionBlock];
  } else {
    self.alpha = (visible) ? 1 : 0;
    [self _notifyDelegate];
  }
}

#pragma mark - Delegate

- (void)_notifyDelegate {
  [self.delegate flashButton:self becameVisible:_visible];
}

- (void)setDelegate:(id<FLASHFlashButtonDelegate>)delegate {
  if (![_delegate isEqual:delegate]) {
    _delegate = delegate;
    [self _notifyDelegate];
  }
}

#pragma mark - Coloring

- (void)colorizeWithInfo:(NSDictionary *)info {
  UIColor *color = info[kColorFlowSecondaryColorKey];
  if ([_slideUpAppGrabberView respondsToSelector:@selector(cfw_colorizeWithColor:)]) {
    [_slideUpAppGrabberView cfw_colorizeWithColor:color];
  }
}

#pragma mark - FLASHFlashlightDelegate

- (void)flashlightDidTurnOn:(BOOL)flag {
  if (flag != self.flashlightOn) {
    self.flashlightOn = flag;

    [self _iconView].alpha = (flag) ? kOnAlpha : kOffAlpha;
  }
}

@end
