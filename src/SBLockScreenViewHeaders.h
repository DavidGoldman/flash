@interface SBLockScreenScrollView : UIScrollView
@end

@interface SBLockScreenView : UIView
@property(retain, nonatomic) UIView *bottomLeftGrabberView;

- (void)FLASH_addOrRemoveButton:(BOOL)addButton;
@end

@interface SBLockScreenViewController : UIViewController
- (SBLockScreenScrollView *)lockScreenScrollView;
@end

@interface SBLockScreenManager : NSObject
+ (instancetype)sharedInstance;
- (SBLockScreenViewController *)lockScreenViewController;
@end
