#!/bin/bash
NODES_FILE=nodes-13.yaml
ROLES_FILE=roles_data-13.yaml
if [ $(awk '{print $6}' /etc/rhosp-release | cut -d. -f1) -gt 13 ]; then
    NODES_FILE=nodes-16.yaml
    ROLES_FILE=roles_data-16.yaml
fi

openstack overcloud deploy \
--timeout 240 \
--templates /usr/share/openstack-tripleo-heat-templates \
--libvirt-type kvm \
--stack overcloud \
-r /home/stack/vlan_provider_network_ovn/roles/$ROLES_FILE \
-n /home/stack/vlan_provider_network_ovn/network/network-config.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/cinder-backup.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/services/neutron-ovn-dvr-ha.yaml \
-e /home/stack/vlan_provider_network_ovn/network/network-environment.yaml \
-e /home/stack/vlan_provider_network_ovn/roles/$NODES_FILE \
-e /home/stack/vlan_provider_network_ovn/ovn-extras.yaml \
-e /home/stack/vlan_provider_network_ovn/l3_fip_qos.yaml \
-e /home/stack/vlan_provider_network_ovn/docker-images.yaml \
-e /home/stack/vlan_provider_network_ovn/performance.yaml \
-e /home/stack/vlan_provider_network_ovn/debug.yaml \
-e /home/stack/vlan_provider_network_ovn/hostnames.yaml \
-e /home/stack/vlan_provider_network_ovn/set-nova-scheduler-filter.yaml
