#
# makefile for pass1
#

PASS := 3

configcmd := $(_src_dir)/configure \
			--prefix=$(TOOLS) \
			--build=$(HOST) --host=$(TARGET) \
			--enable-shared \
			--enable-interfaces="c,cxx" \
			--disable-optimization \
			--with-libgmp-prefix=$(TOOLS) \
			--with-libgmpxx-prefix=$(TOOLS)

afterconfig := echo '\#define PPL_GMP_SUPPORTS_EXCEPTIONS 1' >> confdefs.h

makecmd := make

installcmd := make install


include $(MK)/footer.mk


