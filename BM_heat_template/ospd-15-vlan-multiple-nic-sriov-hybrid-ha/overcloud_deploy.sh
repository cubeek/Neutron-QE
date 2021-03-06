#!/bin/bash
THT_PATH='/home/stack/ospd-15-vlan-multiple-nic-sriov-hybrid-ha'

if [[ ! -f "$THT_PATH/roles_data.yaml" ]]; then
  openstack overcloud roles generate -o $THT_PATH/roles_data.yaml Controller ComputeSriov
fi

openstack -vvv overcloud deploy \
--templates \
--timeout 120 \
-e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/host-config-and-reboot.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/services/neutron-ovs.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/services/neutron-sriov.yaml \
-e /home/stack/ospd-15-vlan-multiple-nic-sriov-hybrid-ha/network-environment.yaml \
-e /home/stack/containers-prepare-parameter.yaml \
-r $THT_PATH/roles_data.yaml \
--log-file overcloud_install.log &> overcloud_install.log
