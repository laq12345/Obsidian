---
date: 2026-04-26
lang: Linux
tags:
  - fd
  - linux
  - 工具
---

# fd 命令行工具用法总结（Markdown 笔记）

## 1. fd 是什么

`fd` 是一个用于文件查找的命令行工具，可视作 `find` 的现代化替代方案之一。

核心特点：

- 语法更简洁，默认行为更符合日常使用习惯。
- 搜索速度快（通常比 `find` 体感更快）。
- 默认彩色输出，结果可读性高。
- 默认启用正则匹配（Rust regex），也支持 glob 和固定字符串。
- 默认会忽略：隐藏文件、`.gitignore` 规则匹配的文件、`.git` 目录。

常见别名：

- 有些发行版中命令叫 `fdfind`（如部分 Debian/Ubuntu 版本）。

---

## 2. 安装

按系统选择一种方式即可。

### Ubuntu / Debian

```bash
sudo apt update
sudo apt install fd-find
```

如果命令名是 `fdfind`，可临时用：

```bash
fdfind PATTERN
```

也可做别名：

```bash
echo "alias fd=fdfind" >> ~/.zshrc
source ~/.zshrc
```

### Fedora

```bash
sudo dnf install fd-find
```

### Arch Linux

```bash
sudo pacman -S fd
```

### macOS (Homebrew)

```bash
brew install fd
```

### Cargo

```bash
cargo install fd-find
```

---

## 3. 基本语法

```bash
fd [OPTIONS] [PATTERN] [PATH...]
```

- `PATTERN`：匹配模式（默认是正则）。
- `PATH`：从哪些目录开始查找，不写则默认当前目录。

最常见写法：

```bash
fd 关键字
fd 关键字 指定目录
```

示例：

```bash
fd config
fd '\.md$' docs/
fd main src/ include/
```

---

## 4. 匹配模式与大小写

### 4.1 默认正则匹配

```bash
fd '^test_.*\.py$'
```

### 4.2 固定字符串匹配（literal）

避免正则转义，按字面匹配：

```bash
fd -F 'a+b.txt'
```

### 4.3 glob 匹配

```bash
fd -g '*.toml'
fd -g '**/*.md'
```

### 4.4 大小写控制

- 默认：智能大小写（smart case）
  - 模式全小写时：不区分大小写
  - 模式含大写时：区分大小写

强制不区分大小写：

```bash
fd -i readme
```

强制区分大小写：

```bash
fd -s Readme
```

---

## 5. 结果过滤（最常用）

### 5.1 按类型过滤

```bash
fd -t f pattern      # 仅文件
fd -t d pattern      # 仅目录
fd -t l pattern      # 仅符号链接
fd -t x pattern      # 仅可执行文件
fd -t e pattern      # 仅空文件
fd -t s pattern      # 仅 socket
fd -t p pattern      # 仅管道
```

类型可组合：

```bash
fd -t fd pattern     # 文件 + 目录
```

### 5.2 按扩展名过滤

```bash
fd -e rs
fd -e js -e ts
```

说明：`-e` 不需要写点号，`-e rs` 即 `.rs`。

### 5.3 排除路径或名称

```bash
fd pattern -E node_modules -E dist
fd . -E '*.min.js'
```

### 5.4 限制搜索深度

```bash
fd pattern --max-depth 2
fd pattern --min-depth 2
```

### 5.5 搜索隐藏文件 / 忽略忽略规则

```bash
fd pattern -H        # 包含隐藏文件
fd pattern -I        # 不遵循 .gitignore/.ignore
fd pattern -u        # 等价于 -H -I（更“无过滤”）
```

---

## 6. 输出与路径行为

### 6.1 仅输出文件名（不带路径）

```bash
fd pattern -a        # 绝对路径
fd pattern -l        # 长格式（显示更多信息，视版本支持）
```

常见路径选项：

```bash
fd pattern --strip-cwd-prefix
```

用于移除 `./` 前缀，便于后续脚本处理。

### 6.2 NUL 分隔输出（脚本安全）

处理带空格/换行文件名时非常重要：

```bash
fd pattern -0
```

配合 `xargs -0`：

```bash
fd -e log -0 | xargs -0 rm -f
```

---

## 7. 与其他命令联动（高频）

`fd` 最强大的地方之一，是和 `rg`、`xargs`、`bat`、`sed` 等组合。

### 7.1 批量执行命令：`-x`

对每个匹配结果执行一次命令：

```bash
fd -e jpg -x convert {} {.}.png
```

占位符：

- `{}`：完整路径
- `{/}`：文件名
- `{.}`：去掉最后一个扩展名后的完整路径
- `{/.}`：去掉扩展名的文件名
- `{//}`：父目录

### 7.2 一次性传入所有结果：`-X`

```bash
fd -e rs -X wc -l
```

区别：

- `-x`：每个文件分别执行命令
- `-X`：将所有文件一次传给命令

### 7.3 和 ripgrep 联动

在所有 Python 文件中搜某个函数：

```bash
fd -e py -X rg 'def\s+handle_request'
```

### 7.4 预览文件内容

```bash
fd -e md -X bat --style=plain
```

---

## 8. 典型实战示例

### 8.1 找项目中所有测试目录

```bash
fd -t d '^test(s)?$'
```

### 8.2 找 7 天内修改过的日志（配合 find）

`fd` 负责筛路径，`find/stat` 负责时间条件：

```bash
fd -e log -X find -L -type f -mtime -7
```

### 8.3 批量删除 Python 缓存目录

```bash
fd -t d '^__pycache__$' -x rm -rf {}
```

### 8.4 查找并格式化所有 Rust 文件

```bash
fd -e rs -X rustfmt
```

### 8.5 只在指定目录集搜索

```bash
fd config src/ tests/ scripts/
```

---

## 9. fd 与 find 的对比

| 维度 | fd | find |
|---|---|---|
| 易用性 | 简洁，参数少 | 功能强但语法偏复杂 |
| 默认忽略规则 | 自动遵循 ignore + 隐藏过滤 | 默认不过滤 |
| 速度体感 | 通常更快 | 依赖写法和场景 |
| 表达复杂条件 | 中等 | 非常强（时间、权限、逻辑表达等） |
| 脚本兼容历史项目 | 较新 | 传统工具，兼容性极高 |

建议：

- 日常检索优先用 `fd`。
- 超复杂筛选条件（如权限、时间、inode 等）可回退 `find`。

---

## 10. 常见坑与规避

1. 忘了 `fd` 默认忽略隐藏文件和 `.gitignore`

```bash
fd pattern -u
```

2. 在脚本里直接用换行分隔，导致含空格文件名出错

```bash
fd pattern -0 | xargs -0 ...
```

3. 把 `PATTERN` 当 glob 用但没加 `-g`

```bash
fd -g '*.yml'
```

4. 系统命令是 `fdfind` 而不是 `fd`

```bash
fdfind pattern
```

---

## 11. 高频速查（Cheat Sheet）

```bash
# 基本
fd keyword
fd keyword path/

# 类型和扩展
fd -t f keyword
fd -t d keyword
fd -e py

# 大小写和模式
fd -i readme
fd -s Readme
fd -F 'a+b.txt'
fd -g '*.md'

# 忽略规则
fd -H keyword
fd -I keyword
fd -u keyword

# 排除/深度
fd keyword -E node_modules -E dist
fd keyword --max-depth 3

# 执行命令
fd -e jpg -x convert {} {.}.png
fd -e rs -X wc -l

# 脚本安全输出
fd keyword -0 | xargs -0 -I{} echo {}
```

---

## 12. 推荐工作流

1. 先用 `fd` 快速缩小文件范围。
2. 再用 `rg` 在这些文件里搜内容。
3. 批处理时优先使用 `-0` + `xargs -0`，保证文件名安全。
4. 复杂到 `fd` 不好表达的条件，交给 `find` 补位。

示例：

```bash
fd -e ts src/ -X rg 'TODO|FIXME'
```

这条命令表示：在 `src/` 下先找 `.ts` 文件，再在这些文件中搜索 `TODO/FIXME`。

---

## 13. 一句话总结

`fd` 适合 90% 的“找文件”场景：快、短、好记；和其他 Unix 工具组合后，能覆盖大多数开发检索与批处理任务。