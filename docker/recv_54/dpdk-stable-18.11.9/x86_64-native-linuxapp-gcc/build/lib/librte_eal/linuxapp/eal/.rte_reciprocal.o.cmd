cmd_rte_reciprocal.o = gcc -Wp,-MD,./.rte_reciprocal.o.d.tmp  -m64 -pthread  -march=native -DRTE_MACHINE_CPUFLAG_SSE -DRTE_MACHINE_CPUFLAG_SSE2 -DRTE_MACHINE_CPUFLAG_SSE3 -DRTE_MACHINE_CPUFLAG_SSSE3 -DRTE_MACHINE_CPUFLAG_SSE4_1 -DRTE_MACHINE_CPUFLAG_SSE4_2 -DRTE_MACHINE_CPUFLAG_AES -DRTE_MACHINE_CPUFLAG_PCLMULQDQ -DRTE_MACHINE_CPUFLAG_AVX -DRTE_MACHINE_CPUFLAG_RDRAND -DRTE_MACHINE_CPUFLAG_FSGSBASE -DRTE_MACHINE_CPUFLAG_AVX2  -I/home/gxh/mycode/dpdk-stable-18.11.9/x86_64-native-linuxapp-gcc/include -include /home/gxh/mycode/dpdk-stable-18.11.9/x86_64-native-linuxapp-gcc/include/rte_config.h -D_GNU_SOURCE -DALLOW_EXPERIMENTAL_API -I/home/gxh/mycode/dpdk-stable-18.11.9/lib/librte_eal/linuxapp/eal/include -I/home/gxh/mycode/dpdk-stable-18.11.9/lib/librte_eal/common -I/home/gxh/mycode/dpdk-stable-18.11.9/lib/librte_eal/common/include -W -Wall -Wstrict-prototypes -Wmissing-prototypes -Wmissing-declarations -Wold-style-definition -Wpointer-arith -Wcast-align -Wnested-externs -Wcast-qual -Wformat-nonliteral -Wformat-security -Wundef -Wwrite-strings -Wdeprecated -Wimplicit-fallthrough=2 -Wno-format-truncation -Wno-address-of-packed-member -O3    -o rte_reciprocal.o -c /home/gxh/mycode/dpdk-stable-18.11.9/lib/librte_eal/common/rte_reciprocal.c 
