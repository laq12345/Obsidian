---
title: asciinema + agg 完全使用指南
tags: [asciinema, agg, terminal, recording, tutorial, gif]
created: 2026-07-28
---

# asciinema + agg 完全使用指南

> **asciinema** (17.6k ⭐) — 终端会话录制器 + 流媒体 + 播放器
> **agg** (1.7k ⭐) — asciinema GIF 生成器
> GitHub: [asciinema/asciinema](https://github.com/asciinema/asciinema) | [asciinema/agg](https://github.com/asciinema/agg)
> 文档: [docs.asciinema.org](https://docs.asciinema.org/manual/)
> 协议: GPL-3.0

---

## 概述

asciinema 与传统录屏软件不同——它**不录制视频**，而是录制终端的**文本输出**，生成轻量的 `.cast` 文件。别人可以播放、暂停、**选中复制**命令，比视频实用得多。

**agg** 是 asciinema 官方的 GIF 转换工具，将 `.cast` 文件转为高质量 GIF，方便嵌入 README / 网页 / 文档。

---

## 安装

### asciinema（Rust 版本 3.x）

```bash
# 用 cargo 安装（推荐）
cargo install --locked --git https://github.com/asciinema/asciinema

# 或用 pipx（旧版 Python 2.x，功能有限）
pipx install asciinema
```

### agg

```bash
cargo install --git https://github.com/asciinema/agg
```

---

## asciinema CLI 用法

### 核心命令

```bash
asciinema rec demo.cast          # 录制终端会话，Ctrl+D 停止
asciinema play demo.cast         # 终端内回放
asciinema cat demo.cast          # 输出原始终端输出
asciinema rec                    # 录制并上传到 asciinema.org
```

### 录制选项

```bash
# 录制指定命令
asciinema rec --command "Rscript analysis.R" demo.cast

# 录制并限制空闲时间（跳过无操作时段）
asciinema rec --idle-time-limit 2 demo.cast

# 设置终端大小
asciinema rec --cols 120 --rows 40 demo.cast

# 录制 + 同时流式传输到本地 HTTP 服务器
asciinema stream -l --port 8080

# 录制到压缩文件（zstd，约原始大小 8%）
asciinema rec demo.cast.zst
```

### 回放选项

```bash
asciinema play demo.cast                   # 正常速度播放
asciinema play --speed 2 demo.cast         # 2 倍速
asciinema play --loop demo.cast            # 循环播放
asciinema play --idle-time-limit 1 demo.cast  # 跳过超过 1 秒的空闲
asciinema play --step demo.cast            # 步进模式，逐帧操作
```

### 转换

```bash
# 转换版本
asciinema convert demo.cast output_v2.cast --to 2

# 转换为纯文本
asciinema convert demo.cast output.txt

# 合并多个录制
asciinema convert part1.cast part2.cast merged.cast
```

### 流式传输

```bash
# 本地 HTTP 直播（观众通过浏览器观看）
asciinema stream -l

# 通过 asciinema 服务器中继直播
asciinema stream -r
```

### 配置

配置文件位置：`~/.config/asciinema/config.toml`（v3）或 `~/.asciinema/config`（v2）

```toml
[record]
command = "zsh"
idle_time_limit = 2
capture_input = false

[play]
speed = 1.5
idle_time_limit = 1
loop = true

[stream]
port = 8080
```

### 标记（Markers）

在录制过程中添加标记，方便跳转：

```bash
# 录制时按默认快捷键 Ctrl+Space 添加标记
# 或在配置中自定义按键
```

```toml
[keys]
marker = "ctrl+space"
pause = "ctrl+p"
```

### 快捷键（回放时）

| 按键 | 功能 |
|------|------|
| `Space` | 暂停/继续 |
| `.` | 逐帧前进 |
| `Ctrl+←` / `Ctrl+→` | 减速 / 加速 |
| `[` / `]` | 跳到上一个/下一个标记 |
| `Ctrl+C` | 退出 |

---

## agg 用法

### 基本转换

```bash
agg demo.cast demo.gif            # .cast → GIF
```

### 从 URL 转换

```bash
agg https://asciinema.org/a/756853 demo.gif
```

### 速度控制

```bash
agg --speed 2 demo.cast demo.gif           # 2 倍速
agg --speed 0.5 demo.cast demo.gif         # 半速
```

### 空闲时间

```bash
agg --idle-time-limit 1 demo.cast demo.gif   # 跳过超过 1 秒的空闲
```

### 主题

```bash
agg --theme dracula demo.cast demo.gif
agg --theme monokai demo.cast demo.gif
agg --theme github-dark demo.cast demo.gif
agg --theme nord demo.cast demo.gif
```

可用主题：`asciinema`、`dracula`、`monokai`、`github-dark`、`github-light`、`kanagawa`、`nord`、`solarized-dark`、`solarized-light`、`gruvbox-dark`

### 自定义主题

```bash
agg --theme-color bg=1e1e2e --theme-color fg=cdd6f4 demo.cast demo.gif
```

### 字体

```bash
agg --font-size 16 --line-height 1.5 demo.cast demo.gif
agg --font-family "Fira Code, monospace" demo.cast demo.gif
agg --font-dir /path/to/fonts demo.cast demo.gif
```

### 帧选择

```bash
# 选择时间范围（秒）
agg --from 5 --to 30 demo.cast demo.gif

# 选择百分比范围
agg --from 10% --to 80% demo.cast demo.gif

# 跳过前 3 秒
agg --from 3s demo.cast demo.gif
```

### 终端大小

```bash
agg --cols 100 --rows 30 demo.cast demo.gif   # 覆盖终端大小
```

### 循环与 FPS

```bash
agg --loop demo.cast demo.gif                  # 循环播放
agg --fps-cap 15 demo.cast demo.gif            # 限制 FPS
agg --last-frame-duration 3 demo.cast demo.gif # 最后一帧停留 3 秒
```

### 渲染后端

```bash
agg --renderer resvg demo.cast demo.gif        # resvg 后端
agg --renderer swash demo.cast demo.gif        # swash 后端（默认）
```

---

## 如何嵌入 README

### 方式一：GIF（最简单，最通用）

```bash
asciinema rec demo.cast
agg demo.cast demo.gif
```

```markdown
![终端演示](demo.gif)
```

GitHub / GitLab / 任何 Markdown 渲染器都支持。

### 方式二：SVG（可交互，GitHub 支持）

```bash
npm install -g svg-term-cli
cat demo.cast | svg-term --out demo.svg --height 500
```

```markdown
![终端演示](demo.svg)
```

### 方式三：asciinema.org 链接 + 徽章

先上传：`asciinema rec`，然后得到 URL `https://asciinema.org/a/123`。

```markdown
[![asciicast](https://asciinema.org/a/123.svg)](https://asciinema.org/a/123)
```

### 方式四：自托管 Web Player

```html
<script src="https://embed.asciinema.org/player.js" data-id="123" data-speed="2" data-theme="dracula" data-loop></script>
```

或用本地文件：

```html
<script src="https://embed.asciinema.org/player.js" data-url="demo.cast" data-speed="1" data-theme="nord"></script>
```

### Player 选项

| 选项 | 类型 | 说明 |
|------|------|------|
| `data-speed` | number | 播放速度 (默认 1) |
| `data-theme` | string | 主题: `asciinema` / `dracula` / `monokai` / `nord` / `solarized-dark` / `solarized-light` |
| `data-loop` | boolean | 循环播放 |
| `data-poster` | string | 封面帧: `npt:5`（第 5 秒）或 `npt:50%`（50%） |
| `data-rows` | number | 覆盖行数 |
| `data-cols` | number | 覆盖列数 |
| `data-autoplay` | boolean | 自动播放 |
| `data-preload` | boolean | 预加载 |
| `data-idle-time-limit` | number | 跳过空闲秒数 |
| `data-font-size` | string | CSS 字体大小 |

---

## 最佳实践

### 录制教程

```bash
# 设置好终端大小，让录制内容清晰
asciinema rec --cols 80 --rows 24 --idle-time-limit 2 tutorial.cast

# 转成 GIF 嵌入 README
agg --theme nord --speed 1.5 --loop --idle-time-limit 1 tutorial.cast tutorial.gif
```

### CI/CD 中自动录制

```bash
# 非交互式录制（headless 模式）
asciinema rec --command "npm test" --overwrite test.cast
agg --theme github-dark test.cast test.gif
```

### 录制小技巧

- **录制前清屏** — `clear` 让录制从干净终端开始
- **放慢操作** — 让观看者能跟上
- **使用标记** — 用 Ctrl+Space 标记关键步骤
- **控制空闲时间** — `--idle-time-limit 2` 自动跳过思考时间
- **选择合适的主题** — Nord 或 Dracula 适合暗色 README

### 文件对比

| 格式 | 大小 | 是否可复制文字 | 可嵌入 | 交互式 |
|------|------|---------------|--------|--------|
| `.cast` (原始) | ~10KB | ✅ | 需播放器 | ✅ |
| `.cast.zst` (压缩) | ~1KB | ✅ | 需播放器 | ✅ |
| `.gif` | ~500KB-2MB | ❌ | ✅ 通用 | ❌ |
| `.svg` | ~100KB | ✅ | ✅ | ✅ |
| asciinema.org 链接 | — | ✅ | 嵌入 | ✅ |

---

## 常见问题

**Q: Windows 支持吗？**
A: asciinema 官方不支持 Windows，可用 [PowerSession](https://github.com/Watfaq/PowerSession-rs) 替代。

**Q: 录制文件太大了？**
A: 使用 zstd 压缩：`asciinema rec demo.cast.zst`，压缩后约原始大小的 8%。

**Q: GIF 背景色不对？**
A: 用 `--theme` 参数：`agg --theme nord demo.cast demo.gif`

**Q: 可以同时录制和直播吗？**
A: 可以，asciinema 3.x 支持同时录制到文件 + 本地 HTTP 流式传输。
