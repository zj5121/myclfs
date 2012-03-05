#
# configuration
#
include $(MK)/header.mk

NAME := eglibc
VERSION := 2.15
PKG_SUFFIX := tar.bz2
PKG_NAME := $(_pkg_name)
DEPS := gcc binutils

MD5SUM := 933b6c8c35a0006c996fbac913f2b067
PKG_URL := http://cross-lfs.org/~cosmo/sources/eglibc-2.15-r17386.tar.bz2

PATCHES := eglibc-2.15-fixes-1.patch \
		eglibc-2.15-fixes-1.patch

PATCHES_URL := http://patches.cross-lfs.org/dev/eglibc-2.15-r17386-dl_dep_fix-1.patch \
		http://patches.cross-lfs.org/dev/eglibc-2.15-fixes-1.patch

PASS1_PATCHES := 

