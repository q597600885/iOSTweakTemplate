ARCHS = arm64 arm64e

TARGET = iphone:clang:latest:15.0


# 自动生成的配置
include tweak_config.mk


include $(THEOS)/makefiles/common.mk


$(TWEAK_NAME)_FILES = Tweak.xm

$(TWEAK_NAME)_CFLAGS = -fobjc-arc


include $(THEOS_MAKE_PATH)/tweak.mk
