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

> [!warning] 2026-09-20 用本机 **sd v1.0.0** 逐条核对后修正
> 修正了三个错误：① `-A` / `--across`、`-i` / `--ignore-case` **这两个选项在 sd 里并不存在**（正确的是 `-f m` / `-f i`）；② 性能基准数字来源不明，已换成本机实测；③ 内存开销的结论是反的（sd 比 sed 费内存得多）。

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
| 换行 → 逗号 | `sd -f m '\n' ','` | `sed ':a;N;$!ba;s/\n/,/g'` |
| 提取含斜杠的内容 | `echo "..." \| sd '.*(/.*/)' '$1'` | `echo "..." \| sed -E 's/.*(\\/.*\\/)/\1/g'` |
| 原地修改文件 | `sd before after file.txt` | `sed -i -e 's/before/after/g' file.txt` |

---

## 3. 性能基准

> [!warning] 原本写的“1.5GB 快 2.35 倍 / 55MB 快 11.93 倍”来自 sd 上游 README 的基准（不同硬件、不同文件），并非本机实测。

**本机实测**（86 MB / 150 万行文本，tmpfs，`time` 计时，结果用 `cmp` 验证过与 sed 一致）：

| 任务 | sd | sed | 倍数 |
|------|-----|-----|------|
| 字面量替换（`-F`） | 0.196 s | 0.470 s | sd **快 2.4×** |
| 正则 + 捕获组替换 | 0.338 s | 0.566 s | sd **快 1.7×** |

结论：**sd 确实快，但在本机这个规模上是 1.7–2.4 倍，不是十几倍。** 十几倍那种数字通常来自特定的硬件与文件特征，别当普适结论引用。

### 3.1 内存：sd 是输的一方

同一份 86 MB 文件，用 `/usr/bin/time -v` 看峰值 RSS：

| 命令 | 峰值内存 |
|------|---------|
| `sd 'a' 'b' file` | **261 MB**（约文件的 3 倍） |
| `sd -f m 'a' 'b' file` | **261 MB**（与是否跨行无关） |
| `sd 'a' 'b' < file`（走管道） | 175 MB |
| `sed -i 's/a/b/g' file` | **3 MB**（真流式） |

**sd 会把整个文件读进内存，sed 是真的流式处理。** 所以：

- 改几个 GB 的大文件（日志、导出的 CSV）时，`sed -i` 更安全；
- `sd` 在内存受限的机器上可能直接被 OOM 杀掉。

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

> [!danger] 索引捕获组也一样会歧义，而且名字字符集比你想的宽
> `$1X` 不会被理解为“第 1 组 + X”，而是“名为 `1X` 的组”，直接**报错退出**：
> ```bash
> $ echo 'needle' | sd 'n(e{2})dle' 'X$1X'
> error: The numbered capture group `$1` in the replacement text is ambiguous.
> hint: Use curly braces to disambiguate it `${1}X`.
>
> $ echo 'needle' | sd 'n(e{2})dle' 'X${1}X'
> XeeX          # 正确
> ```
> `sed` 的 `\1X` 没有这个问题（它能认出组号到 `1` 就结束）。

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

### 5.7 跨行模式（`-f m`）

> [!danger] 这里原本写的是 `-A` / `--across`——**sd 1.0.0 没有这个选项**
> ```bash
> $ printf 'a\nb\n' | sd -A 'a\nb' 'AB'
> error: unexpected argument '-A' found
>
> $ printf 'a\nb\n' | sd --across 'a\nb' 'AB'
> error: unexpected argument '--across' found
> ```
> 正确写法是 **`-f m`（`--flags m`，即 regex 的多行标志 m）**。

默认情况下 sd 是**逐行处理**的（`^` / `$` 匹配行首行尾）。加上 `-f m` 后，`^`/`$` 按整个输入算，模式就能跨越换行边界：

```bash
# 将换行替换为逗号
$ printf 'hello\nworld\n' | sd -f m '\n' ','
hello,world,

# 或者让 . 也匹配换行（-f s）：
$ printf 'a\nb\n' | sd -f s 'a.b' 'AB'
AB
```

| 模式 | 说明 | 本机实测峰值内存（86 MB 文件） |
|------|------|-------------------------------|
| 默认 | 逐行匹配，`^` / `$` 匹配每行边界 | **261 MB** |
| `-f m` | 多行匹配，`^`/`$` 作用于整个输入 | **261 MB**（与默认基本相同） |

> [!note] 内存数字纠正
> 本文原写“默认 ~3 MB / 跨行 ~74 MB”，**两个数字都不对**。实测 sd 无论加不加 `-f m` 都要 ~261 MB；真正流式的是 `sed`（3 MB）。详见 § 3.1。

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
| `-n` | `--max-replacements N` | 限制每文件替换次数（`0` = 不限制） |
| `-f` | `--flags <FLAGS>` | 正则标志，可组合（`c` `e` `i` `m` `s` `w`） |
| `--` | — | 终止标志解析，后续参数视为普通字符串 |

> [!danger] 常见的三个错记
> - `-i` 想当作“忽略大小写”：**sd 没有 `-i`**，正确是 `-f i`（实测 `sd -i` → `error: unexpected argument '-i' found`）。
> - `-A` / `--across` 想当作跨行：**不存在**，正确是 `-f m`。
> - `-f` 后面可组合多个标志，如 `-f mc`（多行 + 区分大小写）。

---

## 8. 实用示例

```bash
# 去除所有行尾空白
sd '\s+$' '' file.txt

# 统一换行符为 Unix 风格（需多行模式）
sd -f m '\r\n' '\n' file.txt

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
