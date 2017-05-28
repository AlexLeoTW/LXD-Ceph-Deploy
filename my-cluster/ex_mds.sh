# deploy MDS
ceph-deploy mds create Ceph-Main

# create fs
ceph osd pool create cephfs_data 128

ceph osd pool create cephfs_metadata 32

ceph osd lspools

ceph fs new cephfs cephfs_metadata cephfs_data

ceph fs ls

ceph status

# mount cephfs
ssh ubuntu@Ceph-Main sudo apt install ceph-fs-common

ceph auth get-or-create client.Ceph-Main mon 'allow r' mds 'allow rw' osd 'allow rw pool=cephfs_data, allow rw pool=cephfs_metadata' -o client.Ceph-Main.key

ssh ubuntu@Ceph-Main sudo cp client.Ceph-Main.key /etc/ceph/Ceph-Main.secret

ssh ubuntu@Ceph-Main sudo chmod 440 /etc/ceph/Ceph-Main.secret

ssh ubuntu@Ceph-Main sudo mkdir /mnt/mycephfs

ssh ubuntu@Ceph-Main sudo mount -t ceph Ceph-Main:6789,MS05:6789:/ /mnt/mycephfs -o name=Ceph-Main,secretfile=/etc/ceph/Ceph-Main.secret

# setup fstab
echo "Back UP old fstab"

ssh ubuntu@Ceph-Main sudo cp /etc/fstab /etc/fstab.bak

ssh ubuntu@Ceph-Main echo "# Ceph_NASfs" >> sudo tee -a /etc/fstab

ssh ubuntu@Ceph-Main echo "Ceph-Main:6789,MS05:6789:/	/mnt/mycephfs	ceph	name=Ceph-Main,secretfile=/etc/ceph/Ceph-Main.secret	0	2" >> sudo tee -a /etc/fstab



