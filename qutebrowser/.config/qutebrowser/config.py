# vim:ft=python
# qutebrowser/config.py
# @author nate zhou
# @since 2025,2026

c.zoom.default = 120

# ---------------------------------------------------------------------------
# Chromium 渲染路径：软件光栅化（不要动这块，除非你有把握）
#
# 本机是 机械革命 极光X (i7-12800HX + RTX 4070 Laptop)，混合显卡：
#   - 内屏 eDP-1 -> Intel i915 (card1)
#   - 外接 HDMI-A-1 -> NVIDIA (card0)，当前是唯一启用的输出
#   - EGL 默认 vendor 是 NVIDIA (/usr/share/glvnd/egl_vendor.d/10_nvidia.json)
#   - Vulkan 只有 NVIDIA 一个 ICD，没有 intel-vulkan-driver
#
# 为什么必须软件光栅化（2026-10-22 实测结论）：
#
# 1) Qt 6.12 的 wayland 平台插件不提供 DRM 集成 => QtWebEngine 判定
#    "GBM is not supported with the current configuration"，
#    然后强制给 Chromium 加 --enable-features=Vulkan，
#    即：qutebrowser 在本机只能走 Vulkan 或软件，没有 GL 这条路。
#    (换成 QT_QPA_PLATFORM=xcb 也没用，GBM 判定依旧失败)
#
# 2) nvidia-open 615.78.08 在这台机器上读不到 SBIOS 的平台温度/功耗模式
#    (NVRM: "failed to get target temp from SBIOS" / "failed to get platform
#    power mode from SBIOS")，走 Vulkan 初始化 NVIDIA 时会挂死整机。
#    实测: 2026-10-22 21:55 打开带 GPU 的 qutebrowser => GPU 进程 SIGSEGV
#    (栈里有 libnvidia-glcore.so.615.78.08) => 整机卡死，只能强制重启。
#
# 3) 只禁 Vulkan 而不禁 GPU (即"保留硬件加速") => Chromium 没有可用后端，
#    GPU 进程直接 SIGSEGV (libgallium + libnvidia-glcore 混合栈)。
#
# 所以：--disable-gpu + 禁用 Vulkan 是本机唯一实测稳定的组合。
# 想让 qutebrowser 有硬件加速，只能换用 Chromium/Firefox 原生版
# (它们不走 Qt 的 GBM/Vulkan 强制逻辑)。
#
# 注意: 这里不要写前导 "--"。qutebrowser 会给每个 c.qt.args 条目自动加 "--"，
# 写成 "--disable-features=..." 会变成 "----disable-features=..."(无效)。
# 而 'disable-features=...' 这种写法会被 qutebrowser 识别为 special flag，
# 与它自己的 --disable-features 合并成一条，不会互相覆盖。
# ---------------------------------------------------------------------------
c.qt.force_software_rendering = 'chromium'
c.qt.args = [
    'disable-gpu-compositing',
    'disable-features=Vulkan,WebGPU',
]

config.source('proxy.py')
config.source('colors.py')
config.source('bindings.py')
config.source('search.py')

c.content.user_stylesheets = ["~/.config/qutebrowser/styles/black.css"]

config.load_autoconfig(False) # ignore GUI settings

import os
import shlex

if os.environ.get('XDG_SESSION_TYPE') == 'wayland':
    term = 'footclient -T Floating_Term -o colors.alpha=0.9'
else:
    term = 'st -T Floating_Term'

c.editor.command = shlex.split(term) + \
        ['nvim', '{file}', '-c', 'normal {line}G{column0}l']

fileChooser = shlex.split(term) + ['lf', '-selection-path={}']
c.fileselect.handler = "external"
c.fileselect.folder.command = fileChooser
c.fileselect.multiple_files.command = fileChooser
c.fileselect.single_file.command = fileChooser

c.url.start_pages = 'file:///dev/null'
c.url.default_page= 'file:///dev/null'
c.tabs.last_close = "startpage"
c.auto_save.session = True

c.zoom.levels = ["25%", "33%", "50%", "67%", "75%", "90%", "100%", "110%", "120%", "130%", "140%", "150%", "175%", "200%", "250%", "300%"]

c.fonts.default_family = 'Noto Sans' # UI
c.fonts.default_size = '14pt'
c.fonts.web.size.default = 18 # webpage
c.fonts.web.size.default_fixed = 18
c.fonts.web.size.minimum = 18
c.fonts.hints = 'normal 12pt SourceCodePro'
c.fonts.tabs.selected = '12pt default_family'
c.fonts.tabs.unselected = '12pt default_family'
c.fonts.statusbar = '14.5pt default_family'

c.tabs.show = "always"
c.tabs.position = "left"
c.tabs.padding = {"bottom":0, "left":0, "right":0, "top":0}
c.tabs.indicator.width = 0
c.tabs.width = '10%'
c.tabs.title.format = '{audio}{current_title}'
c.tabs.title.format_pinned = '[P]{audio}{current_title}'
c.statusbar.show = "always"
c.completion.height = '30%'

c.keyhint.delay = 0
c.hints.uppercase = False
c.hints.chars = "asdfjkl;"
c.hints.min_chars = 2
c.hints.auto_follow = "full-match"

c.downloads.location.directory = "/home/pix/Downloads"
c.downloads.location.prompt = False
c.downloads.location.suggestion = 'both'
c.downloads.location.remember = False
c.downloads.remove_finished = 3300
c.downloads.position = "bottom"

c.content.fullscreen.window = True # Limit fullscreen to browser window
c.content.autoplay = False
c.content.blocking.enabled = True
c.content.blocking.method = 'both'
c.content.blocking.adblock.lists = [
  "https://easylist.to/easylist/easylist.txt",
  "https://secure.fanboy.co.nz/fanboy-cookiemonster.txt",
  "https://easylist.to/easylist/easyprivacy.txt",
  "https://secure.fanboy.co.nz/fanboy-annoyance.txt",]

# privacy
c.content.canvas_reading = False # breaks some sites, see `zcr` in `bindings.py`
c.content.geolocation = False
c.content.webrtc_ip_handling_policy = "default-public-interface-only"
c.completion.open_categories = ['filesystem']
