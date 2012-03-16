#
# configuration
#
include $(MK)/header.mk

NAME := texinfo
VERSION := 4.13a
PKG_SUFFIX := tar.gz
PKG_NAME := $(_pkg_name)
MD5SUM := 

PKG_URL := http://ftp.gnu.org/gnu/texinfo/texinfo-4.13a.tar.gz
DEPS := gcc-3

PASSES := 3
