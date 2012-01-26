TARGET := i686-unknown-linux-gnu
PREFIX := $(HOME)/cross/$(TARGET)
PATH := $(PREFIX)/bin:$(PATH)
ROOT := $(shell pwd)
BLD := $(ROOT)/bld
SRC := $(ROOT)/src
PATCH_DIR := $(ROOT)/patches
TAR_DIR := $(ROOT)/download

bld_binutils_dir := $(BLD)/build_binutils
bld_gcc_dir := $(BLD)/build_gcc

NR_CPU := $(shell cat /proc/cpuinfo|grep processor|wc -l)
INFO = @echo "I: " $1

all: bld_libgcc1

clean:

prep:
	@(echo $(shell [ ! -e $(SRC)/.src_untar ] && [ ! -e $(SRC)/.src_patched ] && echo "I: Prepare sources ..."))
	@(mkdir -p $(BLD) $(SRC))
	@(if [ ! -e $(SRC)/.src_untar ]; then \
		for f in $(TAR_DIR)/*.bz2 ; do \
			[ ! -z $$f ] && [ -e $$f ] && echo -n "I:  untar " $$(basename $$f) "..."  && tar jxf $$f -C $(SRC) && echo " done";\
		done && \
		for f in $(TAR_DIR)/*.gz ; do \
			[ ! -z $$f ] && [ -e $$f ] && echo -n "I:  untar " $$(basename $$f) "..." && tar zxf $$f -C $(SRC) && echo " done"; \
		done && \
		touch $(SRC)/.src_untar ;\
	fi;\
	[ ! -h $(SRC)/gcc-4.6.2/mpc ] && ln -s $(SRC)/mpc-0.9 $(SRC)/gcc-4.6.2/mpc;\
	[ ! -h $(SRC)/gcc-4.6.2/mpfr ] && ln -s $(SRC)/mpfr-3.1.0 $(SRC)/gcc-4.6.2/mpfr;\
	[ ! -h $(SRC)/gcc-4.6.2/gmp ] && ln -s  $(SRC)/gmp-5.0.2 $(SRC)/gcc-4.6.2/gmp;\
	if [ ! -e $(SRC)/.src_patched ] ; then \
		for f in $(PATCH_DIR)/*.*; do \
			d=$$(basename $${f%%--*});\
			cd $(SRC)/$$d; \
			patch -i $$f -p1 && echo "I:  patched $$d" && cd ..;\
		done;\
		touch $(SRC)/.src_patched;\
	fi;)
	
bld_binutil1: prep
	@(mkdir -p $(bld_binutils_dir))
	@(if [ ! -e $(BLD)/.build_binutils_1 ] ; then \
		cd $(bld_binutils_dir); \
		$(ROOT)/src/binutils-2.22/configure --target=$(TARGET) --prefix=$(PREFIX) --disable-nls && \
		make all -j$(NR_CPU)&& make install && touch $(BLD)/.build_binutils_1;\
		cd $(ROOT);\
	 fi)

bld_gcc1: bld_binutil1
	@(mkdir -p $(bld_gcc_dir))
	@(if [ ! -e $(BLD)/.build_gcc_1 ] ; then \
		export PATH=$(PATH);\
		cd $(bld_gcc_dir); \
		$(ROOT)/src/gcc-4.6.2/configure --target=$(TARGET) --prefix=$(PREFIX) --disable-nls --enable-languages=c,c++ --without-headers &&\
		make -j$(NR_CPU) all-gcc && touch $(BLD)/.build_gcc_1;\
		cd $(ROOT); \
	fi)

bld_libgcc1: bld_gcc1
	(if [ ! -e $(BLD)/.build_libcc_1 ] ; then \
		export PATH=$(PATH);\
		cd $(bld_gcc_dir);\
		make all-target-libgcc && make install-target-libgcc;touch $(BLD)/.build_libgcc1;\
		cd $(ROOT);\
	fi)
