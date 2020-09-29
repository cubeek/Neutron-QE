#!/bin/bash
THT_PATH='/home/stack/ospd-13-vlan-multiple-nic-sriov-hybrid-ha-ceph-titan13'

if [[ ! -f "$THT_PATH/roles_data.yaml" ]]; then
  openstack overcloud roles generate -o $THT_PATH/roles_data.yaml Controller ComputeSriov CephStorage 
fi

openstack -vvv overcloud deploy  \
--templates \
--timeout 120 \
-r /home/stack/ospd-13-vlan-multiple-nic-sriov-hybrid-ha-ceph-titan13/roles_data.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/host-config-and-reboot.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/neutron-sriov.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/docker.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/docker-ha.yaml \
-e /home/stack/ospd-13-vlan-multiple-nic-sriov-hybrid-ha-ceph-titan13/l3_fip_qos.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/ceph-ansible/ceph-ansible.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/cinder-backup.yaml \
-e /home/stack/ospd-13-vlan-multiple-nic-sriov-hybrid-ha-ceph-titan13/dns.yaml \
-e /home/stack/ospd-13-vlan-multiple-nic-sriov-hybrid-ha-ceph-titan13/nova-resize-on-the-same-host.yaml \
-e /home/stack/ospd-13-vlan-multiple-nic-sriov-hybrid-ha-ceph-titan13/network-environment.yaml \
-e /home/stack/ospd-13-vlan-multiple-nic-sriov-hybrid-ha-ceph-titan13/docker-images.yaml \
-e /home/stack/ospd-13-vlan-multiple-nic-sriov-hybrid-ha-ceph-titan13/os-net-config-mappings.yaml \
--log-file overcloud_install.log &> overcloud_install.log
