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
