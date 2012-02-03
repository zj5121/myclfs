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
		@(mkdir -p $(dir $@))
		@($(UNTAR$(suffix $<)) $< -C $(call parent,$(call parent,$@)) && touch $@ && $(call echo_cmd,, done))
endef

PATCHCMD = $(call echo_cmd,-n,$(INFO_PATCH_SRC) $(notdir $<)); patch -d $(dir $@) -i $< -p1 2>&1 >/dev/null && $(call echo_cmd,, ... done)

UNTAR_TGTS :=
PATCH_TGTS :=

# $1 = name
# $2 = version
# $3 = suffix
define prepare_source
$(1)_src := $(SRC)/$(1)-$(2)/.$(1)_untared
$(1)_tar := $(TAR_DIR)/$(1)-$(2).$(3)
$$($(1)_src): $$($(1)_tar)
	$(value UNTARCMD)

#UNTAR_TGTS = $(SRC)/.$(notdir $(1)) $(UNTAR_TGTS)
endef

# $1 = name
# $2 = version
# $3 = patch name
define patch_source
$(1)-$(2)-$(3)_patch := $(PATCH_DIR)/$(1)-$(2)-$(3).patch
$(1)-$(2)-$(3)_patch_dest := $$(dir $$($(1)_src)).$$(notdir $$($(1)-$(2)-$(3)_patch))
$$($(1)-$(2)-$(3)_patch_dest): $$($(1)-$(2)-$(3)_patch) $$($(1)_src)
		$(value PATCHCMD) && touch $$@

#PATCH_TGTS = $(SRC)/.$(notdir $(1)) $(PATCH_TGTS)
#$$(info ***$$($(1)-$(2)-$(3)_patch_dest) , $$($(1)_src))
endef
