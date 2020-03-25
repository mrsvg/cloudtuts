#!/bin/bash

read -p "Node Hostname: " HOSTNAME
read -p "Node Type (m/s): " TYPE

echo -e "========== Update OS =========="
sudo apt-get update -y
sudo hostnamectl set-hostname $HOSTNAME
echo -e "========== Turn Off SWAP Memory =========="
sudo swapoff -a
sudo sed -i 's/\/swapfile/#\/swapfile/g' /etc/fstab

echo -e "========== Install Docker =========="
sudo apt-get install docker.io -y
sudo systemctl enable docker
sudo systemctl start docker
sudo docker --version

echo -e "========== Install Kubernetes =========="
sudo apt-get install apt-transport-https curl -y
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"

sudo apt-get install kubeadm -y
kubeadm version


if [ $TYPE == "m" ]
then
  echo -e "========== Configure Kubernetes =========="
  sudo kubeadm init --pod-network-cidr=10.244.0.0/16
  sudo mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

  kubectl get nodes

  echo -e "========== Add Flannel Networks =========="
  sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

  kubeadm token create --ttl 0 --print-join-command >> token.txt
  kubectl api-versions

fi

echo -e "========== Reboot OS =========="
sudo reboot -f

