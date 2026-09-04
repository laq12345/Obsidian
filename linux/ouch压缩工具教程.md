# ouch 压缩工具教程

> 一个命令搞定几乎所有压缩/解压格式的现代 CLI 工具。
> 本机版本：**ouch 0.8.0**（位于 `~/.cargo/bin/ouch`）

---

## 1. ouch 是什么 / 为什么用它

传统上压缩文件要记一堆命令：`tar -xzf`、`unzip`、`7z x`、`gunzip`……每种格式命令还不一样。
**ouch 用一套统一的 `compress / decompress / list` 命令覆盖所有常见格式**，根据文件扩展名自动判断格式，免去记忆负担。

**支持的格式**：`tar, zip, gz, 7z, xz, lzma, lzip, bz/bz2, bz3, lz4, sz (Snappy), zst (Zstd), rar, br (Brotli)`

三个核心动作记牢即可：

| 动作 | 命令 | 别名 |
| ------ | ------ | ------ |
| 解压 | `ouch decompress` | `ouch d` |
| 压缩 | `ouch compress` | `ouch c` |
| 查看内容 | `ouch list` | `ouch l` |

---

## 2. 解压（最常用）

```bash
# 基本用法：解压到当前目录下一个以压缩包名命名的子目录里
ouch d 文件.zip

# 就地在当前目录解开（不建子目录）——最常用的场景
ouch d 文件.tar.gz --here

# 解压到指定目录
ouch d 文件.zip -d ~/下载

# 一次解压多个文件
ouch d a.zip b.7z c.tar.xz

# 带密码解压
ouch d 加密.7z -p 你的密码

# 解压成功后删除原压缩包（清理用）
ouch d 文件.zip -r

# 解压的同时用多线程加速（压缩包很大时）
ouch d 大文件.tar.gz -c 8
```

> 💡 **小贴士**：`--here` 很常用，相当于 `tar -xf` / `unzip` 的那种"就地解开"行为。

---

## 3. 压缩

```bash
# 单个文件压成 zip（格式由输出扩展名决定）
ouch c 笔记.md 笔记.zip

# 多个文件/目录压成一个 tar.gz
ouch c a.txt b.csv 文档/ 结果.tar.gz

# 压成 7z 并加密（-p）
ouch c 重要资料/ 归档.7z -p 密码

# 控制压缩强度：
ouch c 大文件.sql out.zst --fast     # 最快（体积大）
ouch c 大文件.sql out.zst --slow     # 最慢但体积最小
ouch c 大文件.sql out.zst -l 9       # 手动指定级别 0-9

# 打包项目时忽略 .gitignore 和隐藏文件（-g -H）
ouch c myproject/ code.tar.gz -g -H

# 多线程压缩（-c）
ouch c 大目录/ 备份.7z -c 8

# 强制指定格式（即使扩展名不标准，用 -f）
ouch c data.bin out.dat -f zip
```

**要点**：输出文件的**扩展名**就是格式说明书——想压成什么就在输出名里写什么扩展名。

---

## 4. 查看内容

```bash
ouch l 文件.zip        # 列出压缩包内文件
ouch l 文件.tar.gz -p 密码   # 加密包也能列
```

---

## 5. 全局通用选项

| 选项 | 作用 |
| ------ | ------ |
| `-y` / `-n` | 自动回答确认提问 Yes/No |
| `-q` / `--quiet` | 静默输出 |
| `-f <格式>` | 指定格式 |
| `-p <密码>` | 带密码压缩/解压/查看 |
| `-c <线程数>` | 并发工作线程 |
| `-H` | 忽略隐藏文件 |
| `-g` | 忽略被 .gitignore 匹配的文件 |
| `-A` | 无障碍模式（减少视觉噪音） |

---

## 6. 实战场景

### 场景 A：拿到 `测序数据.tar.gz`，就地解开

```bash
ouch d 测序数据.tar.gz --here -y
```

### 场景 B：把生信分析结果打包发人（不想要中间隐藏文件）

```bash
ouch c results/ QC报告.html 结果_0719.tar.gz -g -H -y
```

### 场景 C：加密一份带患者/样本信息的文件

```bash
ouch c samples.csv 敏感结果.xlsx 数据_加密.7z -p 你的强密码 -y
```

### 场景 D：备份整个项目目录，多线程以便更快

```bash
ouch c ~/项目/ ~/备份_20260819.tar.zst -c 8 -y
```

---

## 7. （可选）fish 缩写配置

如果你用 fish shell，可以把下面几行加进 `~/.config/fish/config.fish`，之后输入缩写会自动展开成完整命令：

```fish
# 就地解压到当前目录
abbr -a ux 'ouch d --here'
# 解压并删除原压缩包
abbr -a udr 'ouch d -r'
# 压缩，自动忽略 .gitignore 和隐藏文件
abbr -a uz 'ouch c -y -g -H'
# 列出压缩包内容
abbr -a ul 'ouch l'
```

保存后 `source ~/.config/fish/config.fish` 生效。
（ouck 自带 `c/d/l` 三个子命令别名，本体够短，缩写主要用于"顺手带参数"的场景。）

---

## 8. 常见问题

- **提示确认提问想跳过？** 加 `-y`
- **rar 格式解不开？** 确认系统装了对应后端（`rar`/`unrar` 或 `bsdtar`）
- **想解到"当前目录"而不是子目录？** 记得加 `--here`
- **记不住格式？** 看输出文件名扩展名就行，或 `-f` 强制指定

## 9. 快速参考（一页速查）

```bash
ouch d 文件.zip                # 解压（建子目录）
ouch d 文件.zip --here         # 就地解压
ouch d 文件.zip -d 目录/       # 解到指定目录
ouch c 文件 输出.zip           # 压缩（格式看扩展名）
ouch c 目录/ 输出.tar.gz -y    # 压缩整个目录
ouch l 文件.zip                # 查看内容
```

---

*教程生成时间：2026-08-19　|　针对 ouch 0.8.0　|　官方仓库：github.com/ouch-org/ouch*
