VERBOSE := 
COLOR_TTY := true

COLOR := \033[33;40m
NOCOLOR := \033[0m

ifneq ($(VERBOSE),true)
ifeq ($(COLOR_TTY),true)
echo_prog := $(shell if echo -e | grep -q -- -e; then echo echo ; else echo echo -e ; fi)
echo_cmd = $(echo_prog) $(1) "$(COLOR)$(2)$(NOCOLOR)"
else
echo_cmd = @echo "$(1)";
endif
else # Verbose output
echo_cmd =
endif

parent = $(patsubst %/,%,$(dir $(1)))

INFO_PREP_SRC := I: Prepare source
INFO_PATCH_SRC := I: Patch source 
INFO_CONFIG := I: Configure
UNTAR.bz2 = $(call echo_cmd,-n,$(INFO_PREP_SRC) $(notdir $<) ...); tar jxf 
UNTAR.gz = $(call echo_cmd,-n,$(INFO_PREP_SRC) $(notdir $<) ...) ;tar zxf 
UNTAR.xz = $(call echo_cmd,-n,$(INFO_PREP_SRC) $(notdir $<) ...) ;tar Jxf 

define UNTARCMD
@(mkdir -p $(SRC) && $(UNTAR$(suffix $<)) $< -C $(SRC) && touch $@ && $(call echo_cmd,, done))
endef

PATCH_ = $(call echo_cmd,-n,$(INFO_PATCH_SRC) $(notdir $<) ...); patch -d $(dir $@) -i $< -p1 2>&1 >/dev/null
define PATCHCMD
@($(PATCH_) && touch $@ && $(call echo_cmd,, done))
endef

UNTAR_TGTS :=
PATCH_TGTS :=

# $1 = name
# $2 = version
# $3 = suffix
# $4 = subname, optional
# export var: $(1)_src $(1)_tar
define prepare_source
$(1)$(if $(4),-$(4),)_untared := $(SRC)/$(1)-$(2)/.$(1)-$(if $(4),$(4)-,)$(2)_untared
$(1)$(if $(4),-$(4),)_tar := $(TAR_DIR)/$(1)-$(if $(4),$(4)-,)$(2).$(3)
$$($(1)$(if $(4),-$(4),)_untared): $$($(1)$(if $(4),-$(4),)_tar)
	$(value UNTARCMD)

$(1)_src := $$($(1)_src) $$($(1)$(if $(4),-$(4),)_untared)
$$(if $$($(1)_src_dir),,$$(eval $(1)_src_dir := $(SRC)/$(1)-$(2)))
#$$(warning $(1)_src_dir = $$($(1)_src_dir))
#UNTAR_TGTS = $(SRC)/.$(notdir $(1)) $(UNTAR_TGTS)
endef

# $1 = name
# $2 = version
# $3 = patch name
# $4 = dependency (optional)
define patch_source_
$(1)-$(3)_patch := $(PATCH_DIR)/$(1)-$(2)-$(3).patch
$(1)-$(3)_patch_dest := $$(dir $$(firstword $$($(1)_src))).$$(notdir $$($(1)-$(3)_patch))
$$($(1)-$(3)_patch_dest): $$($(1)-$(3)_patch) $$($(1)_src) $(4)
	$(value PATCHCMD)

$(1)_patched := $$($(1)_patched) $$($(1)-$(3)_patch_dest) 
#$$(warning $(1)-$(3)_patch_dest = $$($(1)-$(3)_patch_dest))
#$$(warning $(1)_patched = $$($(1)_patched))
endef

# $1 = pache list name
# $2 = basename, like gcc
# $3 = version
patch_source = $(foreach p,$($(1)),$(eval $(call patch_source_,$(2),$(3),$(p),$($(1)_src))))

# $1 src dir
# $2 dest dir
define copy_dir_clean 
mkdir -p "$2" && (cd "$1" && tar cf - \
	--exclude=CVS --exclude=.svn --exclude=.git --exclude=.pc \
	--exclude="*~" --exclude=".#*" \
	--exclude="*.orig" --exclude="*.rej" \
	.) | (cd "$2" && tar xf -) 
endef

define MK_ENV1
export BASE=/cross ; \
export PREFIX=/opt/x-tools ; \
export SYSROOT=$(PREFIX)/$(TARGET)/sysroot ; \
export PATH=$(TOOLCHAIN_INSTALL)/bin:/bin:/usr/bin 
endef

define MK_ENV2
export PATH=$(TOOLCHAIN_INSTALL)/bin:/bin:/usr/bin ; \
export AR_FOR_TARGET=$(TARGET)-ar ; \
export NM_FOR_TARGET=$(TARGET)-nm ; \
export OBJDUMP_FOR_TARGET=$(TARGET)-objdump ; \
export STRIP_FOR_TARGET=$(TARGET)-strip 
endef
