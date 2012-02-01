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
UNTAR.bz2 = $(call echo_cmd,-n,$(INFO_PREP_SRC) $(notdir $<) ...); tar jxf 
UNTAR.gz = $(call echo_cmd,-n,$(INFO_PREP_SRC) $(notdir $<) ...) ;tar zxf 
UNTAR.xz = $(call echo_cmd,-n,$(INFO_PREP_SRC) $(notdir $<) ...) ;tar Jxf 

define UNTARCMD
		@(mkdir -p $(dir $@))
		@($(UNTAR$(suffix $<)) $< -C $(call parent,$(call parent,$@)) && touch $@ && $(call echo_cmd,, done))
endef

PATCHCMD = @($(call echo_cmd,-n,$(INFO_PATCH_SRC)); patch -d $(dir $@)$(shell echo $(notdir $<) | sed -e 's/--.*$$//') -i $< -p1 2>&1 >/dev/null)

UNTAR_TGTS :=
PATCH_TGTS :=

# $1 = package base name. i.e. cloog-ppl
# $2 = package version. i.e. 0.15.11
# $3 = package suffix name. i.e. tar.gz
# $4 = package target
# $5 = dependent package
# $6 = prep action.   i.e. cp -v configure{,.orig} && sed ....
# $7 = configure cmd. i.e. configure --with-gmp=$(CLFS_TEMP)
# $8 = make cmd
# $9 = install cmd
define build_pass1
$(strip $(1))_tar := $(SRC)/$(strip $(1))-$(2).$(3)
$(strip $(1))_src := $(SRC)/$(strip $(1))-$(2)/.$(strip $(1))_untared
$($(strip $(1))_src) : $($(strip $(1))_tar)
	$(value UNTARCMD) && touch $$@

$(strip $(1))_dest := $(4)
$(strip $(1))_blddir := $(BLD)/$(notdir $($(strip $(strip $(1)))_src))
$($(strip $(1))_dest) : $($(strip $(1))_src) $(5)
	@(mkdir -p $($(strip $(1))_blddir && cd $($(b)_blddir) && $(or $(6) &&,)&& $(or $(7) &&,) && $(8))&& $(9)

endef
	
# $1 = tar file
define prepare_source
$(SRC)/.$(notdir $(1)): $(1)
	$(value UNTARCMD)

UNTAR_TGTS = $(SRC)/.$(notdir $(1)) $(UNTAR_TGTS)
endef

define patch_source
$(SRC)/.$(notdir $(1)): $(1) 
		$(value PATCHCMD)

PATCH_TGTS = $(SRC)/.$(notdir $(1)) $(PATCH_TGTS)
$$(warning $(PATCH_TGTS))
endef
