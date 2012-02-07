include config.mk
include rules.mk

curdir := $(shell pwd)

.PHONY: prep all

all: build

include packages.mk

$(eval $(call prepare_source,linux,$(LINUX_VER),tar.bz2))
linux_dest := $(CLFS_FINAL)/include/.linux_hdr
$(linux_dest): $(linux_src) 
	@install -dv $(dir $(linux_dest))
	@(cd $(dir $<) && \
		$(MAKE) mrproper && \
		$(MAKE) ARCH=$(TARGET_ARCH) headers_check && \
		$(MAKE) ARCH=$(TARGET_ARCH) CROSS_COMPILE=$(CLFS_)/bin/$(TARGET)- INSTALL_HDR_PATH=dest headers_install && \
		cp -rv dest/include/* $(dir $(linux_dest)) && \
		touch $@; \
	)


# gmp lib
$(eval $(call prepare_source,gmp,$(GMP_VER),tar.bz2))
gmp_dest := $(TOOLCHAIN_HOST)/usr/lib/libgmpxx.a
gmp_bld  := $(BLD)/gmp-$(GMP_VER)
$(gmp_dest): $(gmp_src) 
	(rm -fr $(gmp_bld) && mkdir -p $(gmp_bld) && \
	source $(curdir)/env.sh && \
	cd $(gmp_bld) && \
	CPPFLAGS="-fexceptions" $(gmp_src_dir)/configure \
	--prefix=$(TOOLCHAIN_HOST)/usr \
	--build=$(BUILD) \
	--host=$(BUILD) \
	--target=$(BUILD) \
	--enable-cxx && \
	$(MAKE) && $(MAKE) install && $(MAKE) check \
	)

# mpfr lib
$(eval $(call prepare_source,mpfr,$(MPFR_VER),tar.bz2))
$(eval $(call patch_source,MPFR_PATCHES,mpfr,3.1.0))
mpfr_dest := $(TOOLCHAIN_HOST)/usr/lib/libmpfr.so
mpfr_bld  := $(BLD)/mpfr-$(MPFR_VER)
$(mpfr_dest): $(mpfr_patched) $(gmp_dest)
	@(rm -fr $(mpfr_bld) && mkdir -p $(mpfr_bld) &&\
	source $(curdir)/env.sh && \
	cd $(mpfr_bld) && \
	CPPFLAGS="-I$(TOOLCHAIN_HOST)/usr/include" \
	CFLAGS="-I$(TOOLCHAIN_HOST)/usr/include" \
	LDFLAGS="-Wl,-rpath=$(TOOLCHAIN_HOST)/usr/lib" \
	$(mpfr_src_dir)/configure --prefix=$(TOOLCHAIN_HOST)/usr \
	--enable-shared \
	--with-gmp=$(TOOLCHAIN_HOST)/usr \
	--target=$(TARGET) \
	--build=$(BUILD) \
	--host=$(BUILD) && \
	$(MAKE) && $(MAKE) install && $(MAKE) check)

# mpc lib
$(eval $(call prepare_source,mpc,$(MPC_VER),tar.gz))
mpc_dest := $(TOOLCHAIN_HOST)/usr/lib/libmpc.so
mpc_bld := $(BLD)/mpc-$(MPC_VER)
$(mpc_dest): $(mpc_src) $(mpfr_dest) $(gmp_dest)
	@(rm -fr $(mpc_bld) && mkdir -p $(mpc_bld) &&\
	source $(curdir)/env.sh && \
	cd $(mpc_bld) &&\
	CPPFLAGS="-I$(TOOLCHAIN_HOST)/usr/include" \
	LDFLAGS="-Wl,-rpath=$(TOOLCHAIN_HOST)/usr/lib" \
	$(mpc_src_dir)/configure --prefix=$(TOOLCHAIN_HOST)/usr \
	--build=$(BUILD) \
	--target=$(TARGET) \
	--disable-nls \
	--with-gmp=$(TOOLCHAIN_HOST)/usr \
	--with-mpfr=$(TOOLCHAIN_HOST)/usr &&\
	$(MAKE) && $(MAKE) install && $(MAKE) check)


$(eval $(call prepare_source,ppl,$(PPL_VER),tar.bz2))
ppl_dest := $(TOOLCHAIN_HOST)/usr/lib/libppl.so
ppl_bld := $(BLD)/ppl-$(PPL_VER)
$(ppl_dest): $(ppl_src) $(mpc_dest)
	$(call echo_cmd,,$(INFO_CONFIG) $(notdir $(ppl_bld)))
	@(rm -fr $(ppl_bld) && mkdir -p $(ppl_bld) &&\
	source $(curdir)/env.sh && \
	cd $(ppl_bld) && \
	CFLAGS="-I$(TOOLCHAIN_HOST)/include" CPPFLAGS="-I$(TOOLCHAIN_HOST)/usr/include" \
	LDFLAGS="-Wl,-rpath=$(TOOLCHAIN_HOST)/usr/lib" \
	$(ppl_src_dir)/configure --prefix=$(TOOLCHAIN_HOST)/usr \
	--build=$(BUILD) \
	--target=$(TARGET) \
	--enable-interfaces="c,cxx" \
	--disable-watchdog \
	--with-libgmp-prefix=$(TOOLCHAIN_HOST)/usr \
	--with-libgmpxx-prefix=$(TOOLCHAIN_HOST)/usr && \
	$(MAKE) && $(MAKE) install)



$(eval $(call prepare_source,cloog-ppl,$(CLOOG_VER),tar.gz))
cloog_dest := $(TOOLCHAIN_HOST)/usr/lib/libcloog.so
cloog_bld := $(BLD)/cloog-ppl-$(CLOOG_VER)
$(cloog_dest): $(cloog-ppl_src) $(gmp_dest) $(ppl_dest)
	$(call echo_cmd,,$(INFO_CONFIG) $(notdir $(notdir $(cloog_bld))))
	@(rm -fr $(cloog_bld) && mkdir -p $(cloog_bld) &&\
	source $(curdir)/env.sh && \
	cd $(cloog-ppl_src_dir) && \
	cp -v configure{,.orig} && \
	sed -e "/LD_LIBRARY_PATH=/d" configure.orig > configure && \
	cd $(cloog_bld) && LDFLAGS="-Wl,-rpath=$(TOOLCHAIN_HOST)/usr/lib" \
	$(cloog-ppl_src_dir)/configure --prefix=$(TOOLCHAIN_HOST)/usr \
	--build=$(BUILD) \
	--target=$(TARGET) \
	--disable-shared \
	--disable-nls \
	--with-bits=gmp \
	--with-gmp=$(TOOLCHAIN_HOST)/usr --with-ppl=$(TOOLCHAIN_HOST)/usr && \
	$(MAKE) && $(MAKE) install && $(MAKE) check)

# libelf
$(eval $(call prepare_source,libelf,$(LIBELF_VER),tar.gz))
libelf_dest := $(TOOLCHAIN_HOST)/usr/lib/libelf.so
libelf_bld := $(BLD)/libelf-$(LIBELF_VER)
$(libelf_dest): $(libelf_src)
	@(rm -fr $(libelf_bld) && mkdir -p $(libelf_bld) && \
	source $(curdir)/env.sh && \
	cd $(libelf_bld) && \
	$(libelf_src_dir)/configure --prefix=$(TOOLCHAIN_HOST)/usr \
	--build=$(BUILD) \
	--target=$(TARGET) \
	--host=$(BUILD) \
	--disable-nls \
	--disable-shared && \
	$(MAKE) && $(MAKE) install)

	
# bintuils pass1
$(eval $(call prepare_source,binutils,2.22,tar.bz2))
binutils_dest := $(TOOLCHAIN)/bin/$(TARGET)-ar
binutils_bld := $(BLD)/binutils-$(BINUTILS_VER)
$(binutils_dest): $(binutils_src) $(cloog_dest) $(linux_dest)
	@(rm -fr $(binutils_bld) && mkdir -p $(binutils_bld) && \
	source $(curdir)/env.sh && \
	cd $(binutils_bld) && \
	$(binutils_src_dir)/configure \
	--prefix=$(TOOLCHAIN)  \
	--build=$(HOST)  \
	--host=$(HOST) \
	--target=$(TARGET) \
	--with-sysroot=$(SYSROOT) \
	--enable-poison-system-directories \
	--disable-nls --enable-shared \
	--disable-multilib && \
	$(MAKE) all-libiberty && \
	cp -fr $(binutils_src_dir)/include $(TOOLCHAIN_HOST)/usr/include
	$(MAKE) && $(MAKE) install && \
	mkdir -p $(CLFS_FINAL)/include && \
	cp -v $(dir $(binutils_src))/include/libiberty.h $(CLFS_FINAL)/include)

	#AR=ar AS=as LDFLAGS=-L$(TOOLCHAIN_HOST)/usr/lib CPPFLAGS=-I$(TOOLCHAIN_HOST)/usr/include \
# gcc-4.6 pass1
$(eval $(call prepare_source,gcc,$(GCC_VER),tar.bz2,core))
$(eval $(call prepare_source,gcc,$(GCC_VER),tar.bz2,g++))
$(call patch_source,GCC_PATCHES,gcc,$(GCC_VER))
gcc_dest := $(CLFS_TEMP)/bin/$(TARGET)-gcc
gcc_bld := $(BLD)/gcc-$(GCC_VER)
$(gcc_dest) : $(gcc_src) $(gcc_patched) $(binutils_dest)
	(echo -en '#undef STANDARD_INCLUDE_DIR\n#define STANDARD_INCLUDE_DIR "$(CLFS_FINAL)/include/"\n\n' >> $(gcc_src_dir)/gcc/config/linux.h && \
	echo -en '\n#undef STANDARD_STARTFILE_PREFIX_1\n#define STANDARD_STARTFILE_PREFIX_1 "$(CLFS_FINAL)/lib/"\n' >> $(gcc_src_dir)/gcc/config/linux.h && \
	echo -en '\n#undef STANDARD_STARTFILE_PREFIX_2\n#define STANDARD_STARTFILE_PREFIX_2 ""\n' >> $(gcc_src_dir)/gcc/config/linux.h) && \
	cp -v $(gcc_src_dir)/gcc/Makefile.in{,.orig} && \
	sed -e "s@\(^CROSS_SYSTEM_HEADER_DIR =\).*@\1 $(CLFS_FINAL)/include@g" \
	$(gcc_src_dir)/gcc/Makefile.in.orig > $(gcc_src_dir)/gcc/Makefile.in && \
	touch $(CLFS_FINAL)/include/limits.h && \
	rm -fr $(gcc_bld) && \
	source $(curdir)/env.sh && \
	mkdir -p $(gcc_bld) && cd $(gcc_bld) && \
	PATH=${PATH} && \
	AR=ar LDFLAGS="-Wl,-rpath,$(CLFS_TEMP)/lib" \
  	$(gcc_src_dir)/configure --prefix=$(CLFS_TEMP) \
	  --build=$(HOST) --host=$(HOST) --target=$(TARGET) \
	  --with-sysroot=$(CLFS) --with-local-prefix=$(CLFS_FINAL) --disable-nls \
	  --enable-shared --with-mpfr=$(CLFS_TEMP) --with-gmp=$(CLFS_TEMP) \
	  --with-ppl=$(CLFS_TEMP) --with-cloog=$(CLFS_TEMP) \
	  --without-headers --with-newlib --disable-decimal-float \
	  --disable-libgomp --disable-libmudflap --disable-libssp \
	  --disable-threads --enable-languages=c --disable-multilib \
	  --enable-targets=all --with-gnu-as --with-gnu-ld --enable-lto \
	  --enable-poison-system-directories --with-build-time-tools=$(CLFS_TEMP)/bin && \
	  --with-build-sysroot=$(CLFS_TEMP) '--withhost-libstdcxx=-staic-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm'
	  --with-arch=$(TARGET_ARCH) &&\
	$(MAKE) LDFLAGS_FOR_TARGET=--sysroot=$(CLFS) CPPFLAGS_FOR_TARGET=$(CLFS) build_tooldir=$(CLFS_TEMP) all-gcc && $(MAKE) install-gcc 


#build: $(gcc_dest)

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
