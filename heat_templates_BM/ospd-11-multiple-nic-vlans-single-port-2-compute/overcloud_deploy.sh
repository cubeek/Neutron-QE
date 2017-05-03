#!/bin/bash

openstack overcloud deploy \
--templates \
--ntp-server clock.redhat.com \
-e /home/stack/ospd-11-multiple-nic-vlans-single-port-2-compute/network-environment.yaml \
--log-file overcloud_install.log &> overcloud_install.log
