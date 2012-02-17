#!/bin/sh
env -i
HOME=${HOME}
TERM=${TERM}
set -e
set -u
umask 022
BASE=/cross
LC_ALL=POSIX
#PATH=/cross/toolchain/bin:/bin:/usr/bin
unset CFLAGS
unset CXXFLAGS
HOST_ARCH=`gcc -dumpmachine`
CC_FOR_BUILD=${HOST_ARCH}-gcc
CC=${HOST_ARCH}-gcc
CXX=${HOST_ARCH}-g++
AR=/usr/bin/ar
RANLIB=/usr/bin/ranlib

export CLFAGS CXXFLAGS BASE LC_ALL PATH CC CXX AR RANLIB 
