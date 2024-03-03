#!/bin/bash

# disable swap 
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

sudo hostnamectl set-hostname ${ctrl_plane_name}
echo -e "${ctrl_plane_name} ${ctrl_plane_ip}\n\
${worker1_name} ${worker1_ip}\n\
${worker2_name} ${worker2_ip}" | sudo tee -a /etc/hosts

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

# install containerd
sudo apt update
sudo apt -y install containerd

# add default config for containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo systemctl restart containerd

# install kubeadm, kubelet, kubectl
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
# If the folder `/etc/apt/keyrings` does not exist, it should be created before the curl command
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet=1.29.2-1.1 kubeadm=1.29.2-1.1 kubectl=1.29.2-1.1
# fixates the version
sudo apt-mark hold kubelet kubeadm kubectl

# init node as control plane
sudo kubeadm init

# set up kubeconfig
mkdir -p ~/.kube
sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
