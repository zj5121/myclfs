#!/bin/sh

cd ${_src_dir} && cp -v configure{,.orig} && \
sed -e "/LD_LIBRARY_PATH=/d" configure.orig > configure && \
cd ${_bld_dir} && \
${_src_dir}/configure \
	--build=${HOST} --host=${TARGET} \
	--prefix=${TOOLS} \
	--with-gmp-prefix=${TOOLS}  && \
make && \
make install


