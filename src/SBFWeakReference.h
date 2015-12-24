// BB come back, <3 you ARC.
@interface SBFWeakReference : NSObject
+ (id)weakReferenceWithObject:(id)object;

- (instancetype)initWithObject:(id)object;
- (id)object;
@end
