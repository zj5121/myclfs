#
# configuration
#
include $(MK)/header.mk

NAME := ppl
VERSION := 0.11.2
PKG_SUFFIX := tar.bz2
PKG_NAME := $(_pkg_name)
DEPS := gmp mpc mpfr

MD5SUM := c24429e6c3bc97d45976a63f40f489a1

PKG_URL := ftp://ftp.cs.unipr.it/pub/ppl/releases/0.11.2/ppl-0.11.2.tar.bz2

PASSES := 1 3
