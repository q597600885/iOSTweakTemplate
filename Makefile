ARCHS = arm64 arm64e

TARGET = iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TestTweak

TestTweak_FILES = Tweak.xm
TestTweak_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
