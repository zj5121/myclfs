#
# configuration
#
include $(MK)/header.mk

NAME := binutils
VERSION := 2.22
PKG_SUFFIX := tar.bz2
PKG_NAME := $(_pkg_name)
DEPS := cloog

MD5SUM := ee0f10756c84979622b992a4a61ea3f5
PKG_URL := http://ftp.gnu.org/gnu/binutils/binutils-2.22.tar.bz2 
