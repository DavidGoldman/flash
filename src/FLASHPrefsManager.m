#import "FLASHPrefsManager.h"

#define kAppID "com.golddavid.flash"
#define kPrefsReloadDarwinNotification "com.golddavid.flash/ReloadPrefs"

static NSString * const kEnabledKey = @"Enabled";
static NSString * const kGhostedIconKey = @"GhostedIcon";
static NSString * const kHandoffKey = @"OverrideHandoff";
static NSString * const kCutoffKey = @"LuxCutoff";
static NSString * const kLightCheckKey = @"IgnoreLightCheck";
static const BOOL kDefaultEnabled = YES;
static const BOOL kDefaultGhostedIcon = NO;
static const BOOL kDefaultOverrideHandoff = NO;
static const BOOL kDefaultIgnoreLightCheck = NO;
static const int kDefaultLuxCutoff = 6;

static void refreshPrefs(CFNotificationCenterRef center, void *observer, CFStringRef name,
                         const void *object, CFDictionaryRef userInfo) {
  [(FLASHPrefsManager *)observer reload];
}

@implementation FLASHPrefsManager

+ (instancetype)sharedInstance {
  static dispatch_once_t predicate;
  static FLASHPrefsManager *manager;
  dispatch_once(&predicate, ^{ manager = [[self alloc] init]; });
  return manager;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _enabled = kDefaultEnabled;
    _ghostedIcon = kDefaultGhostedIcon;
    _overrideHandoff = kDefaultOverrideHandoff;
    _luxCutoff = kDefaultLuxCutoff;
    _ignoreLightCheck = kDefaultIgnoreLightCheck;

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), 
                                    self,
                                    &refreshPrefs,
                                    CFSTR(kPrefsReloadDarwinNotification),
                                    NULL,
                                    0);
    [self reload];
  }
  return self;
}

- (NSDictionary *)prefsDictionary {
  CFStringRef appID = CFSTR(kAppID);
  CFArrayRef keyList = CFPreferencesCopyKeyList(appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
  if (!keyList) {
    return nil;
  }
  NSDictionary *dictionary = (NSDictionary *)CFPreferencesCopyMultiple(keyList, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
  CFRelease(keyList);
  return [dictionary autorelease];
}

- (void)reload {
  NSDictionary *prefs = [self prefsDictionary];
  self.enabled = [self boolForValue:prefs[kEnabledKey] withDefault:kDefaultEnabled];
  self.ghostedIcon = [self boolForValue:prefs[kGhostedIconKey] withDefault:kDefaultGhostedIcon];
  self.overrideHandoff = [self boolForValue:prefs[kHandoffKey] withDefault:kDefaultOverrideHandoff];
  self.ignoreLightCheck = [self boolForValue:prefs[kLightCheckKey] withDefault:kDefaultIgnoreLightCheck];
  self.luxCutoff = [self intForValue:prefs[kCutoffKey] withDefault:kDefaultLuxCutoff];
}

- (BOOL)boolForValue:(NSNumber *)value withDefault:(BOOL)defaultValue {
  return (value) ? [value boolValue] : defaultValue;
}

- (int)intForValue:(NSNumber *)value withDefault:(int)defaultValue {
  return (value) ? [value intValue] : defaultValue;
}

- (void)dealloc {
  CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                     self,
                                     CFSTR(kPrefsReloadDarwinNotification),
                                     NULL);
  [super dealloc];
}

@end
