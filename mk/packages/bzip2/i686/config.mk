#
# configuration
#
include $(MK)/header.mk

NAME := bzip2
VERSION := 1.0.6
PKG_SUFFIX := tar.gz
PKG_NAME := $(_pkg_name)
MD5SUM := 00b516f4704d4a7cb50a1d97e6e8e15b

PKG_URL := http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz

PASSES := 3
