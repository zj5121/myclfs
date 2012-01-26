TARGET := i686-unknown-linux-gnu
PREFIX := $(HOME)/x-tools/cross/$(TARGET)
ROOT := $(shell pwd)
BLD := $(ROOT)/bld
bld_binutils_dir := $(BLD)/build_binutils
NR_CPU := $(shell cat /proc/cpuinfo|grep processor|wc -l)

all: bld_binutil1

clean:

bld_binutil1: 
	(mkdir -p $(bld_binutils_dir))
	(if [ ! -e $(BLD)/.build_binutils_1 ] ; then \
		cd $(BLD); \
		../src/binutils-2.22/configure --target=$(TARGET) --prefix=$(PREFIX) --disable-nls && \
		make all -j$(NR_CPU)&& make install && touch $(BLD)/.build_binutils_1;\
	 fi)
