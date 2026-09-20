#!/usr/bin/env bash
set -euo pipefail

# === Color ===
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[0;33m'
COLOR_BLUE='\033[0;34m'
COLOR_NC='\033[0m'

# === File Variable ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# === AUR Helper ===
AUR_HELPER="$(command -v paru || command -v yay || command -v trizen || echo trizen)"

function log_info() {
  echo -e "${COLOR_GREEN}[INFO]${COLOR_NC} $1"
}

function log_warn() {
  echo -e "${COLOR_YELLOW}[WARN]${COLOR_NC} $1"
}

function log_error() {
  echo -e "${COLOR_RED}[ERROR]${COLOR_NC} $1"
}

# === Package functions (from arch_install_user.sh) ===
pacman_install_noconfirm() {
  sudo pacman -S "$1" --noconfirm --needed
}

aur_install_noconfirm() {
  "$AUR_HELPER" -S "$1" --noconfirm --needed
}

echo_not_found() {
  echo -e "${COLOR_YELLOW}$1 is not installed, installing...${COLOR_NC}"
}

echo_is_existed() {
  echo -e "${COLOR_GREEN}$1 is already installed.${COLOR_NC}"
}

echo_install_failed() {
  echo -e "${COLOR_RED}Failed to install $1.${COLOR_NC}" >&2
}

check_install() {
  if pacman -Qi "$1" >/dev/null 2>&1; then
    echo_is_existed "$1"
    return 0
  else
    echo_not_found "$1"
    return 1
  fi
}

pacman_install() {
  for package in "$@"; do
    if ! check_install "$package"; then
      if ! pacman_install_noconfirm "$package"; then
        echo_install_failed "$package"
        return 1
      fi
    fi
  done
}

aur_install() {
  for package in "$@"; do
    if ! check_install "$package"; then
      if ! aur_install_noconfirm "$package"; then
        echo_install_failed "$package"
        return 1
      fi
    fi
  done
}

systemctl_enable() {
  if [ "$(systemctl is-enabled "$1" 2>/dev/null || true)" != "enabled" ]; then
    log_info "enabling $1"
    sudo systemctl enable "$1"
  else
    log_info "$1 already enabled"
  fi
}

systemctl_start() {
  if [ "$(systemctl is-active "$1" 2>/dev/null || true)" != "active" ]; then
    log_info "starting $1"
    sudo systemctl start "$1"
  else
    log_info "$1 already running"
  fi
}

# === Install mihomo from AUR ===
aur_install mihomo

# === Install dependencies ===
pacman_install iptables-nft

# === Setup config directory ===
CONFIG_DIR="/etc/mihomo"
sudo mkdir -p "$CONFIG_DIR"
sudo mkdir -p /var/log/mihomo

# === Stow config management ===
log_info "使用 stow 管理配置..."
if [ -d "$DOTFILES_DIR/mihomo/etc/mihomo" ]; then
  # Backup existing config if not a symlink
  if [ -f "$CONFIG_DIR/config.yaml" ] && [ ! -L "$CONFIG_DIR/config.yaml" ]; then
    log_warn "备份现有配置..."
    sudo mv "$CONFIG_DIR/config.yaml" "$CONFIG_DIR/config.yaml.bak.$(date +%s)"
  fi
  # Use stow to link config
  cd "$DOTFILES_DIR"
  sudo stow -t / -v mihomo 2>&1 | log_info
  log_info "配置已通过 stow 链接"
else
  log_warn "未找到 mihomo/etc/mihomo 目录，跳过 stow 配置"
fi

# === Enable and start mihomo ===
systemctl_enable mihomo
systemctl_start mihomo

# === Install Web UI (MetacubexD) ===
log_info "安装 Web UI (MetacubexD)..."
UI_DIR="/opt/mihomo/ui"
if [ ! -d "$UI_DIR" ]; then
  sudo mkdir -p /opt/mihomo
  cd /tmp
  if command -v curl &>/dev/null; then
    sudo curl -fSL "https://github.com/MetaCubeX/metacubexd/archive/refs/heads/gh-pages.zip" -o metacubexd.zip
  elif command -v wget &>/dev/null; then
    sudo wget -q "https://github.com/MetaCubeX/metacubexd/archive/refs/heads/gh-pages.zip" -O metacubexd.zip
  fi
  sudo unzip -q metacubexd.zip
  sudo mv metacubexd-gh-pages "$UI_DIR"
  sudo rm -rf metacubexd.zip metacubexd-gh-pages
  log_info "MetacubexD UI 已安装到 ${UI_DIR}"
else
  log_info "MetacubexD UI 已存在，跳过安装"
fi

# === Enable external-ui in config ===
if [ -f "$CONFIG_DIR/config.yaml" ]; then
  if ! grep -q "^external-ui:" "$CONFIG_DIR/config.yaml"; then
    log_info "启用 external-ui 配置..."
    sudo sed -i '/^external-controller:/a external-ui: /opt/mihomo/ui' "$CONFIG_DIR/config.yaml"
  fi
  # Restart mihomo to apply UI config
  sudo systemctl restart mihomo
fi

# === Setup TUN transparent proxy ===
log_info "配置 TUN 模式网络..."

# Enable ip_forward
sudo sysctl -w net.ipv4.ip_forward=1
if ! grep -q "^net.ipv4.ip_forward" /etc/sysctl.d/99-mihomo.conf 2>/dev/null; then
  echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-mihomo.conf > /dev/null
fi

# Setup iptables service for transparent proxy
sudo tee /etc/systemd/system/mihomo-tun.service > /dev/null << 'EOF'
[Unit]
Description=mihomo TUN Setup
After=network.target
Before=mihomo.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c '\
  sysctl -w net.ipv4.ip_forward=1 && \
  iptables -t nat -A PREROUTING -p tcp -j REDIRECT --to-ports 7892 && \
  iptables -t nat -A PREROUTING -p udp -j REDIRECT --to-ports 7892 && \
  iptables -t nat -A OUTPUT -p tcp -d 127.0.0.0/8 -j RETURN && \
  iptables -t nat -A OUTPUT -p tcp -j REDIRECT --to-ports 7892'
ExecStop=/bin/sh -c '\
  iptables -t nat -D PREROUTING -p tcp -j REDIRECT --to-ports 7892 && \
  iptables -t nat -D PREROUTING -p udp -j REDIRECT --to-ports 7892 && \
  iptables -t nat -D OUTPUT -p tcp -d 127.0.0.0/8 -j RETURN && \
  iptables -t nat -D OUTPUT -p tcp -j REDIRECT --to-ports 7892'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
systemctl_enable mihomo-tun
systemctl_start mihomo-tun

# === Setup proxy environment variables ===
SHELL_RC="$HOME/.zshrc"
[ ! -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.bashrc"

if ! grep -q "mihomo proxy" "$SHELL_RC" 2>/dev/null; then
  cat >> "$SHELL_RC" << 'EOF'

# mihomo proxy
export http_proxy=http://127.0.0.1:7890
export https_proxy=http://127.0.0.1:7890
export all_proxy=socks5://127.0.0.1:7890
export no_proxy=localhost,127.0.0.1,::1
EOF
  log_info "代理环境变量已添加到 ${SHELL_RC}"
else
  log_info "代理环境变量已存在，跳过"
fi

# === Print usage ===
echo ""
echo -e "${COLOR_BLUE}mihomo 安装完成！${COLOR_NC}"
echo ""
echo "命令："
echo "  systemctl start mihomo      # 启动"
echo "  systemctl stop mihomo       # 停止"
echo "  systemctl status mihomo     # 查看状态"
echo "  systemctl restart mihomo    # 重启"
echo ""
echo "日志："
echo "  journalctl -u mihomo -f     # 实时日志"
echo ""
echo "配置管理 (stow)："
echo "  cd ~/dotfiles"
echo "  sudo stow -t / mihomo       # 链接配置"
echo "  sudo stow -t / -D mihomo    # 取消链接"
echo ""
echo "Web UI："
echo "  http://127.0.0.1:9090/ui    # MetacubexD 管理界面"
echo ""
echo "配置文件：${CONFIG_DIR}/config.yaml"
echo ""
echo -e "${COLOR_YELLOW}注意：配置通过 stow 管理，请在 ~/dotfiles/mihomo/etc/mihomo/ 中修改${COLOR_NC}"
