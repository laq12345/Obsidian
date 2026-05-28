---
lang: Linux
date: 2026-05-28
tags:
  - 编程
  - 工具
  - fish
  - fzf
  - git
  - linux
  - 快捷键
---
# fzf / fzf.fish 快捷键速查

## 来源说明

本文件整合了两套快捷键：

- **标准 fzf**：由 `fzf --fish | source` 提供
- **fzf.fish 插件**：由 `fisher install PatrickF1/fzf.fish` 提供，功能更丰富

> 两套快捷键可以共存。

---

## 快捷键总表

| 快捷键          | 来源       | 功能                                 |
| ------------ | -------- | ---------------------------------- |
| `Ctrl+T`     | 标准 fzf   | 搜索文件，选中插入路径（以光标前一个合法目录为根）          |
| `Alt+C`      | 标准 fzf   | 搜索目录，选中直接 cd 进入                    |
| `Shift+Tab`  | 标准 fzf   | 触发 fzf 模糊补全（替代原生 Tab 补全的翻页）        |
| `Ctrl+R`     | fzf.fish | 搜索 Fish 命令历史，含预览和语法高亮              |
| `Ctrl+Alt+F` | fzf.fish | Search Directory：fd 递归搜文件，bat 预览   |
| `Ctrl+Alt+L` | fzf.fish | Search Git Log：浏览 commit，插入 hash   |
| `Ctrl+Alt+S` | fzf.fish | Search Git Status：浏览变更文件，插入路径      |
| `Ctrl+Alt+P` | fzf.fish | Search Processes：列出进程，插入 PID       |
| `Ctrl+V`     | fzf.fish | Search Variables：列出 shell 变量，插入变量名 |

> 注：fzf.fish 的 `Ctrl+R` 会**覆盖**标准 fzf 的历史搜索。如果你两套都 source 且 fzf.fish 在后，最终生效的是 fzf.fish 版本。

---

## `Ctrl+R` / Search History 内的操作

这些绑定在 fzf.fish 的历史搜索界面内有效：

| 快捷键 | 功能 |
|--------|------|
| `Alt+T` | 切换时间戳显示模式（时间 / 日期+时间 / 无） |
| `Alt+Enter` | 用 `fish_indent` 格式化后插入 |
| `Shift+Delete` | 从历史记录中删除选中条目 |

---

## `Ctrl+T` 的 Fish 专用行为

与其他 Shell 不同，Fish 版 `Ctrl+T` 会自动取**命令行最后一个合法目录**作为搜索根目录：

```fish
# 输入 ls /var/ 然后按 Ctrl+T → 递归搜索 /var/ 下的文件
# 最后一个 token 不是目录时，默认搜索当前目录
```

---

## 安装前提

| 依赖 | 最低版本 | 用途 |
|------|---------|------|
| fish | 4.0.0 | shell |
| fzf | 0.33.0 | 模糊搜索核心 |
| fd | 8.5.0 | Search Directory 用 (替代 find) |
| bat | 0.16.0 | Search Directory 预览用 (替代 cat) |

安装：

```fish
fisher install PatrickF1/fzf.fish
```

> 注意：不兼容其他 fzf 插件 (如 jethrokuan/fzf)，需先卸载。

---

## 各命令详情

### Search Directory (`Ctrl+Alt+F`)

- **输入**：递归列出当前目录非隐藏文件 (通过 `fd`)
- **输出**：选中文件的相对路径
- **预览**：文件用 `bat` 语法高亮，目录用 `ls` 列出内容
- 目录会带末尾 `/` 插入，选单个目录可直接回车 cd 进去
- 光标在有 `/` 的路径上时，自动搜索该目录

### Search Git Log (`Ctrl+Alt+L`)

- **输入**：当前仓库格式化后的 `git log`
- **输出**：选中的 commit hash
- **预览**：commit message 和 diff

### Search Git Status (`Ctrl+Alt+S`)

- **输入**：当前仓库 `git status`
- **输出**：选中文件的相对路径
- **预览**：文件的 git diff

### Search History (`Ctrl+R`)

- **输入**：Fish 命令历史
- **输出**：选中的历史命令
- **预览**：完整命令 (Fish 语法高亮)

### Search Processes (`Ctrl+Alt+P`)

- **输入**：所有运行中进程的 PID 和命令
- **输出**：选中的 PID
- **预览**：进程 CPU、内存、启动时间等信息

### Search Variables (`Ctrl+V`)

- **输入**：当前作用域所有 shell 变量
- **输出**：选中的变量名
- **预览**：变量的作用域信息和值
- `$history` 因技术原因被排除

### 通用交互方式

- `Tab` 多选
- 光标所在的单词会作为 fzf 的默认查询词，并被选中的结果替换

---

## 自定义快捷键

使用 `fzf_configure_bindings` 可在 `config.fish` 中自定义 fzf.fish 快捷键：

```fish
fzf_configure_bindings --help
```

禁用标准 fzf 的快捷键可通过环境变量：

```fish
# 禁用标准 fzf 的 Ctrl+R 和 Alt+C（因为 fzf.fish 已提供替代）
fzf --fish | FZF_CTRL_R_COMMAND= FZF_ALT_C_COMMAND= source
```

---

## 常用配置变量

### 针对具体命令的 fzf 选项

| 命令 | 变量 |
|------|------|
| Search Directory | `fzf_directory_opts` |
| Search Git Log | `fzf_git_log_opts` |
| Search Git Status | `fzf_git_status_opts` |
| Search History | `fzf_history_opts` |
| Search Processes | `fzf_processes_opts` |
| Search Variables | `fzf_variables_opts` |

### 其他配置

| 变量 | 说明 | 示例 |
|------|------|------|
| `fzf_fd_opts` | `fd` 参数 | `--hidden --max-depth 5` |
| `fzf_preview_dir_cmd` | 目录预览命令 | `eza --all --color=always` |
| `fzf_preview_file_cmd` | 文件预览命令 | `cat -n` |
| `fzf_diff_highlighter` | diff 高亮工具 | `delta --paging=never --width=20` |
| `fzf_git_log_format` | git log 格式 | `"%H %s"` |
| `fzf_history_time_format` | 历史时间格式 | `%d-%m-%y` |

### config.fish 示例

```fish
# 搜索隐藏文件
set fzf_fd_opts --hidden

# delta 高亮 diff 预览
set fzf_diff_highlighter "delta --paging=never --width=20"

# eza 预览目录
set fzf_preview_dir_cmd "eza --all --color=always"
```

---

## 扩展阅读

- [fzf.fish 项目主页](https://github.com/PatrickF1/fzf.fish)
- [fzf.fish Wiki](https://github.com/PatrickF1/fzf.fish/wiki)
- [fzf.fish Cookbook](https://github.com/PatrickF1/fzf.fish/wiki/Cookbook)
- [fzf 官方文档](https://github.com/junegunn/fzf)
