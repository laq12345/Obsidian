---
lang: Linux
date: 2026-03-23
tags:
  - 编程
---
好的，以下是为你整理的 **eza 常用用法速查笔记**：

---

# eza 终端工具速查笔记

> 现代化 `ls` 替代品，Rust 编写，支持图标、Git 集成、树形视图

---

## 基础命令

| 命令 | 作用 |
|:---|:---|
| `eza` | 默认网格视图 |
| `eza -1` | 每行一个条目 |
| `eza -l` | 详细列表（权限/大小/日期） |
| `eza -a` | 显示隐藏文件 |
| `eza -la` | 详细视图 + 隐藏文件 |

---

## 视觉增强

| 命令 | 作用 |
|:---|:---|
| `eza --icons=always` | 显示文件图标（需 Nerd Font）|
| `eza --icons=auto` | 自动判断图标 |
| `eza --classify` | 添加类型指示符（`/` 目录等）|
| `eza --color=always` | 强制颜色输出 |

---

## 树形 & 递归

| 命令 | 作用 |
|:---|:---|
| `eza -T` | 树形结构显示 |
| `eza -T --level=2` | 限制深度为 2 层 |
| `eza -R` | 递归列出子目录 |
| `eza -R --level 2` | 限制递归深度 |

---

## Git 集成

| 命令 | 作用 |
|:---|:---|
| `eza --git` | 显示 Git 状态 |
| `eza -l --git` | 详细视图 + Git 状态 |
| `eza --git-ignore` | 忽略 `.gitignore` 文件 |

**Git 状态标识**：`-` 未修改 | `M` 修改 | `N` 新建 | `D` 删除

---

## 排序 & 过滤

| 命令 | 作用 |
|:---|:---|
| `eza -s size` | 按文件大小排序 |
| `eza -s ext` | 按扩展名排序 |
| `eza -s time` | 按修改时间排序 |
| `eza --reverse` | 反向排序 |
| `eza -D` | 只显示目录 |
| `eza -f` | 只显示文件 |

---

## 实用组合

```bash
# 日常详细列表（图标 + Git）
eza -la --icons --git

# 项目目录树形概览
eza -T --level=3 --icons

# 按大小排序，大文件在前
eza -l --sort=size --reverse

# 显示目录总大小
eza -l --total-size
```

---

## 推荐别名

```bash
alias ls='eza --icons=always'
alias ll='eza -la --icons --git'
alias lt='eza -T --icons --level=2'
alias l='eza -l --icons'
```

---

## 记忆口诀

> **1 行单列，l 详细，a 隐藏，T 树形，R 递归，s 排序，--git 看状态，--icons 更美观**

---