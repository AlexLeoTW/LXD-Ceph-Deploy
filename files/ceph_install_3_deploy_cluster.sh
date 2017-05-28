#! /bin/bash

deploy_user="ceph-deploy"
source config.sh

cd /home/$deploy_user/my-cluster || return
