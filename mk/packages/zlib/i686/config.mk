#
# configuration
#
include $(MK)/header.mk

NAME := zlib
VERSION := 1.2.6
PKG_SUFFIX := tar.gz
PKG_NAME := $(_pkg_name)
MD5SUM :=618e944d7c7cd6521551e30b32322f4a

PKG_URL := http://zlib.net/zlib-1.2.6.tar.gz

PASSES := 3
