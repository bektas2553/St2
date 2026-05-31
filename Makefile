ARCHS := arm64
TARGET := iphone:clang:latest:14.0
DEBUG = 0
FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := Standoff2ESP

# Bulut derleyiciye sadece sources/main.mm dosyasını derlemesini söylüyoruz
Standoff2ESP_FILES += sources/main.mm

Standoff2ESP_CFLAGS += -fobjc-arc -Wno-deprecated-declarations -Wno-unused-variable -Wno-module-import-in-extern-c
Standoff2ESP_CXXFLAGS += -std=c++17
Standoff2ESP_OBJCXXFLAGS += -std=c++17

# Jailbreak'siz cihazda çökmeyecek standart Apple kütüphaneleri
Standoff2ESP_FRAMEWORKS += CoreGraphics QuartzCore UIKit Metal MetalKit

include $(THEOS)/makefiles/tweak.mk
