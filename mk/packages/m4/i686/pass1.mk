#
# makefile for pass1
#

PASS1 := y

configcmd := $(_src_dir)/configure --prefix=$(CROSS_TOOLS)

makecmd := $(MAKE)

installcmd := make install

postinstallcmd := 

include $(MK)/footer.mk


