#
# configuration
#
include $(MK)/header.mk

NAME := sed
VERSION := 4.2.1
PKG_SUFFIX := tar.bz2
PKG_NAME := $(_pkg_name)
MD5SUM := 

PKG_URL := http://ftp.gnu.org/gnu/sed/sed-4.2.1.tar.bz2

DEPS := gcc-3

PASSES := 3
