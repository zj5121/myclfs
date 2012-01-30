include config.mk
include rules.mk

bld_nutils_dir := $(BLD)/build_binutils
bld_gcc_dir := $(BLD)/build_gcc
bld_mpc_dir := $(BLD)/build_mpc
bld_mpfr_dir := $(BLD)/build_mpfr
bld_gmp_dir := $(BLD)/build_gmp

.PHONY: prep all

all: patch_source

include packages.mk
$(foreach p,$(PACKAGES),$(eval $(call prepare_source,$(p))))
$(foreach p,$(PATCHES),$(eval $(call patch_source,$(p))))

patch_source: $(UNTAR_TGTS) $(PATCHED_TGTS)

clean:

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
