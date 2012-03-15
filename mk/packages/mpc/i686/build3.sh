#!/bin/sh

EGREP="grep -E" ${_src_dir}/configure \
			--prefix=${TOOLS} \
			--with-gmp=${TOOLS} \
			--with-mpfr=${TOOLS} && \
make && make install


