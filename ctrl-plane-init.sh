#!/bin/bash

sudo swapoff -a
sudo hostnamectl set-hostname ${ctrl_plane_name}

echo -e "${ctrl_plane_name} ${ctrl_plane_ip}}\n\
    ${worker1_name} ${worker1_ip}\n\
    ${worker2_name} ${worker2_ip}" | sudo tee -a /etc/hosts

