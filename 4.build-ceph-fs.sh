#! /bin/bash

mon_hosts=( )
mds_hosts=( )

# shellcheck source=config.sh
source config.sh
# shellcheck source=files/functions.sh
source files/functions.sh

# ================= build ceph-fs =================

title "build ceph-fs" "deploy mds"                                              # deploy mds

for (( i=0; i<${#mds_hosts[@]}; i++ )); do
    lxc exec ${mon_hosts[0]} -- ceph-deploy mds create ${mds_hosts[i]}
done

# ==================================

title "build ceph-fs" "deploy ceph-fs"                                          # deploy ceph-fs

lxc exec ${mon_hosts[0]} -- ceph osd pool create cephfs_data 128
lxc exec ${mon_hosts[0]} -- ceph osd pool create cephfs_metadata 32
lxc exec ${mon_hosts[0]} -- ceph osd lspools

lxc exec ${mon_hosts[0]} -- ceph fs new cephfs cephfs_metadata cephfs_data
lxc exec ${mon_hosts[0]} -- ceph fs ls

lxc exec ${mon_hosts[0]} -- ceph status

# ==================================
