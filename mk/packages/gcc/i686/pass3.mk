#
# makefile for pass1
#

PASS := 3

preconfigcmd := cd $(_src_dir) && (echo -en '\#undef STANDARD_INCLUDE_DIR\n\#define STANDARD_INCLUDE_DIR "$(TOOLS)/include/"\n\n' >> gcc/config/linux.h ;\
		echo -en '\n\#undef STANDARD_STARTFILE_PREFIX_1\n\#define STANDARD_STARTFILE_PREFIX_1 "$(TOOLS)/lib/"\n' >> gcc/config/linux.h; \
		echo -en '\n\#undef STANDARD_STARTFILE_PREFIX_2\n\#define STANDARD_STARTFILE_PREFIX_2 ""\n' >> gcc/config/linux.h) && \
		cp -v gcc/Makefile.in{,.orig} && \
		sed -e "s@\(^NATIVE_SYSTEM_HEADER_DIR =\).*@\1 $(TOOLS)/include@g" gcc/Makefile.in.orig > gcc/Makefile.in 

configure --prefix=/tools \
	--build=$(HOST) --host=$(TARGET) --target=$(TARGET) \
	--with-local-prefix=$(TOOLS) --enable-long-long --enable-c99 \
	--enable-shared --enable-threads=posix --enable-__cxa_atexit \
	--disable-nls --enable-languages=c,c++ --disable-libstdcxx-pch \
	--disable-multilib --enable-cloog-backend=isl

afterconfig := cp -v Makefile{,.orig} && \
	sed "/^HOST_\(GMP\|PPL\|CLOOG\)\(LIBS\|INC\)/s:-[IL]/\(lib\|include\)::" Makefile.orig > Makefile

makecmd := make AS_FOR_TARGET="$(TARGET)-as" LD_FOR_TARGET="$(TARGET)-ld"

installcmd := make install

include $(MK)/footer.mk

