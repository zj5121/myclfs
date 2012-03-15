#!/bin/sh
env -i
HOME=${HOME}
TERM=${TERM}
set -e
set -u
umask 022
LC_ALL=POSIX
unset CFLAGS
unset CXXFLAGS

export CLFAGS CXXFLAGS LC_ALL 
