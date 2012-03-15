#!/bin/sh
CPPFLAGS="-fexceptions" \
${_src_dir}/configure --prefix=${CROSS_TOOLS} --enable-cxx && \
${MMAKE} && make install

