
CURDIR := $(shell pwd)
MK := $(CURDIR)/mk

include $(MK)/gmsl
include $(MK)/config.mk
include $(MK)/rules.mk
include $(MK)/packages_def.mk


.PHONY: prep all

all: prep download_pkgs build

# first step, download clfs htmls
clfs_htmls :=

$(call get_clfs_htmls,$(clfs_files),clfs_htmls)

# second is to construct package targets

#  this will gnerate *.mk file, which includes package targets
$(call get_clfs_packages,$(clfs_htmls),download_list)

htmls: $(clfs_htmls)

download_pkgs : prep htmls $(foreach f,$(download_list),$($f))

prep: 
	$(Q)(if [ ! -d $(DOWNLOAD) ] ; then install -d -v $(DOWNLOAD); fi )
	$(Q)(if [ ! -d $(BASE) ] ; then install -d -v $(BASE); fi)
	$(Q)(if [ ! -d $(BASE)$(CROSS_TOOLS) ] ; then \
		install -d -v $(BASE)$(CROSS_TOOLS) && \
		sudo ln -f -s $(BASE)$(CROSS_TOOLS) / ; fi)
	$(Q)(if [ ! -d $(BASE)$(TOOLS) ] ; then \
		install -d -v $(BASE)$(TOOLS)  && \
		sudo ln -f -s $(BASE)$(TOOLS) / ; fi)



# gmp lib
$(eval $(call prepare_source,gmp,$(GMP_VER),tar.bz2))
gmp_dest := $(CROSS_TOOLS)/.bld/gmp
gmp_bld  := $(BLD)/gmp-$(GMP_VER)
stage1_ := $(gmp_dest) $(stage1_) 
$(gmp_dest): $(gmp_src) 
	(rm -fr $(gmp_bld) && mkdir -p $(gmp_bld) && \
	(source $(MK)/env.sh ; $(call MK_ENV1);\
	cd $(gmp_bld) && \
	CPPFLAGS="-fexceptions" $(gmp_src_dir)/configure \
	--prefix=$(CROSS_TOOLS) \
	--enable-cxx && \
	$(MAKE) && $(MAKE) install && $(MAKE) check &&\
	mkdir -p $(dir $@) && touch $@\
	))

# mpfr lib
$(eval $(call prepare_source,mpfr,$(MPFR_VER),tar.bz2))
#$(eval $(call patch_source,MPFR_PATCHES,mpfr,3.1.0))
mpfr_dest := $(CROSS_TOOLS)/.bld/mpfr
mpfr_bld  := $(BLD)/mpfr-$(MPFR_VER)
stage1_ := $(mpfr_dest) $(stage1_) 
$(mpfr_dest): $(mpfr_src) $(gmp_dest)
	(rm -fr $(mpfr_bld) && mkdir -p $(mpfr_bld) &&\
	(source $(MK)/env.sh ; $(call MK_ENV1); \
	cd $(mpfr_bld) && \
	LDFLAGS="-Wl,-rpath=$(CROSS_TOOLS)/lib" \
	$(mpfr_src_dir)/configure \
	--prefix=$(CROSS_TOOLS) \
	--with-gmp=$(CROSS_TOOLS) &&\
	$(MAKE) && $(MAKE) install && $(MAKE) check && \
	mkdir -p $(dir $@) && touch $@))

# mpc lib
$(eval $(call prepare_source,mpc,$(MPC_VER),tar.gz))
mpc_dest := $(CROSS_TOOLS)/.bld/mpc
mpc_bld := $(BLD)/mpc-$(MPC_VER)
stage1_ := $(mpc_dest) $(stage1_) 
$(mpc_dest): $(mpc_src) $(mpfr_dest) $(gmp_dest)
	@($(call echo_cmd,,$(INFO_CONFIG) $(notdir $(notdir $(mpc_bld)))))
	@(rm -fr $(mpc_bld) && mkdir -p $(mpc_bld) &&\
	(source $(MK)/env.sh ; $(call MK_ENV1) ;\
	cd $(mpc_bld) &&\
	CPPFLAGS="-I$(CROSS_TOOLS)/include" \
	LDFLAGS="-Wl,-rpath=$(CROSS_TOOLS)/lib" \
	$(mpc_src_dir)/configure \
	--prefix=$(CROSS_TOOLS) \
	--with-gmp=$(CROSS_TOOLS) \
	--with-mpfr=$(CROSS_TOOLS) &&\
	$(MAKE) && $(MAKE) install && $(MAKE) check && \
	mkdir -p $(dir $@) && touch $@) )


$(eval $(call prepare_source,ppl,$(PPL_VER),tar.bz2))
ppl_dest := $(CROSS_TOOLS)/.bld/libppl1
ppl_bld := $(BLD)/ppl-$(PPL_VER)
$(ppl_dest): $(ppl_src) $(mpc_dest)
	@$(call echo_cmd,,$(INFO_CONFIG) $(notdir $(ppl_bld)))
	@(rm -fr $(ppl_bld) && mkdir -p $(ppl_bld) &&\
	(source $(MK)/env.sh ; $(call MK_ENV1) ;\
	cd $(ppl_bld) && \
	CFLAGS="-I$(CROSS_TOOLS)/include" CPPFLAGS="-I$(CROSS_TOOLS)/include" \
	LDFLAGS="-Wl,-rpath=$(CROSS_TOOLS)/lib" \
	$(ppl_src_dir)/configure --prefix=$(CROSS_TOOLS) \
	--enable-interfaces="c,cxx" \
	--disable-optimization \
	--disable-watchdog \
	--with-libgmp-prefix=$(CROSS_TOOLS) \
	--with-libgmpxx-prefix=$(CROSS_TOOLS) && \
	$(MAKE) && $(MAKE) install && \
	mkdir -p $(dir $@) && touch $@) )



$(eval $(call prepare_source,cloog-ppl,$(CLOOG_VER),tar.gz))
cloog_dest := $(CROSS_TOOLS)/.bld/libcloog1
cloog_bld := $(BLD)/cloog-ppl-$(CLOOG_VER)
$(cloog_dest): $(cloog-ppl_src) $(gmp_dest) $(ppl_dest)
	@$(call echo_cmd,,$(INFO_CONFIG) $(notdir $(notdir $(cloog_bld))))
	(rm -fr $(cloog_bld) && mkdir -p $(cloog_bld) &&\
	(cd $(cloog-ppl_src_dir) && \
	 [ ! -f configure.orig ] && cp -v configure{,.orig} && \
	 sed -e "/LD_LIBRARY_PATH=/d" configure.orig > configure) ; \
	(source $(MK)/env.sh ; $(call MK_ENV1); \
	cd $(cloog_bld) && LDFLAGS="-Wl,-rpath=$(CROSS_TOOLS)/lib" \
	$(cloog-ppl_src_dir)/configure --prefix=$(CROSS_TOOLS) \
	--enable-shared \
	--with-bits=gmp \
	--with-gmp=$(CROSS_TOOLS) \
	--with-ppl=$(CROSS_TOOLS) && \
	$(MAKE) && $(MAKE) install && $(MAKE) check && \
	mkdir -p $(dir $@) && touch $@) )

# libelf
$(eval $(call prepare_source,libelf,$(LIBELF_VER),tar.gz))
libelf_dest := $(CROSS_TOOLS)/lib/libelf.a
libelf_bld := $(BLD)/libelf-$(LIBELF_VER)
$(libelf_dest): $(libelf_src)
	@($(call echo_cmd,,$(INFO_CONFIG) $(notdir $(notdir $(cloog_bld)))))
	@(rm -fr $(libelf_bld) && mkdir -p $(libelf_bld) && \
	(source $(MK)/env.sh;  $(call MK_ENV1); \
	cd $(libelf_bld) && \
	$(libelf_src_dir)/configure --prefix=$(CROSS_TOOLS) \
	--build=$(BUILD) \
	--target=$(TARGET) \
	--host=$(BUILD) \
	--disable-nls \
	--disable-shared && \
	$(MAKE) && $(MAKE) install))

	
# bintuils pass1
$(eval $(call prepare_source,binutils,$(BINUTILS_VER),tar.bz2))
binutils_dest := $(CROSS_TOOLS)/.bld/binutils1
binutils_bld := $(BLD)/binutils-$(BINUTILS_VER)
$(binutils_dest): $(binutils_src) $(cloog_dest) 
# $(libelf_dset)
	@$(call echo_cmd,,$(INFO_CONFIG) $(notdir $(binutils_bld)))
	(rm -fr $(binutils_bld) && mkdir -p $(binutils_bld) && \
	cd $(binutils_bld) && \
	source $(MK)/env.sh ; $(call MK_ENV1) ;\
	(AR=ar AS=as \
	$(binutils_src_dir)/configure \
	--prefix=$(CROSS_TOOLS)  \
	--host=$(BUILD) \
	--target=$(TARGET) \
	--with-sysroot=$(BASE) \
	--with-lib-path=$(TOOLS)/lib \
	--disable-nls \
	--enable-shared \
	--disable-multilib && \
	$(MAKE) configure-host && $(MAKE) && make install \
	&& mkdir -p $(dir $@) && touch $@) && \
	install -d -v $(TOOLS)/include && \
	install -v $(binutils_src_dir)/include/libiberty.h $(TOOLS)/include)

# install kernel headers for glibc
$(eval $(call prepare_source,linux,$(LINUX_VER),tar.bz2))
linux_dest := $(TOOLS)/.bld/linux_hdr
linux_dest_dir := $(TOOLS)/include
linux_bld := $(BLD)/linux-$(LINUX_VER)
$(linux_dest): $(linux_src) 
	@install -dv $(dir $(linux_dest_dir))
	(mkdir -p $(TOOLS)/include && \
	rm -rf $(linux_bld) &&\
	$(call copy_dir_clean,$(linux_src_dir),$(linux_bld)) &&\
	cd $(linux_bld) &&\
	source $(MK)/env.sh ; $(call MK_ENV1) ;\
	make ARCH=$(TARGET_ARCH) INSTALL_HDR_PATH=dest headers_install &&\
	cp -rv dest/include/* $(linux_dest_dir)/ && mkdir -p $(dir $@) && touch $@ \
	)

$(eval $(call prepare_source,gcc,$(GCC_VER),tar.bz2))
$(call patch_source,GCC_PATCHES,gcc,$(GCC_VER))
gcc1_dest := $(CROSS_TOOLS)/.bld/gcc1
gcc1_bld := $(BLD)/gcc-$(GCC_VER)
$(gcc1_dest) : $(gcc_src) $(gcc_patched) $(binutils_dest) $(linux_dest)
	@$(call echo_cmd,,$(INFO_CONFIG) $(notdir $(notdir $(gcc1_dest))))
	( cd $(gcc_src_dir) && \
	echo -en "#undef STANDARD_INCLUDE_DIR\n#define STANDARD_INCLUDE_DIR \"$(TOOLS)/include/\"\n\n" >> gcc/config/linux.h && \
	echo -en "\n#undef STANDARD_STARTFILE_PREFIX_1\n#define STANDARD_STARTFILE_PREFIX_1 \"$(TOOLS)/lib/\"\n" >> gcc/config/linux.h && \
	echo -en "\n#undef STANDARD_STARTFILE_PREFIX_2\n#define STANDARD_STARTFILE_PREFIX_2 \"\"\n" >> gcc/config/linux.h  && \
	([ ! -f gcc/Makefile.in.orig ] && cp -v gcc/Makefile.in{,.orig} &&  \
	sed -e "s@\(^CROSS_SYSTEM_HEADER_DIR =\).*@\1 $(TOOLS)/include@g" \
    gcc/Makefile.in.orig > gcc/Makefile.in) ; \
	touch $(TOOLS)/include/limits.h && \
	rm -rf $(gcc1_bld) && \
	mkdir -p $(gcc1_bld) && cd $(gcc1_bld) && \
	(source $(MK)/env.sh ; $(call MK_ENV1) ;\
	AR=ar LDFLAGS="-Wl,-rpath=$(CROSS_TOOLS)/lib" \
	$(gcc_src_dir)/configure \
	--target=$(TARGET) \
	--build=$(BUILD) \
	--host=$(BUILD) \
	--prefix=$(CROSS_TOOLS) \
	--with-local-prefix=$(TOOLS) \
	--disable-libmudflap \
	--disable-libssp \
	--disable-libstdcxx-pch \
	--disable-multilib \
	--disable-nls \
	--disable-shared \
	--disable-threads \
	--disable-libgomp \
	--without-headers \
	--with-newlib \
	--disable-decimal-float \
	--disable-libffi \
	--disable-libquadmath \
	--enable-languages=c \
	--with-sysroot=$(BASE) \
	--with-gmp=$(CROSS_TOOLS) \
	--with-mpc=$(CROSS_TOOLS) \
	--with-mpfr=$(CROSS_TOOLS) \
	--with-ppl=$(CROSS_TOOLS) \
	--with-cloog=$(CROSS_TOOLS) && \
	$(MAKE) all-gcc all-target-libgcc && \
	$(MAKE) install-gcc install-target-libgcc && \
	mkdir -p $(dir $@) && touch $@ \
	))
			
# eglibc 1
$(eval $(call prepare_source,eglibc,$(EGLIBC_VER),tar.bz2))
$(call patch_source,EGLIBC_PATCHES,eglibc,$(EGLIBC_VER))
eglibc1_dest := $(TOOLS)/.bld/eglibc1
eglibc1_bld := $(BLD)/eglibc-$(GCC_VER)
$(eglibc1_dest) : $(eglibc_src) $(eglic_patched) $(gcc1_dest) $(linux_dest)
	@$(call echo_cmd,,$(INFO_CONFIG) $(notdir $(notdir $(eglibc1_dset))))
	(cd $(eglibc_src_dir) && \
		([ ! -f Makeconfig.orig ] && cp -v Makeconfig{,.orig} && \
			sed -e 's/-lgcc_eh//g' Makeconfig.orig > Makeconfig) ; \
	mkdir -p $(eglibc1_bld) && \
	cd $(eglibc1_bld) && \
	(echo "libc_cv_forced_unwind=yes" > config.cache; \
		echo "libc_cv_c_cleanup=yes" >> config.cache; \
		echo "libc_cv_gnu89_inline=yes" >> config.cache; \
		echo "libc_cv_ssp=no" >> config.cache\
	) &&  \
	(source $(MK)/env.sh ; $(call MK_ENV1); \
	BUILD_CC="gcc" CC="$(TARGET)-gcc" \
	AR="$(TARGET)-ar" RANLIB="$(TARGET)-ranlib" \
	CFLAGS="-march=$(shell cut -d- -f1 <<< '$(TARGET)') -mtune=generic -g -O2" \
	$(eglibc_src_dir)/configure \
	--prefix=$(TOOLS) \
	--host=$(TARGET)  \
	--build=$(BUILD) \
	--disable-profile \
	--enable-add-ons \
	--with-tls \
	--enable-kernel=2.6.0 \
	--with-__thread \
	--with-binutils=$(CROSS_TOOLS)/bin \
	--with-headers=$(TOOLS)/include \
	--cache-file=config.cache &&\
	$(MAKE) && make install && \
	mkdir -p $(dir $@) && touch $@ \
	))

# gcc2
# use source untared and patched before
gcc2_dest := $(CROSS_TOOLS)/.bld/gcc2
gcc2_bld := $(BLD)/gcc-$(GCC_VER)
$(gcc2_dest) : $(eglibc1_dest)
	@$(call echo_cmd,,$(INFO_CONFIG $(notdir $(notdir $(gcc2_dest)))))
	(rm -fr $(gcc2_bld) && mkdir -p $(gcc2_bld) && \
	cd $(gcc2_bld) && \
	(source $(MK)/env.sh ; $(call MK_ENV1) ; \
	AR=ar LDFLAGS="-Wl,-rpath=$(CROSS_TOOLS)/lib" \
	$(gcc_src_dir)/configure \
	--prefix=$(CROSS_TOOLS) \
	--build=$(BUILD) \
	--target=$(TARGET) \
	--host=$(BUILD) \
	--with-sysroot=$(BASE) \
	--with-local-prefix=$(TOOLS) \
	--disable-nls \
	--enable-shared \
	--enable-languages=c,c++ \
	--enable-__cxa_atexit \
	--with-mpfr=$(CROSS_TOOLS) \
	--with-gmp=$(CROSS_TOOLS) \
	--enable-c99 \
	--with-ppl=$(CROSS_TOOLS) \
	--with-cloog=$(CROSS_TOOLS) \
	--enable-long-long \
	--enable-thread=posix \
	--disable-multilib && \
	$(MAKE) AS_FOR_TARGET="$(TARGET)-as" LD_FOR_TARGET="$(TARGET)-ld" && \
	make install && mkdir -p $(dir $@) && touch $@))


build_stage1: $(gcc2_dest)

#############################################
# temporary system build

# gmp
gmp2_dest := $(TOOLS)/.bld/gmp
gmp2_bld  := $(BLD)/gmp-$(GMP_VER)
$(gmp2_dest): $(gcc2_dest)
	@$(call echo_cmd,,$(INFO_CONFIG $(notdir $(notdir $(gmp2_dest)))))
	(rm -fr $(gmp2_bld) && mkdir -p $(gmp2_bld) && \
	(source $(MK)/env2.sh ; $(MK_ENV2);\
	cd $(gmp2_bld) && \
	HOST_CC=gcc	CPPFLAGS="-fexceptions" $(gmp_src_dir)/configure \
	--prefix=$(TOOLS) \
	--build=$(BUILD) \
	--host=$(TARGET) \
	--enable-cxx && \
	$(MAKE) && $(MAKE) install && \
	$(call TOUCH_DEST) ))

# mpfr lib
mpfr2_dest := $(TOOLS)/.bld/mpfr
mpfr2_bld := $(BLD)/mpfr-$(MPFR_VER)
$(mpfr2_dest) : $(gmp2_dest)
	@$(call echo_cmd,,$(INFO_CONFIG $(notdir $(notdir $(mpfr2_dest)))))
	(rm -fr $(mpfr2_bld) && mkdir -p $(mpfr2_bld) && \
	(source $(MK)/env2.sh ; $(MK_ENV2);\
	cd $(mpfr2_bld) && \
	$(mpfr_src_dir)/configure \
	--prefix=$(TOOLS) \
	--build=$(BUILD) \
	--host=$(TARGET) \
	--with-gmp=$(TOOLS) && \
	$(MAKE) && $(MAKE) install &&\
	$(call TOUCH_DEST)) )

# mpc lib
mpc2_dest := $(TOOLS)/.bld/mpc
mpc2_bld := $(BLD)/mpc-$(MPC_VER)
$(mpc2_dest) : $(mpfr2_dest)
	@$(call echo_cmd,,$(INFO_CONFIG $(notdir $(notdir $(mpc2_dest)))))
	(rm -fr $(mpc2_bld) && mkdir -p $(mpc2_bld) && \
	(source $(MK)/env2.sh ; $(MK_ENV2);\
	cd $(mpc2_bld) && \
	EGREP="grep -E" \
	$(mpc_src_dir)/configure \
	--prefix=$(TOOLS) \
	--build=$(BUILD) \
	--host=$(TARGET) && \
	$(MAKE) && $(MAKE) install &&\
	$(call TOUCH_DEST)) )


# ppl lib
ppl2_dest := $(TOOLS)/.bld/ppl
ppl2_bld := $(BLD)/ppl-$(PPL_VER)
$(ppl2_dest) : $(mpc2_dest)
	@$(call echo_cmd,,$(INFO_CONFIG $(notdir $(notdir $(ppl2_dest)))))
	(rm -fr $(ppl2_bld) && mkdir -p $(ppl2_bld) && \
	(source $(MK)/env2.sh ; $(MK_ENV2);\
	cd $(ppl2_bld) && \
	$(ppl_src_dir)/configure \
	--prefix=$(TOOLS) \
	--build=$(BUILD) \
	--host=$(TARGET) \
	--enable-interfaces="c,cxx" \
	--enable-shared \
	--disable-optimization \
	--with-libgmp-prefix=$(TOOLS) \
	--with-libgmpxx-prefix=$(TOOLS) && \
	echo '#define PPL_GMP_SUPPORTS_EXCEPTIONS 1' >> confdefs.h && \
	$(MAKE) && $(MAKE) install &&\
	$(call TOUCH_DEST)) )

# cloog 2
cloog2_dest := $(TOOLS)/.bld/cloog
cloog2_bld := $(BLD)/cloog-ppl-$(CLOOG_VER)
$(cloog2_dest) : $(ppl2_dest)
	@$(call echo_cmd,,$(INFO_CONFIG $(notdir $(notdir $(cloog2_dest)))))
	(rm -fr $(cloog2_bld) && mkdir -p $(cloog2_bld) && \
	(source $(MK)/env2.sh ; $(MK_ENV2);\
	cd $(cloog2_bld) && \
	$(cloog-ppl_src_dir)/configure \
	--prefix=$(TOOLS) \
	--build=$(BUILD) \
	--host=$(TARGET) \
	--with-bits=gmp \
	--with-ppl=$(TOOLS) \
	--with-gmp=$(TOOLS) && \
	$(MAKE) && $(MAKE) install &&\
	$(call TOUCH_DEST)) )

# binutils 2
binutils2_dest := $(TOOLS)/.bld/bintuils
binutils2_bld := $(BLD)/binutils-$(BINUTILS_VER)
$(binutils2_dest) : $(cloog2_dest)
	@$(call echo_cmd,,$(INFO_CONFIG $(notdir $(notdir $(binutils2_dest)))))
	(rm -fr $(binutils2_bld) && mkdir -p $(binutils2_bld) && \
	(source $(MK)/env2.sh ; $(MK_ENV2);\
	cd $(binutils2_bld) && \
	$(binutils_src_dir)/configure \
	--prefix=$(TOOLS) \
	--build=$(BUILD) \
	--host=$(TARGET) \
	--target=$(TARGET) \
	--with-lib-path=/tools/lib \
	--disable-nls \
	--enable-shared \
	--disable-multilib && \
	$(MAKE) configure-host && $(MAKE) && $(MAKE) install && \
	$(call TOUCH_DEST)))

gcc3_dest := $(TOOLS)/.bld/gcc3
gcc3_bld := $(BLD)/gcc-$(GCC_VER)
$(gcc3_dest): $(binutils2_dest)
	@$(call echo_cmd,,$(INFO_CONFIG),$(notdir $(notdir $(gcc3_dest))))
	(rm -fr $(gcc3_bld) && mkdir -p $(gcc3_bld) && \
	(source $(MK)/env2.sh ; $(MK_ENV2);\
	cd $(gcc3_bld) && \
	$(gcc_src_dir)/configure \
	--prefix=$(TOOLS) \
	--build=$(BUILD) \
	--host=$(TARGET) \
	--target=$(TARGET) \
	--with-local-prefix=$(TOOLS) \
	--enable-long-long \
	--enable-c99 \
	--enable-shared \
	--enable-threads=posix \
	--enable-__cxa_atexit \
	--disable-nls \
	--enable-languages=c,c++ \
	--disable-libstdcxx-pch \
	--disable-multilib && \
	(if [ ! -f Makefile.orig ] ; then \
		cp -v Makefile{,.orig} && \
		sed "/^HOST_\(GMP\|PPL\|CLOOG\)\(LIBS\|INC\)/s:-[IL]/\(lib\|include\)::" Makefile.orig > Makefile; \
	fi) && \
	$(MAKE) AS_FOR_TARGET="${AS}" LD_FOR_TARGET="${LD}" && $(MAKE) install && \
	$(call TOUCH_DEST)))


$(eval $(call prepare_source,zlib,$(ZLIB_VER),tar.bz2))
zlib_dest := $(TOOLS)/.bld/zlib
zlib_bld := $(zlib_src_dir)
$(zlib_dest): $(zlib_src)
	@$(call echo_cmd,,$(INFO_CONFIG) zlib)
	@(source $(MK)/env2.sh ; $(MK_ENV2);\
	cd $(zlib_bld) && \
	$(zlib_src_dir)/configure --prefix=$(TOOLS) && \
	$(MAKE) && make install && \
	$(call TOUCH_DEST))

$(eval $(call prepare_source,ncurses,$(NCURSES_VER),tar.gz))
$(eval $(call patch_source,NCURSES_PATCHES,ncurses,$(NCURSES_VER)))
ncurses_dest := $(TOOLS)/.bld/ncurses
ncurses_bld := $(ncurses_src_dir)
$(ncurses_dest): $(ncurses_src) $(ncurses_patched)
	@$(call echo_cmd,,$(INFO_CONFIG) ncurses)
	@(source $(MK)/env2.sh ; $(call MK_ENV2);\
	cd $(ncurses_bld) && \
	./configure --prefix=/tools \
	--with-shared \
    --host=$(TARGET) --build=$(HOST) \
    --without-debug --without-ada \
    --enable-overwrite --with-build-cc=gcc && \
    $(MAKE) && make install && \
    $(call TOUCH_DEST))

$(eval $(call prepare_source,bash,$(BASH_VER),tar.gz))
$(eval $(call patch_source,BASH_PATCHES,bash,$(BASH_VER)))
bash_dest := $(TOOLS)/.bld/bash
bash_bld := $(bash_src_dir)
$(bash_dest): $(bash_src) $(bash_patched)
	@$(call echo_cmd,,$(INFO_CONFIG) $(notdir $(bash_dest)))
	@(source $(MK)/env2.sh ; $(MK_ENV2);\
	cd $(bash_bld) &&\
		echo "ac_cv_func_mmap_fixed_mapped=yes" > config.cache ;\
		echo "ac_cv_func_strcoll_works=yes" >> config.cache ; \
		echo "ac_cv_func_working_mktime=yes" >> config.cache ;\
		echo "bash_cv_func_sigsetjmp=present" >> config.cache  ; \
		echo "bash_cv_getcwd_malloc=yes" >> config.cache ; \
		echo "bash_cv_job_control_missing=present" >> config.cache ;\
		echo "bash_cv_printf_a_format=yes" >> config.cache ;\
		echo "bash_cv_sys_named_pipes=present" >> config.cache ;\
		echo "bash_cv_ulimit_maxfds=yes" >> config.cache ;\
		echo "bash_cv_under_sys_siglist=yes" >> config.cache ;\
		echo "bash_cv_unusable_rtsigs=no" >> config.cache ; \
		echo "gt_cv_int_divbyzero_sigfpe=yes" >> config.cache ;\
	./configure --prefix=$(TOOLS) \
    --build=$(HOST) --host=$(TARGET) \
    --without-bash-malloc --cache-file=config.cache	&& \
    $(MAKE) && make install && \
    ln -fsv bash $(TOOLS)/bin/sh && \
    $(call TOUCH_DEST))

$(eval $(call prepare_source,bison,$(BISON_VER),tar.bz2))
bison_dest := $(TOOLS)/.bld/bison
bison_bld := $(bison_src_dir)
$(bison_dest): $(bison_src)
	@$(call echo_cmd,,$(INFO_CONFIG) $(notdir $(bison_bld)))
	@(source $(MK)/env2.sh ; $(MK_ENV2);\
	cd $(bison_bld) &&\
	./configure --prefix=$(TOOLS) \
	--build=$(HOST) \
	--host=$(TARGET) && \
	$(MAKE) && make install && \
	$(call TOUCH_DEST))


$(eval $(call prepare_source,bzip2,$(BZIP2_VER),tar.gz))
bzip2_dest := $(TOOLS)/.bld/bzip2
bzip2_bld := $(bzip2_src_dir)
$(bzip2_dest): $(bzip2_src)
	@$(call echo_cmd,,$(INFO_CONFIG) $(notdir $(bzip2_bld)))
	(source $(MK)/env2.sh ; $(MK_ENV2) ; \
	cd $(bzip2_bld) && \
	cp -v Makefile{,.orig} && \
	sed -e 's@^\(all:.*\) test@\1@g' Makefile.orig > Makefile && \
	$(MAKE) CC="$${CC}" AR="$${AR}" RANLIB="$${RANLIB}" && \
	make PREFIX=$(TOOLS) install && \
	$(call TOUCH_DEST))

$(eval $(call prepare_source,coreutils,$(COREUTILS_VER),tar.gz))
$(eval $(call patch_source,COREUTILS_PATCHES,coreutils,$(COREUTILS_VER)))
coreutils_dest := $(TOOLS)/.bld/coreutils
coreutils_bld := $(coreutils_src_dir)
$(coreutils_dest): $(coreutils_src) $(coreutils_patched)
	@$(call echo_cmd,,$(INFO_BUILD) $(notdir $(coreutils_bld)))
	(source $(MK)/env2.sh ; $(MK_ENV2) ;\
		cd $(coreutils_bld) && \
		touch man/uname.1 man/hostname.1 && \
		echo "fu_cv_sys_stat_statfs2_bsize=yes" > config.cache && \
		echo "gl_cv_func_working_mkstemp=yes" >> config.cache && \
		./configure --prefix=$(TOOLS) \
    	--build=$(HOST) --host=$(TARGET) \
    	--enable-install-program=hostname --cache-file=config.cache && \
    	$(MAKE) && make install && $(call TOUCH_DEST))


$(eval $(call prepare_source,diffutils,$(DIFFUTILS_VER),tar.gz))
diffutils_dest := $(TOOLS)/.bld/diffutils
diffutils_bld := $(diffutils_src_dir)
$(diffutils_dest): $(diffutils_src)
	@$(call echo_cmd,,$(INFO_BUILD) $(notdir $(diffutils_bld)))
	(source $(MK)/env2.sh ; $(MK_ENV2) ;\
		cd $(diffutils_bld) && \
		./configure --prefix=$(TOOLS) \
    	--build=$(HOST) --host=$(TARGET) && \
    	$(MAKE) && make install && $(call TOUCH_DEST))

$(eval $(call prepare_source,findutils,$(FINDUTILS_VER),tar.gz))
findutils_dest := $(TOOLS)/.bld/findutils
findutils_bld := $(findutils_src_dir)
$(findutils_dest): $(findutils_src)
	@$(call echo_cmd,,$(INFO_BUILD) $(notdir $(findutils_bld)))
	(source $(MK)/env2.sh ; $(MK_ENV2) ;\
		cd $(findutils_bld) && \
		echo "gl_cv_func_wcwidth_works=yes" > config.cache && \
		echo "ac_cv_func_fnmatch_gnu=yes" >> config.cache &&\
		./configure --prefix=$(TOOLS) \
    	--build=$(HOST) --host=$(TARGET) --cache-file=config.cache && \
    	$(MAKE) && make install && $(call TOUCH_DEST))

$(eval $(call prepare_source,file,$(FILE_VER),tar.gz))
file_dest := $(TOOLS)/.bld/file
file_bld := $(file_src_dir)
$(file_dest): $(file_src)
	@$(call echo_cmd,,$(INFO_BUILD) $(notdir $(file_bld)))
	(source $(MK)/env2.sh ; $(MK_ENV2) ;\
		cd $(file_bld) && \
		./configure --prefix=$(TOOLS) \
    	--build=$(HOST) --host=$(TARGET) && \
    	$(MAKE) && make install && $(call TOUCH_DEST))

$(eval $(call prepare_source,flex,$(FLEX_VER),tar.bz2))
$(eval $(call patch_source,FLEX_PATCHES,flex,$(FLEX_VER)))
flex_dest := $(TOOLS)/.bld/flex
flex_bld := $(flex_src_dir)
$(flex_dest): $(flex_src) $(flex_patched)
	@$(call echo_cmd,,$(INFO_BUILD) $(notdir $(flex_bld)))
	(source $(MK)/env2.sh ; $(MK_ENV2) ;\
		cd $(flex_bld) && \
		echo "ac_cv_func_malloc_0_nonnull=yes" > config.cache && \
		echo "ac_cv_func_realloc_0_nonnull=yes" >> config.cache &&\
		./configure --prefix=$(TOOLS) \
    	--build=$(HOST) --host=$(TARGET) \
    	--cache-file=config.cache && \
    	$(MAKE) && make install && $(call TOUCH_DEST))


$(eval $(call prepare_source,gawk,$(GAWK_VER),tar.bz2))
gawk_dest := $(TOOLS)/.bld/gawk
gawk_bld := $(gawk_src_dir)
$(gawk_dest): $(gawk_src)
	@$(call echo_cmd,,$(INFO_BUILD) $(notdir $(gawk_bld)))
	(source $(MK)/env2.sh ; $(MK_ENV2) ;\
		cd $(gawk_bld) && \
		./configure --prefix=$(TOOLS) \
    	--build=$(HOST) --host=$(TARGET) && \
    	$(MAKE) && make install && $(call TOUCH_DEST))

$(eval $(call prepare_source,gettext,$(GETTEXT_VER),tar.gz))
gettext_dest := $(TOOLS)/.bld/gettext
gettext_bld := $(gettext_src_dir)
$(gettext_dest): $(gettext_src)
	@$(call echo_cmd,,$(INFO_BUILD) $(notdir $(gettext_bld)))
	(source $(MK)/env2.sh ; $(MK_ENV2) ;\
		cd $(gettext_bld) && \
		echo "gl_cv_func_wcwidth_works=yes" > config.cache &&\
		./configure --prefix=$(TOOLS) \
    	--build=$(HOST) --host=$(TARGET)  \
    	--disable-shared --cache-file=config.cache && \
    	$(MAKE) && $(MAKE) check && $(MAKE) install && \
    	install -dv src/msgfmt $(TOOLS)/bin && \
    	$(call TOUCH_DEST))

$(eval $(call prepare_source,grep,$(GREP_VER),tar.gz))
grep_dest := $(TOOLS)/.bld/grep
grep_bld := $(grep_src_dir)
$(grep_dest): $(grep_src)
	@$(call echo_cmd,,$(INFO_BUILD) $(notdir $(grep_bld)))
	(source $(MK)/env2.sh ; $(MK_ENV2) ;\
		cd $(grep_bld) && \
		echo "ac_cv_func_malloc_0_nonnull=yes" > config.cache && \
		echo "ac_cv_func_realloc_0_nonnull=yes" >> config.cache && \
		./configure --prefix=$(TOOLS) \
    	--build=$(HOST) --host=$(TARGET)  \
    	--disable-perl-regexp \
    	--without-included-regex \
    	--cache-file=config.cache && \
    	$(MAKE) && make install && $(call TOUCH_DEST))

$(eval $(call prepare_source,gzip,$(GZIP_VER),tar.bz2))
gzip_dest := $(TOOLS)/.bld/gzip
gzip_bld := $(gzip_src_dir)
$(gzip_dest): $(gzip_src)
	@$(call echo_cmd,,$(INFO_BUILD) $(notdir $(gzip_bld)))
	(source $(MK)/env2.sh ; $(MK_ENV2) ;\
		cd $(gzip_bld) && \
		./configure --prefix=$(TOOLS) \
    	--build=$(HOST) --host=$(TARGET) && \
    	$(MAKE) && make install && $(call TOUCH_DEST))

$(eval $(call prepare_source,m4,$(M4_VER),tar.bz2))
m4_dest := $(TOOLS)/.bld/m4
m4_bld := $(m4_src_dir)
$(m4_dest): $(m4_src)
	@$(call echo_cmd,,$(INFO_BUILD) $(notdir $(m4_bld)))
	(source $(MK)/env2.sh ; $(MK_ENV2) ;\
		cd $(m4_bld) && \
		echo "gl_cv_func_btowc_eof=yes" > config.cache && \
		echo "gl_cv_func_mbrtowc_incomplete_state=yes" >> config.cache && \
		echo "gl_cv_func_mbrtowc_sanitycheck=yes" >> config.cache && \
		echo "gl_cv_func_mbrtowc_null_arg=yes" >> config.cache && \
		echo "gl_cv_func_mbrtowc_retval=yes" >> config.cache && \
		echo "gl_cv_func_mbrtowc_nul_retval=yes" >> config.cache && \
		echo "gl_cv_func_wcrtomb_retval=yes" >> config.cache && \
		echo "gl_cv_func_wctob_works=yes" >> config.cache && \
		./configure --prefix=$(TOOLS) \
    	--build=$(HOST) --host=$(TARGET) \
    	--cache-file=config.cache && \
    	$(MAKE) && make install && $(call TOUCH_DEST))

$(eval $(call prepare_source,make,$(MAKE_VER),tar.bz2))
make_dest := $(TOOLS)/.bld/make
make_bld := $(make_src_dir)
$(make_dest): $(make_src)
	@$(call echo_cmd,,$(INFO_BUILD) $(notdir $(make_bld)))
	(source $(MK)/env2.sh ; $(MK_ENV2) ;\
		cd $(make_bld) && \
		./configure --prefix=$(TOOLS) \
    	--build=$(HOST) --host=$(TARGET) && \
    	$(MAKE) && make install && $(call TOUCH_DEST))

$(eval $(call prepare_source,patch,$(PATCH_VER),tar.bz2))
patch_dest := $(TOOLS)/.bld/patch
patch_bld := $(patch_src_dir)
$(patch_dest): $(patch_src)
	@$(call echo_cmd,,$(INFO_BUILD) $(notdir $(patch_bld)))
	(source $(MK)/env2.sh ; $(MK_ENV2) ;\
		cd $(patch_bld) && \
		echo "ac_cv_func_strnlen_working=yes" > config.cache && \
		./configure --prefix=$(TOOLS) \
    	--build=$(HOST) --host=$(TARGET) \
    	--cache-file=config.cache && \
    	$(MAKE) && make install && $(call TOUCH_DEST))

$(eval $(call prepare_source,sed,$(SED_VER),tar.bz2))
sed_dest := $(TOOLS)/.bld/sed
sed_bld := $(sed_src_dir)
$(sed_dest): $(sed_src)
	@$(call echo_cmd,,$(INFO_BUILD) $(notdir $(sed_bld)))
	(source $(MK)/env2.sh ; $(MK_ENV2) ;\
		cd $(sed_bld) && \
		./configure --prefix=$(TOOLS) \
    	--build=$(HOST) --host=$(TARGET) && \
    	$(MAKE) && make install && $(call TOUCH_DEST))

$(eval $(call prepare_source,tar,$(TAR_VER),tar.bz2))
tar_dest := $(TOOLS)/.bld/tar
tar_bld := $(tar_src_dir)
$(tar_dest): $(tar_src)
	@$(call echo_cmd,,$(INFO_BUILD) $(notdir $(tar_bld)))
	(source $(MK)/env2.sh ; $(MK_ENV2) ;\
		cd $(tar_bld) && \
		echo "gl_cv_func_wcwidth_works=yes" > config.cache && \
		echo "gl_cv_func_btowc_eof=yes" >> config.cache && \
		echo "ac_cv_func_malloc_0_nonnull=yes" >> config.cache && \
		echo "ac_cv_func_realloc_0_nonnull=yes" >> config.cache && \
		echo "gl_cv_func_mbrtowc_incomplete_state=yes" >> config.cache && \
		echo "gl_cv_func_mbrtowc_nul_retval=yes" >> config.cache && \
		echo "gl_cv_func_mbrtowc_null_arg=yes" >> config.cache && \
		echo "gl_cv_func_mbrtowc_retval=yes" >> config.cache && \
		echo "gl_cv_func_wcrtomb_retval=yes" >> config.cache && \
		./configure --prefix=$(TOOLS) \
    	--build=$(HOST) --host=$(TARGET) \
    	--cache-file=config.cache &&\
    	$(MAKE) && make install && $(call TOUCH_DEST))

$(eval $(call prepare_source,texinfo,$(TEXINFO_VER),tar.gz))
texinfo_dest := $(TOOLS)/.bld/texinfo
texinfo_bld := $(texinfo_src_dir)
$(texinfo_dest): $(texinfo_src)
	@$(call echo_cmd,,$(INFO_BUILD) $(notdir $(texinfo_bld)))
	(source $(MK)/env2.sh ; $(MK_ENV2) ;\
		cd $(texinfo_bld) && \
		./configure --prefix=$(TOOLS) \
    	--build=$(HOST) --host=$(TARGET) && \
    	$(MAKE) -C gnulib/lib  && \
    	$(MAKE) && make install && $(call TOUCH_DEST))

$(eval $(call prepare_source,vim,$(VIM_VER),tar.bz2))
$(eval $(call patch_source,VIM_PATCHES,vim,$(VIM_VER)))
vim_dest := $(TOOLS)/.bld/vim
vim_bld := $(vim_src_dir)
$(vim_dest): $(vim_src)
	@$(call echo_cmd,,$(INFO_BUILD) $(notdir $(vim_bld)))
	(source $(MK)/env2.sh ; $(MK_ENV2) ;\
		cd $(vim_bld) && \
		echo "vim_cv_getcwd_broken=no" > config.cache && \
		echo "vim_cv_memmove_handles_overlap=yes" >> config.cache && \
		echo "vim_cv_stat_ignores_slash=no" >> config.cache && \
		echo "vim_cv_terminfo=yes" >> config.cache && \
		echo "vim_cv_tgent=zero" >> config.cache && \
		echo "vim_cv_toupper_broken=no" >> conig.cache && \
		echo "vim_cv_tty_group=world" >> config.cache && \
		echo "ac_cv_sizeof_int=4" >> config.cache && \
		echo "ac_cv_sizeof_long=4" >> config.cache && \
		echo "ac_cv_sizeof_time_t=4" >> config.cache && \
		echo "ac_cv_sizeof_off_t=4" >> config.cache && \
		echo '#define SYS_VIMRC_FILE "$(TOOLS)/etc/vimrc"' >> src/feature.h && \
		./configure \
    		--build=$(HOST) --host=$(TARGET) \
    		--prefix=$(TOOLS) \
    		--enable-multibyte \
    		--enable-gui=no \
		    --disable-gtktest \
		    --disable-xim \
		    --with-features=normal \
		    --disable-gpm \
		    --without-x \
		    --disable-netbeans \
		    --with-tlib=ncurses && \
    	$(MAKE) && make install && \
    	$(call TOUCH_DEST))

$(eval $(call prepare_source,xz,$(XZ_VER),tar.bz2))
xz_dest := $(TOOLS)/.bld/xz
xz_bld := $(xz_src_dir)
$(xz_dest): $(xz_src)
	@$(call echo_cmd,,$(INFO_BUILD) $(notdir $(xz_bld)))
	(source $(MK)/env2.sh ; $(MK_ENV2) ;\
		cd $(xz_bld) && \
		./configure --prefix=$(TOOLS) \
    	--build=$(HOST) --host=$(TARGET) && \
    	$(MAKE) && make install && $(call TOUCH_DEST))

$(eval $(call prepare_source,util-linux,$(UTIL-LINUX_VER),tar.bz2))
util-linux_dest := $(TOOLS)/.bld/UTIL-LINUX
util-linux_bld := $(util-linux_src_dir)
$(util-linux_dest): $(util-linux_src)
	@$(call echo_cmd,,$(INFO_BUILD) $(notdir $(util-linux_bld)))
	(source $(MK)/env2.sh ; $(MK_ENV2) ;\
		cd $(util-linux_bld) && \
		./configure --prefix=$(TOOLS) \
    	--build=$(HOST) --host=$(TARGET)  \
    	--disable-makeinstall-chown && \
    	$(MAKE) && make install && $(call TOUCH_DEST))


$(eval $(call prepare_source,e2fsprogs,$(E2FSPROG_VER),tar.gz))
e2fsprogs_dest := $(TOOLS)/.bld/e2fsprogs
e2fsprogs_bld := $(e2fsprogs_src_dir)
$(e2fsprogs_dest): $(e2fsprogs_src)
	@$(call echo_cmd,,$(INFO_BUILD) $(notdir $(e2fsprogs_bld)))
	(source $(MK)/env2.sh ; $(MK_ENV2) ;\
		cd $(e2fsprogs_bld) && \
		PKG_CONFIG=true ./configure --prefix=$(TOOLS) \
    	--build=$(HOST) --host=$(TARGET)  \
    	--enable-elf-shlibs --disable-libblkid \
    	--disable-libuuid --disable-fsck \
    	--disable-uuid && \
    	$(MAKE) LIBUUID="-luuid" STATIC_LIBUUID="-luuid" \
    		LIBBLKID="-lblkid" STATIC_LIBBLKID="-lblkid" && \
    	make install && make install-libs && \
    	mkdir -p $(BASE)/sbin &&\
    	ln -sv $(TOOLS)/sbin/{fsck,ext2,fsck.ext3,fsck.ext4,e2fsck} $(BASE)/sbin && \
     $(TOUCH_DEST))


build_stage2: build_stage1 $(gcc3_dest)  $(zlib_dest) $(ncurses_dest) $(bash_dest) \
		$(bison_dest) $(bzip2_dest) $(coreutils_dest) $(diffutils_dest) \
		$(findutils_dest) $(file_dest) $(flex_dest) $(gawk_dest) $(gettext_dest) \
		$(grep_dest) $(m4_dest) $(make_dest) $(patch_dest) $(gzip_dest) $(tar_dest) $(sed_dest) \
		$(texinfo_dest) $(vim_dest) $(xz_dest) $(util-linux_dest) $(e2fsprogs_dest) 



######################################################
# prepare chroot
$(BASE)/.prep_fs: 
	@$(call echo_cmd,,I: Prepare basic fs ...,,)
	(mkdir -pv $(BASE)/{dev,proc,sys} && \
		([ -f $(BASE)/dev/console ] && mknod -m 600 $(BASE)/dev/console c 5 1 ; true) && \
		([ -f $(BASE)/dev/null ] && mknod -m 666 $(BASE)/dev/null c 1 3 ; true) && \
		mkdir -p $(BASE)/dev/shm && \
		$(call try_mount,/proc,-vt proc,$(BASE)/proc) && \
		$(call try_mount,/sys,-vt sysfs,$(BASE)/sys) && \
		$(call try_mount,/dev,-v -o bind,$(BASE)/dev) && \
		$(call try_mount,tmpfs,-F -vt tmpfs,$(BASE)/dev/shm) && \
		$(call try_mount,devpts,-vt devpts -o gid=4$(comma)mode=620,$(BASE)/dev/pts))
		$(call try_mount,$(CURDIR),-o bind,$(NEWBASE))
	@([ ! -f $(BASE)/bin/sh ] && sudo $(MK)/prep_dirs $(BASE) ; true)
	#@(r=`stat -c %u $(TOOLS)/bin` && ([ $$r -ne 0 ] && sudo chown -Rv 0:0 $(TOOLS)/ ; true))
	#@(r=`stat -c %u $(CROSS_TOOLS)/bin` && ([ $$r -ne 0 ] && sudo chown -Rv 0:0 $(CROSS_TOOLS)/ ; true))
	#@(r=`stat -c %u $(BASE)/bin` && ([ $$r -ne 0 ] && sudo chown -Rv 0:0 $(BASE)/{bin,sbin,boot,etc,opt,root,home,srv,usr,var,lib,media,mnt,tmp}; true))
	@($(TOUCH_DEST))



build: build_stage2 $(BASE)/.prep_fs 

chroot_build: build_stage2 $(BASE)/.prep_fs 
	@$(call echo_cmd,,======== GO INTO CHROOT BUILD ========)
	($(call chroot-run,cd $${BASE}; make -f ./Makefile.chroot))

go_chroot:
	$(go-chroot)

umount:
	-sudo umount -f $(BASE)/{proc,sys,dev/shm,dev/pts,dev}
	-sudo umount -f $(NEWBASE)
	-rm $(BASE)/.prep_fs
