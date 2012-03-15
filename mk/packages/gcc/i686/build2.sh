#!/bin/sh

source ${_mk_dir}/build_common.sh

cp -v gcc/Makefile.in{,.orig} && \
sed -e 's@\(^CROSS_SYSTEM_HEADER_DIR =\).*@\1 ${TOOLS}/include@g' gcc/Makefile.in.orig > gcc/Makefile.in && \
cd ${_bld_dir} && \
AR=ar LDFLAGS=-Wl,-rpath="${CROSS_TOOLS}/lib" \
${_src_dir}/configure --prefix=${CROSS_TOOLS} \
	--build=${HOST} --target=${TARGET} --host=${HOST} \
	--with-sysroot=${BASE} --with-local-prefix=${TOOLS} --disable-nls \
	--enable-shared --enable-languages=c,c++ --enable-__cxa_atexit \
	--with-mpfr=${CROSS_TOOLS} --with-gmp=${CROSS_TOOLS} --enable-c99 \
	--with-ppl=${CROSS_TOOLS} --with-cloog=${CROSS_TOOLS} --enable-cloog-backend=isl \
	--enable-long-long --enable-threads=posix --disable-multilib && \
make AS_FOR_TARGET="${TARGET}-as" LD_FOR_TARGET="${TARGET}-ld" && \
make install

