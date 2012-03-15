#!/bin/sh

cd ${_src_dir} && \
(cat >> gcc/config/linux.h << EOF
#undef STANDARD_INCLUDE_DIR
#define STANDARD_INCLUDE_DIR "${TOOLS}/include/" 
#undef STANDARD_STARTFILE_PREFIX_1
#define STANDARD_STARTFILE_PREFIX_1 "${TOOLS}/lib/" 
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_2 ""
EOF
)  

