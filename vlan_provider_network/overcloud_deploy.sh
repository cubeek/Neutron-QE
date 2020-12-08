#!/bin/bash

openstack overcloud deploy \
    --timeout 240 \
    --templates /usr/share/openstack-tripleo-heat-templates \
    --libvirt-type kvm \
    --stack overcloud \
    -r /home/stack/vlan_provider_network/roles/roles_data.yaml \
    -n /home/stack/vlan_provider_network/network/network-config.yaml \
    -e /usr/share/openstack-tripleo-heat-tempaltes/environments/network-isolation.yaml \
    -e /usr/share/openstack-tripleo-heat-tempaltes/environments/network-environment.yaml \
    -e /home/stack/vlan_provider_network/network/network-environment-overrides.yaml \
    -e /home/stack/vlan_provider_network/roles/nodes.yaml
