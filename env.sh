set -e
set -u
umask 022
BASE=/cross
LC_ALL=POSIX
PATH=/cross/toolchain/bin:/bin:/usr/bin
unset CFLAGS
unset CXXFLAGS
export CLFAGS CXXFLAGS BASE LC_ALL PATH
