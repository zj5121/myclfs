# follow clfs

TARGET := i686-unknown-linux-gnu
TARGET_ARCH := i386

NR_CPU := $(shell cat /proc/cpuinfo|grep processor|wc -l)
MAKE := make -j$(NR_CPU)
BASE := /cross
TOOLCHAIN_HOST:= $(BASE)/host
TOOLCHAIN := $(BASE)/toolchain
SYSROOT := $(BASE)/$(TARGET)/sysroot

PATH := $(TOOCHAIN_HOST)/bin:/bin:/usr/bin

BUILD := $(shell gcc -dumpmachine)
#HOST := $(shell echo $(BUILD) | sed "s/-[^-]*/-cross/")

ROOT := $(shell pwd)
BLD := $(ROOT)/bld
SRC := $(ROOT)/src
PATCH_DIR := $(ROOT)/patches
TAR_DIR := $(ROOT)/download

