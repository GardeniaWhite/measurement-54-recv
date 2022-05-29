[TOC]

# DPDK 编译安装 (v20.11.3)

>   VirtualBox 虚拟机
>
>   dpdk version: 20.11.3 LTS
>
>   OS version: ubuntu 20.04, kernel: 5.4.155
>
> - [DPDK 文档 中文翻译版](https://dpdk-docs.readthedocs.io/en/latest/linux_gsg/index.html)
> - [DPDK 文档 英文版](https://doc.dpdk.org/guides/linux_gsg/index.html)
> - [Open vSwitch with DPDK](https://docs.openvswitch.org/en/latest/intro/install/dpdk/)
> - [20.11.0安装](https://blog.csdn.net/Q93068/article/details/110581617)
> - [19.11.0安装](https://blog.csdn.net/qq_39992615/article/details/103777991)

## 1. 准备

```bash
# 获取源码
wget https://fast.dpdk.org/rel/dpdk-20.11.3.tar.xz
# 编译工具 meson ninja，从v19开始使用meson进行DPDK的编译！
sudo pip3 install meson ninja
# 还有一些依赖需要安装，但好像也没有报错
sudo apt install libnuma-dev libpcap-dev libfdt-dev 
```

## 2. 编译安装

```bash
cd dpdk-stable-20.11.3
# 编译 使用`| tee file`是将日志显示在终端的同时，保存到文件中
meson build	| tee ../meson.build
ninja -C build
# 安装库 将DPDK的相关库文件复制到根目录下的相关引用目录
sudo ninja -C build install
# 更新缓存 (usually run when a new library is installed)
sudo ldconfig
# 测试一下 libdpdk 是否安装成功
pkg-config --modversion libdpdk

# 卸载 dpdk
sudo ninja uninstall
# 清理编译过程的文件
make clean
```

## 3. 相关配置

>   [编译和运行简单应用程序](https://dpdk-docs.readthedocs.io/en/latest/linux_gsg/build_sample_apps.html)

### - 网卡

网卡使用的VirtualBox中的网络地址转换器(NAT)，设置了三个网卡。要运行任何的DPDK应用程序，需要将合适的uio模块线加载到当前内核中。在多数情况下，Linux内核包含了标准的 `uio_pci_generic` 模块就可以提供uio能力。

DPDK程序在运行前，需要将所要使用的端口绑定到 `uio_pci_generic`, `igb_uio` 或 `vfio-pci` 模块上。 任何Linux内核本身控制的端口无法被DPDK PMD驱动所使用。

```bash
# 1. 查看网卡状态
dpdk-devbind.py -s
Network devices using kernel driver
===================================
0000:00:03.0 '82540EM Gigabit Ethernet Controller 100e' if=enp0s3 drv=e1000 unused=vfio-pci *Active*
0000:00:08.0 '82540EM Gigabit Ethernet Controller 100e' if=enp0s8 drv=e1000 unused=vfio-pci *Active*
0000:00:09.0 '82540EM Gigabit Ethernet Controller 100e' if=enp0s9 drv=e1000 unused=vfio-pci *Active*
# 当前网卡为Active，使用的kernel driver，下面将其绑定到DPDK
# 2. 停用当前网卡
sudo ifconfig enp0s8 down
sudo ifconfig enp0s9 down
# 3. 绑定到DPDK，uio_pci 和 vfio_pci（更推荐后者）
sudo modprobe uio_pci_generic	# 加载uio_pci_generic模块
sudo dpdk-devbind.py --bind=uio_pci_generic 0000:00:08.0
sudo dpdk-devbind.py --bind=uio_pci_generic 0000:00:09.0
dpdk-devbind.py -s
Network devices using DPDK-compatible driver
============================================
0000:00:08.0 '82540EM Gigabit Ethernet Controller 100e' drv=uio_pci_generic unused=e1000,vfio-pci
0000:00:09.0 '82540EM Gigabit Ethernet Controller 100e' drv=uio_pci_generic unused=e1000,vfio-pci

Network devices using kernel driver
===================================
0000:00:03.0 '82540EM Gigabit Ethernet Controller 100e' if=enp0s3 drv=e1000 unused=vfio-pci,uio_pci_generic *Active*
```
如上设置后就可以在ovs中添加对应的网卡接口了，但设置为DPDK类型后，就不能正常连接外网了！

下面将网卡解绑并重新设置为正常类型！
```bash
# 1. 解绑
sudo dpdk-devbind.py -u 0000:05:00.0	# 对应网卡的id
# 2. 绑定为原来的driver
sudo dpdk-devbind.py -b RTL8125 0000:05:00.0 # 选择默认使用的driver
```

### - 大页

```bash
# 1.查看cpu是否支持大页内存，目前大页内存一般分为2M和1G
cat  /proc/cpuinfo |grep --color pse	 # 2M, 如果存在则表示支持
cat  /proc/cpuinfo |grep --color pdpe1gb # 1Gb
# 2.查看内核是否支持大页内存
grep -i hugetlb /boot/config-内核版本
CONFIG_ARCH_WANT_GENERAL_HUGETLB=y
CONFIG_CGROUP_HUGETLB=y	# 以下两种都为y则标识支持
CONFIG_HUGETLBFS=y 
CONFIG_HUGETLB_PAGE=y

# 3.设置为2M的大页1024个
sudo dpdk-hugepages.py -p 2M --setup 2G
# 查看
sudo dpdk-hugepages.py -s
cat /proc/meminfo | grep -i hugepage
```
使用dpdk-hugepages.py 配置大页时，就是修改`/sys/devices/system/node/node0/hugepages` 目录下的文件，hugepages-2048kB 是2M的大页，hugepages-1048576kB 是1GB的大页，其中的 nr_hugepages 表示要分配的大页数量，分配的大页会挂载到/dev/hugepages/。

使用过1G、2M大页后就会有上面的两个文件夹，但只能使用一种大页，如当前使用1G的大页，在运行DPDK时，如`dpdk-testpmd` 就会有`EAL: No available hugepages reported in hugepages-2048kB`提示，说没有可用的2M大页！（好像不影响什么）

### - EAL

应用程序与DPDK目标环境的环境抽象层（EAL）库相关联，该库提供了所有DPDK程序通用的一些选项如下：

```
./rte-app -c COREMASK [-n NUM] [-b <domain:bus:devid.func>] \
          [--socket-mem=MB,...] [-m MB] [-r NUM] [-v] [--file-prefix] \
          [--proc-type <primary|secondary|auto>] [-- xen-dom0]
```

选项描述如下：

-   `-c COREMASK`: 要运行的内核的十六进制掩码。如`ff:1111 1111`就是在8个内核上运行，`3:11`就是在1，2号内核运行。
-   `-n NUM`: 每个处理器插槽的内存通道数目。
-   `-b <domain:bus:devid.func>`: 端口黑名单，避免EAL使用指定的PCI设备。
-   `--use-device`: 仅使用指定的以太网设备。使用逗号分隔 `[domain:]bus:devid.func` 值，不能与 `-b` 选项一起使用。
-   `--socket-mem`: 从特定插槽上的hugepage分配内存。
-   `-m MB`: 内存从hugepage分配，不管处理器插槽。建议使用 `--socket-mem` 而非这个选项。
-   `-r NUM`: 内存数量。
-   `-v`: 显示启动时的版本信息。
-   `--huge-dir`: 挂载hugetlbfs的目录。
-   `--file-prefix`: 用于hugepage文件名的前缀文本。
-   `--proc-type`: 程序实例的类型。
-   `--xen-dom0`: 支持在Xen Domain0上运行，但不具有hugetlbfs的程序。
-   `--vmware-tsc-map`: 使用VMware TSC 映射而不是本地RDTSC。
-   `--base-virtaddr`: 指定基本虚拟地址。
-   `--vfio-intr`: 指定要由VFIO使用的中断类型。(如果不支持VFIO，则配置无效)。

## 4. examples 测试

DPDK 源码目录下提供了很多测试样例，位于`examples`文件夹中，下面以`helloworld`为例：

```bash
cd examples/helloworld
make
sudo ./build/helloworld	-c 0xf1	 # 要使用sudo运行！
EAL: Detected 8 lcore(s)
EAL: Detected 1 NUMA nodes
EAL: Detected shared linkage of DPDK
EAL: Multi-process socket /var/run/dpdk/rte/mp_socket
EAL: Selected IOVA mode 'PA'
EAL: Probing VFIO support...
EAL: VFIO support initialized
EAL: Probe PCI driver: net_e1000_em (8086:100e) device: 0000:00:08.0 (socket 0)
EAL: Probe PCI driver: net_e1000_em (8086:100e) device: 0000:00:09.0 (socket 0)
EAL: No legacy callbacks, legacy socket not created
hello from core 1
hello from core 2
hello from core 0
```

## 5. pktgen 编译安装

pktgen也是基于DPDK的一个子项目，用于生成测试流量，在DPDK官网的[hosted-projects](https://www.dpdk.org/hosted-projects/)中可以找到，[download pages](https://git.dpdk.org/apps/pktgen-dpdk/refs/) 中选择与上面安装的DPDK同一版本安装，注意`20.11.x`中只有`20.11.3`才能用，`20.11.0/1`在编译pktgen时会报错。

## 6. DPDK+pktgen 镜像

[Dockerfile](https://github.com/Yo-gurts/pktgen-lua-container/blob/main/Dockerfile) 如下：

```dockerfile
# 指定使用的DPDK, pktgen 版本
ARG dpdk_version=20.11.3
ARG pktgen_version=20.11.3

FROM ubuntu:20.04 as build
ARG dpdk_version
ARG pktgen_version

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get -y install build-essential python3-pip liblua5.3-dev \
  cmake wget libnuma-dev pciutils libpcap-dev libelf-dev linux-headers-generic \
  && pip3 install meson ninja pyelftools
#  cmake wget libnuma-dev pciutils libpcap-dev libelf-dev linux-headers-`uname -r` \

ENV DPDK_VER=$dpdk_version
ENV PKTGEN_VER=$pktgen_version
ENV RTE_SDK=/opt/dpdk-stable-$DPDK_VER
RUN echo DPDK_VER=${DPDK_VER}
RUN echo PKTGEN_VER=${PKTGEN_VER}

WORKDIR /opt

# downloading and unpacking DPDK
RUN wget -q https://fast.dpdk.org/rel/dpdk-$DPDK_VER.tar.xz && tar xf dpdk-$DPDK_VER.tar.xz

# build & install DPDK ...
RUN cd $RTE_SDK \
   && meson build \
   && ninja -C build \
   && ninja -C build install \
   && cp -r build/lib /usr/local/

# patch to make pktgen compile on arm. Got tip from
# https://medium.com/codex/nvidia-mellanox-bluefield-2-smartnic-dpdk-rig-for-dive-part-ii-change-mode-of-operation-a994f0f0e543
RUN sed -i 's/#  error Platform.*//' /usr/local/include/rte_spinlock.h
RUN sed -i 's/#  error Platform.*//' /usr/local/include/rte_atomic_32.h

# downlaod and unpack pktgen
RUN wget -q https://git.dpdk.org/apps/pktgen-dpdk/snapshot/pktgen-dpdk-pktgen-$PKTGEN_VER.tar.gz \
   && tar xf pktgen-dpdk-pktgen-$PKTGEN_VER.tar.gz

# building pktgen
RUN cd pktgen-dpdk-pktgen-$PKTGEN_VER \
      && tools/pktgen-build.sh clean \
      && tools/pktgen-build.sh buildlua \
      && cp -r usr/local /usr/ \
      && mkdir -p /usr/local/share/lua/5.3/ \
      && cp Pktgen.lua /usr/local/share/lua/5.3/

#####################################################
FROM ubuntu:20.04
ARG dpdk_version
ENV DPDK_VER=$dpdk_version

COPY --from=build /usr/local /usr/local/

RUN apt-get update \
  && apt-get -y --no-install-recommends install liblua5.3 libnuma-dev pciutils libpcap-dev python3 iproute2 \
  && ldconfig
```

编译`docker`镜像：`docker build -t pktgen20 .`

# OVS DPDK 编译安装

由于这里我们使用DPDK datapath，没有内核datapath，所以也就不用执行 `make modules_install` 去安装内核模块！

```bash
# get ovs v2.16.0
wget https://github.com/openvswitch/ovs/archive/refs/tags/v2.16.0.zip 
# 安装依赖包
sudo apt install build-essential fakeroot
dpkg-checkbuilddeps	# 检查依赖并手动安装缺少的模块
./boot.sh
./configure --with-dpdk=static CFLAGS="-Ofast -msse4.2 -mpopcnt"

# 开始编译
make
# 单元测试（可以跳过）
make check TESTSUITEFLAGS=-j8
# 安装
sudo make install
```

## OVS 默认路径

在`v2.16.0`中使用的主要路径有：

-   `/usr/local/etc/openvswitch/`
-   `/usr/local/var/run/openvswitch/`
-   `/usr/local/var/log/openvsiwtch/`

若要清空配置，只需要删除相关目录下的文件即可！

```bash
rm /usr/local/etc/openvswitch/*
rm /usr/local/var/run/openvswitch/*
```

## 以DPDK启动OVS

```bash
# 0. 设置hugepages
dpdk-hugepages.py -p 1G --setup 8G

export PATH=$PATH:/usr/local/share/openvswitch/scripts
export DB_SOCK=/usr/local/var/run/openvswitch/db.sock

# 1. 启动ovsdb，先不启动ovs-vswitchd
ovs-ctl --no-ovs-vswitchd --system-id=random start

# 2. 配置使用DPDK，可以配置从任何给定 NUMA 节点使用的内存量
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem="1024"
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true

# 3. 启动ovs-vswitchd
ovs-ctl --no-ovsdb-server --db-sock="$DB_SOCK" start

# 4. 验证DPDK是否启用，启用输出 true
ovs-vsctl get Open_vSwitch . dpdk_initialized
ovs-vswitchd --version
# ovs-vswitchd (Open vSwitch) 2.16.0
# DPDK 20.11.3
```

主要的参数有：

-   dpdk-init：指定ovs是否初始化和支持dpdk端口。
-   dpdk-lcore-mask：指明lcore使用的逻辑核，用于处理 dpdk library task。同dpdk的-c参数。
-   pmd-cpu-mask：指明pmd使用的cpu核，未指定时每个numa自动分配一个核。
-   dpdk-socket-mem：指明不同numa节点提前申请的大页内存。同dpdk的--socket-mem参数。
-   dpdk-hugepage-dir：大页文件系统mount的目录。同dpdk的--huge-dir参数。
-   vhost-sock-dir：设置vhost-user 套接字的路径。
-   dpdk-extra：其他的dpdk配置参数。
-   tx-flush-interval：指定一个包可以等待的时间，us。
-   smc-enable：true/false。

## 添加端口

端口类型主要有：

-   `dpdk`：物理端口，需要指定对应的`dpdk-devargs`；
-   `dpdkvhostuser`：virtio虚拟化的后端，与虚拟机中的前端配合使用（不推荐使用）；
-   `dpdkvhostuserclient`：virtio虚拟化的前端，虚拟机中的部署后端（推荐）。

```bash
ovs-vsctl add-br br0 \
    -- set bridge br0 datapath_type=netdev

ovs-vsctl add-port br0 myportnameone \
    -- set Interface myportnameone type=dpdk \
       options:dpdk-devargs=0000:08:00.0

ovs-vsctl add-port br0 dpdkvhostclient0 \
    -- set Interface dpdkvhostclient0 type=dpdkvhostuserclient \
       options:vhost-server-path=/tmp/dpdkvhostclient0
       
ovs-vsctl add-port br0 dpdkvhost1 \
    -- set Interface dpdkvhost1 type=dpdkvhostuser \
       options:vhost-server-path=/tmp/dpdkvhost1
```

## OVS Logger Level设置

>   https://www.xmodulo.com/enable-logging-open-vswitch.html

可以使用命令行工具在运行时动态配置 OVS 日志记录`ovs-appctl`。

`ovs-appctl`自定义 VLOG的语法如下。

```bash
$ sudo ovs-appctl vlog/set module[:facility[:level]]
```

-   **module：**在OVS任何有效成分的名称（例如`netdev`，`ofproto`，`dpif`，`vswitchd`，和许多其他人）
-   **facility：**日志信息的目的地（必须是：控制台、系统日志或文件）
-   **level：**日志的详细程度（必须是：emer、err、warn、info 或 dbg）

在 OVS 源代码中，模块名称在每个源文件中定义的形式为：

```c
VLOG_DEFINE_THIS_MODULE(<module-name>);
```

在 OVS 源代码中，有多个严重级别用于定义几种不同类型的日志消息：`VLOG_INFO()`用于信息、`VLOG_WARN()`用于警告、`VLOG_ERR()`用于错误、`VLOG_DBG()`用于调试、`VLOG_EMERG`用于紧急情况。日志级别和设施决定了哪些日志消息发送到哪里。

要查看可用模块、设施及其各自日志记录级别的完整列表，请运行以下命令。必须在启动 OVS 后调用此命令。

```bash
$ ovs-appctl vlog/list
                 console    syslog    file
                 -------    ------    ------
backtrace          OFF        ERR       INFO
bfd                OFF        ERR       INFO
bond               OFF        ERR       INFO
bridge             OFF        ERR       INFO
bundle             OFF        ERR       INFO
bundles            OFF        ERR       INFO
cfm                OFF        ERR       INFO
collectors         OFF        ERR       INFO
command_line       OFF        ERR       INFO
connmgr            OFF        ERR       INFO
conntrack          OFF        ERR       INFO
conntrack_tp       OFF        ERR       INFO
coverage           OFF        ERR       INFO
ct_dpif            OFF        ERR       INFO
daemon             OFF        ERR       INFO
daemon_unix        OFF        ERR       INFO
dns_resolve        OFF        ERR       INFO
dpdk               OFF        ERR       INFO
dpif               OFF        ERR       INFO
dpif_lookup_autovalidator   OFF        ERR       INFO
dpif_lookup_avx512_gather   OFF        ERR       INFO
dpif_lookup_generic   OFF        ERR       INFO
dpif_mfex_extract_study   OFF        ERR       INFO
dpif_netdev        OFF        ERR       INFO
dpif_netdev_extract   OFF        ERR       INFO
dpif_netdev_impl   OFF        ERR       INFO
dpif_netdev_lookup   OFF        ERR       INFO
dpif_netlink       OFF        ERR       INFO
dpif_netlink_rtnl   OFF        ERR       INFO
entropy            OFF        ERR       INFO
fail_open          OFF        ERR       INFO
fatal_signal       OFF        ERR       INFO
flow               OFF        ERR       INFO
hmap               OFF        ERR       INFO
in_band            OFF        ERR       INFO
ipf                OFF        ERR       INFO
ipfix              OFF        ERR       INFO
jsonrpc            OFF        ERR       INFO
lacp               OFF        ERR       INFO
lldp               OFF        ERR       INFO
lldpd              OFF        ERR       INFO
lldpd_structs      OFF        ERR       INFO
lockfile           OFF        ERR       INFO
memory             OFF        ERR       INFO
meta_flow          OFF        ERR       INFO
native_tnl         OFF        ERR       INFO
netdev             OFF        ERR       INFO
netdev_dpdk        OFF        ERR       INFO
netdev_dummy       OFF        ERR       INFO
netdev_linux       OFF        ERR       INFO
netdev_offload     OFF        ERR       INFO
netdev_offload_dpdk   OFF        ERR       INFO
netdev_offload_tc   OFF        ERR       INFO
netdev_vport       OFF        ERR       INFO
netflow            OFF        ERR       INFO
netlink            OFF        ERR       INFO
netlink_conntrack   OFF        ERR       INFO
netlink_notifier   OFF        ERR       INFO
netlink_socket     OFF        ERR       INFO
nx_match           OFF        ERR       INFO
odp_execute        OFF        ERR       INFO
odp_util           OFF        ERR       INFO
ofp_actions        OFF        ERR       INFO
ofp_bundle         OFF        ERR       INFO
ofp_connection     OFF        ERR       INFO
ofp_errors         OFF        ERR       INFO
ofp_flow           OFF        ERR       INFO
ofp_group          OFF        ERR       INFO
ofp_match          OFF        ERR       INFO
ofp_meter          OFF        ERR       INFO
ofp_monitor        OFF        ERR       INFO
ofp_msgs           OFF        ERR       INFO
ofp_packet         OFF        ERR       INFO
ofp_port           OFF        ERR       INFO
ofp_protocol       OFF        ERR       INFO
ofp_queue          OFF        ERR       INFO
ofp_table          OFF        ERR       INFO
ofp_util           OFF        ERR       INFO
ofproto            OFF        ERR       INFO
ofproto_dpif       OFF        ERR       INFO
ofproto_dpif_mirror   OFF        ERR       INFO
ofproto_dpif_monitor   OFF        ERR       INFO
ofproto_dpif_rid   OFF        ERR       INFO
ofproto_dpif_upcall   OFF        ERR       INFO
ofproto_dpif_xlate   OFF        ERR       INFO
ofproto_xlate_cache   OFF        ERR       INFO
ovs_lldp           OFF        ERR       INFO
ovs_numa           OFF        ERR       INFO
ovs_rcu            OFF        ERR       INFO
ovs_replay         OFF        ERR       INFO
ovs_router         OFF        ERR       INFO
ovs_thread         OFF        ERR       INFO
ovsdb_cs           OFF        ERR       INFO
ovsdb_error        OFF        ERR       INFO
ovsdb_idl          OFF        ERR       INFO
ox_stat            OFF        ERR       INFO
pcap               OFF        ERR       INFO
pmd_perf           OFF        ERR       INFO
poll_loop          OFF        ERR       INFO
process            OFF        ERR       INFO
rconn              OFF        ERR       INFO
reconnect          OFF        ERR       INFO
route_table        OFF        ERR       INFO
rstp               OFF        ERR       INFO
rstp_sm            OFF        ERR       INFO
sflow              OFF        ERR       INFO
signals            OFF        ERR       INFO
socket_util        OFF        ERR       INFO
socket_util_unix   OFF        ERR       INFO
stp                OFF        ERR       INFO
stream             OFF        ERR       INFO
stream_fd          OFF        ERR       INFO
stream_replay      OFF        ERR       INFO
stream_ssl         OFF        ERR       INFO
stream_tcp         OFF        ERR       INFO
stream_unix        OFF        ERR       INFO
svec               OFF        ERR       INFO
system_stats       OFF        ERR       INFO
tc                 OFF        ERR       INFO
timeval            OFF        ERR       INFO
tunnel             OFF        ERR       INFO
unixctl            OFF        ERR       INFO
userspace_tso      OFF        ERR       INFO
util               OFF        ERR       INFO
uuid               OFF        ERR       INFO
vconn              OFF        ERR       INFO
vconn_stream       OFF        ERR       INFO
vlog               OFF        ERR       INFO
vswitchd           OFF        ERR       INFO
xenserver          OFF        ERR       INFO
```

给定任何一个 OVS 模块，您可以有选择地更改任何特定设施的调试级别：

```bash
$ ovs-appctl vlog/set netdev_dpdk:file:dbg
```



# 实验一

网络拓扑如下，在主机上部署`dpdk openvswitch`软交换机，添加四个`vhostuser`端口，并添加`flow`使流量按下图的方式转发。另启动两个docker作为虚拟机，并在其中一个部署了数据包生成发送模块`pktgen`。而另一个`docker`中使用`testpmd`来接收数据包。

![img](../images/DPDK_%E7%BC%96%E8%AF%91%E5%AE%89%E8%A3%85/2018-8-17-1.jpg)

1.  [以DPDK启动OVS](#以DPDK启动OVS)

2.  环境清理

    ```bash
    ovs-ofctl del-flows br0                    # 清空流表
    ovs-ofctl -O OpenFlow15 del-meters br0     # 删除meter表
    ovs-vsctl del-br br0                       # 删除bridge
    ovs-vsctl -- --all destroy QoS -- --all destroy Queue   # 清除所有队列和QoS
    ```

3.  创建环境，OVS添加端口、流表

    ```bash
    # 添加 bridge
    ovs-vsctl add-br br0 \
        -- set bridge br0 datapath_type=netdev
    
    ovs-vsctl add-port br0 vhost-user1 \
        -- set Interface vhost-user1 type=dpdkvhostuser ofport_request=1
    ovs-vsctl add-port br0 vhost-user2 \
        -- set Interface vhost-user2 type=dpdkvhostuser ofport_request=2
    ovs-vsctl add-port br0 vhost-user3 \
        -- set Interface vhost-user3 type=dpdkvhostuser ofport_request=3
    ovs-vsctl add-port br1 vhost-user4 \
        -- set Interface vhost-user4 type=dpdkvhostuser ofport_request=4
    ovs-vsctl show
    
    #添加patch端口，以下两步会报错，提示error detected while setting up... 不用理会
    ovs-vsctl add-port br0 patch2-0
    ovs-vsctl add-port br0 patch0-2
    #设置端口的类型为patch
    ovs-vsctl set Interface patch2-0 type=patch
    ovs-vsctl set Interface patch0-2 type=patch
    #设置端口的对端
    ovs-vsctl set Interface patch2-0 option:peer=patch0-2
    ovs-vsctl set Interface patch0-2 option:peer=patch2-0
    
    
    
    
    ovs-ofctl add-flow br0 in_port=2,dl_type=0x800,idle_timeout=0,action=set_queue:2,output:3
    ovs-ofctl add-flow br0 in_port=3,dl_type=0x800,idle_timeout=0,action=set_queue:3,output:2
    ovs-ofctl add-flow br0 in_port=1,dl_type=0x800,idle_timeout=0,action=set_queue:1,output:4
    ovs-ofctl add-flow br0 in_port=4,dl_type=0x800,idle_timeout=0,action=set_queue:4,output:1
    ```

4.  启动容器

    ```bash
    # pktgen 
    docker run -it --rm --privileged --name=app-pktgen \
        -v /dev/hugepages:/dev/hugepages \
        -v /usr/local/var/run/openvswitch:/var/run/openvswitch \
        pktgen20:latest /bin/bash
    
    # testpmd
    docker run -it --rm --privileged --name=app-testpmd \
        -v /dev/hugepages:/dev/hugepages \
        -v /usr/local/var/run/openvswitch:/var/run/openvswitch \
        pktgen20:latest /bin/bash
    ```

5.  `pktgen`容器中运行

    ```bash
    pktgen -c 0x19 --main-lcore 3 -n 1 --socket-mem 1024 --file-prefix pktgen --no-pci  \
    --vdev 'net_virtio_user1,mac=00:00:00:00:00:01,path=/var/run/openvswitch/vhost-user1' \
    --vdev 'net_virtio_user2,mac=00:00:00:00:00:02,path=/var/run/openvswitch/vhost-user2'  \
    -- -T -P -m "0.0,4.1"
    
    Pktgen:/> start all
    
    Pktgen:/> stop all
    Pktgen:/> quit
    ```

6.  `testpmd`容器中运行

    -   --coremask 设置运行数据包转发测试的内核
    -   -i 以交互模式运行 testpmd。在此模式下，testpmd 以提示符开始，可用于启动和停止转发、配置应用程序并显示当前数据包处理会话的统计信息。

    ```bash
    dpdk-testpmd -c 0xE0 -n 1 --socket-mem 1024 --file-prefix testpmd --no-pci --vdev \
    'net_virtio_user3,mac=00:00:00:00:00:03,path=/var/run/openvswitch/vhost-user3' --vdev \
    'net_virtio_user4,mac=00:00:00:00:00:04,path=/var/run/openvswitch/vhost-user4' -- -i -a --coremask=0xc0
    
    testpmd> show port stats all
    testpmd> quit
    ```

7.  参考文献：
    1.  *[Docker-DPDK-OVS](https://datawine.github.io/2018/07/22/Docker-DPDK-OVS/)*
    2.  *[Run testpmd and pktgen Inside Separate Docker Containers | Intel Software](https://www.youtube.com/watch?v=gkCMk-1m3HA)*

# 实验二

```bash
# 以DPDK启动OVS

## 0. 设置hugepages
dpdk-hugepages.py -p 1G --setup 4G

## 1. 启动ovsdb，先不启动ovs-vswitchd
ovs-ctl --no-ovs-vswitchd start

## 2. 配置使用DPDK，可以配置从任何给定 NUMA 节点使用的内存量
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem="1024"
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true

## 3. 启动ovs-vswitchd
ovs-ctl --no-ovsdb-server --db-sock="$DB_SOCK" start

## 4. 设置日志级别
ovs-appctl vlog/set dpif_netdev:file:dbg

## 5. 添加 bridge
ovs-vsctl add-br br0 -- set bridge br0 datapath_type=netdev

ovs-vsctl add-port br0 vhost-user1 \
    -- set Interface vhost-user1 type=dpdkvhostuser ofport_request=1
ovs-vsctl add-port br0 vhost-user2 \
    -- set Interface vhost-user2 type=dpdkvhostuser ofport_request=2
ovs-vsctl add-port br0 vhost-user3 \
    -- set Interface vhost-user3 type=dpdkvhostuser ofport_request=3
ovs-vsctl add-port br0 vhost-user4 \
    -- set Interface vhost-user4 type=dpdkvhostuser ofport_request=4
ovs-vsctl show

## 6. 添加流表
ovs-ofctl del-flows br0  # 删除当前流表
ovs-ofctl add-flow br0 in_port=2,dl_type=0x800,idle_timeout=0,action=set_queue:2,output:3
ovs-ofctl add-flow br0 in_port=3,dl_type=0x800,idle_timeout=0,action=set_queue:3,output:2
ovs-ofctl add-flow br0 in_port=1,dl_type=0x800,idle_timeout=0,action=set_queue:1,output:4
ovs-ofctl add-flow br0 in_port=4,dl_type=0x800,idle_timeout=0,action=set_queue:4,output:1

## 7. 启动容器

# pktgen 
docker run -it --rm --privileged --name=app-pktgen \
    -v /dev/hugepages:/dev/hugepages \
    -v /usr/local/var/run/openvswitch:/var/run/openvswitch \
    pktgen20:latest /bin/bash

# testpmd
docker run -it --rm --privileged --name=app-testpmd \
    -v /dev/hugepages:/dev/hugepages \
    -v /usr/local/var/run/openvswitch:/var/run/openvswitch \
    pktgen20:latest /bin/bash


```



# QEMU

1. [Qemu 官方文档](https://www.qemu.org/docs/master/)
2. [Qemu 入门指南](https://blog.csdn.net/FontThrone/article/details/104157859)
3. [使用Qemu](https://my.oschina.net/kelvinxupt/blog/265108)

## 安装

~~在大多数Linux发行版中都有QEMU的安装包！~~

```bash
# sudo apt install qemu
```

Ubuntu中使用上面的命令无效，下面选择从源码编译的方式安装，选择5.0.0版本：

```bash
wget https://download.qemu.org/qemu-5.0.0.tar.xz

sudo apt install libpixman-1-dev 
./configure --enable-kvm --enable-debug --enable-vnc --enable-werror  --target-list="x86_64-softmmu"
make -j8
sudo make install
```

至此，安装完成:happy:

上面的`configure`脚本用于生成`Makefile`，其选项可以用`./configure --help`查看。

## 创建磁盘映像

这里说的磁盘映像就像是`VirtualBox`中的虚拟硬盘！QEMU 支持许多磁盘映像格式，包括可增长的磁盘映像（它们的大小随着写入非空扇区而增加）、压缩和加密的磁盘映像。请参阅`qemu-img -h`查看更多信息。

```bash
qemu-img create fedora35.img 20G
```

## 启动虚拟机

磁盘映像文件创建完成后，可使用qemu-system-x86来启动x86架构的虚拟机。

```bash
$ qemu-system-x86_64 fedora35.img 
WARNING: Image format was not specified for 'fedora35.img' and probing guessed raw.
         Automatically detecting the format is dangerous for raw images, write operations on block 0 will be restricted.
         Specify the 'raw' format explicitly to remove the restrictions.
VNC server running on 127.0.0.1:5900
```

这个版本并没有图形窗口，而是启动了一个VNC Server，需要下载[VNC Viewer](https://www.realvnc.com/en/connect/download/viewer/linux/)连接使用。

因为fedora.img中并未给虚拟机安装操作系统，所以会提示“No bootable device”，无可启动设备。

下面以指定操作系统镜像的方式启动：

```bash
qemu-system-x86_64 -m 2048 -enable-kvm fedora.img -cdrom Fedora-Workstation-Live-x86_64-35-1.2.iso
```

