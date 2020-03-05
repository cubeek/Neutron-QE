#!/bin/bash


openstack overcloud deploy  \
--templates \
--timeout 120 \
-r /home/stack/ospd-13-vlan-multiple-nic-sriov-hybrid-ha/roles_data.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/docker.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/docker-ha.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/services/neutron-sriov.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/host-config-and-reboot.yaml \
-e /home/stack/ospd-13-vlan-multiple-nic-sriov-hybrid-ha/docker-images.yaml \
-e /home/stack/ospd-13-vlan-multiple-nic-sriov-hybrid-ha/network-environment.yaml \
-e /home/stack/ospd-13-vlan-multiple-nic-sriov-hybrid-ha/inject-trust-anchor.yaml \
--log-file overcloud_install.log &> overcloud_install.log
