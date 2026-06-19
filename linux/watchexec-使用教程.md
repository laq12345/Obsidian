# watchexec 使用教程

## 这是什么？

watchexec 是一个**文件监控工具** — 你告诉它「盯着这些文件，变了就跑某个命令」。做分析时不用手动 rerun，文件一保存就自动触发。

```
watchexec -e py -- python analysis.py
# 只要 .py 文件变了，自动重跑
```

## 安装

```bash
cargo install watchexec-cli
```

已安装，确认版本：

```bash
watchexec --version
# watchexec 2.5.1
```

## 快速上手

### 基础用法

最简单的形式 — 监控当前目录，任何文件变了就执行命令：

```bash
watchexec echo "文件变了！"
```

> **默认行为**：启动时先跑一次命令，然后开始监控。之后每次检测到变化都重新跑。

### 场景 1：Python 脚本改了就 rerun

```bash
watchexec -e py -- python analysis.py
```

`-e py` 表示只关心 `.py` 文件。编辑器中保存脚本 → 终端自动 rerun。

### 场景 2：R Markdown / Quarto 文档自动渲染

```bash
watchexec -e Rmd -c -- quarto render report.qmd
```

`-c`（`--clear`）每次跑前清屏，输出不堆叠。

### 场景 3：Snakemake / Nextflow 等管线修改后重跑

```bash
watchexec -e smk -- snakemake --cores 8
```

### 场景 4：服务器开发模式（重启）

```bash
watchexec -e js,ts -r -- node server.js
```

`-r`（`--restart`）是 watchexec 的王牌功能：如果旧进程还在跑，先优雅停掉再启动新的。

### 场景 5：只监控特定目录

```bash
watchexec -w src/ -w data/ -- python pipeline.py
```

`-w`（`--watch`）可以多次使用，只关心这两个目录。

---

## 必知概念

### 1. 启动时先跑一次（默认）

默认 watchexec 启动就会执行一次命令，然后才开始监控。如果不想这样（希望等第一次文件变化才跑），加 `--postpone`（短选项 `-p`）：

```bash
watchexec -p -- python analysis.py   # 等文件变了才第一次跑
```

### 2. 防抖（debounce）

你保存文件时，编辑器可能触发多次事件。watchexec 默认等 50ms 收拢事件后再行动：

```bash
watchexec --debounce 200ms -- python analysis.py   # 等 200ms
watchexec -d 1s -- python analysis.py              # 等 1 秒
```

太长（比如 `30s`）可以用作省电/省带宽的定时备份。

### 3. .gitignore 感知

watchexec **自动读取 .gitignore**，不会因为 `node_modules/`、`_freeze/`、`.snakemake/` 等目录变化而触发重跑。可以加 `--no-vcs-ignore` 强制包括被 gitignore 的文件。

---

## 常用选项速查

| 选项 | 含义 | 例子 |
|------|------|------|
| `-e, --exts` | 只监控特定扩展名 | `-e py,R` |
| `-w, --watch` | 指定监控路径 | `-w src/ -w data/` |
| `-c, --clear` | 跑命令前清屏 | `-c` |
| `-r, --restart` | 进程还在跑就先停后启 | `-r` |
| `-p, --postpone` | 启动时不跑，等第一次文件变化 | `-p` |
| `-d, --debounce` | 防抖时间 | `-d 100ms` |
| `-i, --ignore` | 忽略匹配的文件 | `-i "*.log"` |
| `-f, --filter` | 只匹配特定文件 | `-f "*.csv"` |
| `-n` | 不用 shell（直接 exec） | `-n` |
| `--no-vcs-ignore` | 不忽略 .gitignore 里的文件 | `--no-vcs-ignore` |
| `--exit-on-error` | 命令失败时退出 watchexec | `--exit-on-error` |
| `--shell` | 指定 shell | `--shell=bash` |
| `--stop-timeout` | 重启时等旧进程退出多久 | `--stop-timeout 5s` |
| `--notify` | 跑完发桌面通知 | `-N` |
| `--timings` | 打印命令耗时 | `--timings` |
| `--bell` | 跑完响铃 | `--bell` |

---

## Glob 模式详解（官方文档重点）

`--filter`（`-f`）和 `--ignore`（`-i`）使用的 glob 规则基于 **globset** 库，匹配的是文件的**完整绝对路径**，这点容易踩坑：

| 通配符 | 含义 |
|--------|------|
| `?` | 匹配单个字符 |
| `*` | 匹配零或多个字符，**不跨目录分隔符** |
| `**` | 匹配零或多个字符，**可以跨目录** |
| `{a,b}` | 匹配 a 或 b（不支持嵌套） |
| `[ab]` | 匹配字符 a 或 b |

**实际使用中的坑（官方文档特别强调）：**

- 匹配基于**完整绝对路径**，不是相对路径。所以模式最好以 `*/` 开头
- `-i data/` 并不能忽略 `data/` 里的文件 — 事件携带的是文件本身的路径。应该用 `-i "*/data/**/*"`
- 如果你的项目路径是 `/home/user/project/test/data`，模式 `*/data/**/*` 会意外匹配到所有事件（因为路径中含 `data`），导致全部被忽略

**踩坑对照表：**

```
# ❌ 不工作
-i data/
-i log.txt

# ✅ 正确写法
-i "*/data/**"
-i "**/log.txt"
-i "*.pyc"
```

## Linux inotify 限制（官方文档）

watchexec 在 Linux 上依赖 **inotify**（内核文件系统监控机制）。inotify 有三个关键限制：

| 限制项 | 默认值 | 说明 |
|--------|--------|------|
| `max_user_watches` | 8192 | **最大监控文件数**（最常触发） |
| `max_user_instances` | 128 | 同时运行的应用数 |
| `max_queued_events` | 16384 | 内核事件队列大小（很少出问题） |

当监控大型项目目录（如包含几十万文件的单细胞数据目录）时，你可能会看到：

```
No space left on device — Failed to watch "..."
```

这是 **inotify watch 用完了**，不是硬盘满了。修法：

```bash
# 临时生效（重启丢失）
sudo sysctl fs.inotify.max_user_watches=65536

# 永久生效
echo "fs.inotify.max_user_watches=65536" | sudo tee /etc/sysctl.d/inotify.conf
```

每个 inotify watch 大约消耗 1080 bytes 内核内存（64 位），65536 个 ≈ 70MB，安全合理。如果你监控超大型目录（比如整个 home），可以设到 524288。

---

## 进阶用法

### 用 shell 管道和重定向

watchexec 默认把命令丢给 shell（`/bin/sh`）执行，所以管道、重定向、变量展开都能用：

```bash
watchexec -- "echo '分析完成' | tee -a log.txt"
```

如果不想经过 shell（性能稍好、更安全），加 `-n`：

```bash
watchexec -n -- python analysis.py
```

### 交互模式：按 r 重启、p 暂停、q 退出

```bash
watchexec -I -- python server.py
```

`-I` 进入交互模式，按 `r` 手动重启、`p` 暂停/恢复监控、`q` 退出。适合调试场景。

### 监控特定类型的事件

```bash
watchexec --fs-events create,remove -- python deploy.py
```

只关心文件**创建**和**删除**，忽略修改。可选的类型：`access`, `create`, `remove`, `rename`, `modify`, `metadata`。

### 排除文件

```bash
watchexec -i "*.log" -i "*.tmp" -- python analysis.py
```

`-i` 使用 glob 模式排除匹配的文件。

### 加载忽略规则文件

```bash
watchexec --ignore-file .watchexec-ignore -- python analysis.py
```

可以创建 `.watchexec-ignore` 文件，格式同 `.gitignore`。

### 保存 watchexec 参数到文件

```bash
# 创建参数文件
echo "-e R" > args.txt
echo "-w R/" >> args.txt
echo "-- quarto render report.qmd" >> args.txt

# 用 @ 引用
watchexec @args.txt
```

### 给命令传环境变量

```bash
watchexec -E LOG_LEVEL=debug -E THREADS=8 -- python analysis.py
```

只传给子进程，不影响 watchexec 自己。

---

## 生信实战场景

### 场景 A：边写边渲染 Quarto 报告

```bash
watchexec -e qmd,R -c -- quarto render paper.qmd
```

### 场景 B：修改 scanpy 脚本后自动 rerun

```bash
watchexec -e py -c -- pixi run python cluster_analysis.py
```

### 场景 C：监控数据文件，有新数据就重跑

```bash
watchexec -e h5ad,csv -- python full_pipeline.py
```

### 场景 D：重启 Shiny / Flask 服务器

```bash
watchexec -e R -r -- Rscript -e "shiny::runApp()"
```

`-r` 是关键 — 旧 server 先停，新 server 再起。

### 场景 E：同时监控多个目录

```bash
watchexec -w src/ -w notebooks/ -e py,ipynb -- python scripts/render_all.py
```

### 场景 F：自动备份数据

```bash
watchexec --postpone --fs-events create -- rsync -av data/ backup/
```

### 场景 G：命令太耗时，超时终止

```bash
watchexec -e py --timeout 30m -- python long_training.py
```

每次超过 30 分钟就自动杀掉，等下次保存再重试。

---

## 注意事项

### 1. 编辑器保存文件的方式

有些编辑器（Vim、nano）保存文件时不是修改原文件，而是**创建新文件再重命名**（`write`→`rename`）。这种情况下监控单个文件可能漏掉事件。**推荐监控整个目录**，而不是单个文件：

```
# 不推荐
watchexec -w report.qmd -- quarto render report.qmd

# 推荐（监控当前目录，只触发 .qmd 变化）
watchexec -e qmd -- quarto render report.qmd
```

### 2. 命令里带参数时用 `--` 分隔

```
watchexec -- rsync -av --delete src/ dest/
```

`--` 告诉 watchexec：后面都是要执行的命令，不是 watchexec 自己的选项。不然 `--delete` 会被误认为是 watchexec 的参数。

### 3. 循环触发

如果命令会修改被监控的文件（比如 `quarto render` 产生了 HTML），而 HTML 恰好在监控范围内且没被 ignore，就可能导致无限 rerun。解决方案：

- 把输出目录加到 `.gitignore`（watchexec 自动读取）
- 用 `-e` 限制只监控特定扩展名
- 用 `-i "_book/"` 排除输出目录

### 4. 默认忽略的格式

watchexec 内置忽略：`*.pyc`、`*.pyo`、`.DS_Store`、`.git/`、`.hg/`、`.svn/`、`.bzr/`、编辑器临时文件等。用 `--no-default-ignore` 关闭。

---

## 与 entr 的对比

| 对比项 | watchexec | entr |
|--------|-----------|------|
| 安装方式 | cargo install | dnf install / apt install |
| 二进制大小 | ~5MB（Rust） | ~30KB（C） |
| .gitignore 感知 | 内置自动 | 需手动处理 |
| 防抖（debounce） | 内置（默认 50ms） | 无 |
| 重启进程 | `-r` 搞定 | 需手动写 wrapper |
| 启动时先跑一次 | 默认启动时就跑 | 需手动加 trick |
| 桌面通知 | `-N` | 无 |
| 过滤事件类型 | `--fs-events` | 有限 |
| 跨平台 | Windows / macOS / Linux | 仅 Unix-like |
| 适用场景 | 开发服务器、复杂分析管线 | 极简监控 |

你选择 watchexec 完全合理 — entr 的优势（极小二进制）对你来说没意义，而 watchexec 的 `.gitignore` 感知、重启模式、事件过滤在日常分析中更实用。

---

## 一键生成 bash 补全

```bash
watchexec --completions fish > ~/.config/fish/completions/watchexec.fish
# 你的 shell 是 fish，装完重启终端即可 Tab 补齐
```

---

## 速查卡片

```bash
# 最常用
watchexec -e py -c -- python script.py         # Python 脚本
watchexec -e Rmd -c -- quarto render doc.qmd   # Quarto 渲染
watchexec -e R -r -- Rscript app.R             # R 服务器重启
watchexec -e smk -c -- snakemake -j8           # Snakemake 管线

# 监控控制
watchexec -w src/ -w lib/ -e py                # 只监控某些目录
watchexec -i "*.log" -i "*.tmp"                # 排除文件
watchexec --no-vcs-ignore                       # 包括 gitignore 的文件

# 运行模式
watchexec -p                                    # 等第一次变化再跑
watchexec -r                                    # 进程重启模式
watchexec -I                                    # 交互模式（r/p/q）
watchexec -N                                    # 跑完发通知
watchexec -d 200ms                              # 调防抖时间

# 调试
watchexec --print-events                        # 看触发了什么事件
watchexec -vvv --log-file ./                    # 详细日志分析
```
