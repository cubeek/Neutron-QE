#!/bin/bash


openstack overcloud deploy  \
--templates \
-e /usr/share/openstack-tripleo-heat-templates/environments/neutron-sriov.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
-e /home/stack/ospd-10-multiple-nic-vlans-sriov2/network/network-environment.yaml \
--log-file overcloud_install.log &> overcloud_install.log
