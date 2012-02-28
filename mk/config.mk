# follow clfs
curdir := $(shell pwd)

TARGET := i686-unknown-linux-gnu
TARGET_ARCH := i386

NR_CPU := $(shell cat /proc/cpuinfo|grep processor|wc -l)

ifeq ($(IS_CHROOT),y)
MAKE := make
BASE := /chroot-bld
PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin:/tools/sbin
else
MAKE := make -j$(NR_CPU)
BASE := $(curdir)/crossbuild
PATH := $(CROSS_TOOLS)/bin:/bin:/usr/bin
NEWBASE := $(BASE)/chroot-bld
endif

TOOLS := /tools
CROSS_TOOLS := /cross_tools
BUILD := $(shell gcc -dumpmachine)

MYPATCHES_DIR := $(curdir)/mypatches
PATCHES_DIR := $(curdir)/patches

ROOT := $(curdir)
DOWNLOAD := $(ROOT)/download
BLD := $(ROOT)/bld
SRC := $(ROOT)/src
PATCH_DIR := $(ROOT)/patches
TAR_DIR := $(ROOT)/download

PKG_SUFFIXES := tar.bz2 tar.xz .tar.gz
download_list :=

