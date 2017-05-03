#!/bin/bash

openstack overcloud deploy \
--templates \
--ntp-server clock.redhat.com \
-e /usr/share/openstack-tripleo-heat-templates/environments/neutron-ovs-dpdk.yaml \
-e /home/stack/ospd-11-multiple-nic-vlans-ovs-dpdk-single-port-1-compute/network-environment.yaml \
--log-file overcloud_install.log &> overcloud_install.log
