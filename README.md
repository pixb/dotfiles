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
bash scripts/mechrevo_jiguangx_install.sh  # 极光X 机型专用：驱动 + 风扇控制 (非 MECHREVO 自动跳过)
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
| `scripts/mechrevo_jiguangx_install.sh` | 极光X 机型专用：驱动 + 风扇控制安装 |

## MECHREVO 极光X 风扇控制

机型：MECHREVO JiguangX Series GM6AR57C。EC 是 Uniwill/同方方案，风扇占空比只能走
`mechrevo-drivers-dkms` 提供的 `/dev/tuxedo_io`（Uniwill 接口），尺度 **0-200**（`200 = 100%`）。
EC RAM `0x460` (FFAN) 在这台机器上恒为 0，早期脚本读的就是这个寄存器，所以一直显示风扇停转。

### 安装

```shell
bash scripts/mechrevo_jiguangx_install.sh
```

脚本只在 `sys_vendor = MECHREVO` 时执行，会装 `dkms`/`linux-headers`/`mechrevo-drivers-dkms`、
编译风扇工具、装 cron，并停用 `tccd.service`（TCC 的 Auto 会在几秒内覆盖脚本写入的占空比，
风扇控制权只能有一个）。

| 组件 | 说明 |
|------|------|
| `scripts/mechrevo-fan.c` | 读/写风扇占空比，装到 `/usr/local/bin/mechrevo-fan` |
| `scripts/mechrevo-fanctl` | 曲线执行器，装到 `/usr/local/bin/mechrevo-fanctl` |
| `/etc/cron.d/fanmode` | `* * * * * root /usr/local/bin/mechrevo-fanctl` |
| `/run/user/1000/mechrevo-fan` | 占空比缓存，`damblocks` 状态栏读取显示 |
| `damblocks` 的 `update_fanmode()` | 图标：0=󱜝 停 / ≤25%=󱑰 / 26-60%=󱜝 / >60%=󱑯 |

### 曲线

在 `scripts/mechrevo-fanctl` 顶部两行，改完 `sudo cp` 到 `/usr/local/bin/` 即可生效：

```sh
DUTIES="1 50 90 130 170 200"     # 1 = 停转 (写 0 时 EC 会先冲 30% 约 3 分钟)
LIMITS="50 60 70 80 90 1000"    # 对应温度上限 (℃, 读 /sys/class/thermal/thermal_zone0)
```

即 `≤50℃ 停 / 60→25% / 70→45% / 80→65% / 90→85% / >90→100%`。
升温立即拉满对应档，降档要多降 3℃（迟滞，防止来回抖动）。cron 每分钟采样一次。

### 常用命令

```shell
sudo /usr/local/bin/mechrevo-fan        # 读当前占空比，如 "180 180"
sudo /usr/local/bin/mechrevo-fan -v     # 附带风扇温度 / 最低速 / 可停转标志
sudo /usr/local/bin/mechrevo-fan w 120  # 手动设定 (0-200)
sudo /usr/local/bin/mechrevo-fan a      # 交回 EC 自动
```

### 与 Tuxedo Control Center 的关系

`tccd.service` 持有 `/dev/tuxedo_io`，开启时由它按 EC 内置曲线控制风扇；本方案接管后必须停用它：

```shell
sudo systemctl disable --now tccd.service   # 脚本接管 (安装脚本已做)
sudo systemctl enable --now tccd.service    # 交回 TCC
sudo /usr/local/bin/mechrevo-fan a          # 同时把风扇交回 EC 自动
```

## Add ranger config to stow manager example

```shell
cd ~/dotfiles
mkdir -p ranger/.config
cp -r ~/.config/ranger ranger/.config
stow -t ~ ranger
```
