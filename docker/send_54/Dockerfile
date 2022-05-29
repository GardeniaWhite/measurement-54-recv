FROM ubuntu:18.04
COPY ./mycode /root/mycode
COPY ./dpdk-stable-20.11.3 /usr/src/dpdk
COPY ./ovs-2.16.0 /usr/src/ovs
WORKDIR /root/mycode/shell
RUN apt-get update && apt-get install -y build-essential automake python3-pip libcap-ng-dev gawk pciutils linux-headers-$(uname -a | awk '{print $3}') vim kmod numactl libnuma-dev iputils-ping net-tools cmake wget libpcap-dev libelf-dev golang git
RUN pip3 install -U pip six meson ninja
#RUN go get github.com/google/gopacket/layers github.com/google/gopacket github.com/google/gopacket/pcap encoding/json
ENV DPDK_DIR "/usr/src/dpdk"
ENV RTE_SDK "/usr/src/dpdk"
ENV OVS_DIR "/usr/src/ovs"
RUN ./build_dpdk.sh
RUN ./build_ovs.sh
#RUN ./dpdkovs.sh
#CMD ["/bin/bash"]
