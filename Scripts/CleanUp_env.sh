#!/bin/bash
#######################################################################################
#By Eran Kuris and Noam Manos 24.7.2018 ###############################################
#######################################################################################
cd /home/stack
# shellcheck disable=SC1091
source overcloudrc
for vm in $(openstack server list -c ID -f value | grep -v "^$"); do openstack server delete $vm; done
router_id=$(openstack router list -c ID -f value | head -1)
for fip in $(openstack floating ip list -c ID -f value | grep -v "^$"); do openstack floating ip delete $fip; done
for router in $(openstack router list -c ID -f value | grep -v "^$"); do openstack router unset --external-gateway $router; done
for router in $(openstack router list -c ID -f value | grep -v "^$"); do neutron router-gateway-clear $router; done
for subnet in $(openstack subnet list -c ID -f value | grep -v "^$"); do openstack router remove subnet $router_id $subnet; done
for subnet in $(openstack subnet list -c ID -f value | grep -v "^$"); do openstack subnet delete $subnet; done
for router in $(openstack router list -c ID -f value | grep -v "^$"); do openstack router delete $router; done
for port in $(openstack port list -c ID -f value | grep -v "^$"); do openstack port delete $port; done
for network in $(openstack network list -c ID -f value | grep -v "^$"); do openstack network delete $network; done
for image in $(openstack image list -c ID -f value | grep -v "^$"); do openstack image delete $image; done
for flavor in $(openstack flavor list -c ID -f value | grep -v "^$"); do openstack flavor delete $flavor; done
for secgroup in $(openstack security group list -c ID -f value | grep -v "^$"); do openstack security group delete $secgroup; done

