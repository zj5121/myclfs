#
# makefile for pass1
#

PASS := 3

configcmd := $(_src_dir)/configure \
		--prefix=$(CROSS_TOOLS) \
		--build=$(HOST) --host=$(TARGET) --target=$(TARGET) \
		--with-lib-path=$(TOOLS)/lib --disable-nls --enable-shared \
		--disable-multilib --with-ppl=$(TOOLS)\
		--with-cloog=$(TOOLS) --enable-cloog-backend=isl

makecmd := make configure-host && make

installcmd := make install 

include $(MK)/footer.mk


