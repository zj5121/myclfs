#
# makefile for pass1
#

PASS := 2

preconfigcmd := cd $(_src_dir) && (echo -en '\#undef STANDARD_INCLUDE_DIR\n\#define STANDARD_INCLUDE_DIR "$(TOOLS)/include/"\n\n' >> gcc/config/linux.h ;\
		echo -en '\n\#undef STANDARD_STARTFILE_PREFIX_1\n\#define STANDARD_STARTFILE_PREFIX_1 "$(TOOLS)/lib/"\n' >> gcc/config/linux.h; \
		echo -en '\n\#undef STANDARD_STARTFILE_PREFIX_2\n\#define STANDARD_STARTFILE_PREFIX_2 ""\n' >> gcc/config/linux.h) && \
		cp -v gcc/Makefile.in{,.orig} && \
		sed -e "s@\(^CROSS_SYSTEM_HEADER_DIR =\).*@\1 $(TOOLS)/include@g" gcc/Makefile.in.orig > gcc/Makefile.in && \
		touch $(TOOLS)/include/limits.h

configcmd := AR=ar LDFLAGS="-Wl,-rpath,$(CROSS_TOOLS)/lib" \
		  $(_src_dir)/configure --prefix=$(CROSS_TOOLS) \
		  --build=$(HOST) --host=$(HOST) --target=$(TARGET) \
		  --with-sysroot=$(BASE) --with-local-prefix=$(TOOLS) --disable-nls \
		  --disable-shared --with-mpfr=$(CROSS_TOOLS) --with-gmp=$(CROSS_TOOLS) \
		  --with-ppl=$(CROSS_TOOLS) --with-cloog=$(CROSS_TOOLS) \
		  --without-headers --with-newlib --disable-decimal-float \
		  --disable-libgomp --disable-libmudflap --disable-libssp \
		  --disable-threads --enable-languages=c --disable-multilib \
		  --enable-cloog-backend=isl

deps := binutils mpc ppl gmp mpc mpfr

makecmd := make all-gcc all-target-libgcc

installcmd := make install-gcc install-target-libgcc

include $(MK)/footer.mk

