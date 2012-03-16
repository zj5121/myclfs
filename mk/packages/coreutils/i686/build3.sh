#!/bin/sh
#
source ${MK}/funcs.sh

copy_dir_clean ${_src_dir} ${_bld_dir} && \
cd ${_bld_dir} &&\
touch man/uname.1 man/hostname.1 && \
(cat > config.cache << EOF
fu_cv_sys_stat_statfs2_bsize=yes
gl_cv_func_working_mkstemp=yes
EOF
) &&\
./configure --prefix=${TOOLS}  \
    --build=${HOST} --host=${TARGET} \
    --enable-install-program=hostname --cache-file=config.cache && \
make && \
make install
