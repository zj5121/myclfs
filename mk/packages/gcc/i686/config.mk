#
# configuration
#
include $(MK)/header.mk

NAME := gcc
VERSION := 4.6.2
PKG_SUFFIX := tar.bz2
PKG_NAME := $(_pkg_name)
DEPS := gmp mpc mpfr cloog ppl

MD5SUM := 
PKG_URL :=http://ftp.gnu.org/gnu/gcc/gcc-4.6.2/gcc-4.6.2.tar.bz2 

PATCHES := gcc-4.6.2-specs-1.patch \
		gcc-4.6.2-branch_update-1.patch
PATCHES_URL := http://patches.cross-lfs.org/dev/gcc-4.6.2-specs-1.patch \
		http://patches.cross-lfs.org/dev/gcc-4.6.2-branch_update-1.patch

PASS1_PATCHES := gcc-4.6.2-specs-1.patch

