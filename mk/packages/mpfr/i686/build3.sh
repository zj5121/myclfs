#!/bin/sh

${_src_dir}/configure \
	--build=${HOST} --host=${TARGET}\
	--prefix=${TOOLS} \
	--enable-shared --with-gmp=${TOOLS} && \
make && make install
