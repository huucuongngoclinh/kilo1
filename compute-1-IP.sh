#!/bin/bash -ex
source config.cfg

echo "compute1" > /etc/hostname
hostname -F /etc/hostname
ifaces=/etc/network/interfaces
rm $ifaces
touch $ifaces
cat << EOF >> $ifaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
address $COM1_MGNT_IP
netmask $NETMASK_ADD

auto eth1
iface eth1 inet static
address $COM1_EXT_IP
netmask $NETMASK_ADD
gateway $GATEWAY_IP
dns-nameservers 8.8.8.8

auto eth2
iface eth2 inet static
address $COM1_DATA_VM_IP
netmask $NETMASK_ADD
EOF

init 6