#
# configuration
#
include $(MK)/header.mk

NAME := flex
VERSION := 2.5.35
PKG_SUFFIX := tar.bz2
PKG_NAME := $(_pkg_name)
MD5SUM := 

PKG_URL := http://downloads.sourceforge.net/project/flex/flex/flex-2.5.35/flex-2.5.35.tar.bz2

DEPS := gcc-3

PASSES := 3
