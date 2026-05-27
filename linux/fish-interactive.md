---
date: 2026-05-27
lang: Linux
tags:
  - 编程
  - 工具
  - linux
  - shell
  - terminal
  - fish
---

# Fish 交互使用指南

> 基于 [fish 官方文档 — Interactive Use](https://fishshell.com/docs/current/interactive.html)

---

## 帮助系统

```fish
help                 # 浏览器打开主页
help syntax          # 查看特定主题
help set             # 查看内置命令帮助
man set              # 终端内查看手册
set -h               # 内置命令的 -h 参数
help tutorial        # 查看教程
```

---

## 自动建议

输入时灰色文字为建议，基于历史记录、补全和有效路径。

| 操作 | 快捷键 |
|---|---|
| 接受建议 | → 或 Ctrl+F |
| 接受第一个词 | Alt+→ 或 Alt+F |
| 忽略 | 继续输入 |

```fish
# 关闭自动建议
set -g fish_autosuggestion_enabled 0
```

---

## Tab 补全

- 按 Tab 完成命令/参数/路径
- 多个候选项时打开分页器（pager）
- 分页器导航：方向键、PageUp/PageDown、Tab/Shift+Tab
- 分页器搜索：Ctrl+S（vi 模式中按 /）
- 补全脚本放在 `~/.config/fish/completions/` 自动加载

---

## 语法高亮

默认用红色标记错误：命令不存在、文件不存在、重定向错误、括号不匹配等。

```fish
fish_config theme choose none       # 关闭
fish_config theme choose default    # 恢复默认
fish_config theme show              # 预览所有主题
fish_config                         # 浏览器界面选择
```

### 语法高亮颜色变量

```fish
set fish_color_error red --bold     # 错误：红色加粗
set fish_color_command blue         # 命令：蓝色
set fish_color_param cyan           # 参数：青色
set fish_color_comment brblack      # 注释：灰色
set fish_color_autosuggestion brblack  # 自动建议：深灰
```

| 变量 | 含义 |
|---|---|
| `fish_color_normal` | 默认颜色 |
| `fish_color_command` | 命令名 |
| `fish_color_param` | 普通参数 |
| `fish_color_keyword` | 关键字（如 if），回退到 command 颜色 |
| `fish_color_quote` | 引号内文本 |
| `fish_color_redirection` | 重定向符号 |
| `fish_color_end` | 分隔符 `;` `&` |
| `fish_color_error` | 语法错误 |
| `fish_color_comment` | 注释 |
| `fish_color_operator` | 参数展开操作符 `*` `~` |
| `fish_color_escape` | 转义字符 `\n` `\x70` |
| `fish_color_autosuggestion` | 自动建议 |
| `fish_color_selection` | vi 模式下选中的文本 |
| `fish_color_search_match` | 历史搜索匹配项（仅背景） |
| `fish_color_valid_path` | 有效文件路径 |
| `fish_color_option` | 选项（以 `-` 开头），回退到 param 颜色 |

### 分页器颜色变量

```fish
set fish_pager_color_prefix black
set fish_pager_color_completion black
set fish_pager_color_description brblack
set fish_pager_color_background --background=white
set fish_pager_color_selected_background --background=brblue
```

| 变量 | 含义 |
|---|---|
| `fish_pager_color_progress` | 左下角进度条 |
| `fish_pager_color_background` | 行背景色 |
| `fish_pager_color_prefix` | 补全前缀 |
| `fish_pager_color_completion` | 补全内容 |
| `fish_pager_color_description` | 补全描述 |
| `fish_pager_color_selected_background` | 选中项背景 |
| `fish_pager_color_selected_prefix` | 选中项前缀 |
| `fish_pager_color_selected_completion` | 选中项补全 |
| `fish_pager_color_selected_description` | 选中项描述 |
| `fish_pager_color_secondary_*` | 偶数行样式（未设置则用普通样式） |

---

## 缩写（Abbreviations）

比别名更强大的功能：输入缩写后在命令行展开为完整命令，可看到并编辑最终命令，且历史记录保存的是展开后的完整命令。

```fish
abbr --add gco git checkout

# 正则缩写
function multicd
    echo cd (string repeat -n (math (string length -- $argv[1]) - 1) ../)
end
abbr --add dotdot --regex '^\.\.+$' --function multicd
# ..  → cd ../
# ... → cd ../../
```

---

## 提示符

fish 通过函数定义提示符（不是 `PS1`）：

```fish
# 左侧提示符
function fish_prompt
    echo (pwd) '> '
end

# 右侧提示符
function fish_right_prompt
    date "+%H:%M"
end

funcsave fish_prompt     # 保存到文件
```

内置提示符选择：
```fish
fish_config prompt show       # 预览
fish_config prompt choose disco  # 试用
fish_config prompt save       # 保存
fish_config                   # 网页界面
```

---

## 问候语

```fish
# 禁用
set -U fish_greeting

# 自定义
set -g fish_greeting 'Hey, stranger!'

# 随机问候
function fish_greeting
    random choice "Hello!" "Hi" "G'day" "Howdy"
end
```

---

## 命令行编辑器

### 通用快捷键（Emacs 和 Vi 模式共享）

| 快捷键 | 功能 |
|---|---|
| Tab | 补全 |
| Shift+Tab | 补全并打开搜索 |
| Enter | 执行（命令不完整时插入换行） |
| Alt+Enter | 在光标处插入换行 |
| Alt+→ / Alt+← | 移动一个参数（或一个词），空行时遍历目录历史 |
| Ctrl+→ / Ctrl+← | 移动一个词 |
| ↑ / ↓ | 搜索历史 |
| Alt+↑ / Alt+↓ | 按当前光标所在词搜索历史 |
| Ctrl+C | 中断 |
| Ctrl+D | 删除右侧字符；空行时退出 fish |
| Ctrl+U | 删除从行首到光标 |
| Ctrl+L | 清屏（滚动到 scrollback） |
| Ctrl+W | 删除前一个路径组件 |
| Ctrl+X | 复制到剪贴板 |
| Ctrl+V | 从剪贴板粘贴 |
| Alt+D | 删除下一个词 |
| Alt+H / F1 | 显示当前命令的 man 手册 |
| Alt+L | 列出当前目录内容 |
| Alt+E | 在外部编辑器编辑当前命令行 |
| Alt+S | 在命令行前加 `sudo` |
| Ctrl+Space | 插入空格但不展开缩写 |

### Emacs 模式

```fish
fish_default_key_bindings  # 启用（默认）
```

| 快捷键 | 功能 |
|---|---|
| Ctrl+A | 行首 |
| Ctrl+E | 行尾（或接受建议） |
| Ctrl+K | 删除到行尾 |
| Ctrl+R | 打开历史搜索分页器 |
| Ctrl+Backspace | 删除前一个词 |
| Ctrl+T | 交换最后两个字符 |
| Alt+T | 交换最后两个词 |
| Ctrl+Z | 撤销 |
| Alt+/ | 重做 |
| Alt+< | 到命令开头 |
| Alt+> | 到命令末尾 |

### Vi 模式

```fish
fish_vi_key_bindings     # 启用
```

初始为插入模式，按 Esc 进入命令模式。

#### 命令模式

| 键 | 功能 |
|---|---|
| h/l | 左右移动光标 |
| k/j | 搜索上/下一条历史 |
| i | 在光标处进入插入模式 |
| I | 在行首进入插入模式 |
| a | 在光标后进入插入模式 |
| A | 在行尾进入插入模式 |
| o/O | 在下一行/上一行进入插入模式 |
| v | 进入可视模式 |
| dd | 删除整行 |
| D | 删除到行尾 |
| p | 粘贴 |
| u / Ctrl+R | 撤销 / 重做 |
| ¬ / ˚ | 按词搜索历史 |
| / | 打开历史搜索分页器 |

#### 可视模式

| 键 | 功能 |
|---|---|
| h/l/k/j | 移动光标扩展选区 |
| b/w | 按词扩展选区 |
| d/x | 删除选区 |
| y | 复制选区 |
| c/s | 删除选区并进入插入模式 |

#### 光标样式

```fish
set fish_cursor_default block
set fish_cursor_insert line
set fish_cursor_replace_one underscore
set fish_cursor_external line
set fish_cursor_visual block
```

### 自定义快捷键

```fish
bind ctrl-c cancel-commandline
bind --mode insert \cg 'echo "hi"'

# 查找按键名称
fish_key_reader

# 删除自定义绑定
bind --erase ctrl-c

# Escape 延迟（毫秒）
set -g fish_escape_delay_ms 100
```

---

## 复制粘贴（Kill Ring）

fish 使用 Emacs 风格的 kill ring：

| 快捷键 | 功能 |
|---|---|
| Ctrl+K | 剪切到行尾 |
| Ctrl+Y | 粘贴（yank） |
| Alt+Y | 粘贴后切换到上一次剪切 |
| Ctrl+X / Ctrl+V | 系统剪贴板复制/粘贴 |

支持 xsel、xclip、wl-copy/wl-paste、pbcopy/pbpaste。

---

## 历史搜索

- **↑/↓**：搜索完整命令行
- **Alt+↑/Alt+↓**：按光标所在词搜索
- **Ctrl+R**：打开分页器搜索，再按搜索更旧条目，Ctrl+S 搜索更新条目
- 搜索不区分大小写（除非含大写字母）
- 命令前加空格 → 不写入历史文件
- 历史文件：`~/.local/share/fish/fish_history`

```fish
# 切换历史会话
set -g fish_history new_session
```

---

## 多行编辑

```fish
# 方法 1：块未闭合时按 Enter
if true
    echo hello
end

# 方法 2：Alt+Enter 在光标处插入换行

# 方法 3：反斜杠转义换行
echo hello \
    world
```

---

## 隐私模式

```fish
# 启动时
fish --private
fish -P

# 检测
if test -n "$fish_private_mode"
    echo "隐私模式"
end
```

---

## 目录导航

### 目录历史

```fish
dirh      # 列出历史
cdh       # 交互式选择
prevd     # 后退（Alt+←）
nextd     # 前进（Alt+→）
```

### 目录栈

```fish
dirs              # 显示栈
pushd /tmp        # 压入并跳转
popd              # 弹出并跳转
```
