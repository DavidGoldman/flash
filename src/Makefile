export ARCHS = armv7 arm64
export TARGET = iphone:9.2:9.2
export THEOS_PACKAGE_DIR_NAME = debs
# PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)~beta$(VERSION.INC_BUILD_NUMBER)
include theos/makefiles/common.mk

BUNDLE_NAME = Resources
Resources_INSTALL_PATH = /Library/Application Support/Flash

TWEAK_NAME = Flash
Flash_FILES = Tweak.xm FLASHFlashButton.xm FLASHFlashController.m
Flash_FRAMEWORKS = UIKit CoreGraphics AVFoundation IOKit
Flash_LDFLAGS += -Wl,-segalign,4000

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard"
