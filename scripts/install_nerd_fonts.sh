#!/bin/env bash
set -e

COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[0;33m'
COLOR_NC='\033[0m'

DOWNLOADS_PATH="${HOME}/Downloads"

install_font() {
  local name="$1"
  local check_file="$2"
  local zip_url="$3"
  local zip_name="$(basename "$zip_url")"

  if [ -f "$check_file" ]; then
    echo -e "${COLOR_GREEN}${name} is installed${COLOR_NC}"
    return
  fi

  echo -e "${COLOR_YELLOW}${name} is not installed${COLOR_NC}"

  if [ ! -f "${DOWNLOADS_PATH}/${zip_name}" ]; then
    echo -e "${COLOR_YELLOW}Downloading ${zip_name}...${COLOR_NC}"
    if ! wget -q -O "${DOWNLOADS_PATH}/${zip_name}" "$zip_url"; then
      echo -e "${COLOR_RED}Failed to download ${zip_name}${COLOR_NC}"
      return 1
    fi
  fi

  local extract_dir="${DOWNLOADS_PATH}/${name}"
  mkdir -p "$extract_dir"
  unzip -q -o "${DOWNLOADS_PATH}/${zip_name}" -d "$extract_dir"

  local moved=0
  for f in "$extract_dir"/*.otf; do
    [ -f "$f" ] && sudo mv "$f" /usr/share/fonts/OTF/ && moved=1
  done
  for f in "$extract_dir"/*.ttf; do
    [ -f "$f" ] && sudo mv "$f" /usr/share/fonts/TTF/ && moved=1
  done

  if [ "$moved" -eq 1 ]; then
    echo -e "${COLOR_GREEN}${name} installed successfully${COLOR_NC}"
  else
    echo -e "${COLOR_RED}${name} - no font files found in archive${COLOR_NC}"
  fi

  rm -rf "$extract_dir"
}

install_font "Monaspace" \
  "/usr/share/fonts/OTF/MonaspiceArNerdFont-Bold.otf" \
  "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Monaspace.zip"

install_font "NotoSansM" \
  "/usr/share/fonts/TTF/NotoSansMNerdFontMono-Regular.ttf" \
  "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Noto.zip"

fc-cache -fv
