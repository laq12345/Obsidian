# mpv 使用笔记

## 简介

mpv 是开源命令行视频播放器，MPlayer/mplayer2 分支，支持几乎所有音视频格式、字幕、脚本扩展。

## 安装（Fedora Kinoite）

推荐 Flatpak 版（GPU 加速完整）：

```bash
flatpak install flathub io.mpv.Mpv
```

配置 yt-dlp 路径（用于在线播放）：

```bash
mkdir -p ~/.var/app/io.mpv.Mpv/config/mpv
echo 'script-opts=ytdl_hook-ytdl_path=/var/home/smile/.pixi/bin/yt-dlp' >> ~/.var/app/io.mpv.Mpv/config/mpv/mpv.conf
```

Fish alias：

```fish
alias mpv="flatpak run io.mpv.Mpv"
funcsave mpv
```

> **注意**：pixi 的 mpv 缺少 GPU 上下文后端，Wayland + AMD 下无画面输出。Flatpak 版功能完整。

## 常用用法

```bash
# 播放本地文件
mpv 视频.mp4
mpv 音频.mp3

# 在线播放（需 yt-dlp 支持）
mpv https://www.bilibili.com/video/BVxxxxxx

# 先下载再播放（B站 CDN 受限时）
yt-dlp "B站链接" && mpv *.mp4
```

## 常用参数

| 参数 | 说明 |
|------|------|
| `--fs` | 全屏启动 |
| `--no-video` | 纯音频模式 |
| `--start=30s` | 从 30s 开始播放 |
| `--loop=inf` | 循环播放 |
| `--speed=1.5` | 倍速播放 |
| `--volume=50` | 初始音量 |
| `--sub-file=字幕.srt` | 加载外挂字幕 |
| `--vo=gpu-next` | 指定视频输出驱动 |
| `--ytdl-format="bestvideo[height<=?1080]+bestaudio/best"` | 限制在线视频清晰度 |

## 快捷键

| 按键 | 功能 |
|------|------|
| `空格` | 暂停/继续 |
| `←` `→` | 后退/前进 5s |
| `↑` `↓` | 后退/前进 1min |
| `[` `]` | 后退/前进 10% |
| `9` `0` | 音量减/加 |
| `f` | 全屏 |
| `v` | 显示/隐藏字幕 |
| `l` | 循环播放 |
| `Ctrl+←` `Ctrl+→` | 逐帧后退/前进 |
| `q` / `Q` | 退出 / 不保存配置退出 |

## 配置文件 `mpv.conf`

位置：`~/.var/app/io.mpv.Mpv/config/mpv/mpv.conf`

```ini
save-position-on-quit=yes    # 记住播放位置
volume=60                    # 默认音量
fs=yes                       # 全屏启动
hwdec=auto                   # 硬件解码
sub-auto=fuzzy               # 自动加载字幕
script-opts=ytdl_hook-ytdl_path=/var/home/smile/.pixi/bin/yt-dlp  # yt-dlp 路径
```

## 排错

- **只有声音没有画面**：`Failed initializing any suitable GPU context!` → 换 Flatpak 版 mpv
- **B站 412 / CDN 拒绝连接**：yt-dlp 版本过旧 → 更新 `pixi global update yt-dlp`
- **在线播放失败**：可能 B站 CDN 限流 → 改为先下载后播放
