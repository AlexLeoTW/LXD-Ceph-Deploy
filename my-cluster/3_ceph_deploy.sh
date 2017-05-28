ceph-deploy install Ceph-Main MS05

ceph-deploy mon create-initial

ceph-deploy disk zap Ceph-Main:sda

ceph-deploy osd create Ceph-Main:sda

ceph-deploy disk zap MS05:sda

ceph-deploy osd create --fs-type btrfs MS05:sda

ceph-deploy admin Ceph-Main MS05

ssh ubuntu@Ceph-Main sudo chmod +r /etc/ceph/ceph.client.admin.keyring

ssh ubuntu@MS05 sudo chmod +r /etc/ceph/ceph.client.admin.keyring

ceph health
