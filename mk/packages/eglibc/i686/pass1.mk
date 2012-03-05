#
# makefile for pass1
#

PASS1 := y

preconfigcmd := cd $(_src_dir) && cp -v Makeconfig{,.orig} && sed -e 's/-lgcc_eh//g' Makeconfig.orig > Makeconfig && \
		(echo "libc_cv_forced_unwind=yes" > config.cache ;\
		echo "libc_cv_c_cleanup=yes" >> config.cache; \
		echo "libc_cv_gnu89_inline=yes" >> config.cache; \
		echo "libc_cv_ssp=no" >> config.cache)

configcmd := BUILD_CC="gcc" CC="$(TARGET)-gcc" \
		    AR="$(TARGET)-ar" RANLIB="$(TARGET)-ranlib" \
			    CFLAGS="-march=$(shell cut -d- -f1 <<< $(TARGET)) -mtune=generic -g -O2" \
				$(_src_dir)/configure --prefix=$(TOOLS) \
				--host=$(TARGET) --build=$(HOST) \
				--disable-profile --enable-add-ons \
				--with-tls --enable-kernel=2.6.0 --with-__thread \
				--with-binutils=$(CROSS_TOOLS)/bin --with-headers=$(TOOLS)/include \
				--cache-file=config.cache

makecmd := make 

installcmd := make install inst_vardbdir=$(TOOLS)/var/db

include $(MK)/footer.mk


