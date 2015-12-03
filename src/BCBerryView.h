@interface BCBerryView : UIView
@property(nonatomic, retain) UIScrollView *scrollView;
@property(nonatomic, retain) NSMutableArray *appViews;

+ (instancetype)sharedInstanceForFrame:(CGRect)frame;
@end
