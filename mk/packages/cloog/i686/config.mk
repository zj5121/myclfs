#
# configuration
#
include $(MK)/header.mk

NAME := cloog
VERSION := 0.16.3
PKG_SUFFIX := tar.gz
PKG_NAME := $(_pkg_name)
DEPS := gmp

MD5SUM := 0f8a241cd1c4f103f8d2c91642b3498
PKG_URL := http://www.bastoul.net/cloog/pages/download/cloog-0.16.3.tar.gz
#PKG_URL := http://www.bastoul.net/cloog/pages/download/count.php3?url=./cloog-0.17.0.tar.gz
