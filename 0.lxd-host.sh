#! /bin/bash
# shellcheck source=config.sh

netif="eth0"
source config.sh

# test for sudo
if [[ $UID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
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
echo "please manually execute \"sudo lxd init\""
# ================= end of =================
# ================= lxd config =================
