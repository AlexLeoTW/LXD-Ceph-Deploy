#! /bin/bash

osd_hosts=( osd0 osd1 )
osd_disks=( "/dev/sda" "/dev/sdc" )

for (( i=0; i<${#osd_hosts[@]}; i++ ));
do
  echo lxc config device add ${osd_hosts[i]} sda unix-block path=${osd_disks[i]}
done
