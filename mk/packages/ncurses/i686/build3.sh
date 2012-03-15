#!/bin/sh

cd ${_bld_dir} && \
${_src_dir}/configure --prefix=${TOOLS} --with-shared \
    --build=${HOST} --host=${TARGET} \
    --without-debug --without-ada \
    --enable-overwrite --with-build-cc=gcc && \
make && make install
