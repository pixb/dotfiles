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
编译风扇工具、装 systemd timer，并停用 `tccd.service`（TCC 的 Auto 会在几秒内覆盖脚本写入的占空比，
风扇控制权只能有一个）。

| 组件 | 说明 |
|------|------|
| `scripts/mechrevo-fan.c` | 读/写风扇占空比，装到 `/usr/local/bin/mechrevo-fan` |
| `scripts/mechrevo-fanctl` | 曲线执行器（多源温度取最大值），装到 `/usr/local/bin/mechrevo-fanctl` |
| `etc/systemd/system/mechrevo-fanctl.service` | 一拍执行一次 |
| `etc/systemd/system/mechrevo-fanctl.timer` | 每 10 秒一拍（取代旧 `/etc/cron.d/fanmode` 每分钟） |
| `/run/user/1000/mechrevo-fan` | 占空比缓存，`damblocks` 状态栏读取显示 |
| `damblocks` 的 `update_fanmode()` | 图标：0=󱜝 停 / ≤25%=󱑰 / 26-60%=󱜝 / >60%=󱑯 |

### 曲线

决策温度 **T = 所有热源的最大值**，不再是单一传感器：

```text
CPU 封装(coretemp) · GPU(nvidia-smi) · 内存条 x2(spd5118) · NVMe x2 · WiFi(iwlwifi) ·
EC 机箱热区(acpitz/ECTZ) · EC 风扇温度(fan_temp)
```

> 为什么改：旧版只读 `thermal_zone0`，而这台机器上 `thermal_zone0` 是 **acpitz / ECTZ（EC 机箱热区）**，
> 是反应最慢的传感器；CPU 封装在 coretemp，GPU/显存/内存/SSD 完全没参与。实测 ComfyUI 出图时
> ECTZ 几乎不动 → 风扇停在 `duty 1`（`fan1=0/200 fan2=0/200`，完全停转），同时内存条 SPD5118
> 已越过 55℃ 报警线。这就是“积热”的直接来源。

改完 `sudo cp` 到 `/usr/local/bin/` 即可生效：

```sh
DUTIES="60 80 110 140 170 190 200"    # 1 = 停转 (写 0 时 EC 会先冲 30% 约 3 分钟)
LIMITS="40 48 55 62 70 78 1000"      # 对应 T 上限 (℃)
```

即 `≤40→30% / 48→40% / 55→55% / 62→70% / 70→85% / 78→95% / >78→100%`。

叠加的强制下限（比基础曲线优先）：

| 触发条件 | 占空比下限 |
|---|---|
| 内存条 ≥52℃ / ≥56℃ / ≥60℃ | 110 / 150 / 200 |
| GPU ≥75℃ / ≥82℃ / ≥88℃ | 150 / 190 / 200 |
| NVMe ≥65℃ / ≥72℃ | 150 / 200 |
| 接电源 / 电池 | 60 (30%) / 50 (25%) —— 永不停转 |

升档立即；降档需比目标档下限再低 4℃ 且连续 12 拍（约 2 分钟），一档一档回落，防止来回抖动。

### 观测

```shell
journalctl -t mechrevo-fanctl -n 20 --no-pager   # 每拍的温度快照 + 当前占空比
systemctl status mechrevo-fanctl.timer
sudo /usr/local/bin/mechrevo-fan -v              # EC 侧真实风扇状态
```

每拍都写 journal，所以万一再硬死机，`journalctl -t mechrevo-fanctl -n 20` 就是冻结前最后的温度快照。

旧版曲线（历史背景，已废弃）：`DUTIES="1 50 90 130 170 200"` / `LIMITS="50 60 70 80 90 1000"`，
即 `≤50℃ 停转 / 60→25% / 70→45% / 80→65% / 90→85%`，cron 每分钟一拍。

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
