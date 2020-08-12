#!/bin/bash
THT_PATH='/home/stack/ospd-16-vlan-multiple-nic-sriov-hybrid-ha-titan13'


openstack -vvv overcloud deploy  \
--templates \
--timeout 120 \
-n /home/stack/ospd-16-vlan-multiple-nic-sriov-hybrid-ha-titan13/network_data.yaml \
-r /home/stack/ospd-16-vlan-multiple-nic-sriov-hybrid-ha-titan13/roles_data.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/services/neutron-sriov.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/host-config-and-reboot.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/services/neutron-ovs.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/services/neutron-sriov.yaml \
-e /home/stack/ospd-16-vlan-multiple-nic-sriov-hybrid-ha-titan13/l3_fip_qos.yaml \
-e /home/stack/ospd-16-vlan-multiple-nic-sriov-hybrid-ha-titan13/dns.yaml \
-e /home/stack/ospd-16-vlan-multiple-nic-sriov-hybrid-ha-titan13/floating_ip_port_forwarding.yaml \
-e /home/stack/ospd-16-vlan-multiple-nic-sriov-hybrid-ha-titan13/nova-resize-on-the-same-host.yaml \
-e /home/stack/ospd-16-vlan-multiple-nic-sriov-hybrid-ha-titan13/network-environment.yaml \
-e /home/stack/containers-prepare-parameter.yaml \
-e /home/stack/ospd-16-vlan-multiple-nic-sriov-hybrid-ha-titan13/debug.yaml \
-e /home/stack/ospd-16-vlan-multiple-nic-sriov-hybrid-ha-titan13/os-net-config-mappings.yaml \
--log-file overcloud_install.log &> overcloud_install.log
