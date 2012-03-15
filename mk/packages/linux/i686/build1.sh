#!/bin/sh

export MAKE="make"
mkdir -p "${_bld_dir}" && (cd "${_src_dir}" && tar cf - \
	--exclude=CVS --exclude=.svn --exclude=.git --exclude=.pc \
	--exclude="*~" --exclude=".#*" \
	--exclude="*.orig" --exclude="*.rej" \
	.) | (cd "${_bld_dir}" && tar xf -)  && \
cd ${_bld_dir} && \
install -dv ${TOOLS}/include && \
make mrproper && make ARCH=${ARCH} headers_check && \
make ARCH=${ARCH} INSTALL_HDR_PATH=dest headers_install && cp -rv dest/include/* ${TOOLS}/include

