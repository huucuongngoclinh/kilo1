#!/bin/bash -ex
echo "########## policy ##########"
nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
nova secgroup-add-rule default udp 1 65535 0.0.0.0/0

neutron net-create ext_net --router:external True --shared

neutron subnet-create --name sub_ext_net ext_net 192.168.$ID.0/24 --gateway 192.168.$ID.2 --allocation-pool start=192.168.$ID.200,end=192.168.$ID.250 --enable_dhcp=False --dns-nameservers list=true 8.8.8.8 8.8.4.4 210.245.0.11
neutron net-create int_net
sleep 3
neutron subnet-create int_net --name int_subnet --dns-nameserver 8.8.8.8 172.16.10.0/24
sleep 3
neutron router-create router_1
sleep 3
neutron router-gateway-set router_1 ext_net
sleep 3
neutron router-interface-add router_1 int_subnet
sleep 3

ID_int_net=`neutron net-list | awk '/int*/ {print $2}'`

nova boot test --image cirros-0.3.2-x86_64 --flavor 1 --security-groups default --nic net-id=$ID_int_net

sleep 10
nova list
echo "Finished"
