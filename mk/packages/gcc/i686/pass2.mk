#
# makefile for pass1
#

PASS := 2

preconfigcmd := cd $(_src_dir) && (echo -en '\#undef STANDARD_INCLUDE_DIR\n\#define STANDARD_INCLUDE_DIR "$(TOOLS)/include/"\n\n' >> gcc/config/linux.h ;\
		echo -en '\n\#undef STANDARD_STARTFILE_PREFIX_1\n\#define STANDARD_STARTFILE_PREFIX_1 "$(TOOLS)/lib/"\n' >> gcc/config/linux.h; \
		echo -en '\n\#undef STANDARD_STARTFILE_PREFIX_2\n\#define STANDARD_STARTFILE_PREFIX_2 ""\n' >> gcc/config/linux.h) && \
		cp -v gcc/Makefile.in{,.orig} && \
		sed -e "s@\(^CROSS_SYSTEM_HEADER_DIR =\).*@\1 $(TOOLS)/include@g" gcc/Makefile.in.orig > gcc/Makefile.in 

configcmd := AR=ar LDFLAGS="-Wl,-rpath,$(CROSS_TOOLS)/lib" \
	$(_src_dir)/configure --prefix=$(CROSS_TOOLS) \
	--build=$(HOST) --target=$(TARGET) --host=$(HOST) \
	--with-sysroot=$(BASE) --with-local-prefix=$(TOOLS) --disable-nls \
	--enable-shared --enable-languages=c,c++ --enable-__cxa_atexit \
	--with-mpfr=$(CROSS_TOOLS) --with-gmp=$(CROSS_TOOLS) --enable-c99 \
	--with-ppl=$(CROSS_TOOLS) --with-cloog=$(CROSS_TOOLS) --enable-cloog-backend=isl \
	--enable-long-long --enable-threads=posix --disable-multilib

makecmd := make AS_FOR_TARGET="$(TARGET)-as" LD_FOR_TARGET="$(TARGET)-ld" 

installcmd := make install

include $(MK)/footer.mk

