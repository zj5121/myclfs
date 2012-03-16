#!/bin/sh
source ${MK}/funcs.sh

copy_dir_clean ${_src_dir} ${_bld_dir} && \
cd ${_bld_dir}/gettext-tools && \
echo "gl_cv_func_wcwidth_works=yes" > config.cache && \
./configure --prefix=${TOOLS} \
	--disable-shared \
    --build=${HOST} --host=${TARGET} \
    --cache-file=config.cache && \
make -C gnulib-lib && \
make -C src msgfmt && \
cp -v src/msgfmt /tools/bin


