#!/bin/bash
#######################################################################################
#By Eran Kuris and Noam Manos 24.7.2018 ###############################################
#######################################################################################
cd /home/stack
# shellcheck disable=SC1091
source overcloudrc

set -o xtrace
echo "This Script is creating 2 networks with IPv4 & Ipv6 subnets."
echo "It creates router with exteranl connectivity and internal connectivity."
echo "It's booting instances for each network with FIP"
echo "For each vm we have IPv4 address& IPv6 address"


echo "Which image do you want to use: rhel74 / rhel75 / cirros35 ?"
read -r image

echo "How many instances do you want to run for each network?"
read -r ins

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
if [[ $image = cirros35 ]]; then
  #cirros image
  echo "creating cirros 3.5 image"
  wget -N https://download.cirros-cloud.net/0.3.5/cirros-0.3.5-x86_64-disk.img
  openstack image create --container-format bare --disk-format qcow2 --public --file cirros-0.3.5-x86_64-disk.img cirros35
  flavor=cirros_flavor
else
  if [[ $image = rhel74 ]]; then
    #rhel v7.4 image
    echo "creating rhel v7.4 image"
    wget -N http://file.tlv.redhat.com/~ekuris/custom_ci_image/rhel-guest-image-7.4-191.x86_64.qcow2
    openstack image create --container-format bare --disk-format qcow2 --public --file rhel-guest-image-7.4-191.x86_64.qcow2 rhel74
    flavor=rhel_flavor
  else
    if [[ $image = rhel75 ]]; then
      echo "creating rhel v7.5 image"
      wget -N http://file.tlv.redhat.com/~ekuris/custom_ci_image/rhel-guest-image-7.5-137.x86_64.qcow2
      openstack image create --container-format bare --disk-format qcow2 --public --file rhel-guest-image-7.5-137.x86_64.qcow2 rhel75
      flavor=rhel_flavor
    fi
  fi
fi

#create flavors
echo "creating flavors"
openstack flavor create --public rhel_flavor --id 1 --ram 1024 --disk 10 --vcpus 1
openstack flavor create --public cirros_flavor --id 2 --ram 512 --disk 1 --vcpus 1

#create tenant network 1 with IPv4 & IPv6
openstack network create net-64-1
openstack subnet create --subnet-range 10.0.1.0/24  --network net-64-1 --dhcp subnet_4_1
openstack subnet create --subnet-range 2001::/64 --network net-64-1  --ipv6-address-mode slaac  --ipv6-ra-mode slaac --ip-version 6 subnet_6_1

#create tenant network 2 with IPv4 & IPv6
openstack network create net-64-2
openstack subnet create --subnet-range 10.0.2.0/24  --network net-64-2 --dhcp subnet_4_2
openstack subnet create --subnet-range 2002::/64 --network net-64-2  --ipv6-address-mode slaac  --ipv6-ra-mode slaac --ip-version 6 subnet_6_2

#create Router
openstack router create Router_eNet

#create sub_interface
openstack router add subnet Router_eNet subnet_4_1
openstack router add subnet Router_eNet subnet_4_2
openstack router add subnet Router_eNet subnet_6_1
openstack router add subnet Router_eNet subnet_6_2

#create external gateway
openstack router set --external-gateway $ext_net Router_eNet
neutron router-gateway-set Router_eNet $ext_net 

#create security group
SecID=$(openstack security group create sec_group | awk -F'[ \t]*\\|[ \t]*' '/ id / {print $3}')

#create security group rules
openstack security group rule create --protocol icmp --ingress --prefix 0.0.0.0/0 $SecID
openstack security group rule create --protocol tcp --ingress --prefix 0.0.0.0/0 $SecID
openstack security group rule create --protocol udp --ingress --prefix 0.0.0.0/0 $SecID
openstack security group rule create --protocol icmp --ingress --ethertype IPv6 $SecID
openstack security group rule create --protocol tcp --ingress --ethertype IPv6 $SecID
openstack security group rule create --protocol udp --ingress --ethertype IPv6 $SecID

echo "You wanted to create" "$ins" " instanses for each tenant network, let's start..."

for i in `seq 1 $ins`; do
   image_id=$(openstack image list | grep $image | head -1 | cut -d " " -f 2)
   openstack server create --flavor $flavor --image $image_id --nic net-id=net-64-1 --security-group $SecID net-64-1_VM_$i
   until openstack server show net-64-1_VM_${i} | grep -E 'ACTIVE' -B 5; do sleep 1 ; done
   openstack server create --flavor $flavor --image $image_id --nic net-id=net-64-2 --security-group $SecID net-64-2_VM_$i
   until openstack server show net-64-2_VM_${i} | grep -E 'ACTIVE' -B 5; do sleep 1 ; done

   IP_1=$(openstack floating ip create $ext_net | awk -F'[ \t]*\\|[ \t]*' '/ floating_ip_address / {print $3}')
   echo "Adding floating ip $IP_1 to net-64-1_VM_$i"
   openstack server add floating ip net-64-1_VM_$i $IP_1;
   until ping -c1 $IP_1 ; do sleep 1 ; done
   curl $IP_1:80

   IP_2=$(openstack floating ip create $ext_net | awk -F'[ \t]*\\|[ \t]*' '/ floating_ip_address / {print $3}')
   echo "Adding floating ip $IP_2 to net-64-2_VM_$i"
   openstack server add floating ip net-64-2_VM_$i $IP_2;
   until ping -c1 $IP_2 ; do sleep 1 ; done
   ping -c3 $IP_2
   curl $IP_2:80

done


echo "root password to rhel images is: 12345678"
echo "password for cirros is cubswin:)"

