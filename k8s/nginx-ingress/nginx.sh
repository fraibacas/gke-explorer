#!/bin/bash

# based on https://zihao.me/post/cheap-out-google-container-engine-load-balancer/

export CLUSTER_NAME=paco
# create load balancer's static ip
gcloud compute addresses create $CLUSTER_NAME-ip --region us-central1
export LB_ADDRESS_IP=$(gcloud compute addresses list | grep $CLUSTER_NAME-ip | awk '{print $3}')

# create cluster with one instance
gcloud container clusters create $CLUSTER_NAME --disable-addons HttpLoadBalancing
gcloud container clusters get-credentials $CLUSTER_NAME

# re-assign static ip to instance
export LB_INSTANCE_NAME=$(kubectl describe nodes | head -n1 | awk '{print $2}')
export LB_INSTANCE_NAT=$(gcloud compute instances describe $LB_INSTANCE_NAME | grep -A3 networkInterfaces: | tail -n1 | awk -F': ' '{print $2}')
gcloud compute instances delete-access-config $LB_INSTANCE_NAME --access-config-name "$LB_INSTANCE_NAT"
gcloud compute instances add-access-config $LB_INSTANCE_NAME --access-config-name "$LB_INSTANCE_NAT" --address $LB_ADDRESS_IP

# label our load balancer node
kubectl label nodes $LB_INSTANCE_NAME role=load-balancer

# enable http ports for load balancer
gcloud compute instances add-tags $LB_INSTANCE_NAME --tags http-server,https-server