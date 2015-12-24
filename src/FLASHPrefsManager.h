@interface FLASHPrefsManager : NSObject
@property(nonatomic, assign, getter=isEnabled) BOOL enabled;
@property(nonatomic, assign, getter=useGhostedIcon) BOOL ghostedIcon;
@property(nonatomic, assign, getter=shouldOverrideHandoff) BOOL overrideHandoff;
@property(nonatomic, assign) int luxCutoff;

+ (instancetype)sharedInstance;
- (void)reload;

@end
