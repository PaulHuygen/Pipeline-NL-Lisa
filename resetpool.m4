m4_include(inst.m4)m4_dnl
#!/bin/bash
# resetpool -- reset stopos pool
# 20150604 Paul Huygen
ROOT=m4_projroot
DATAROOT=$ROOT/data
INTRAY=$DATAROOT/intray
POOL=m4_stopospool
find $INTRAY -type f -print >filelist
stopos -p $POOL purge
stopos -p $POOL create
stopos -p $POOL add filelist
stopos -p $POOL status

