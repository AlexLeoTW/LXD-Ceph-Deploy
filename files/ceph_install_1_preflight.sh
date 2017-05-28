#! /bin/bash

deploy_user="ceph-deploy"
source config.sh

apt install ntp
apt install openssh-server

apt purge ceph ceph-common ceph-dbg ceph-deploy ceph-fs-common ceph-fuse ceph-mds
apt autoremove

wget -q -O- 'https://download.ceph.com/keys/release.asc' | apt-key add -
echo deb https://download.ceph.com/debian-kraken/ "$(lsb_release -sc)" main | tee /etc/apt/sources.list.d/ceph.list
apt update
apt install ceph-deploy


# config firewell
apt install ufw
ufw allow ssh
ufw allow 6789/tcp
ufw allow 6800:7300/tcp

# running as deploy_user
su $deploy_user
ssh-keygen -t rsa -N "" -f /home/$deploy_user/.ssh/id_rsa
