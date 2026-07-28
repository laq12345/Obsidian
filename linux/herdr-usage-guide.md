---
title: Herdr 完全使用指南
tags: [herdr, terminal-multiplexer, ai-agent, tool-guide]
created: 2026-07-28
---

# Herdr 完全使用指南

> **Agent Multiplexer** — 为 AI coding agent 优化的终端工作区管理器
> GitHub: [ogulcancelik/herdr](https://github.com/ogulcancelik/herdr) | ⭐ 21.6k | Apache 2.0
> 官网: [herdr.dev](https://herdr.dev) | 文档: [herdr.dev/docs](https://herdr.dev/docs)

## 概述

Herdr 是一个终端工作区管理器，专为同时运行多个 AI coding agent 设计。它保持真实的终端进程运行并在其周围添加结构化视图。

### 核心特点

- **Agent 状态一目了然** — 侧栏显示每个 agent 的状态: blocked / working / done / idle
- **后台持久运行** — 断开客户端后 agent 继续运行，会话跨重启存活
- **Socket API** — agent 可以自己创建 pane、读写输出、互相等待
- **键盘+鼠标** — 既支持 tmux 风格的 prefix 键，也支持点击/拖拽/右键菜单
- **插件系统** — 可扩展 pane 和工作流
- **单二进制、无 Electron** — 在任意终端中运行

## 安装

```bash
# Linux/macOS 一键安装
curl -fsSL https://herdr.dev/install.sh | sh

# 或 Homebrew
brew install herdr

# 验证
herdr
```

### 更新

```bash
herdr update                    # 直接安装版本更新
herdr channel set preview       # 切换到 preview 频道
herdr channel set stable        # 切回 stable
herdr update --handoff          # 实验性：热迁移会话不中断进程
```

## 核心概念

### Workspace（工作区）

顶层项目容器。每个项目/仓库/任务用一个 workspace。包含 tabs 和 panes。

```bash
herdr workspace list            # 列出工作区
```

### Tab（标签页）

Workspace 内的布局视图。用于分隔不同视图（如 `agents`、`logs`、`server`、`review`）。

### Pane（面板）

一个真实的终端。Herdr 渲染其输出、发送输入，并在客户端断开后保留 pane。

```bash
herdr pane list                 # 列出所有 pane
herdr pane split                # 拆分 pane
```

### Agent（AI 代理）

Herdr 识别的 pane 内进程。状态包括：

| 状态 | 含义 |
|------|------|
| `blocked` | Agent 需要输入/批准/决策 |
| `working` | Agent 正在运行 |
| `done` | Agent 已完成，待查看 |
| `idle` | 已完成或等待中，已被查看 |
| `unknown` | 无法分类 |

### Session（会话）

持久化的 Herdr 服务器命名空间。

```bash
herdr session list              # 列出会话
herdr session attach work       # 附加到命名会话
```

### Client/Server 架构

默认 Herdr 作为后台服务器运行，附加一个或多个客户端。服务器拥有 pane 和进程状态，客户端是终端 UI。

```bash
herdr server stop               # 停止服务器（会结束所有 pane 进程）
```

## 键盘快捷键

### 必记五个

| 操作 | 快捷键 |
|------|--------|
| 新建标签页 | `prefix + c` |
| 向右/向下拆分 | `prefix + v` / `prefix + -` |
| 在 panes 间移动 | `prefix + h/j/k/l` |
| Workspace 导航 | `prefix + w` |
| 断开（保持进程运行） | `prefix + q` |

### Panes

| 操作 | 快捷键 |
|------|--------|
| 缩放当前 pane | `prefix + z` |
| 关闭 pane | `prefix + x` |
| 交换 pane | `prefix + Shift + h/j/k/l` |
| 调整大小模式 | `prefix + r` |
| 复制模式 | `prefix + [` |

### Tabs

| 操作 | 快捷键 |
|------|--------|
| 下一个/上一个 tab | `prefix + n` / `prefix + p` |
| 跳转到 tab 1-9 | `prefix + 1..9` |
| 重命名 tab | `prefix + Shift + t` |
| 关闭 tab | `prefix + Shift + x` |

### Workspace

| 操作 | 快捷键 |
|------|--------|
| 新建 workspace | `prefix + Shift + n` |
| 重命名 workspace | `prefix + Shift + w` |
| 关闭 workspace | `prefix + Shift + d` |
| 跳转选择器 | `prefix + g` |
| 切换侧栏 | `prefix + b` |

### 复制模式 (`prefix + [`)

支持 `h/j/k/l` 移动、`/`/`?` 搜索、`v`/Space 选择、`y`/Enter 复制、`q`/Esc 退出。

### 自定义快捷键

所有快捷键均可配置，包括 prefix 本身：

```toml
[keys]
prefix = "ctrl+a"
```

## 支持的 Agent

Herdr 自动检测常见 coding agent：

| Agent | 状态检测方式 | 会话恢复 |
|-------|-------------|---------|
| Claude Code | 屏幕检测 | ✅ |
| Codex (OpenAI) | 屏幕检测 | ✅ |
| OpenCode | **生命周期插件** | ✅ |
| GitHub Copilot CLI | 屏幕检测 | ✅ |
| Cursor Agent CLI | 屏幕检测 | ✅ |
| Pi | 生命周期 hooks | ✅ |
| Kimi Code CLI | 生命周期 hooks | ✅ |
| Hermes Agent | 生命周期 hooks | ✅ |
| Grok CLI | 屏幕检测 | ❌ |
| Devin CLI | 屏幕检测 | ✅ |
| Kilo Code CLI | 生命周期插件 | ✅ |
| Codex | 屏幕检测 | ❌ |

### 安装集成

```bash
herdr integration install claude       # 安装 Claude Code 集成
herdr integration status               # 查看已安装集成
herdr agent explain <target>           # 排查 agent 状态误判
```

## 会话持久化

### 不同场景的持久化能力

| 场景 | 进程 | 布局 | 屏幕内容 | Agent 对话 |
|------|------|------|----------|-----------|
| 断开重连 | ✅ | ✅ | ✅ 实时 | ✅ 进程未停 |
| 服务器重启 | ❌ | ✅ | 需配置 pane 历史 | ✅ 原生恢复 |
| 更新 (含 `--handoff`) | 尽力 | ✅ | 热迁移成功则保留 | ✅ |

### pane 屏幕历史（默认关闭）

```toml
[experimental]
pane_history = true
```

**注意**：pane 输出可能包含密钥/token，谨慎使用。

## 远程访问

### 方式一：传统 SSH

```bash
ssh you@server
herdr                             # 在远程服务器启动 herdr
```

### 方式二：本地客户端连接远程

```bash
herdr --remote workbox             # 通过 SSH config
herdr --remote ssh://you@server:2222
```

### 方式三：手机 SSH

任意 SSH 客户端连接到服务器，运行 `herdr`。Herdr 会自适应窄屏。

## 配置

配置文件路径：`~/.config/herdr/config.toml`

### 常用配置项

```toml
[ui]
mouse_capture = false              # 禁用鼠标捕获（纯键盘模式）
sidebar_collapsed_mode = "hidden"  # 折叠侧栏时零宽度

[keys]
prefix = "ctrl+a"                  # 自定义 prefix

[session]
resume_agents_on_restore = false   # 禁用 agent 会话自动恢复

[update]
manifest_check = false             # 禁用远程 manifest 自动更新

[experimental]
pane_history = true                # 启用 pane 屏幕历史

[remote]
manage_ssh_config = true           # 自动管理 SSH config
```

## CLI 速查

```bash
herdr                               # 启动/附加到会话
herdr session list                  # 列出会话
herdr session attach <name>         # 附加到命名会话
herdr server stop                   # 停止服务器

herdr workspace list                # 列出工作区
herdr pane list                     # 列出面板
herdr pane split                    # 拆分面板

herdr agent explain <target>        # 排查 agent 状态
herdr agent attach <name>           # 直接附加到 agent
herdr agent rename <target> <name>  # 重命名 agent

herdr integration install <agent>   # 安装 agent 集成
herdr integration status            # 查看集成状态

herdr update                        # 更新 herdr
herdr channel set preview/stable    # 切换更新频道

herdr --remote <host>               # 连接远程 herdr 会话
```

## Socket API

Herdr 提供纯 socket API，agent 可以通过 API 管理自己的工作区：

- 创建/关闭 pane
- 读取 pane 输出
- 发送输入
- 等待其他 agent 完成
- 报告自定义状态

详细参考：[herdr.dev/docs/socket-api](https://herdr.dev/docs/socket-api/)

## 已知问题

- **侧栏 agent 状态偶尔不准** — agent 停止后侧栏仍显示运行中。这是检测机制的问题（依赖轮询 + 屏幕启发式），v0.7.4 有改进但未完全根治
- **Linux 前台进程检测** — 在繁忙的多用户系统上可能增加 CPU 使用

## 与 Zellij/tmux 对比

| 特性 | herdr | Zellij | tmux |
|------|-------|--------|------|
| Agent 状态感知 | ✅ 内置 | ❌ | ❌ |
| 鼠标操作 | ✅ 原生 | ✅ | 需配置 |
| 开箱可用 | ✅ | ✅ | ❌ |
| Socket API | ✅ | ❌ | ❌ |
| 插件系统 | ✅ | ✅ | ✅ |
| 跨平台 | Linux/macOS | Linux/macOS/Windows | 全平台 |
| 许可证 | Apache 2.0 | MIT | BSD |
| 适合 | AI agent 并行工作流 | 日常终端管理 | 服务器/SSH 环境 |
