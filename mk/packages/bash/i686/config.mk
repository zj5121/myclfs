#
# configuration
#
include $(MK)/header.mk

NAME := bash
VERSION := 4.2
PKG_SUFFIX := tar.gz
PKG_NAME := $(_pkg_name)
#MD5SUM :=618e944d7c7cd6521551e30b32322f4a

PKG_URL := http://ftp.gnu.org/gnu/bash/bash-4.2.tar.gz

PATCHES := bash-4.2-branch_update-3.patch
PATCHES_URL := http://patches.cross-lfs.org/dev/bash-4.2-branch_update-3.patch

PASSES := 3
