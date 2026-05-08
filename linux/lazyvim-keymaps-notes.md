---
date: 2026-04-24
tags:
  - lazyvim
  - neovim
  - 工具
---

# LazyVim Keymaps 详细笔记

- 来源: https://www.lazyvim.org/keymaps
- 整理时间: 2026-04-23
- 覆盖范围: 57 个章节, 490 条键位映射（含基础配置与 Extras 插件映射）

## 1. 页面核心内容总结

- LazyVim 使用 `which-key.nvim` 展示可用快捷键前缀提示, 按下例如 `<space>` 可弹出可用映射。
- 默认前缀: `<leader>` = `<space>`, `<localleader>` = `\`。
- 页面结构由两部分组成: 基础键位（General/LSP 等）+ 插件与 Extras 键位（仅在启用对应插件时生效）。
- 高占比场景是文件/搜索导航、LSP 操作、Git 工作流、调试（DAP）、测试、AI 助手与问题追踪。
- `Mode` 列表示该键位在哪些 Vim 模式可用, 同一个键在不同模式下可能触发不同行为。

## 2. `<...>` 形式快捷键是什么意思

- `<...>` 是 Vim/Neovim 对“特殊按键或组合键”的写法。
- `<leader>`: 用户前缀键（LazyVim 默认是空格 `Space`）。例: `<leader>ff` = `Space` 后再按 `f` `f`。
- `<localleader>`: 文件类型本地前缀（LazyVim 默认是反斜杠 `\`）。
- `<C-x>`: `Ctrl + x`，例如 `<C-s>` = `Ctrl + s`。
- `<A-x>`: `Alt + x`（有些终端需要额外配置，可能显示为 Meta）。
- `<S-x>`: `Shift + x`，例如 `<S-h>` 通常等于大写 `H`。
- `<esc>` / `<tab>` / `<space>` / `<cr>`: 分别是 Esc、Tab、空格、回车。
- `<Up>` `<Down>` `<Left>` `<Right>`: 方向键。
- `<leader><tab>...` 是“前缀链”写法, 表示先按 `leader`, 再按 `Tab`, 再按后续键。
- 像 `[d`、`]d` 这种不带尖括号写法是“普通字符序列”映射，不是特殊键名。

## 3. Mode 列各字符含义

| Mode 字符 | 名称 | 含义 | 本页出现次数 |
|---|---|---|---:|
| `n` | Normal mode | 普通模式 | 483 |
| `i` | Insert mode | 插入模式 | 8 |
| `v` | Visual+Select mode | 可视/选择模式（`v` 覆盖 visual + select） | 7 |
| `x` | Visual mode | 可视模式（仅 visual） | 51 |
| `s` | Select mode | 选择模式 | 4 |
| `o` | Operator-pending mode | 操作符等待模式（如 `d`/`c` 后等待动作） | 10 |
| `t` | Terminal mode | 终端模式 | 3 |
| `c` | Command-line mode | 命令行模式 | 2 |

- 注: 页面中个别 `mode` 显示为 `n,n` 这类重复值，语义上等同于 `n`。

## 4. 全量键位表（Description 已翻译为中文）

> 说明: 下表按官网章节顺序整理。若章节标注 `Part of ...`，表示属于 LazyVim Extras，对应模块启用后才会生效。

### 4.1 General

- 条目数: 90

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `j` | 向下 | `n,x` | Down |
| `<Down>` | 向下 | `n,x` | Down |
| `k` | 向上 | `n,x` | Up |
| `<Up>` | 向上 | `n,x` | Up |
| `<C-h>` | 跳转到左侧窗口 | `n` | Go to Left Window |
| `<C-j>` | 跳转到下方窗口 | `n` | Go to Lower Window |
| `<C-k>` | 跳转到上方窗口 | `n` | Go to Upper Window |
| `<C-l>` | 跳转到右侧窗口 | `n` | Go to Right Window |
| `<C-Up>` | 增大窗口高度 | `n` | Increase Window Height |
| `<C-Down>` | 减小窗口高度 | `n` | Decrease Window Height |
| `<C-Left>` | 减小窗口宽度 | `n` | Decrease Window Width |
| `<C-Right>` | 增大窗口宽度 | `n` | Increase Window Width |
| `<A-j>` | 向下移动 | `n,i,v` | Move Down |
| `<A-k>` | 向上移动 | `n,i,v` | Move Up |
| `<S-h>` | 上一个缓冲区 | `n` | Prev Buffer |
| `<S-l>` | 下一个缓冲区 | `n` | Next Buffer |
| `[b` | 上一个缓冲区 | `n` | Prev Buffer |
| `]b` | 下一个缓冲区 | `n` | Next Buffer |
| `<leader>bb` | 切换到另一个缓冲区 | `n` | Switch to Other Buffer |
| `<leader>`` | 切换到另一个缓冲区 | `n` | Switch to Other Buffer |
| `<leader>bd` | 删除缓冲区 | `n` | Delete Buffer |
| `<leader>bo` | 删除其他缓冲区 | `n` | Delete Other Buffers |
| `<leader>bD` | 删除缓冲区并关闭窗口 | `n` | Delete Buffer and Window |
| `<esc>` | 退出并清除 hlsearch | `i,n,s` | Escape and Clear hlsearch |
| `<leader>ur` | 重绘 / 清除 hlsearch / 更新 Diff | `n` | Redraw / Clear hlsearch / Diff Update |
| `n` | 下一个搜索结果 | `n,x,o` | Next Search Result |
| `N` | 上一个搜索结果 | `n,x,o` | Prev Search Result |
| `<C-s>` | 保存文件 | `i,x,n,s` | Save File |
| `<leader>K` | 关键字程序（keywordprg） | `n` | Keywordprg |
| `gco` | 在下方添加注释 | `n` | Add Comment Below |
| `gcO` | 在上方添加注释 | `n` | Add Comment Above |
| `<leader>l` | 打开 Lazy | `n` | Lazy |
| `<leader>fn` | 新建文件 | `n` | New File |
| `<leader>xl` | 位置列表 | `n` | Location List |
| `<leader>xq` | Quickfix 列表 | `n` | Quickfix List |
| `[q` | 上一个 Quickfix 项 | `n` | Previous Quickfix |
| `]q` | 下一个 Quickfix 项 | `n` | Next Quickfix |
| `<leader>cf` | 格式化 | `n,x` | Format |
| `<leader>cd` | 行诊断 | `n` | Line Diagnostics |
| `]d` | 下一个诊断 | `n` | Next Diagnostic |
| `[d` | 上一个诊断 | `n` | Prev Diagnostic |
| `]e` | 下一个错误 | `n` | Next Error |
| `[e` | 上一个错误 | `n` | Prev Error |
| `]w` | 下一个警告 | `n` | Next Warning |
| `[w` | 上一个警告 | `n` | Prev Warning |
| `<leader>uf` | 切换自动格式化（全局） | `n` | Toggle Auto Format (Global) |
| `<leader>uF` | 切换自动格式化（缓冲区） | `n` | Toggle Auto Format (Buffer) |
| `<leader>us` | 切换拼写检查 | `n` | Toggle Spelling |
| `<leader>uw` | 切换自动换行 | `n` | Toggle Wrap |
| `<leader>uL` | 切换相对行号 | `n` | Toggle Relative Number |
| `<leader>ud` | 切换诊断显示 | `n` | Toggle Diagnostics |
| `<leader>ul` | 切换行号显示 | `n` | Toggle Line Numbers |
| `<leader>uc` | 切换 Conceal 级别 | `n` | Toggle Conceal Level |
| `<leader>uA` | 切换标签栏 | `n` | Toggle Tabline |
| `<leader>uT` | 切换 Treesitter 高亮 | `n` | Toggle Treesitter Highlight |
| `<leader>ub` | 切换深色背景 | `n` | Toggle Dark Background |
| `<leader>uD` | 切换变暗效果 | `n` | Toggle Dimming |
| `<leader>ua` | 切换动画 | `n` | Toggle Animations |
| `<leader>ug` | 切换缩进参考线 | `n` | Toggle Indent Guides |
| `<leader>uS` | 切换平滑滚动 | `n` | Toggle Smooth Scroll |
| `<leader>dpp` | 切换性能分析器 | `n` | Toggle Profiler |
| `<leader>dph` | 切换性能分析高亮 | `n` | Toggle Profiler Highlights |
| `<leader>uh` | 切换内联提示 | `n` | Toggle Inlay Hints |
| `<leader>gL` | Git 日志（当前目录） | `n` | Git Log (cwd) |
| `<leader>gb` | Git 当前行归责 | `n` | Git Blame Line |
| `<leader>gf` | Git 当前文件历史 | `n` | Git Current File History |
| `<leader>gl` | Git 日志 | `n` | Git Log |
| `<leader>gB` | Git 浏览（打开） | `n,x` | Git Browse (open) |
| `<leader>gY` | Git 浏览（复制） | `n,x` | Git Browse (copy) |
| `<leader>qq` | 全部退出 | `n` | Quit All |
| `<leader>ui` | 检查当前位置 | `n` | Inspect Pos |
| `<leader>uI` | 检查语法树 | `n` | Inspect Tree |
| `<leader>L` | LazyVim 更新日志 | `n` | LazyVim Changelog |
| `<leader>fT` | 终端（当前目录） | `n` | Terminal (cwd) |
| `<leader>ft` | 终端（根目录） | `n` | Terminal (Root Dir) |
| `<c-/>` | 终端（根目录） | `n,t` | Terminal (Root Dir) |
| `<c-_>` | which-key 忽略占位 | `n,t` | which_key_ignore |
| `<leader>-` | 向下分割窗口 | `n` | Split Window Below |
| `<leader>\|` | 向右分割窗口 | `n` | Split Window Right |
| `<leader>wd` | 删除窗口 | `n` | Delete Window |
| `<leader>wm` | 切换缩放模式 | `n` | Toggle Zoom Mode |
| `<leader>uZ` | 切换缩放模式 | `n` | Toggle Zoom Mode |
| `<leader>uz` | 切换禅模式 | `n` | Toggle Zen Mode |
| `<leader><tab>l` | 最后一个标签页 | `n` | Last Tab |
| `<leader><tab>o` | 关闭其他标签页 | `n` | Close Other Tabs |
| `<leader><tab>f` | 第一个标签页 | `n` | First Tab |
| `<leader><tab><tab>` | 新建标签页 | `n` | New Tab |
| `<leader><tab>]` | 下一个标签页 | `n` | Next Tab |
| `<leader><tab>d` | 关闭标签页 | `n` | Close Tab |
| `<leader><tab>[` | 上一个标签页 | `n` | Previous Tab |

### 4.2 LSP

- 条目数: 24

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>cl` | LSP 信息 | `n` | Lsp Info |
| `gd` | 跳转到定义 | `n` | Goto Definition |
| `gr` | 引用 | `n` | References |
| `gI` | 跳转到实现 | `n` | Goto Implementation |
| `gy` | 跳转到类型定义 | `n` | Goto T[y]pe Definition |
| `gD` | 跳转到声明 | `n` | Goto Declaration |
| `K` | 悬停文档 | `n` | Hover |
| `gK` | 签名帮助 | `n` | Signature Help |
| `<c-k>` | 签名帮助 | `i` | Signature Help |
| `<leader>ca` | 代码操作 | `n,x` | Code Action |
| `<leader>cc` | 运行 Codelens | `n,x` | Run Codelens |
| `<leader>cC` | 刷新并显示 Codelens | `n` | Refresh & Display Codelens |
| `<leader>cR` | 重命名文件 | `n` | Rename File |
| `<leader>cr` | 重命名 | `n` | Rename |
| `<leader>cA` | 源代码操作 | `n` | Source Action |
| `]]` | 下一个引用 | `n` | Next Reference |
| `[[` | 上一个引用 | `n` | Prev Reference |
| `<a-n>` | 下一个引用 | `n` | Next Reference |
| `<a-p>` | 上一个引用 | `n` | Prev Reference |
| `<leader>co` | 整理导入 | `n` | Organize Imports |
| `<leader>ss` | LSP 符号 | `n` | LSP Symbols |
| `<leader>sS` | LSP 工作区符号 | `n` | LSP Workspace Symbols |
| `gai` | 传入调用 | `n` | C[a]lls Incoming |
| `gao` | 传出调用 | `n` | C[a]lls Outgoing |

### 4.3 bufferline.nvim

- 条目数: 11

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>bj` | 选择缓冲区 | `n` | Pick Buffer |
| `<leader>bl` | 删除左侧缓冲区 | `n` | Delete Buffers to the Left |
| `<leader>bp` | 切换固定 | `n` | Toggle Pin |
| `<leader>bP` | 删除未固定缓冲区 | `n` | Delete Non-Pinned Buffers |
| `<leader>br` | 删除右侧缓冲区 | `n` | Delete Buffers to the Right |
| `[b` | 上一个缓冲区 | `n` | Prev Buffer |
| `[B` | 缓冲区前移 | `n` | Move buffer prev |
| `]b` | 下一个缓冲区 | `n` | Next Buffer |
| `]B` | 缓冲区后移 | `n` | Move buffer next |
| `<S-h>` | 上一个缓冲区 | `n` | Prev Buffer |
| `<S-l>` | 下一个缓冲区 | `n` | Next Buffer |

### 4.4 conform.nvim

- 条目数: 1

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>cF` | 格式化注入语言 | `n,x` | Format Injected Langs |

### 4.5 flash.nvim

- 条目数: 6

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<c-s>` | 切换 Flash 搜索 | `c` | Toggle Flash Search |
| `r` | 远程 Flash | `o` | Remote Flash |
| `R` | Treesitter 搜索 | `o,x` | Treesitter Search |
| `s` | Flash 跳转 | `n,o,x` | Flash |
| `S` | Flash Treesitter 跳转 | `n,o,x` | Flash Treesitter |
| `<c-space>` | Treesitter 增量选择 | `n,o,x` | Treesitter Incremental Selection |

### 4.6 grug-far.nvim

- 条目数: 1

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>sr` | 搜索与替换 | `n,x` | Search and Replace |

### 4.7 mason.nvim (1)

- 条目数: 1

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>cm` | Mason 包管理 | `n` | Mason |

### 4.8 noice.nvim

- 条目数: 9

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<c-b>` | 向后滚动 | `n,i,s` | Scroll Backward |
| `<c-f>` | 向前滚动 | `n,i,s` | Scroll Forward |
| `<leader>sn` | 分组：Noice 相关 | `n` | +noice |
| `<leader>sna` | Noice 全部消息 | `n` | Noice All |
| `<leader>snd` | 清除全部 | `n` | Dismiss All |
| `<leader>snh` | Noice 历史 | `n` | Noice History |
| `<leader>snl` | Noice 最后一条消息 | `n` | Noice Last Message |
| `<leader>snt` | Noice 选择器（Telescope/FzfLua） | `n` | Noice Picker (Telescope/FzfLua) |
| `<S-Enter>` | 重定向命令行 | `c` | Redirect Cmdline |

### 4.9 persistence.nvim

- 条目数: 4

| Key          | Description（中文） | Mode | Description（原文）            |
| ------------ | --------------- | ---- | -------------------------- |
| `<leader>qd` | 不保存当前会话         | `n`  | Don't Save Current Session |
| `<leader>ql` | 恢复上次会话          | `n`  | Restore Last Session       |
| `<leader>qs` | 恢复会话            | `n`  | Restore Session            |
| `<leader>qS` | 选择会话            | `n`  | Select Session             |

### 4.10 snacks.nvim (1)

- 条目数: 56

| Key               | Description（中文）          | Mode  | Description（原文）                     |
| ----------------- | ------------------------ | ----- | ----------------------------------- |
| `<leader><space>` | 查找文件（根目录）                | `n`   | Find Files (Root Dir)               |
| `<leader>,`       | 缓冲区列表                    | `n`   | Buffers                             |
| `<leader>.`       | 切换临时缓冲区                  | `n`   | Toggle Scratch Buffer               |
| `<leader>/`       | 全文搜索（根目录）                | `n`   | Grep (Root Dir)                     |
| `<leader>:`       | 命令历史                     | `n`   | Command History                     |
| `<leader>dps`     | 性能分析临时缓冲区                | `n`   | Profiler Scratch Buffer             |
| `<leader>e`       | Snacks 文件浏览器（根目录）        | `n`   | Explorer Snacks (root dir)          |
| `<leader>E`       | Snacks 文件浏览器（当前目录）       | `n`   | Explorer Snacks (cwd)               |
| `<leader>fb`      | 缓冲区列表                    | `n`   | Buffers                             |
| `<leader>fB`      | 所有缓冲区列表                  | `n`   | Buffers (all)                       |
| `<leader>fc`      | 查找配置文件                   | `n`   | Find Config File                    |
| `<leader>fe`      | Snacks 文件浏览器（根目录）        | `n`   | Explorer Snacks (root dir)          |
| `<leader>fE`      | Snacks 文件浏览器（当前目录）       | `n`   | Explorer Snacks (cwd)               |
| `<leader>ff`      | 查找文件（根目录）                | `n`   | Find Files (Root Dir)               |
| `<leader>fF`      | 查找文件（当前目录）               | `n`   | Find Files (cwd)                    |
| `<leader>fg`      | 查找文件（Git 文件）             | `n`   | Find Files (git-files)              |
| `<leader>fp`      | 项目列表                     | `n`   | Projects                            |
| `<leader>fr`      | 最近文件                     | `n`   | Recent                              |
| `<leader>fR`      | 最近文件（当前目录）               | `n`   | Recent (cwd)                        |
| `<leader>gd`      | Git 差异（代码块）              | `n`   | Git Diff (hunks)                    |
| `<leader>gD`      | Git 差异（远端 origin）        | `n`   | Git Diff (origin)                   |
| `<leader>gi`      | GitHub Issues（打开）        | `n`   | GitHub Issues (open)                |
| `<leader>gI`      | GitHub Issues（全部）        | `n`   | GitHub Issues (all)                 |
| `<leader>gp`      | GitHub Pull Requests（打开） | `n`   | GitHub Pull Requests (open)         |
| `<leader>gP`      | GitHub Pull Requests（全部） | `n`   | GitHub Pull Requests (all)          |
| `<leader>gs`      | Git 状态                   | `n`   | Git Status                          |
| `<leader>gS`      | Git 暂存区                  | `n`   | Git Stash                           |
| `<leader>n`       | 通知历史                     | `n`   | Notification History                |
| `<leader>S`       | 选择临时缓冲区                  | `n`   | Select Scratch Buffer               |
| `<leader>s"`      | 寄存器列表                    | `n`   | Registers                           |
| `<leader>s/`      | 搜索历史                     | `n`   | Search History                      |
| `<leader>sa`      | 自动命令                     | `n`   | Autocmds                            |
| `<leader>sb`      | 缓冲区行                     | `n`   | Buffer Lines                        |
| `<leader>sB`      | 在已打开缓冲区中搜索               | `n`   | Grep Open Buffers                   |
| `<leader>sc`      | 命令历史                     | `n`   | Command History                     |
| `<leader>sC`      | 命令列表                     | `n`   | Commands                            |
| `<leader>sd`      | 诊断列表                     | `n`   | Diagnostics                         |
| `<leader>sD`      | 当前缓冲区诊断                  | `n`   | Buffer Diagnostics                  |
| `<leader>sg`      | 全文搜索（根目录）                | `n`   | Grep (Root Dir)                     |
| `<leader>sG`      | 全文搜索（当前目录）               | `n`   | Grep (cwd)                          |
| `<leader>sh`      | 帮助页面                     | `n`   | Help Pages                          |
| `<leader>sH`      | 高亮组                      | `n`   | Highlights                          |
| `<leader>si`      | 图标列表                     | `n`   | Icons                               |
| `<leader>sj`      | 跳转列表                     | `n`   | Jumps                               |
| `<leader>sk`      | 按键映射列表                   | `n`   | Keymaps                             |
| `<leader>sl`      | 位置列表                     | `n`   | Location List                       |
| `<leader>sm`      | 标记列表                     | `n`   | Marks                               |
| `<leader>sM`      | Man 页面                   | `n`   | Man Pages                           |
| `<leader>sp`      | 搜索插件规范                   | `n`   | Search for Plugin Spec              |
| `<leader>sq`      | Quickfix 列表              | `n`   | Quickfix List                       |
| `<leader>sR`      | 恢复上次搜索                   | `n`   | Resume                              |
| `<leader>su`      | 撤销树                      | `n`   | Undotree                            |
| `<leader>sw`      | 选区或光标词搜索（根目录）            | `n,x` | Visual selection or word (Root Dir) |
| `<leader>sW`      | 选区或光标词搜索（当前目录）           | `n,x` | Visual selection or word (cwd)      |
| `<leader>uC`      | 配色方案                     | `n`   | Colorschemes                        |
| `<leader>un`      | 清除全部通知                   | `n`   | Dismiss All Notifications           |

### 4.11 todo-comments.nvim (1)

- 条目数: 6

| Key          | Description（中文）       | Mode | Description（原文）          |
| ------------ | --------------------- | ---- | ------------------------ |
| `<leader>st` | 待办                    | `n`  | Todo                     |
| `<leader>sT` | 待办/Fix/Fixme          | `n`  | Todo/Fix/Fixme           |
| `<leader>xt` | 待办（Trouble）           | `n`  | Todo (Trouble)           |
| `<leader>xT` | 待办/Fix/Fixme（Trouble） | `n`  | Todo/Fix/Fixme (Trouble) |
| `[t`         | 上一个 Todo 注释           | `n`  | Previous Todo Comment    |
| `]t`         | 下一个 Todo 注释           | `n`  | Next Todo Comment        |

### 4.12 trouble.nvim

- 条目数: 8

| Key          | Description（中文）        | Mode | Description（原文）                          |     |
| ------------ | ---------------------- | ---- | ---------------------------------------- | --- |
| `<leader>cs` | 符号（Trouble）            | `n`  | Symbols (Trouble)                        |     |
| `<leader>cS` | LSP 引用/定义/...（Trouble） | `n`  | LSP references/definitions/... (Trouble) |     |
| `<leader>xL` | 位置列表（Trouble）          | `n`  | Location List (Trouble)                  |     |
| `<leader>xQ` | Quickfix 列表（Trouble）   | `n`  | Quickfix List (Trouble)                  |     |
| `<leader>xx` | 诊断（Trouble）            | `n`  | Diagnostics (Trouble)                    |     |
| `<leader>xX` | 缓冲区诊断（Trouble）         | `n`  | Buffer Diagnostics (Trouble)             |     |
| `[q`         | 上一个 Trouble/Quickfix 项 | `n`  | Previous Trouble/Quickfix Item           |     |
| `]q`         | 下一个 Trouble/Quickfix 项 | `n`  | Next Trouble/Quickfix Item               |     |

### 4.13 which-key.nvim

- 条目数: 2

| Key            | Description（中文）        | Mode | Description（原文）               |
| -------------- | ---------------------- | ---- | ----------------------------- |
| `<c-w><space>` | 窗口 Hydra 模式（which-key） | `n`  | Window Hydra Mode (which-key) |
| `<leader>?`    | 当前缓冲区键位（which-key）     | `n`  | Buffer Keymaps (which-key)    |
|                |                        |      |                               |

### 4.14 avante.nvim

- 条目数: 11
- Part of: `[lazyvim.plugins.extras.ai.avante](/extras/ai/avante)`

| Key          | Description（中文） | Mode | Description（原文）        |
| ------------ | --------------- | ---- | ---------------------- |
| `<leader>aa` | 向 Avante 提问     | `n`  | Ask Avante             |
| `<leader>ac` | 与 Avante 对话     | `n`  | Chat with Avante       |
| `<leader>ae` | 编辑 Avante       | `n`  | Edit Avante            |
| `<leader>af` | 聚焦 Avante       | `n`  | Focus Avante           |
| `<leader>ah` | Avante 历史       | `n`  | Avante History         |
| `<leader>am` | 选择 Avante 模型    | `n`  | Select Avante Model    |
| `<leader>an` | 新建 Avante 对话    | `n`  | New Avante Chat        |
| `<leader>ap` | 切换 Avante 提供商   | `n`  | Switch Avante Provider |
| `<leader>ar` | 刷新 Avante       | `n`  | Refresh Avante         |
| `<leader>as` | 停止 Avante       | `n`  | Stop Avante            |
| `<leader>at` | 切换 Avante       | `n`  | Toggle Avante          |

### 4.15 claudecode.nvim

- 条目数: 10
- Part of: `[lazyvim.plugins.extras.ai.claudecode](/extras/ai/claudecode)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>a` | 分组：AI 相关 | `n,v` | +ai |
| `<leader>aa` | 接受差异 | `n` | Accept diff |
| `<leader>ab` | 添加当前缓冲区 | `n` | Add current buffer |
| `<leader>ac` | 切换 Claude | `n` | Toggle Claude |
| `<leader>aC` | 继续 Claude 会话 | `n` | Continue Claude |
| `<leader>ad` | 拒绝差异 | `n` | Deny diff |
| `<leader>af` | 聚焦 Claude | `n` | Focus Claude |
| `<leader>ar` | 恢复 Claude 会话 | `n` | Resume Claude |
| `<leader>as` | 添加文件 | `n` | Add file |
| `<leader>as` | 发送到 Claude | `v` | Send to Claude |

### 4.16 CopilotChat.nvim

- 条目数: 6
- Part of: `[lazyvim.plugins.extras.ai.copilot-chat](/extras/ai/copilot-chat)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<c-s>` | 提交提示词 | `n` | Submit Prompt |
| `<leader>a` | 分组：AI 相关 | `n,x` | +ai |
| `<leader>aa` | 切换（CopilotChat） | `n,x` | Toggle (CopilotChat) |
| `<leader>ap` | 提示词操作（CopilotChat） | `n,x` | Prompt Actions (CopilotChat) |
| `<leader>aq` | 快速对话（CopilotChat） | `n,x` | Quick Chat (CopilotChat) |
| `<leader>ax` | 清空（CopilotChat） | `n,x` | Clear (CopilotChat) |

### 4.17 sidekick.nvim

- 条目数: 9
- Part of: `[lazyvim.plugins.extras.ai.sidekick](/extras/ai/sidekick)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>a` | 分组：AI 相关 | `n,v` | +ai |
| `<leader>aa` | 切换 Sidekick CLI | `n` | Sidekick Toggle CLI |
| `<leader>ad` | 分离 CLI 会话 | `n` | Detach a CLI Session |
| `<leader>af` | 发送文件 | `n` | Send File |
| `<leader>ap` | Sidekick 选择提示词 | `n,x` | Sidekick Select Prompt |
| `<leader>as` | 选择 CLI | `n` | Select CLI |
| `<leader>at` | 发送当前内容 | `n,x` | Send This |
| `<leader>av` | 发送可视选区 | `x` | Send Visual Selection |
| `<c-.>` | 聚焦 Sidekick | `n,i,t,x` | Sidekick Focus |

### 4.18 mini.surround (1)

- 条目数: 7
- Part of: `[lazyvim.plugins.extras.coding.mini-surround](/extras/coding/mini-surround)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `gsa` | 添加包围符 | `n,x` | Add Surrounding |
| `gsd` | 删除包围符 | `n` | Delete Surrounding |
| `gsf` | 查找右侧包围符 | `n` | Find Right Surrounding |
| `gsF` | 查找左侧包围符 | `n` | Find Left Surrounding |
| `gsh` | 高亮包围符 | `n` | Highlight Surrounding |
| `gsn` | 更新 `MiniSurround.config.n_lines` | `n` | Update `MiniSurround.config.n_lines` |
| `gsr` | 替换包围符 | `n` | Replace Surrounding |

### 4.19 neogen

- 条目数: 1
- Part of: `[lazyvim.plugins.extras.coding.neogen](/extras/coding/neogen)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>cn` | 生成注释（Neogen） | `n` | Generate Annotations (Neogen) |

### 4.20 yanky.nvim

- 条目数: 18
- Part of: `[lazyvim.plugins.extras.coding.yanky](/extras/coding/yanky)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>p` | 打开 Yank 历史 | `n,x` | Open Yank History |
| `<p` | 粘贴并左缩进 | `n` | Put and Indent Left |
| `<P` | 向前粘贴并左缩进 | `n` | Put Before and Indent Left |
| `=p` | 应用过滤后向后粘贴 | `n` | Put After Applying a Filter |
| `=P` | 应用过滤后向前粘贴 | `n` | Put Before Applying a Filter |
| `>p` | 粘贴并右缩进 | `n` | Put and Indent Right |
| `>P` | 向前粘贴并右缩进 | `n` | Put Before and Indent Right |
| `[p` | 在光标前按行缩进粘贴 | `n` | Put Indented Before Cursor (Linewise) |
| `[P` | 在光标前按行缩进粘贴 | `n` | Put Indented Before Cursor (Linewise) |
| `[y` | 在 Yank 历史中向前循环 | `n` | Cycle Forward Through Yank History |
| `]p` | 在光标后按行缩进粘贴 | `n` | Put Indented After Cursor (Linewise) |
| `]P` | 在光标后按行缩进粘贴 | `n` | Put Indented After Cursor (Linewise) |
| `]y` | 在 Yank 历史中向后循环 | `n` | Cycle Backward Through Yank History |
| `gp` | 在选区后粘贴文本 | `n,x` | Put Text After Selection |
| `gP` | 在选区前粘贴文本 | `n,x` | Put Text Before Selection |
| `p` | 在光标后粘贴文本 | `n,x` | Put Text After Cursor |
| `P` | 在光标前粘贴文本 | `n,x` | Put Text Before Cursor |
| `y` | 复制文本 | `n,x` | Yank Text |

### 4.21 nvim-dap (1)

- 条目数: 17
- Part of: `[lazyvim.plugins.extras.dap.core](/extras/dap/core)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>da` | 带参数运行 | `n` | Run with Args |
| `<leader>db` | 切换断点 | `n` | Toggle Breakpoint |
| `<leader>dB` | 断点条件 | `n` | Breakpoint Condition |
| `<leader>dc` | 运行/继续 | `n` | Run/Continue |
| `<leader>dC` | 运行到光标 | `n` | Run to Cursor |
| `<leader>dg` | 跳转到行（不执行） | `n` | Go to Line (No Execute) |
| `<leader>di` | 单步进入 | `n` | Step Into |
| `<leader>dj` | 向下 | `n` | Down |
| `<leader>dk` | 向上 | `n` | Up |
| `<leader>dl` | 运行上次命令 | `n` | Run Last |
| `<leader>do` | 单步跳出 | `n` | Step Out |
| `<leader>dO` | 单步跳过 | `n` | Step Over |
| `<leader>dP` | 暂停 | `n` | Pause |
| `<leader>dr` | 切换 REPL | `n` | Toggle REPL |
| `<leader>ds` | 会话 | `n` | Session |
| `<leader>dt` | 终止 | `n` | Terminate |
| `<leader>dw` | 小组件 | `n` | Widgets |

### 4.22 nvim-dap-ui

- 条目数: 2
- Part of: `[lazyvim.plugins.extras.dap.core](/extras/dap/core)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>de` | 求值 | `n,x` | Eval |
| `<leader>du` | Dap UI 面板 | `n` | Dap UI |

### 4.23 aerial.nvim

- 条目数: 1
- Part of: `[lazyvim.plugins.extras.editor.aerial](/extras/editor/aerial)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>cs` | Aerial 符号面板 | `n` | Aerial (Symbols) |

### 4.24 telescope.nvim (1)

- 条目数: 1
- Part of: `[lazyvim.plugins.extras.editor.aerial](/extras/editor/aerial)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>ss` | 跳转到符号（Aerial） | `n` | Goto Symbol (Aerial) |

### 4.25 dial.nvim

- 条目数: 4
- Part of: `[lazyvim.plugins.extras.editor.dial](/extras/editor/dial)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<C-a>` | 递增 | `n,v` | Increment |
| `<C-x>` | 递减 | `n,v` | Decrement |
| `g<C-a>` | 递增 | `n,x` | Increment |
| `g<C-x>` | 递减 | `n,x` | Decrement |

### 4.26 harpoon

- 条目数: 11
- Part of: `[lazyvim.plugins.extras.editor.harpoon2](/extras/editor/harpoon2)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>1` | Harpoon 跳到文件 1 | `n` | Harpoon to File 1 |
| `<leader>2` | Harpoon 跳到文件 2 | `n` | Harpoon to File 2 |
| `<leader>3` | Harpoon 跳到文件 3 | `n` | Harpoon to File 3 |
| `<leader>4` | Harpoon 跳到文件 4 | `n` | Harpoon to File 4 |
| `<leader>5` | Harpoon 跳到文件 5 | `n` | Harpoon to File 5 |
| `<leader>6` | Harpoon 跳到文件 6 | `n` | Harpoon to File 6 |
| `<leader>7` | Harpoon 跳到文件 7 | `n` | Harpoon to File 7 |
| `<leader>8` | Harpoon 跳到文件 8 | `n` | Harpoon to File 8 |
| `<leader>9` | Harpoon 跳到文件 9 | `n` | Harpoon to File 9 |
| `<leader>h` | Harpoon 快速菜单 | `n` | Harpoon Quick Menu |
| `<leader>H` | Harpoon 文件标记 | `n` | Harpoon File |

### 4.27 vim-illuminate

- 条目数: 2
- Part of: `[lazyvim.plugins.extras.editor.illuminate](/extras/editor/illuminate)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `[[` | 上一个引用 | `n` | Prev Reference |
| `]]` | 下一个引用 | `n` | Next Reference |

### 4.28 leap.nvim

- 条目数: 3
- Part of: `[lazyvim.plugins.extras.editor.leap](/extras/editor/leap)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `gs` | Leap 跨窗口跳转 | `n,o,x` | Leap from Windows |
| `s` | Leap 向前跳 | `n,o,x` | Leap Forward to |
| `S` | Leap 向后跳 | `n,o,x` | Leap Backward to |

### 4.29 mini.surround (2)

- 条目数: 1
- Part of: `[lazyvim.plugins.extras.editor.leap](/extras/editor/leap)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `gz` | 分组：包围符相关 | `n` | +surround |

### 4.30 mini.diff

- 条目数: 1
- Part of: `[lazyvim.plugins.extras.editor.mini-diff](/extras/editor/mini-diff)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>go` | 切换 mini.diff 覆盖层 | `n` | Toggle mini.diff overlay |

### 4.31 mini.files

- 条目数: 2
- Part of: `[lazyvim.plugins.extras.editor.mini-files](/extras/editor/mini-files)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>fm` | 打开 mini.files（当前文件所在目录） | `n` | Open mini.files (Directory of Current File) |
| `<leader>fM` | 打开 mini.files（当前目录） | `n` | Open mini.files (cwd) |

### 4.32 outline.nvim

- 条目数: 1
- Part of: `[lazyvim.plugins.extras.editor.outline](/extras/editor/outline)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>cs` | 切换 Outline | `n` | Toggle Outline |

### 4.33 overseer.nvim

- 条目数: 3
- Part of: `[lazyvim.plugins.extras.editor.overseer](/extras/editor/overseer)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>oo` | 运行任务 | `n` | Run task |
| `<leader>ot` | 任务操作 | `n` | Task action |
| `<leader>ow` | 任务列表 | `n` | Task list |

### 4.34 refactoring.nvim

- 条目数: 9
- Part of: `[lazyvim.plugins.extras.editor.refactoring](/extras/editor/refactoring)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>r` | 分组：重构相关 | `n,x` | +refactor |
| `<leader>rc` | 调试清理 | `n` | Debug Cleanup |
| `<leader>rf` | 提取函数 | `n,x` | Extract Function |
| `<leader>rF` | 提取函数到文件 | `n,x` | Extract Function To File |
| `<leader>ri` | 内联变量 | `n,x` | Inline Variable |
| `<leader>rp` | 打印调试变量 | `n,x` | Debug Print Variable |
| `<leader>rP` | 打印调试位置 | `n` | Debug Print Location |
| `<leader>rs` | 选择重构 | `n,x` | Select Refactor |
| `<leader>rx` | 提取变量 | `n,x` | Extract Variable |

### 4.35 snacks.nvim (2)

- 条目数: 4
- Part of: `[lazyvim.plugins.extras.editor.snacks\_explorer](/extras/editor/snacks_explorer)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>e` | Snacks 文件浏览器（根目录） | `n` | Explorer Snacks (root dir) |
| `<leader>E` | Snacks 文件浏览器（当前目录） | `n` | Explorer Snacks (cwd) |
| `<leader>fe` | Snacks 文件浏览器（根目录） | `n` | Explorer Snacks (root dir) |
| `<leader>fE` | Snacks 文件浏览器（当前目录） | `n` | Explorer Snacks (cwd) |

### 4.36 snacks.nvim (3)

- 条目数: 48
- Part of: `[lazyvim.plugins.extras.editor.snacks\_picker](/extras/editor/snacks_picker)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader><space>` | 查找文件（根目录） | `n` | Find Files (Root Dir) |
| `<leader>,` | 缓冲区列表 | `n` | Buffers |
| `<leader>/` | 全文搜索（根目录） | `n` | Grep (Root Dir) |
| `<leader>:` | 命令历史 | `n` | Command History |
| `<leader>fb` | 缓冲区列表 | `n` | Buffers |
| `<leader>fB` | 所有缓冲区列表 | `n` | Buffers (all) |
| `<leader>fc` | 查找配置文件 | `n` | Find Config File |
| `<leader>ff` | 查找文件（根目录） | `n` | Find Files (Root Dir) |
| `<leader>fF` | 查找文件（当前目录） | `n` | Find Files (cwd) |
| `<leader>fg` | 查找文件（Git 文件） | `n` | Find Files (git-files) |
| `<leader>fp` | 项目列表 | `n` | Projects |
| `<leader>fr` | 最近文件 | `n` | Recent |
| `<leader>fR` | 最近文件（当前目录） | `n` | Recent (cwd) |
| `<leader>gd` | Git 差异（代码块） | `n` | Git Diff (hunks) |
| `<leader>gD` | Git 差异（远端 origin） | `n` | Git Diff (origin) |
| `<leader>gi` | GitHub Issues（打开） | `n` | GitHub Issues (open) |
| `<leader>gI` | GitHub Issues（全部） | `n` | GitHub Issues (all) |
| `<leader>gp` | GitHub Pull Requests（打开） | `n` | GitHub Pull Requests (open) |
| `<leader>gP` | GitHub Pull Requests（全部） | `n` | GitHub Pull Requests (all) |
| `<leader>gs` | Git 状态 | `n` | Git Status |
| `<leader>gS` | Git 暂存区 | `n` | Git Stash |
| `<leader>n` | 通知历史 | `n` | Notification History |
| `<leader>s"` | 寄存器列表 | `n` | Registers |
| `<leader>s/` | 搜索历史 | `n` | Search History |
| `<leader>sa` | 自动命令 | `n` | Autocmds |
| `<leader>sb` | 缓冲区行 | `n` | Buffer Lines |
| `<leader>sB` | 在已打开缓冲区中搜索 | `n` | Grep Open Buffers |
| `<leader>sc` | 命令历史 | `n` | Command History |
| `<leader>sC` | 命令列表 | `n` | Commands |
| `<leader>sd` | 诊断列表 | `n` | Diagnostics |
| `<leader>sD` | 当前缓冲区诊断 | `n` | Buffer Diagnostics |
| `<leader>sg` | 全文搜索（根目录） | `n` | Grep (Root Dir) |
| `<leader>sG` | 全文搜索（当前目录） | `n` | Grep (cwd) |
| `<leader>sh` | 帮助页面 | `n` | Help Pages |
| `<leader>sH` | 高亮组 | `n` | Highlights |
| `<leader>si` | 图标列表 | `n` | Icons |
| `<leader>sj` | 跳转列表 | `n` | Jumps |
| `<leader>sk` | 按键映射列表 | `n` | Keymaps |
| `<leader>sl` | 位置列表 | `n` | Location List |
| `<leader>sm` | 标记列表 | `n` | Marks |
| `<leader>sM` | Man 页面 | `n` | Man Pages |
| `<leader>sp` | 搜索插件规范 | `n` | Search for Plugin Spec |
| `<leader>sq` | Quickfix 列表 | `n` | Quickfix List |
| `<leader>sR` | 恢复上次搜索 | `n` | Resume |
| `<leader>su` | 撤销树 | `n` | Undotree |
| `<leader>sw` | 选区或光标词搜索（根目录） | `n,x` | Visual selection or word (Root Dir) |
| `<leader>sW` | 选区或光标词搜索（当前目录） | `n,x` | Visual selection or word (cwd) |
| `<leader>uC` | 配色方案 | `n` | Colorschemes |

### 4.37 todo-comments.nvim (2)

- 条目数: 2
- Part of: `[lazyvim.plugins.extras.editor.snacks\_picker](/extras/editor/snacks_picker)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>st` | 待办 | `n` | Todo |
| `<leader>sT` | 待办/Fix/Fixme | `n` | Todo/Fix/Fixme |

### 4.38 nvim-ansible

- 条目数: 1
- Part of: `[lazyvim.plugins.extras.lang.ansible](/extras/lang/ansible)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>ta` | 运行 Ansible Playbook/Role | `n` | Ansible Run Playbook/Role |

### 4.39 haskell-tools.nvim

- 条目数: 4
- Part of: `[lazyvim.plugins.extras.lang.haskell](/extras/lang/haskell)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<localleader>e` | 全部求值 | `n` | Evaluate All |
| `<localleader>h` | Hoogle 签名搜索 | `n` | Hoogle Signature |
| `<localleader>r` | REPL（包） | `n` | REPL (Package) |
| `<localleader>R` | REPL（缓冲区） | `n` | REPL (Buffer) |

### 4.40 telescope\_hoogle

- 条目数: 1
- Part of: `[lazyvim.plugins.extras.lang.haskell](/extras/lang/haskell)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<localleader>H` | Hoogle 搜索 | `n` | Hoogle |

### 4.41 markdown-preview.nvim

- 条目数: 1
- Part of: `[lazyvim.plugins.extras.lang.markdown](/extras/lang/markdown)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>cp` | Markdown 预览 | `n` | Markdown Preview |

### 4.42 nvim-dap-python

- 条目数: 2
- Part of: `[lazyvim.plugins.extras.lang.python](/extras/lang/python)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>dPc` | 调试类 | `n` | Debug Class |
| `<leader>dPt` | 调试方法 | `n` | Debug Method |

### 4.43 venv-selector.nvim

- 条目数: 1
- Part of: `[lazyvim.plugins.extras.lang.python](/extras/lang/python)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>cv` | 选择虚拟环境 | `n` | Select VirtualEnv |

### 4.44 nvim-metals

- 条目数: 3
- Part of: `[lazyvim.plugins.extras.lang.scala](/extras/lang/scala)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>mc` | Metals 级联编译 | `n` | Metals compile cascade |
| `<leader>me` | Metals 命令 | `n` | Metals commands |
| `<leader>mh` | Metals 悬停工作表 | `n` | Metals hover worksheet |

### 4.45 vim-dadbod-ui

- 条目数: 1
- Part of: `[lazyvim.plugins.extras.lang.sql](/extras/lang/sql)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>D` | 切换 DBUI | `n` | Toggle DBUI |

### 4.46 vimtex

- 条目数: 1
- Part of: `[lazyvim.plugins.extras.lang.tex](/extras/lang/tex)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<localLeader>l` | 分组：VimTeX 相关 | `n` | +vimtex |

### 4.47 typst-preview.nvim

- 条目数: 1
- Part of: `[lazyvim.plugins.extras.lang.typst](/extras/lang/typst)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>cp` | 切换 Typst 预览 | `n` | Toggle Typst Preview |

### 4.48 neotest

- 条目数: 11
- Part of: `[lazyvim.plugins.extras.test.core](/extras/test/core)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>t` | 分组：测试相关 | `n` | +test |
| `<leader>ta` | 附加到测试（Neotest） | `n` | Attach to Test (Neotest) |
| `<leader>tl` | 运行上次测试（Neotest） | `n` | Run Last (Neotest) |
| `<leader>to` | 显示输出（Neotest） | `n` | Show Output (Neotest) |
| `<leader>tO` | 切换输出面板（Neotest） | `n` | Toggle Output Panel (Neotest) |
| `<leader>tr` | 运行最近测试（Neotest） | `n` | Run Nearest (Neotest) |
| `<leader>ts` | 切换汇总（Neotest） | `n` | Toggle Summary (Neotest) |
| `<leader>tS` | 停止（Neotest） | `n` | Stop (Neotest) |
| `<leader>tt` | 运行文件测试（Neotest） | `n` | Run File (Neotest) |
| `<leader>tT` | 运行所有测试文件（Neotest） | `n` | Run All Test Files (Neotest) |
| `<leader>tw` | 切换监听（Neotest） | `n` | Toggle Watch (Neotest) |

### 4.49 nvim-dap (2)

- 条目数: 1
- Part of: `[lazyvim.plugins.extras.test.core](/extras/test/core)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>td` | 调试最近目标 | `n` | Debug Nearest |

### 4.50 edgy.nvim

- 条目数: 2
- Part of: `[lazyvim.plugins.extras.ui.edgy](/extras/ui/edgy)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>ue` | 切换 Edgy | `n` | Edgy Toggle |
| `<leader>uE` | Edgy 选择窗口 | `n` | Edgy Select Window |

### 4.51 chezmoi.nvim

- 条目数: 1
- Part of: `[lazyvim.plugins.extras.util.chezmoi](/extras/util/chezmoi)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>sz` | Chezmoi 管理 | `n` | Chezmoi |

### 4.52 gh.nvim

- 条目数: 32
- Part of: `[lazyvim.plugins.extras.util.gh](/extras/util/gh)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>G` | 分组：GitHub 相关 | `n` | +Github |
| `<leader>Gc` | 分组：提交相关 | `n` | +Commits |
| `<leader>Gcc` | 关闭 | `n` | Close |
| `<leader>Gce` | 展开 | `n` | Expand |
| `<leader>Gco` | 打开到 | `n` | Open To |
| `<leader>Gcp` | 弹出 | `n` | Pop Out |
| `<leader>Gcz` | 折叠 | `n` | Collapse |
| `<leader>Gi` | 分组：Issue 相关 | `n` | +Issues |
| `<leader>Gio` | 打开 | `n` | Open |
| `<leader>Gip` | 预览 | `n` | Preview |
| `<leader>Gl` | 分组：Litee 相关 | `n` | +Litee |
| `<leader>Glt` | 切换面板 | `n` | Toggle Panel |
| `<leader>Gp` | 分组：Pull Request 相关 | `n` | +Pull Request |
| `<leader>Gpc` | 关闭 | `n` | Close |
| `<leader>Gpd` | 详情 | `n` | Details |
| `<leader>Gpe` | 展开 | `n` | Expand |
| `<leader>Gpo` | 打开 | `n` | Open |
| `<leader>Gpp` | 弹出 | `n` | PopOut |
| `<leader>Gpr` | 刷新 | `n` | Refresh |
| `<leader>Gpt` | 打开到 | `n` | Open To |
| `<leader>Gpz` | 折叠 | `n` | Collapse |
| `<leader>Gr` | 分组：评审相关 | `n` | +Review |
| `<leader>Grb` | 开始 | `n` | Begin |
| `<leader>Grc` | 关闭 | `n` | Close |
| `<leader>Grd` | 删除 | `n` | Delete |
| `<leader>Gre` | 展开 | `n` | Expand |
| `<leader>Grs` | 提交 | `n` | Submit |
| `<leader>Grz` | 折叠 | `n` | Collapse |
| `<leader>Gt` | 分组：线程相关 | `n` | +Threads |
| `<leader>Gtc` | 创建 | `n` | Create |
| `<leader>Gtn` | 下一个 | `n` | Next |
| `<leader>Gtt` | 切换 | `n` | Toggle |

### 4.53 mason.nvim (2)

- 条目数: 2
- Part of: `[lazyvim.plugins.extras.util.gitui](/extras/util/gitui)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>gg` | GitUi（根目录） | `n` | GitUi (Root Dir) |
| `<leader>gG` | GitUi（当前目录） | `n` | GitUi (cwd) |

### 4.54 octo.nvim

- 条目数: 16
- Part of: `[lazyvim.plugins.extras.util.octo](/extras/util/octo)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>gi` | 列出 Issues（Octo） | `n` | List Issues (Octo) |
| `<leader>gI` | 搜索 Issues（Octo） | `n` | Search Issues (Octo) |
| `<leader>gp` | 列出 PRs（Octo） | `n` | List PRs (Octo) |
| `<leader>gP` | 搜索 PRs（Octo） | `n` | Search PRs (Octo) |
| `<leader>gr` | 列出仓库（Octo） | `n` | List Repos (Octo) |
| `<leader>gS` | 搜索（Octo） | `n` | Search (Octo) |
| `<localleader>a` | 分组：指派人（Octo） | `n` | +assignee (Octo) |
| `<localleader>c` | 分组：评论/代码（Octo） | `n` | +comment/code (Octo) |
| `<localleader>g` | 分组：跳转 Issue（Octo） | `n` | +goto_issue (Octo) |
| `<localleader>i` | 分组：Issue（Octo） | `n` | +issue (Octo) |
| `<localleader>l` | 分组：标签（Octo） | `n` | +label (Octo) |
| `<localleader>p` | 分组：PR（Octo） | `n` | +pr (Octo) |
| `<localleader>pr` | 分组：变基（Octo） | `n` | +rebase (Octo) |
| `<localleader>ps` | 分组：压缩提交（Octo） | `n` | +squash (Octo) |
| `<localleader>r` | 分组：反应（Octo） | `n` | +react (Octo) |
| `<localleader>v` | 分组：评审（Octo） | `n` | +review (Octo) |

### 4.55 fzf-lua

- 条目数: 1
- Part of: `[lazyvim.plugins.extras.util.project](/extras/util/project)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>fp` | 项目列表 | `n` | Projects |

### 4.56 telescope.nvim (2)

- 条目数: 1
- Part of: `[lazyvim.plugins.extras.util.project](/extras/util/project)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>fp` | 项目列表 | `n` | Projects |

### 4.57 kulala.nvim

- 条目数: 14
- Part of: `[lazyvim.plugins.extras.util.rest](/extras/util/rest)`

| Key | Description（中文） | Mode | Description（原文） |
|---|---|---|---|
| `<leader>R` | 分组：REST 相关 | `n` | +Rest |
| `<leader>Rb` | 打开草稿区 | `n` | Open scratchpad |
| `<leader>Rc` | 复制为 cURL | `n` | Copy as cURL |
| `<leader>RC` | 从 curl 粘贴 | `n` | Paste from curl |
| `<leader>Re` | 设置环境 | `n` | Set environment |
| `<leader>Rg` | 下载 GraphQL schema | `n` | Download GraphQL schema |
| `<leader>Ri` | 检查当前请求 | `n` | Inspect current request |
| `<leader>Rn` | 跳到下一个请求 | `n` | Jump to next request |
| `<leader>Rp` | 跳到上一个请求 | `n` | Jump to previous request |
| `<leader>Rq` | 关闭窗口 | `n` | Close window |
| `<leader>Rr` | 重放上一次请求 | `n` | Replay the last request |
| `<leader>Rs` | 发送请求 | `n` | Send the request |
| `<leader>RS` | 显示统计 | `n` | Show stats |
| `<leader>Rt` | 切换 headers/body | `n` | Toggle headers/body |
