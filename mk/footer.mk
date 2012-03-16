#
# construct target
#
include $(MK)/gmsl

# download tar files
ifeq ($($(NAME)_tar_file),)
$(NAME)_tar_file := $(_pkg_name)
$(NAME)_pkg_url := $(PKG_URL)
$(NAME)_md5sum := $(MD5SUM)
$(NAME)_sha1sum := $(SHA1SUM)
$(eval $(call download_tar_file,$(NAME),$(VERSION)))
endif

# download patches
ifneq ($(PATCHES),)
ifneq ($(PATCHES_URL),)
ifeq ($($(NAME)_patches),)
$(NAME)_patches := $(PATCHES)
$(call __pairmap,download_patch_file,$(PATCHES),$(PATCHES_URL))
endif
endif
endif

# inflat pkg file
$(eval $(call prepare_source,$(NAME),$(VERSION),$(PKG_SUFFIX),,$(PASS)))

$(NAME)_preconfig_$(PASS) := $(preconfigcmd)
$(NAME)_configcmd_$(PASS) := $(configcmd)
$(NAME)_afterconfig_$(PASS) := $(afterconfig)
$(NAME)_makecmd_$(PASS) := $(makecmd)
$(NAME)_installcmd_$(PASS) := $(installcmd)
$(NAME)_postinstallcmd_$(PASS) := $(postinstallcmd)

# build target
#
$(NAME)_deps-$(PASS) := $(foreach d,$(DEPS),$(if $(filter $(d),$$($(pass$(PASS)_list))),$($(d)),$($(d)-$(PASS))))
$(warning >>>>> $(NAME)_deps-$(PASS)=$($(NAME)_deps-$(PASS)), $(DEPS))
$(eval $(call patch_source,$(PATCHES),$(NAME),$(VERSION),$(PASS)))
$(eval $(call build_tgt_pass,$(NAME),$(VERSION),$(PASS)))

PASS :=


