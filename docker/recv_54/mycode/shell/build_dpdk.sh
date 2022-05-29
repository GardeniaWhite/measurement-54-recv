cd "$DPDK_DIR"
echo "Building the $DPDK_BUILD flavor of DPDK in the $DPDK_DIR/$DPDK_BUILD directory"
make config O="$DPDK_BUILD" T="$DPDK_BUILD"
cd "$DPDK_BUILD"
make -j8
