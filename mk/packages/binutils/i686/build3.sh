#!/bin/sh
cd ${_bld_dir} &&  \
${_src_dir}/configure \
    --prefix=${TOOLS} \
    --build=${HOST} \
    --host=${TARGET} \
    --target=${TARGET} --with-lib-path=${TOOLS}/lib --disable-nls \
    --enable-shared --enable-64-bit-bfd --disable-multilib \
    --with-ppl=${TOOLS} --with-cloog=${TOOLS} --enable-cloog-backend=isl && \
make configure-host && make &&\
make install 


