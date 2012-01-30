# follow clfs

NR_CPU := $(shell cat /proc/cpuinfo|grep processor|wc -l)
MAKE := make -j$(NR_CPU)
CLFS := /cross
CLFS_TEMP := $(CLFS)/cross-tools
CLFS_FINAL := $(CLFS)/tools
PATH := $(CLFS_TEMP)/bin:/bin:/usr/bin

MACHINETYPE := $(shell gcc --verbose 2>&1 | grep "Target:" | cut -c 9-)
HOST := $(shell echo $(MACHINETYPE) | sed "s/-[^-]*/-cross/")

TARGET := i686-unknown-linux-gnu
TARGET_ARCH := i386

ROOT := $(shell pwd)
BLD := $(ROOT)/bld
SRC := $(ROOT)/src
PATCH_DIR := $(ROOT)/patches
TAR_DIR := $(ROOT)/download

LINUX_VER := 3.2.2
BINUTILS_VER := 2.22
GCC_VER := 4.6.2
GMP_VER := 5.0.2
MPFR_VER := 3.1.0
MPC_VER := 0.9


