#
# Constructing temp system
#

PASS := 3

configcmd := $(_src_dir)/configure --prefix=$(TOOLS)

makecmd := make

installcmd := make install

include $(MK)/footer.mk
