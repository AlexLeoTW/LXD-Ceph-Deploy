#! /bin/bash

cd "${0%/*}"

deploy_user="ceph-deploy"
source config.sh

apt install ntp -y
apt install openssh-server -y

apt purge ceph ceph-common ceph-dbg ceph-deploy ceph-fs-common ceph-fuse ceph-mds -y
apt autoremove -y

wget -q -O- 'https://download.ceph.com/keys/release.asc' | apt-key add -
echo deb https://download.ceph.com/debian-kraken/ "$(lsb_release -sc)" main | tee /etc/apt/sources.list.d/ceph.list
apt update
apt install ceph-deploy -y


# config firewell
apt install ufw -y
sed -i -- 's/IPV6=yes/IPV6=no/g' /etc/default/ufw
ufw allow ssh
ufw allow 6789/tcp
ufw allow 6800:7300/tcp
ufw enable
ufw status

# running as deploy_user
chown -R $deploy_user:$deploy_user /home/$deploy_user
su $deploy_user -c "ssh-keygen -t rsa -N \"\" -f /home/$deploy_user/.ssh/id_rsa"
