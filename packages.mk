
PACKAGES = $(wildcard $(TAR_DIR)/*.bz2) $(wildcard $(TAR_DIR)/*.gz) $(wildcard $(TAR_DIR)/*.xz)
PATCHES = $(wildcard $(PATCH_DIR)/*.patch)

LINUX_VER := 3.2.2
BINUTILS_VER := 2.22
GCC_VER := 4.6.2
GMP_VER := 5.0.2
MPFR_VER := 3.1.0
MPC_VER := 0.9
PPL_VER := 0.11.2
CLOOG_VER := 0.15.11
BINTUILS_VER := 2.22
LIBELF_VER := 0.8.9
GCC_PATCHES := 
#cross_compile-1 specs-1 startfiles_fix-1
MPFR_PATCHES := fixes-1

gcc_patched :=
mpfr_patched :=
