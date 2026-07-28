---
tags:
  - cli
  - tool
  - timer
  - productivity
created: 2026-07-15
---

# termdown — 终端倒计时/秒表

> 安装：`pip install termdown`（Python 包）

命令行倒计时与秒表，适合番茄钟/煮面/午休/定时提醒。

---

## 基本用法

```bash
# 倒计时
termdown 10                # 10 秒
termdown 5m                # 5 分钟
termdown 1h 30m            # 1 小时 30 分
termdown 25m               # 25 分钟（番茄钟）

# 秒表（正向计时，不加参数）
termdown

# 倒计时到特定时间
termdown 12:00             # 到中午 12 点
termdown 2026-12-31        # 到跨年
```

---

## 快捷键（运行时按）

| 键       | 功能       |
| ------- | -------- |
| `Space` | 暂停/继续    |
| `R`     | 重置       |
| `+`     | 加 10 秒   |
| `-`     | 减 10 秒   |
| `L`     | 计圈（秒表模式） |
| `E`     | 显示结束时间   |
| `Q`     | 退出       |

---

## 实用参数

| 参数 | 说明 |
|---|---|
| `-b` | 结束时闪屏 |
| `-B` | 结束时不要响铃 |
| `-s` | 不显示秒（最后 1 分钟才显示） |
| `-t "文字"` | 结束时显示的文字 |
| `-T "文字"` | 标题（显示在倒计时上方） |
| `-c N` | 最后 N 秒变红+逐秒播报 |
| `-f FONT` | ASCII 艺术字体 |
| `-o FILE` | 把剩余时间写入文件 |
| `-q N` | 倒计时结束后 N 秒自动退出 |
| `-z` | 显示当前时间而非倒计时 |

## 语音播报

需要安装 espeak：

```bash
sudo dnf install espeak
termdown -v 5m    # 带语音报时
termdown -v -p "还剩" 10m  # 自定义播报前缀
```

---

## 典型场景

### 番茄钟（25 分钟专注）

```bash
termdown -b -T "🍅 专注时间" 25m
```

### 煮面（5 分钟倒计时）

```bash
termdown -b -t "面好了！" 5m
```

### 代码编译预估（秒表计时）

```bash
make && termdown  # 编译完开始计时
```

### 午休计时（不显示秒）

```bash
termdown -s -b 30m
```

---

## alias 推荐

加到 `~/.config/fish/config.fish`：

```fish
alias tomato='termdown -b -T "🍅" 25m'
alias break='termdown -b -T "☕" 5m'
alias timer='termdown -b'
```

然后直接：`tomato`、`break`、`timer 10m`。
