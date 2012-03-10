#
# makefile for pass1
#
PASS := 1

configcmd := $(_src_dir)/configure --prefix=$(CROSS_TOOLS)

makecmd := $(MAKE)

installcmd := make install

postinstallcmd := 

include $(MK)/footer.mk


