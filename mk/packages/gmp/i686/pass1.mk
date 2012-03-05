#
# makefile for pass1
#

PASS1 := y

configcmd := CPPFLAGS="-fexceptions" $(_src_dir)/configure \
			--prefix=$(CROSS_TOOLS) \
			--enable-cxx

makecmd := $(MAKE)

installcmd := make install

postinstallcmd := $(MAKE) check

include $(MK)/footer.mk


