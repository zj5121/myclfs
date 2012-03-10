#
# makefile for pass1
#

PASS := 1

configcmd := LDFLAGS="-Wl,-rpath=$(CROSS_TOOLS)/lib" $(_src_dir)/configure \
			--prefix=$(CROSS_TOOLS) \
			--enable-shared --with-gmp=$(CROSS_TOOLS)

makecmd := $(MAKE)

installcmd := make install

postinstallcmd := 

deps := gmp

include $(MK)/footer.mk


