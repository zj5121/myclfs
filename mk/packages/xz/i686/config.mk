#
# configuration
#
include $(MK)/header.mk

NAME := xz
VERSION := 5.0.3
PKG_SUFFIX := tar.xz
PKG_NAME := $(_pkg_name)
MD5SUM := 

PKG_URL := http://tukaani.org/xz/xz-5.0.3.tar.xz

DEPS := gcc-3

PASSES := 3
