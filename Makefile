#
# main Makefile
#

TOP := $(shell pwd)
MK := $(TOP)/mk
ARCH ?= i386

ifeq ($(strip $(ARCH)),i386)
TARGET_ARCH := i686
else
TARGET_ARCH := $(ARCH)
endif
HOST := $(shell echo $${MACHTYPE} | sed -e 's/-[^-]*/-cross/')

include $(MK)/packages_def.mk
#include $(MK)/gmsl
include $(MK)/config-$(TARGET_ARCH).mk
include $(MK)/rules.mk

pass1_list := $(foreach p,$(PACKAGES),$(p)-1)
pass2_list := $(foreach p,$(PACKAGES),$(p)-2)
pass3_list := $(foreach p,$(PACKAGES),$(p)-3)

.PHONY: prep all tar_files build-1 build-2 build

all: prep build


prep: 
	@(if [ ! -d $(DOWNLOAD) ] ; then install -d -v $(DOWNLOAD); fi )
	@(if [ ! -d $(BASE) ] ; then install -d -v $(BASE); fi)
	@(if [ ! -d $(BASE)$(CROSS_TOOLS)/bin ] ; then \
		install -d -v $(BASE)$(CROSS_TOOLS)/{bin,include,lib,sbin} ; fi)
	@(if [ ! -h $(CROSS_TOOLS) ]; then \
		sudo rm -fr $(CROSS_TOOLS); \
		sudo ln -f -s $(BASE)$(CROSS_TOOLS) / ; fi)
	@(if [ ! -d $(BASE)$(TOOLS)/bin ] ; then \
		install -dv $(BASE)$(TOOLS)/{bin,include,lib,sbin} ; fi)
	@(if [ ! -h $(TOOLS) ]; then \
		sudo rm -fr $(TOOLS) ; \
		sudo ln -fsv $(BASE)$(TOOLS) / ; fi)

define builder

include $$(MK)/packages/$$(p)/$$(TARGET_ARCH)/config.mk
_src_dir := $(SRC)/$$(NAME)-$$(VERSION)
_bld_dir := $(BLD)/$$(NAME)-$$(VERSION)
$$(NAME)_PASSES := $$(PASSES)
$$(warning ---- $$(NAME),$$(VERSION),$$($$(NAME)_PASSES))
$$(foreach i,$$($$(NAME)_PASSES),\
	$$(eval PASS := $$(i)) \
	$$(eval include $$(MK)/footer.mk))

endef

$(foreach p,$(PACKAGES),$(eval $(builder)))

tar_files : $(PKG_DOWNLOADED) $(PATCHES_DOWNLOADED)

cross_compiler : $(TGTS_PASS-1) $(TGTS_PASS-2)

temp_sys: cross_compiler $(TGTS_PASS-3) 

build: prep tar_files cross_compiler temp_sys

