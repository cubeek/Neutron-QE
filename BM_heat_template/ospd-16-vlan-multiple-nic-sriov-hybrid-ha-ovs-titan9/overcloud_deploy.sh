#!/bin/bash
THT_PATH='/home/stack/ospd-16-vlan-multiple-nic-sriov-hybrid-ha-ovs-titan9'

if [[ ! -f "$THT_PATH/roles_data.yaml" ]]; then
  openstack overcloud roles generate -o $THT_PATH/roles_data.yaml Controller ComputeSriov
fi

openstack -vvv overcloud deploy  \
--templates \
--timeout 120 \
-r /home/stack/ospd-16-vlan-multiple-nic-sriov-hybrid-ha-ovs-titan9/roles_data.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/services/neutron-sriov.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/host-config-and-reboot.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/services/neutron-ovs.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/services/neutron-sriov.yaml \
-e /home/stack/ospd-16-vlan-multiple-nic-sriov-hybrid-ha-ovs-titan9/network-environment.yaml \
-e /home/stack/containers-prepare-parameter.yaml \
-e /home/stack/ospd-16-vlan-multiple-nic-sriov-hybrid-ha-ovs-titan9/os-net-config-mappings.yaml \
--log-file overcloud_install.log &> overcloud_install.log
