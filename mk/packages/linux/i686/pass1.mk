#
# makefile for pass1
#

PASS := 1

preconfigcmd := $(call copy_dir_clean,$(_src_dir),$(_bld_dir))
configcmd := install -dv $(TOOLS)/include

makecmd := make mrproper && make ARCH=$(ARCH) headers_check

installcmd := make ARCH=$(ARCH) INSTALL_HDR_PATH=dest headers_install && cp -rv dest/include/* $(TOOLS)/include


postinstallcmd := 

include $(MK)/footer.mk


