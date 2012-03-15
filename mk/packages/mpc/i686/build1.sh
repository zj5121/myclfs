#!/bin/sh

LDFLAGS="-Wl,-rpath,${CROSS_TOOLS}/lib" ${_src_dir}/configure \
			--prefix=${CROSS_TOOLS} \
			--with-gmp=${CROSS_TOOLS} \
			--with-mpfr=${CROSS_TOOLS} && \
${MMAKE} && ${MMAKE} install 


