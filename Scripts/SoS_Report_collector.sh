#!/bin/bash

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

echo "Attempting to install sshpass"
sudo yum install -y sshpass
if [ "$?" != "0" ]; then
   echo "Error! Was not able to install sshpass. Exiting..."
   exit 1
fi

read -p "Please enter your kerberos username: " username
read -s -p "Please enter your kerberos password: " password
echo ""
read -p "Please enter the bz ID you provide the sosreports for: " bug_id

SOSREPORTS_DIR="sosreports"
REMOTE_DIR=/var/www/html/log/bz${bug_id}
echo "Creating the directory on a corporate machine"
sshpass -p $password ssh -o StrictHostKeyChecking=no ${username}@rhos-release.virt.bos.redhat.com "if [ ! -d $REMOTE_DIR ]; then mkdir $REMOTE_DIR; fi"

if [ ! -d $SOSREPORTS_DIR ]; then
    mkdir $SOSREPORTS_DIR;
fi
for i in `nova list|awk '/ACTIVE/ {print $(NF-1)}'|awk -F"=" '{print $NF}'`; do echo $i; ssh -o StrictHostKeyChecking=no heat-admin@$i "sudo sosreport --batch; sudo chown heat-admin  /var/tmp/sosreport*"; scp -o StrictHostKeyChecking=no heat-admin@$i:/var/tmp/sosreport*.tar.xz $SOSREPORTS_DIR; done

sudo sosreport --batch; sudo cp /var/tmp/sosreport*.tar.xz $SOSREPORTS_DIR
sudo chown $USER $SOSREPORTS_DIR/*

echo "Copying the results to the publicly available URL"
sshpass -p $password /usr/bin/scp -o StrictHostKeyChecking=no  $SOSREPORTS_DIR/*  ${username}@rhos-release.virt.bos.redhat.com:$REMOTE_DIR
sshpass -p $password ssh -o StrictHostKeyChecking=no ${username}@rhos-release.virt.bos.redhat.com "chmod go+r $REMOTE_DIR/*"
if [ "$?" == "0" ]; then
    echo "The reports should be available here: http://rhos-release.virt.bos.redhat.com/log/bz${bug_id}"
else
    echo "Error! There was a problem uploading the sosreports."
    exit 1
fi
