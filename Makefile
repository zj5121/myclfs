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
		$(MAKE) ARCH=$(TARGET_ARCH) INSTALL_HDR_PATH=dest headers_install && \
		cp -rv dest/include/* $(dir $(linux_dest)) && \
		touch $@; \
	)

$(eval $(call prepare_source,gmp,$(GMP_VER),tar.bz2))
gmp_dest := $(CLFS_TEMP)/lib/libgmpxx.a
gmp_bld  := $(BLD)/gmp-$(GMP_VER)
$(gmp_dest): $(gmp_src) 
	@(rm -fr $(gmp_bld) && mkdir -p $(gmp_bld) && \
	source $(curdir)/env.sh && \
	cd $(gmp_bld) && \
	CPPFLAGS="-fexceptions" $(dir $(gmp_src))/configure \
	--prefix=$(call parent,$(call parent,$@)) --enable-cxx && \
	$(MAKE) && $(MAKE) install \
	)

$(eval $(call prepare_source,mpfr,$(MPFR_VER),tar.bz2))
$(eval $(call patch_source,MPFR_PATCHES,mpfr,3.1.0))
mpfr_dest := $(CLFS_TEMP)/lib/libmpfr.so
mpfr_bld  := $(BLD)/mpfr-$(MPFR_VER)
$(mpfr_dest): $(mpfr_patched) $(gmp_dest)
	@(rm -fr $(mpfr_bld) && mkdir -p $(mpfr_bld) &&\
	source $(curdir)/env.sh && \
	cd $(mpfr_bld) && \
	CPPFLAGS="-I$(CLFS_TEMP)/include" \
	CFLAGS="-I$(CFLAGS)/include" \
	LDFLAGS="-Wl,-rpath=$(CLFS_TEMP)/lib" \
	$(dir $(mpfr_src))/configure --prefix=$(CLFS_TEMP) --enable-shared --with-gmp=$(CLFS_TEMP) && \
	$(MAKE) && $(MAKE) install)


$(eval $(call prepare_source,mpc,$(MPC_VER),tar.gz))
mpc_dest := $(CLFS_TEMP)/lib/libmpc.so
mpc_bld := $(BLD)/mpc-$(MPC_VER)
$(mpc_dest): $(mpc_src) $(mpfr_dest) $(gmp_dest)
	@(rm -fr $(mpc_bld) && mkdir -p $(mpc_bld) &&\
	source $(curdir)/env.sh && \
	cd $(mpc_bld) &&\
	CPPFLAGS="-I$(CLFS_TEMP)/include" \
	LDFLAGS="-Wl,-rpath=$(CLFS_TEMP)/lib" \
	$(dir $(mpc_src))/configure --prefix=$(CLFS_TEMP) --with-gmp=$(CLFS_TEMP) --with-mpfr=$(CLFS_TEMP) &&\
	$(MAKE) && $(MAKE) install)

$(eval $(call prepare_source,ppl,$(PPL_VER),tar.bz2))
ppl_dest := $(CLFS_TEMP)/lib/libppl.so
ppl_bld := $(BLD)/ppl-$(PPL_VER)
$(ppl_dest): $(ppl_src) $(mpc_dest)
	$(call echo_cmd,,$(INFO_CONFIG) $(notdir $(ppl_bld)))
	@(rm -fr $(ppl_bld) && mkdir -p $(ppl_bld) &&\
	source $(curdir)/env.sh && \
	cd $(ppl_bld) && \
	CFLAGS="-I$(CLFS_TEMP)/include" CPPFLAGS="-I$(CLFS_TEMP)/include" \
	LDFLAGS="-Wl,-rpath=$(CLFS_TEMP)/lib" \
	$(dir $(ppl_src))/configure --prefix=$(CLFS_TEMP) --enable-shared \
	--enable-interfaces="c,cxx" --disable-optimization \
	--with-libgmp-prefix=$(CLFS_TEMP) \
	--with-libgmpxx-prefix=$(CLFS_TEMP) && \
	$(MAKE) && $(MAKE) install)


$(eval $(call prepare_source,cloog-ppl,$(CLOOG_VER),tar.gz))
cloog_dest := $(CLFS_TEMP)/lib/libcloog.so
cloog_bld := $(BLD)/cloog-ppl-$(CLOOG_VER)
$(cloog_dest): $(cloog-ppl_src) $(gmp_dest) $(ppl_dest)
	$(call echo_cmd,,$(INFO_CONFIG) $(notdir $(notdir $(cloog_bld))))
	@(rm -fr $(cloog_bld) && mkdir -p $(cloog_bld) &&\
	source $(curdir)/env.sh && \
	cd $(dir $(cloog-ppl_src)) && \
	cp -v configure{,.orig} && \
	sed -e "/LD_LIBRARY_PATH=/d" configure.orig > configure && \
	cd $(cloog_bld) && LDFLAGS="-Wl,-rpath=$(CLFS_TEMP)/lib" \
	$(dir $(cloog-ppl_src))/configure --prefix=$(CLFS_TEMP) --enable-shared --with-bits=gmp \
	--with-gmp=$(CLFS_TEMP) --with-ppl=$(CLFS_TEMP) && \
	$(MAKE) && $(MAKE) install)

# bintuils pass1
$(eval $(call prepare_source,binutils,2.22,tar.bz2))
binutils_dest := $(CLFS_TEMP)/bin/$(TARGET)-ar
binutils_bld := $(BLD)/binutils-$(BINUTILS_VER)
$(binutils_dest): $(binutils_src) $(cloog_dest) $(linux_dest)
	@(rm -fr $(binutils_bld) && mkdir -p $(binutils_bld) && \
	source $(curdir)/env.sh && \
	cd $(binutils_bld) && \
	AR=ar AS=as $(dir $(binutils_src))/configure \
	--prefix=$(CLFS_TEMP) --host=$(HOST) --target=$(TARGET) \
	--with-sysroot=$(CLFS) --with-lib-path=$(CLFS_FINAL)/lib \
	--disable-nls --enable-shared \
	--disable-multilib && \
	$(MAKE) configure-host && \
	$(MAKE) && $(MAKE) install && \
	mkdir -p $(CLFS_FINAL)/include && \
	cp -v $(dir $(binutils_src))/include/libiberty.h $(CLFS_FINAL)/include)

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
	  --disable-shared --with-mpfr=$(CLFS_TEMP) --with-gmp=$(CLFS_TEMP) \
	  --with-ppl=$(CLFS_TEMP) --with-cloog=$(CLFS_TEMP) \
	  --without-headers --with-newlib --disable-decimal-float \
	  --disable-libgomp --disable-libmudflap --disable-libssp \
	  --disable-threads --enable-languages=c --disable-multilib \
	  --with-arch=$(TARGET_ARCH) &&\
	$(MAKE) all-gcc && $(MAKE) install-gcc 
	#all-target-libgcc && $(MAKE) install-gcc install-target-libgcc

libgcc_dest := $(CLFS_TEMP)/lib/gcc/libgcc.a
libgcc_bld := $(BLD)/gcc-$(GCC_VER)
$(libgcc_dest) : $(gcc_dest)
	@(source $(curdir)/env.sh && cd $(gcc_bld) &&
	$(MAKE) all-target-libgcc && $(MAKE install-target-libgcc))

build: $(gcc_dest)

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
