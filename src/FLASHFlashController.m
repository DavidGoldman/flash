#import "FLASHFlashController.h"

#include <IOKit/hid/IOHIDEventSystemClient.h>

#import "Macros.h"
#import "FLASHFlashButton.h"
#import "SBCCFlashlightSetting.h"

static const int kDefaultHashTableCapacity = 8;
static const int kSensorInterval = (int) (0.5 * 1000000); // Check every half second.
static const int kPrimaryUsagePage = 0xff00;
static const int kPrimaryUsage = 4;

// You can lower this if it's triggering when there's a decent amount of light. The min lux value is
// 0, so this should be >= 1.
static const int kMinLuxForHidden = 6;
static const int kUnassignedLux = -1;

static NSString * const kBacklightNotification = @"SBBacklightLevelChangedNotification";
static NSString * const kBacklightKey = @"SBBacklightNewFactorKey";

static void handleHIDEvent(void *target, void *refcon, IOHIDEventQueueRef queue, IOHIDEventRef event) {
  if (IOHIDEventGetType(event) == kIOHIDEventTypeAmbientLightSensor) {
    FLASHFlashController *flashController = (FLASHFlashController *)target;
    int lux = IOHIDEventGetIntegerValue(event, (IOHIDEventField) kIOHIDEventFieldAmbientLightSensorLevel);
    [flashController onAmbientLightSensorEvent:lux];
  }
}

@implementation FLASHFlashController {
  SBCCFlashlightSetting *_flashlightSetting;
  NSHashTable *_delegates;
  IOHIDEventSystemClientRef _eventSystemClient;
  int _prevLux;
  BOOL _eventSystemClientRegistered;
  BOOL _screenIsOn;
  BOOL _showDelegates;
}

+ (instancetype)sharedFlashController {
  static dispatch_once_t predicate;
  static FLASHFlashController *controller;
  dispatch_once(&predicate, ^{ controller = [[self alloc] init]; });
  return controller;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    NSHashTableOptions options = NSHashTableWeakMemory | NSHashTableObjectPointerPersonality;
    _delegates = [[NSHashTable alloc] initWithOptions:options capacity:kDefaultHashTableCapacity];
    

    _prevLux = kUnassignedLux;
    _screenIsOn = YES;
    _eventSystemClient = IOHIDEventSystemClientCreate(kCFAllocatorDefault);
    CFDictionaryRef matchingFilter = (CFDictionaryRef) @{
        @"PrimaryUsagePage" : @(kPrimaryUsagePage),
        @"PrimaryUsage" : @(kPrimaryUsage)
    };
    IOHIDEventSystemClientSetMatching(_eventSystemClient, matchingFilter);
    CFArrayRef services = IOHIDEventSystemClientCopyServices(_eventSystemClient);
    if (services) {
      if (CFArrayGetCount(services) == 1) {
        IOHIDServiceClientRef service = (IOHIDServiceClientRef) CFArrayGetValueAtIndex(services, 0);
        IOHIDServiceClientSetProperty(service, CFSTR("ReportInterval"), (CFNumberRef) @(kSensorInterval));
      } else {
        INFO(@"Whack systemClientServices %@", services);
      }
      CFRelease(services);
    } else {
      INFO(@"IOHIDEventSystemClientCopyServices returned nil");
    }

    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self
                      selector:@selector(_handleBacklightNotification:)
                          name:kBacklightNotification
                        object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kBacklightNotification object:nil];
  [self onFlashlightSettingDealloc:_flashlightSetting];

  [self _unbindSystemClient];
  CFRelease(_eventSystemClient);

  [_delegates release];
  [super dealloc];
}

- (void)flashButtonTapped:(FLASHFlashButton *)button {
  [_flashlightSetting toggleState];
}

- (void)onAmbientLightSensorEvent:(int)lux {
  BOOL flashOn = _flashlightSetting.flashlightOn;
  if (!flashOn && _prevLux == kUnassignedLux) {
    _prevLux = lux;
    return;
  }
  BOOL show = flashOn || (_prevLux + lux < 2 * kMinLuxForHidden);
  _prevLux = lux;
  [self _showDelegates:show immediately:NO];
}

- (BOOL)berryView:(UIView *)berryView shouldIgnoreHitTest:(CGPoint)test withEvent:(UIEvent *)event {
  for (id<FLASHFlashlightDelegate> delegate in _delegates) {
    if ([delegate isKindOfClass:[FLASHFlashButton class]]) {
      FLASHFlashButton *button = (FLASHFlashButton *)delegate;
      if (!button.visible) {
        continue;
      }
      CGPoint point = [button convertPoint:test fromView:berryView];
      if ([button hitTest:point withEvent:event]) {
        return YES;
      }
    }
  }
  return NO;
}

// Dirty, but w/e.
- (void)_showDelegates:(BOOL)show immediately:(BOOL)immediately {
  _showDelegates = show;

  for (id<FLASHFlashlightDelegate> delegate in _delegates) {
    if ([delegate isKindOfClass:[FLASHFlashButton class]]) {
      FLASHFlashButton *button = (FLASHFlashButton *)delegate;
      [button setVisible:show immediately:immediately animated:!immediately];
    }
  }
}

- (void)_handleBacklightNotification:(NSNotification *)notification {
  // This seems to just be 0 or 1, but it looks like it is indeed a float -
  // MPUSystemMediaControlsViewController uses the floatValue method.
  float backlightLevel = [notification.userInfo[kBacklightKey] floatValue];
  BOOL screenOn = (backlightLevel > 0);
  if (_screenIsOn != screenOn) {
    _screenIsOn = screenOn;

    if (screenOn) {
      _prevLux = kUnassignedLux; // TODO: Potentially remove this. Might slow it down too much.
      [self _showDelegates:_flashlightSetting.flashlightOn immediately:YES];
      [self _bindSystemClient];
    } else {
      [self _unbindSystemClient];
    }
  }
}

#pragma mark - HID Stuff

- (void)_bindSystemClient {
  if (!_eventSystemClientRegistered && _screenIsOn && _delegates.count > 0) {
    IOHIDEventSystemClientScheduleWithRunLoop(_eventSystemClient, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    IOHIDEventSystemClientRegisterEventCallback(_eventSystemClient, &handleHIDEvent, self, NULL);
    _eventSystemClientRegistered = YES;
  }
}

- (void)_unbindSystemClient {
  if (_eventSystemClientRegistered) {
    IOHIDEventSystemClientUnscheduleWithRunLoop(_eventSystemClient, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    IOHIDEventSystemClientUnregisterEventCallback(_eventSystemClient);
    _eventSystemClientRegistered = NO;
    _prevLux = kUnassignedLux;
  }
}

#pragma mark - Delegates

- (void)addDelegate:(id<FLASHFlashlightDelegate>)delegate {
  if (![_delegates containsObject:delegate]) {
    [_delegates addObject:delegate];
    [delegate flashlightDidTurnOn:_flashlightSetting.flashlightOn];

    if ([delegate isKindOfClass:[FLASHFlashButton class]]) {
      FLASHFlashButton *button = (FLASHFlashButton *)delegate;
      [button setVisible:_showDelegates immediately:YES animated:NO];
    }

    [self _bindSystemClient];
  }
}

- (void)removeDelegate:(id<FLASHFlashlightDelegate>)delegate {
  [_delegates removeObject:delegate];
  if (!_delegates.count) {
    [self _unbindSystemClient];
    _showDelegates = NO;
  }
}

#pragma mark - FlashlightSettings

- (void)observeValueForKeyPath:(id)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if (context == @selector(flashButtonTapped:) && object == _flashlightSetting) {
    BOOL turningOn = [change[NSKeyValueChangeNewKey] boolValue];
    for (id<FLASHFlashlightDelegate> delegate in _delegates) {
      [delegate flashlightDidTurnOn:turningOn];

      // We _could_ also update _showDelegates but that's too complicated IMO. It'll happen anyway.
    }
  }
}

- (void)onFlashlightSettingInit:(SBCCFlashlightSetting *)setting {
  if (!_flashlightSetting) {
    _flashlightSetting = setting;
    [_flashlightSetting addObserver:self
                         forKeyPath:@"flashlightOn"
                            options:NSKeyValueObservingOptionNew
                            context:@selector(flashButtonTapped:)];
  }
}

- (void)onFlashlightSettingDealloc:(SBCCFlashlightSetting *)setting {
  if (_flashlightSetting == setting) {
    [_flashlightSetting removeObserver:self
                            forKeyPath:@"flashlightOn"
                               context:@selector(flashButtonTapped:)];
    _flashlightSetting = nil;
  }
}

@end
