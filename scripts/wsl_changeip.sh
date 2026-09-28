#!/usr/bin/env bash

# 生成随机 MAC 地址
NEW_MAC="02:$(openssl rand -hex 5 | sed 's/\(..\)/\1:/g; s/:$//')"
echo "新 MAC 地址: $NEW_MAC"

sudo ip link set eth0 down
# sudo ip link set eth0 address 02:11:22:33:44:55
sudo ip link set eth0 address "$NEW_MAC"
sudo ip link set eth0 up
