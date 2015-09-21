#!/bin/bash -ex
#
source config.cfg

iphost=/etc/hosts

rm $iphost
touch $iphost
cat << EOF >> $iphost
127.0.0.1 localhost
$CON_MGNT_IP controller
$COM1_MGNT_IP compute1
$NET_MGNT_IP network
EOF

apt-get install ubuntu-cloud-keyring
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu" "trusty-updates/kilo main" > /etc/apt/sources.list.d/cloudarchive-kilo.list

apt-get update -y
apt-get upgrade -y
apt-get dist-upgrade -y

apt-get install ntp -y
apt-get install python-mysqldb -y

cp /etc/ntp.conf /etc/ntp.conf.bka
rm /etc/ntp.conf
cat /etc/ntp.conf.bka | grep -v ^# | grep -v ^$ >> /etc/ntp.conf
#
sed -i 's/server/#server/' /etc/ntp.conf
echo "server controller" >> /etc/ntp.conf
echo "net.ipv4.conf.all.rp_filter=0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.rp_filter=0" >> /etc/sysctl.conf
sysctl -p

echo "Finished"