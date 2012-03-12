#
# makefile for pass1
#

PASS := 3

preconfigcmd := cd $(_src_dir) && cp -v configure{,.orig} && \
		sed -e "/LD_LIBRARY_PATH=/d" configure.orig > configure

configcmd := $(_src_dir)/configure \
		--build=$(HOST) --host=$(TARGET) \
		--prefix=$(TOOLS) \
		--with-gmp-prefix=$(TOOLS) 

makecmd := make

installcmd := make install

deps := gmp mpc mpfr ppl

include $(MK)/footer.mk


