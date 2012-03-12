#
# makefile for pass1
#

PASS := 3

configcmd := $(_src_dir)/configure \
			--build=$(HOST) --host=$(TARGET) \
			--prefix=$(TOOLS) \
			--enable-shared --with-gmp=$(TOOLS)

makecmd := make

installcmd := make install

postinstallcmd := 

include $(MK)/footer.mk


