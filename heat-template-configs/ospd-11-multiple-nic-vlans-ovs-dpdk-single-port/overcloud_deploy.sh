#!/bin/bash

cat >"$HOME/extra_env.yaml"<<EOF
---
parameter_defaults:
    Debug: true
EOF

openstack overcloud deploy --debug \
--templates \
--environment-file "$HOME/extra_env.yaml" \
--libvirt-type kvm \
--ntp-server clock.redhat.com \
-e /home/stack/ospd-11-multiple-nic-vlans-ovs-dpdk-single-port/network-environment.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/neutron-ovs-dpdk.yaml \
--log-file overcloud_install.log &> overcloud_install.log
