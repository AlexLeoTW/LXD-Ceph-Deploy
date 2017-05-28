#! /bin/bash

netif="eth0"
hosts=( )
host_ip=( )
netmask="255.255.255.0"
gateway="192.168.1.1"
mon_hosts=( )
osd_hosts=( )
osd_disks=( )
deploy_user="ceph-deploy"

# shellcheck source=config.sh
source config.sh

# test for sudo
if [[ $UID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# ================= support function =================
function title() {
   echo '.'
   echo ''
   echo "========================="
   echo "$1"
   if [[ $2 -ne '' ]]; then
      echo "   $2"
   fi
   echo "========================="
   echo ''
   echo '.'
}
# ================= end of =================
# ================= support function =================

# create temp directory
if [[ ! -d temp ]]; then
   mkdir temp
fi

# ================= network config =================

# do a quick system update
echo "$(title "network config" "do a quick system update")"
apt update && apt upgrade -y

# config bridge
echo "$(title "network config" "install bridge-utils")"
apt install bridge-utils -y

echo "$(title "network config" "config bridge")"
if [[ $netif != "br0" ]]; then
   echo "" >> /etc/network/interfaces
   echo "# Bridged Setup" >> /etc/network/interfaces
   echo "auto br0" >> /etc/network/interfaces
   echo "iface br0 inet dhcp" >> /etc/network/interfaces
   echo "	bridge_ports enp1s0" >> /etc/network/interfaces
   echo "" >> /etc/network/interfaces
   echo "iface enp1s0 inet manual" >> /etc/network/interfaces
fi

sudo ifdown $netif && sudo ifup $netif && sudo ifup br0

# ================= end of =================
# ================= network config =================



# ================= lxd config =================

echo "$(title "lxd config" "install lxd & zfs package")"
apt-get install lxd zfsutils-linux -y

echo "$(title "lxd config" "manual init config")"
echo "recommand:"
echo "
    Do you want to configure a new storage pool (yes/no) [default=yes]? yes
    Name of the new storage pool [default=default]: lxdpool
    Name of the storage backend to use (dir, zfs) [default=zfs]: zfs
    Create a new ZFS pool (yes/no) [default=yes]? yes
    Would you like to use an existing block device (yes/no) [default=no]? yes
    Path to the existing block device: /dev/sdb
    Would you like LXD to be available over the network (yes/no) [default=no]? no
    Would you like stale cached images to be updated automatically (yes/no) [default=yes]? yes
    Would you like to create a new network bridge (yes/no) [default=yes]? no
    LXD has been successfully configured.
"
# ================= end of =================
# ================= lxd config =================



# ================= ceph host config =================
echo "$(title "ceph host config" "intital containers")"

echo "$(title "ceph host config" "generate ssh config")"
for (( i=0; i<${#hosts[@]}; i++ )); do
    cat files/ssh_config_template >> temp_ssh_config
    sed -i "s/%hostname%/${hosts[i]}/g" temp_ssh_config
    sed -i "s/%ceph_user%/$deploy_user/g" temp_ssh_config
done

for (( i=0; i<${#hosts[@]}; i++ )); do

  echo "$(title "ceph host config" "intital host:${hosts[i]}")"
  echo "stop ${hosts[i]} from LXD"
  lxc stop ${hosts[i]}
  echo "delete ${hosts[i]} from LXD"
  lxc delete ${hosts[i]}

  echo "initial ${hosts[i]} for LXD"
  lxc launch ubuntu:16.04 ${hosts[i]}
  lxc config set ${hosts[i]} security.privileged true
  lxc config set ${hosts[i]} limits.memory 2GB

  echo "$(title "ceph host config" "config network for ${hosts[i]}")"
  lxc exec ${hosts[i]} -- cp /etc/network/interfaces /etc/network/interfaces.bak
  lxc stop ${hosts[i]}
  lxc file pull ${hosts[i]}/etc/network/interfaces container_if
  cat files/etc_network_interfaces >> container_if
  sed -i 's/^source/#source/g' container_if
  sed -i "s/%host_ip%/${host_ip[i]}/g" container_if
  sed -i "s/%netmask%/${netmask}/g" container_if
  sed -i "s/%gateway%/${gateway}/g" container_if
  echo "*** config: ***"
  cat container_if
  echo "***************"
  lxc file push container_if ${hosts[i]}/etc/network/interfaces
  rm container_if

  echo "$(title "ceph host config" "config /etc/hostname for ${hosts[i]}")"
  lxc exec ${hosts[i]} -- echo ${hosts[i]} > /etc/hostname
  echo "$(title "ceph host config" "config ~/.ssh/config for ${hosts[i]}")"
  lxc push temp_ssh_config ${hosts[i]}/home/$deploy_user/.ssh/config

  lxc start ${hosts[i]}
done

echo "$(title "ceph host config" "set /etc/hosts")"
lxc stop ${hosts[i]}
# create %ceph_hosts% entry
for (( i=0; i<${#hosts[@]}; i++ )); do
  echo "${hosts[i]} ${host_ip[i]}" >> ceph_hosts
done
# write files to lxc
for (( i=0; i<${#hosts[@]}; i++ )); do
  cp ./files/etc_hosts temp_hosts
  sed -i "s/%hostname%/${hosts[i]}/g" temp_hosts
  sed -i "s/%ceph_hosts%/$(cat ceph_hosts)/g" temp_hosts

  lxc file push temp_hosts ${hosts[i]}/etc/hosts
  rm temp_hosts
done
rm ceph_hosts
lxc start ${hosts[i]}

echo "$(title "ceph host config" "mapping physical devices")"
for (( i=0; i<${#osd_hosts[@]}; i++ )); do
  lxc stop ${hosts[i]}
  lxc config device add ${osd_hosts[i]} sda unix-block path=${osd_disks[i]}
  lxc start ${hosts[i]}
done
# ================= end of =================
# ================= ceph host config =================




# ================= install ceph =================
# push config.sh
for (( i = 0; i < ${#hosts}; i++ )); do
   lxc file push config.sh ${hosts[i]}/home/$deploy_user/my-cluster/config.sh
done

# preflight
for (( i = 0; i < ${#hosts}; i++ )); do
   lxc file push files/ceph_install_1_preflight.sh ${hosts[i]}/home/$deploy_user/my-cluster/ceph_install_1_preflight.sh
   lxc exec ${hosts[i]} -- chmod +x /home/$deploy_user/ceph_install_1_preflight.sh
   lxc exec ${hosts[i]} -- /home/$deploy_user/ceph_install_1_preflight.sh
done

# setup ssh keys
ceph_install_2_mon_ceph-deploy.sh

# setup ceph.config
for (( i=0; i<${#mon_hosts}; i++ )); do
   cat files/ceph_conf_entry_mon_template >> temp/config_connfig_mon
   sed -i "s/%hostname%/${hosts[i]}/g" temp_hosts
done

cat files/ceph_conf_entry_template
# ================= end of =================
# ================= install ceph =================
