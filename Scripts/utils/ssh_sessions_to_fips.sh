#!/bin/bash
# This script creates ssh connection to each floating ip and starts infinite ping
# from each fip to an ip address 10.0.0.1 in the external network.
# Each session runs in separate screen.

[ -z $1 ] && echo "Usage $0 [start|stop|status]" && exit 1
cmd=$1
if [ -e ~/overcloudrc ];then 
  . ~/overcloudrc 
else
  echo Missing environment file 
  exit 1
fi

install_screen(){
  sudo yum install screen -y
}

start_sessions(){
  for fip in $fips ; do
    screen -dm -S session_to_${fip} /bin/bash -c "sshpass -p 'cubswin:)' ssh cirros@$fip 'ping 10.0.0.1' "
  done
}

kill_sessions(){
sessions=$(screen -ls | grep  session_to )
for s in $sessions; do
  screen -X -S $s quit
done
}

if [ ! -e /bin/screen ]; then
  install_screen
fi

case $cmd in
  start)
    echo Getting list of fips
    fips=$(openstack floating ip list -c 'Floating IP Address' -f value)
    echo Starting ssh to fips and ping external host
    start_sessions
    ;;
  stop)
    kill_sessions
    ;;
  status)
    screen -ls
    ;;
  *)
    echo Command not found
    ;;
esac

