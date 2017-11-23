#!/bin/bash


openstack overcloud deploy  \
--templates \
-r /home/stack/ospd-11-multiple-nic-vlans-sriov-hybrid-ha/roles-data.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/neutron-sriov.yaml \
-e /home/stack/ospd-11-multiple-nic-vlans-sriov-hybrid-ha/network-environment.yaml \
--log-file overcloud_install.log &> overcloud_install.log
