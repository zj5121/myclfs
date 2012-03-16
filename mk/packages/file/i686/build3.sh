#!/bin/sh
cd ${_bld_dir} && \
${_src_dir}/configure --prefix=${TOOLS} \
	--build=${HOST} --host=${TARGET} && \
make && \
make install


