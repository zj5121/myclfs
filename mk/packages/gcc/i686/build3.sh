#!/bin/sh
source ${_mk_dir}/build_common.sh

cd ${_src_dir} && \
cp -v gcc/Makefile.in{,.orig} && \
sed -e "s@\(^NATIVE_SYSTEM_HEADER_DIR =\).*@\1 ${TOOLS}/include@g" gcc/Makefile.in.orig > gcc/Makefile.in  && \
cd ${_bld_dir} && \
${_src_dir}/configure --prefix=/tools \
	--build=${HOST} --host=${TARGET} --target=${TARGET} \
	--with-local-prefix=${TOOLS} --enable-long-long --enable-c99 \
	--enable-shared --enable-threads=posix --enable-__cxa_atexit \
	--disable-nls --enable-languages=c,c++ --disable-libstdcxx-pch \
	--disable-multilib --enable-cloog-backend=isl && \
cp -v Makefile{,.orig} && \
sed "/^HOST_\(GMP\|PPL\|CLOOG\)\(LIBS\|INC\)/s:-[IL]/\(lib\|include\)::" Makefile.orig > Makefile && \
make AS_FOR_TARGET="${AS}" LD_FOR_TARGET="${LD}" && \
make install 


