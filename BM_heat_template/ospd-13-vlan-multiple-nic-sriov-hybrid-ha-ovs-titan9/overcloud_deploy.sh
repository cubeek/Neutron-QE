#!/bin/bash
THT_PATH='/home/stack/ospd-13-vlan-multiple-nic-sriov-hybrid-ha-ovs-titan9'


openstack -vvv overcloud deploy  \
--templates \
--timeout 120 \
-r $THT_PATH/roles_data.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/services/neutron-sriov.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/host-config-and-reboot.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/services/neutron-sriov.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/docker.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/docker-ha.yaml \
-e $THT_PATH/network-environment.yaml \
-e $THT_PATH/docker-images.yaml \
-e $THT_PATH//os-net-config-mappings.yaml \
--log-file overcloud_install.log &> overcloud_install.log
