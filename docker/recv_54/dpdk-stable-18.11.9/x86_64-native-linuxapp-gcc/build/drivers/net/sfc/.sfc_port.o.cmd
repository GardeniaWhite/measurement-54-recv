cmd_sfc_port.o = gcc -Wp,-MD,./.sfc_port.o.d.tmp  -m64 -pthread  -march=native -DRTE_MACHINE_CPUFLAG_SSE -DRTE_MACHINE_CPUFLAG_SSE2 -DRTE_MACHINE_CPUFLAG_SSE3 -DRTE_MACHINE_CPUFLAG_SSSE3 -DRTE_MACHINE_CPUFLAG_SSE4_1 -DRTE_MACHINE_CPUFLAG_SSE4_2 -DRTE_MACHINE_CPUFLAG_AES -DRTE_MACHINE_CPUFLAG_PCLMULQDQ -DRTE_MACHINE_CPUFLAG_AVX -DRTE_MACHINE_CPUFLAG_RDRAND -DRTE_MACHINE_CPUFLAG_FSGSBASE -DRTE_MACHINE_CPUFLAG_AVX2  -I/home/gxh/mycode/dpdk-stable-18.11.9/x86_64-native-linuxapp-gcc/include -include /home/gxh/mycode/dpdk-stable-18.11.9/x86_64-native-linuxapp-gcc/include/rte_config.h -D_GNU_SOURCE -DALLOW_EXPERIMENTAL_API -I/home/gxh/mycode/dpdk-stable-18.11.9/drivers/net/sfc/base/ -I/home/gxh/mycode/dpdk-stable-18.11.9/drivers/net/sfc -O3 -W -Wall -Wstrict-prototypes -Wmissing-prototypes -Wmissing-declarations -Wold-style-definition -Wpointer-arith -Wcast-align -Wnested-externs -Wcast-qual -Wformat-nonliteral -Wformat-security -Wundef -Wwrite-strings -Wdeprecated -Wimplicit-fallthrough=2 -Wno-format-truncation -Wno-address-of-packed-member -Wno-strict-aliasing -Wextra -Wdisabled-optimization -Waggregate-return -Wnested-externs    -o sfc_port.o -c /home/gxh/mycode/dpdk-stable-18.11.9/drivers/net/sfc/sfc_port.c 
