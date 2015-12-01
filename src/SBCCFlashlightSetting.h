@interface SBCCFlashlightSetting : NSObject
@property(assign, nonatomic, getter=isFlashlightOn) BOOL flashlightOn;

- (void)toggleState;
@end
