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

sudo apt-get update -y
sudo apt-get install kubeadm -y
kubeadm version

echo -e "========== Enable iptables bridge call =========="
echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

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

# Configure nat in mac

sudo pfctl -s nat
sudo sysctl -w net.inet.ip.forwarding=1

vi /etc/pf.conf
nat on en0 from 192.168.56.0/24 to any -> (en0)

sudo pfctl -nf /etc/pf.conf
sudo pfctl -f /etc/pf.conf

sudo pfctl -sn
