#!/bin/sh

HOST_CC="gcc" CPPFLAGS="-fexceptions" ${_src_dir}/configure \
		--build=${HOST} --host=${TARGET} \
		--prefix=${TOOLS} \
		--enable-cxx && \
make && make install