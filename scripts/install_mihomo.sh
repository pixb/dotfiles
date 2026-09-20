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
sudo mkdir -p /opt/mihomo

# === Download GeoIP/GeoSite databases ===
log_info "下载 GeoIP/GeoSite 数据库..."
if [ ! -f /opt/mihomo/geoip.dat ]; then
  sudo curl -fSL "https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.dat" -o /opt/mihomo/geoip.dat
  log_info "geoip.dat 已下载"
else
  log_info "geoip.dat 已存在，跳过下载"
fi

if [ ! -f /opt/mihomo/geosite.dat ]; then
  sudo curl -fSL "https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat" -o /opt/mihomo/geosite.dat
  log_info "geosite.dat 已下载"
else
  log_info "geosite.dat 已存在，跳过下载"
fi

# === Setup share group for stow ===
log_info "配置 share 组..."
if ! getent group share >/dev/null 2>&1; then
  sudo groupadd share
  log_info "share 组已创建"
fi

# Add pix and mihomo users to share group
sudo usermod -aG share "$(whoami)" 2>/dev/null || true
sudo usermod -aG share mihomo 2>/dev/null || true

# Set group permissions ONLY on mihomo config directory
# This allows mihomo user (in share group) to read configs via stow symlinks
sudo chown -R pix:share "$DOTFILES_DIR/mihomo"
find "$DOTFILES_DIR/mihomo" -type d -exec sudo chmod 750 {} \;
find "$DOTFILES_DIR/mihomo" -type f -exec sudo chmod 640 {} \;

# === Stow config management ===
log_info "使用 stow 管理配置..."
if [ -d "$DOTFILES_DIR/mihomo/etc/mihomo" ]; then
  # Remove existing config if it's a regular file (not symlink)
  if [ -f "$CONFIG_DIR/config.yaml" ] && [ ! -L "$CONFIG_DIR/config.yaml" ]; then
    log_warn "备份现有配置..."
    sudo mv "$CONFIG_DIR/config.yaml" "$CONFIG_DIR/config.yaml.bak.$(date +%s)"
  fi
  # Use stow to link config
  cd "$DOTFILES_DIR"
  STOW_OUTPUT=$(sudo stow -t / -v mihomo 2>&1)
  log_info "$STOW_OUTPUT"
  log_info "配置已通过 stow 链接"
else
  log_warn "未找到 mihomo/etc/mihomo 目录，跳过 stow 配置"
fi

# === Enable and start mihomo ===
# Create/update systemd service with correct config path
log_info "配置 systemd 服务..."
sudo tee /etc/systemd/system/mihomo.service > /dev/null << 'EOF'
[Unit]
Description=mihomo Daemon
After=network.target NetworkManager.service systemd-networkd.service

[Service]
Type=simple
User=mihomo
Group=mihomo
LimitNPROC=500
LimitNOFILE=1000000
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_RAW CAP_NET_BIND_SERVICE CAP_SYS_TIME CAP_SYS_PTRACE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_RAW CAP_NET_BIND_SERVICE CAP_SYS_TIME CAP_SYS_PTRACE
Environment="SAFE_PATHS=/opt/mihomo"
Restart=always
RestartSec=10
ExecStartPre=/usr/bin/sleep 1
ExecStart=/usr/bin/mihomo -d /etc/mihomo
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
systemctl_enable mihomo
systemctl_start mihomo

# === Install Web UI (MetacubexD) ===
log_info "安装 Web UI (MetacubexD)..."
UI_DIR="/opt/mihomo/ui"
if [ ! -d "$UI_DIR" ]; then
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

# === Enable external-ui and geodata in config ===
if [ -f "$CONFIG_DIR/config.yaml" ]; then
  if ! grep -q "^external-ui:" "$CONFIG_DIR/config.yaml"; then
    log_info "启用 external-ui 配置..."
    sudo sed -i '/^external-controller:/a external-ui: /opt/mihomo/ui' "$CONFIG_DIR/config.yaml"
  fi
  
  # Add geodata paths if not present
  if ! grep -q "geo-ip:" "$CONFIG_DIR/config.yaml"; then
    log_info "添加 geodata 路径配置..."
    sudo sed -i '/^external-ui:/a geox-url:\n  geo-ip: /opt/mihomo/geoip.dat\n  geo-site: /opt/mihomo/geosite.dat' "$CONFIG_DIR/config.yaml"
  fi
  
  # Ensure correct ownership (skip if symlink - stow manages the source file)
  if [ ! -L "$CONFIG_DIR/config.yaml" ]; then
    sudo chown mihomo:mihomo "$CONFIG_DIR/config.yaml"
  fi
  
  # Restart mihomo to apply config
  sudo systemctl restart mihomo
fi

# === Setup TUN transparent proxy ===
log_info "配置 TUN 透明代理..."

# Enable ip_forward
sudo sysctl -w net.ipv4.ip_forward=1
if ! grep -q "^net.ipv4.ip_forward" /etc/sysctl.d/99-mihomo.conf 2>/dev/null; then
  echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-mihomo.conf > /dev/null
fi

# TUN mode is configured in config.yaml with auto-route and auto-redirect
# No additional iptables setup needed - mihomo handles it automatically

# === TUN mode note ===
log_info "TUN 模式已配置，无需设置代理环境变量"

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
echo "GeoIP 数据：/opt/mihomo/geoip.dat"
echo "GeoSite 数据：/opt/mihomo/geosite.dat"
echo ""
echo -e "${COLOR_YELLOW}注意：请在 ~/dotfiles/mihomo/etc/mihomo/ 中修改配置${COLOR_NC}"
