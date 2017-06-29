#!/usr/bin/env bash

MASTER_DNS=$1
LOCATION=$2
MASTER_USERNAME=$3
BASED_PRIVATE_KEY=$4
REGISTRY_NAME=$5
REGISTRY_PASS=$6
STORAGE_ACCOUNT=$7
STORAGE_LOCATION=$8

export STORAGE_ACCOUNT=$7
export STORAGE_LOCATION=$8

PRIVATE_KEY='private_key'

MASTER_URL=${MASTER_DNS}.${LOCATION}.cloudapp.azure.com

# prerequisite
sudo apt-get update
sudo apt-get install unzip

# install kubectl
cd /tmp
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# write private key
echo ${BASED_PRIVATE_KEY} | base64 -d | tee ${PRIVATE_KEY}
chmod 400 ${PRIVATE_KEY}

yes | scp -i ${PRIVATE_KEY} ${MASTER_USERNAME}@${MASTER_URL}:.kube/config ~/.kube/config

# install helm
curl -s https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
helm init

# download templates
REPO_URL='https://github.com/yaweiw/elk-acs-kubernetes-template/archive/develop.zip'

curl -LO ${REPO_URL}
unzip develop.zip -d template
cd template
bash docker/push-images.sh ${REGISTRY_NAME} ${REGISTRY_PASS}
bash helm-charts/start-elk.sh ${REGISTRY_NAME} ${REGISTRY_PASS}
