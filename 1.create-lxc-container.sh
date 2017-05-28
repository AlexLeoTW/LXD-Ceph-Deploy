#! /bin/bash

hosts=( )
host_ip=( )
netmask="255.255.255.0"
gateway="192.168.1.1"
deploy_user="ceph-deploy"
# shellcheck source=config.sh
source config.sh

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

for (( i=0; i<${#hosts[@]}; i++ )); do                                          # delete old lxd with the same name
    echo "$(title "ceph host config" "delete LXD host:${hosts[i]}")"
    echo "stop ${hosts[i]} from LXD"
    lxc stop ${hosts[i]}
    echo "delete ${hosts[i]} from LXD"
    lxc delete ${hosts[i]}
done

# ==================================

for (( i=0; i<${#hosts[@]}; i++ )); do                                          # init all lxd with hosts[]
    echo "$(title "ceph host config" "create LXD host:${hosts[i]}")"
    echo "initial ${hosts[i]} for LXD"
    lxc launch ubuntu:16.04 ${hosts[i]}
    lxc config set ${hosts[i]} security.privileged true
    lxc config set ${hosts[i]} limits.memory 2GB
done

# ==================================

echo "$(title "ceph host config" "config /etc/hostname for ${hosts[i]}")"       # config /etc/hostname
lxc exec ${hosts[i]} -- echo ${hosts[i]} > /etc/hostname

# ==================================

for (( i=0; i<${#hosts[@]}; i++ )); do                                          # config static IP lxd host
    echo "$(title "ceph host config" "config static IP for ${hosts[i]}")"       # containers DOWN
    lxc exec ${hosts[i]} -- cp /etc/network/interfaces /etc/network/interfaces.bak
    lxc stop ${hosts[i]}
    lxc file pull ${hosts[i]}/etc/network/interfaces temp/container_if
    cat templates/etc_network_interfaces_static_ip >> temp/container_if
    sed -i 's/^source/#source/g' temp/container_if
    sed -i "s/%host_ip%/${host_ip[i]}/g" temp/container_if
    sed -i "s/%netmask%/${netmask}/g" temp/container_if
    sed -i "s/%gateway%/${gateway}/g" temp/container_if
    echo "*** config: ***"
    cat temp/container_if
    echo "***************"
    lxc file push temp/container_if ${hosts[i]}/etc/network/interfaces
    rm temp/container_if
done

# ==================================

echo "$(title "ceph host config" "setup ~/.ssh/config")"                        # setup /etc/hosts
file_path="temp/ceph_etc_hosts"                                                 # containers DOWN
# create %ceph_hosts% entry
for (( i=0; i<${#hosts[@]}; i++ )); do
  echo "${hosts[i]} ${host_ip[i]}" >> temp/ceph_hosts
done

for (( i=0; i<${#hosts[@]}; i++ )); do
  cp ./templates/etc_hosts $file_path
  sed -i "s/%hostname%/${hosts[i]}/g" $file_path
  sed -i "s/%ceph_hosts%/$(cat ceph_hosts)/g" $file_path

  lxc file push $file_path ${hosts[i]}/etc/hosts
  rm $file_path
done

# ==================================

echo "$(title "ceph host config" "setup ~/.ssh/config")"                        # setup ~/.ssh/config
                                                                                # containers DOWN
file_path="temp/ssh_config"

for (( i=0; i<${#hosts[@]}; i++ )); do
    echo "writing ${hosts[i]} into $file_path"
    cat files/ssh_config_template >> $file_path
    sed -i "s/%hostname%/${hosts[i]}/g" $file_path
    sed -i "s/%ceph_user%/$deploy_user/g" $file_path
done

echo "$(title "ceph host config" "config ~/.ssh/config for ${hosts[i]}")"
lxc push temp_ssh_config ${hosts[i]}/home/$deploy_user/.ssh/config

# ==================================

lxc start ${hosts[i]}                                                           # launch host

# ================= ceph host config =================
