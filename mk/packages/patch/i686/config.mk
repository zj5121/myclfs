#
# configuration
#
include $(MK)/header.mk

NAME := patch
VERSION := 2.6.1
PKG_SUFFIX := tar.xz
PKG_NAME := $(_pkg_name)
MD5SUM := 

PKG_URL := http://ftp.gnu.org/gnu/patch/patch-2.6.1.tar.xz

DEPS := gcc-3

PASSES := 3
