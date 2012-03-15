#!/bin/sh

source ${_mk_dir}/build_common.sh

cp -v gcc/Makefile.in{,.orig} && \
sed -e "s@\(^CROSS_SYSTEM_HEADER_DIR =\).*@\1 ${TOOLS}/include@g" gcc/Makefile.in.orig > gcc/Makefile.in
touch ${TOOLS}/include/limits.h && \
cd ${_bld_dir} && \
AR=ar LDFLAGS="-Wl,-rpath,${CROSS_TOOLS}/lib" \
${_src_dir}/configure \
  --prefix=${CROSS_TOOLS} \
  --build=${HOST} \
  --host=${HOST} \
  --target=${TARGET} \
  --with-sysroot=${BASE} \
  --with-local-prefix=${TOOLS} \
  --disable-nls \
  --disable-shared \
  --with-mpfr=${CROSS_TOOLS} \
  --with-gmp=${CROSS_TOOLS} \
  --with-ppl=${CROSS_TOOLS} \
  --with-cloog=${CROSS_TOOLS} \
  --without-headers --with-newlib --disable-decimal-float \
  --disable-libgomp --disable-libmudflap --disable-libssp \
  --disable-threads --enable-languages=c --disable-multilib \
  --enable-cloog-backend=isl && \
${MMAKE} all-gcc all-target-libgcc && \
${MMAKE} install-gcc install-target-libgcc

