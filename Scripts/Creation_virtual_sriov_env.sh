#!/bin/bash
#######################################################################################
#By Eran Kuris and Noam Manos 24.7.2018 ###############################################
#######################################################################################
cd /home/stack
# shellcheck disable=SC1091
source overcloudrc

set -o xtrace
echo "This Script is creating 1 network with IPv4 & Ipv6 subnets."
echo "It creates router with exteranl connectivity and internal connectivity."
echo "It's booting instances with FIP"
echo "For each vm we have IPv4 address& IPv6 address"


echo "Which image do you want to use: rhel74 / rhel75 ?"
read -r image

echo "Do you want to create external network (yes / no) ?"
read -r external_network_needed

if  [[ $external_network_needed = yes ]]
  then
    echo "What is the provider-network type: flat / vlan ?"
    read -r provider_network_type

    if [[ $provider_network_type = vlan ]]
      then
        echo "what is the subnet-range {format x.c.v.b/y}?"
        read -r subnet_range

        echo "what is the gateway {format ip_address-x.c.v.b}?"
        read -r gateway

        echo "what is the allocation pool start & end?"
        read -r start
        read -r end

        echo "what is the provider-segment?"
        read -r vlan_id

        openstack network create --provider-network-type vlan  --provider-segment "$vlan_id" --provider-physical-network datacentre --external  nova
        openstack subnet create --subnet-range "$subnet_range" --network nova  --no-dhcp --gateway "$gateway"  --allocation-pool start="$start",end="$end" nova
    else
      openstack network create --provider-network-type flat  --provider-physical-network datacentre --external  nova
      openstack subnet create --subnet-range 10.0.0.0/24 --network nova  --no-dhcp --gateway 10.0.0.1  --allocation-pool start=10.0.0.210,end=10.0.0.250 nova
    fi
fi

ext_net=$(openstack network list --external -c Name -f value)

if [[ -z "$ext_net" ]]
  then
    echo "External network was not created, exiting!"
    exit 1
fi

# Download and creating images & flavors
# changing root password to 12345678
if [[ $image = rhel75 ]]; then

   echo "creating rhel v7.5 image"
   wget -N http://file.tlv.redhat.com/~ekuris/custom_ci_image/rhel-guest-image-7.5-137.x86_64.qcow2
   openstack image create --container-format bare --disk-format qcow2 --public --file rhel-guest-image-7.5-137.x86_64.qcow2 rhel75
   flavor=rhel_flavor
else
  if [[ $image = rhel74 ]]; then
    #rhel v7.4 image
    echo "creating rhel v7.4 image"
    wget -N http://file.tlv.redhat.com/~ekuris/custom_ci_image/rhel-guest-image-7.4-191.x86_64.qcow2
    openstack image create --container-format bare --disk-format qcow2 --public --file rhel-guest-image-7.4-191.x86_64.qcow2 rhel74
    flavor=rhel_flavor

  fi
fi

#create flavors
echo "creating flavors"
openstack flavor create --public rhel_flavor --id 1 --ram 1024 --disk 10 --vcpus 1


#create tenant network 1 with IPv4 & IPv6
vlan_tenant_id=$(openstack network create net-64-1 | awk -F'[ \t]*\\|[ \t]*' '/ provider:segmentation_id / {print $3}')
openstack subnet create --subnet-range 10.0.1.0/24  --network net-64-1 --dhcp subnet_4_1
openstack subnet create --subnet-range 2001::/64 --network net-64-1  --ipv6-address-mode slaac  --ipv6-ra-mode slaac --ip-version 6 subnet_6_1


#create Router
openstack router create Router_eNet

#create sub_interface
openstack router add subnet Router_eNet subnet_4_1
openstack router add subnet Router_eNet subnet_6_1

#create external gateway
openstack router set --external-gateway $ext_net Router_eNet
neutron router-gateway-set Router_eNet $ext_net 

SecID=$(openstack port create  --network net-64-1 --vnic-type direct vf_sriov | awk -F'[ \t]*\\|[ \t]*' '/ security_groups / {print $3}')
openstack port create  --network net-64-1 --vnic-type direct-physical PF_sriov
openstack port create  --network net-64-1 normal

#create security group rules
openstack security group rule create --protocol icmp --ingress --prefix 0.0.0.0/0 $SecID
openstack security group rule create --protocol tcp --ingress --prefix 0.0.0.0/0 $SecID
openstack security group rule create --protocol udp --ingress --prefix 0.0.0.0/0 $SecID
openstack security group rule create --protocol icmp --ingress --ethertype IPv6 $SecID
openstack security group rule create --protocol tcp --ingress --ethertype IPv6 $SecID
openstack security group rule create --protocol udp --ingress --ethertype IPv6 $SecID

echo #cloud-config >>create_int.yaml
echo write_files: >>create_int.yaml
echo  - path: "/etc/sysconfig/network-scripts/ifcfg-eth0."$vlan_tenant_id >>create_int.yaml
echo    owner: "root" >>create_int.yaml
echo    permissions: '777'>>create_int.yaml
echo    content: | >>create_int.yaml
echo      DEVICE="eth0."$vlan_tenant_id >>create_int.yaml
echo      BOOTPROTO="dhcp" >>create_int.yaml
echo      ONBOOT="yes" >>create_int.yaml
echo      VLAN="yes" >>create_int.yaml
echo      PERSISTENT_DHCLIENT="yes" >>create_int.yaml
echo runcmd: >>create_int.yaml
echo    - [ sh, -c , 'systemctl restart network' ] >>create_int.yaml

image_id=$(openstack image list | grep $image | head -1 | cut -d " " -f 2)
#VF
openstack server create --flavor $flavor --image $image_id --nic port-id=vf_sriov net-64-1_vf
until openstack server show net-64-1_vf | grep -E 'ACTIVE' -B 5; do sleep 1 ; done
#PF
openstack server create  --config-drive True --user-data create_int.yaml --flavor $flavor --image $image_id --nic port-id=PF_sriov net-64-1_pf
until openstack server show net-64-1_pf | grep -E 'ACTIVE' -B 5; do sleep 1 ; done
#Normal
openstack server create  --flavor $flavor --image $image_id --nic port-id=normal net-64-1_normal
until openstack server show net-64-1_normal | grep -E 'ACTIVE' -B 5; do sleep 1 ; done

   IP_1=$(openstack floating ip create "$ext_net" | awk -F'[ \t]*\\|[ \t]*' '/ floating_ip_address / {print $3}')
   echo "Adding floating ip $IP_1 to net-64-1_vf"
   openstack server add floating ip net-64-1_vf $IP_1;
   until ping -c1 $IP_1 ; do sleep 1 ; done

   IP_3=$(openstack floating ip create "$ext_net" | awk -F'[ \t]*\\|[ \t]*' '/ floating_ip_address / {print $3}')
   echo "Adding floating ip $IP_3 to  net-64-1_normal"
   openstack server add floating ip  net-64-1_normal $IP_3;
   until ping -c1 $IP_3 ; do sleep 1 ; done
   ping -c3 $IP_3

   IP_2=$(openstack floating ip create "$ext_net" | awk -F'[ \t]*\\|[ \t]*' '/ floating_ip_address / {print $3}')
   echo "Adding floating ip $IP_2 to  net-64-1_pf"
   openstack server add floating ip  net-64-1_pf $IP_2;
   until ping -c1 $IP_2 ; do sleep 1 ; done
   ping -c3 $IP_2


