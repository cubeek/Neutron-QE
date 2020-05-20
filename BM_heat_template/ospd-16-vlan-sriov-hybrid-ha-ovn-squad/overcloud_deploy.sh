#!/bin/bash
THT_PATH='/home/stack/ospd-16-vlan-sriov-hybrid-ha-ovn-squad'

if [[ ! -f "$THT_PATH/roles_data.yaml" ]]; then
  openstack overcloud roles generate -o $THT_PATH/roles_data.yaml ControllerSriov ComputeSriov
fi

openstack -vvv overcloud deploy  \
--templates \
--timeout 120 \
-r $THT_PATH/roles_data.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/services/neutron-sriov.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/host-config-and-reboot.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/services/neutron-ovn-dvr-ha.yaml \
-e /home/stack/containers-prepare-parameter.yaml \
-e $THT_PATH/api-policies.yaml \
-e $THT_PATH/network-environment.yaml \
-e $THT_PATH/os-net-config-mappings.yaml \
-e $THT_PATH/nova-resize-on-the-same-host.yaml \
-e $THT_PATH/l3_fip_qos.yaml \
-e $THT_PATH/ovn-extras.yaml \
--log-file overcloud_install.log &> overcloud_install.log
