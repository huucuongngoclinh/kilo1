#!/bin/bash -ex

source config.cfg
SERVICE_ID=`keystone tenant-get service | awk '$2~/^id/{print $4}'`

apt-get -y install neutron-server neutron-plugin-ml2 python-neutronclient

#
controlneutron=/etc/neutron/neutron.conf
rm $controlneutron
touch $controlneutron
cat << EOF >> $controlneutron
[DEFAULT]

#rpc_backend = neutron.openstack.common.rpc.impl_kombu
rpc_backend = rabbit
rabbit_host = controller
rabbit_password = $RABBIT_PASS
state_path = /var/lib/neutron
lock_path = \$state_path/lock
core_plugin = neutron.plugins.ml2.plugin.Ml2Plugin
notification_driver = neutron.openstack.common.notifier.rpc_notifier
verbose = True
auth_strategy = keystone
notify_nova_on_port_status_changes = True
notify_nova_on_port_data_changes = True
nova_url = http://controller:8774/v2
nova_admin_username = nova
nova_admin_tenant_id = $SERVICE_ID
nova_admin_password = $ADMIN_PASS
nova_admin_auth_url = http://controller:35357/v2.0
core_plugin = ml2
service_plugins = router
allow_overlapping_ips = True

[matchmaker_redis]
[matchmaker_ring]
[quotas]

[agent]
root_helper = sudo /usr/bin/neutron-rootwrap /etc/neutron/rootwrap.conf

[keystone_authtoken]
auth_uri = http://controller:5000
#auth_host = controller
#auth_protocol = http
#auth_port = 35357
#admin_tenant_name = service
#admin_user = neutron
#admin_password = $ADMIN_PASS
signing_dir = \$state_path/keystone-signing

auth_url = http://$CON_MGNT_IP:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
project_name = service
username = neutron
password = $NEUTRON_PASS

[database]
connection = mysql://neutron:$NEUTRON_PASS@controller/neutron

[nova]
auth_url = http://$CON_MGNT_IP:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
region_name = RegionOne
project_name = service
username = nova
password = $NOVA_PASS

[oslo_concurrency]
lock_path = \$state_path/lock
[oslo_policy]
[oslo_messaging_amqp]
[oslo_messaging_qpid]

[oslo_messaging_rabbit]
rabbit_host = $CON_MGNT_IP
rabbit_userid = openstack
rabbit_password = $RABBIT_PASS

#[service_providers]
#service_provider=LOADBALANCER:Haproxy:neutron.services.loadbalancer.drivers.haproxy.plugin_driver.HaproxyOnHostPluginDriver:default
#service_provider=VPN:openswan:neutron.services.vpn.service_drivers.ipsec.IPsecVPNDriver:default
EOF

echo "########## ML2 ##########"
controlML2=/etc/neutron/plugins/ml2/ml2_conf.ini
rm $controlML2
touch $controlML2
cat << EOF >> $controlML2
[ml2]
type_drivers = flat,vlan,gre,vxlan
tenant_network_types = gre
mechanism_drivers = openvswitch

[ml2_type_flat]
[ml2_type_vlan]
[ml2_type_gre]
tunnel_id_ranges = 1:1000

[ml2_type_vxlan]

[securitygroup]
enable_security_group = True
enable_ipset = True
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
EOF

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
sleep 7

service nova-api restart
service nova-scheduler restart
service nova-conductor restart
service neutron-server restart
echo "Finished"