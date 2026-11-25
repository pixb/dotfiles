# Samba 网络共享挂载

本仓库用 **systemd mount + automount unit** 管理局域网 SMB 共享，挂载到 `~/mnt/<IP>/<共享名>`。
凭据用 root-only 文件（明文，权限 600），不进 git；仓库里只放 credentials 模板。

## 设计决策

| 项目 | 选择 | 原因 |
|---|---|---|
| 协议 | SMB (cifs) | Mac/Linux 通用 |
| 挂载方式 | systemd automount | 按需挂载，网络不通不影响开机，空闲自动断开 |
| 挂载点 | `~/mnt/<IP>/<共享名>` | 路径即 IP，一目了然 |
| 凭据 | `/etc/samba/credentials/<IP>` (600 root:root) | 密码不进 git、不进 unit 文件 |
| SMB 版本 | `vers=3.0` | 本机 Mac 服务端不支持 3.1.1（见下方排错） |
| 依赖 | **不声明** `network-online.target` | 在 `~/mnt` 下声明会与 local-fs.target 形成依赖环 |

## 文件结构

```
etc/
├── samba/
│   └── credentials.example        # 凭据模板（可进 git）
└── systemd/system/
    ├── home-pix-mnt-192.168.1.200-work.mount       # 实际挂载
    └── home-pix-mnt-192.168.1.200-work.automount   # 按需触发
```

unit 文件名由挂载点路径决定，用 `systemd-escape -p --suffix=mount <绝对路径>` 生成。
注意：IP 里的 `.` 在 unit 名里**不转义**。

## 部署步骤（新机器 / 新增共享）

### 1. 安装依赖

```shell
sudo pacman -S cifs-utils samba
```

### 2. 创建凭据（每台主机一份）

```shell
sudo install -d -m 700 /etc/samba/credentials
sudo install -m 600 /dev/null /etc/samba/credentials/<IP>
sudo tee /etc/samba/credentials/<IP> >/dev/null <<'EOF'
username=<用户名>
password=<密码>
EOF
# 格式参考 etc/samba/credentials.example
```

### 3. 创建挂载点

```shell
sudo install -d -m 755 -o "$USER" -g "$USER" "$HOME/mnt/<IP>/<共享名>"
```

### 4. 生成 unit 文件

复制现有 unit，改 4 处：
- 文件名（`systemd-escape -p --suffix=mount /home/pix/mnt/<IP>/<共享名>`）
- `Description`
- `What=` → `//<IP>/<共享名>`
- `Where=` → 绝对路径挂载点
- `.mount` 的 `Options=` 里 `credentials=` 指向对应 IP 的凭据文件

放到 `etc/systemd/system/`。

### 5. 部署并启用

```shell
sudo install -m 644 etc/systemd/system/<name>.{mount,automount} /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now <name>.automount
```

只需 enable **automount**（mount 由它按需触发）。

### 6. 验证

```shell
systemd-analyze verify etc/systemd/system/<name>.mount       # 应无 error/cycle
ls "$HOME/mnt/<IP>/<共享名>"                                  # 首次访问触发挂载
findmnt "$HOME/mnt/<IP>/<共享名>"                             # 应显示 cifs
systemctl status <name>.mount
```

## 当前已配置的共享

| 主机 | 共享 | 挂载点 | 凭据 |
|---|---|---|---|
| 192.168.1.200 | work | `~/mnt/192.168.1.200/work` | `/etc/samba/credentials/192.168.1.200` |

## 挂载选项说明

```
credentials=...           从 root-only 文件读账号密码
vers=3.0                  SMB 协议版本（本机 Mac 最高支持 3.0，不支持 3.1.1）
uid=1000,gid=1000         文件属主为当前用户
file_mode=0644,dir_mode=0755  文件/目录权限
nofail                    挂载失败不阻塞启动
rsize/wsize=1048576       大读写缓冲（SMB3 性能）
cache=loose               客户端缓存策略（个人环境够用）
TimeoutIdleSec=600        (automount) 空闲 10 分钟自动卸载
```

## 排错记录

### `mount error(95): Operation not supported` + `Dialect not supported by server`

原因：服务端不支持客户端请求的 SMB 方言。本机 Mac 不支持 `vers=3.1.1`。

排查：
```shell
sudo dmesg | grep -i cifs        # 看内核具体错误
smbclient -L //<IP> -U '<用户>%<密码>'   # 先确认认证和共享列表
```

解决：降低 `vers=`（3.0 / 2.1 / 2.0）逐个试。当前确认 `3.0` 可用。

### `Send error in QFSUnixInfo = -95` + `mount error(2)`

原因：Linux 内核 cifs 查询 UNIX 文件信息时 Mac 服务端返回不支持，导致挂载失败。
曾出现在 Mac 端设置调整之前；调整后 `vers=3.0` 正常。若复现，可尝试：
- 在 Mac 上确认共享权限和 SMB 设置（系统设置 → 通用 → 共享 → 文件共享）
- 降低 `vers=` 到 2.1 / 2.0
- 用户态替代方案：`gio mount smb://...`（gvfs）、`smbnetfs`

### `systemd-analyze verify` 报 ordering cycle

```
local-fs.target → <name>.automount → network-online.target → ... → sysinit.target → local-fs.target
```

原因：挂载点在 `~/mnt`（local-fs），却声明了 `After/Wants=network-online.target`，网络服务又依赖 sysinit → local-fs，形成环。

解决：**mount/automount unit 都不声明 `network-online.target`**。automount 按需触发，访问时网络必然已就绪。

## 扩展：多台主机 / 多个共享

systemd 规则是**一个挂载点一对 unit**，不能一个 unit 挂多个目标。每台主机、每个共享都要：
1. 一份 credentials（按 IP 命名）
2. 一对 `.mount` + `.automount` unit（文件名按挂载点生成）

共享多了以后可写生成脚本（放 `scripts/`），输入 `IP 共享名` 自动生成 unit 和凭据模板，避免手写出错。公共选项（vers/uid/gid/cache 等）保持一致，只变 `What`/`Where`/`credentials=`。

## 安全提醒

- 凭据文件权限必须是 600 root:root，目录 700
- 密码不写进 unit（unit 在 git 里、world-readable）
- 本文示例里的密码为测试用，公开网络环境请更换
- 若凭据需跨机同步，可改用 GPG 加密存密文、登录时解密到 `$XDG_RUNTIME_DIR`（tmpfs），unit 引用内存中的明文文件
