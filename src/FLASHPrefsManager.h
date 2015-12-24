@interface FLASHPrefsManager : NSObject
@property(nonatomic, assign, getter=useClassicIcon) BOOL classicIcon;
@property(nonatomic, assign, getter=shouldOverrideHandoff) BOOL overrideHandoff;
@property(nonatomic, assign) int luxCutoff;

+ (instancetype)sharedInstance;
- (void)reload;

@end
