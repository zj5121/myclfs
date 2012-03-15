#!/bin/sh

LDFLAGS="-Wl,-rpath=${CROSS_TOOLS}/lib" ${_src_dir}/configure \
			--prefix=${CROSS_TOOLS} \
			--enable-shared --with-gmp=${CROSS_TOOLS} && \
${MMAKE} && $MMAKE install

