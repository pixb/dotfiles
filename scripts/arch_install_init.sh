#!/bin/env bash
pacstrap -i /mnt/ base linux-lts linux-firmware lvm2 linux-lts-headers --noconfirm
#genfstab -U /mnt >>/mnt/etc/fstab
