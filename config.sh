#! /bin/bash

netif=$(route | grep default | grep -oE '[^ ]+$')

hosts=( mon0 osd0 osd1 mds0 )
host_ip=( "192.168.1.100" "192.168.1.101" "192.168.1.102" "192.168.1.105" )
netmask="255.255.255.0"
gateway="192.168.1.1"

mon_hosts=( mon0 )
mon_ip=( "192.168.1.100" )
osd_hosts=( osd0 osd1 )
osd_ip=( "192.168.1.101" "192.168.1.102" "192.168.1.105" )
osd_disks=( "/dev/sda" "/dev/sdc" )
mds_hosts=( mds0 )

deploy_user="ceph-deploy"
