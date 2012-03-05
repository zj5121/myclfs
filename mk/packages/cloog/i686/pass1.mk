#
# makefile for pass1
#

PASS1 := y

preconfigcmd := cd $(_src_dir) && cp -v configure{,.orig} && \
		sed -e "/LD_LIBRARY_PATH=/d" configure.orig > configure

configcmd := LDFLAGS="-Wl,-rpath,$(CROSS_TOOLS)/lib" \
		$(_src_dir)/configure \
			--prefix=$(CROSS_TOOLS) \
			--enable-shared \
			--with-gmp-prefix=$(CROSS_TOOLS) 

makecmd := $(MAKE)

installcmd := make install

include $(MK)/footer.mk


