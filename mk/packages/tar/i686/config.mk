#
# configuration
#
include $(MK)/header.mk

NAME := tar
VERSION := 1.26
PKG_SUFFIX := tar.xz
PKG_NAME := $(_pkg_name)
MD5SUM := 

PKG_URL := http://ftp.gnu.org/gnu/tar/tar-1.26.tar.xz

DEPS := gcc-3

PASSES := 3
