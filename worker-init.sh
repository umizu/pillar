#!/bin/bash

# disable swap 
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

sudo hostnamectl set-hostname ${hostname}
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
