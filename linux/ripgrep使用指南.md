---
date: 2026-05-25
lang: Linux
tags:
  - 编程
  - 工具
  - linux
  - riggrep
---

# ripgrep (rg) 使用指南

> ripgrep 是一个面向行的搜索工具，递归搜索目录，默认遵守 `.gitignore`，速度极快。

## 一、基本搜索

```bash
rg fast README.md          # 搜索单文件中含 "fast" 的行
rg 'fn write\(' src        # 递归搜索 src 目录（正则模式）
rg pattern                 # 不指定路径时，默认递归搜索当前目录
rg pattern ./              # 等价于上一条
```

## 二、正则表达式

ripgrep 默认使用正则表达式（语法同 [Rust regex](https://docs.rs/regex)）：

```bash
rg 'fast\w+'               # fast 后跟至少一个单词字符（如 faster）
rg 'fast\w*'               # fast 后跟零或多个单词字符
rg '\d{3}-\d{4}'           # 匹配 123-4567 格式
rg -F 'fn write('          # -F：字面量模式，禁用正则
```

> shell 特殊字符（`()` `[]` `$` 等）要用单引号包裹正则表达式。

## 三、自动过滤（默认行为）

ripgrep 默认**不搜索**以下内容：

| 过滤项 | 说明 | 禁用选项 |
|--------|------|----------|
| `.gitignore` 规则 | 包括全局和仓库级 | `--no-ignore` |
| 隐藏文件/目录 | `.` 开头 | `--hidden` / `-.` |
| 二进制文件 | 含 NUL 字节 | `--text` / `-a` |
| 符号链接 | 不跟踪 | `--follow` / `-L` |

### 便捷组合 `-u`

```bash
rg -u pattern    #  禁用 .gitignore
rg -uu pattern   #  + 搜索隐藏文件
rg -uuu pattern  #  + 搜索二进制文件（等于无限制）
```

### `.ignore` / `.rgignore` 文件

优先级：`.rgignore` > `.ignore` > `.gitignore`

```bash
# 在 .gitignore 排除了 log/ 的情况下，用 .ignore 白名单回来：
# .ignore 内容：
!log/
```

## 四、手动过滤

### glob 过滤 (`-g`)

```bash
rg clap -g '*.toml'        # 只搜 .toml 文件
rg clap -g '!*.toml'       # 排除 .toml 文件
rg pattern -g '*.{rs,toml}'  # 搜 .rs 和 .toml
```

> `-g '!*.toml' -g '*.toml'` → 只搜 .toml（后覆盖前）  
> `-g '*.toml' -g '!*.toml'` → 什么都不搜（黑名单优先）

### 文件类型过滤 (`-t` / `-T`)

```bash
rg 'fn run' --type rust     # 只搜 Rust 文件
rg 'fn run' -trust          # 等价简写
rg clap --type-not rust     # 排除 Rust 文件
rg clap -Trust              # 等价简写
```

查看所有内置类型：

```bash
rg --type-list
```

自定义类型：

```bash
rg --type-add 'web:*.{html,css,js}' -tweb title    # 单次有效
```

持久化：在配置文件或别名中加 `--type-add 'web:*.{html,css,js}'`。

### 特殊类型 `all`

```bash
rg --type all pattern      # 搜所有有扩展名的已知类型文件
rg --type-not all pattern  # 只搜无扩展名/未知类型文件
```

## 五、替换 (`-r` / `--replace`)

**注意**：ripgrep 只替换输出，**不会修改原文件**。

```bash
rg fast README.md -r FAST              # 将 fast 替换为 FAST
rg fast README.md -o -r FAST           # -o：只输出匹配部分
rg '^.*fast.*$' README.md -r FAST      # 替换整行
```

### 捕获组

```bash
rg 'fast\s+(\w+)' README.md -r 'fast-$1'           # $1 = 第1个捕获组
rg 'fast\s+(?P<word>\w+)' README.md -r 'fast-$word' # 命名捕获组
```

## 六、配置文件

设置 `RIPGREP_CONFIG_PATH` 环境变量指向配置文件：

```bash
export RIPGREP_CONFIG_PATH=~/.ripgreprc
```

配置格式（每行一个 flag，`#` 开头为注释）：

```
# ~/.ripgreprc 示例
--max-columns=150
--max-columns-preview
--smart-case
--hidden
--type-add
web:*.{html,css,js}
--glob=!.git/*
--colors=line:none
--colors=line:style:bold
```

> 命令行参数会**覆盖**配置文件中的同名设置。

## 七、编码与二进制

### 编码 (`-E` / `--encoding`)

- 默认 `--encoding auto`：假定 ASCII 兼容编码，自动检测 UTF-16 BOM 并转码
- `-E utf-8`：强制按指定编码搜索
- `-E none`：完全禁用编码处理，逐字节搜索

```bash
rg 'Шерлок' some-utf16-file          # 自动处理 UTF-16
rg -E none pattern binary-file        # 逐字节搜索
```

### 禁用 Unicode（正则内）

```bash
rg '(?-u:.)'        # . 匹配任意字节（而非 Unicode 字符）
rg '\w(?-u:\w)\w'   # Unicode\w + ASCII\w + Unicode\w
```

### 二进制文件三种模式

| 模式 | 行为 | 启用方式 |
|------|------|----------|
| 默认 | 检测到 NUL 即停止搜索该文件 | 默认（仅递归搜索时） |
| 二进制模式 | 遇到匹配才停止 | `--binary` |
| 文本模式 | 不检测，全部当文本搜 | `-a` / `--text` |

## 八、预处理器 (`--pre`)

用外部命令预处理文件后再搜索：

```bash
# 搜索 PDF
cat > preprocess <<'EOF'
#!/bin/sh
case "$1" in
  *.pdf) [ -s "$1" ] && exec pdftotext - - ;;
  *)     exec cat ;;
esac
EOF

chmod +x preprocess
rg --pre ./preprocess '关键词' *.pdf
```

限制预处理器只对特定文件生效（避免性能损失）：

```bash
rg --pre ./preprocess --pre-glob '*.pdf' '关键词'
```

## 九、常用选项速查

| 选项 | 简写 | 说明 |
|------|------|------|
| `--ignore-case` | `-i` | 忽略大小写 |
| `--smart-case` | `-S` | 智能大小写（有大写则区分） |
| `--fixed-strings` | `-F` | 字面量模式（禁用正则） |
| `--word-regexp` | `-w` | 整词匹配 |
| `--count` | `-c` | 只显示匹配行数 |
| `--files` | | 列出会被搜索的文件（不实际搜索） |
| `--text` | `-a` | 搜索二进制文件 |
| `--multiline` | `-U` | 允许跨行匹配 |
| `--search-zip` | `-z` | 搜索压缩文件 |
| `--context` | `-C` | 显示匹配行前后 N 行上下文 |
| `--max-columns` | `-M` | 限制输出行最大长度 |
| `--sort path` | | 按文件名排序输出（会变慢） |
| `--hidden` | `-.` | 搜索隐藏文件 |
| `--no-ignore` | | 不遵守 gitignore |
| `--follow` | `-L` | 跟踪符号链接 |
| `--only-matching` | `-o` | 只输出匹配部分 |
| `--no-mmap` | | 禁用内存映射（二进制检测更一致） |
| `--no-config` | | 不读取配置文件 |
| `--debug` | | 调试输出（排查为何某文件被忽略） |

## 十、常见问题

1. **什么都没搜到？** → `rg --debug pattern` 查看过滤原因，或者加 `-uuu` 无限制搜索
2. **想搜二进制/隐藏文件？** → `-u` 逐级放开，`-uuu` 全部放开
3. **正则不生效？** → 用单引号包裹，或改用 `-F` 字面量模式
4. **配置文件在哪里？** → 需手动设置 `RIPGREP_CONFIG_PATH` 环境变量，无默认路径
5. **别名/函数不能用于 `-x`？** → ripgrep 本身没有 `--exec`，配合 `xargs` 使用：`rg -l pattern | xargs command`
