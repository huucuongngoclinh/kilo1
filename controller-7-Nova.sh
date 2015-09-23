#!/bin/bash -ex
#

source config.cfg
apt-get -y install nova-api nova-cert nova-conductor nova-consoleauth nova-novncproxy nova-scheduler python-novaclient
apt-get install libguestfs-tools -y
#
controlnova=/etc/nova/nova.conf
rm $controlnova
touch $controlnova
cat << EOF >> $controlnova
[DEFAULT]

dhcpbridge_flagfile=/etc/nova/nova.conf
dhcpbridge=/usr/bin/nova-dhcpbridge
logdir=/var/log/nova
state_path=/var/lib/nova
lock_path=/var/lock/nova
force_dhcp_release=True
iscsi_helper=tgtadm
libvirt_use_virtio_for_bridges=True
connection_type=libvirt
root_helper=sudo nova-rootwrap /etc/nova/rootwrap.conf
verbose=True
ec2_private_dns_show_ip=True
api_paste_config=/etc/nova/api-paste.ini
volumes_path=/var/lib/nova/volumes
enabled_apis=ec2,osapi_compute,metadata
auth_strategy = keystone

rpc_backend = rabbit
#rabbit_host = controller
#rabbit_password = $RABBIT_PASS

my_ip = $CON_MGNT_IP
vncserver_listen = $CON_MGNT_IP
vncserver_proxyclient_address = $CON_MGNT_IP

resume_guests_state_on_host_boot=True

libvirt_inject_password = True
libvirt_inject_partition = -1
enable_instance_password = True
network_api_class = nova.network.neutronv2.api.API
neutron_url = http://controller:9696
neutron_auth_strategy = keystone
neutron_admin_tenant_name = service
neutron_admin_username = neutron
neutron_admin_password = $ADMIN_PASS
neutron_admin_auth_url = http://controller:35357/v2.0
linuxnet_interface_driver = nova.network.linux_net.LinuxOVSInterfaceDriver
firewall_driver = nova.virt.firewall.NoopFirewallDriver
security_group_api = neutron
service_neutron_metadata_proxy = true
neutron_metadata_proxy_shared_secret = $METADATA_SECRET

network_api_class = nova.network.neutronv2.api.API

[oslo_messaging_rabbit]
rabbit_host = controller
rabbit_userid = openstack
rabbit_password = $RABBIT_PASS

[database]
connection = mysql://nova:$ADMIN_PASS@controller/nova

[keystone_authtoken]
auth_uri = http://controller:5000
#auth_host = controller
#auth_port = 35357
#auth_protocol = http
#admin_tenant_name = service
#admin_user = nova
#admin_password = $ADMIN_PASS
auth_url = http://controller:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
project_name = service
username = nova
password = $NOVA_PASS

[glance]
host = $CON_MGNT_IP

[oslo_concurrency]
lock_path = /var/lock/nova

[neutron]
url = http://controller:9696
auth_strategy = keystone
admin_auth_url = http://$CON_MGNT_IP:35357/v2.0
admin_tenant_name = service
admin_username = neutron
admin_password = $NEUTRON_PASS
service_metadata_proxy = True
metadata_proxy_shared_secret = $METADATA_SECRET

EOF

rm /var/lib/nova/nova.sqlite
sleep 5
nova-manage db sync
sleep 7
echo 'kvm_intel' >> /etc/modules
sleep 5
service nova-api restart
service nova-cert restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart
sleep 5
service nova-api restart
service nova-cert restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart

nova-manage service list
echo "Finished"