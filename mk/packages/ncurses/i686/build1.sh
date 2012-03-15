#!/bin/sh

cd ${_bld_dir} && \
${_src_dir}/configure --prefix=${CROSS_TOOLS} --without-debug --without-shared && ${MMAKE} -C include && ${MMAKE} -C progs tic && \
install -v -m755 progs/tic ${CROSS_TOOLS}/bin/