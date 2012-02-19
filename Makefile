
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

download_pkgs : htmls $(foreach f,$(download_list),$($f))

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
$(gmp_dest): $(prep) $(gmp_src) 
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

#############################################
# basic system install

# gmp
gmp2_dest := $(TOOLS)/.bld/gmp
gmp2_bld  := $(BLD)/gmp-$(GMP_VER)
$(gmp2_dest): $(gcc2_dest)
	@$(call echo_cmd,,$(INFO_CONFIG $(notdir $(notdir $(gmp2_dest)))))
	(rm -fr $(gmp2_bld) && mkdir -p $(gmp2_bld) && \
	(source $(MK)/env2.sh ; $(call MK_ENV2);\
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
	(source $(MK)/env2.sh ; $(call MK_ENV2);\
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
	(source $(MK)/env2.sh ; $(call MK_ENV2);\
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
	(source $(MK)/env2.sh ; $(call MK_ENV2);\
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
	(source $(MK)/env2.sh ; $(call MK_ENV2);\
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
	(source $(MK)/env2.sh ; $(call MK_ENV2);\
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

gcc3_dest := $(TOOLS)/.bld/gcc
gcc3_bld := $(BLD)/gcc-$(GCC_VER)
$(gcc3_dest): $(binutils2_dest)
	@$(call echo_cmd,,$(INFO_CONFIG $(notdir $(notdir $(gcc3_dest)))))
	(rm -fr $(gcc3_bld) && mkdir -p $(gcc3_bld) && \
	(source $(MK)/env2.sh ; $(call MK_ENV2);\
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

build: $(gcc3_dest)


