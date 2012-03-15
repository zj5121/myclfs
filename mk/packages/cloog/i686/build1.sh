#!/bin/sh

cd ${_src_dir} && cp -v configure{,.orig} && \
sed -e "/LD_LIBRARY_PATH=/d" configure.orig > configure && \
cd ${_bld_dir} &&\
LDFLAGS="-Wl,-rpath,${CROSS_TOOLS}/lib" \
${_src_dir}/configure \
			--prefix=${CROSS_TOOLS} \
			--enable-shared \
			--with-gmp-prefix=${CROSS_TOOLS} && \
${MMAKE} && \
make install


