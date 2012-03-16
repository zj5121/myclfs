#
# configuration
#
include $(MK)/header.mk

NAME := make
VERSION := 3.82
PKG_SUFFIX := tar.bz2
PKG_NAME := $(_pkg_name)
MD5SUM := 

PKG_URL := ftp://ftp.gnu.org/gnu/make/make-3.82.tar.bz2

DEPS := gcc-3

PASSES := 3
