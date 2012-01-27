include config.mk

bld_stage1 := $(PREFIX)/stage1
bld_binutils_dir := $(BLD)/build_binutils
bld_gcc_dir := $(BLD)/build_gcc
bld_mpc_dir := $(BLD)/build_mpc
bld_mpfr_dir := $(BLD)/build_mpfr
bld_gmp_dir := $(BLD)/build_gmp


all: bld_libgcc1

clean:

prep:
	@(if [ ! -d $(XTOOLDIR) ] ; then echo "Error: $(XTOOLDIR) doesn't exist!" ; exit 1; fi)
	@(echo $(shell ([ ! -e $(SRC)/.src_untar ] || [ ! -e $(SRC)/.src_patched ]) && echo "I: Prepare sources ..."))
	@(mkdir -p $(BLD) $(SRC))
	@(if [ ! -e $(SRC)/.src_untar ]; then \
		for f in $(TAR_DIR)/*.bz2 ; do \
			[ ! -z $$f ] && [ -e $$f ] && echo -n "I:  untar " $$(basename $$f) "..."  && tar jxf $$f -C $(SRC) && echo " done";\
		done && \
		for f in $(TAR_DIR)/*.gz ; do \
			[ ! -z $$f ] && [ -e $$f ] && echo -n "I:  untar " $$(basename $$f) "..." && tar zxf $$f -C $(SRC) && echo " done"; \
		done && \
		for f in $(TAR_DIR)/*.xz ; do \
			[ ! -z $$f ] && [ -e $$f ] && echo -n "I:  untar " $$(basename $$f) "..." && tar Jxf $$f -C $(SRC) && echo " done"; \
		done && \
		touch $(SRC)/.src_untar ;\
	fi)
	#@(if [ ! -h $(SRC)/gcc-4.6.2/mpc ]; then \
	#	ln -s $(SRC)/mpc-0.9 $(SRC)/gcc-4.6.2/mpc || (echo "Error: can't link mpc into gcc dir!" && exit 1);\
	#fi)
	#@(if [ ! -h $(SRC)/gcc-4.6.2/mpfr ] ; then \
	#	ln -s $(SRC)/mpfr-3.1.0 $(SRC)/gcc-4.6.2/mpfr || (echo "Error: can't link mpfr into gcc dir!" && exit 1);\
	#fi)
	#@(if [ ! -h $(SRC)/gcc-4.6.2/gmp ] ; then \
	#	ln -s  $(SRC)/gmp-5.0.2 $(SRC)/gcc-4.6.2/gmp || (echo "Error: can't link gmp into gcc dir!" && exit 1);\
	#fi)
	@(if [ ! -e $(SRC)/.src_patched ] ; then \
		for f in $(PATCH_DIR)/*.*; do \
			d=$$(basename $${f%%--*});\
			cd $(SRC)/$$d; \
			patch -i $$f -p1 && echo "I:  patched $$d" && cd ..;\
		done;\
		touch $(SRC)/.src_patched;\
	fi)

kernel_prep: prep
	@(mkdir -p $(PREFIX)/usr/include)
	rm -f $(SRC)/linux && ln -s $(SRC)/linux-$(LINUX_VER) $(SRC)/linux
	(if [ ! -e $(BLD)/.kernel_prep ] ; then\
		cd $(SRC)/linux	&&\
		make mrproper && \
		make ARCH=$(TARGET_ARCH) headers_check && \
		make ARCH=$(TARGET_ARCH) INSTALL_HDR_PATH=dest headers_install && \
		cp -rv dest/include/* $(PREFIX)/usr/include &&\
		touch $(BLD)/.kernel_prep ;\
	fi)

bld_binutil1: kernel_prep 
	@(mkdir -p $(bld_binutils_dir))
	@(if [ ! -e $(BLD)/.build_binutils_1 ] ; then \
		cd $(bld_binutils_dir); \
		$(ROOT)/src/binutils-$(BINUTILS_VER)/configure --target=$(TARGET) --prefix=$(bld_stage1) \
		--disable-nls --with-sysroot=$(PREFIX) --enable-shared --disable-multilib && \
		make all -j$(NR_CPU)&& make install && \
		cp -v $(SRC)/binutils-$(BINUTILS_VER)/include/libiberty.h $(PREFIX)/usr/include && \
		touch $(BLD)/.build_binutils_1 && \
		cd $(ROOT);\
	 fi)

bld_gmp: kernel_prep
	@(mkdir -p $(bld_gmp_dir))
	@(if [ ! -e $(BLD)/.build_gmp ]; then \
		cd $(bld_gmp_dir);\
		$(ROOT)/src/gmp-$(GMP_VER)/configure --prefix=$(bld_stage1) && \
		make install && touch $(BLD)/.build_gmp; \
	fi)

bld_mpc: bld_mpfr
	@(mkdir -p $(bld_mpc_dir))
	@(if [ ! -e $(BLD)/.build_mpc ]; then \
		cd $(bld_mpc_dir);\
		$(ROOT)/src/mpc-$(MPC_VER)/configure LD_FLAGS="-Wl,-rpath=$(bld_stage1)/lib" --prefix=$(bld_stage1) \
		--enable-mpfr=$(bld_stage1) --enable-gmp=$(bld_stage1) && \
		make && make install && touch $(BLD)/.build_mpc; \
	fi)

bld_mpfr: bld_gmp
	@(mkdir -p $(bld_mpfr_dir))
	@(if [ ! -e $(BLD)/.build_mpfr ]; then \
		cd $(bld_mpfr_dir);\
		$(ROOT)/src/mpfr-$(MPFR_VER)/configure LD_FLAGS="-Wl,-rpath=$(bld_stage1)/lib" --prefix=$(bld_stage1) \
		--enable-shared --with-gmp=$(bld_stage1) && \
		make && make install && touch $(BLD)/.build_mpfr; \
	fi)

bld_gcc1: bld_binutil1 bld_mpc
	@(mkdir -p $(bld_gcc_dir))
	@(if [ ! -e $(BLD)/.build_gcc_1 ] ; then \
		export PATH=$(PATH);\
		cd $(bld_gcc_dir); \
		$(ROOT)/src/gcc-$(GCC_VER)/configure AR=ar LDFLAGS="-Wl,-rpath=$(PREFIX)/tmp/lib" \
		--build=$(HOST) --host=$(HOST) --with-sysroot=$(PREFIX) \
		--target=$(TARGET) --prefix=$(bld_stage1) --disable-nls \
		--enable-languages=c --without-headers \
		--disable-shared --disable-multilib \
    	--disable-decimal-float --disable-threads \
    	--disable-libmudflap --disable-libssp \
    	--disable-target-libiberty \
    	--disable-target-zlib \
    	--without-ppl --without-cloog \
    	--with-mpfr=$(bld_stage1) \
    	--with-gmp=$(bld_stage1) \
    	--with-mpc=$(bld_stage1) \
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
