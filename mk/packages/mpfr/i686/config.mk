#
# configuration
#
include $(MK)/header.mk

NAME := mpfr
VERSION := 3.0.1
PKG_SUFFIX := tar.bz2
PKG_NAME := $(_pkg_name)
MD5SUM := bfbecb2eacb6d48432ead5cfc3f7390a

PKG_URL := http://ftp.gnu.org/gnu/mpfr/mpfr-3.0.1.tar.bz2

DEPS := gmp

PASSES := 1 3