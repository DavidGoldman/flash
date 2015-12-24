#import "PreferenceHeaders/PSControlTableCell.h"
#import "PreferenceHeaders/PSListController.h"
#import "PreferenceHeaders/PSSpecifier.h"
#import "PreferenceHeaders/PSSwitchTableCell.h"
#import "PreferenceHeaders/PSTableCell.h"
#import "PreferenceHeaders/PSViewController.h"

@protocol PreferencesTableCustomView
- (id)initWithSpecifier:(id)specifier;
@optional
- (CGFloat)preferredHeightForWidth:(CGFloat)width;
- (CGFloat)preferredHeightForWidth:(CGFloat)width inTableView:(id)tableView;
@end

@interface UITableViewCell (Private)
@property(nonatomic, assign) UITableViewCellSeparatorStyle separatorStyle;
@end

@interface NSArray(Private)
- (id)specifierForID:(id)id;
@end
