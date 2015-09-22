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

apt-get -y install ubuntu-cloud-keyring
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu" "trusty-updates/kilo main" > /etc/apt/sources.list.d/cloudarchive-kilo.list

apt-get update -y
apt-get upgrade -y
apt-get dist-upgrade -y

apt-get install ntp -y
cp /etc/ntp.conf /etc/ntp.conf.bka
rm /etc/ntp.conf
cat /etc/ntp.conf.bka | grep -v ^# | grep -v ^$ >> /etc/ntp.conf

## Config NTP in KILO
sed -i 's/server ntp.ubuntu.com/ \
server 0.vn.pool.ntp.org iburst \
server 1.asia.pool.ntp.org iburst \
server 2.asia.pool.ntp.org iburst/g' /etc/ntp.conf

sed -i 's/restrict -4 default kod notrap nomodify nopeer noquery/ \
#restrict -4 default kod notrap nomodify nopeer noquery/g' /etc/ntp.conf

sed -i 's/restrict -6 default kod notrap nomodify nopeer noquery/ \
restrict -4 default kod notrap nomodify \
restrict -6 default kod notrap nomodify/g' /etc/ntp.conf

apt-get install rabbitmq-server -y
rabbitmqctl change_password guest $RABBIT_PASS
sleep 3
rabbitmqctl set_permissions openstack ".*" ".*" ".*"
sleep 3
service rabbitmq-server restart
echo "Finish"