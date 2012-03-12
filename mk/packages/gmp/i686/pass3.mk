#
# Constructing temp system
#

PASS := 3

configcmd := HOST_CC="gcc" CPPFLAGS="-fexceptions" $(_src_dir)/configure \
		--build=$(HOST) --host=$(TARGET) \
		--prefix=$(TOOLS) \
		--enable-cxx

makecmd := $(MAKE)

installcmd := make install

postinstallcmd := $(MAKE) check

deps := linux

include $(MK)/footer.mk
