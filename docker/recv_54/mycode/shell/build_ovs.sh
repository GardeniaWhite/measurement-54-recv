#!/bin/bash
cd "$OVS_DIR"
./boot.sh;
export RTE_SDK=$RTE_SDK;
export RTE_TARGET=$RTE_TAEGET;
export DPDK_BUILD=$DPDK_DIR/$DPDK_BUILD;
./configure --with-dpdk=$DPDK_BUILD CFLAGS="-Ofast -msse4.2 -mpopcnt";
make -j8;
make install;
