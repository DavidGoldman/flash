#import "FLASHListController.h"

#import "FLASHHeaderCell.h"
#import "FLASHSwitchTableCell.h"

#import "../UIImage+Private.h"

#define kAppID "com.golddavid.flash"

static UIColor * UIColorFromRGB(int rgb) {
  return [UIColor colorWithRed:((rgb >> 16) & 0xFF) / 255.0F
                         green:((rgb >> 8) & 0xFF) / 255.0F
                          blue:(rgb & 0xFF) / 255.0F
                         alpha:1];
}

@implementation FLASHListController {
  NSArray *_lightLevelSpecifiers;
}

- (id)specifiers {
  if(_specifiers == nil) {
    NSMutableArray *specifiers = [[self loadSpecifiersFromPlistName:@"Flash" target:self] mutableCopy];

    Class DisplayController = %c(PSUIDisplayController); // Appears to be iOS 9+.
    if (!DisplayController) { // iOS 8.
      DisplayController = %c(DisplayController);
    }
    if (DisplayController) {
      PSSpecifier *luxCutoffSpecifier = [specifiers specifierForID:@"LuxCutoff"];
      NSBundle *bundle = [NSBundle bundleForClass:DisplayController];
      UIImage *leftImage = [UIImage imageNamed:@"LessBright" inBundle:bundle];
      UIImage *rightImage = [UIImage imageNamed:@"MoreBright" inBundle:bundle];
      if (leftImage && rightImage) {
        [luxCutoffSpecifier setProperty:leftImage forKey:@"leftImage"];
        [luxCutoffSpecifier setProperty:rightImage forKey:@"rightImage"];
      }
    }

    // Handle light level specifiers.
    [_lightLevelSpecifiers release];
    _lightLevelSpecifiers = [[self specifiersIn:specifiers fromID:@"LightLevelText" toID:@"LuxCutoff"] retain];
    if (CFPreferencesGetAppBooleanValue(CFSTR("IgnoreLightCheck"),
                                        CFSTR(kAppID),
                                        NULL)) {
      [specifiers removeObjectsInArray:_lightLevelSpecifiers];
    }

    // Actually update _specifiers.
    _specifiers = [specifiers copy];
    [specifiers release];
  }
  return _specifiers;
}

- (NSArray *)specifiersIn:(NSArray *)specifiers fromID:(NSString *)from toID:(NSString *)to {
  NSMutableArray *array = [NSMutableArray array];
  PSSpecifier *a = [specifiers specifierForID:from];
  PSSpecifier *b = [specifiers specifierForID:to];
  if (!a || !b) {
    return array;
  }
  NSUInteger start = [specifiers indexOfObject:a];
  NSUInteger end = [specifiers indexOfObject:b];
  if (start < end) {
    for (NSUInteger i = start; i <= end; ++i) {
      [array addObject:specifiers[i]];
    }
  }
  return array;
}

// Thanks to MultitaskingGestures (https://github.com/hamzasood/MultitaskingGestures).
- (void)setIgnoreLightCheckEnabled:(NSNumber *)value forSpecifier:(PSSpecifier *)specifier {
  [self setPreferenceValue:value specifier:specifier];
  if (![value boolValue]) {
    int index = [_specifiers indexOfObject:specifier] + 1;
    [self insertContiguousSpecifiers:_lightLevelSpecifiers 
                             atIndex:index
                            animated:YES];
  } else {
    [self removeContiguousSpecifiers:_lightLevelSpecifiers animated:YES];
  }
}

- (id)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

  // Oh god the hacks. Remove the separator between the slider cell and the cell before it.
  // This hack is from http://stackoverflow.com/a/32818943.
  if ([cell isKindOfClass:%c(PSTableCell)]) {
    PSSpecifier *specifier = ((PSTableCell *) cell).specifier;
    NSString *identifier = specifier.identifier;

    if ([identifier isEqualToString:@"LightLevelText"]) {
      CGFloat inset = cell.bounds.size.width * 10;
      cell.separatorInset = UIEdgeInsetsMake(0, inset, 0, 0);
      cell.indentationWidth = -inset;
      cell.indentationLevel = 1;
    }
    if ([identifier isEqualToString:@"Enabled"] && [cell isMemberOfClass:[FLASHSwitchTableCell class]]) {
      ((FLASHSwitchTableCell *)cell).hidesSeparators = YES;
    }
  }
  return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  FLASHHeaderCell *headerCell = [self _headerCell];
  if (headerCell) {
    CGFloat actualOffset = scrollView.contentOffset.y + [self _contentYInset];
    [headerCell setContentYOffset:actualOffset];
  }
}

#pragma mark - Private Stuff

- (CGFloat)_contentYInset {
  return [self table].contentInset.top;
}

- (FLASHHeaderCell *)_headerCell {
  UIView *view = [self tableView:[self table] viewForHeaderInSection:0];
  if ([view isMemberOfClass:[FLASHHeaderCell class]]) {
    return (FLASHHeaderCell *)view;
  }
  return nil;
}

#pragma mark - View Lifecycle

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [[UIApplication sharedApplication] keyWindow].tintColor = UIColorFromRGB(0xFFCD02);
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [[UIApplication sharedApplication] keyWindow].tintColor = nil;
}

@end
