#!/bin/bash

openstack overcloud deploy \
--templates \
--timeout 120 \
-r /home/stack/ospd-15-vlan-multiple-nic-sriov-hybrid-ha/roles_data.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/services/neutron-sriov.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/host-config-and-reboot.yaml \
-e /home/stack/ospd-15-vlan-multiple-nic-sriov-hybrid-ha/network-environment.yaml \
-e /home/stack/containers-prepare-parameter.yaml \
--log-file overcloud_install.log &> overcloud_install.log
