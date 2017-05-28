echo "backup old config"
mv ceph.conf ceph.conf.bk

echo "[global]" >> ceph.conf
echo "fsid = $(uuidgen)" >> ceph.conf
echo "fsid = $(uuidgen)"
cat ceph.conf.templete >> ceph.conf
