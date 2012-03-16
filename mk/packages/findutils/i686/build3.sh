#!/bin/sh
source ${MK}/funcs.sh

copy_dir_clean ${_src_dir} ${_bld_dir} && \
echo "gl_cv_func_wcwidth_works=yes" > config.cache && \
echo "ac_cv_func_fnmatch_gnu=yes" >> config.cache &&\
cd ${_bld_dir} && \
./configure --prefix=${TOOLS} \
	--build=${HOST} --host=${TARGET} \
	--cache-file=config.cache && \
make && \
make install


