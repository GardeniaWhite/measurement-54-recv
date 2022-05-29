#!/bin/bash
export PATH=$PATH:/usr/local/share/openvswitch/scripts;
export DB_SOCK=/usr/local/var/run/openvswitch/db.sock;
ovs-ctl stop;
ovs-ctl --no-ovs-vswitchd --system-id=random start;
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem="1024";
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true;
ovs-ctl --no-ovsdb-server --db-sock="$DB_SOCK" start;
ovs-vsctl get Open_vSwitch . dpdk_initialized;
ovs-vsctl del-br br0
ovs-vsctl add-br br0 -- set bridge br0 datapath_type=netdev
ovs-vsctl add-port br0 myportnameone -- set Interface myportnameone type=dpdk \
        options:dpdk-devargs=0000:00:08.0
ovs-ofctl add-flow br0 in_port=myportnameone,eth_type=0x8847,actions=pop_mpls:0x0800,output=LOCAL;
ifconfig br0 192.168.57.12/24
