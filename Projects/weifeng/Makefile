TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = weifeng

weifeng_FILES = Tweak.xm
weifeng_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
