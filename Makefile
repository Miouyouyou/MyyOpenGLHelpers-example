O := .build

CC = gcc
ifeq ($(origin CFLAGS), undefined)
  CFLAGS = -O3 -march=native
endif
CFLAGS += -fPIC -fuse-ld=gold -DDEBUG
INCLUDE_DIRS = -Imyy -I.
LDFLAGS = -lGLESv2
CCC := $(CC) $(CFLAGS) $(INCLUDE_DIRS)

X11_LDFLAGS = -lX11 -lEGL -lGLESv2
X11_SOURCES = $(shell find ./myy/platforms/PC_X11 -name '*.c')

ANDROID_CC = armv7a-hardfloat-linux-gnueabi-gcc
ANDROID_CFLAGS = -fPIC -D__ANDROID__ -DANDROID -O3 -mthumb -mthumb-interwork -fuse-ld=gold -mfloat-abi=softfp -std=c11 -nostdlib -DDEBUG
ANDROID_BASE_DIR = $(ANDROID_NDK_HOME)/platforms/android-18/arch-arm/usr
ANDROID_CCC = $(ANDROID_CC) $(ANDROID_CFLAGS) -I$(ANDROID_BASE_DIR)/include $(INCLUDE_DIRS)
ANDROID_LIBNAME = libmain.so
ANDROID_LDFLAGS = -Wl,-Bsymbolic,-znow,-soname=$(ANDROID_LIBNAME),--dynamic-linker=/system/bin/linker,--hash-style=sysv -L$(ANDROID_BASE_DIR)/lib -lEGL -lGLESv2 -llog -landroid -lc
ANDROID_APK_PATH = ./myy/platforms/android/apk
ANDROID_APK_LIB_PATH = $(ANDROID_APK_PATH)/app/src/main/jniLibs
ANDROID_ASSETS_FOLDER = $(ANDROID_APK_PATH)/app/src/main/assets
ANDROID_SOURCES = $(shell find ./myy/platforms/android -name '*.c')

ifeq ($(origin PLATFORM), undefined)
  PLATFORM = PC_X11
endif

SOURCES := $(shell find . -name '*.c' -not -path './myy/platforms/*')
OBJECTS := $(prefix $(O)/, $(notdir SOURCES))

.PHONY: all
all: $(PLATFORM)

.PHONY: PC_X11
PC_X11: $(SOURCES)
	mkdir -p $(O)
	$(CCC) -o $(O)/Program $(SOURCES) $(X11_SOURCES) $(LDFLAGS) $(X11_LDFLAGS)

_android: $(SOURCES)
	mkdir -p $(O)
	$(ANDROID_CCC) --shared -o $(O)/$(ANDROID_LIBNAME) $(SOURCES) $(ANDROID_SOURCES) $(ANDROID_LDFLAGS)
	mkdir -p $(ANDROID_ASSETS_FOLDER)/textures
	mkdir -p $(ANDROID_ASSETS_FOLDER)/shaders
	cp -r shaders/* $(ANDROID_ASSETS_FOLDER)/shaders/
	cp -r textures/* $(ANDROID_ASSETS_FOLDER)/textures/
	cp $(O)/$(ANDROID_LIBNAME) $(ANDROID_APK_LIB_PATH)/armeabi/
	cp $(O)/$(ANDROID_LIBNAME) $(ANDROID_APK_LIB_PATH)/armeabi-v7a/

android: _android
	$(MAKE) -C $(ANDROID_APK_PATH) install

clean:
	$(RM) .build/*
	$(MAKE) -C $(ANDROID_APK_PATH) clean
