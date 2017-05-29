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
fi

# ================= ceph host config =================
                                                                                # create ceph-deploy user
title "ceph-deploy-tool" "create ceph-deploy user [$deploy_user] in each host"

for (( i=0; i<${#hosts}; i++ )); do
    # adduser --disabled-password --gecos "" $deploy_user
    lxc exec ${hosts[i]} -- adduser --disabled-password --gecos "" $deploy_user
    # echo "$deploy_user_pass" | passwd "$deploy_user" --stdin
    lxc exec ${hosts[i]} -- echo "$deploy_user_pass" | passwd "$deploy_user" --stdin
    # adduser $deploy_user sudo
    lxc exec ${hosts[i]} -- adduser $deploy_user sudo
    # echo "${deploy_user} ALL = (root) NOPASSWD:ALL" | tee /etc/sudoers.d/${deploy_user}
    lxc exec ${hosts[i]} -- echo "${deploy_user} ALL = (root) NOPASSWD:ALL" | tee /etc/sudoers.d/${deploy_user}
    # sudo chmod 0440 /etc/sudoers.d/${deploy_user}
    lxc exec ${hosts[i]} -- chmod 0440 /etc/sudoers.d/${deploy_user}
done

# ==================================

title "ceph-deploy-tool" "push config.sh"                             # push config.sh

cp config.sh temp/config.sh
sed -i "/deploy_user_pass/d" temp/config.sh
for (( i = 0; i < ${#hosts}; i++ )); do
    lxc file push temp/config.sh ${hosts[i]}/home/$deploy_user/config.sh
done
rm temp/config.sh

# ==================================

title "ceph-deploy-tool" "config ceph repo"                           # launch ceph preflight

for (( i = 0; i < ${#hosts}; i++ )); do
    lxc file push files/ceph_install_1_preflight.sh ${hosts[i]}/home/$deploy_user/my-cluster/ceph_install_1_preflight.sh
    lxc exec ${hosts[i]} -- chmod +x /home/$deploy_user/ceph_install_1_preflight.sh
    lxc exec ${hosts[i]} -- /home/$deploy_user/ceph_install_1_preflight.sh
done

# ==================================

title "ceph-deploy-tool" "distrobute ssh keys"                        # distrobute ssh keys

for (( index=0; index<${#mon_hosts[@]}; index++ )); do

    if [[ -f /home/$deploy_user/.ssh/id_rsa ]]; then
        lxc exec ${mon_hosts[index]} -- ssh-keygen -t rsa -N "" -f /home/$deploy_user/.ssh/id_rsa
    fi

    lxc file pull ${mon_hosts[index]}/home/$deploy_user/.ssh/id_rsa.pub temp/${mon_hosts[index]}.hostkey.pub

    for (( i=0; i<${#hosts[@]}; i++ )); do
        lxc file push temp/${mon_hosts[index]}.hostkey.pub ${hosts[i]}/home/$deploy_user/deplyHost.key
        lxc exec ${hosts[i]} -- cat /home/$deploy_user/deplyHost.key >> /home/$deploy_user/.ssh/authorized_keys
        lxc exec ${hosts[i]} -- rm /home/$deploy_user/deplyHost.key
    done

    rm temp/${mon_hosts[index]}.hostkey.pub

done

# ==================================
