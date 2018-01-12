#!/bin/bash


openstack overcloud deploy  \
--templates \
-r /home/stack/ospd-10-vlan-multiple-nic-sriov-hybrid-ha/roles_data.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/neutron-sriov.yaml \
-e /home/stack/ospd-10-vlan-multiple-nic-sriov-hybrid-ha/network-environment.yaml \
--log-file overcloud_install.log &> overcloud_install.log
