FROM ubuntu:18.04

COPY ./mycode /root/mycode
COPY ./dpdk-stable-18.11.9 /usr/src/dpdk
COPY ./openvswitch-2.12.0 /usr/src/ovs
COPY ./libhiredis.so /usr/local/lib
COPY ./libhiredis.so.0.13 /usr/local/lib
WORKDIR /root/mycode/shell
RUN apt-get update && apt-get install -y build-essential automake python3-pip libcap-ng-dev gawk pciutils linux-headers-$(uname -a | awk '{print $3}') vim kmod numactl libnuma-dev iputils-ping net-tools
RUN pip3 install -U pip six
RUN echo '/usr/local/lib' >>/etc/ld.so.conf
RUN ldconfig
ENV PATH "$PATH:/usr/src/dpdk/x86_64-native-linuxapp-gcc/app/"
ENV DPDK_DIR "/usr/src/dpdk"
ENV DPDK_BUILD "x86_64-native-linuxapp-gcc"
ENV RTE_SDK "/usr/src/dpdk"
ENV RTE_TARGET "x86_64-native-linuxapp-gcc"
ENV OVS_DIR "/usr/src/ovs"
RUN ./build_dpdk.sh
RUN ./build_ovs.sh
#RUN ./dpdkovs.sh
#CMD ["/bin/bash"]
