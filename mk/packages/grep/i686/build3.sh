#!/bin/sh
source ${MK}/funcs.sh

copy_dir_clean ${_src_dir} ${_bld_dir} && \
cd ${_bld_dir} && \
(cat > config.cache << EOF
ac_cv_func_malloc_0_nonnull=yes
ac_cv_func_realloc_0_nonnull=yes
EOF
) && \
./configure --prefix=${TOOLS} \
	--build=${HOST} --host=${TARGET} \
    --disable-perl-regexp --without-included-regex \
    --cache-file=config.cache && \
make && make install

