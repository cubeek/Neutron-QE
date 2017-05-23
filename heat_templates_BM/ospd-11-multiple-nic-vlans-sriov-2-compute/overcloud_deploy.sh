#!/bin/bash


openstack overcloud deploy  \
--templates \
-e /usr/share/openstack-tripleo-heat-templates/environments/neutron-sriov.yaml \
-e /home/stack/ospd-11-multiple-nic-vlans-sriov-2-compute/network-environment.yaml \
--log-file overcloud_install.log &> overcloud_install.log
