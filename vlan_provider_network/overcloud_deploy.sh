#!/bin/bash

openstack overcloud deploy \
    --timeout 240 \
    --templates /usr/share/openstack-tripleo-heat-templates \
    --libvirt-type kvm \
    --stack overcloud \
    -r /home/stack/vlan_provider_network/roles/roles_data.yaml \
    -n /home/stack/vlan_provider_network/roles/network-config.yaml \
