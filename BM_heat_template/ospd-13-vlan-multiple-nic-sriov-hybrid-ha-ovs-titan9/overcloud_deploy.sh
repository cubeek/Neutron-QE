#!/bin/bash
THT_PATH='/home/stack/ospd-13-vlan-multiple-nic-sriov-hybrid-ha-ovs-titan9'

if [[ ! -f "$THT_PATH/roles_data.yaml" ]]; then
  openstack overcloud roles generate -o $THT_PATH/roles_data.yaml Controller ComputeSriov
fi

openstack -vvv overcloud deploy  \
--templates \
--timeout 120 \
-r /home/stack/ospd-13-vlan-multiple-nic-sriov-hybrid-ha-ovs-titan9/roles_data.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/host-config-and-reboot.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/neutron-sriov.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/docker.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/docker-ha.yaml \
-e /home/stack/ospd-16-vlan-sriov-hybrid-ha-ovn-squad/l3_fip_qos.yaml \
-e /home/stack/16_vlan/dns.yaml \
-e /home/stack/16_vlan/nova-resize-on-the-same-host.yaml \
-e /home/stack/ospd-13-vlan-multiple-nic-sriov-hybrid-ha-ovs-titan9/network-environment.yaml \
-e /home/stack/ospd-13-vlan-multiple-nic-sriov-hybrid-ha-ovs-titan9/docker-images.yaml \
-e /home/stack/ospd-13-vlan-multiple-nic-sriov-hybrid-ha-ovs-titan9/os-net-config-mappings.yaml \
--log-file overcloud_install.log &> overcloud_install.log
