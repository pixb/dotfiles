#!/usr/bin/env bash

# === Color ===
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[0;33m'
COLOR_NC='\033[0m'

# === handing failures and errors. ===
set -euo pipefail

# === File Variable ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1

echo -e "${COLOR_GREEN}SCRIPT_DIR = ${SCRIPT_DIR} ${COLOR_NC}"

# === Helper functions ===

pacman_install_noconfirm() {
  sudo pacman -S "$1" --noconfirm --needed
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

# === Full system upgrade first ===
# A partial upgrade causes dependency conflicts, e.g.:
#   installing gstreamer breaks dependency required by gst-plugins-bad-libs
echo -e "${COLOR_GREEN}Syncing and upgrading the system (avoids partial-upgrade conflicts)...${COLOR_NC}"
sudo pacman -Syu --noconfirm

# === Select OpenCL driver provider ===
echo -e "${COLOR_GREEN}Detecting OpenCL driver provider...${COLOR_NC}"

OPENCL_PROVIDER=""
if pacman -Qq nvidia-utils >/dev/null 2>&1 || pacman -Qq nvidia >/dev/null 2>&1; then
  OPENCL_PROVIDER="opencl-nvidia"
elif pacman -Qq rocm-opencl-runtime >/dev/null 2>&1 || pacman -Qq vulkan-radeon >/dev/null 2>&1; then
  OPENCL_PROVIDER="rocm-opencl-runtime"
elif pacman -Qq vulkan-intel >/dev/null 2>&1; then
  OPENCL_PROVIDER="intel-compute-runtime"
else
  OPENCL_PROVIDER="opencl-mesa"
fi

echo -e "${COLOR_GREEN}Using OpenCL provider: ${OPENCL_PROVIDER}${COLOR_NC}"
pacman_install "$OPENCL_PROVIDER"

# === Install repo dependencies ===
echo -e "${COLOR_GREEN}Installing repository dependencies...${COLOR_NC}"
pacman_install \
  glu \
  fuse2 \
  qt5-svg \
  qt5-quickcontrols2 \
  qt5-multimedia \
  xmlsec \
  python-numpy \
  apr-util \
  libc++ \
  libc++abi

# === Install trizen (AUR helper) ===
echo -e "${COLOR_GREEN}Checking trizen...${COLOR_NC}"

if ! check_install trizen; then
  echo -e "${COLOR_YELLOW}Installing trizen from AUR...${COLOR_NC}"
  TMP_DIR="$(mktemp -d)"
  git clone https://aur.archlinux.org/trizen.git "$TMP_DIR/trizen"
  (cd "$TMP_DIR/trizen" && makepkg -si --noconfirm)
  rm -rf "$TMP_DIR"
fi

# === Download DaVinci Resolve source zip ===
# AUR removed auto-download (Blackmagic form policy), but the website API still works:
#   1. GET downloads.json -> find release downloadId for Linux
#   2. POST registration form -> returns signed CloudFront URL
RESOLVE_VER="21.1.1"
RESOLVE_ZIP="DaVinci_Resolve_${RESOLVE_VER}_Linux.zip"
TRIZEN_SRC="$HOME/.cache/trizen/sources/davinci-resolve"
BMD_API="https://www.blackmagicdesign.com/api"

echo -e "${COLOR_GREEN}Checking DaVinci Resolve installer source...${COLOR_NC}"

# trizen clones the AUR repo on first run; make sure it exists
if [ ! -d "$TRIZEN_SRC" ]; then
  echo -e "${COLOR_YELLOW}Preparing trizen source directory...${COLOR_NC}"
  trizen -S --noconfirm --skippgpcheck davinci-resolve 2>/dev/null || true
fi

if [ ! -f "$TRIZEN_SRC/$RESOLVE_ZIP" ]; then
  # Search common download locations first
  FOUND_ZIP=""
  for dir in "$HOME/Downloads" "$HOME/下载" "$HOME"; do
    if [ -f "$dir/$RESOLVE_ZIP" ]; then
      FOUND_ZIP="$dir/$RESOLVE_ZIP"
      break
    fi
  done

  if [ -n "$FOUND_ZIP" ]; then
    echo -e "${COLOR_GREEN}Found $FOUND_ZIP, copying to trizen source dir...${COLOR_NC}"
    cp "$FOUND_ZIP" "$TRIZEN_SRC/$RESOLVE_ZIP"
  else
    echo -e "${COLOR_YELLOW}Downloading $RESOLVE_ZIP from Blackmagic...${COLOR_NC}"

    DOWNLOADS_JSON="$(curl -s --max-time 30 "$BMD_API/support/us/downloads.json" \
      -H 'User-Agent: Mozilla/5.0')"

    DOWNLOAD_ID="$(printf '%s' "$DOWNLOADS_JSON" | python3 -c "
import json, sys
version = '$RESOLVE_VER'
data = json.load(sys.stdin)
for item in data.get('downloads', []):
    name = item.get('name', '')
    # e.g. 'DaVinci Resolve 21.1.1 Update' or 'DaVinci Resolve 21.1.1'
    if name.startswith('DaVinci Resolve ') and version in name and 'Studio' not in name:
        urls = item.get('urls') or {}
        linux = urls.get('Linux') or []
        if linux:
            print(linux[0]['downloadId'])
            sys.exit(0)
sys.exit(1)
")" || {
      echo -e "${COLOR_RED}Failed to resolve downloadId from Blackmagic API.${COLOR_NC}" >&2
      exit 1
    }

    SIGNED_URL="$(curl -s --max-time 30 -X POST \
      "$BMD_API/register/us/download/$DOWNLOAD_ID" \
      -H 'Content-Type: application/json' \
      -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0' \
      -H 'Referer: https://www.blackmagicdesign.com/support/family/davinci-resolve-and-fusion' \
      --data-raw '{"platform":"Linux","policy":true,"downloadOnly":true,"product":"DaVinci Resolve","firstname":"a","lastname":"b","company":"c","email":"a@b.com","phone":"1234567890","country":"US","city":"City","street":"Street 1","zip":"12345","state":"CA","use":"","add":"","serial":""}')"

    if [[ "$SIGNED_URL" != https://* ]]; then
      echo -e "${COLOR_RED}Failed to get signed download URL:${COLOR_NC}" >&2
      echo "$SIGNED_URL" >&2
      exit 1
    fi

    echo -e "${COLOR_GREEN}Downloading (~4 GB, may take a while)...${COLOR_NC}"
    # HTTP/1.1 + resume + retries: long downloads through mihomo HTTP/2 die with stream reset
    if ! curl -L --fail --progress-bar --http1.1 -C - --retry 5 --retry-delay 3 \
      -o "$TRIZEN_SRC/$RESOLVE_ZIP.part" "$SIGNED_URL"; then
      echo -e "${COLOR_RED}Download failed (partial file kept at $TRIZEN_SRC/$RESOLVE_ZIP.part, re-run to resume).${COLOR_NC}" >&2
      exit 1
    fi
    mv "$TRIZEN_SRC/$RESOLVE_ZIP.part" "$TRIZEN_SRC/$RESOLVE_ZIP"
    echo_is_existed "$RESOLVE_ZIP"
  fi
else
  echo_is_existed "$RESOLVE_ZIP"
fi

# === Install davinci-resolve ===
echo -e "${COLOR_GREEN}Installing davinci-resolve (ffmpeg4.4 will also be built from AUR)...${COLOR_NC}"
trizen -S davinci-resolve --noconfirm

echo -e "${COLOR_GREEN}DaVinci Resolve installation completed!${COLOR_NC}"

# Fix for 21.1+: Resolve needs a writable Immersive/ dir under /opt/resolve
if [ -d /opt/resolve ] && [ ! -d /opt/resolve/Immersive ]; then
  echo -e "${COLOR_YELLOW}Creating /opt/resolve/Immersive (21.1+ startup fix)...${COLOR_NC}"
  sudo mkdir -p /opt/resolve/Immersive
  sudo chown "$USER:$USER" /opt/resolve/Immersive
fi

echo -e "${COLOR_YELLOW}Note: The free version from AUR does not include Studio features.${COLOR_NC}"
echo -e "${COLOR_YELLOW}Note: If Resolve fails to launch, ensure your GPU drivers are up to date.${COLOR_NC}"
