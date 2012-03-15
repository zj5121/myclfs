#
# init
#

ifndef d
d := $(or $(TOP),$(shell pwd))
include $(MK)/skel.mk
endif

NAME := 
VERSION := 
MD5SUM :=
SHA1SUM :=
PKG_SUFFIX := 
PKG_NAME :=
PATCHES :=
PATCHES_URL :=
DEPS :=
PASSES :=

PKG_URL := 

preconfigcmd :=
configcmd :=
afterconfig :=
makecmd :=
installcmd :=
postinstallcmd :=

