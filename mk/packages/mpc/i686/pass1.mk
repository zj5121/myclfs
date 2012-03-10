#
# makefile for pass1
#

PASS := 1

configcmd := LDFLAGS="-Wl,-rpath,$(CROSS_TOOLS)/lib" $(_src_dir)/configure \
			--prefix=$(CROSS_TOOLS) \
			--with-gmp=$(CROSS_TOOLS) \
			--with-mpfr=$(CROSS_TOOLS)

makecmd := $(MAKE)

installcmd := make install

deps := gmp mpfr

include $(MK)/footer.mk


