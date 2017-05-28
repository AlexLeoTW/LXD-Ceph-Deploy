# Software Plan

-------

## Network

### ✔ br0

[LXD, ZFS and bridged networking on Ubuntu 16.04 LTS+ | Jason Bayton](https://bayton.org/docs/linux/lxd/lxd-zfs-and-bridged-networking-on-ubuntu-16-04-lts/)

install bridge package:

`sudo apt install bridge-utils`

edit `/etc/network/interfaces`:

```
# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto br0
iface br0 inet dhcp
	bridge_ports eth0

iface eth0 inet manual
```
restart network interface:

`sudo ifdown eth0 && sudo ifup eth0 && sudo ifup br0`

### macvlan with Additional IP

[5.1 LXC with Advanced Networking - www.bonsaiframework.com - Bonsai Framework](http://www.bonsaiframework.com/wiki/display/bonsai/5.1+LXC+with+Advanced+Networking)

-------

## Storage

### ✔ /dev/sda3 with loopback `zfs` devices

run `sudo lxd init`:

```
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
```

__verify__:

`lxc info`

```
... cut ....
 storage: zfs
 storage_version: 0.6.5.9-2
```
