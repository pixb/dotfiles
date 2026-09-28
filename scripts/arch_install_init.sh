#!/bin/env bash
pacstrap -i /mnt/ base linux linux-firmware lvm2 linux-headers --noconfirm
#genfstab -U /mnt >>/mnt/etc/fstab
