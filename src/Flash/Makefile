include theos/makefiles/common.mk

BUNDLE_NAME = Flash
Flash_FILES = FLASHListController.xm FLASHSwitchTableCell.m FLASHHeaderCell.m
Flash_INSTALL_PATH = /Library/PreferenceBundles
Flash_FRAMEWORKS = UIKit CoreGraphics
Flash_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/Flash.plist$(ECHO_END)
