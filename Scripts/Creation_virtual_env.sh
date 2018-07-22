 #!/bin/bash
#######################################################################################
#Created by Eran Kuris 22.7.2018                                                      #
#######################################################################################
source ~/overcloudrc
cd /tmp/
set -x
set -e
echo "This Script is creating 2 network with IPv4& Ipv6 subnets"
echo "It booting instances for each network with FIP"

echo "which image do you want? rhel74/rhel75/cirros?"
read image

echo "How many instances do you want to run for each network?"
read ins

echo "Do you want to create external network? yes or no?"
read external_network_needed
if  [[ $external_network_needed = yes ]]
then

  echo "what is the provider-network-type flat/vlan?"
  read provider_network_type


  if [[ $provider_network_type = vlan ]]
  then
    echo "what is the subnet-range {format x.c.v.b/y}?"
    read subnet_range

    echo "what is the gateway {format ip_address}?"
    read gateway

    echo "what is the allocation pool start & end?"
    read start
    read end

    echo "what is the provider-segment?"
    read vlan_id

    openstack network create --provider-network-type vlan  --provider-segment $vlan_id --provider-physical-network datacentre --external  nova
    openstack subnet create --subnet-range $(subnet_range) --network nova  --no-dhcp --gateway $(gateway)  --allocation-pool start=$(start),end=$(end) nova
  else
    openstack network create --provider-network-type flat  --provider-physical-network datacentre --external  nova
    openstack subnet create --subnet-range 10.0.0.0/24 --network nova  --no-dhcp --gateway 10.0.0.1  --allocation-pool start=10.0.0.210,end=10.0.0.250 nova
  fi
fi

sudo yum -y install libguestfs-tools
sudo yum -y install libvirt && sudo systemctl start libvirtd

# Download and creating images & flavors
# changing root password to 12345678

#cirros image
echo "creating cirros image"
wget https://download.cirros-cloud.net/0.3.5/cirros-0.3.5-x86_64-disk.img
openstack image create --container-format bare --disk-format qcow2 --public --file cirros-0.3.5-x86_64-disk.img cirros35

#rhel v7.4 image
echo "creating rhel v7.4 image"
wget http://file.tlv.redhat.com/~ekuris/custom_ci_image/rhel-guest-image-7.4-191.x86_64.qcow2
virt-customize -a rhel-guest-image-7.4-191.x86_64.qcow2 --root-password password:12345678
virt-edit -a rhel-guest-image-7.4-191.x86_64.qcow2 -e 's/^disable_root: 1/disable_root: 0/' /etc/cloud/cloud.cfg
virt-edit -a rhel-guest-image-7.4-191.x86_64.qcow2 -e 's/^ssh_pwauth:\s+0/ssh_pwauth: 1/' /etc/cloud/cloud.cfg
openstack image create --container-format bare --disk-format qcow2 --public --file rhel-guest-image-7.4-191.x86_64.qcow2 rhel74

#rhel v7.5 image
echo "creating rhel v7.5 image"
wget http://file.tlv.redhat.com/~ekuris/custom_ci_image/rhel-guest-image-7.5-137.x86_64.qcow2
virt-customize -a rhel-guest-image-7.5-137.x86_64.qcow2 --root-password password:12345678
virt-edit -a rhel-guest-image-7.5-137.x86_64.qcow2 -e 's/^disable_root: 1/disable_root: 0/' /etc/cloud/cloud.cfg
virt-edit -a rhel-guest-image-7.5-137.x86_64.qcow2 -e 's/^ssh_pwauth:\s+0/ssh_pwauth: 1/' /etc/cloud/cloud.cfg
openstack image create --container-format bare --disk-format qcow2 --public --file rhel-guest-image-7.5-137.x86_64.qcow2 rhel75

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
openstack router set --external-gateway nova Router_eNet

#create security group
SecID=$(openstack security group create sec_group | awk -F'[ \t]*\\|[ \t]*' '/ id / {print $3}')

#create security group rules
openstack security group rule create --protocol icmp --ingress --prefix 0.0.0.0/0 $SecID
openstack security group rule create --protocol tcp --ingress --prefix 0.0.0.0/0 $SecID
openstack security group rule create --protocol udp --ingress --prefix 0.0.0.0/0 $SecID
openstack security group rule create --protocol icmp --ingress --ethertype IPv6 $SecID
openstack security group rule create --protocol tcp --ingress --ethertype IPv6 $SecID
openstack security group rule create --protocol udp --ingress --ethertype IPv6 $SecID

if [[ $image=rhel74 || $image=rhel75 ]]; then
  flavor=1
else
  flavor=2
fi

echo "‏You wanted to create" $ins " instanses for each tenant network , let's start "

for i in $(eval echo {1..$ins});do
  openstack server create --flavor $flavor --image $image --nic net-id=net-64-1 --security-group $SecID net-64-1_VM_$i
  openstack server create --flavor $flavor --image $image --nic net-id=net-64-2 --security-group $SecID net-64-2_VM_$i

   eval floatingip_net1[$i]=$(openstack floating ip create nova  | awk -F'[ \t]*\\|[ \t]*' '/ floating_ip_address / {print $3}')
   eval IP_1=${floatingip_net1[$i]}
   echo $IP_1
   eval floatingip_net2[$i]=$(openstack floating ip create nova  | awk -F'[ \t]*\\|[ \t]*' '/ floating_ip_address / {print $3}')
   eval IP_2=${floatingip_net2[$i]}
   echo $IP_2
   openstack server add floating ip net-64-1_VM_$i $IP_1
   openstack server add floating ip net-64-2_VM_$i $IP_2

done

