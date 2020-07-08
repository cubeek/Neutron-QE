#!/bin/sh

# This is script that will be used temporary on a setup which is configured to use jumbo MTU for creating an external network exactly like cloud-config creates.
# It will be run as --overcloud-postdeploy-action
# Note: cloud-config can not be used due to couple of reasons:
# a. it creates external network with mtu 9000 on such setup which is not what we need for our testing.
# b. while it is still possible to add support to cloud-init to support setting mtu the feature depends on ansible 2.9 but infrared currently is hard-coded to use 2.7.* (probably due to compatibility reasons)
# There is a patch[0] for allowing usage of latest ansible in infrared but it is still in review (long time already).
# [0] https://review.gerrithub.io/c/redhat-openstack/infrared/+/493623

NETWORK=nova
source /home/stack/overcloudrc && \
openstack network create --provider-network-type flat --provider-physical-network datacentre --external $NETWORK --mtu 1500 && \
openstack subnet create --no-dhcp --gateway 10.0.0.1 --network $NETWORK --subnet-range 10.0.0.0/24 --allocation-pool start=10.0.0.210,end=10.0.0.250 external-subnet && \
openstack subnet create --no-dhcp --ip-version 6  --gateway 2620:52:0:13b8::fe  --subnet-range 2620:52:0:13b8::/64  --network $NETWORK   external_ipv6_subnet   --allocation-pool start=2620:52:0:13b8::1000:1,end=2620:52:0:13b8::1000:aa
