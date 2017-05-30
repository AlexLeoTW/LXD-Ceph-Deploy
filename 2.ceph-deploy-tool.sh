#! /bin/bash

hosts=( )
mon_hosts=( )
deploy_user="ceph-deploy"
deploy_user_pass=""

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

# ================= ceph host config =================
                                                                                # create ceph-deploy user
title "ceph-deploy-tool" "create ceph-deploy user [$deploy_user] in each host"

for (( i=0; i<${#hosts}; i++ )); do
    # adduser --disabled-password --gecos "" $deploy_user
    # lxc exec ${hosts[i]} -- adduser --disabled-password --gecos "" $deploy_user
    # echo "$deploy_user_pass" | passwd "$deploy_user" --stdin
    # lxc exec ${hosts[i]} -- echo "$deploy_user:$deploy_user_pass" | chpasswd
    # adduser $deploy_user sudo
    lxc exec ${hosts[i]} -- adduser $deploy_user sudo
    # echo "${deploy_user} ALL = (root) NOPASSWD:ALL" | tee /etc/sudoers.d/${deploy_user}
    lxc exec ${hosts[i]} -- bash -c "echo \"${deploy_user} ALL = (root) NOPASSWD:ALL\" > /etc/sudoers.d/${deploy_user}"
    # sudo chmod 0440 /etc/sudoers.d/${deploy_user}
    lxc exec ${hosts[i]} -- chmod 0440 /etc/sudoers.d/${deploy_user}
done

# ==================================

title "ceph-deploy-tool" "push config.sh"                                       # push config.sh

cp config.sh temp/config.sh
sed -i "/deploy_user_pass/d" temp/config.sh
for (( i = 0; i < ${#hosts}; i++ )); do
    echo "push to ${hosts[i]}"
    lxc file push temp/config.sh ${hosts[i]}/home/$deploy_user/config.sh
done
rm temp/config.sh

# ==================================


for (( i = 0; i < ${#hosts}; i++ )); do                                         # launch ceph preflight
    title "ceph-deploy-tool" "launch ceph preflight on ${hosts[i]}"

    lxc file push files/ceph_install_1_preflight.sh ${hosts[i]}/home/$deploy_user/ceph_install_1_preflight.sh
    lxc exec ${hosts[i]} -- bash -c "chmod +x /home/$deploy_user/ceph_install_1_preflight.sh"
    lxc exec ${hosts[i]} -- bash -c "/home/$deploy_user/ceph_install_1_preflight.sh"
done

# ==================================

title "ceph-deploy-tool" "distrobute ssh keys"                                  # distrobute ssh keys

for (( i=0; i<${#mon_hosts[@]}; i++ )); do

    if [[ -f /home/$deploy_user/.ssh/id_rsa ]]; then
        lxc exec ${mon_hosts[i]} -- "ssh-keygen -t rsa -N \"\" -f /home/$deploy_user/.ssh/id_rsa"
    fi

    echo "pull id_rsa.pub from ${mon_hosts[i]}"
    lxc file pull ${mon_hosts[i]}/home/$deploy_user/.ssh/id_rsa.pub temp/${mon_hosts[i]}.hostkey.pub
    echo -e "\n\n*** key: ***"
    cat temp/${mon_hosts[i]}.hostkey.pub
    echo -e "************\n\n"

    for (( j=0; j<${#hosts[@]}; j++ )); do
        echo "temp/${mon_hosts[i]}.hostkey.pub --> ${hosts[j]}/home/$deploy_user/deplyHost.key --> authorized_keys"
        lxc file push temp/${mon_hosts[i]}.hostkey.pub ${hosts[j]}/home/$deploy_user/deplyHost.key
        lxc exec ${hosts[j]} -- bash -c "cat /home/$deploy_user/deplyHost.key >> /home/$deploy_user/.ssh/authorized_keys"
        lxc exec ${hosts[j]} -- bash -c "rm /home/$deploy_user/deplyHost.key"

        sudossh "$deploy_user" "$deploy_user" "${hosts[i]}" "echo SSH OK!"
    done

    rm temp/${mon_hosts[i]}.hostkey.pub

done

# ==================================
