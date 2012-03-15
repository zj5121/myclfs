#!/bin/sh
cd ${_bld_dir} && \
${_src_dir}/configure --prefix=${CROSS_TOOLS} && \
${MMAKE} && \
${MMAKE} install


