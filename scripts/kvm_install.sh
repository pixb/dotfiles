#!/usr/bin/env bash

# === KVM/QEMU/Libvirt Installation Script (CLI only) for Arch Linux ===
# Installs KVM stack for command-line management via virsh/virt-install.
# Reference: ArchWiki - QEMU, libvirt

set -euo pipefail

COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[0;33m'
COLOR_NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1
SCRIPT_FULL_NAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_FILE_NAME="${SCRIPT_FULL_NAME%.*}"

echo -e "${COLOR_GREEN}SCRIPT_DIR = ${SCRIPT_DIR} ${COLOR_NC}"
echo -e "${COLOR_GREEN}SCRIPT_FULL_NAME = ${SCRIPT_FULL_NAME} ${COLOR_NC}"
echo -e "${COLOR_GREEN}SCRIPT_FILE_NAME = ${SCRIPT_FILE_NAME} ${COLOR_NC}"

warn() { echo -e "${COLOR_YELLOW}[warn] $*${COLOR_NC}" >&2; }
die()  { echo -e "${COLOR_RED}[fail] $*${COLOR_NC}" >&2; exit 1; }

check_install() {
  pacman -Qi "$1" >/dev/null 2>&1
}

pacman_install() {
  for pkg in "$@"; do
    if ! check_install "$pkg"; then
      echo -e "${COLOR_GREEN}Installing $pkg...${COLOR_NC}"
      sudo pacman -S "$pkg" --noconfirm --needed || die "Failed to install $pkg"
    else
      echo -e "${COLOR_GREEN}$pkg already installed${COLOR_NC}"
    fi
  done
}

systemctl_enable_now() {
  if [ "$(systemctl is-enabled "$1" 2>/dev/null || true)" != "enabled" ]; then
    sudo systemctl enable "$1"
  fi
  if [ "$(systemctl is-active "$1" 2>/dev/null || true)" != "active" ]; then
    sudo systemctl start "$1"
  fi
}

# === Pre-flight ===
echo -e "${COLOR_GREEN}Checking CPU virtualization support...${COLOR_NC}"
grep -E '(vmx|svm)' /proc/cpuinfo >/dev/null || die "CPU virtualization not enabled in BIOS/UEFI."

# === Install core packages (no GUI) ===
echo -e "${COLOR_GREEN}=== Installing KVM core packages (CLI only) ===${COLOR_NC}"

pacman_install \
  qemu-base \
  qemu-desktop \
  libvirt \
  ovmf \
  virt-install \
  dnsmasq \
  openbsd-netcat \
  iptables-nft \
  ebtables \
  vde2

# Guest agent (useful inside VMs, optional on host)
pacman_install qemu-guest-agent

# === Libvirt daemon: use socket activation (Arch recommended) ===
echo -e "${COLOR_GREEN}=== Enabling libvirt socket activation ===${COLOR_NC}"
sudo systemctl enable --now libvirtd.socket
# virtlogd.socket is pulled in automatically by libvirtd.socket

# === User groups ===
echo -e "${COLOR_GREEN}=== Adding $USER to libvirt and kvm groups ===${COLOR_NC}"
for group in libvirt kvm; do
  if ! id -nG "$USER" | grep -qw "$group"; then
    sudo usermod -aG "$group" "$USER"
    warn "Added to $group group. Re-login required."
  else
    echo -e "${COLOR_GREEN}User already in $group group${COLOR_NC}"
  fi
done

# === QEMU user mapping (critical for non-root disk access) ===
echo -e "${COLOR_GREEN}=== Configuring qemu.conf user mapping ===${COLOR_NC}"
QEMU_CONF="/etc/libvirt/qemu.conf"
if [ -f "$QEMU_CONF" ] && ! grep -qE "^user\s*=\s*\"$USER\"" "$QEMU_CONF" 2>/dev/null; then
  sudo sed -i "s/^#\?user\s*=.*/user = \"$USER\"/" "$QEMU_CONF"
  sudo sed -i "s/^#\?group\s*=.*/group = \"$USER\"/" "$QEMU_CONF"
  echo "Set QEMU user/group to $USER in $QEMU_CONF"
  sudo systemctl restart libvirtd.socket 2>/dev/null || true
elif [ -f "$QEMU_CONF" ]; then
  echo "qemu.conf already configured for $USER"
else
  warn "$QEMU_CONF not found, skipping user mapping"
fi

# === Default network (define explicitly if missing) ===
echo -e "${COLOR_GREEN}=== Configuring default libvirt network ===${COLOR_NC}"

if ! sudo virsh net-list --all --name 2>/dev/null | grep -q "^default$"; then
  warn "Default network not defined. Defining from template..."
  if [ -f /etc/libvirt/qemu/networks/default.xml ]; then
    sudo virsh net-define /etc/libvirt/qemu/networks/default.xml
  elif [ -f /usr/share/libvirt/networks/default.xml ]; then
    sudo virsh net-define /usr/share/libvirt/networks/default.xml
  else
    warn "Default network template not found, skipping"
  fi
fi

sudo virsh net-start default 2>/dev/null || true
sudo virsh net-autostart default

# === Polkit rule (optional, passwordless management for wheel) ===
POLKIT_RULE="/etc/polkit-1/rules.d/50-libvirt.rules"
if [ ! -f "$POLKIT_RULE" ]; then
  echo -e "${COLOR_GREEN}Creating polkit rule for libvirt...${COLOR_NC}"
  sudo tee "$POLKIT_RULE" >/dev/null <<'EOF'
polkit.addRule(function(action, subject) {
    if (action.id == "org.libvirt.unix.manage" &&
        subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});
EOF
else
  echo -e "${COLOR_GREEN}Polkit rule already exists${COLOR_NC}"
fi

# === Verify ===
echo -e "${COLOR_GREEN}=== Verification ===${COLOR_NC}"

systemctl is-active libvirtd.socket >/dev/null && echo -e "${COLOR_GREEN}libvirtd.socket: active${COLOR_NC}" || warn "libvirtd.socket not active"
[ -r /dev/kvm ] && [ -w /dev/kvm ] && echo -e "${COLOR_GREEN}/dev/kvm: accessible${COLOR_NC}" || warn "/dev/kvm not accessible (re-login needed)"

echo -e "${COLOR_GREEN}virsh version:${COLOR_NC}"
virsh version 2>/dev/null | head -4 || warn "virsh not ready (re-login and retry)"

echo ""
echo -e "${COLOR_GREEN}=== Done ===${COLOR_NC}"
echo -e "${COLOR_YELLOW}Re-login (or reboot) for group changes, then use:${COLOR_NC}"
echo "  virsh list --all"
echo "  virt-install --name vm1 --memory 2048 --vcpus 2 --disk size=20 --cdrom /path/to.iso --os-variant archlinux"
