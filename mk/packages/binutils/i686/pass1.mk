#
# makefile for pass1
#

PASS1 := y

preconfigcmd := 

configcmd := AR=ar AS=as $(_src_dir)/configure \
		--prefix=$(CROSS_TOOLS) --host=$(HOST) --target=$(TARGET) \
		--with-sysroot=$(BASE) --with-lib-path=$(TOOLS)/lib --disable-nls --enable-shared \
		--disable-multilib --with-ppl=$(CROSS_TOOLS)\
		--with-cloog=$(CROSS_TOOLS) --enable-cloog-backend=isl

makecmd := make configure-host && $(MAKE)

installcmd := make install && cp -v $(_src_dir)/include/libiberty.h $(TOOLS)/include

deps := cloog

include $(MK)/footer.mk

