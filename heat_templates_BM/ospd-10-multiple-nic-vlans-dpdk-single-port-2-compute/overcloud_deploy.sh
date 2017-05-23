#!/bin/bash

openstack overcloud deploy \
--templates \
--ntp-server clock.redhat.com \
-e /usr/share/openstack-tripleo-heat-templates/environments/neutron-ovs-dpdk.yaml \
-e /home/stack/ospd-10-multiple-nic-vlans-dpdk-single-port-2-compute/network-environment.yaml \
--log-file overcloud_install.log &> overcloud_install.log \
--timeout 130
