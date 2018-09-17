#!/bin/bash
#######################################################################################
# By Eran Kuris and Noam Manos, 2018 ###############################################
#######################################################################################

# CONSTANTS
RED='\033[0;31m'
YELLOW='\033[1;33m'
NO_CLR='\033[0m' # No Color

shopt -s nocasematch # No case sensitive match for cli options

# CLI user options
POSITIONAL=()
while [ $# -gt 0 ]
do
    # Consume next (1st) argument
    case $1 in
    -i|--image)
      image="$2"
      echo "VM image to use: $image"
      shift 2 ;;
    -t|--topology)
      topology="$2"
      [[ $topology = mni ]] && echo "Topology to create: Multiple NICs per virtual-machine"
      [[ $topology = mvi ]] && echo "Topology to create: Multiple VMs per network"
      shift 2 ;;
    -n|--networks)
      net_num="$2" ; echo "Number of Networks to create: $net_num"
      shift 2 ;;
    -v|--machines)
      inst_num="$2" ; echo "Number of VMs to create: $inst_num"
      shift 2 ;;
    -e|--external)
      external_network_type="$2"
      echo "External network type to create: $external_network_type"
      shift 2 ;;
    -c|--cleanup)
      cleanup_needed="$2"
      echo "Run environment cleanup initially: $cleanup_needed"
      shift 2 ;;
    -d|--debug)
      trap '! [[ "$BASH_COMMAND" =~ ^(echo|read|if|while) ]] && echo $PS1$BASH_COMMAND' DEBUG
      debug="--debug"
      shift ;;
    -q|--quit)
      quit_on_error=True
      shift ;;
    -*)
      echo "$0: Error - unrecognized option $1" 1>&2; exit 1 ;;
    *)
      break ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

echo "----------------------------------------------------------------------
This script will create and run:

* Multiple VM instances (of type RHEL 7.5 / RHEL 7.4 / Cirros)
* Multiple Networks with IPv4 & Ipv6 subnets, and Floating IPs, connected to external router.
* SSH Keypair and connectivity test.

Running with pre-defined parameters (optional):

* To debug (verbose output):                            -d / --debug
* To quit on first error:                               -q / --quit
* To set VM image:                                      -i / --image    [ rhel74 / rhel75 / cirros35 ]
* To set topology - Multiple VMs or multiple NICs:      -t / --topology [ mni = Multiple Networks Intrfaces / mvi = Multiple VM Instances ]
* To set the number of networks:                        -n / --networks [ 1-100 ]
* To set the number of VMs:                             -v / --machines [ 1-100 ]
* To create external network:                           -e / --external [ flat / vlan / skip ]
* To run environment cleanup initially:                 -c / --cleanup  [ NO / YES ]

Command example:
./create_multi_topology.sh -d -q -t mvi -i cirros35 -n 2 -v 1 -e flat -c YES

----------------------------------------------------------------------"

# Script will stop executing on first error, if requested
[[ -z "$quit_on_error" ]] || set -e

# Running commands inside Undercloud as Overcloud admin user
if [ "$USER" != "stack" ];then
    echo "Must be logged in as stack user. Exiting."
    exit 1
fi

cd /home/stack

ENV_FILE=/home/stack/overcloudrc
if [ ! -f $ENV_FILE ]; then
    echo "Can't find overcloudrc environment file, Overcloud must be correctly deployed. Exiting."
    exit 1
else
    . $ENV_FILE
fi


osp_version=$(cat /etc/yum.repos.d/latest-installed)
# better to use:  cat /etc/yum.repos.d/rhos-release-13.repo | grep puddle_baseurl
echo -e "\nBase OSP version: $osp_version"
echo -e "\nCurrently deployed puddle:"
cat /etc/yum.repos.d/rhos-release-*.repo | grep -m 1 puddle_baseurl

osp_version=$(echo $osp_version | awk '{print $1}')

while ! [[ "$image" =~ ^(rhel74|rhel75|cirros35)$ ]]
do
  echo -e "\nWhich image do you want to use: rhel74 / rhel75 / cirros35 ?"
  read -r image
done

while ! [[ "$topology" =~ ^(mni|mvi)$ ]]
do
  echo -e "\nWhich Networks <--> VMs topology do you want to create ?
  * To create multiple NICs on each machine, enter: mni
  * To create multiple VMs on each network, enter: mvi"
  read -r topology
done

# Checking if to create external network
ext_net=$(openstack network list --external -c Name -f value)
if [[ -z "$ext_net" ]]; then
  echo -e "\n${RED}Warning: External network does NOT exist!${NO_CLR}"
else
  echo -e "\n${YELLOW}External network exists:${NO_CLR} $ext_net"
fi

if ! [[ "$external_network_type" =~ ^(flat|vlan|skip)$ ]]; then
  echo -e "\nDo you want to create a new external network ?
Press enter to skip, otherwise enter the network type to create (flat / vlan)"
  read -r external_network_type
  external_network_type=${external_network_type:-skip}
fi

# Getting VLAN network details if required
if [[ $external_network_type = vlan ]]; then
  while ! [[ "$vlan_subnet_range" = *.*.*.*/* ]]
  do
    echo -e "\nWhat is the vlan subnet-range (for example: 10.35.166.0/24) ?"
    read -r vlan_subnet_range
  done

  while ! [[ "$vlan_gateway" = *.*.*.* ]]
  do
    echo -e "\nWhat is the vlan gateway (for example: 10.35.166.254) ?"
    read -r vlan_gateway
  done

  while ! [[ "$vlan_start" = *.*.*.* ]]
  do
    echo -e "\nWhat is the vlan allocation pool start (for example: 10.35.166.100) ?"
    read -r vlan_start
  done

  while ! [[ "$vlan_end" = *.*.*.* ]]
  do
    echo -e "\nWhat is the vlan allocation pool start (for example: 10.35.166.140) ?"
    read -r vlan_end
  done

  while ! [[ "$vlan_id" =~ ^([0-9]+)$ ]]
  do
    echo -e "\nWhat is the vlan provider-segment (for example: 181)?"
    read -r vlan_id
  done
fi

# Getting number of networks to create
while ! [[ "$net_num" =~ ^([0-9]+)$ && "$net_num" -le "100" && "$net_num" -gt "0" ]]
do
  echo -e "\nHow many internal networks do you want to create (1-100) ?"
  read -r net_num
done

# Getting number of VM instances to create
while ! [[ "$inst_num" =~ ^([0-9]+)$ && "$inst_num" -le "100" && "$inst_num" -gt "0" ]]
do
  echo -e "\nHow many VM instances do you want to create (1-100) ?
${YELLOW}NOTICE:${NO_CLR} In a multiple VMs topology (mvi)- it's the number of instances per network!
The total number of instances will be ${YELLOW}N X $net_num ${NO_CLR}."
  read -r inst_num
done

# Running CLEANUP if required (cleanup_needed = YES)
if ! [[ "$cleanup_needed" =~ ^(NO|YES)$ ]]; then
  echo -e "\n${YELLOW}NOTICE: Before starting, do you want to remove ALL exiting VMs and Networks ? ${NO_CLR}
Press enter to skip, otherwise enter in upper-case: YES"
  read -r cleanup_needed
  cleanup_needed=${cleanup_needed:-NO}
fi

if  [[ $cleanup_needed = YES ]];  then
  echo -e "\n* Deleting all VM instances"
  for vm in $(openstack server list --all -c ID -f value | grep -v "^$"); do echo -e ".\c"; openstack server delete $vm; done

  for router in $(openstack router list -c ID -f value | grep -v "^$"); do
    echo -e "\n* Removing all subnets from router (ID: $router)"
    for subnet in $(openstack subnet list -c ID -f value | grep -v "^$"); do echo -e ".\c"; openstack $debug router remove subnet $router $subnet; done
  done

  echo -e "\n* Deleting all floating ips"
  for fip in $(openstack floating ip list -c ID -f value | grep -v "^$"); do echo -e ".\c"; openstack $debug floating ip delete $fip; done

  #for OSP 13 might need to use: neutron router-gateway-clear
  echo -e "\n* Unsetting external gateway from all routers"
  for router in $(openstack router list -c ID -f value | grep -v "^$"); do echo -e ".\c"; openstack $debug router unset --external-gateway $router; done

  echo -e "\n* Deleting all trunks"
  for trunk in $(openstack network trunk list -c ID -f value | grep -v "^$"); do echo -e ".\c"; openstack $debug network trunk delete $trunk; done

  echo -e "\n* Deleting all ports"
  for port in $(openstack port list -c ID -f value | grep -v "^$"); do echo -e ".\c"; openstack $debug port delete $port; done

  echo -e "\n* Deleting all subnets"
  for subnet in $(openstack network list --internal -c Subnets -f value | tr -d "," | grep -v "^$"); do echo -e ".\c"; openstack $debug subnet delete $subnet; done

  echo -e "\n* Deleting all routers"
  for router in $(openstack router list -c ID -f value | grep -v "^$"); do echo -e ".\c"; openstack $debug router delete $router; done

  echo -e "\n* Deleting all internal networks"
  for network in $(openstack network list --internal -c ID -f value | grep -v "^$"); do echo -e ".\c"; openstack $debug network delete $network; done

  if [[ "$external_network_type" =~ ^(flat|vlan)$ ]]; then
    echo -e "\n* You've requested to re-create external network - Deleting all external networks and subnets."
    for subnet in $(openstack subnet list -c ID -f value | grep -v "^$"); do echo -e ".\c"; openstack $debug subnet delete $subnet; done
    for network in $(openstack network list --external -c ID -f value | grep -v "^$"); do echo -e ".\c"; openstack $debug network delete $network; done
  fi

  echo -e "\n* Deleting all VM images"
  for img in $(openstack image list -c ID -f value | grep -v "^$"); do echo -e ".\c"; openstack $debug image delete $img; done

  echo -e "\n* Deleting all VM flavors"
  for flavor in $(openstack flavor list -c ID -f value | grep -v "^$"); do echo -e ".\c"; openstack $debug flavor delete $flavor; done

  echo -e "\n* Deleting all security groups"
  for secgroup in $(openstack security group list -c ID -f value | grep -v "^$"); do echo -e ".\c"; openstack $debug security group delete $secgroup; done

  echo -e "\n* Deleting Tenant test project and user"
  rm -rf tester_key.pem
  openstack project list | grep test_cloud && openstack $debug project delete test_cloud || echo No project test_cloud
  openstack user list | grep tester && openstack $debug user delete tester || echo No user tester
  #rm -rf tester_rc
fi

# Creating a new external network, if requested
if [[ $external_network_type = vlan ]]; then
  openstack $debug network create --provider-network-type vlan  --provider-segment "$vlan_id" --provider-physical-network datacentre --external  nova
  openstack $debug subnet create --subnet-range "$vlan_subnet_range" --network nova  --no-dhcp --gateway "$vlan_gateway"  --allocation-pool start="$vlan_start",end="$vlan_end" nova
else
  if [[ $external_network_type = flat ]]; then
  openstack $debug network create --provider-network-type flat  --provider-physical-network datacentre --external  nova
  openstack $debug subnet create --subnet-range 10.0.0.0/24 --network nova  --no-dhcp --gateway 10.0.0.1  --allocation-pool start=10.0.0.210,end=10.0.0.250 nova
  fi
fi

# Getting external network name, and if it is not yet created, exiting with Error
ext_net=$(openstack network list --external -c Name -f value)

if [[ -z "$ext_net" ]]; then
  echo -e "\nError: ${RED}External network was not created, exiting!${NO_CLR}"
  exit 1
fi

# Downloading and creating images & flavors
if [[ $image = cirros35 ]]; then
  # cirros image
  echo -e "\n* Creating CirrOS 0.3.5 Image:"
  wget -N https://download.cirros-cloud.net/0.3.5/cirros-0.3.5-x86_64-disk.img --no-check-certificate
  openstack $debug image create --container-format bare --disk-format qcow2 --public --file cirros-0.3.5-x86_64-disk.img cirros35

  # cirros flavor
  echo -e "\n* Creating CirrOS Flavor:"
  flavor=cirros_flavor
  openstack flavor show $flavor || openstack $debug flavor create --public $flavor --id auto --ram 512 --disk 1 --vcpus 1
  ssh_user=cirros

else
  if [[ $image = rhel74 ]]; then
    # rhel v7.4 image
    echo -e "\n* Creating RHEL v7.4 Image:"
    wget -N http://file.tlv.redhat.com/~ekuris/custom_ci_image/rhel-guest-image-7.4-191.x86_64.qcow2
    openstack $debug image create --container-format bare --disk-format qcow2 --public --file rhel-guest-image-7.4-191.x86_64.qcow2 rhel74
  else
    if [[ $image = rhel75 ]]; then
      # rhel v7.5 image
      echo -e "\n* Creating RHEL v7.5 Image:"
      #wget -N http://file.tlv.redhat.com/~ekuris/custom_ci_image/rhel-guest-image-7.5-137.x86_64.qcow2
      #openstack image create $image --container-format bare --disk-format qcow2 --public --file rhel-guest-image-7.5-137.x86_64.qcow2
      wget -N http://file.tlv.redhat.com/~nmanos/rhel-guest-image-7.5-146_apache_php.qcow2
      openstack $debug image create $image --container-format bare --disk-format qcow2 --public --file rhel-guest-image-7.5-146_apache_php.qcow2
    fi
  fi

  # rhel flavor
  echo -e "\n* Creating RHEL Flavor:"
  flavor=rhel_flavor
  openstack flavor show $flavor || openstack $debug flavor create --public $flavor --id auto --ram 1024 --disk 10 --vcpus 1
  ssh_user=cloud-user
fi


# Creating tenant tester (privalaged user)

echo -e "\n* Create Tenant user \"tester\" - privilaged user (non-admin):"
openstack $debug project create test_cloud --enable
openstack $debug user create tester --enable --password testerpass --project test_cloud
openstack $debug role add _member_ --user tester --project test_cloud
openstack user list
openstack role list

echo -e "\n* Create a \"tester_rc\" file, similar to \"overcloudrc\", but with tester limited access:"
KEYSTONE_PUBLIC_IP=$(openstack endpoint list | grep keystone.*public | awk -F'\\||//|:' '{print $10}')
echo echo -e "\n* Keystone Public IP: $KEYSTONE_PUBLIC_IP"

KEYSTONE_ADMIN_IP=$(openstack endpoint list | grep keystone.*admin | awk -F'\\||//|:' '{print $10}')
echo echo -e "\n* Keystone Admin IP: $KEYSTONE_ADMIN_IP"

cat > tester_rc <<EOF
# Clear any old environment that may conflict.
for key in \$( set | awk '{FS="="}  /^OS_/ {print \$1}' ); do unset \$key ; done
export OS_NO_CACHE=True
export COMPUTE_API_VERSION=1.1
export OS_USERNAME=tester
export no_proxy=,${KEYSTONE_PUBLIC_IP},${KEYSTONE_PUBLIC_IP}
export OS_USER_DOMAIN_NAME=Default
export OS_VOLUME_API_VERSION=3
export OS_CLOUDNAME=tester
export OS_AUTH_URL=http://${KEYSTONE_PUBLIC_IP}:5000//v3
export NOVA_VERSION=1.1
export OS_IMAGE_API_VERSION=2
export OS_PASSWORD=testerpass
export OS_PROJECT_DOMAIN_NAME=Default
export OS_IDENTITY_API_VERSION=3
export OS_PROJECT_NAME=test_cloud
export OS_AUTH_TYPE=password
export PYTHONWARNINGS="ignore:Certificate has no, ignore:A true SSLContext object is not available"

# Add OS_CLOUDNAME to PS1
if [ -z "\${CLOUDPROMPT_ENABLED:-}" ]; then
    export PS1=\${PS1:-""}
    export PS1=\\\${OS_CLOUDNAME:+"(\\\$OS_CLOUDNAME)"}\ \$PS1
    export CLOUDPROMPT_ENABLED=1
fi

# Add Timestamp to PS1
if [ -z "\${TIMESTAMP_ENABLED:-}" ]; then
    export PS1="[\\\$(date +%T.%3N)] \$PS1"
    export TIMESTAMP_ENABLED=1
fi
EOF

# Print diff between tester_rc and overcloudrc
diff tester_rc overcloudrc || echo -e "\n* New env. file \"tester_rc\" was created."

# Running actions as tenant tester (privalaged user)
echo -e "\n* Sourcing \"tester_rc\" environment to run actions as tenant \"tester\" (privalaged user):"
. tester_rc

echo -e "\n* Creating Router and $net_num Networks - each one with both IPv4 and IPv6 Subnets:"
# Create networks
openstack $debug router create Router_eNet
router_id=$(openstack router list | grep -m 1 Router_eNet | cut -d " " -f 2)

# Create networks and sub-networks
for i in `seq 1 $net_num`; do
  #create sub network with IPv4 & IPv6
  echo -e "\n* Creating Network net_ipv64_$i:"
  openstack $debug network create net_ipv64_$i
  echo -e "\n* Creating ipv4 Subnet on net_ipv64_$i - subnet_ipv4_$i:"
  openstack $debug subnet create --subnet-range 10.0.$i.0/24  --network net_ipv64_$i --dhcp subnet_ipv4_$i
  echo -e "\n* Creating ipv6 Subnet on net_ipv64_$i - subnet_ipv6_$i:"
  openstack $debug subnet create --subnet-range 200$i::/64 --network net_ipv64_$i  --ipv6-address-mode slaac  --ipv6-ra-mode slaac --ip-version 6 subnet_ipv6_$i

  #add the subnet to the router
  echo -e "\n* Adding subnet_ipv4_$i and subnet_ipv6_$i to the router."
  openstack $debug router add subnet $router_id subnet_ipv4_$i
  openstack $debug router add subnet $router_id subnet_ipv6_$i
done


#create external gateway
echo -e "\n* Connecting the router to the external network \"$ext_net\""
if [[ $osp_version > 10 ]]; then
  openstack $debug router set --external-gateway $ext_net $router_id
else
  neutron $debug router-gateway-set $router_id $ext_net
fi

#create security group
echo -e "\n* Creating security group rules for group \"sec_group\""
sec_id=$(openstack security group create sec_group | awk -F'[ \t]*\\|[ \t]*' '/ id / {print $3}')

#create security group rules
openstack $debug security group rule create $sec_id --protocol tcp --dst-port 80 --remote-ip 0.0.0.0/0
openstack $debug security group rule create $sec_id --protocol tcp --dst-port 22 --remote-ip 0.0.0.0/0
openstack $debug security group rule create $sec_id --protocol tcp --dst-port 443 --remote-ip 0.0.0.0/0
openstack $debug security group rule create $sec_id --protocol icmp --dst-port -1 --remote-ip 0.0.0.0/0

# openstack $debug security group rule create --protocol icmp --ingress --prefix 0.0.0.0/0 $sec_id
# openstack $debug security group rule create --protocol tcp --ingress --prefix 0.0.0.0/0 $sec_id
# openstack $debug security group rule create --protocol udp --ingress --prefix 0.0.0.0/0 $sec_id
# openstack $debug security group rule create --protocol icmp --ingress --ethertype IPv6 $sec_id
# openstack $debug security group rule create --protocol tcp --ingress --ethertype IPv6 $sec_id
# openstack $debug security group rule create --protocol udp --ingress --ethertype IPv6 $sec_id

openstack security group rule list

#Create RSA private-key:
echo -e "\n* Creating openstack key pair to easily login into VMs:"
#openstack keypair create tester-key --private-key tester_key.pem
openstack keypair list | grep tester-key || openstack $debug keypair create tester-key --private-key tester_key.pem
chmod 400 tester_key.pem
openstack keypair list

###### Seting Networks and VMs topology

#create for each VM - multiple NICs (mni)
if  [[ $topology = mni ]];  then
  #Create VM instanses:"
  echo -e "\n* Creating $inst_num VM instanses."
  for i in `seq 1 $inst_num`; do
     image_id=$(openstack image list | grep $image | head -1 | cut -d " " -f 2)
     vm_name=${image}_vm${i}

     nics=""
     for n in `seq 1 $net_num`; do
       nics="$nics --nic net-id=net_ipv64_$n"
     done

     echo -e "\n* Creating and booting VM instance with ${net_num} NICs: ${vm_name}"

     #openstack server create --flavor $flavor --image $image_id $nics --security-group $sec_id --key-name tester-key $vm_name
     #until openstack server show $vm_name | grep -E 'ACTIVE' -B 5; do sleep 1 ; done

     #openstack server create --flavor $flavor --image $image_id $nics --security-group $sec_id --key-name tester-key $vm_name |& tee _temp.out
     #vm_id=$(cat _temp.out | awk -F'[ \t]*\\|[ \t]*' '/ id / {print $3}')

     openstack $debug server create --flavor $flavor --image $image_id $nics --security-group $sec_id --key-name tester-key $vm_name
     vm_id=$(openstack server list -c ID -f value | head -1)
     until openstack server show $vm_id | grep -E 'ACTIVE' -B 5; do sleep 1 ; done

     ipv4s=$(openstack server show $vm_id -c addresses -f value | sed -r "s/\w+:+//g" | sed -r "s/\w{4}(,|;)//g")
     echo -e "\n* Configuring Networks for each of the $net_num NICs: $ipv4s"

     # loop over addresses of each NIC inside VM (net_ipv64_1, net_ipv64_2, etc.)
     # And create multiple floating ips in VM (FIP for each NIC)
     for n in `seq 1 $net_num`; do

       fip=$(openstack floating ip create $ext_net -c floating_ip_address -f value)

       #openstack $debug server add floating ip $vm_id $fip --fixed-ip-address
       #openstack $debug server add floating ip $vm_id $fip

       #int_ip=$(openstack server list | grep $vm_id | awk '{ gsub(/[,=\|]/, " " ); print $6; }')
       #int_ip=$(openstack server show $vm_id -c addresses -f value | awk -F net_ipv64_${n}= '{print $2}' | cut -d ',' -f 1)

       int_ip=$(echo $ipv4s | awk -F net_ipv64_${n}= '{print $2}' | cut -d ',' -f 1 | tr -d ' ')
       port_id=$(openstack port list | grep $int_ip | cut -d ' ' -f 2)

       echo -e "\n* Adding floating ip $fip to $vm_name, and connecting to IP $int_ip (Port $port_id)."
       openstack $debug floating ip set --port $port_id $fip
       sleep 10

       # openstack port list | grep $int_ip | sed -E 's/(\||\s+)/ /g'
       # port_id=$(openstack port list | grep -A1 $int_ip | cut -d " " -f 2)
       # port_id=$(openstack floating ip show $fip -c port_id -f value)

       echo -e "\n* Setting a name to the port of the new floating ip: \"${vm_name}_${fip}\""
       openstack $debug port set $port_id --name "${vm_name}_${fip}"
       openstack $debug port show $port_id

       echo -e "\n* Waiting for Port status to be ACTIVE on $vm_name, with internal IP address $int_ip:\n"
       until openstack port show $port_id | grep -E 'ACTIVE' -B 14; do sleep 1 ; done

       # until ping -c1 $fip ; do sleep 1 ; done
       ping -w 30 -c 5 ${fip:-NO_FIP}
       curl $fip:80
       #curl $fip:443

       echo -e "\n* Generate ssh key to access ${vm_name} on ${fip}, and checking ssh uptime:"
       ssh-keygen -f ~/.ssh/known_hosts -R $fip
       ssh -i tester_key.pem -o "StrictHostKeyChecking no" ${ssh_user}@${fip} uptime
     done
  done
fi

#create for each Network - multiple VM instances (mvi)
if  [[ $topology = mvi ]];  then
  echo -e "\n* For each Network - creating $inst_num VM instances:"
  for n in `seq 1 $net_num`; do
    #Create VM instanses:"
    for i in `seq 1 $inst_num`; do
      #create one floating ip for each VM instance
      fip=$(openstack floating ip create $ext_net -c floating_ip_address -f value)

      image_id=$(openstack image list | grep $image | head -1 | cut -d " " -f 2)
      vm_name=${image}_vm${i}_net${n}

      echo -e "\n* Creating and booting VM instance: ${vm_name}, connected to network net_ipv64_${n}:"

      # openstack server create --flavor $flavor --image $image_id --nic net-id=net_ipv64_$n --security-group $sec_id --key-name tester-key $vm_name
      # until openstack server show $vm_name | grep -E 'ACTIVE' -B 5; do sleep 1 ; done

      # openstack server create --flavor $flavor --image $image_id --nic net-id=net_ipv64_$n --security-group $sec_id --key-name tester-key $vm_name |& tee _temp.out
      # vm_id=$(cat _temp.out | awk -F'[ \t]*\\|[ \t]*' '/ id / {print $3}')
      # until openstack server show $vm_id | grep -E 'ACTIVE' -B 5; do sleep 1 ; done

      openstack $debug server create --flavor $flavor --image $image_id --nic net-id=net_ipv64_$n --security-group $sec_id --key-name tester-key $vm_name
      vm_id=$(openstack server list -c ID -f value | head -1)
      until openstack server show $vm_id | grep -E 'ACTIVE' -B 5; do sleep 1 ; done

      echo -e "\n* Adding floating ip $fip to $vm_name, and checking connectivity:"
      #openstack $debug server add floating ip $vm_name $fip --fixed-ip-address
      openstack $debug server add floating ip $vm_id $fip
      sleep 10

      int_ip=$(openstack server list | grep $vm_id | awk '{ gsub(/[,=\|]/, " " ); print $6; }')
      # openstack port list | grep $int_ip | sed -E 's/(\||\s+)/ /g'
      # port_id=$(openstack port list | grep -A1 $int_ip | cut -d " " -f 2)
      port_id=$(openstack floating ip show $fip -c port_id -f value)

      echo -e "\n* Setting a name to the port of the new floating ip: \"${vm_name}_${fip}\""
      openstack $debug port set $port_id --name "${vm_name}_${fip}"
      openstack $debug port show $port_id

      echo -e "\n* Waiting for Port status to be ACTIVE on $vm_name, with internal IP address $int_ip:"
      until openstack port show $port_id | grep -E 'ACTIVE' -B 14; do sleep 1 ; done

      # until ping -c1 $fip ; do sleep 1 ; done
      ping -w 30 -c 5 ${fip:-NO_FIP}
      curl $fip:80
      #curl $fip:443

      echo -e "\n* Generate ssh key to access $vm_name on $fip, and checking ssh uptime:"
      ssh-keygen -f ~/.ssh/known_hosts -R $fip
      ssh -i tester_key.pem -o "StrictHostKeyChecking no" ${ssh_user}@${fip} uptime
    done
  done
fi

openstack router list
openstack port list
openstack server list

echo -e "\n----------------------------------------------------------------------------------------------------
Creating and testing multiple VMs and Networks completed. Please verify output contains no failures.
"

echo "To SSH into VM:
ssh -i tester_key.pem ${ssh_user}@SERVER_FIP"

#echo "root password to rhel images is: 12345678"
#echo "password for cirros is cubswin:)"
