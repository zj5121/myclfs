#
# makefile for pass1
#

PASS := 3

configcmd := EGREP="grep -E" $(_src_dir)/configure \
			--prefix=$(TOOLS) \
			--with-gmp=$(TOOLS) \
			--with-mpfr=$(TOOLS)

makecmd := make

installcmd := make install

include $(MK)/footer.mk


