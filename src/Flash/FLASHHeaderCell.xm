#import "FLASHHeaderCell.h"

#import "../Macros.h"
#import "../UIImage+Private.h"

static const CGFloat kForegroundParallaxFactor = 0.2;
static const CGFloat kOverlayParallaxFactor = 0.3;

static CGFloat screenIntegral(CGFloat dim) {
  UIScreen *screen = [UIScreen mainScreen];
  CGFloat scale = screen.scale;
  CGFloat dimInPixels = CG_FLOAT_ROUND(dim * scale);
  return dimInPixels / scale;
}

@implementation FLASHHeaderCell {
  UIImageView *_backgroundView;
  UIImageView *_foregroundView;
  UIImageView *_overlayView;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(id)reuseIdentifier
                    specifier:(id)specifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];
  if (self) {
    NSBundle *bundle = [NSBundle bundleWithPath:kPrefsBundlePath];
    UIImage *backgroundImage = [UIImage imageNamed:@"Banner" inBundle:bundle];
    UIImage *foregroundImage = [UIImage imageNamed:@"Icons" inBundle:bundle];
    UIImage *overlayImage = [UIImage imageNamed:@"Icon" inBundle:bundle];
    _backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
    _foregroundView = [[UIImageView alloc] initWithImage:foregroundImage];
    _overlayView = [[UIImageView alloc] initWithImage:overlayImage];
    _backgroundView.contentMode = UIViewContentModeScaleAspectFit;
    _foregroundView.contentMode = UIViewContentModeScaleAspectFit;
    _overlayView.contentMode = UIViewContentModeScaleAspectFit;

    [self addSubview:_backgroundView];
    [self addSubview:_foregroundView];
    [self addSubview:_overlayView];
    self.clipsToBounds = YES;
  }
  return self;
}

- (instancetype)initWithSpecifier:(id)specifier {
  UITableViewCellStyle style = UITableViewCellStyleDefault;
  return [self initWithStyle:style reuseIdentifier:@"FLASHHeaderCell" specifier:specifier];
}

#pragma mark - Protocols

- (CGFloat)preferredHeightForWidth:(CGFloat)width {
  // Appears to be zero on the first call for w/e stupid reason. That breaks things?
  if (width == 0) {
    width = [UIScreen mainScreen].bounds.size.width;
  }
  // Our background has a ratio of 3.75w : 1h.
  return screenIntegral(width / 3.75);
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width inTableView:(id)tableView {
  return [self preferredHeightForWidth:width];
}

#pragma mark - Hacks

// This is needed, otherwise the TableView thinks that this header needs to treated as TableViewCell
// and when we animate the specifiers, it somehow removes the specifier from this view causing it to
// be hidden.
- (BOOL)isKindOfClass:(Class)clazz {
  if (clazz == %c(UITableViewCell)) {
    return NO;
  }
  return [super isKindOfClass:clazz];
}

#pragma mark - Overrides

- (void)layoutSubviews {
  [super layoutSubviews];

  CGRect bounds = self.bounds;
  _backgroundView.frame = bounds;
  [self _layoutParallaxView:_foregroundView
                  baseFrame:bounds
             parallaxFactor:kForegroundParallaxFactor];
  [self _layoutParallaxView:_overlayView
                  baseFrame:[self _overlayFrame]
             parallaxFactor:kOverlayParallaxFactor];
}

// Fix for iPad alignment issue.  
- (void)setFrame:(CGRect)frame {
  frame.origin.x = 0;
  [super setFrame:frame];
}

- (void)dealloc {
  [_backgroundView release];
  [_foregroundView release];
  [_overlayView release];
  [super dealloc];
}

#pragma mark - Properties

- (void)setContentYOffset:(CGFloat)contentYOffset {
  if (contentYOffset != _contentYOffset) {
    _contentYOffset = contentYOffset;
    [self setNeedsLayout];
  }
}

#pragma mark - Private Stuff

- (void)_layoutParallaxView:(UIView *)view
                  baseFrame:(CGRect)frame
             parallaxFactor:(CGFloat)factor {
  frame.origin.y -= self.contentYOffset * factor;
  // if (clamp) {
  //   CGRect bounds = self.bounds;
  //   CGFloat min = CGRectGetMinY(bounds);
  //   CGFloat max = CGRectGetMaxY(bounds);
  //   if (CGRectGetMinY(frame) < min) {
  //     frame.origin.y = min;
  //   } else if (CGRectGetMaxY(frame) > max) {
  //     frame.origin.y = max - CGRectGetHeight(frame);
  //   }
  // }
  view.frame = frame;
}

- (CGRect)_overlayFrame {
  CGRect bounds = self.bounds;
  CGFloat scale = bounds.size.width / 375 / 2;
  CGSize size = _overlayView.image.size;
  size.width = screenIntegral(size.width * scale);
  size.height = screenIntegral(size.height * scale);
  return CGRectMake(screenIntegral(CGRectGetMidX(bounds) - size.width / 2),
                    screenIntegral(CGRectGetMidY(bounds) - size.height / 2),
                    size.width, size.height);
}

@end
