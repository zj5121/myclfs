#!/bin/sh

source ${MK}/funcs.sh
copy_dir_clean ${_src_dir} ${_bld_dir} && \
cd ${_bld_dir} && \
echo "ac_cv_func_strnlen_working=yes" > config.cache
./configure --prefix=${TOOLS} \
	--build=${HOST} --host=${TARGET} \
	--cache-file=config.cache && \
make && \
make install


