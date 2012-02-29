# follow clfs
curdir := $(shell pwd)

TARGET := i686-unknown-linux-gnu
TARGET_ARCH := i386

NR_CPU := $(shell cat /proc/cpuinfo|grep processor|wc -l)

ifeq ($(IS_CHROOT),y)
MAKE := make
BASE := /chroot-bld
PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin:/tools/sbin
DOTBLD := $(BASE)/.bld
ROOT := $(BASE)
SRC := $(ROOT)/newsrc
BLD := $(ROOT)/newbld
else
MAKE := make -j$(NR_CPU)
BASE := $(curdir)/crossbuild
PATH := $(CROSS_TOOLS)/bin:/bin:/usr/bin
NEWBASE := $(BASE)/chroot-bld
ROOT := $(curdir)
TAR_DIR := $(ROOT)/download
BLD := $(ROOT)/bld
SRC := $(ROOT)/src
endif
TAR_DIR := $(ROOT)/download
TOOLS := /tools
CROSS_TOOLS := /cross_tools
BUILD := $(shell gcc -dumpmachine)

MYPATCHES_DIR := $(curdir)/mypatches
PATCHES_DIR := $(curdir)/patches

DOWNLOAD := $(ROOT)/download
PATCH_DIR := $(ROOT)/patches

PKG_SUFFIXES := tar.bz2 tar.xz .tar.gz
download_list :=

