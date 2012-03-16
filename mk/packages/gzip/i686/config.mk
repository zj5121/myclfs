#
# configuration
#
include $(MK)/header.mk

NAME := gzip
VERSION := 1.4
PKG_SUFFIX := tar.xz
PKG_NAME := $(_pkg_name)
MD5SUM := 

PKG_URL := ftp://ftp.gnu.org/gnu/gzip/gzip-1.4.tar.xz
DEPS := gcc-3

PASSES := 3
