# dotfiles

My dotfiles.

## 新机器部署顺序

### 1. 克隆仓库

```shell
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
```

### 2. 安装系统依赖

```shell
bash scripts/install_ui.sh    # 安装 UI 相关包 (foot, swaybg, dunst, waybar 等)
bash scripts/install_river.sh # 安装 river + kwm
```

### 3. 部署配置文件

```shell
stow -t ~ river    # river 合成器配置
stow -t ~ kwm      # kwm 窗口管理器配置
stow -t ~ foot     # foot 终端配置
stow -t ~ dunst    # dunst 通知配置
stow -t ~ fcitx5   # 输入法配置
stow -t ~ waybar   # waybar 状态栏配置 (如使用 sway)
stow -t ~ shell    # .bashrc 等通用 shell 配置
stow -t ~ gnupg    # ~/.gnupg/gpg-agent.conf (TTL / pinentry)
stow -t ~ newsboat # RSS 阅读器配置
stow -t ~ lf       # lf 文件管理器配置
```

### 4. 部署脚本

```shell
# .local/bin/ 下的脚本会通过 stow 自动部署到 ~/.local/bin/
# 包含: foots, damblocks, damblocks-mpdd, audio, bright, exiland 等
stow -t ~/.local .local
```

## 脚本说明

| 脚本 | 用途 |
|------|------|
| `foots` | 启动 foot 终端服务 |
| `damblocks` | 状态栏生成器 |
| `damblocks-mpdd` | mpd 状态更新 |
| `wttr` | 天气查询，缓存到 `~/.cache/wttr` 供状态栏显示 |
| `news` | 打开 newsboat，退出后刷新未读数 |
| `newsboat-update-cron` | 定时抓取 RSS feeds 并刷新未读数 |
| `newsboat-num-cron` | RSS 未读数缓存到 `~/.cache/newsboat.num` |
| `scope` | lf/fzf 通用文件预览器 |
| `lf-rearrange` | lf 打开文件时保持文件列表排序 |
| `audio` | 音量控制 |
| `bright` | 亮度控制 |
| `exiland` | 退出 river/sway |

## Add ranger config to stow manager example

```shell
cd ~/dotfiles
mkdir -p ranger/.config
cp -r ~/.config/ranger ranger/.config
stow -t ~ ranger
```
