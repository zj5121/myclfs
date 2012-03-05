#
# configuration
#
include $(MK)/header.mk

NAME := ncurses
VERSION := 5.9
PKG_SUFFIX := tar.gz
PKG_NAME := $(_pkg_name)
DEPS := linux

PATCHES     := ncurses-5.9-bash_fix-1.patch
PATCHES_URL := http://patches.cross-lfs.org/dev/ncurses-5.9-bash_fix-1.patch

MD5SUM := 4cea34b087b060772511e066e2038196 
PKG_URL := http://ftp.gnu.org/gnu/ncurses/ncurses-5.9.tar.gz 

