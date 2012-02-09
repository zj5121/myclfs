include config.mk
include rules.mk

curdir := $(shell pwd)

.PHONY: prep all

all: build

include packages.mk


# gmp lib
$(eval $(call prepare_source,gmp,$(GMP_VER),tar.bz2))
gmp_dest := $(TOOLCHAIN_HOST)/lib/libgmpxx.so
gmp_bld  := $(BLD)/gmp-$(GMP_VER)
$(gmp_dest): $(gmp_src) 
	(rm -fr $(gmp_bld) && mkdir -p $(gmp_bld) && \
	source $(curdir)/env.sh && \
	cd $(gmp_bld) && \
	CPPFLAGS="-fexceptions" $(gmp_src_dir)/configure \
	--prefix=$(TOOLCHAIN_HOST) \
	--enable-shared \
	--enable-cxx && \
	$(MAKE) && $(MAKE) install && $(MAKE) check \
	)

# mpfr lib
$(eval $(call prepare_source,mpfr,$(MPFR_VER),tar.bz2))
$(eval $(call patch_source,MPFR_PATCHES,mpfr,3.1.0))
mpfr_dest := $(TOOLCHAIN_HOST)/lib/libmpfr.a
mpfr_bld  := $(BLD)/mpfr-$(MPFR_VER)
$(mpfr_dest): $(mpfr_patched) $(gmp_dest)
	@(rm -fr $(mpfr_bld) && mkdir -p $(mpfr_bld) &&\
	source $(curdir)/env.sh && \
	cd $(mpfr_bld) && \
	CPPFLAGS="-I$(TOOLCHAIN_HOST)/include" \
	CFLAGS="-I$(TOOLCHAIN_HOST)/include" \
	LDFLAGS="-Wl,-rpath=$(TOOLCHAIN_HOST)/lib" \
	$(mpfr_src_dir)/configure --prefix=$(TOOLCHAIN_HOST) \
	--disable-shared \
	--with-gmp=$(TOOLCHAIN_HOST) &&\
	$(MAKE) && $(MAKE) install && $(MAKE) check)

# mpc lib
$(eval $(call prepare_source,mpc,$(MPC_VER),tar.gz))
mpc_dest := $(TOOLCHAIN_HOST)/lib/libmpc.a
mpc_bld := $(BLD)/mpc-$(MPC_VER)
$(mpc_dest): $(mpc_src) $(mpfr_dest) $(gmp_dest)
	@($(call echo_cmd,,$(INFO_CONFIG) $(notdir $(notdir $(mpc_bld)))))
	@(rm -fr $(mpc_bld) && mkdir -p $(mpc_bld) &&\
	source $(curdir)/env.sh && \
	cd $(mpc_bld) &&\
	CPPFLAGS="-I$(TOOLCHAIN_HOST)/include" \
	LDFLAGS="-Wl,-rpath=$(TOOLCHAIN_HOST)/lib" \
	$(mpc_src_dir)/configure --prefix=$(TOOLCHAIN_HOST) \
	--target=$(TARGET) \
	--disable-shared \
	--with-gmp=$(TOOLCHAIN_HOST) \
	--with-mpfr=$(TOOLCHAIN_HOST) &&\
	$(MAKE) && $(MAKE) install && $(MAKE) check)


$(eval $(call prepare_source,ppl,$(PPL_VER),tar.bz2))
ppl_dest := $(TOOLCHAIN_HOST)/lib/libppl.so
ppl_bld := $(BLD)/ppl-$(PPL_VER)
$(ppl_dest): $(ppl_src) $(mpc_dest)
	$(call echo_cmd,,$(INFO_CONFIG) $(notdir $(ppl_bld)))
	@(rm -fr $(ppl_bld) && mkdir -p $(ppl_bld) &&\
	source $(curdir)/env.sh && \
	cd $(ppl_bld) && \
	CFLAGS="-I$(TOOLCHAIN_HOST)/include" CPPFLAGS="-I$(TOOLCHAIN_HOST)/include" \
	LDFLAGS="-Wl,-rpath=$(TOOLCHAIN_HOST)/lib" \
	$(ppl_src_dir)/configure --prefix=$(TOOLCHAIN_HOST) \
	--build=$(BUILD) \
	--target=$(TARGET) \
	--enable-interfaces="c,cxx" \
	--disable-watchdog \
	--with-libgmp-prefix=$(TOOLCHAIN_HOST) \
	--with-libgmpxx-prefix=$(TOOLCHAIN_HOST) && \
	$(MAKE) && $(MAKE) install)



$(eval $(call prepare_source,cloog-ppl,$(CLOOG_VER),tar.gz))
cloog_dest := $(TOOLCHAIN_HOST)/lib/libcloog.so
cloog_bld := $(BLD)/cloog-ppl-$(CLOOG_VER)
$(cloog_dest): $(cloog-ppl_src) $(gmp_dest) $(ppl_dest)
	$(call echo_cmd,,$(INFO_CONFIG) $(notdir $(notdir $(cloog_bld))))
	(rm -fr $(cloog_bld) && mkdir -p $(cloog_bld) &&\
	source $(curdir)/env.sh && \
	cd $(cloog-ppl_src_dir) && \
	cp -v configure{,.orig} && \
	sed -e "/LD_LIBRARY_PATH=/d" configure.orig > configure && \
	cd $(cloog_bld) && LDFLAGS="-Wl,-rpath=$(TOOLCHAIN_HOST)/lib" \
	$(cloog-ppl_src_dir)/configure --prefix=$(TOOLCHAIN_HOST) \
	--build=$(BUILD) \
	--target=$(TARGET) \
	--enable-shared \
	--disable-nls \
	--with-bits=gmp \
	--with-gmp=$(TOOLCHAIN_HOST) \
	--with-ppl=$(TOOLCHAIN_HOST) && \
	$(MAKE) && $(MAKE) install && $(MAKE) check)

# libelf
$(eval $(call prepare_source,libelf,$(LIBELF_VER),tar.gz))
libelf_dest := $(TOOLCHAIN_HOST)/lib/libelf.a
libelf_bld := $(BLD)/libelf-$(LIBELF_VER)
$(libelf_dest): $(libelf_src)
	@($(call echo_cmd,,$(INFO_CONFIG) $(notdir $(notdir $(cloog_bld)))))
	@(rm -fr $(libelf_bld) && mkdir -p $(libelf_bld) && \
	source $(curdir)/env.sh && $(call MK_ENV1) \
	cd $(libelf_bld) && \
	$(libelf_src_dir)/configure --prefix=$(TOOLCHAIN_HOST) \
	--build=$(BUILD) \
	--target=$(TARGET) \
	--host=$(BUILD) \
	--disable-nls \
	--disable-shared && \
	$(MAKE) && $(MAKE) install)

	
# bintuils pass1
$(eval $(call prepare_source,binutils,2.22,tar.bz2))
binutils_dest := $(TOOLCHAIN_INSTALL)/bin/$(TARGET)-ar
binutils_bld := $(BLD)/binutils-$(BINUTILS_VER)
$(binutils_dest): $(binutils_src) $(cloog_dest) $(libelf_dset)
	$(call echo_cmd,,$(INFO_CONFIG) $(notdir $(binutils_bld)))
	(rm -fr $(binutils_bld) && mkdir -p $(binutils_bld) && \
	source $(curdir)/env.sh ; $(call MK_ENV1) ;\
	cd $(binutils_bld) && \
	$(call copy_dir_clean,$(binutils_src_dir),$(binutils_bld)) && \
	$(binutils_bld)/configure \
	--prefix=$(PREFIX)  \
	--build=$(BUILD)  \
	--host=$(BUILD) \
	--target=$(TARGET) \
	--with-sysroot=$(SYSROOT) \
	--enable-poison-system-directories \
	--disable-nls --enable-shared \
	--disable-multilib && \
	$(MAKE) all-libiberty && \
	$(call copy_dir_clean,$(binutils_src_dir)/include,$(binutils_bld)/usr/include) && \
	mkdir -p $(binutils_bld)/usr/lib && \
	cp -f $(binutils_bld)/libiberty/libiberty.a $(binutils_bld)/usr/lib &&\
	CPPFLAGS=-I$(binutils_bld)/usr/include LDFLAGS=-L$(binutils_bld)/usr/lib \
	$(MAKE) && \
	CPPFLAGS=-I$(binutils_bld)/usr/include LDFLAGS=-L$(binutils_bld)/usr/lib \
	$(MAKE) install prefix=$(TOOLCHAIN_INSTALL) exec_prefix=$(TOOLCHAIN_INSTALL) libdir=$(TOOLCHAIN_INSTALL)/lib datadir=$(TOOLCHAIN_INSTALL)/share&& \
	rm -fr $(TOOLCHAIN_INSTALL)/lib* && \
	CPPFLAGS=-I$(binutils_bld)/usr/include LDFLAGS=-L$(binutils_bld)/usr/lib \
	$(MAKE) install prefix=$(TOOLCHAIN_INSTALL) exec_prefix=$(TOOLCHAIN_INSTALL) libdir=$(TOOLCHAIN_INSTALL)/lib datadir=$(TOOLCHAIN_INSTALL)/share&& \
	CPPFLAGS=-I$(binutils_bld)/usr/include LDFLAGS=-L$(binutils_bld)/usr/lib \
	$(MAKE) install prefix=$(TOOLCHAIN_INSTALL) exec_prefix=$(TOOLCHAIN_INSTALL) libdir=$(TOOLCHAIN_INSTALL)/lib datadir=$(TOOLCHAIN_INSTALL)/share&& \
	cp $(binutils_bld)/bfd/.libs/libbfd.a $(binutils_bld)/usr/lib && \
	cp $(binutils_bld)/bfd/bfd.h $(binutils_bld)/usr/include &&\
	cp $(binutils_bld)/bfd/elf-bfd.h $(binutils_bld)/usr/include && \
	cp $(binutils_bld)/opcodes/.libs/libopcodes.a $(binutils_bld)/usr/lib &&\
	rm -fr $(TOOLCHAIN_INSTALL)/share/doc && \
	rm -f $(TOOLCHAIN_INSTALL)/bin/$(TARGET)-ld.bfd && \
	rm -f $(TOOLCHAIN_INSTALL)/bin/ld.bfd &&\
	rm -f $(TOOLCHAIN_INSTALL)/$(TARGET)/bin/ld.bfd \
	)

# install kernel headers for glibc
$(eval $(call prepare_source,linux,$(LINUX_VER),tar.bz2))
linux_dest := $(SYSROOT)/usr/include/.linux_hdr
linux_dest_dir := $(dir $(linux_dest))
linux_bld := $(BLD)/linux-$(LINUX_VER)
$(linux_dest): $(linux_src) 
	@install -dv $(dir $(linux_dest_dir))
	(mkdir -p $(TOOLCHAIN_INSTALL_SYSROOT)/usr/include $(TOOLCHAIN_INSTALL_SYSROOT)/usr/include/bits $(TOOLCHAIN_INSTALL_SYSROOT)/usr/include/gnu &&\
	rm -rf $(linux_bld) &&\
	$(call copy_dir_clean,$(linux_src_dir),$(linux_bld)) &&\
	source $(curdir)/env.sh ; $(call MK_ENV1) ;\
	cd $(linux_bld) &&\
	make ARCH=$(TARGET_ARCH) CROSS_COMPILE=$(TOOLCHAIN_INSTALL)/bin/$(TARGET)- INSTALL_HDR_PATH=dest headers_install &&\
	cp -rv dest/include/* $(TOOLCHAIN_INSTALL_SYSROOT)/usr/include/ && touch $@; \
	mkdir -p $(SYSROOT)/{atom,core2}
	)

# install glibc header
$(eval $(call prepare_source,glibc,2.14.1,tar.xz))
glibc_hdr_dest := $(SYSROOT)/usr/include/.glibc_hdr
glibc_hdr_bld := $(BLD)/glibc-$(GLIBC_VER)
$(glibc_hdr_dest) : $(glibc_src)
	(rm -fr $(glibc_hdr_bld) && mkdir -p $(glibc_hdr_bld) && \
	cd $(glibc_hdr_bld) && \
	$(glibc_src_dir)/configure \
		--host=$(TARGET) \
		--prefix=/opt/x-tools \
		--with-headers=$(SYSROOT)/usr/include \
		--disable-sanity-checks && \
		$(MAKE) -k install-headers install_root=$(SYSROOT) && \
		mkdir -p $(SYSROOT)/usr/include/gnu && \
		touch $(SYSROOT)/usr/include/gnu/stubs.h && \
		cp -f bits/stdio_lim.h $(SYSROOT)/usr/include/bits/ && \
		ln -s usr/include $(SYSROOT)/sys-include)

# gcc-4.6 pass1
$(eval $(call prepare_source,gcc,$(GCC_VER),tar.bz2,core))
$(eval $(call prepare_source,gcc,$(GCC_VER),tar.bz2,g++))
$(call patch_source,GCC_PATCHES,gcc,$(GCC_VER))
gcc1_dest := $(TOOLCHAIN_INSTALL)/bin/$(TARGET)-gcc
gcc1_bld := $(BLD)/gcc-$(GCC_VER)
$(gcc1_dest) : $(gcc_src) $(gcc_patched) $(binutils_dest)
	$(call echo_cmd,,$(INFO_CONFIG) $(notdir $(notdir $(gcc1_dest))))
	(source $(curdir)/env.sh ; $(call MK_ENV1) ; $(call MK_ENV2); \
	rm -rf $(gcc1_bld) && \
	mkdir -p $(gcc1_bld) && cd $(gcc1_bld) && \
	$(gcc_src_dir)/configure \
	--target=i686-pc-linux-gnu \
	--build=$(BUILD) \
	--host=$(BUILD) \
	--enable-threads \
	--disable-libmudflap \
	--disable-libssp \
	--disable-libstdcxx-pch \
	--enable-targets=all \
	--disable-multilib \
	--with-arch-32=pentium4 \
	--with-cpu=generic \
	--with-gnu-as \
	--with-gnu-ld \
	--enable-languages=c,c++ \
	--disable-shared\
	--enable-lto \
	--enable-symvers=gnu \
	--enable-__cxa_atexit \
	'--with-pkgversion=Sourcery CodeBench Lite 2011.09-24' \
	--disable-nls \
	--prefix=$(PREFIX) \
	--disable-shared \
	--disable-threads \
	--disable-libssp \
	--disable-libgomp \
	--without-headers \
	--with-newlib \
	--disable-decimal-float \
	--disable-libffi \
	--disable-libquadmath \
	--enable-languages=c \
	--with-sysroot=$(SYSROOT) \
	--with-build-sysroot=$(TOOLCHAIN_INSTALL_SYSROOT) \
	--with-gmp=$(TOOLCHAIN_HOST) \
	--with-mpc=$(TOOLCHAIN_HOST) \
	--with-mpfr=$(TOOLCHAIN_HOST) \
	--with-ppl=$(TOOLCHAIN_HOST) \
	--with-cloog=$(TOOLCHAIN_HOST) \
	--with-libelf=$(TOOLCHAIN_HOST) \
	--disable-libgomp \
	--enable-poison-system-directories \
	--with-build-time-tools=$(TOOLCHAIN_INSTALL)/bin  && \
	$(MAKE) LDFLAGS_FOR_TARGET=--sysroot=$(TOOLCHAIN_INSTALL_SYSROOT) \
			LDFLAGS_FOR_BUILD=-Wl,-rpath=$(TOOLCHAIN_HOST) \
			CPPFLAGS_FOR_TARGET=--sysroot=$(TOOLCHAIN_INSTALL_SYSROOT) \
			build_tooldir=$(TOOLCHAIN_INSTALL)/$(TARGET) )
#--with-arch-64=nocona \
#'--with-host-libstdcxx=-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm' 
build: $(gcc1_dest)

prep_patch: prep_src
	@(if [ ! -e $(SRC)/.src_patched ] ; then \
		echo "I: Patch sources ..." ; \
		for f in $(PATCH_DIR)/*.*; do \
			d=$$(basename $${f%%--*});\
			cd $(SRC)/$$d; \
			(patch -i $$f -p1 2>&1) && echo "I:  patched $$d" && cd ..;\
		done && \
		touch $(SRC)/.src_patched;\
	fi)

kernel_prep: prep_patch
	@(mkdir -p $(CLFS)/usr/include)
	rm -f $(SRC)/linux && ln -s $(SRC)/linux-$(LINUX_VER) $(SRC)/linux
	(if [ ! -e $(CLFS)/.kernel_prep ] ; then\
		cd $(SRC)/linux	&&\
		make mrproper && \
		make ARCH=$(TARGET_ARCH) headers_check && \
		make ARCH=$(TARGET_ARCH) INSTALL_HDR_PATH=dest headers_install && \
		cp -rv dest/include/* $(CLFS)/usr/include &&\
		touch $(CLFS)/.kernel_prep ;\
	fi)

bld_binutil1: kernel_prep 
	@(mkdir -p $(bld_binutils_dir))
	@(if [ ! -e $(BLD)/.build_binutils_1 ] ; then \
		cd $(bld_binutils_dir); \
		$(ROOT)/src/binutils-$(BINUTILS_VER)/configure --target=$(TARGET) --prefix=$(CLFS_TEMP) \
		--disable-nls --with-sysroot=$(CLFS) --enable-shared --disable-multilib && \
		make all -j$(NR_CPU)&& make install && \
		cp -v $(SRC)/binutils-$(BINUTILS_VER)/include/libiberty.h $(CLFS)/usr/include && \
		touch $(BLD)/.build_binutils_1 && \
		cd $(ROOT);\
	 fi)

bld_gmp: kernel_prep
	@(mkdir -p $(bld_gmp_dir))
	@(if [ ! -e $(BLD)/.build_gmp ]; then \
		cd $(bld_gmp_dir);\
		$(ROOT)/src/gmp-$(GMP_VER)/configure --prefix=$(CLFS_TEMP) && \
		make install && touch $(BLD)/.build_gmp; \
	fi)

bld_mpc: bld_mpfr
	@(mkdir -p $(bld_mpc_dir))
	@(if [ ! -e $(BLD)/.build_mpc ]; then \
		cd $(bld_mpc_dir);\
		$(ROOT)/src/mpc-$(MPC_VER)/configure LD_FLAGS="-Wl,-rpath=$(CLFS_TEMP)/lib" --prefix=$(CLFS_TEMP) \
		--enable-mpfr=$(CLFS_TEMP) --enable-gmp=$(CLFS_TEMP) && \
		make && make install && touch $(BLD)/.build_mpc; \
	fi)

bld_mpfr: bld_gmp
	@(mkdir -p $(bld_mpfr_dir))
	@(if [ ! -e $(BLD)/.build_mpfr ]; then \
		cd $(bld_mpfr_dir);\
		$(ROOT)/src/mpfr-$(MPFR_VER)/configure LD_FLAGS="-Wl,-rpath=$(CLFS_TEMP)/lib" --prefix=$(CLFS_TEMP) \
		--enable-shared --with-gmp=$(CLFS_TEMP) && \
		make && make install && touch $(BLD)/.build_mpfr; \
	fi)

bld_gcc1: bld_binutil1 bld_mpc
	@(mkdir -p $(bld_gcc_dir))
	@(if [ ! -e $(BLD)/.build_gcc_1 ] ; then \
		export PATH=$(PATH);\
		cd $(bld_gcc_dir); \
		$(ROOT)/src/gcc-$(GCC_VER)/configure AR=ar LDFLAGS="-Wl,-rpath=$(CLFS)/tmp/lib" \
		--build=$(HOST) --host=$(HOST) --with-sysroot=$(CLFS) \
		--target=$(TARGET) --prefix=$(CLFS_TEMP) --disable-nls \
		--enable-languages=c --without-headers \
		--disable-shared --disable-multilib \
    	--disable-decimal-float --disable-threads \
    	--disable-libmudflap --disable-libssp \
    	--disable-target-libiberty \
    	--disable-target-zlib \
    	--without-ppl --without-cloog \
    	--with-mpfr=$(CLFS_TEMP) \
    	--with-gmp=$(CLFS_TEMP) \
    	--with-mpc=$(CLFS_TEMP) \
    	--with-arch=$(TARGET_ARCH) && \
		make -j$(NR_CPU) all-gcc && touch $(BLD)/.build_gcc_1 || exit 1;\
		cd $(ROOT); \
	fi)

bld_libgcc1: bld_gcc1
	(if [ ! -e $(BLD)/.build_libcc_1 ] ; then \
		export PATH=$(PATH);\
		cd $(bld_gcc_dir);\
		make all-target-libgcc && make install-target-libgcc;touch $(BLD)/.build_libgcc1;\
		cd $(ROOT);\
	fi)
