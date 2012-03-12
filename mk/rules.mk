
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
PV := $(shell which pv 2>&1 > /dev/null && echo pv || echo cat)
UNTAR.bz2 = $(call echo_cmd,,$(INFO_PREP_SRC) $(notdir $<) ...); $(PV) $< | tar --strip=1 -jx 
UNTAR.gz  = $(call echo_cmd,,$(INFO_PREP_SRC) $(notdir $<) ...); $(PV) $< | tar --strip=1 -zx 
UNTAR.xz  = $(call echo_cmd,,$(INFO_PREP_SRC) $(notdir $<) ...); $(PV) $< | tar --strip=1 -Jx 

# $1 = src dest dir
define UNTARCMD
(mkdir -p $(1) && $$(UNTAR$$(suffix $$<)) -C $(1) && mkdir -p $$(dir $$@) && touch $$@ )
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
# $5 = pass#
# export var: $(1)_src-$(5) $(1)_srcfile-$(5)
define prepare_source
#$$(warning prepare_source->$(1), $(2), $(3), $(4), $(5))
_untar := $$(dir $$(_src_dir)).src/$$(notdir $$(_src_dir))-$(5)
_tarfile := $(TAR_DIR)/$(1)$(if $(4),-$(4),)$(if $(2),-$(2),).$(3)
$$(_untar): $$(_tarfile)
	rm -fr $$(_src_dir)
	mkdir -p $$(dir $$@)
	$(call UNTARCMD,$(_src_dir))

$(1)_srcdir-$(5) := $$(_src_dir)
$(1)_src-$(5) := $$(_untar)
$(1)_srcfile-$(5) := $$(_tarfile)

#$$(warning $$(_untar): $$(_tarfile), $$($(1)_src))
endef

# $1 = srcdir
define PATCHCMD
($$(call echo_cmd,-n,$$(INFO_PATCH_SRC) $$(notdir $$<) ...); patch -d $(1) -i $$< -p1 2>&1 >/dev/null \
&& touch $$@ && $$(call echo_cmd,, done))
endef

# $1 = name
# $2 = version
# $3 = patch name
# $4 = dependency (optional)
# $5 = patch#
define patch_source_
#$$(warning patch_source, $(1),$(2),$(3),$(4),$(5))
__$(1)_patch_count-$(5) := $$(__$(1)_patch_count-$(5)) x
_patched := $(SRC)/.src/$$(notdir $$(_src_dir))_patched_$$(words $$(__$(1)_patch_count-$(5)))-$(5)
_patch_file := $(DOWNLOAD)/$(3)
$$(_patched): $$(_patch_file) $$($(1)_src-$(5)) $(4)
	$(call PATCHCMD,$$($(1)_srcdir-$(5)))

$(1)_patched-$(5) := $$($(1)_patched-$(5)) $$(_patched) 

#$$(warning $$(_patched): $$(_patch_file) $$($(1)_src-$(5)) $(4) )
#$$(warning $$($(1)_patched-$(5)))
endef

# $1 = pache list
# $2 = basename, like gcc
# $3 = version
# $4 = pass#
patch_source = $(foreach p,$(1),$(eval $(call patch_source_,$(2),$(3),$(p),$($(2)_src),$(4))))

# $1 src dir
# $2 dest dir
define copy_dir_clean 
mkdir -p "$2" && (cd "$1" && tar cf - \
	--exclude=CVS --exclude=.svn --exclude=.git --exclude=.pc \
	--exclude="*~" --exclude=".#*" \
	--exclude="*.orig" --exclude="*.rej" \
	.) | (cd "$2" && tar xf -) 
endef

define SETUP_ENV_COMMON
export PATH=$(CROSS_TOOLS)/bin:/bin:/usr/bin 
endef

SETUP_ENV-1 = $(SETUP_ENV_COMMON)
#$(warning env-1=$(SETUP_ENV-1))
SETUP_ENV-2 = $(SETUP_ENV-1)
#$(warning env-2=$(SETUP_ENV-2))

define SETUP_ENV-3_
export CC="$(TARGET)-gcc" ;\
export CXX="$(TARGET)-g++";\
export AR="$(TARGET)-ar"; \
export AS="$(TARGET)-as";\
export RANLIB="$(TARGET)-ranlib";\
export LD="$(TARGET)-ld";\
export STRIP="$(TARGET)-strip"
endef

SETUP_ENV-3 = $(SETUP_ENV-2) ; $(SETUP_ENV-3_)
#$(warning env-3=$(SETUP_ENV-3))

TOUCH_DEST = mkdir -p $(dir $@) && touch $@

_get_file := $(shell which curl 2>&1 >/dev/null && echo curl -L -o || echo wget --no-check-certificate -O)

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
# $3 = pass#
define build_tgt_pass
#$$(warning build_tgt_pass->$(1), $(2), $(3))
$$(CROSS_TOOLS)/.bld/$(1)-$(3): $$($(1)_src-$(3)) $$($(1)_patched-$(3)) $$($(1)_deps-$(3))
	(rm -fr $(_bld_dir) && mkdir -p $(_bld_dir) && \
			(($$(if $$($(1)_preconfig_$(3)),$$($(1)_preconfig_$(3)),true))&&\
			(env -i /bin/sh --noprofile --norc -c "source $(MK)/env-$(3).sh ; $(SETUP_ENV-$(3)); \
			cd $(_bld_dir) && \
			$$(if $$($(1)_configcmd_$(3)),$$($(1)_configcmd_$(3)),true) && \
			$$(if $$($(1)_afterconfig_$(3)),$$($(1)_afterconfig_$(3)),true) && \
			$$(if $$($(1)_makecmd_$(3)),$$($(1)_makecmd_$(3)),true)&& \
			$$(if $$($(1)_installcmd_$(3)),$$($(1)_installcmd_$(3)),true)&& \
			$$(if $$($(1)_postinstallcmd_$(3)),$$($(1)_postinstallcmd_$(3)),true)" &&\
			$$(TOUCH_DEST) ))\
	)
$(1)-$(3) := $$(CROSS_TOOLS)/.bld/$(1)-$(3)

TGTS_PASS-$(3) := $(TGTS_PASS-$(3)) $$(CROSS_TOOLS)/.bld/$(1)-$(3)

#$$(warning $$(CROSS_TOOLS)/.bld/$(1)-$(3): $$($(1)_src-$(3)), $$($(1)_patched-$(3)), $$($(1)_deps-$(3)))
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
#$$(warning $$($(DOWNLOAD)/$$($(1)_tar_file)): )
endef

__pairmap = $(if $2$3,$(eval $(call $1,$(firstword $2),$(firstword $3))) $(call __pairmap,$1,$(wordlist 2,$(words $2),$2),$(wordlist 2,$(words $3),$3)),)
# $1 = file name
# $2 = file url
define download_patch_file
$(NAME)_patch_file := $(DOWNLOAD)/$(1)
$$($(NAME)_patch_file):
	@$$(call echo_cmd,-n,Fetch $(2) --> $$@ ... ,,)
	($(_get_file) $$@ $(2) && touch $$@; $\\
		if [ "x$$$$?" == "x0" ]; then $\\
			grep "Not Found" $$@ 2>&1 >/dev/null && $\\
			$$(call echo_err,,Failed) && rm -fr $$@ && exit 1; $\\
			$$(call echo_cmd,,Done!,,) ;$\\
		else $\\
			$$(call echo_err,,Failed); rm -f $$@; exit 1; $\\
		fi)

PATCHES_DOWNLOADED := $$($(NAME)_patch_file) $$(PATCHES_DOWNLOADED)
#$$(warning $$($(NAME)_patch_file): )
endef

