#
# configuration
#
include $(MK)/header.mk

NAME := vim
VERSION := 7.3
PKG_SUFFIX := tar.bz2
PKG_NAME := $(_pkg_name)
MD5SUM := 

PKG_URL := ftp://ftp.vim.org/pub/vim/unix/vim-7.3.tar.bz2 

PATCHES := vim-7.3-branch_updates-3.patch
PATCHES_URL := http://trac.cross-lfs.org/export/7bb1bf01b922864725e1f0bd9268224e409c16e2/patches/vim-7.3-branch_update-3.patch

DEPS := gcc-3

PASSES := 3
