#!/bin/bash


THT_PATH='/home/stack/ospd-13-multiple-nic-VxLan-hybrid-ha-IPv6'

if [[ ! -f "$THT_PATH/roles_data.yaml" ]]; then
  openstack overcloud roles generate -o $THT_PATH/roles_data.yaml Controller Compute
fi

openstack overcloud deploy  \
--templates \
--timeout 120 \
-e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation-v6.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/docker.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/docker-ha.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/host-config-and-reboot.yaml \
-e $THT_PATH/docker-images.yaml \
-e $THT_PATH/network-environment.yaml \
-r $THT_PATH/roles_data.yaml \
--log-file overcloud_install.log &> overcloud_install.log
