#! /bin/bash

hosts=( )
host_ip=( )
netmask="255.255.255.0"
gateway="192.168.1.1"
nameserver="192.168.1.1"
deploy_user="ceph-deploy"
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

title "ceph host config" "delete old lxd with the same name"                    # delete old lxd with the same name

for (( i=0; i<${#hosts[@]}; i++ )); do
    echo "stop ${hosts[i]} from LXD"
    lxc stop ${hosts[i]}
    echo "delete ${hosts[i]} from LXD"
    lxc delete ${hosts[i]}
done

# ==================================

for (( i=0; i<${#hosts[@]}; i++ )); do
    title "ceph host config" "init lxd: ${hosts[i]}"                            # init lxd: ${hosts[i]}

    echo "initial ${hosts[i]} for LXD"
    lxc launch ubuntu:16.04 ${hosts[i]}
    lxc config set ${hosts[i]} security.privileged true
    lxc config set ${hosts[i]} limits.memory 2GB
    sleep 10
    lxc exec ${hosts[i]} -- adduser --disabled-password --gecos "" $deploy_user
    lxc exec ${hosts[i]} -- apt update
    lxc exec ${hosts[i]} -- apt upgrade -y
done

# ==================================

# title "ceph host config" "config /etc/hostname for all hosts"                   # config /etc/hostname
# lxc did this by default
# lxc exec ${hosts[i]} -- "\'echo ${hosts[i]} > /etc/hostname\'"

# ==================================

for (( i=0; i<${#hosts[@]}; i++ )); do                                          # config static IP lxd host
    title "ceph host config" "config static IP for ${hosts[i]}"
    lxc exec ${hosts[i]} -- apt install network-manager -y

    # remove ifupdown config
    lxc exec ${hosts[i]} -- cp /etc/network/interfaces /etc/network/interfaces.bak
    lxc exec ${hosts[i]} -- sed -i 's/^source/#source/g' /etc/network/interfaces

    # config NetworkManager
    lxc exec ${hosts[i]} -- systemctl start network-manager
    lxc exec ${hosts[i]} -- systemctl enable network-manager
    lxc exec ${hosts[i]} -- nmcli con add type ethernet con-name eth0 ifname eth0 ip4 ${host_ip[i]}/${netmask} gw4 ${gateway}
    lxc exec ${hosts[i]} -- nmcli con mod eth0 ipv4.dns "8.8.8.8 8.8.4.4"
    lxc exec ${hosts[i]} -- nmcli con up eth0
    sleep 5
    lxc exec ${hosts[i]} -- nmcli dev disconnect eth0
    sleep 2
    lxc exec ${hosts[i]} -- nmcli dev connect eth0
    sleep 2

    echo "*** config: ***"
    lxc exec ${hosts[i]} -- cat /etc/NetworkManager/system-connections/eth0
    echo "***************"
    lxc exec ${hosts[i]} -- nmcli con show

done

# ==================================

title "ceph host config" "setup /etc/hosts"                                     # setup /etc/hosts
file_path="temp/ceph_etc_hosts"                                                 # containers DOWN
# create %ceph_hosts% entry
for (( i=0; i<${#hosts[@]}; i++ )); do
    lxc stop ${hosts[i]}
    echo -e "${host_ip[i]}\t${hosts[i]}" >> temp/ceph_hosts
done

for (( i=0; i<${#hosts[@]}; i++ )); do
    cp ./templates/etc_hosts $file_path
    sed -i "s/%hostname%/${hosts[i]}/g" $file_path
    lineReplace $file_path %ceph_hosts% "$(cat temp/ceph_hosts)"

    lxc file push $file_path ${hosts[i]}/etc/hosts
    echo -e "\n\n*** config: ***"
    cat $file_path
    echo "***************"

    rm $file_path
done

# ==================================

title "ceph host config" "setup ~/.ssh/config"                                  # setup ~/.ssh/config
                                                                                # containers DOWN
file_path="temp/ssh_config"

for (( i=0; i<${#hosts[@]}; i++ )); do
    echo "writing ${hosts[i]} into $file_path"
    cat templates/ssh_config_entry >> $file_path
    sed -i "s/%hostname%/${hosts[i]}/g" $file_path
    sed -i "s/%ceph_user%/$deploy_user/g" $file_path
done

echo "*** config: ***"
cat $file_path
echo "***************"

for (( i=0; i<${#hosts[@]}; i++ )); do
    echo "push to ${hosts[i]}"
    lxc start ${hosts[i]}
    lxc exec ${hosts[i]} -- mkdir -p /home/$deploy_user/.ssh
    lxc file push $file_path ${hosts[i]}/home/$deploy_user/.ssh/config
done

# ==================================
# title "ceph host config" "launch host"                                          # launch host
# for (( i=0; i<${#hosts[@]}; i++ )); do
#     echo "launch ${hosts[i]}"
#     lxc start ${hosts[i]}
# done
