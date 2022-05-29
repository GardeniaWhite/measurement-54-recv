cd "$DPDK_DIR"
echo "Building the $DPDK_BUILD flavor of DPDK in the $DPDK_DIR/$DPDK_BUILD directory"
meson build
ninja -C build
ninja -C build install
ldconfig

