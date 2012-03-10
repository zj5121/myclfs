#
# makefile for pass1
#

PASS := 1

configcmd := CPPFLAGS="-fexceptions" $(_src_dir)/configure \
			--prefix=$(CROSS_TOOLS) \
			--enable-cxx

makecmd := $(MAKE)

installcmd := make install

postinstallcmd := $(MAKE) check

deps := linux

include $(MK)/footer.mk


