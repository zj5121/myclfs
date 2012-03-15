#
# configuration
#
include $(MK)/header.mk

NAME := mpc
VERSION := 0.9
PKG_SUFFIX := tar.gz
PKG_NAME := $(_pkg_name)
DEPS := gmp mpfr

SHA1SUM := 229722d553030734d49731844abfef7617b64f1a

PKG_URL := http://www.multiprecision.org/mpc/download/mpc-0.9.tar.gz

PASSES := 1 3