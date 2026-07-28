# yt-dlp 使用笔记

## 简介

yt-dlp 是 youtube-dl 的活跃分支，命令行视频/音频下载器，支持 B站、YouTube 等上千个网站。

## 安装

```bash
pixi global install yt-dlp     # 推荐（conda-forge，更新快）
```

更新：

```bash
pixi global update yt-dlp      # 走 conda-forge，不走 GitHub API（避免限流）
```

> **避免用 `yt-dlp -U` 更新**：走 GitHub Releases API，容易 403 rate limit。

## 常用用法

```bash
# 查看可用格式
yt-dlp -F "URL"

# 下载最佳画质
yt-dlp "URL"

# 指定格式下载
yt-dlp -f "bestvideo[height<=1080]+bestaudio/best" "URL"

# 只下载音频
yt-dlp -x --audio-format mp3 "URL"

# 提取直链（不下载）
yt-dlp -g "URL"

# 导出浏览器 cookie 绕过登录限制
yt-dlp --cookies-from-browser firefox "URL"

# 下载字幕
yt-dlp --write-subs --sub-langs all "URL"

# 下载播放列表
yt-dlp --playlist-start 1 --playlist-end 5 "playlist_URL"

# 指定输出文件名
yt-dlp -o "%(title)s.%(ext)s" "URL"
```

## 参数速查

| 参数 | 说明 |
|------|------|
| `-F` | 列出所有可用格式 |
| `-f` | 指定格式 ID 下载 |
| `-o` | 输出文件名模板 |
| `-x` | 仅提取音频 |
| `--audio-format mp3` | 音频转码格式 |
| `-g` | 获取视频直链（不下载） |
| `--cookies-from-browser` | 从浏览器导出 cookie |
| `--write-subs` | 下载字幕 |
| `--sub-langs` | 指定字幕语言 |
| `--playlist-start` / `--playlist-end` | 播放列表范围 |
| `--limit-rate` | 限速下载 |
| `--no-check-certificates` | 跳过证书检查 |
| `--proxy` | 通过代理下载 |

## 与 mpv 配合

mpv 内部调用 yt-dlp 实现在线播放（非下载后播放）：

```
mpv "B站链接"  →  yt-dlp 解析出视频流  →  mpv 在线播放
```

B站 CDN 限流时，先下载再播放：

```bash
yt-dlp "URL" && mpv *.mp4
```

## 排错

| 问题 | 原因 | 解决 |
|------|------|------|
| `HTTP Error 412: Precondition Failed` | B站 CDN 反爬，或 yt-dlp 版本过旧 | 更新 yt-dlp，或加 `--cookies-from-browser` |
| `HTTP Error 403: rate limit exceeded` | `yt-dlp -U` 被 GitHub 限流 | 改用 `pixi global update yt-dlp` |
| 下载速度慢 | CDN 限速 | 用 `--limit-rate 5M` 或换代理 |
