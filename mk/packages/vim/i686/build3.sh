#!/bin/sh
source ${MK}/funcs.sh

copy_dir_clean ${_src_dir} ${_bld_dir} && \
cd ${_bld_dir} && \
sed -i "/using uint32_t/s/as_fn_error/#&/" src/auto/configure && \
(cat > src/auto/config.cache << "EOF"
vim_cv_getcwd_broken=no
vim_cv_memmove_handles_overlap=yes
vim_cv_stat_ignores_slash=no
vim_cv_terminfo=yes
vim_cv_tgent=zero
vim_cv_toupper_broken=no
vim_cv_tty_group=world
ac_cv_sizeof_int=4
ac_cv_sizeof_long=4
ac_cv_sizeof_time_t=4
ac_cv_sizeof_off_t=4
EOF
) && \
echo '#define SYS_VIMRC_FILE "${TOOLS}/etc/vimrc"' >> src/feature.h && \
./configure --prefix=${TOOLS} \
    --build=${HOST} --host=${TARGET} \
    --enable-multibyte --enable-gui=no \
    --disable-gtktest --disable-xim --with-features=normal \
    --disable-gpm --without-x --disable-netbeans \
    --with-tlib=ncurses && \
make && make install && \
ln -sfv vim ${TOOLS}/bin/vi && \
(cat > ${TOOLS}/etc/vimrc << "EOF"
" Begin /etc/vimrc

set nocompatible
set backspace=2
set ruler
syntax on

" End /etc/vimrc
EOF
)
