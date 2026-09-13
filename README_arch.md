# ArchLinux Install script

## 1. Install Step

### 1.1. If use ssh install

```shell
passwd
```

```shell
ssh root@remote
```

### 1.2. Clone arch-install

```shell
pacman -Sy
pacman -S git
```

```shell
git clone https://github.com/pixb/dotfiles.git
```

### 1.3. Partation

```shell
lsblk
fdisk /dev/sda
```

- `boot`: 1G
- `swap`: 16G
- `root`: all.

fdisk

- `g`: GPT
- `n`: New Partation

```shell
mkfs.ext4 /dev/sda3
mkfs.fat -F32 /dev/sda1
mkswap /dev/sda2
swapon /dev/sda2
```

### 1.4. Mount

```shell
mount /dev/sda3 /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot
```

### 1.5. Base Install to mnt

```bash
cd dotfiles
bash scripts/arch_install_init.sh
```

### 1.6. Genfstab

```bash
genfstab -U /mnt >>/mnt/etc/fstab
```

### 1.7. Move dotfiles to /mnt/root

```bash
mv dotfiles /mnt/root
```

### 1.8. arch-chroot

```bash
arch-chroot /mnt
cd /root/dotfiles
bash scripts/arch_install_root.sh
```

### 1.9. Complete install and exit

```bash
exit
umount -a
reboot
```

## 2. First boot and install

### 2.1. Sync all package

Set pacman.conf

```bash
sudo nvim /etc/pacman.conf
```

Open `[multilib]`

Set `mirror list`

```bash
sudo nvim /etc/pacman.d/mirrorlist
```

Move `## China` mirrorlist to Top.

```bash
sudo pacman -Syyu
```

### 2.1. Add ssh key to github

```bash
ssh-keygen -t rsa
cat ~/.ssh/id_rsa.pub
```

### 2.2. Clone self

```bash
cd ~
git clone git@github.com:pixb/dotfiles.git
```

### 2.3. Install_user

```bash
cd dotfiles
bash scripts/arch_install_user.sh
```

## Install scripts

### install_init.sh

pacstrap install to /mnt.

## `kvm_install.sh`

安装`kvm`虚拟机脚本。
参考`kvm`笔记。
