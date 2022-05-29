#!/bin/bash
export PATH=$PATH:/usr/local/share/openvswitch/scripts;
export DB_SOCK=/usr/local/var/run/openvswitch/db.sock;
ovs-ctl stop;
ovs-ctl --no-ovs-vswitchd --system-id=random start;
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem="1024";
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true;
ovs-ctl --no-ovsdb-server --db-sock="$DB_SOCK" start;
ovs-vsctl get Open_vSwitch . dpdk_initialized;
ovs-ofctl add-flow br0 in_port=myportnameone,eth_type=0x8847,actions=pop_mpls:0x0800,output=LOCAL;

