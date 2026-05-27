---
date: 2026-05-27
lang: Linux
tags:
  - linux
  - 工具
  - sd
---

# sd — `s`earch & `d`isplace 用法笔记

> **sd** 是一个直觉式的查找替换 CLI 工具，用 Rust 编写，是 `sed` 的现代替代品。
>
> GitHub: https://github.com/chmln/sd  
> License: MIT | Stars: 7.1k+

---

## 1. 为什么选择 sd？

| 特性        | 说明                                                     |
| --------- | ------------------------------------------------------ |
| **无痛正则**  | 使用 JavaScript/Python 风格的 regex 语法，无需记忆 sed/awk 的各种怪异规则 |
| **字面量模式** | 非正则的纯文本查找替换，`-F` 一键切换，不用疯狂转义                           |
| **易读易写**  | 查找和替换表达式拆分传入，再也不会被斜杠搞晕                                 |
| **合理默认值** | 默认行为贴合日常使用场景                                           |

---

## 2. 与 sed 的对比

| 场景 | sd | sed |
|------|----|-----|
| 替换所有匹配 | `sd before after` | `sed 's/before/after/g'` |
| 换行 → 逗号 | `sd -A '\n' ','` | `sed ':a;N;$!ba;s/\n/,/g'` |
| 提取含斜杠的内容 | `echo "..." \| sd '.*(/.*/)' '$1'` | `echo "..." \| sed -E 's/.*(\\/.*\\/)/\1/g'` |
| 原地修改文件 | `sd before after file.txt` | `sed -i -e 's/before/after/g' file.txt` |

---

## 3. 性能基准

在 **1.5GB JSON 文件**上做简单替换，sd 比 sed 快约 **2.35 倍**。  
在 **55MB JSON 文件**上做正则替换，sd 比 sed 快约 **11.93 倍**。

---

## 4. 安装

```bash
# Cargo（推荐）
cargo install sd

# 其他包管理器
# 见 https://repology.org/project/sd-find-replace/versions
```

---

## 5. 核心用法

### 5.1 基本语法

```
sd [OPTIONS] <find> <replace-with> [files...]
```

- `<find>` — 要查找的模式（默认是正则）
- `<replace-with>` — 替换后的内容
- `[files...]` — 可选的文件列表，不指定则从 stdin 读取

---

### 5.2 字面量模式 (`-F` / `--fixed-strings`)

禁用正则，纯文本匹配：

```bash
echo 'lots((([\]))) of special chars' | sd -F '((([\])))' ''
# 输出: lots of special chars
```

---

### 5.3 基础正则

```bash
# 去除行尾空白
echo 'lorem ipsum 23   ' | sd '\s+$' ''
# 输出: lorem ipsum 23
```

---

### 5.4 捕获组

**索引捕获组（`$1`, `$2`, ...）：**

```bash
echo 'cargo +nightly watch' | sd '(\w+)\s+\+(\w+)\s+(\w+)' 'cmd: $1, channel: $2, subcmd: $3'
# 输出: cmd: cargo, channel: nightly, subcmd: watch
```

**命名捕获组（`(?P<name>...)` + `$name`）：**

```bash
echo "123.45" | sd '(?P<dollars>\d+)\.(?P<cents>\d+)' '$dollars dollars and $cents cents'
# 输出: 123 dollars and 45 cents
```

**消除歧义（`${var}` 语法）：**

当变量名后紧跟字母/数字/下划线时使用 `${var}`：

```bash
echo '123.45' | sd '(?P<dollars>\d+)\.(?P<cents>\d+)' '${dollars}_dollars and ${cents}_cents'
# 输出: 123_dollars and 45_cents
```

---

### 5.5 文件内替换

```bash
# 直接原地修改文件
sd 'window.fetch' 'fetch' http.js

# 预览变更（不写入文件）
sd -p 'window.fetch' 'fetch' http.js
```

---

### 5.6 跨项目批量替换

配合 [fd](https://github.com/sharkdp/fd) 使用：

```bash
# 在所有文件中替换
fd --type file --exec sd 'from "react"' 'from "preact"'

# 带备份的批量替换
fd --type file --exec cp {} {}.bk \; --exec sd 'from "react"' 'from "preact"'
```

---

### 5.7 跨行模式 (`-A` / `--across`)

默认情况下 sd 是**逐行处理**的（`^` / `$` 匹配行首行尾）。

加上 `-A` 后，模式可以跨越换行边界：

```bash
# 将换行替换为逗号
echo -e "hello\nworld" | sd -A '\n' ','
# 输出: hello,world
```

| 模式 | 说明 | 峰值内存 |
|------|------|----------|
| 默认（逐行） | 低内存，流式输出，`^` / `$` 匹配每行边界 | ~3 MB |
| `-A`（跨行） | 多行匹配，如替换 `\n`、多行模式 | ~74 MB |

---

### 5.8 转义特殊字符

`$` 字符用 `$$` 转义：

```bash
echo "foo" | sd 'foo' '$$bar'
# 输出: $bar
```

---

### 5.9 处理以 `-` 开头的参数

使用 `--` 终止标志解析：

```bash
echo "./hello foo" | sd "foo" -- "-w"
# 输出: ./hello -w

echo "./hello --foo" | sd -- "--foo" "-w"
# 输出: ./hello -w
```

---

## 6. 预览模式 (`-p` / `--preview`)

显示将要修改的内容，但不实际写入文件：

```bash
sd -p 'old' 'new' file.txt
```

---

## 7. 常用选项速查

| 选项 | 全称 | 说明 |
|------|------|------|
| `-F` | `--fixed-strings` | 字面量模式，禁用正则 |
| `-p` | `--preview` | 预览模式，显示变化但不修改文件 |
| `-A` | `--across` | 跨行模式，模式可跨换行匹配 |
| `-i` | `--ignore-case` | 忽略大小写（推测） |
| `--` | — | 终止标志解析，后续参数视为普通字符串 |

---

## 8. 实用示例

```bash
# 去除所有行尾空白
sd '\s+$' '' file.txt

# 统一换行符为 Unix 风格（需跨行模式）
sd -A '\r\n' '\n' file.txt

# 删除所有空行
sd '^\s*\n' '' file.txt

# 将单引号替换为双引号
sd "'" '"' file.js

# 重命名变量（预览）
sd -p 'oldFunctionName' 'newFunctionName' src/*.ts

# 批量替换 CSS 类名
fd -e css -x sd '\.old-class' '.new-class'
```

---

## 9. 总结

`sd` 是 `sed` 的最佳现代化替代品：语法直觉、性能优秀、默认值合理。适合日常的查找替换任务，尤其是对正则表达式有大量需求的场景。配合 `fd` 使用可以实现强大的批量文本处理。
