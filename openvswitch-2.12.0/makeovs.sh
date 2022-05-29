#!/bin/bash
ovs-ctl stop;
clear;
./boot.sh;
export RTE_SDK=/home/gxh/mycode/dpdk-stable-18.11.9/;
export RTE_TARGET=x86_64-native-linuxapp-gcc;
export DPDK_BUILD=/home/gxh/mycode/dpdk-stable-18.11.9/x86_64-native-linuxapp-gcc/;
./configure --with-dpdk=$DPDK_BUILD CFLAGS="-Ofast -msse4.2 -mpopcnt";
make -j10;
make install;
