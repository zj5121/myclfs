#!/bin/sh
#
source ${MK}/funcs.sh

copy_dir_clean ${_src_dir} ${_bld_dir} && \
cd ${_bld_dir} && \
cp -v Makefile{,.orig} &&
sed -e 's@^\(all:.*\) test@\1@g' Makefile.orig > Makefile && \
make CC="${CC}" AR="${AR}" RANLIB="${RANLIB}" && \
make PREFIX=${TOOLS} install
