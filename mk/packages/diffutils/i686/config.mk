#
# configuration
#
include $(MK)/header.mk

NAME := diffutils
VERSION := 3.2
PKG_SUFFIX := tar.xz
PKG_NAME := $(_pkg_name)
MD5SUM :=

PKG_URL := http://ftp.gnu.org/gnu/coreutils/coreutils-8.15.tar.xz

PASSES := 3
