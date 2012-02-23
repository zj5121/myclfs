
PACKAGES = $(wildcard $(TAR_DIR)/*.bz2) $(wildcard $(TAR_DIR)/*.gz) $(wildcard $(TAR_DIR)/*.xz)
PATCHES = $(wildcard $(PATCH_DIR)/*.patch)

clfs_files	:=  packages.html http://cross-lfs.org/view/svn/x86/materials/packages.html \
				patches.html http://cross-lfs.org/view/svn/x86/materials/patches.html \
				patches-x86.html http://cross-lfs.org/view/svn/x86/materials/patches-x86.html
				
				

LINUX_VER := 2.6.39
BINUTILS_VER := 2.21.1a
GCC_VER := 4.6.0
GMP_VER := 5.0.2
MPFR_VER := 3.0.1
MPC_VER := 0.9
PPL_VER := 0.11.2
CLOOG_VER := 0.15.11
LIBELF_VER := 0.8.9
EGLIBC_VER := 2.13-r13356
ZLIB_VER := 1.2.6
NCURSES_VER := 5.9
BASH_VER := 4.2
BISON_VER := 2.5
BZIP2_VER := 1.0.6
COREUTILS_VER := 8.12
DIFFUTILS_VER := 3.0
FINDUTILS_VER := 4.4.2
FILE_VER := 5.07
FLEX_VER := 2.5.35
GAWK_VER := 3.1.8
GETTEXT_VER := 0.18.1.1
GREP_VER := 2.8
GZIP_VER := 1.4
M4_VER := 1.4.16
MAKE_VER := 3.82
PATCH_VER := 2.6.1
SED_VER := 4.2.1
TAR_VER := 1.26
TEXINFO_VER := 4.13a
VIM_VER := 7.3
XZ_VER := 5.0.2
UTIL-LINUX_VER := 2.19.1
E2FSPROG_VER := 1.41.14

GCC_PATCHES := branch_update-1 specs-1
EGLIBC_PATCHES := cross-statge1-support r13356-dl_dep_fix-1
NCURSES_PATCHES := bash_fix-1
BASH_PATCHES := branch_update-2
COREUTILS_PATCHES := uname-1
FLEX_PATCHES := gcc44-1
VIM_PATCHES := branch_update-2

gcc_patched :=
eglibc_patched :=