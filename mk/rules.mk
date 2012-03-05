
VERBOSE := 
COLOR_TTY := true

COLOR := \033[33;40m
NOCOLOR := \033[0m
ERRCOLOR := \033[31;40m

ifneq ($(VERBOSE),true)
Q = @
ifeq ($(COLOR_TTY),true)
echo_prog := $(shell if echo -e | grep -q -- -e; then echo echo ; else echo echo -e ; fi)
echo_cmd = $(echo_prog) $(1) "$(COLOR)$(2)$(NOCOLOR)"
echo_err = $(echo_prog) $(1) "$(ERRCOLOR)$(2)$(NOCOLOR)"
else
echo_cmd = @echo "$(1)"
echo_err = @echo "$(1)"
endif
else # Verbose output
Q =
echo_cmd =
echo_err = 
endif

parent = $(patsubst %/,%,$(dir $(1)))

INFO_PREP_SRC := I: Prepare source
INFO_PATCH_SRC := I: Patch source 
INFO_CONFIG := I: Configure
INFO_BUILD := I: Build
PV := $(shell which pv &> /dev/null && echo pv || echo cat)
UNTAR.bz2 = $(call echo_cmd,,$(INFO_PREP_SRC) $(notdir $<) ...); $(PV) $< | tar --strip=1 -jx 
UNTAR.gz  = $(call echo_cmd,,$(INFO_PREP_SRC) $(notdir $<) ...); $(PV) $< | tar --strip=1 -zx 
UNTAR.xz  = $(call echo_cmd,,$(INFO_PREP_SRC) $(notdir $<) ...); $(PV) $< | tar --strip=1 -Jx 

# $1 = src dest dir
define UNTARCMD
@(mkdir -p $(SRC)/$(1) && $$(UNTAR$$(suffix $$<)) -C $(SRC)/$(1) && touch $$@ )
endef

PATCH_ = $(call echo_cmd,-n,$(INFO_PATCH_SRC) $(notdir $<) ...); patch -d $(dir $@) -i $< -p1 2>&1 >/dev/null
define PATCHCMD
($(PATCH_) && touch $@ && $(call echo_cmd,, done))
endef

UNTAR_TGTS :=
PATCH_TGTS :=

_pkg_name = $(NAME)-$(VERSION).$(PKG_SUFFIX)
_mk_dir = $(MK)/packages/$(NAME)/$(TARGET_ARCH)

PASS1_ENV = env -i HOME=$(HOME) TERM=$(TERM) LC_ALL=POSIX PATH=$(CROSS_TOOLS)/bin:/bin:/usr/bin 

# $1 = name
# $2 = version
# $3 = suffix
# $4 = subname, optional
# export var: $(1)_src $(1)_tar
define prepare_source
$(1)$(if $(4),-$(4),)_untared := $(SRC)/$(1)$(if $(2),-$(2),)/.$(1)$(if $(4),-$(4),)$(if $(2),-$(2),)_untared
$(1)$(if $(4),-$(4),)_tar := $(TAR_DIR)/$(1)$(if $(4),-$(4),)$(if $(2),-$(2),).$(3)
$$($(1)$(if $(4),-$(4),)_untared): $$($(1)$(if $(4),-$(4),)_tar)
	@mkdir -p $(SRC)/$(1)$(if $(2),-$(2),)
	$(call UNTARCMD,$(1)$(if $(2),-$(2),))

$(1)_src := $$($(1)_src) $$($(1)$(if $(4),-$(4),)_untared)
$$(if $$($(1)_src_dir),,$$(eval $(1)_src_dir := $(SRC)/$(1)$(if $(2),-$(2),)))
#$$(warning $(1)_src_dir = $$($(1)_src_dir))
#UNTAR_TGTS = $(SRC)/.$(notdir $(1)) $(UNTAR_TGTS)
endef

# $1 = name
# $2 = version
# $3 = patch name
# $4 = dependency (optional)
define patch_source_
$(1)_patch_dest := $$(dir $$(firstword $$($(1)_src))).$$(notdir $$($(1)_patch_file))
$$($(1)_patch_dest): $$($(1)_patch_file) $$($(1)_src) $(4)
	$(value PATCHCMD)

$(1)-$(3)_patched := $$($(1)-$(3)_patched) $$($(1)-$(3)_patch_dest) 
#$$(warning $(1)-$(3)_patch_dest = $$($(1)-$(3)_patch_dest))
#$$(warning $(1)_patched = $$($(1)_patched))
endef

# $1 = pache list
# $2 = basename, like gcc
# $3 = version
patch_source = $(foreach p,$(1),$(eval $(call patch_source_,$(2),$(3),$(p),$($(2)_src))))

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
export PREFIX=$(BASE); \
export PATH=$(CROSS_TOOLS)/bin:/bin:/usr/bin 
endef

MK_ENV2 = $(call MK_ENV2_)

define MK_ENV2_
export CC="$(TARGET)-gcc" ;\
export CXX="$(TARGET)-g++";\
export AR="$(TARGET)-ar"; \
export AS="$(TARGET)-as";\
export RANLIB="$(TARGET)-ranlib";\
export LD="$(TARGET)-ld";\
export STRIP="$(TARGET)-strip";\
export PATH=$(CROSS_TOOLS)/bin:/bin:/usr/bin 
endef

TOUCH_DEST = mkdir -p $(dir $@) && touch $@

_get_file := $(shell which curl &> /dev/null && echo curl -L -o ||echo wget --no-check-certificate -O)

# $1 - target file
# $2 - url
# $3 - result target file list
define download_file
$(DOWNLOAD)/$(1) :
	$$(Q)$$(call echo_cmd,-n,Fetch $(2) --> $$@ ... ,,)
	($(_get_file) $$@ $(2) && touch $$@; $\\
		if [ "x$$$$?" == "x0" ]; then $\\
			grep "Not Found" $$@ 2>&1 >/dev/null && $\\
			$$(call echo_err,,Failed) && rm -fr $$@ && exit 1; $\\
			$$(call echo_cmd,,Done!,,) ;$\\
			if [ -f $(MYPATCHES_DIR)/$(1).patch ]; then $\\
				patch -b -V t -i $(MYPATCHES_DIR)/$(1).patch $$@; $\\
			fi $\\
		else $\\
			$$(call echo_err,,Failed); rm -f $$@; exit 1; $\\
		fi)

$3 := $(DOWNLOAD)/$1 $$($3)
endef

# $1 - target/url pair list
# $2 - result target file list
get_clfs_htmls = $(if $1,$(eval $(call download_file,$(firstword $1),$(firstword $(call rest,$1)),$2)) \
                        $(eval $(call get_clfs_htmls,$(call rest,$(call rest,$1)),$2)))

# $1 - src html file
# $2 - result package tgt list
define mk_dw_tgt_list_from_html
$2 := $(notdir $(1:.html=.mk)).$(2) $$($2) 
$(notdir $(1:.html=.mk)): $(1) Makefile
	$$(Q)$$(call echo_cmd,-n,Parse $$< to $$@ ... ,,)
	$$(Q)(echo -n "$$(@).$2 := " > $$@ && $\\
	(grep -A1 "Download:" $$< | $\\
		sed -n 's,"\(\(http\|ftp\)://\(.*\)/\([^/]*\)\)".*$$$$,\4 \\,p'>>$$@)  && $\\
	echo  "" >> $$@ && $\\
	(grep -A1 "Download:" $$< | $\\
		sed -n 's,"\(\(http\|ftp\)://\(.*\)/\([^/]*\)\)".*$$$$,\4: $$(DOWNLOAD)/\4\n$$(DOWNLOAD)/\4:\n\t$$(call DOWNLOAD_PKG,\1)\n,p' |$\\
		sed 's/^[ ]*//'>> $$@ ) && $$(call echo_cmd,,Done!))

-include $(notdir $(1:.html=.mk))
endef

# $1 html file list
# $2 packge tgt list name
get_clfs_packages = $(foreach f,$1,$(eval $(call mk_dw_tgt_list_from_html,$f,$2)))

DOWNLOAD_PKG = $$(Q)$$\(call echo_cmd\,\,"I: Downloading $$(notdir $$@)"\)\n\t$$(Q)\(wget --progress=bar -nv -c $(1) -O $$@ || (rm -f $$@ ; exit 1;)\)

_check_file = $(wildcard $(filter $(DOWNLOAD)/$(1),$(2)),$(1),,)

comma := ,
# $(call try_mount,proc,proc,$(BASE)/proc)
# $1 - source dir
# $2 - mount options
# $3 - tgt dir
try_mount = ((cat /proc/mounts|awk '{print $$2'}|grep $3|grep ^$3$$ 2>&1>/dev/null) || ($(call echo_cmd,,mount $2 $1 $3) && sudo mkdir -p $3 && sudo mount $2 $1 $3))

sharp := \#
# $1 - goto chroot env
go-chroot = setarch linux32 sudo /usr/sbin/chroot '$(BASE)' $(TOOLS)/bin/env -i HOME=/root TERM="${TERM}" PS1='\u:\W $$(sharp) ' PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin /tools/bin/bash --login +h

# $1 - run command in chroot
chroot-run = setarch linux32 sudo /usr/sbin/chroot '$(BASE)' $(TOOLS)/bin/env -i HOME=/root TERM="${TERM}" PS1='\u:\W $(sharp) ' BASE=/chroot-bld PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin sh -c '$1'

# $1 = name
# $2 = version
define build_tgt_pass1
$(1)_SRC := $$(_src_dir)
$(1)_1_dest := $$(CROSS_TOOLS)/.bld/$(1)_1
$(1)_1_bld := $$(BLD)/$(1)-$(2)
_$(1)_1_deps := $$(foreach d,$($(1)_1_deps),$$(dir $$($(1)_1_dest))$$(d))
PASS1_TGTS := $$($(1)_1_dest) $$(PASS1_TGTS)
#$$(warning $(1)=$$($(1)_preconfig))
$$($(1)_1_dest): $$($(1)_src) $$($(1)_patch_dest) $$(_$(1)_1_deps) 
	(rm -fr $$($(1)_1_bld) && mkdir -p $$($(1)_1_bld) && \
			(($$(if $$($(1)_preconfig),$$($(1)_preconfig),true))&&\
			(source $(MK)/env.sh ; $(MK_ENV1); \
			cd $$($(1)_1_bld) && \
			$$(if $$($(1)_configcmd),$$($(1)_configcmd),true) && \
			$$(if $$($(1)_makecmd),$$($(1)_makecmd),true)&& \
			$$(if $$($(1)_installcmd),$$($(1)_installcmd),true)&& \
			$$(if $$($(1)_postinstallcmd),$$($(1)_postinstallcmd),true) &&\
			$$(TOUCH_DEST) ))\
	)
endef

# $1 = name
# $2 = version
define download_tar_file
$(DOWNLOAD)/$$($(1)_tar_file):
	@$$(call echo_cmd,,Fetch $$($(1)_pkg_url) --> $$@ ... ,,)
	($$(_get_file) $$@ $$($(1)_pkg_url) && touch $$@; \
		($$(if $$(strip $$($(1)_md5sum)),echo "$$(strip $$($(1)_md5sum))  $$@" | md5sum -c &>/dev/null,true) || \
		$$(if $$(strip $$($(1)_sha1sum)),echo "$$(strip $$($(1)_sha1sum))  $$@" | sha1sum -c &>/dev/null,true) || \
		($$(call echo_err,,Failed); rm -fr $$@ && exit 1)) && \
		$$(call echo_cmd,,Done!,,))

PKG_DOWNLOADED := $(DOWNLOAD)/$$($(1)_tar_file) $$(PKG_DOWNLOADED)

endef

__pairmap = $(if $2$3,$(eval $(call $1,$(firstword $2),$(firstword $3))) $(call __pairmap,$(wordlist 2,$(words $2),$2),$(wordlist 2,$(words $3),$3)),)
# $1 = file name
# $2 = file url
define download_patch_file
$(NAME)_patch_file := $(DOWNLOAD)/$(1)
$$($(NAME)_patch_file):
	@$$(call echo_cmd,-n,Fetch $(2) --> $$@ ... ,,)
	@($(_get_file) $$@ $(2) && touch $$@; $\\
		if [ "x$$$$?" == "x0" ]; then $\\
			grep "Not Found" $$@ 2>&1 >/dev/null && $\\
			$$(call echo_err,,Failed) && rm -fr $$@ && exit 1; $\\
			$$(call echo_cmd,,Done!,,) ;$\\
		else $\\
			$$(call echo_err,,Failed); rm -f $$@; exit 1; $\\
		fi)

PATCHES_DOWNLOADED := $($(NAME)_patch_file) $(PATCHES_DOWNLOADED)
endef



