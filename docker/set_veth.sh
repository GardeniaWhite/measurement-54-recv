send=`docker inspect -f '{{.State.Pid}}' tender_mirzakhani` 
recv=`docker inspect -f '{{.State.Pid}}' loving_lewin`
sudo mkdir -p /var/run/netns
sudo ln -s /proc/${send}/ns/net /var/run/netns/${send}
sudo ln -s /proc/${recv}/ns/net /var/run/netns/${recv}
sudo ip link add A type veth peer name B
sudo ip link set A netns ${send}
sudo ip netns exec ${send} ip addr add 10.1.1.1/32 dev A
sudo ip netns exec ${send} ip link set A up
sudo ip netns exec ${send} ip route add 10.1.1.2/32 dev A
sudo ip link set B netns ${recv}
sudo ip netns exec ${recv} ip addr add 10.1.1.2/32 dev B
sudo ip netns exec ${recv} ip link set B up
sudo ip netns exec ${recv} ip route add 10.1.1.1/32 dev B
