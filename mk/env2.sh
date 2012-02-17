#!/bin/sh
env -i
HOME=${HOME}
TERM=${TERM}
set -e
set -u
umask 022
BASE=/cross
LC_ALL=POSIX
unset CFLAGS
unset CXXFLAGS

export CLFAGS CXXFLAGS BASE LC_ALL PATH
