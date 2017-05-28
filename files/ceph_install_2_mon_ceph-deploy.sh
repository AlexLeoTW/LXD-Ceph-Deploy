#! /bin/bash

deploy_user="ceph-deploy"
hosts=( )
mon_hosts=( )
source ../config.sh

for (( index=0; index<${#mon_hosts[@]}; index++ )); do

    if [[ -f /home/$deploy_user/.ssh/id_rsa ]]; then
        lxc exec ${mon_hosts[index]} -- ssh-keygen -t rsa -N "" -f /home/$deploy_user/.ssh/id_rsa
    fi

    lxc file pull ${mon_hosts[index]}/home/$deploy_user/.ssh/id_rsa.pub hostkey.pub

    for (( i=0; i<${#hosts[@]}; i++ )); do
        lxc file push hostkey.pub ${hosts[i]}/home/$deploy_user/deplyHost.key
        lxc exec ${hosts[i]} -- cat /home/$deploy_user/deplyHost.key >> /home/$deploy_user/.ssh/authorized_keys
        lxc exec ${hosts[i]} -- rm /home/$deploy_user/deplyHost.key
    done

    rm hostkey.pub

done
