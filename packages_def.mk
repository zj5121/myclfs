
PACKAGES = $(wildcard $(TAR_DIR)/*.bz2) $(wildcard $(TAR_DIR)/*.gz) $(wildcard $(TAR_DIR)/*.xz)
PATCHES = $(wildcard $(PATCH_DIR)/*.patch)

PACKAGE_HTML := $(DOWNLOAD)/packages.html
PACKAGE_URL := http://cross-lfs.org/view/svn/x86/materials/packages.html
PACKAGE_CONF := packages.conf
PATCH_HTML := $(DOWNLOAD)/patches.html
PATCH_URL := http://cross-lfs.org/view/svn/x86/materials/patches.html
PATCH_CONF := patches.conf

LINUX_VER := 2.6.39
BINUTILS_VER := 2.21.1a
GCC_VER := 4.6.0
GMP_VER := 5.0.2
MPFR_VER := 3.1.0
MPC_VER := 0.9
PPL_VER := 0.11.2
CLOOG_VER := 0.15.11
LIBELF_VER := 0.8.9
EGLIBC_VER := 2.13-r13356

GCC_PATCHES := branch_update-1 specs-1
EGLIBC_PATCHES := cross-statge1-support r13356-dl_dep_fix-1

gcc_patched :=
eglibc_patched :=