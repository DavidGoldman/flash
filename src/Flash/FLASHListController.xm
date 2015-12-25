#import "FLASHListController.h"

#import "FLASHHeaderCell.h"
#import "FLASHSwitchTableCell.h"

#import "../UIImage+Private.h"

static UIColor * UIColorFromRGB(int rgb) {
  return [UIColor colorWithRed:((rgb >> 16) & 0xFF) / 255.0F
                         green:((rgb >> 8) & 0xFF) / 255.0F
                          blue:(rgb & 0xFF) / 255.0F
                         alpha:1];
}

@implementation FLASHListController

- (id)specifiers {
  if(_specifiers == nil) {
    _specifiers = [[self loadSpecifiersFromPlistName:@"Flash" target:self] retain];

    Class PSUIDisplayController = %c(PSUIDisplayController);
    if (PSUIDisplayController) {
      PSSpecifier *luxCutoffSpecifier = [_specifiers specifierForID:@"LuxCutoff"];
      NSBundle *bundle = [NSBundle bundleForClass:PSUIDisplayController];
      UIImage *leftImage = [UIImage imageNamed:@"LessBright" inBundle:bundle];
      UIImage *rightImage = [UIImage imageNamed:@"MoreBright" inBundle:bundle];
      if (leftImage && rightImage) {
        [luxCutoffSpecifier setProperty:leftImage forKey:@"leftImage"];
        [luxCutoffSpecifier setProperty:rightImage forKey:@"rightImage"];
      }
    }
  }
  return _specifiers;
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
