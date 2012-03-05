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

include $(MK)/gmsl
include $(MK)/config-$(TARGET_ARCH).mk
include $(MK)/rules.mk
include $(MK)/packages_def.mk

.PHONY: prep all

all: prep build


prep: 
	@(if [ ! -d $(DOWNLOAD) ] ; then install -d -v $(DOWNLOAD); fi )
	@(if [ ! -d $(BASE) ] ; then install -d -v $(BASE); fi)
	@(if [ ! -d $(BASE)$(CROSS_TOOLS)/bin ] ; then \
		install -d -v $(BASE)$(CROSS_TOOLS)/bin ; fi)
	@(if [ ! -h $(CROSS_TOOLS) ]; then \
		sudo rm -fr $(CROSS_TOOLS); \
		sudo ln -f -s $(BASE)$(CROSS_TOOLS) / ; fi)
	@(if [ ! -d $(BASE)$(TOOLS)/bin ] ; then \
		install -dv $(BASE)$(TOOLS)/bin ; fi)
	@(if [ ! -h $(TOOLS) ]; then \
		sudo rm -fr $(TOOLS) ; \
		sudo ln -fsv $(BASE)$(TOOLS) / ; fi)

define builder

include $$(MK)/packages/$$(p)/$$(TARGET_ARCH)/config.mk
_src_dir := $(SRC)/$$(NAME)-$$(VERSION)
_bld_dir := $(BLD)/$$(NAME)-$$(VERSION)
include $$(MK)/packages/$$(p)/$$(TARGET_ARCH)/pass1.mk

endef

$(foreach p,$(PACKAGES),$(eval $(builder)))

build: prep $(PKG_DOWNLOADED) $(PATCHES_DOWNLOADED) $(PASS1_TGTS)

