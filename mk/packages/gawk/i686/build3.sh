#!/bin/sh
source ${MK}/funcs.sh

copy_dir_clean ${_src_dir} ${_bld_dir} && \
cd ${_bld_dir} && \
./configure --prefix=${TOOLS} \
    --build=${HOST} --host=${TARGET}
make && \
make install


