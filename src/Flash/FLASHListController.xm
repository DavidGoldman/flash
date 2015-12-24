#import "FLASHListController.h"

#import "FLASHHeaderCell.h"
#import "FLASHSwitchTableCell.h"

@implementation FLASHListController

- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Flash" target:self] retain];
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
  FLASHHeaderCell *headerCell = [self headerCell];
  if (headerCell) {
    CGFloat actualOffset = scrollView.contentOffset.y + [self contentYInset];
    [headerCell setContentYOffset:actualOffset];
  }
}

- (CGFloat)contentYInset {
  return [self table].contentInset.top;
}

- (FLASHHeaderCell *)headerCell {
  UIView *view = [self tableView:[self table] viewForHeaderInSection:0];
  if ([view isMemberOfClass:[FLASHHeaderCell class]]) {
    return (FLASHHeaderCell *)view;
  }
  return nil;
}

@end
