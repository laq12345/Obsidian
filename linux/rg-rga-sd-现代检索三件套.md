---
time: 2026-09-20T23:20:00
lang: Linux
tags:
  - linux
  - 工具
  - shell
  - 编程
---

# rg / rga / sd：现代检索替换三件套

> **rg 是 grep 的超集式替代，rga 是 rg 的"穿透二进制格式"扩展，sd 是只做替换的 sed。**
> 三者都是 Rust 写的，共用一套"默认就该做对的事"的哲学：递归默认、自动跳过 `.gitignore`、并行、UTF-8 安全。
> 本机版本：**ripgrep 15.2.0**（`~/.cargo/bin/rg`，⚠ **无 PCRE2**）、**ripgrep-all 0.10.10**（`~/.pixi/bin/rga`）、**sd 1.0.0**（`~/.cargo/bin/sd`）。
> 本文所有输出均为本机实跑：合成样本见附录 B，**真实素材用 `~/Desktop/test` 里的 ARDS 综述 PDF/DOCX 与 `整理结果.zip`**（见附录 A）。

> [!info] 和已有笔记的关系
> `rg` 和 `sd` 在这个库里早有单独的笔记，本文**不重复它们的内容**，只做：
> 1. 三件套的**选型与横向对照**；2. 补齐完全没有笔记的 **`rga`**（第三节）；3. 把版本升级后**已经过时/写错的点**标出来。
> 细节请看 [[ripgrep使用指南]]、[[sd笔记]]、[[sd-vs-sed-完全指南]]。

---

## 一、选型：什么时候用谁

| 任务 | 用什么 | 为什么 |
|------|--------|--------|
| 在代码/文本里找内容 | **`rg`** | 递归默认、自动跳过 `.gitignore`、并行、结果按文件分组 |
| 在 **PDF/Office/电子书/压缩包/数据库/音视频**里找内容 | **`rga`** | 只有它能把二进制格式抽成文本再交给 rg |
| 在**代码里替换**（单文件/多文件/整仓库） | **`sd`** | 参数直觉、默认全局替换、命名捕获组 |
| 在管道里做行级变换（删行/插行/跨行/保持空间） | **`sed`** | `sd` 只会替换，不做行操作 |
| 按列计算、分组统计 | **`awk`** | 三位都不做这个 |
| 在**没有 .gitignore 概念**的老环境/最小系统里搜 | **`grep -r`** | rg 不是所有机器都有；`grep` 是 POSIX 保证存在 |
| 搜**单个已知文件**里的字面串 | **`grep -F`** | 起进程最快，不需要 rg 的目录扫描 |
| 输出对齐成表 | **`column`** | 见 [[文本处理三剑客]] 第八节 |

一条经验法则：**`rg` 和 `grep` 不是二选一，而是"交互搜索用 rg，脚本兼容用 grep"**；`rga` 只在"你确定要找的东西藏在一个 PDF/Excel/zip 里"时才需要——它慢得多（见 3.6）。

---

## 二、rg（ripgrep 15.2.0）

> 详细的用法（`.ignore`/`.rgignore`、`-t`/`-T` 类型过滤、`--pre` 预处理器、配置文件、编码、二进制处理）见 [[ripgrep使用指南]]。本节只写**选型相关**和**和那篇笔记不一致的地方**。

### 2.1 它比 `grep` 强在哪

| 行为 | `grep -r` | `rg` |
|------|-----------|------|
| 递归 | 要写 `-r` | 默认就递归 |
| 跳 `.gitignore` / `.ignore` | 不会，得手动排除 | 默认遵守 |
| 跳隐藏文件/目录 | 会搜 `.git` | 默认跳过 |
| 并行 | 单线程 | 多线程 |
| 输出 | 每行都带文件名 | 按文件分组（文件名只出现一次） |
| 行号 | `-n` | 默认带 |
| 大小写 | 只按你写的 | 智能大小写（见下） |
| 正则 | BRE/ERE | Rust regex（无反向引用/环视） |
| 跨行匹配 | 不支持 | `-U`（多行模式） |

**智能大小写**（实测）：全小写的模式自动忽略大小写，模式里出现大写就变成区分大小写。

```bash
$ rg -c 'falcon' memo.md memo.html      # 全小写 → 忽略大小写
memo.html:1
memo.md:1

$ rg -c 'Falcon' memo.md memo.html      # 含大写 → 区分大小写
$ echo "exit=$?"
exit=1
```

要关掉这个行为：`-s`（区分大小写）、`-i`（忽略大小写）、`-S`（智能，默认）。

### 2.2 常用选项（实跑）

```bash
$ rg -o '\bBC-[0-9]+' memo.md           # -o 只输出匹配的部分
BC-9931

$ rg -l 'falcon' -t md -g '!pkg/**'     # -l 只列文件；-t 类型；-g glob
memo.md

$ rg --files | head -5                  # 只列文件（不走内容搜索）
doc.typ
doc.pdf
memo.md
memo.docx
memo.odt

$ rg -r 'FALCON' 'falcon' memo.md       # -r 预览替换结果（不写文件）
The FALCON-north project moved to cluster `atlas-7` in September.
```

**默认跳过隐藏文件和 .gitignore 里的东西**，这是最需要记住的一点：

```bash
$ mkdir -p hid && printf 'falcon hidden\n' > hid/.secret.md
$ rg -l falcon hid                      # 默认无输出（隐藏文件被跳过）
$ rg -l --hidden --no-ignore falcon hid # 显式打开才搜
hid/.secret.md
```

### 2.3 ⚠ 你这版 rg **没有编译 PCRE2**

```bash
$ rg --version
ripgrep 15.2.0
features:-pcre2
simd(compile):+SSE2,-SSSE3,-AVX2
simd(runtime):+SSE2,+SSSE3,+AVX2
PCRE2 is not available in this build of ripgrep.

$ rg -P 'a(?=b)' .
rg: PCRE2 is not available in this build of ripgrep
```

**影响**：`-P`（以及依赖它的 `\K`、环视 `(?=)`/`(?<=)`、反向引用）全都用不了。如果哪天需要：

```bash
cargo install ripgrep --features pcre2 --force    # 或者装带 pcre2 的发行版包
```

这条是本机 cargo 编译时没开默认特性导致的——**上游官方二进制是带 pcre2 的**，所以"别人的 rg 能用 -P"这句话对你这台机器不成立。

> [!important] 这条也适用于本文其它地方
> 我把 `-P` 相关的例子全部去掉了，改用 `-U` 多行或 `sd`/`awk` 替代方案。

### 2.4 `-z` 到底能搜哪些压缩文件（实测）

`rg -z`（`--search-zip`）**只解压单流压缩格式，不支持容器格式**：

| 文件 | `rg -z -q BC-9931 <file>` | 说明 |
|------|--------------------------|------|
| `n.gz` | ✅ 搜到 | 支持 |
| `n.bz2` | ✅ 搜到 | 支持 |
| `n.xz` | ✅ 搜到 | 支持 |
| `n.zst` | ✅ 搜到 | 支持（lz4/brotli 同理） |
| `bundle.zip` | ❌ 搜不到 | **zip 是容器，rg 不支持** |
| `bundle.tar.gz` | ✅ 搜到 | **假阳性**：gz 解开后是 tar，tar 里文件正文是明文，被当文本扫到了 |

`--stats` 能看出它确实在解压后再搜：

```bash
$ rg -z --stats falcon bundle.zip
binary file matches (found "\0" byte around offset 5)   # zip 只能得到这个
$ rg -z --stats BC-9931 notes.txt.gz
1 files contained matches
1 files searched
54 bytes printed
5 bytes searched          ← 搜索的是解压后的 5 字节，不是压缩后的 77 字节
```

结论：**要正经搜 zip/tar 里的内容，用 `rga`，不要指望 `rg -z`。**`tar.gz` 那种"碰巧命中"的可靠性很低（偏移错乱、二进制夹杂、无法给出准确行号）。

### 2.5 性能（本机实测）

5000 个小文件 / 59 MB（tmpfs，热缓存，`time` 取最快一次）：

| 命令 | 耗时 | 相对 |
|------|------|------|
| `rg -l falcon .` | 0.011 s | 1.0× |
| `rg -c falcon .` | 0.015 s | 1.4× |
| `grep -rc falcon .` | 0.027 s | 2.5× |
| `find . -type f -exec awk '/falcon/' {} \;` | 8.883 s | **807×** |

要点：

- rg 比 `grep -r` 快约 **1.8 倍**（多线程 + 跳 `.gitignore`）。规模越大差距越明显，几十个文件时是噪声。
- 最后一行不是"awk 慢"，而是**"每个文件起一个进程"慢**——807 倍里绝大部分花在 `fork/exec` 5000 次上。任何 `find -exec` 逐文件调用解释器的写法都有这个量级的问题，这也是 rg 快的根本原因：**一个进程内部并行**。

---

## 三、rga（ripgrep-all 0.10.10）—— 本节重点

> 这个工具在本库**之前完全没有笔记**，所以这节写得完整些。

### 3.1 它到底是什么

`rga` **不是**另一个搜索引擎。它是 **rg 的前端**：

```
你敲 rga 'pattern' 路径/
        │
        ├─ 遍历文件，按扩展名/magic 选适配器
        ├─ 适配器调用外部工具把文件抽成【纯文本】(PDF→pdftotext, docx→pandoc, zip→解压…)
        ├─ 抽取结果塞进缓存（sqlite + zstd）
        └─ 把纯文本喂给【真正的 rg】，其余选项原样透传
```

所以：**`rga` 支持所有 `rg` 选项**，而 `rg` 做不到的（读 PDF/docx/zip/db）由适配器补上。

```bash
rga [RGA 选项] [RG 选项] PATTERN [路径...]
```

### 3.2 能搜什么：适配器 + 外部依赖

`rga --rga-list-adapters` 列出的默认适配器（本机 0.10.10）：

| 适配器 | 处理 | 支持扩展名 | 依赖的外部工具 |
|--------|------|-----------|--------------|
| `pandoc` | 文档→markdown | `.epub .odt .docx .fb2 .ipynb .html .htm` | `pandoc` |
| `poppler` | PDF→纯文本（带页码） | `.pdf` | `pdftotext`（poppler-utils） |
| `postprocpagebreaks` | 给 poppler 输出加 `Page N:` 前缀 | 内部用 | — |
| `ffmpeg` | 音视频元数据/章节/字幕/歌词 | `.mkv .mp4 .avi .mp3 .ogg .flac .webm` | `ffmpeg` |
| `zip` | 递归走进压缩包 | `.zip .jar .xpi .kra .snagx` | 内建 |
| `tar` | 递归走进 tar | `.tar` | 内建 |
| `decompress` | 解压单流压缩后交给别的适配器 | `.gz .bz2 .xz .zst .tgz .tbz2 .als` | 内建 |
| `sqlite` | 数据库导成文本 | `.db .db3 .sqlite .sqlite3` | 内建（不需要 sqlite3 CLI） |
| `mail` | 邮件正文+附件 | `.mbox .mbx .eml` | **默认禁用**，要 `--rga-adapters=+mail` |

> [!warning] 能不能搜某种格式，取决于你**装了哪些外部工具**
> 本机实测的依赖情况：
> | 工具 | 状态 |
> |------|------|
> | `pandoc` | ✅ `~/.pixi/bin/pandoc`（3.11） |
> | `pdftotext` / `pdfinfo` | ✅ `/usr/bin/`（poppler-utils） |
> | `ffmpeg` / `ffprobe` | ✅ mise 装的 |
> | `unzip` / `tar` / `gzip` | ✅ |
> | `sqlite3` CLI | ❌ 缺失，**但不影响**——`sqlite` 适配器用的是内建绑定 |
> | `tesseract`（OCR）、`exiftool` | ❌ 缺失，所以**没有 OCR / EXIF 适配器可用** |
>
> 缺 `pandoc` 就搜不了 docx/odt/epub；缺 `pdftotext` 就搜不了 PDF，而且 rga 只会安静地跳过（不会明确报"我没装 pdftotext"）。

### 3.3 跨格式搜索实测（合成样本，逐格式验证）

一次命令，同时穿透 11 种格式（同一个目录，`rga falcon-north .` 的完整输出）：

```bash
$ rga falcon-north .
./doc.typ:Internal codename for the project is "falcon-north".        ← 纯文本，rg 直接搜
./memo.md:The falcon-north project moved to cluster `atlas-7` ...
./pkg/inner.md:secret token: falcon-north
./app.db:users: id=1, name='alice', note='falcon-north rollout'       ← sqlite 表被导成文本
./memo.html:The falcon-north project moved to cluster atlas-7 ...
./bundle.zip:pkg/inner.md: secret token: falcon-north                 ← 压缩包【内部路径】
./pkg2/deep.zip:pkg/inner.md: secret token: falcon-north
./bundle.tar.gz:pkg/inner.md: secret token: falcon-north
./memo.ipynb:The falcon-north project moved to cluster atlas-7 ...
./doc.pdf:Page 1: the project is “falcon-north”.                      ← PDF，带页码前缀
./memo.epub:The falcon-north project moved to cluster atlas-7 ...
./memo.docx:The falcon-north project moved to cluster atlas-7 ...
./memo.odt:The falcon-north project moved to cluster atlas-7 ...
./nested.zip:pkg2/deep.zip: pkg/inner.md: secret token: falcon-north  ← 嵌套压缩包，两级前缀
./tone.mp3:metadata: format.tags.title="falcon-north review BC-9931"  ← mp3 元数据
```

几个值得注意的点：

- **压缩包内的匹配会显示内层路径**：`bundle.zip:pkg/inner.md: ...`，嵌套就是 `nested.zip:pkg2/deep.zip: pkg/inner.md:`。这很方便，但**内层路径也会被当成搜索内容**（所以搜 `inner` 会命中路径），要关掉用 `--rga-no-prefix-filenames`：
  ```bash
  $ rga falcon bundle.zip
  pkg/inner.md: secret token: falcon-north
  $ rga --rga-no-prefix-filenames falcon bundle.zip
  secret token: falcon-north
  ```
- **PDF 的行会被加上 `Page N:` 前缀**（`postprocpagebreaks` 适配器），这是判断"这行来自 PDF 第几页"的唯一线索——代价是关键词本身可能被分页拆开。
- **docx/odt/epub/ipynb 统一走 pandoc → 转成 markdown 再搜**，所以搜到的是**转换后**的文本，格式（表格、脚注）可能与原文档观感不同。
- **sqlite 是把表导成 `表名: 列=值, 列=值` 的文本**，所以搜 `users` 表名也会命中。

只列文件名（`-l` 透传给 rg）：

```bash
$ rga -l BC-9931 . | sort
./app.db
./bundle.tar.gz
./bundle.zip
./doc.pdf?   ← 不含 BC-9931，不会出现
```
（实测命中：`app.db`、`bundle.tar.gz`、`bundle.zip`、`memo.docx`、`memo.epub`、`memo.html`、`memo.ipynb`、`memo.md`、`memo.odt`、`nested.zip`、`notes.txt.gz`、`pkg/notes.txt`、`tone.mp3`）

### 3.3b 真实素材实测：一篇 ARDS 综述的 PDF / DOCX / ZIP

合成样本只能证明"适配器能跑通"，真实文件才能看出问题。用 `~/Desktop/test` 里的三份真实素材：

```bash
$ ls ~/Desktop/test
ARDS_Review.docx  ARDS_Review.pdf  整理结果.zip
# PDF 2.3 MB（Typst 排版，有文本层），DOCX 1.7 MB，ZIP 里是 6 个 xlsx 表格

$ rga 'VILI' ARDS_Review.pdf | head -3
Page 1: VILI Monitoring in ARDS: Research Progress and
Page 1: ventilator-induced lung injury (VILI)—a process driven by the transduction of nonphysiological mechanical forces into biological signals that trigger inflammation,
Page 1: of VILI has evolved substantially over the past quarter-century, transitioning
```

抽取质量很好（连字符、换行、全角引号都被 pdftotext 处理得不错）。但有三个**必须知道的坑**：

> [!danger] 坑 1：`-c` 数的是行，不是出现次数；同一篇文档的 PDF 与 DOCX 结果差很多
> ```bash
> $ rga -c 'ARDS' ARDS_Review.pdf        # 含 ARDS 的【行数】
> 119
> $ rga -c 'ARDS' ARDS_Review.docx       # 同一篇文档的 Word 版
> 73
> $ rga -o 'ARDS' ARDS_Review.pdf  | wc -l   # 真正的【出现次数】
> 121
> $ rga -o 'ARDS' ARDS_Review.docx | wc -l
> 119
> ```
> 原因：PDF 抽取后每行很短（版心窄、频繁换行），DOCX 抽取后段落长，所以"含匹配的行数"完全不同。**跨格式数关键词，一律用 `-o | wc -l`，不要用 `-c`。**
> 抽取出的文本量（`--stats` 的 `bytes searched`）：PDF **230,219 字节**、DOCX **217,865 字节**——总量接近，说明两种适配器都没丢内容。

> [!danger] 坑 2：ZIP 里装着 xlsx 时，rga **静默地什么都不报**
> ```bash
> $ unzip -l 整理结果.zip   # 基线表1-患者基本信息.xlsx … 结局表2-研究结局.xlsx（共 6 个）
> $ rga -l 'ARDS' 整理结果.zip
> $ echo "exit=$?"
> exit=1                       # 无任何输出、无任何报错
> ```
> rga 0.10 **没有 xlsx 适配器**，zip 适配器又只能把内容交给其它适配器，于是整个搜索变成"什么都没发生"——它甚至不告诉你"我不支持这个格式"。解决办法见 3.8。

> [!danger] 坑 3：`--rga-no-cache` 在本机 0.10.10 上是坏的（见 3.6）
> 而"干净重跑"恰好是搜大 PDF 时最常用的需求，所以这个 bug 很呛人。

所以搜自己的论文/资料库时，实用姿势是：

```bash
# 搜一份 PDF/DOCX，拿到真实出现次数
rga -o 'PEEP' ARDS_Review.pdf | wc -l

# 同时搜整个目录，只列文件（-l 走 rg，不受 -c 行数问题影响）
$ rga -l 'PEEP|ARDS' ~/Desktop/test
./ARDS_Review.pdf
./ARDS_Review.docx
```

### 3.4 适配器控制：`--rga-adapters`

三种写法：

```bash
--rga-adapters=poppler,zip     # 只用这两个
--rga-adapters=-pandoc         # 用全部默认，但排除 pandoc
--rga-adapters=+mail           # 默认全用，再加上 mail
```

实测对比（同一目录 `rga -l falcon .`）：

```bash
$ rga --rga-adapters=poppler -l falcon .    # 只剩 PDF + 纯文本
./doc.typ  ./s.txt  ./p.txt  ./pkg/inner.md  ./memo.html  ./memo.ipynb  ./memo.md
./doc.pdf  ./copies/r01.pdf … r20.pdf

$ rga --rga-adapters=-pandoc -l falcon .    # docx/odt/epub 消失，但 html/ipynb 还在！
./doc.typ  ./pkg/inner.md  ./memo.html  ./memo.ipynb  ./memo.md  ./p.txt  ./s.txt
./doc.pdf  ./app.db  ./bundle.tar.gz  ./bundle.zip  ./tone.mp3  ./nested.zip …
```

> [!note] 关键理解：**纯文本文件根本不需要适配器**
> 上面 `-pandoc` 之后 `memo.html` 和 `memo.ipynb` 仍然被搜到——因为它们是纯文本，**rg 自己就能读**，pandoc 适配器对它们只是"可选的更好解析"。
> 所以 `--rga-adapters` 控制的只是**二进制/不可直读格式**的处理方式，你没法用它"关掉"对文本文件的搜索。

### 3.5 `--rga-accurate`：扩展名骗人时

默认 rga **按扩展名**选适配器（快）。文件被改名/没有扩展名时（sqlite 数据库常这样）就失效：

```bash
$ cp doc.pdf doc.bin
$ rga falcon doc.bin                  # 默认：按扩展名找不到适配器
$ echo "exit=$?"; exit=1
$ rga --rga-accurate falcon doc.bin   # 按 magic bytes（前 8KiB）判断
Page 1: the project is “falcon-north”.
```

代价：每个文件都要读前 8KiB 做嗅探，大目录下更慢。**只在"确实有伪装扩展名的文件"时才加。**

### 3.6 缓存机制

rga 会把适配器抽出的文本压缩后存进 sqlite，避免重复解析：

```bash
$ ls -la ~/.cache/ripgrep-all/
-rw-r--r--. 1 smile smile 8331264 cache.sqlite3
...
$ du -h ~/.cache/ripgrep-all/cache.sqlite3
7.4M
```

相关选项：

| 选项 | 作用 |
|------|------|
| `--rga-cache-path=<path>` | 换缓存位置（默认 `~/.cache/ripgrep-all`）。**注意必须用 `=`**，写成空格会报 `For more information try --help` |
| `--rga-cache-max-blob-len <n>` | 超过这个压缩后大小的抽取结果不进缓存（默认 2 MB） |
| `--rga-cache-compression-level <1-22>` | zstd 压缩级别（默认 12） |
| `--rga-no-cache` | 声称禁用缓存，但**本机 0.10.10 上是坏的**，见下 |

**实测（真实文件，`~/Desktop/test`）**：

| 文件 | 冷（空缓存目录） | 温（缓存命中） | 收益 |
|------|----------------|--------------|------|
| `ARDS_Review.pdf`（2.3 MB） | 0.134 s | 0.011 s | **12×** |
| `ARDS_Review.docx`（1.7 MB） | 0.468 s | 0.013 s | **36×** |
| `pdftotext` 单独跑（基准） | 0.112 s | — | — |

冷启动的时间基本就是"调用外部工具"的时间（PDF ≈ pdftotext 基线 + 20 ms，DOCX 的 pandoc 转换慢到 0.47 s），缓存直接把这笔开销省掉。**缓存确实有用，而且大文件上收益很大。**

> [!danger] `--rga-no-cache` 在本机 0.10.10 上是坏掉的
> 加了它之后，**所有需要适配器的文件都会解析失败**：
> ```bash
> $ rga --rga-no-cache 'VILI' ARDS_Review.pdf
> rg: ARDS_Review.pdf: preprocessor command failed: '"…/rga-preproc" "ARDS_Review.pdf"':
> -------------------------------------------------------------------------------
> /var/home/smile/Desktop/test/ARDS_Review.pdf adapter: poppler
> Error: during preprocessing
>
> Caused by:
>     0: run_adapter(/var/home/smile/Desktop/test/ARDS_Review.pdf)
>     1: No cache?
> -------------------------------------------------------------------------------
> $ echo "exit=$?"
> exit=2
> ```
> 特征：**纯文本文件照常搜得到**（rg 不经预处理器），所以不会一眼看出问题；`--stats` 会报 `0 files searched`。
> **绕过办法**：不要用 `--rga-no-cache`，改用一个空目录当缓存路径：
> ```bash
> rga --rga-cache-path=/tmp/freshcache -c 'ARDS' ARDS_Review.pdf   # 119（正确）
> rm -rf /tmp/freshcache                                            # 想要"干净重跑"就删目录
> ```

> [!warning] 测 rga 性能时有两个隐性陷阱（我踩了两个）
> 1. **不要用 `-q`**：rg 的 `-q` 命中即退，抽文本的子进程会被 SIGPIPE 提前杀掉，量出来的不是真实耗时。
> 2. **不要把输出丢给 `/dev/null`**：rg 在输出被丢弃时也会走"只需知道有没有匹配"的快路径，同样提前退出（和 [[文本处理三剑客]] 3.7 节里 `grep -c >/dev/null` 的坑是同一个原理）。
> 正确姿势：输出到真实文件（`> /tmp/o.txt`）或用 `-c` 且不重定向到 `/dev/null`。上面那些数据就是这么测的。

### 3.7 `rga-preproc`：单独把文件转成文本

`rga` 装包时还会带一个 `rga-preproc`，用于**把某个文件抽取成纯文本**（正是适配器干的事），可以拿它跟别的工具组合：

```bash
$ rga-preproc doc.pdf
/tmp/modern/doc.pdf adapter: poppler          ← stderr，告诉你用了哪个适配器
Page 1: Quarterly Report
Page 1: The migration to the new billing cluster finished on schedule.
Page 1: Total revenue recognised was 48213 USD. Internal codename for
Page 1: the project is “falcon-north”.
```

用法示例：

```bash
rga-preproc big.pdf | awk '{s+=length($0)} END{print s" 字符"}'   # 统计 PDF 字数
rga-preproc annual.docx | sd -f w 'BC-[0-9]+' 'REDACTED'          # 转文本后替换
rga-preproc a.pdf > a.txt                                          # 转成文本再交给 grep/sd
```

### 3.8 rga 做不到 / 需要知道的限制

| 限制 | 实测 | 说明 |
|------|------|------|
| **不支持 xlsx** | `rga -l 'ARDS' 整理结果.zip`（里含 6 个 xlsx）→ **无任何输出、无报错**，退出码 1 | 0.10 没有 xlsx 适配器，且是**静默失败**。两种绕法见 3.8.1 |
| **不能从管道读** | `cat doc.pdf \| rga falcon` → 无输出 | rg 能读 stdin，**rga 不能**（没有适配器能作用于 stdin）。要搜先落盘成文件 |
| **没有 OCR** | 扫描版 PDF（无文本层）搜不到 | 适配器列表里没有 OCR；需要 `tesseract` 自行处理 |
| **没有 EXIF 适配器** | 本机 `exiftool` 缺失，也没有 image 适配器 | 照片元数据搜不了 |
| **比 rg 慢一个量级** | 见下 | 每个文件都要跑外部进程 + 读缓存 |
| **`mail` 适配器默认禁用** | 需要显式加 | `--rga-adapters=+mail` |
| 嵌套归档深度 | 默认 5 层 | `--rga-max-archive-recursion` |

### 3.8.1 搜 xlsx 的三种绕法（针对 `整理结果.zip` 里的 6 个表实测）

**绕法 A：把 xlsx 当 zip 直接扒 XML**（最快，不装任何东西）

xlsx 本质是 zip + XML，字符串就在 `xl/worksheets/sheetN.xml` 里。
⚠ 注意**不是** `xl/sharedStrings.xml`——本机这 6 个表用的是 **inline 字符串**，压根没有 sharedStrings.xml（`unzip -l … | grep sharedStrings` → 0）：

```bash
$ unzip -p /tmp/xl/基线表1-患者基本信息.xlsx xl/worksheets/sheet1.xml | rg -o 'ARDS|机械通气|PEEP' | sort | uniq -c
    410 ARDS
      1 PEEP

# 批量：整个 zip 里每个 xlsx 的命中次数
$ mkdir -p /tmp/xl && unzip -oq ~/Desktop/test/整理结果.zip -d /tmp/xl
$ for f in /tmp/xl/*.xlsx; do
    n=$(unzip -p "$f" 'xl/worksheets/*.xml' | rg -o 'ARDS' | wc -l)
    printf '%-40s %s\n' "$(basename "$f")" "$n"
  done
基线表1-患者基本信息.xlsx                410
基线表2-入ICU时基线资料.xlsx               4
基线表3-APACHII评分.xlsx                    4
基线表4-SOFA评分.xlsx                       4
结局表1-并发并发症.xlsx                     4
结局表2-研究结局.xlsx                       4
```

> [!warning] 为什么这里用 `-o | wc -l` 而不是 `-c`
> XML 是一整行，`rg -c` 只会给你 `1`（1 行包含匹配），但 `rg -o | wc -l` 才是真实出现次数（410）。这和 § 3.3b 的坑 1 是同一个道理。

局限：字符串是**逐单元格**存的，被拆成多段的文本在 XML 里接不上；数值单元格也不一定以文本形式出现。所以这招适合"某个词有没有、几次"，**不适合读表格结构**。

**绕法 B：转成 CSV，再交给 rg / rga / awk**（正规做法，保留行列结构）

```bash
$ python3 - <<'PY'
import os, csv, glob, openpyxl
os.makedirs('/tmp/xlsx2csv', exist_ok=True)
for f in sorted(glob.glob('/tmp/xl/*.xlsx')):
    wb = openpyxl.load_workbook(f, read_only=True, data_only=True)
    out = '/tmp/xlsx2csv/' + os.path.basename(f).replace('.xlsx', '.csv')
    with open(out, 'w', newline='') as fh:
        w = csv.writer(fh)
        for row in wb.active.iter_rows(values_only=True):
            w.writerow(['' if c is None else c for c in row])
    print('转换:', os.path.basename(out))
PY

$ rg -c 'ARDS' /tmp/xlsx2csv/
/tmp/xlsx2csv/基线表1-患者基本信息.csv:382
/tmp/xlsx2csv/基线表2-入ICU时基线资料.csv:4
/tmp/xlsx2csv/基线表3-APACHII评分.csv:4
/tmp/xlsx2csv/基线表4-SOFA评分.csv:4
/tmp/xlsx2csv/结局表1-并发并发症.csv:4
/tmp/xlsx2csv/结局表2-研究结局.csv:4

$ rg -l '机械通气' /tmp/xlsx2csv/
/tmp/xlsx2csv/基线表4-SOFA评分.csv
/tmp/xlsx2csv/结局表1-并发并发症.csv
/tmp/xlsx2csv/结局表2-研究结局.csv
```

转成 CSV 之后，`rg` / `rga` / `awk` / `column` / `sd` 全部可用，而且能按列算（比如"哪些表里 PEEP 列的均值 > 10"）。

**绕法 C：给 rga 写自定义适配器**——rga 支持配置文件（`--rga-config-file`、`--rga-print-config-schema`），理论上可以为 xlsx 定义 `custom_adapters`。**这条我没有实测**，只据 `--help` 里存在这两个开关，别当结论用。

### 3.9 与 rg 的差异清单

| 方面 | `rg` | `rga` |
|------|------|-------|
| 所有 `rg` 选项 | — | **全部可用**（原样透传） |
| 读 stdin | ✅ `cat f \| rg pat` | ❌ |
| 搜二进制格式 | ❌ | ✅（PDF/Office/归档/db/媒体） |
| 速度 | 快 | 慢（抽文本的开销） |
| `-z` 搜压缩 | 单流格式 | 容器格式（zip/tar）也支持 |
| 缓存 | 无 | sqlite+zstd 缓存抽取结果 |
| 适配器相关选项 | 无 | `--rga-*` |
| 二进制文件 | 默认跳过（`binary file matches`） | 交给适配器，抽不出文本就跳过 |

---

## 四、sd（1.0.0）

> 完整用法见 [[sd笔记]]，与 `sed` 的逐项对照见 [[sd-vs-sed-完全指南]]。本节只写**代码里做替换**最相关的部分 + 两个硬限制。

### 4.1 语法与核心差异

```bash
sd '<查找>' '<替换>' [文件...]      # 不写文件 = 读 stdin 写 stdout
sd -p '<查找>' '<替换>' 文件        # 预览，不写盘
```

和 `sed` 的三条根本区别：

1. **默认全局替换**，不用写 `g`。
2. **默认原地修改文件**（相当于 `sed -i`，但**不备份**）。
3. **参数就是两个位置参数**，没有 `s/../../` 那套定界符。

```bash
$ echo 'hello world' | sd 'world' 'there'
hello there

$ echo 'a-b-c' | sd '-' '_'          # 不用 /g，默认全换
a_b_c

$ sd 'AA' 'BB' f1.txt f2.txt         # 多文件原地替换
```

### 4.2 选项实测（v1.0.0 全套）

```bash
$ sd -p 'falcon' 'atlas' p.txt       # -p 预览：高亮改动，不写文件
name: atlas, code: BC-9931           # （终端里 atlas 是彩色反显）
$ cat p.txt                          # 文件内容确实没变
name: falcon, code: BC-9931

$ echo 'a.b.c' | sd -F '.' '_'       # -F 字面量
a_b_c
$ echo 'a.b.c' | sd '.' '_'          # 不加 -F 时 . 是通配符
_____

$ echo '2026-09-20' | sd '(\d+)-(\d+)-(\d+)' '$3/$2/$1'      # 捕获组 $1..$9
20/09/2026
$ echo 'key=value' | sd '(?P<k>\w+)=(?P<v>\w+)' '$v:$k'      # 命名捕获组
value:key

$ echo 'a a a a' | sd -n 2 'a' 'X'   # -n 每文件最多替换几次
X X a a
```

`-f` 正则标志（可组合，如 `-f mc`）：

| 标志 | 含义 | 实测 |
|------|------|------|
| `c` | 区分大小写 | — |
| `i` | 忽略大小写 | `echo 'Hello HELLO hello' \| sd -f i 'hello' 'hi'` → `hi hi hi` |
| `w` | 只匹配整词 | `echo 'cat category' \| sd -f w 'cat' 'dog'` → `dog category` |
| `m` | 多行模式（`^`/`$` 匹配每行） | `printf 'a\nb\n' \| sd -f m 'a\nb' 'AB'` → `AB` |
| `s` | 让 `.` 也匹配换行 | `printf 'a\nb\n' \| sd -f s 'a.b' 'AB'` → `AB` |
| `e` | 关闭多行匹配 | — |

### 4.3 ⚠ 硬限制：Rust regex 不支持环视和反向引用

`sd` 用的是 Rust 的 `regex` 库，**故意不支持**回溯类特性。实测：

```bash
$ echo 'foo' | sd '(?<=f)oo' 'X'         # 后视
error: invalid regex regex parse error:
    (?<=f)oo
$ echo 'aa' | sd '(a)\1' 'X'             # 反向引用
error: invalid regex regex parse error:
    (a)\1
```

这些 `sed` 能做（`sed` 也**不支持**环视，但**支持反向引用**）：

```bash
$ printf 'aa\n' | sed -E 's/(a)\1/X/'    # sed 的反向引用：成功
X
$ echo 'foo' | sed -E 's/f(?=o)/X/'      # sed 也不行（BRE/ERE 都无环视）
sed：-e 表达式 #1，字符 11：前面的正则表达式无效
```

结论表：

| 特性 | `sd` | `sed -E` | `grep -P`（需 PCRE2） |
|------|------|---------|---------------------|
| 反向引用 `\1` | ❌ | ✅ | ✅ |
| 环视 `(?=)` `(?<=)` | ❌ | ❌ | ✅ |
| 命名捕获组 | ✅ `(?P<k>…)` | ❌ | ✅ |
| 惰性量词 `*?` | ✅ | ❌（GNU 也不支持惰性） | ✅ |
| Unicode 属性 `\p{Han}` | ✅ | ❌ | ✅ |

**碰到需要反向引用/环视的替换，别硬用 `sd`**：要么用 `perl -pe`，要么 `grep -oP` 提取后再拼（本机 rg 无 PCRE2，但 `grep -P` 可用）。

### 4.4 sd 不能做的事

| 不行 | 替代 |
|------|------|
| 删行/插行/跨行编辑 | `sed`/`awk` |
| 一次执行多条替换 | 串两次 `sd`（`sd a b \| sd c d`，但注意文件 vs 管道） |
| 无备份的原地修改（**默认行为，很危险**） | 先 `git commit`，或 `sd -p` 预览，或复制一份 |
| 用退出码判断"是否替换过" | 实测 **没匹配也返回 0**，不能做脚本判断；需要判断时用 `grep -q` 先探 |
| 指定编码/处理二进制 | `sd` 不做，用 `iconv`/`rg --encoding` |

---

## 五、三件套 vs 三剑客：能力对照

| 能力 | grep | sed | awk | rg | rga | sd |
|------|:----:|:---:|:---:|:--:|:---:|:--:|
| 找文本 | ✅ | 部分 | ✅ | ✅ | ✅ | ❌ |
| 默认递归 | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ |
| 尊重 `.gitignore` | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ |
| 并行 | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ |
| 读 PDF/Office/归档/db | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| 读 stdin | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| 替换 | ❌ | ✅ | ✅ | 仅预览 | 仅预览 | ✅ |
| 改文件 | ❌ | `-i`(+备份) | 手写重定向 | ❌ | ❌ | 默认原地(无备份) |
| 删行/插行/跨行 | ❌ | ✅ | ✅ | 多行匹配 | ❌ | ❌ |
| 按列计算/统计 | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| 反向引用 | 部分 | ✅ | ✅ | ❌ | ❌ | ❌ |
| 环视 | `-P` | ❌ | ❌ | `-P` | `-P` | ❌ |
| 可移植性 | POSIX | POSIX | POSIX | 需另装 | 需另装+外部工具 | 需另装 |

**选型口诀：**

- 找东西 → `rg`；找不到就上 `rga`；在**二进制格式里**找 → 直接上 `rga`。
- 换东西 → 文件里换用 `sd`，管道里换用 `sed`。
- 算东西 → `awk`。
- 写进要给别人用的脚本 → `grep`/`sed`/`awk`（POSIX 保证存在）。

---

## 六、组合流水线

```bash
# 1) rg 粗筛出候选文件 → sd 批量替换（最常用的重构姿势）
rg -l 'old_function_name' -t py | xargs sd 'old_function_name' 'new_function_name'
# 先看会改哪些
rg -l 'old_function_name' -t py

# 2) rga 深挖：在整个资料库里找某个合同编号（含 PDF/Word/Excel 导出件）
rga -l 'BC-9931' ~/Documents --rga-adapters=-mail

# 3) PDF 转文本 → 三剑客处理
rga-preproc annual.pdf | rg -n 'revenue|收入' | head

# 4) rga ─→ 只看某个适配器结果，再交给 rg 的其它选项
rga --rga-adapters=poppler -l 'confidential' .        # 哪些 PDF 里提到了
rga --rga-adapters=poppler -c 'confidential' . | sort -t: -k2 -rn | head   # 按出现次数排

# 5) 归档里找文件并抽取（rga + rg 的 --files 思路）
rga --rga-no-prefix-filenames -l 'api_key' bundle.zip

# 6) sd 替换前先算清楚影响面
rg -c 'timeout: 30' -t yaml | sort -t: -k2 -rn      # 哪些文件最多
rg -l 'timeout: 30' -t yaml | xargs sd 'timeout: 30' 'timeout: 60'
```

---

## 七、坑清单

| # | 坑 | 正解 |
|---|-----|------|
| 1 | 本机 `rg` **没有 PCRE2**，`-P`/环视/`\K` 全废 | 换官方二进制或 `cargo install ripgrep --features pcre2`；或改用 `grep -P`（本机可用） |
| 2 | 以为 `rg -z` 能搜 zip | 那是 `rga` 的活；`-z` 只管 gz/bz2/xz/zst 这类单流 |
| 3 | `rg -z` 对 `tar.gz` "搜到了"其实是假阳性 | 搜归档用 `rga` |
| 4 | `rga` 用管道喂不进去 | `cat f \| rga pat` 无输出；先落盘 |
| 5 | `--rga-adapters=-pandoc` 后 html/ipynb 还在 | 它们是纯文本，rg 直接搜，适配器管不着 |
| 6 | 文件被改名/无扩展名时 `rga` 搜不到 | 加 `--rga-accurate` |
| 7 | 以为 rga 能搜 xlsx | 0.10 **没有 xlsx 适配器**，而且静默返回空（见 § 3.8.1 的两种绕法） |
| 8 | 扫描版 PDF 搜不到 | 无文本层就没救，`rga` 没有 OCR |
| 9 | 归档内层路径被当成搜索内容 | `--rga-no-prefix-filenames` |
| 10 | 以为 rga 缓存没用（或以为一定更快） | 真实文件实测收益 **12–36 倍**（§ 3.6）；但**必须禁用 `-q` 和 `>/dev/null` 才能测准** |
| 10b | `--rga-no-cache` 在 0.10.10 上会让需要适配器的文件全部失败（`Error: during preprocessing … 1: No cache?`，exit=2） | 用 `--rga-cache-path=<空目录>` 代替，或直接删缓存目录重跑 |
| 10c | 用 `-c` 跨格式比关键词数量 | `-c` 数的是行数：同一文档 PDF 119 行 / DOCX 73 行，但出现次数都是 121 / 119。**要用 `-o \| wc -l`** |
| 11 | `sd` 默认**原地修改且不备份** | 先 `git commit`，或 `sd -p` 预览 |
| 12 | `sd` 的 `.` 不加 `-F` 就是通配符 | 字面量替换一律 `-F` |
| 13 | `sd` 不支持 `(?<=)`/`\1` | 用 `perl -pe` 或 `grep -oP` + 拼接 |
| 14 | 用 `sd` 的退出码判断有没有替换 | 实测没匹配也返回 0；先用 `rg -q`/`grep -q` |
| 15 | 以为 `sd` 能替代 `sed` 的删行/插行 | 不能，它只会替换 |
| 16 | 在脚本里用 `rg`/`sd` 却不检查是否存在 | 给别人用的脚本用 `grep`/`sed`，或先探测命令 |

---

## 八、速查卡

### rg

```bash
rg pat                      # 递归找（默认带行号、跳 .gitignore/隐藏文件）
rg -t py pat                # 只在 python 文件里
rg -T py pat                # 排除 python 文件
rg -g '*.md' -g '!docs/**' pat
rg -l pat / -c pat / -o pat # 只列文件 / 计数 / 只出匹配
rg -i / -s / -S pat         # 忽略大小写 / 区分 / 智能（默认）
rg -w pat / -F pat          # 整词 / 字面量
rg -A3 -B3 -C3 pat          # 上下文
rg --hidden --no-ignore pat # 连隐藏文件和被忽略的一起搜
rg -uuu pat                 # 彻底放开（-u 叠加三次）
rg -r NEW pat f             # 预览替换（不写文件）
rg --files                  # 只列文件
rg -z pat f.gz              # 搜单流压缩（gz/bz2/xz/zst，不含 zip）
rg -U 'a\n.*b'              # 多行匹配
rg --json pat               # 机器可读输出
rg --stats pat              # 统计信息
rg --type-list              # 所有内置类型
rg --sort path pat          # 确定性排序（默认并行、顺序不定）
```

### rga

```bash
rga pat .                          # 跨格式搜索
rga -l PAT .                       # 只列文件名
rga --rga-adapters=poppler pat .   # 只用某些适配器
rga --rga-adapters=-pandoc pat .   # 排除某些适配器
rga --rga-adapters=+mail pat .     # 启用默认禁用的
rga --rga-accurate pat .           # 按 magic bytes 判断类型（扩展名骗人时）
rga --rga-no-cache pat .           # 禁用缓存
rga --rga-no-prefix-filenames pat x.zip   # 不显示归档内层路径
rga -o 'PAT' f.pdf | wc -l         # 真实【出现次数】（-c 只数行数）
rga --rga-cache-path=/tmp/fc pat .  # 换/清缓存（代替坏掉的 --rga-no-cache）
# ⚠ 0.10.10 的 --rga-no-cache 是坏的，会用不了适配器（见 § 3.6）
rga --rga-list-adapters            # 列适配器
rga --rga-print-config-schema      # 配置文件的 JSON Schema
rga --rg-version / --rg-help       # 看内嵌的 rg 版本 / 完整 rg 帮助
rga-preproc file.pdf               # 单独把文件抽成纯文本
```

### sd

```bash
sd 'old' 'new'                     # stdin → stdout
sd 'old' 'new' f1 f2               # 原地改文件（无备份！）
sd -p 'old' 'new' f                # 预览，不写盘
sd -F '.' '_'                      # 字面量
sd -n 2 'a' 'X'                    # 最多替换 2 次
sd -f i 'a' 'b'                    # 忽略大小写（c/i/w/m/s/e 可组合）
sd '(\w+)=(\w+)' '$2:$1'           # 捕获组
sd '(?P<k>\w+)=(?P<v>\w+)' '$v:$k' # 命名捕获组
rg -l pat -t py | xargs sd pat NEW # 批量重构
```

---

## 附录 A：真实测试素材

`~/Desktop/test`（本文 § 3.3b / § 3.6 / § 3.8.1 用的就是这三份）：

| 文件 | 大小 | 内容 / 备注 |
|------|------|------------|
| `ARDS_Review.pdf` | 2.3 MB | Typst 排版的 VILI/ARDS 综述，**有文本层**；pdftotext 单独跑 0.112 s，抽出 230,219 字节 |
| `ARDS_Review.docx` | 1.7 MB | 同一篇的 Word 版；pandoc 转换慢（冷启动 0.468 s），抽出 217,865 字节 |
| `整理结果.zip` | 796 KB | 6 个 xlsx（基线表1-4、结局表1-2）；**rga 搜不了**，需用 § 3.8.1 的绕法 |

常用命令：

```bash
# 扫整个目录（自动跳二进制、能在 PDF/docx 里找到）
rga -l 'PEEP|ARDS' ~/Desktop/test

# 真实次数（不是行数）
rga -o 'ARDS' ~/Desktop/test/ARDS_Review.pdf | wc -l

# 绕过缓存重跑一次干净搜索
rga --rga-cache-path=/tmp/fc-$(date +%s) -l 'VILI' ~/Desktop/test

# 把 PDF 转成文本，交给 grep/sd/awk
rga-preproc ~/Desktop/test/ARDS_Review.pdf > /tmp/ards.txt

# zip 里 6 个 xlsx：扒 XML 数次数
mkdir -p /tmp/xl && unzip -oq ~/Desktop/test/整理结果.zip -d /tmp/xl
for f in /tmp/xl/*.xlsx; do
  printf '%-40s %s\n' "$(basename "$f")" "$(unzip -p "$f" 'xl/worksheets/*.xml' | rg -o 'ARDS' | wc -l)"
done
```

---

## 附录 B：本文用到的合成样本

```bash
# 目录：/tmp/modern
# PDF（typst 造的，带文本层）
cat > doc.typ <<'EOF'
#set page(width: 12cm, height: 6cm)
= Quarterly Report
The migration to the new billing cluster finished on schedule.
Total revenue recognised was 48213 USD.
Internal codename for the project is "falcon-north".
EOF
typst compile doc.typ doc.pdf

# docx / odt / epub / html / ipynb（pandoc）
cat > memo.md <<'EOF'
# Migration Memo

The falcon-north project moved to cluster `atlas-7` in September.
Owner: ops-team. Budget code: BC-9931.
EOF
pandoc memo.md -o memo.docx
pandoc memo.md -o memo.odt
pandoc memo.md -o memo.epub
pandoc memo.md -o memo.html
pandoc memo.md -o memo.ipynb

# 压缩包（含嵌套 / 单流）
mkdir -p pkg
printf 'budget code BC-9931 lives in this plain text file\n' > pkg/notes.txt
printf 'secret token: falcon-north\n' > pkg/inner.md
zip -qr bundle.zip pkg
tar czf bundle.tar.gz pkg
gzip -c pkg/notes.txt > notes.txt.gz
bzip2 -c pkg/notes.txt > n.bz2
xz -c    pkg/notes.txt > n.xz
zstd -q -c pkg/notes.txt > n.zst
mkdir -p pkg2 && zip -qr pkg2/deep.zip pkg && zip -qr nested.zip pkg2

# sqlite（python 内建模块即可）
python3 - <<'PY'
import sqlite3
c=sqlite3.connect('app.db')
c.execute("create table users(id integer, name text, note text)")
c.executemany("insert into users values(?,?,?)",
  [(1,'alice','falcon-north rollout'),(2,'bob','budget BC-9931'),(3,'carol','billing cluster')])
c.commit(); c.close()
PY

# mp3 元数据（ffmpeg）
ffmpeg -f lavfi -i anullsrc=r=8000:cl=mono -t 1 \
  -metadata title="falcon-north review BC-9931" -metadata artist="ops-team" \
  -c:a libmp3lame tone.mp3

# xlsx（用来证明 rga 不支持它）
python3 -c "
import openpyxl
wb=openpyxl.Workbook(); ws=wb.active
ws.append(['item','amount']); ws.append(['falcon-north license','1200'])
wb.save('book.xlsx')"

# 性能测试树：20 目录 × 250 文件，共 5000 个 / 59 MB
python3 - <<'PY'
import os, random
random.seed(7)
words=['alpha','beta','gamma','falcon','delta','atlas','epsilon','zeta']
for d in range(20):
    os.makedirs(f'd{d:02d}', exist_ok=True)
    for f in range(250):
        with open(f'd{d:02d}/f{f:03d}.txt','w') as fh:
            for i in range(200):
                fh.write(' '.join(random.choices(words,k=8))+'\n')
PY
```

---

## 相关笔记

- [[ripgrep使用指南]] —— `rg` 的完整用法（含 `--pre`、`.ignore`、类型过滤、配置文件）
- [[sd笔记]] —— `sd` 的完整用法
- [[sd-vs-sed-完全指南]] —— `sd` 与 `sed` 的逐项对照
- [[文本处理三剑客]] —— `grep`/`sed`/`awk`/`column`：经典工具的完整参考，含性能实测与坑清单
- [[文本处理三剑客#八、让输出对齐：column]] —— `column` 把检索结果排成表格
- [[xargs-tutorial]] —— `rg -l ... | xargs sd ...` 这条流水线的另一半
- [[fd使用指南]] —— `fd`：`find` 的现代替代（和 `rg` 同属"新工具"）
- [[eza常见用法]] —— `eza`：`ls` 的现代替代
- [[fzf-fzf.fish快捷键及用法]] —— 把 `rg`/`rga` 的结果接进模糊查找
