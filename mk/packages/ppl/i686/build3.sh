#!/bin/sh

${_src_dir}/configure \
    --prefix=${TOOLS} \
    --build=${HOST} --host=${TARGET} \
    --enable-shared \
    --enable-interfaces="c,cxx" \
    --disable-optimization \
    --with-libgmp-prefix=${TOOLS} \
    --with-libgmpxx-prefix=${TOOLS} && \
echo '\#define PPL_GMP_SUPPORTS_EXCEPTIONS 1' >> confdefs.h && \
make && \
make install
