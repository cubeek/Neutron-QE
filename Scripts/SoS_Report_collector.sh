#!/bin/bash
##########################################################################################
# Maintained by Eran Kuris and Noam Manos, 2018 ##########################################
#
# This script creates RHEL SOS-REPORTs on Openstack Undercloud and on all Overcloud nodes,
# and uploads it to http://rhos-release.virt.bos.redhat.com/log
# with a BZ number (or current date if BZ not specified) as URL to be added to Bugzilla.
#
##########################################################################################

if [ "$USER" != "stack" ];then
    echo "Must use the stack user. Exiting."
    exit 1
fi

ENV_FILE=/home/stack/stackrc
if [ ! -f $ENV_FILE ]; then
    echo "Can't find the environment file. Exiting..."
    exit 1
else
    source $ENV_FILE
fi

read -p "Please enter your kerberos username: " username
read -s -p "Please enter your kerberos password: " password
echo ""
read -p "Please enter the bz ID you provide the sosreports for: " bug_id


echo "Attempting to install sshpass"
sudo yum install -y sshpass
if [ "$?" != "0" ]; then
   echo "Error! Was not able to install sshpass. Exiting..."
   exit 1
fi

timestamp="`date +%d-%m-%Y_%H%M`"
SOSREPORTS_DIR="sosreports/$timestamp"
REMOTE_DIR="/var/www/html/log/bz${bug_id:-$timestamp}"
SOS_CMD="sudo sosreport --verbose --batch --tmp-dir $SOSREPORTS_DIR --alloptions --profile=openstack,openstack_undercloud,openstack_controller --enable-plugins=openstack_neutron"

echo "Creating the directory on a corporate machine"
sshpass -p $password ssh -o StrictHostKeyChecking=no ${username}@rhos-release.virt.bos.redhat.com "if [ ! -d $REMOTE_DIR ]; then mkdir -p $REMOTE_DIR; fi"

echo "Creating the directory on local host (Undercloud)"
if [ ! -d $SOSREPORTS_DIR ]; then
    mkdir -p $SOSREPORTS_DIR;
fi

for node in `nova list|awk '/ACTIVE/ {print $(NF-1)}'|awk -F"=" '{print $NF}'`; do
  echo "Generating SOS Report on $node";
  ssh -o StrictHostKeyChecking=no heat-admin@$node "if [ ! -d $SOSREPORTS_DIR ]; then sudo mkdir -p $SOSREPORTS_DIR; fi"
  ssh -o StrictHostKeyChecking=no heat-admin@$node "$SOS_CMD; sudo tar tvf $SOSREPORTS_DIR/*.tar.xz | grep var/log; sudo chown heat-admin $SOSREPORTS_DIR/*";
  scp -o StrictHostKeyChecking=no heat-admin@$node:$SOSREPORTS_DIR/sosreport*.tar.xz $SOSREPORTS_DIR;
done

echo "Generating SOS Report on local host (Undercloud)"
$SOS_CMD
sudo chown $USER $SOSREPORTS_DIR/*

echo "Copying the results to the publicly available URL"
sshpass -p $password /usr/bin/scp -o StrictHostKeyChecking=no $SOSREPORTS_DIR/*  ${username}@rhos-release.virt.bos.redhat.com:$REMOTE_DIR
sshpass -p $password ssh -o StrictHostKeyChecking=no ${username}@rhos-release.virt.bos.redhat.com "chmod go+r $REMOTE_DIR/*"
if [ "$?" == "0" ]; then
    echo "The reports should be available here: http://rhos-release.virt.bos.redhat.com/log/bz${bug_id:-$timestamp}"
else
    echo "Error! There was a problem uploading the sosreports."
    exit 1
fi
