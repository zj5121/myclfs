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
UNTAR.bz2 = $(call echo_cmd,-n,$(INFO_PREP_SRC) $(notdir $<) ...); tar --strip=1 -jxf 
UNTAR.gz = $(call echo_cmd,-n,$(INFO_PREP_SRC) $(notdir $<) ...) ;tar --strip=1 -zxf 
UNTAR.xz = $(call echo_cmd,-n,$(INFO_PREP_SRC) $(notdir $<) ...) ;tar --strip=1 -Jxf 

# $1 = src dest dir
define UNTARCMD
@(mkdir -p $(SRC)/$(1) && $$(UNTAR$$(suffix $$<)) $$< -C $(SRC)/$(1) && touch $$@ && $(call echo_cmd,, done))
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
$(1)$(if $(4),-$(4),)_untared := $(SRC)/$(1)$(if $(2),-$(2),)/.$(1)$(if $(4),-$(4),)$(if $(2),-$(2),)_untared
$(1)$(if $(4),-$(4),)_tar := $(TAR_DIR)/$(1)$(if $(4),-$(4),)$(if $(2),-$(2),).$(3)
#$$(warning $(1)$(if $(2),-$(2),))
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
$(1)-$(3)_patch := $$(DOWNLOAD)/$(1)-$(2)-$(3).patch
$(1)-$(3)_patch_dest := $$(dir $$(firstword $$($(1)_src))).$$(notdir $$($(1)-$(3)_patch))
$$($(1)-$(3)_patch_dest): $$($(1)-$(3)_patch) $$($(1)_src) $(4)
	$$(warning $$($(1)-$(3)_patch_dest))
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

# $1 - target file
# $2 - url
# $3 - result target file list
define download_file
$(DOWNLOAD)/$(1) :
	$$(Q)$$(call echo_cmd,-n,Fetch $(2) --> $$@ ... ,,)
	@(wget -q -c $(2) -O $$@ && touch $$@; $\\
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

# $1 - package name
# $2 - version number
define build_tgt
_file := $(or $(call _check_file,$(DOWNLOAD)/$(1)-$(2).tar.gz,$(call _check_file,$(DOWNLOAD)/$(1)-$(2).tar.bz2),$(call _check_file,$(DOWNLOAD/$(1)-$(2).tar.xz))))
ifeq (_file,)
_file := $(or $(call _check_file,$(DOWNLOAD)/$(1)-$(2).tar.gz,$(call _check_file,$(DOWNLOAD)/$(1)-$(2).tar.bz2),$(call _check_file,$(DOWNLOAD/$(1)-$(2).tar.xz)))))
else
endif
$(eval $(call prepare_source,$1,$2,tar.bz2)))
$(eval $(call patch_source, NCURSES_PATCHES,ncurses,$(NCURSES_VER)))
endef
