#!/usr/bin/env bash

set -e

MASTER_DNS=$1
LOCATION=$2
MASTER_USERNAME=$3
NGINX_PASSWORD=$4
BASED_PRIVATE_KEY=$5
REGISTRY_NAME=$6
REGISTRY_PASS=$7

export REGISTRY_URL=${REGISTRY_NAME}.azurecr.io
export STORAGE_ACCOUNT=$8
export STORAGE_LOCATION=$9

PRIVATE_KEY='private_key'

MASTER_URL=${MASTER_DNS}.${LOCATION}.cloudapp.azure.com

export KUBECONFIG=/root/.kube/config

# prerequisite
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
apt-cache policy docker-ce
sudo apt-get install -y unzip docker-ce nginx apache2-utils

# install kubectl
cd /tmp
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# write private key
echo "${BASED_PRIVATE_KEY}" | base64 -d | tee ${PRIVATE_KEY}
chmod 400 ${PRIVATE_KEY}

mkdir -p /root/.kube
scp -o StrictHostKeyChecking=no -i ${PRIVATE_KEY} ${MASTER_USERNAME}@${MASTER_URL}:.kube/config ${KUBECONFIG}
kubectl get nodes

# install helm
curl -s https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
helm init

# download templates
REPO_URL='https://github.com/yaweiw/elk-acs-kubernetes-template/archive/develop.zip'

curl -LO ${REPO_URL}
unzip -o develop.zip -d template

# expose kubectl proxy
cd template/elk-acs-kubernetes-template-develop
echo ${NGINX_PASSWORD} | htpasswd -c -i /etc/nginx/.htpasswd ${MASTER_USERNAME}
cp nginx-site.conf /etc/nginx/sites-available/default
nohup kubectl proxy --port=8080 &
systemctl reload nginx

# push image & helm install 
cd docker
bash push-images.sh ${REGISTRY_NAME} ${REGISTRY_PASS}
cd ../helm-charts
bash start-elk.sh ${REGISTRY_NAME} ${REGISTRY_PASS}
