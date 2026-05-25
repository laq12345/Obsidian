---
date: 2026-05-25
lang: Linux
tags:
  - 工具
  - 编程
  - linux
  - fd
---

# fd 使用指南

> fd 是一个简单、快速、用户友好的 `find` 替代工具。默认使用正则表达式搜索，支持智能大小写、忽略隐藏文件/`.gitignore`、彩色输出、并行命令执行。

## 一、基本搜索

```bash
# 搜索包含 "netfl" 的文件/目录（默认递归当前目录，正则匹配）
fd netfl

# 指定搜索目录
fd passwd /etc

# 列出所有文件（递归）
fd .
```

## 二、正则表达式搜索

fd 默认使用正则表达式，语法见 [regex 文档](https://docs.rs/regex/latest/regex/#syntax)。

```bash
# 搜索以 x 开头、rc 结尾的文件
fd '^x.*rc$' /etc
```

> **注意**：特殊字符（`[]^$`等）也是 shell 特殊字符，建议用单引号包裹正则。如果 pattern 以 `-` 开头，需加 `--` 或使用字符类写法。

## 三、过滤选项

### 按扩展名 (`-e`)

```bash
fd -e md              # 所有 .md 文件
fd -e rs mod          # 扩展名为 .rs 且匹配 "mod"
```

### 按文件类型 (`-t`)

```bash
fd -t f               # 普通文件
fd -t d               # 目录
fd -t l               # 符号链接
fd -t x               # 可执行文件
fd -t e               # 空文件
```

### 按文件名精确匹配 (`-g` / `--glob`)

```bash
fd -g 'libc.so' /usr                    # glob 模式精确匹配
fd -g 'test_*.py'                       # glob 通配符
```

### 按大小 (`-S`)

```bash
fd -S +100k          # 大于 100KB
fd -S -1M            # 小于 1MB
```

### 按修改时间

```bash
fd --changed-within 1day               # 1天内修改
fd --changed-before '2025-01-01'       # 2025年之前修改
```

### 按所有者 (`-o`)

```bash
fd -o root           # 所有者为 root
fd -o :wheel         # 所属组为 wheel
fd -o user:group     # 指定用户和组
```

### 匹配完整路径 (`-p` / `--full-path`)

```bash
fd -p '.*/lesson-\d+/[a-z]+\.(jpg|png)'    # 匹配整个路径
```

## 四、排序与深度控制

```bash
fd -d 3 pattern      # 最大搜索深度 3 层
```

## 五、隐藏与忽略文件

```bash
fd -H                 # 搜索隐藏文件和目录
fd -I                 # 不遵守 .gitignore / .fdignore
fd -u                 # = -HI，无限制搜索（显示所有）
fd -E '.git'          # 排除匹配 .git 的路径
fd -E '*.bak'        # 排除 .bak 文件
fd -E /mnt/external   # 排除挂载目录
```

全局忽略规则可写到 `~/.config/fd/ignore` 或 `.fdignore` 文件中（格式同 `.gitignore`）。

## 六、输出格式

```bash
fd -a                 # 显示绝对路径
fd -l                 # 详细列表（等价于 -X ls -lhd），含权限、大小、时间
fd -0                 # 以 NULL 字符分隔结果（配合 xargs -0 使用）
fd --color always     # 强制彩色输出
```

## 七、命令执行

### `-x` / `--exec` — 逐个执行（并行）

```bash
fd -e zip -x unzip                    # 解压所有 zip 文件
fd -e h -e cpp -x clang-format -i    # 格式化所有 C/C++ 文件
fd -tf -x md5sum > checksums.txt     # 并行计算所有文件的 MD5

fd -t f -e jpg -x convert {} {.}.png  # 批量转换 jpg 到 png
```

> `{}` 是结果占位符，fd 自动在末尾追加。用 `-j 1` 或 `--threads=1` 可改为串行执行。

### `-X` / `--exec-batch` — 所有结果作为参数一次执行

```bash
fd -g 'test_*.py' -X vim              # 一次打开所有匹配文件
fd -e cpp -e hpp -X rg 'std::cout'   # 在 C++ 文件中批量搜索
```

### 占位符语法

| 占位符 | 含义 | 示例 |
|--------|------|------|
| `{}` | 完整路径 | `docs/images/party.jpg` |
| `{.}` | 不含扩展名 | `docs/images/party` |
| `{/}` | 文件名 | `party.jpg` |
| `{//}` | 父目录 | `docs/images` |
| `{/.}` | 文件名不含扩展名 | `party` |

### 终止命令模板

```bash
fd -x echo \; pattern path     # \; 之后是 fd 参数，不传给 echo
# 更清晰的写法（推荐）：
fd pattern path -x echo
```

## 八、删除文件

```bash
# 删除所有 .DS_Store 文件（先预览再删）
fd -H '^\.DS_Store$' -tf
fd -H '^\.DS_Store$' -tf -X rm
fd -H '^\.DS_Store$' -tf -X rm -i    # 交互式确认
```

## 九、与其他工具配合

### fzf（模糊搜索）

```bash
export FZF_DEFAULT_COMMAND='fd --type file --follow --hidden --exclude .git'
export FZF_DEFAULT_COMMAND="fd --type file --color=always"
export FZF_DEFAULT_OPTS="--ansi"
```

### xargs

```bash
fd -0 -e rs | xargs -0 wc -l     # 统计所有 .rs 文件行数
```

### tree（树形输出）

```bash
fd | tree --fromfile             # 以树形展示搜索结果
fd -e rs | tree --fromfile       # 只看 .rs 文件
# 可设置别名：
alias as-tree='tree --fromfile'
```

### ripgrep（内容搜索）

```bash
fd -e cpp -e hpp -X rg 'std::cout'
```

### rofi（图形菜单）

```bash
fd --type f -e pdf . ~ | rofi -dmenu -i -p FILES -multi-select | xargs -I {} xdg-open {}
```

### emacs

```elisp
(setq ffip-use-rust-fd t)   ;; 配合 find-file-in-project 使用
```

## 十、快速参考表

| 选项 | 简写 | 说明 |
|------|------|------|
| `--hidden` | `-H` | 搜索隐藏文件 |
| `--no-ignore` | `-I` | 不忽略 .gitignore |
| `--unrestricted` | `-u` | = `-HI` |
| `--case-sensitive` | `-s` | 强制区分大小写 |
| `--ignore-case` | `-i` | 强制忽略大小写 |
| `--glob` | `-g` | 使用 glob 模式 |
| `--absolute-path` | `-a` | 绝对路径输出 |
| `--list-details` | `-l` | 详细列表 |
| `--follow` | `-L` | 跟踪符号链接 |
| `--full-path` | `-p` | 匹配完整路径 |
| `--max-depth` | `-d` | 最大搜索深度 |
| `--exclude` | `-E` | 排除 glob 匹配项 |
| `--type` | `-t` | 按类型过滤 |
| `--extension` | `-e` | 按扩展名过滤 |
| `--size` | `-S` | 按文件大小过滤 |
| `--exec` | `-x` | 逐个执行命令 |
| `--exec-batch` | `-X` | 批量执行命令 |
| `--threads` | `-j` | 并行线程数 |

## 十一、常见问题

1. **找不到文件？** 默认忽略隐藏文件和 gitignore → 加 `-u`
2. **正则不生效？** 用单引号包裹，特殊字符需转义
3. **彩色输出不生效？** 确保 `LS_COLORS` 环境变量已设置
4. **alias/shell 函数不能用于 `-x`？** zsh 用 `alias -g`，bash 用 `export -f` + `bash -c`
