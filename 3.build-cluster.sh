#! /bin/bash

hosts=( )
mon_hosts=( )
mon_ip=( )
osd_hosts=( )
osd_disks=( )
mds_hosts=( )
deploy_user="ceph-deploy"
# shellcheck disable=SC2164
local_user="$(cd ~; pwd | sed "s/\/home\///g")"

# shellcheck source=config.sh
source config.sh
# shellcheck source=files/functions.sh
source files/functions.sh

# test for sudo
if [[ $UID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

# create temp directory
if [[ ! -d temp ]]; then
    mkdir temp
else
    rm temp/*
fi

# ================= build ceph cluster =================

title "build-ceph-cluster" "build ceph.conf"                                    # build ceph.conf

cp templates/ceph_conf_template temp/ceph.conf
sed -i "s/%new_fsid%/$(uuidgen)/g" temp/ceph.conf

mon_list=$(arrayToString mon_hosts[@] ", ")
mon_ip_list=$(arrayToString mon_ip[@] ", ")

printf "mon_list=[%s]\n" "$mon_list"
printf "mon_ip_list=[%s]\n" "$mon_ip_list"

sed -i -- "s/%mon_hosts%/${mon_list}/g" temp/ceph.conf
sed -i -- "s/%mon_ip%/${mon_ip_list}/g" temp/ceph.conf
sed -i -- "s/%osd_size%/${#osd_hosts[@]}/g" temp/ceph.conf

for (( i=0; i<${#mon_hosts[@]}; i++ )); do
   cat templates/ceph_config_entry_mon_template >> temp/ceph.conf.mon
   sed -i "s/%hostname%/${mon_hosts[i]}/g" temp/ceph.conf.mon
   sed -i "s/%host_ip%/${mon_ip[i]}/g" temp/ceph.conf.mon
done

for (( i=0; i<${#osd_hosts[@]}; i++ )); do
   cat templates/ceph_config_entry_template >> temp/ceph.conf.osd
   sed -i "s/%type%/osd/g" temp/ceph.conf.osd
   sed -i "s/%hostname%/${osd_hosts[i]}/g" temp/ceph.conf.osd
done

for (( i=0; i<${#mds_hosts[@]}; i++ )); do
    cat templates/ceph_config_entry_template >> temp/ceph.conf.mds
    sed -i "s/%type%/mds/g" temp/ceph.conf.mds
    sed -i "s/%hostname%/${mds_hosts[i]}/g" temp/ceph.conf.mds
done

lineReplace temp/ceph.conf %mon_hosts_detial% "$(cat temp/ceph.conf.mon)"
lineReplace temp/ceph.conf %osd_hosts_detial% "$(cat temp/ceph.conf.osd)"
lineReplace temp/ceph.conf %mds_hosts_detial% "$(cat temp/ceph.conf.mds)"

rm temp/ceph.conf.mon
rm temp/ceph.conf.osd
rm temp/ceph.conf.mds

echo -e "\n\n*** ceph.conf: ***"
    cat temp/ceph.conf
echo -e "******************\n\n"

lxc file push temp/ceph.conf ${mon_hosts[0]}/home/$deploy_user/ceph.conf

# ==================================

title "ceph host config" "mapping physical drives"                              # mapping physical drives
for (( i=0; i<${#osd_hosts[@]}; i++ )); do
    echo "lxc config device add ${osd_hosts[i]} sda unix-block path=${osd_disks[i]}"
    lxc stop ${osd_hosts[i]}
    lxc config device add ${osd_hosts[i]} sda unix-block path=${osd_disks[i]}
    lxc start ${osd_hosts[i]}
done

# ==================================

title "build-ceph-cluster" "setup ssh key for manage node (${mon_hosts[0]})"    # setup ssh key for manage node
if [[ ! -f ~/.ssh/id_rsa ]]; then
    ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
fi
echo -e "\n*** key: ***"
cat ~/.ssh/id_rsa.pub
echo -e "************\n"
lxc exec ${mon_hosts[0]} -- bash -c "echo \"$(cat ~/.ssh/id_rsa.pub)\" >> /home/$deploy_user/.ssh/authorized_keys"

# ==================================

title "build-ceph-cluster" "really deploying cluster"                           # really deploying cluster

lxc exec ${mon_hosts[0]} -- chown -R $deploy_user:$deploy_user /home/$deploy_user

echo -e "installing ceph package for all lxc hosts\n"
# shellcheck disable=SC2145
sudossh "$local_user" "$deploy_user" "${mon_ip[0]}" "ceph-deploy install $(arrayToString hosts[@] " ")"

echo "add the initial monitor(s) and gather the keys"
sudossh "$local_user" "$deploy_user" "${mon_ip[0]}" 'ceph-deploy mon create-initial'

for (( i=0; i<${#osd_hosts[@]}; i++ )); do
    echo "build osd ${osd_hosts[i]}:${osd_disks[i]}"
    sudossh "$local_user" "$deploy_user" "${mon_ip[0]}" "ceph-deploy disk zap ${osd_hosts[i]}:${osd_disks[i]}"
    sudossh "$local_user" "$deploy_user" "${mon_ip[0]}" "ceph-deploy osd create ${osd_hosts[i]}:${osd_disks[i]}"
done

ssh -o StrictHostKeyChecking=no ${deploy_user}@${mon_ip[0]} ceph-deploy admin ${mon_hosts[0]}
for (( i=0; i<${#osd_hosts[@]}; i++ )); do
    sudossh "$local_user" "$deploy_user" "${mon_ip[0]}" "ssh ${deploy_user}@${osd_hosts[i]} sudo chmod +r /etc/ceph/ceph.client.admin.keyring"
done

echo -e "\n\n*** ceph health ***"
sudossh "$local_user" "$deploy_user" "${mon_ip[0]}" "ceph health"
echo -e "*******************\n\n"
