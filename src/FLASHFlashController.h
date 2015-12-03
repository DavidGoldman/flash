@class FLASHFlashButton, SBCCFlashlightSetting;

@protocol FLASHFlashlightDelegate <NSObject>
- (void)flashlightDidTurnOn:(BOOL)on;
@end

@interface FLASHFlashController : NSObject
+ (instancetype)sharedFlashController;

- (void)flashButtonTapped:(FLASHFlashButton *)button;
- (void)onAmbientLightSensorEvent:(int)lux;
- (BOOL)berryView:(UIView *)berryView shouldIgnoreHitTest:(CGPoint)test withEvent:(UIEvent *)event;

- (void)addDelegate:(id<FLASHFlashlightDelegate>)delegate;
- (void)removeDelegate:(id<FLASHFlashlightDelegate>)delegate;

- (void)onFlashlightSettingInit:(SBCCFlashlightSetting *)setting;
- (void)onFlashlightSettingDealloc:(SBCCFlashlightSetting *)setting;
@end
