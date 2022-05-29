#!/bin/bash
ifconfig enp0s8 down;
modprobe uio_pci_generic;
./usertools/dpdk-devbind.py  --bind=uio_pci_generic 0000:00:08.0;
echo 2048 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages;
mount -t hugetlbfs nodev /mnt/huge/;
cat /proc/meminfo | grep -i hugepage;
