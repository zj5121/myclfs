#!/bin/sh

cd ${_bld_dir} && \
AR=ar AS=as ${_src_dir}/configure \
		--prefix=${CROSS_TOOLS} \
		--build=${HOST} \
		--host=${HOST} \
        --target=${TARGET} \
		--with-sysroot=${BASE} \
        --with-lib-path=${TOOLS}/lib \
        --disable-nls --enable-shared \
		--disable-multilib \
        --with-ppl=${CROSS_TOOLS} \
		--with-cloog=${CROSS_TOOLS} \
        --enable-cloog-backend=isl && \
make configure-host && ${MMAKE} && \
${MMAKE} install && \
cp -v ${_src_dir}/include/libiberty.h ${TOOLS}/include



