#!/bin/sh
source ${MK}/funcs.sh

copy_dir_clean ${_src_dir} ${_bld_dir} && \
cd ${_bld_dir} && \
./configure --prefix=${CROSS_TOOLS} --build=${HOST} --host=${TARGET} && \
${MMAKE} && \
${MMAKE} install


