---
date: 2026-04-24
tags:
  - neovim
  - lazyvim
  - 工具
  - cheatsheet
---

# LazyVim Keymaps 精简速查

- 版本基于: https://www.lazyvim.org/keymaps（默认配置）
- 默认前缀: `<leader>` = `Space`, `<localleader>` = `\\`
- Mode 速记: `n` 普通, `i` 插入, `x` 可视, `o` 操作符等待, `t` 终端, `c` 命令行

## 1) 高频导航与窗口

| Key | 用途 | Mode |
|---|---|---|
| `<C-h>` / `<C-j>` / `<C-k>` / `<C-l>` | 在窗口间左/下/上/右跳转 | `n` |
| `<C-Up>` / `<C-Down>` | 调整窗口高度 | `n` |
| `<C-Left>` / `<C-Right>` | 调整窗口宽度 | `n` |
| `<leader>-` | 向下分割窗口 | `n` |
| `<leader>\|` | 向右分割窗口 | `n` |
| `<leader>wd` | 删除窗口 | `n` |
| `<leader>wm` | 切换窗口缩放模式 | `n` |
| `<leader>uZ` | 切换窗口缩放模式 | `n` |
| `<leader>uz` | 切换 Zen 模式 | `n` |

## 2) Buffer / Tab

| Key | 用途 | Mode |
|---|---|---|
| `<S-h>` / `<S-l>` | 上一个/下一个缓冲区 | `n` |
| `[b` / `]b` | 上一个/下一个缓冲区 | `n` |
| `<leader>bb` | 切换到上一个缓冲区 | `n` |
| `<leader>bd` | 删除当前缓冲区 | `n` |
| `<leader>bo` | 删除其他缓冲区 | `n` |
| `<leader><tab><tab>` | 新建标签页 | `n` |
| `<leader><tab>d` | 关闭标签页 | `n` |
| `<leader><tab>[` / `<leader><tab>]` | 上一个/下一个标签页 | `n` |
| `<leader><tab>o` | 关闭其他标签页 | `n` |

## 3) 文件/搜索（Snacks）

| Key | 用途 | Mode |
|---|---|---|
| `<leader><space>` / `<leader>ff` | 查找文件（根目录） | `n` |
| `<leader>fF` | 查找文件（当前目录） | `n` |
| `<leader>fg` | 查找 Git 文件 | `n` |
| `<leader>/` / `<leader>sg` | 全文搜索（根目录） | `n` |
| `<leader>sG` | 全文搜索（当前目录） | `n` |
| `<leader>sw` / `<leader>sW` | 搜索当前词/选区（根目录/当前目录） | `n,x` |
| `<leader>fr` / `<leader>fR` | 最近文件（根目录/当前目录） | `n` |
| `<leader>,` / `<leader>fb` | 缓冲区列表 | `n` |
| `<leader>e` / `<leader>E` | 文件浏览器（根目录/当前目录） | `n` |
| `<leader>:` / `<leader>sc` | 命令历史 | `n` |

## 4) LSP 常用

| Key | 用途 | Mode |
|---|---|---|
| `gd` | 跳转到定义 | `n` |
| `gr` | 查看引用 | `n` |
| `gI` | 跳转到实现 | `n` |
| `gy` | 跳转到类型定义 | `n` |
| `gD` | 跳转到声明 | `n` |
| `K` | 悬停文档 | `n` |
| `gK` / `<C-k>` | 签名帮助（普通/插入） | `n` / `i` |
| `<leader>ca` | 代码操作（Code Action） | `n,x` |
| `<leader>cr` | 重命名符号 | `n` |
| `<leader>co` | 整理导入 | `n` |
| `<leader>cd` | 行诊断 | `n` |
| `]d` / `[d` | 下一个/上一个诊断 | `n` |

## 5) Git 常用

| Key | 用途 | Mode |
|---|---|---|
| `<leader>gs` | Git 状态 | `n` |
| `<leader>gS` | Git Stash | `n` |
| `<leader>gd` | Git 差异（hunks） | `n` |
| `<leader>gD` | Git 差异（origin） | `n` |
| `<leader>gb` | 当前行 Blame | `n` |
| `<leader>gl` / `<leader>gL` | Git 日志（仓库/当前目录） | `n` |
| `<leader>gf` | 当前文件历史 | `n` |
| `<leader>gB` / `<leader>gY` | Git Browse（打开/复制） | `n,x` |

## 6) 诊断/问题列表

| Key | 用途 | Mode |
|---|---|---|
| `<leader>xx` | Trouble 诊断面板 | `n` |
| `<leader>xX` | Trouble 当前缓冲区诊断 | `n` |
| `<leader>xq` / `<leader>xl` | Quickfix / Location List | `n` |
| `<leader>xQ` / `<leader>xL` | Trouble Quickfix / Location | `n` |
| `[q` / `]q` | 上一个/下一个 Quickfix 或 Trouble 项 | `n` |
| `<leader>st` / `<leader>sT` | Todo / Todo+Fix+Fixme | `n` |
| `[t` / `]t` | 上一个/下一个 Todo 注释 | `n` |

## 7) 终端/会话

| Key | 用途 | Mode |
|---|---|---|
| `<leader>ft` / `<leader>fT` | 打开终端（根目录/当前目录） | `n` |
| `<c-/>` | 打开终端（根目录） | `n,t` |
| `<leader>qs` / `<leader>ql` | 恢复会话 / 恢复上次会话 | `n` |
| `<leader>qS` | 选择会话 | `n` |
| `<leader>qd` | 本次不保存会话 | `n` |
| `<leader>qq` | 退出全部 | `n` |

## 8) 常用开关（Toggle）

| Key | 用途 | Mode |
|---|---|---|
| `<leader>uf` / `<leader>uF` | 自动格式化（全局/当前缓冲区） | `n` |
| `<leader>us` | 拼写检查 | `n` |
| `<leader>uw` | 自动换行 | `n` |
| `<leader>ud` | 诊断显示 | `n` |
| `<leader>ul` / `<leader>uL` | 行号/相对行号 | `n` |
| `<leader>uT` | Treesitter 高亮 | `n` |
| `<leader>ub` | 深色背景 | `n` |
| `<leader>ua` | 动画 | `n` |
| `<leader>uh` | Inlay Hints | `n` |

---

如果你希望，我可以再给你一版「按场景学习路径」：
1. 新手必背 20 个
2. 写代码高频 20 个
3. Git/调试高频 20 个
