#import "FLASHFlashButton.h"

#import "FLASHFlashController.h"
#import "Macros.h"

#import "SBFLockScreenMetrics.h"
#import "SBFWeakReference.h"
#import "SBLockScreenViewHeaders.h"
#import "SBSlideUpAppGrabberView.h"
#import "UIImage+Private.h"

static const CGFloat kOnAlpha = 1;
static const CGFloat kOffAlpha = 0.6;

static const NSTimeInterval kHideTimerInterval = 3;
static const NSTimeInterval kAnimationDuration = 0.35;

static NSString * const kColorFlowSecondaryColorKey = @"SecondaryColor";

static SBLockScreenScrollView * getLockScreenScrollView() {
  SBLockScreenViewController *vc =
      [[%c(SBLockScreenManager) sharedInstance] lockScreenViewController];
  return [vc lockScreenScrollView];
}

@implementation FLASHFlashButton {
  UIImageView *_flashImageView;
  SBSlideUpAppGrabberView *_slideUpAppGrabberView;
  SBFWeakReference *_delegateWeakRef;
  NSTimer *_hideTimer;
}

- (instancetype)initWithFrame:(CGRect)frame classicIcon:(BOOL)classicIcon {
  self = [super initWithFrame:frame];
  if (self) {
    UITapGestureRecognizer *tapGestureRecogizer =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleTap:)];
    [self addGestureRecognizer:tapGestureRecogizer];
    [getLockScreenScrollView().panGestureRecognizer requireGestureRecognizerToFail:tapGestureRecogizer];
    [tapGestureRecogizer release];

    NSBundle *bundle = [NSBundle bundleWithPath:kBundlePath];
    if (classicIcon) {
      UIImage *icon = [UIImage imageNamed:@"Flash" inBundle:bundle];
      _flashImageView = [[UIImageView alloc] initWithImage:icon];
      _flashImageView.alpha = kOffAlpha;
      [self addSubview:_flashImageView];
    } else {
      UIImage *icon = [UIImage imageNamed:@"FlashGhosted" inBundle:bundle];
      _slideUpAppGrabberView = [[%c(SBSlideUpAppGrabberView) alloc] initWithAdditionalTopPadding:NO
                                                                            invertVerticalInsets:NO];
      [_slideUpAppGrabberView setGrabberImage:icon];
      [_slideUpAppGrabberView sizeToFit];
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

- (void)dealloc {
  // _hideTimer must be nil otherwise we wouldn't dealloc (it holds a strong ref to us).
  [_flashImageView release];
  [_slideUpAppGrabberView release];
  [_delegateWeakRef release];
  [super dealloc];
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
  if (!_hideTimer) {
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:kHideTimerInterval
                                                      target:self
                                                    selector:@selector(_timerDidFire:)
                                                    userInfo:nil
                                                     repeats:NO];
    _hideTimer = [timer retain];
  }
}

- (void)_removeTimer {
  if (_hideTimer) {
    [_hideTimer invalidate];
    [_hideTimer release];
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

- (id<FLASHFlashButtonDelegate>)delegate {
  return [_delegateWeakRef object];
}

- (void)setDelegate:(id<FLASHFlashButtonDelegate>)delegate {
  if (!delegate) {
    [_delegateWeakRef release];
    _delegateWeakRef = nil;
    return;
  }
  id<FLASHFlashButtonDelegate> currentDelegate = self.delegate;
  if (![currentDelegate isEqual:delegate]) {
    [_delegateWeakRef release];
    _delegateWeakRef = [[%c(SBFWeakReference) alloc] initWithObject:delegate];
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
