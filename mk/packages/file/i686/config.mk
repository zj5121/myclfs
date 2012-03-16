#
# configuration
#
include $(MK)/header.mk

NAME := file
VERSION := 5.10
PKG_SUFFIX := tar.gz
PKG_NAME := $(_pkg_name)
MD5SUM := 4cea34b087b060772511e066e2038196 

PKG_URL := ftp://ftp.astron.com/pub/file/file-5.10.tar.gz 

DEPS := gcc-3

PASSES := 1 3
