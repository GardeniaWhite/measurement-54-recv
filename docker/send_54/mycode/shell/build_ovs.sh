cd $OVS_DIR
./boot.sh;
./configure --with-dpdk=static CFLAGS="-Ofast -msse4.2 -mpopcnt";
make -j8;
make install;

