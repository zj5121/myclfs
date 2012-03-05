#
# makefile for pass1
#

PASS1 := y

configcmd := $(_src_dir)/configure --prefix=$(CROSS_TOOLS) --without-debug --without-shared

makecmd := $(MAKE) -C include && make -C progs tic

installcmd := install -v -m755 progs/tic $(CROSS_TOOLS)/bin/

postinstallcmd := 

include $(MK)/footer.mk


