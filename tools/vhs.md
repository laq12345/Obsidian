---
tags:
  - cli
  - tool
  - recording
  - gif
  - charmbracelet
created: 2026-07-13
---

# VHS — 终端录制 GIF/MP4

> GitHub：<https://github.com/charmbracelet/vhs>
> 安装：`sudo dnf install vhs ffmpeg`（Charm 仓库），依赖 `ttyd` + `ffmpeg`

用脚本录制终端操作，产出 GIF/MP4/WebM，适合 README 演示和 CLI 展示。

---

## 工作流

```bash
vhs new demo.tape    # 创建脚本
vim demo.tape        # 编辑
vhs demo.tape        # 渲染
```

## Tape 脚本语法

### 输出

```
Output demo.gif
Output demo.mp4
Output frames/
```

### 设置

```
Set Shell bash
Set FontSize 46
Set FontFamily "Monoflow"
Set Width 1200
Set Height 600
Set Padding 32
Set Margin 60
Set BorderRadius 10
Set WindowBar Colorful
Set Theme "Catppuccin Frappe"
Set Framerate 60
Set TypingSpeed 0.1
Set PlaybackSpeed 1.0
Set CursorBlink true
```

### 操作命令

```
Type "echo hello"         # 打字
Type@500ms "slow"        # 覆盖速度
Enter / Backspace         # 回车 / 退格
Up / Down / Left / Right  # 方向键
Tab / Space               # Tab / 空格
Ctrl+R                    # Ctrl 组合
ScrollUp 10 / ScrollDown  # 滚动
Sleep 2s                  # 等待
```

### 等待条件

```
Wait /World/              # 等屏幕出现 World
Wait+Screen /Done/        # 搜全屏
Wait+Line /error/         # 只搜最后一行
```

### 录制控制

```
Hide                      # 暂停录制（setup/cleanup）
Show                      # 恢复录制
Screenshot frame.png      # 截图
Copy "text" / Paste      # 剪贴板
Env KEY value             # 环境变量
Require gum               # 依赖检查
Source config.tape        # 引入其他 tape
```

### 隐藏的典型模式

```
Output demo.gif

Hide
Type "go build -o example . && clear"
Enter
Show

Type './example'
Enter
Sleep 3s

Hide
Type 'rm example'
Enter
```

---

## 录制模式

```bash
vhs record > demo.tape   # 边操作边生成脚本
vhs demo.tape
```

## 分享

```bash
vhs publish demo.gif
```

## SSH 远程

```bash
# 服务端
vhs serve

# 客户端
ssh vhs.example.com < demo.tape > demo.gif
```

## 完整示例

```
Output neofetch.gif
Set FontSize 46
Set Width 1200
Set Height 600
Set Theme "Catppuccin Frappe"
Set TypingSpeed 0.05

Type "neofetch"
Sleep 500ms
Enter
Sleep 5s
```
