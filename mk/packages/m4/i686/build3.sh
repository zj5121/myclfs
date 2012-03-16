#!/bin/sh
source ${MK}/funcs.sh

copy_dir_clean ${_src_dir} ${_bld_dir} && \
cd ${_bld_dir} && \
(cat > config.cache << EOF
gl_cv_func_btowc_eof=yes
gl_cv_func_mbrtowc_incomplete_state=yes
gl_cv_func_mbrtowc_sanitycheck=yes
gl_cv_func_mbrtowc_null_arg=yes
gl_cv_func_mbrtowc_retval=yes
gl_cv_func_mbrtowc_nul_retval=yes
gl_cv_func_wcrtomb_retval=yes
gl_cv_func_wctob_works=yes
EOF
) && \
./configure --prefix=${TOOLS} \
	--build=${HOST} --host=${TARGET} \
    --cache-file=config.cache && \
make && make install
