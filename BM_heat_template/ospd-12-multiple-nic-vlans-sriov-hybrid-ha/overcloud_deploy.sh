#!/bin/bash


openstack overcloud deploy  \
--templates \
--timeout 120 \
-r /home/stack/ospd-12-multiple-nic-vlans-sriov-hybrid-ha/roles_data.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/host-config-and-reboot.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/neutron-sriov.yaml \
-e /home/stack/ospd-12-multiple-nic-vlans-sriov-hybrid-ha/docker-images.yaml \
-e /home/stack/ospd-12-multiple-nic-vlans-sriov-hybrid-ha/network-environment.yaml \
--log-file overcloud_install.log &> overcloud_install.log
