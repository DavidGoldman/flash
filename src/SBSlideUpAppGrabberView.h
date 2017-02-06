@class _SBFVibrantSettings;

@interface SBSlideUpAppGrabberView : UIView
@property(assign, nonatomic, getter=isVibrancyAllowed) BOOL vibrancyAllowed;
@property(retain, nonatomic) _SBFVibrantSettings *vibrantSettings;

- (id)initWithAdditionalTopPadding:(BOOL)additionalTopPadding invertVerticalInsets:(BOOL)insets;

// iOS 8 - 9
- (void)setGrabberImage:(UIImage *)image;
- (void)setStrength:(CGFloat)strength;

- (void)updateForChangedSettings:(id)settings;
- (void)setLegibilitySettings:(id)settings;
@end
@interface SBSlideUpAppGrabberView (ColorFlow2)
- (void)cfw_colorizeWithColor:(UIColor *)color;
@end
