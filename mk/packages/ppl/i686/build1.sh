#!/bin/sh

CPPFLAGS="-I${CROSS_TOOLS}/include" \
LDFLAGS="-Wl,-rpath,${CROSS_TOOLS}/lib" \
${_src_dir}/configure \
    --prefix=${CROSS_TOOLS} \
    --enable-shared \
    --enable-interfaces="c,cxx" \
    --disable-optimization \
    --with-libgmp-prefix=${CROSS_TOOLS} \
    --with-libgmpxx-prefix=${CROSS_TOOLS} && \
${MMAKE} && ${MMAKE} install


