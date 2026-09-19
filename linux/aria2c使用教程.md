---
time: 2026-09-19T11:10:00
lang: Linux
tags:
  - 工具
  - linux
  - aria2
  - 下载
  - 命令行
---

# aria2c 使用教程

> 一个命令行的多协议、多线程、多任务下载器。
> 本机版本：**aria2 1.37.0**（`/var/home/smile/.pixi/bin/aria2c`，由 pixi 安装）
> 已启用功能：Async DNS、BitTorrent、Firefox3 Cookie、GZip、HTTPS、Message Digest、Metalink、XML-RPC、SFTP
> 本文所有选项说明与默认值均取自本机 `aria2c --help=#all` 输出，并在本机实测验证（见文末「实测记录」）。

---

## 一、它是什么，为什么用

`aria2c` 是**非交互式**命令行下载工具，一个进程就能同时干下面这些事：

| 能力 | 说明 |
| --- | --- |
| **多协议** | HTTP / HTTPS / FTP / SFTP / BitTorrent / Metalink |
| **单文件多连接** | 把一个文件切成多段并行下载（传统下载器叫「多线程」） |
| **多任务并发** | 同时下载多个不同文件 |
| **断点续传** | 中断后继续，靠 `*.aria2` 控制文件记录进度 |
| **BitTorrent** | 支持 `.torrent`、磁力链、DHT、PEX、LPD、做种 |
| **Metalink** | 一个文件多镜像 + 校验值，自动挑最快镜像 |
| **RPC 远程控制** | JSON-RPC / XML-RPC，可被 AriaNg、Motrix 等图形前端驱动 |
| **事件钩子** | 下载开始/完成/出错时调用外部脚本 |

**和 `curl` / `wget` 的区别**：那两者是「取一个东西」，aria2c 是「把下载这件事本身当成一个任务管理器」。真正的差异化能力是**分片并发 + 断点续传 + 批量会话 + RPC**。

> [!note] 项目现状
> **1.37.0（2023-11-15）至今仍是唯一的稳定版**，上游开发非常缓慢。这有两个实际影响：
> 1. 功能和选项基本冻结，本文写的就是最终形态；
> 2. 不存在「等等就好」的新特性，需要新特性得看 fork（如 aria2-next）或换工具。
>
> 好消息是它已经很稳定，协议层面该有的都有。

---

## 二、基本语法

```bash
aria2c [选项...] [URI | 磁力链 | torrent文件 | METALINK文件]...
```

它接受四类输入源，可以混着给：

```bash
aria2c https://example.com/a.iso                       # 普通 URL
aria2c magnet:?xt=urn:btih:xxxxxxxx                     # 磁力链
aria2c ./debian.torrent                                 # 本地种子文件
aria2c ./fedora.meta4                                   # Metalink 文件
aria2c https://a.com/1.iso https://a.com/2.iso          # 多个 URL（合并处理）
```

### 2.1 选项的三种来源与优先级（实测，反直觉）

同一个选项可以从三个地方给。**优先级从高到低**：

```
① -i 输入文件里每行 URI 后的缩进行内选项
② 命令行的选项
③ 配置文件（aria2.conf）里的选项
```

> [!warning] 反直觉之处
> **输入文件里的选项会覆盖命令行选项**，不是反过来。实测：
>
> ```bash
> # 输入文件 prio2.txt 里写了 dir=/tmp/aria2lab/dl
> aria2c -q -i prio2.txt -d /tmp/aria2lab/srv http://127.0.0.1/small.txt
> # 结果：文件落在 /tmp/aria2lab/dl，命令行的 -d 被忽略
> ```
>
> 所以批量脚本里如果发现「命令行改了参数却不生效」，先检查 `-i` 文件里有没有同名选项。

### 2.2 查看帮助的方式

```bash
aria2c -h                    # #basic 标签的常用选项（默认）
aria2c --help=#all           # 全部选项，很长，适合重定向到文件查
aria2c --help=#advanced      # 按标签：basic/advanced/http/https/ftp
                             # metalink/bittorrent/cookie/hook/file
                             # rpc/checksum/experimental/deprecated/help
aria2c --help=http           # 只要 HTTP 相关的（也可以给关键词）
aria2c -v                    # 版本 + 编译特性 + 支持的哈希算法
```

---

## 三、输出位置：`-d` / `-o` / 重命名 / 覆盖

这一组选项是新手最容易踩坑的地方，单独讲清楚。

### `-d, --dir=<目录>`

保存目录。**默认是当前工作目录**（注意：`aria2c --help` 里显示的「默认」是打印帮助那一刻的 CWD，别被它误导）。

```bash
aria2c -d ~/Downloads https://example.com/a.iso
```

### `-o, --out=<文件名>`

指定输出文件名。**始终相对于 `-d` 指定的目录**，所以它不能和 `-d` 打架：

```bash
aria2c -d ~/Downloads -o ubuntu.iso https://example.com/a.iso
# 结果：~/Downloads/ubuntu.iso
```

> [!warning] `-o` 与 `-Z` 互斥
> 使用 `-Z, --force-sequential` 时，**`-o` 会被忽略**（因为一个会话里可能有好几个文件，一个名字不够用）。

**不指定 `-o` 时文件名从哪来？** 优先用服务器返回的 `Content-Disposition` 头里的文件名，否则从 URL 末段推导。实测：带 `filename*=UTF-8''测试文件.bin` 的响应会直接存成 `测试文件.bin`。

### `-O, --index-out=<索引>=<路径>`

用于**一个种子/Metalink 里含多个文件**的场景，逐个指定某文件的输出路径（路径相对于 `-d`）。可以重复使用：

```bash
aria2c -S ./big.torrent                       # 先看文件索引
aria2c -T ./big.torrent \
  -O 1=video.mp4 -O 2=audio.m4a               # 再按索引改名
```

配套的 `-S, --show-files` 只列出种子/Meta4/Metalink 里的文件清单然后退出，不下载。是 `-O` 和 `--select-file` 的前置步骤。

### `--auto-file-renaming`（默认 `true`）与 `--allow-overwrite`（默认 `false`）

两者共同决定「目标文件已存在时怎么办」：

| 场景 | 默认行为 |
| --- | --- |
| 同名文件已存在 | **自动重命名**：在文件名后、扩展名前插入 `.1`、`.2`…… |
| 同名文件已存在，且设置了 `--auto-file-renaming=false` | **直接报错退出**，退出码 `13` |
| `--allow-overwrite=true` | **覆盖**已有文件 |

```bash
# 实测：r.txt 已存在时
aria2c -o r.txt URL                # → 存成 r.1.txt
aria2c --auto-file-renaming=false -o r.txt URL   # → 报错，exit 13
aria2c --allow-overwrite=true -o r.txt URL       # → 覆盖 r.txt
```

重命名插入的是 `.X` 且**在扩展名之前**，所以用 `ls r.txt*` 是看不到 `r.1.txt` 的 —— 找文件时别被 glob 骗了。

> [!tip] 什么时候需要 `--allow-overwrite=true`
> **配合 `-c` 续传单个文件时**要小心：`-c` 需要目标文件存在才能续。如果因为 `--auto-file-renaming` 默认开着而新建了 `file.1`，续传就变成了一次全新下载。定点续传一个已知文件名时，常见组合是：
> ```bash
> aria2c -c --auto-file-renaming=false -o big.iso URL
> ```

---

## 四、分片与并发：`-s` / `-x` / `-k` / `-j`

这是 aria2c 的核心性能选项，**也是配置最容易抄错的地方**。

### `-s, --split=N`（默认 `5`）

把一个文件切成 N 段并行下载。N 是「我希望能用这么多连接」，**不是保证能达到的数字**。

### `-x, --max-connection-per-server=N`（默认 `1`，范围 **1–16**）

对**单个服务器**的最大连接数。

> [!warning] 只调 `-s` 是没用的
> `-x` 默认只有 **1**。也就是说 `aria2c -s16 URL` 实际上仍然是单连接。**要提速必须同时给 `-x`**：
> ```bash
> aria2c -x16 -s16 -k1M URL      # 这才是真正的 16 连接
> ```
> `-x` 上限是 16，给 `-x20` 会直接报错退出（`errorCode=28`）。

### `-k, --min-split-size=<大小>`（默认 `20M`，范围 1M–1G）

**aria2 不切分小于 `2 × <大小>` 的下载区间**。这是「分片粒度下限」，决定了一个文件最多能被切成几块：

- 20 MiB 的文件 + `-k10M` → 最多 2 块（`2×10M ≤ 20M`）→ 最多 2 个连接
- 20 MiB 的文件 + `-k15M` → 不分片（`2×15M > 20M`）→ 1 个连接

**所以小文件配大 `-k` 时，`-s16` 完全不起作用。** 下载小文件想多连接，必须把 `-k` 调小。

**实际并发连接数的三条约束**（取最小者）：

```
  实际连接数 = min( -s 的值,
                    -x 的值 × 可用镜像数,
                    文件大小 ÷ (2 × -k 的值) )
```

### `-j, --max-concurrent-downloads=N`（默认 `5`）

**同时下载多少个不同的任务**（URL / 种子 / Metalink 各算一个）。注意它和 `-s` 的区别：

| 选项 | 控制的是 | 类比 |
| --- | --- | --- |
| `-j` | 同时下几个**文件** | 几辆车同时上路 |
| `-s` / `-x` | 一个文件用几条**连接** | 一辆车占几条车道 |

```bash
# 同时下 3 个文件，每个文件 16 条连接
aria2c -j3 -x16 -s16 -k1M URL1 URL2 URL3
```

配套的 `--optimize-concurrent-downloads=true|false|A:B`（默认 `false`）会根据历史测速**自动调整**并发数，公式 `N = A + Blog10(速度Mbps)`，默认 `A=5,B=25`。省事但不精确，一般还是手动给 `-j` 更可控。

### `-Z, --force-sequential`（默认 `false`）

**默认**行为：命令行给的多个 URL 会被当作**同一个文件的不同镜像**，合并成一个下载任务，互相接力/备份。

**加 `-Z`**：每个 URL 当作**独立任务**逐个下载，就像 `wget` 那样。

```bash
aria2c    URL1 URL2        # 视为同一文件的 2 个镜像
aria2c -Z URL1 URL2        # 视为 2 个不同文件，依次下载
```

> [!tip] 什么时候必须加 `-Z`
> 下**不同文件**的多个 URL 时。如果不加 `-Z`，aria2 会认为它们在提供同一个文件，只下一个名字，另一个只作为镜像备用。而 `-P` 参数化 URI 展开出多个不同文件时，**`-Z` 是必需的**。

---

## 五、断点续传与控制文件

aria2 的续传靠一个隐藏的**控制文件** `文件名.aria2`，里面记录分片位图和进度，默认每 60 秒写一次。

### `-c, --continue`（默认 `false`）

继续下载一个**部分完成**的文件。

**关键区别**：
- **有 `.aria2` 控制文件**时，续传是**自动**的，不需要 `-c`。
- **没有控制文件**（比如用浏览器下了一半、或者 `aria2c` 被非正常清掉了控制文件）时，**必须加 `-c`** 才能从已有字节继续。

```bash
# 浏览器下了一半的文件，用 aria2c 接手
aria2c -c -o big.iso https://example.com/big.iso
```

> [!warning] `-c` 只对 HTTP(S)/FTP 有效
> BitTorrent / Metalink 的续传走各自的机制，`-c` 对它们无意义。

### 控制文件相关选项

| 选项 | 默认 | 作用 |
| --- | --- | --- |
| `--auto-save-interval=<秒>` | `60` | 每隔多久存一次控制文件。设 `0` 表示下载过程中不存（**退出时仍会存**）。频繁中断的场景调小它 |
| `--remove-control-file` | `false` | 下载**前**删掉控制文件，强制从头开始。适合代理不支持重连的场景 |
| `--allow-piece-length-change` | `false` | 分片长度和控制文件记录不一致时怎么办。`false` 直接停，`true` 继续但丢部分进度 |
| `--always-resume` | `true` | 总是尝试续传；无法续传就中止。设 `false` 则在镜像不支持续传时**从头重下** |
| `--max-resume-failure-tries=N` | `0` | 配合 `--always-resume=false`：遇到 N 个不支持续传的 URI 就从头重下 |

### 退出码 7 的含义（实测）

用 `Ctrl-C` / `SIGINT` 中断带未完成任务的会话时，aria2 **退出码是 7**，并且会保留 `.aria2` 控制文件：

```
rc_interrupt=7
-rw-r--r-- part.bin        324608     ← 已下载部分保留
-rw-r--r-- part.bin.aria2      59     ← 控制文件保留
```

直接重跑同一条命令即可续传（**不需要** `-c`，因为控制文件还在）。

---

## 六、限速、超时与重试

### 限速

| 选项 | 默认 | 作用 |
| --- | --- | --- |
| `--max-overall-download-limit=<速度>` | `0`（不限） | **所有**下载的总下载速度上限 |
| `--max-download-limit=<速度>` | `0` | **每个**下载的速度上限 |
| `--max-overall-upload-limit=<速度>` | `0` | 总上传速度上限（BT） |
| `-u, --max-upload-limit=<速度>` | `0` | 每个种子的上传速度上限 |
| `--lowest-speed-limit=<速度>` | `0` | 速度低于此值就断开连接（**对 BT 无效**） |

速度可带 `K` / `M` 后缀，**按 1024 进制**（`1K=1024`，`1M=1024K`）。

```bash
aria2c --max-overall-download-limit=2M URL       # 总限速 2 MiB/s
aria2c --max-download-limit=500K URL1 URL2       # 各限 500 KiB/s
```

### 超时与重试

| 选项 | 默认 | 取值范围 | 作用 |
| --- | --- | --- | --- |
| `-t, --timeout=<秒>` | `60` | 1–600 | 连接建立**之后**的 I/O 超时 |
| `--connect-timeout=<秒>` | `60` | 1–600 | **建立连接**阶段的超时；连接建立后此值失效，改由 `-t` 接管 |
| `-m, --max-tries=<次数>` | `5` | 0–∞ | 重试次数。`0` = 不限 |
| `--retry-wait=<秒>` | `0` | 0–600 | 收到 HTTP 503 后等待多久再重试 |
| `--max-file-not-found=<次数>` | `0` | 0–∞ | 收到 N 次「文件未找到」且未拿到任何数据就判失败。`0` = 禁用。**重试次数计入 `-m`** |

**`-t` 和 `--connect-timeout` 的区别要记牢**：一个管「连上了但没数据」，一个管「根本连不上」。

```bash
# 弱网环境：快速放弃不可达的源
aria2c --connect-timeout=5 -t 10 -m 3 --retry-wait=2 URL
```

### 下载结果的输出控制

| 选项 | 默认 | 作用 |
| --- | --- | --- |
| `--summary-interval=<秒>` | `60` | 进度摘要输出间隔。`0` = 关闭（脚本里常用） |
| `--console-log-level=<级别>` | `notice` | 控制台日志级别：`debug/info/notice/warn/error` |
| `--log=<文件>` / `-l` | — | 把日志写到文件，`-` 表示标准输出 |
| `--log-level=<级别>` | `debug` | `-l` 文件的日志级别 |
| `-q, --quiet` | `false` | 静默，不在控制台输出 |
| `--show-console-readout` | `true` | 是否显示那行实时读数 |
| `--truncate-console-readout` | `true` | 读数压缩成单行 |
| `--download-result=default\|full\|hide` | `default` | 结束时的「下载结果」表格格式，`hide` 完全隐藏 |
| `--human-readable` | `true` | 用 `1.2Ki`、`3.4Mi` 这种人类可读单位 |
| `--enable-color` | `true` | 终端彩色输出 |

实时读数的样子（实测，限速 800K + 4 连接）：

```
[#880f12 768KiB/2.8MiB(26%) CN:3 DL:402KiB ETA:5s]
```

其中 `CN:` 是当前连接数，`DL:` 是速度，`ETA:` 是预计剩余时间。**`CN` 是排查「为什么没提速」的第一现场** —— 如果 `CN:1`，说明没开 `-x` 或文件太小没切分。

---

## 七、磁盘与 I/O 调优

### `--file-allocation=METHOD`（默认 `prealloc`）

下载前预分配磁盘空间的策略：

| 值 | 含义 | 适用 |
| --- | --- | --- |
| `none` | 不预分配 | 老式/网络文件系统，或不在乎碎片 |
| `prealloc` | 老老实实写零占位 | **默认值**，但在大文件上很慢 |
| `falloc` | 用 `posix_fallocate()` 瞬间分配 | **现代文件系统首选**：ext4(extents)、btrfs、xfs、NTFS |
| `trunc` | 用 `ftruncate()` 造个稀疏文件 | 想快又不想真占空间 |

> [!tip] 本机建议
> 本机 `/var/home` 是 **btrfs**，用 `falloc`：
> ```bash
> aria2c --file-allocation=falloc URL
> ```
> `falloc` 在几 GiB 的文件上几乎瞬间完成；但**别在 ext3 / FAT32 上用**，那会比 `prealloc` 还慢，而且会**整个卡住 aria2** 直到分配结束。系统若无 `posix_fallocate()`，`falloc` 也可能不可用。

### 其他磁盘相关选项

| 选项 | 默认 | 作用 |
| --- | --- | --- |
| `--no-file-allocation-limit=<大小>` | `5M` | 小于此大小的文件不预分配 |
| `--disk-cache=<大小>` | `16M` | 内存磁盘缓存。数据按偏移排序后成批写入，减少磁盘 I/O；做哈希校验时还能免掉一次读盘。`0` = 关闭 |
| `--rlimit-nofile=<数量>` | `1024` | 提升打开文件描述符的软上限（**只增不减**）。BT 多文件下载时有用 |
| `--enable-mmap` | `false` | 用 mmap 写文件 |
| `--max-mmap-limit=<大小>` | 极大 | 超过此总大小就禁用 mmap |

---

## 八、HTTP / HTTPS 相关

### 请求头与身份

| 选项 | 默认 | 作用 |
| --- | --- | --- |
| `--header=<报头>` | — | 追加自定义请求头。**可重复使用** |
| `-U, --user-agent=<UA>` | `aria2/1.37.0` | 设置 User-Agent |
| `--referer=<地址>` | — | 设置 Referer。给 `*` 表示用下载 URI 自身当 Referer |
| `--http-user` / `--http-passwd` | — | HTTP 基本认证，对**所有**链接生效 |
| `--http-auth-challenge` | `false` | `false` 时认证头**永远**先发；`true` 时只在服务器质询后才发（URI 内嵌用户名密码的情况例外，永远发） |
| `--load-cookies=<文件>` | — | 从 Netscape/Firefox3 格式的 cookies.txt 读 Cookie |
| `--save-cookies=<文件>` | — | 把 Cookie 存成同样格式（会覆盖已有文件，会话 Cookie 存为有效期 0） |
| `-n, --no-netrc` | `false` | 禁用 `~/.netrc` |
| `--netrc-path=<文件>` | `~/.netrc` | 指定 netrc 路径 |

```bash
# 多个自定义头：--header 可以叠加
aria2c --header="X-A: b78" --header="X-B: 9J1" https://host/file

# 需要登录态的下载
aria2c --load-cookies=~/cookies.txt \
       --header="Authorization: Bearer xxxxx" \
       -U "Mozilla/5.0 ..." URL
```

### 传输细节

| 选项 | 默认 | 作用 |
| --- | --- | --- |
| `--enable-http-keep-alive` | `true` | HTTP/1.1 长连接 |
| `--enable-http-pipelining` | `false` | HTTP/1.1 流水线，能减少重连开销 |
| `--http-accept-gzip` | `false` | 发 `Accept-Encoding: deflate, gzip` 并自动解压响应 |
| `--http-no-cache` | `false` | 发 `Cache-Control: no-cache` / `Pragma: no-cache` |
| `--use-head` | `false` | 先发 HEAD 探一下 |
| `--reuse-uri` | `true` | URI 用完后是否复用 |
| `--uri-selector=inorder\|feedback\|adaptive` | `feedback` | 多镜像时怎么挑。`feedback` 按历史测速挑**最快**的（能自动跳过死镜像），`inorder` 按给定顺序，`adaptive` 混合策略 |
| `--server-stat-if` / `--server-stat-of` | — | 读写测速档案文件，配合 `feedback` |
| `--conditional-get` | `false` | **仅本地文件比远端旧时才下载**（见下） |
| `--content-disposition-default-utf8` | `false` | 把 `filename="..."` 的引号内容按 UTF-8 而非 ISO-8859-1 解释 |
| `--no-want-digest-header` | `false` | 禁用 `Want-Digest` 请求头 |
| `--dry-run` | `false` | **只检查远端可达，不下载任何数据**（见下） |

> [!warning] `--conditional-get` 的局限
> 它靠比较远端 `Last-Modified` 和本地文件 mtime 来决定是否下载，**限制很多**：
> - 只对 HTTP(S) 有效；
> - 会**忽略 `Content-Disposition`** 头；
> - 如果存在 `.aria2` 控制文件，该选项被**完全忽略**；
> - Metalink 中指定了文件大小时不生效。
>
> 实测中它还会因为目标文件名被占用而改名存成 `name.2.ext`。要做「镜像同步」类任务，它并不够用，建议自己用 `curl -z` 或脚本判断。

> [!tip] `--dry-run` 的实用价值
> 实测：`aria2c --dry-run -o out.bin URL` 会报告 `(OK):下载完成。`，但**磁盘上不会产生任何文件**。
> 用途：批量下载前先验证一堆 URL 是否还有效，不浪费流量。

### 证书与 TLS

| 选项 | 默认 | 作用 |
| --- | --- | --- |
| `--check-certificate` | `true` | 校验服务器证书 |
| `--ca-certificate=<文件>` | — | 指定 CA 证书包（PEM，可含多个） |
| `--certificate=<文件>` / `--private-key=<文件>` | — | 客户端证书认证（PEM，私钥须未加密） |
| `--min-tls-version=` | `TLSv1.2` | 可选 `TLSv1.1/1.2/1.3` |

遇到 `SSL certificate problem` 时正确做法是配 `--ca-certificate`，**不是**关掉 `--check-certificate=false`。

### FTP / SFTP

| 选项 | 默认 | 作用 |
| --- | --- | --- |
| `--ftp-user` / `--ftp-passwd` | — | FTP 认证，对所有 URL 生效 |
| `-p, --ftp-pasv` | `true` | 被动模式；`false` 为主动模式 |
| `--ftp-type=binary\|ascii` | `binary` | 传输类型 |
| `--ftp-reuse-connection` | `true` | 复用连接 |
| `--ssh-host-key-md=<类型>=<摘要>` | — | 验证 SFTP 服务器公钥（`sha-1` 或 `md5`）。**不设置就不验证** |

### 代理

| 选项 | 作用 |
| --- | --- |
| `--all-proxy=<代理>` | 所有协议统一代理 |
| `--http-proxy` / `--https-proxy` / `--ftp-proxy` | 按协议分别指定 |
| `--no-proxy=<列表>` | 不走代理的主机/域名/CIDR，逗号分隔 |
| `--proxy-method=get\|tunnel` | 代理请求方式，默认 `get` |
| `--{all,http,https,ftp}-proxy-user` / `-passwd` | 代理认证 |

代理格式：`[http://][USER:PASSWORD@]HOST[:PORT]`。用**空字符串** `""` 可以覆盖掉之前定义的值。

---

## 九、批量下载与自动化

### `-i, --input-file=<文件>`（`-` 表示从标准输入读）

一次读入一批下载任务。**每行一个 URI**，同一行可用制表符分隔多个 URI；**紧跟在 URI 后面的缩进行是给这个 URI 的选项**（每行一个选项，行首必须有空白）：

```
http://example.com/a.iso
  out=a.iso
  dir=/data/downloads
http://example.com/b.iso
  out=b.iso
  max-connection-per-server=4
  split=4
  min-split-size=1M
  dir=/data/downloads
```

实测这份输入文件能正确下载两个文件，并且每行的选项**确实覆盖命令行**。

> [!tip] 配合 `--deferred-input=true`
> 默认 `false`：启动时就把整个输入文件的 URI 和选项读进内存。若输入文件里有**几十万条**，改成 `true` 可以按需逐条读取，显著降低内存占用。

### `-P, --parameterized-uri`（默认 **`false`**）—— 通配/展开

支持两种展开语法：

```
# 集合展开
http://{sv1,sv2,sv3}/foo.iso

# 数值序列，可带步进（步进可省略）
http://host/image[000-100:2].img
http://host/img0[1-3].txt
```

> [!warning] `-P` 必须显式打开（实测）
> 默认是 `false`，**不打开就没任何展开**，方括号会被当成 URL 的字面字符：
>
> ```bash
> $ aria2c -Z "http://127.0.0.1:18081/img0[1-3].txt"
> (ERR):发生错误。                              ← 404，退出码 3
> $ aria2c -P -Z "http://127.0.0.1:18081/img0[1-3].txt"
> NOTICE 下载完成：img01.txt
> NOTICE 下载完成：img02.txt
> NOTICE 下载完成：img03.txt                    ← 正确
> ```
>
> 另外：**展开出的多个 URI 如果不是同一个文件，必须加 `-Z`**。

### 会话保存与恢复

| 选项 | 默认 | 作用 |
| --- | --- | --- |
| `--save-session=<文件>` | — | 退出时把「出错/未完成」的下载写入文件 |
| `--save-session-interval=<秒>` | `0` | 每隔多久存一次会话。`0` = 只在退出时存 |
| `--force-save` | `false` | 即使已完成/已删除也保存（含控制文件状态），常用来保住 BT 种子状态 |
| `--save-not-found` | `true` | 即使文件在服务器上找不到也保存 |
| `--gid=<GID>` | 自动 | 手动指定 GID（16 位十六进制），恢复会话时保持身份一致 |
| `--max-download-result=<数量>` | `1000` | 内存中最多保留多少条下载结果（超出按 FIFO 淘汰） |
| `--keep-unfinished-download-result` | `true` | 未完成的结果不计入上面的上限，避免丢会话 |

**完整工作流**（实测通过）：

```bash
# 1) 下载中被打断，会话 + 控制文件都被保留
aria2c --max-overall-download-limit=400K --save-session=sess.txt -o s.bin URL
# Ctrl-C  →  exit 7
#   s.bin        429.0K      ← 部分数据
#   s.bin.aria2   59B        ← 控制文件
#   sess.txt                 ← 会话文件，内容形如：
#       http://.../big.bin
#        gid=18d34d7ecc0f3403
#        out=s.bin

# 2) 从会话恢复（会自动续传，无需 -c）
aria2c -i sess.txt
# NOTICE 下载完成：/tmp/aria2lab/dl/s.bin   ← 续传后文件完整
```

> [!note] RPC 添加的任务不会进会话文件
> 通过 `aria2.addTorrent` / `aria2.addMetalink` 添加的下载，元数据无法存成文件，因此 `--save-session` 不会保存它们（除非 `--rpc-save-upload-metadata=true`）。被 `aria2.remove` / `aria2.forceRemove` 删掉的也不会保存。

### Metalink

| 选项 | 默认 | 作用 |
| --- | --- | --- |
| `-M, --metalink-file=<文件>` | — | 指定 `.meta4` / `.metalink`，`-` 为 stdin |
| `--metalink-version` / `-language` / `-os` / `-location` | — | 按版本/语言/系统/位置筛选要下载的文件 |
| `--metalink-preferred-protocol=http\|https\|ftp\|none` | `none` | 首选协议 |
| `--metalink-enable-unique-protocol` | `true` | 同一镜像有多个协议时只用其中一个 |
| `--metalink-base-uri=<URI>` | — | 解析本地 Metalink 中相对 URI 的基准 |
| `--follow-torrent=true\|mem\|false` | `true` | 下载到 `.meta4`/`.torrent` 时是否顺便解析并下载其中内容；`mem` = 只放内存不落盘 |

### 校验

| 选项 | 默认 | 作用 |
| --- | --- | --- |
| `--checksum=<类型>=<摘要>` | — | 手动指定校验值，**仅 HTTP(S)/FTP**。如 `--checksum=sha-1=0192ba11...` |
| `-V, --check-integrity` | `false` | 用分片哈希/整文件哈希校验完整性。可用于 BT、带校验的 Metalink、（配合 `--checksum` 的）HTTP(S)/FTP |
| `--hash-check-only` | `false` | 只做完整性检查然后退出，不管下载是否完成 |
| `--realtime-chunk-checksum` | `true` | 有分片校验值时边下边校验 |

支持的哈希：`sha-1, sha-224, sha-256, sha-384, sha-512, md5, adler32`（`aria2c -v` 可查）。

---

## 十、BitTorrent

### 基本用法

```bash
aria2c ./debian.torrent
aria2c -T ./debian.torrent
aria2c "magnet:?xt=urn:btih:xxxxxxxxxxxxxxxx"
aria2c -S ./debian.torrent          # 只看内容清单
```

| 选项 | 默认 | 作用 |
| --- | --- | --- |
| `-T, --torrent-file=<文件>` | — | 指定 `.torrent` 路径 |
| `--follow-torrent=true\|mem\|false` | `true` | `mem` = 种子文件只留内存不写盘 |
| `--listen-port=<端口...>` | `6881-6999` | BT 的 TCP 监听端口。支持 `6881,6885` 或 `6881-6999` |
| `--bt-max-peers=<数量>` | `55` | 每个种子最大 peer 数。`0` = 不限 |
| `--bt-request-peer-speed-limit=<速度>` | `50K` | 总速度低于此值时**临时提高 peer 数**来加速。调高它常能显著提速 |
| `--bt-max-open-files=<数量>` | `100` | 多文件种子全局最大打开文件数 |

### DHT / PEX / LPD

| 选项 | 默认 | 作用 |
| --- | --- | --- |
| `--enable-dht` | `true` | IPv4 DHT（同时启用 UDP Tracker）。种子带 `private` 标记时**强制不用 DHT** |
| `--enable-dht6` | `false` | IPv6 DHT |
| `--dht-listen-port` | `6881-6999` | DHT / UDP Tracker 的 UDP 端口 |
| `--dht-entry-point=<主机:端口>` | — | DHT 入口节点 |
| `--dht-file-path` | `~/.cache/aria2/dht.dat` | DHT 路由表文件 |
| `--enable-peer-exchange` | `true` | PEX 节点交换 |
| `--bt-enable-lpd` | `false` | 本地节点发现 |
| `--bt-lpd-interface=<接口>` | — | LPD 使用的网络接口 |

### Tracker

| 选项 | 默认 | 作用 |
| --- | --- | --- |
| `--bt-tracker=<URI,...>` | — | **追加** Tracker（在排除之后添加，不受排除项影响） |
| `--bt-exclude-tracker=<URI,...>` | — | 删除指定 Tracker。`'*'` 表示清空所有（记得转义或加引号） |
| `--bt-tracker-interval=<秒>` | `0` | 完全覆盖 Tracker 返回的间隔；`0` 表示按响应和下载进度自动决定 |
| `--bt-tracker-timeout=<秒>` | `60` | Tracker 超时 |
| `--bt-tracker-connect-timeout=<秒>` | `60` | 连接 Tracker 的超时 |
| `--bt-external-ip=<IP>` | — | 向 Tracker / DHT 报告的对外 IP，内网做种时重要 |

```bash
# 给一个公开种子补一堆 tracker
aria2c -T ./file.torrent \
  --bt-tracker="udp://tracker.opentrackr.org:1337/announce,udp://open.demonii.com:1337/announce" \
  --bt-exclude-tracker='*'          # 先清空再补
```

### 做种与完成行为

| 选项 | 默认 | 作用 |
| --- | --- | --- |
| `--seed-ratio=<比率>` | `1.0` | 做种到分享率达到此值。`0.0` = 无限做种 |
| `--seed-time=<分钟>` | — | 做种指定分钟数。与 `--seed-ratio` **同时给则任一条件达成即停** |
| `--bt-stop-timeout=<秒>` | `0` | 连续这么多秒速度为 0 就停。`0` = 禁用 |
| `--bt-detach-seed-only` | `false` | 仅做种的任务不计入 `-j` 并发数，让排队的任务开始 |
| `--bt-hash-check-seed` | `true` | `-V` 校验通过后继续做种 |
| `--bt-enable-hook-after-hash-check` | `true` | 哈希检查成功后触发 `--on-bt-download-complete` 钩子 |
| `--bt-seed-unverified` | `false` | 做种前不做分片哈希校验 |
| `--bt-remove-unselected-file` | `false` | 下载完成后**删除未选中的文件**（⚠️ 会真实删盘） |

### 磁力链与元数据

| 选项 | 默认 | 作用 |
| --- | --- | --- |
| `--bt-save-metadata` | `false` | 把磁力链取到的元数据存成 `.torrent` 文件（文件名是十六进制哈希；已存在则不覆盖） |
| `--bt-metadata-only` | `false` | **只要元数据**，不下载实际文件 —— 用磁力链攒种子文件的标准姿势 |
| `--bt-load-saved-metadata` | `false` | 走 DHT 之前先试着读 `--bt-save-metadata` 存过的文件 |

```bash
# 用磁力链得到 .torrent（只取元数据）
aria2c --bt-metadata-only=true --bt-save-metadata=true "magnet:?xt=urn:btih:..."
```

### 加密

| 选项 | 默认 | 作用 |
| --- | --- | --- |
| `--bt-min-crypto-level=plain\|arc4` | `plain` | 最低加密级别 |
| `--bt-require-crypto` | `false` | 拒绝旧版握手，只用混淆握手 |
| `--bt-force-encryption` | `false` | 等价于前两者都开且要求 arc4 负载加密 |

### 文件选择

| 选项 | 默认 | 作用 |
| --- | --- | --- |
| `--select-file=<索引...>` | — | 按索引选择要下载的文件。支持 `3,6` 和 `1-5`。索引用 `-S` 查 |
| `-O, --index-out=<索引>=<路径>` | — | 给选中的文件单独指定输出路径 |
| `--bt-prioritize-piece=head[=大小],tail[=大小]` | — | 优先下每个文件的首尾片段（默认 1M），**边下边看**视频时有用 |
| `--stream-piece-selector=default\|inorder\|random\|geom` | `default` | HTTP/FTP 的分片选择顺序。`inorder` / `geom` 从文件开头顺序下载，配合 `--bt-prioritize-piece` 用于流式观看 |

```bash
# 只下种子里的第 1、3 个文件
aria2c -S ./big.torrent
aria2c -T ./big.torrent --select-file=1,3
```

---

## 十一、事件钩子（hooks）

| 选项 | 触发时机 |
| --- | --- |
| `--on-download-start=<命令>` | 下载开始后 |
| `--on-download-pause=<命令>` | 下载暂停后 |
| `--on-download-stop=<命令>` | 下载**因错误停止**后 |
| `--on-download-complete=<命令>` | 下载**成功完成**后 |
| `--on-download-error=<命令>` | 下载**出错中止**后 |
| `--on-bt-download-complete=<命令>` | BT 下载完成但**还在做种**时（做种结束才触发 `--on-download-complete`） |

**命令收到的三个参数**（实测确认）：

```bash
$1 = GID            # 下载项标识
$2 = 文件数量
$3 = 第一个文件的路径
```

实测的钩子脚本与输出：

```bash
#!/bin/bash
echo "hook args: gid=$1 numfiles=$2 path=$3" >> /tmp/hook.log
```

```
hook args: gid=699b66155b141c3e numfiles=1 path=/tmp/aria2lab/dl/hook.bin   ← start
hook args: gid=699b66155b141c3e numfiles=1 path=/tmp/aria2lab/dl/hook.bin   ← complete
```

> [!note] `--on-download-stop` 与 `--on-download-complete/error` 的关系
> 如果同时指定了 complete/error，那么在对应条件下**只执行 complete/error，不执行 stop**。可以把 stop 当作「以上都没匹配到」的兜底。

---

## 十二、RPC 远程控制

让 aria2 跑成后台服务，由别的程序（AriaNg、Motrix、自写脚本）来控制。

### 服务端启动

```bash
aria2c --enable-rpc \
       --rpc-secret=你的令牌 \
       --rpc-listen-port=6800 \
       --rpc-listen-all=false \
       -D
```

| 选项 | 默认 | 作用 |
| --- | --- | --- |
| `--enable-rpc` | `false` | 启用 JSON-RPC / XML-RPC 服务 |
| `--rpc-secret=<令牌>` | — | **RPC 授权令牌，强烈建议设置** |
| `--rpc-listen-port=<端口>` | `6800` | 监听端口（1024–65535） |
| `--rpc-listen-all` | `false` | `false` 只监听回环；`true` 监听所有网卡 |
| `--rpc-allow-origin-all` | `false` | 响应头加 `Access-Control-Allow-Origin: *`，给浏览器前端跨域用 |
| `--rpc-max-request-size=<大小>` | `2M` | 超过此大小的请求直接断开 |
| `--rpc-secure` | `false` | 用 SSL/TLS 加密 RPC |
| `--rpc-certificate` / `--rpc-private-key` | — | RPC 服务端证书与私钥（PEM） |
| `--rpc-save-upload-metadata` | `true` | 保存通过 RPC 上传的种子/Metalink 元数据 |
| `--rpc-user` / `--rpc-passwd` | — | ⚠️ **已标记 deprecated**，请改用 `--rpc-secret` |
| `-D, --daemon` | `false` | 以守护进程运行（CWD 变 `/`，stdout/stderr 丢弃） |
| `--pause` | `false` | 添加任务后先暂停（**需 `--enable-rpc=true`**） |
| `--pause-metadata` | `false` | 元数据下载产生的后续下载先暂停（**需 `--enable-rpc=true`**） |

### 客户端调用（实测）

未授权请求会被拒绝：

```bash
$ curl -s http://127.0.0.1:6800/jsonrpc \
    -d '{"jsonrpc":"2.0","id":"1","method":"aria2.getVersion","params":[]}'
{"id":"1","jsonrpc":"2.0","error":{"code":1,"message":"Unauthorized"}}
```

带上 `token:` 前缀的令牌即可：

```bash
# 查版本
curl -s http://127.0.0.1:6800/jsonrpc -d '{
  "jsonrpc":"2.0","id":"1","method":"aria2.getVersion","params":["token:你的令牌"]}'
# {"id":"1","jsonrpc":"2.0","result":{"version":"1.37.0","enabledFeatures":[...]}}

# 添加下载（第三个参数是选项字典，等同于命令行选项名）
curl -s http://127.0.0.1:6800/jsonrpc -d '{
  "jsonrpc":"2.0","id":"2","method":"aria2.addUri",
  "params":["token:你的令牌",["https://example.com/a.iso"],
            {"out":"a.iso","dir":"/data","split":"4","max-connection-per-server":"4"}]}'
# {"id":"2","jsonrpc":"2.0","result":"28b07976f25f49cb"}    ← GID

# 查已完成任务
curl -s http://127.0.0.1:6800/jsonrpc -d '{
  "jsonrpc":"2.0","id":"3","method":"aria2.tellStopped",
  "params":["token:你的令牌",0,10]}'

# 暂停 / 继续 / 删除（用 GID）
# aria2.pause / aria2.unpause / aria2.remove / aria2.forceRemove
```

常用方法：`aria2.addUri`、`aria2.addTorrent`、`aria2.addMetalink`、`aria2.remove`、`aria2.forceRemove`、`aria2.pause`、`aria2.unpause`、`aria2.tellStatus`、`aria2.tellActive`、`aria2.tellWaiting`、`aria2.tellStopped`、`aria2.getGlobalStat`、`aria2.changeGlobalOption`、`aria2.purgeDownloadResult`。

> [!warning] 安全提醒
> `--rpc-listen-all=true` 且**没有 `--rpc-secret`** = 把一台可以任意写文件的下载器暴露到网络上。
> 公网场景务必：设 `--rpc-secret` + 保持 `--rpc-listen-all=false` + 用 SSH 端口转发，或者上 `--rpc-secure`。
>
> ```bash
> # 本机安全用法：只监听回环，需要远程就 SSH 转发
> ssh -L 6800:127.0.0.1:6800 user@server
> ```

---

## 十三、配置文件

### 位置

本机默认路径：**`~/.config/aria2/aria2.conf`**

相关选项：

| 选项 | 作用 |
| --- | --- |
| `--conf-path=<路径>` | 换个配置文件位置 |
| `--no-conf` | **完全禁用**配置文件加载 |

### 格式（有坑，实测）

每行 `选项名=值`，`#` 开头是注释，空行可忽略。

> [!warning] 配置里**不能**写 `--` 前缀，也不能写短选项
> 实测：
>
> ```
> $ cat t2.conf
> --dir=/tmp/aria2lab/dl        ← 报 WARN Unknown option
> -o=conf2.bin                  ← 报 WARN Unknown option
>
> $ cat test.conf
> dir=/tmp/aria2lab/dl          ← 正确
> out=conf.bin
> ```
>
> 即：**必须写长选项名，且不带前导 `--`**。单字符短选项（`-o`）也不认。

### 一份可用的模板

```conf
# ~/.config/aria2/aria2.conf

# ── 目录 ──────────────────────────────
dir=/data/downloads
# file-allocation 按文件系统选：btrfs/xfs/ext4 用 falloc
file-allocation=falloc

# ── 并发与分片 ────────────────────────
split=16
max-connection-per-server=16
min-split-size=1M
max-concurrent-downloads=5

# ── 续传 ──────────────────────────────
continue=true
always-resume=true
# 每 30 秒存一次控制文件，防意外断电丢进度
auto-save-interval=30

# ── 重试 ──────────────────────────────
max-tries=5
retry-wait=3
connect-timeout=10
timeout=30

# ── 输出 ──────────────────────────────
summary-interval=0
console-log-level=warn
# 下载完成后不保留结果列表
max-download-result=50

# ── 会话（配合 aria2c -i 恢复）────────
save-session=/data/downloads/aria2.session
save-session-interval=30
input-file=/data/downloads/aria2.session

# ── 日志 ──────────────────────────────
#log=/data/downloads/aria2.log
#log-level=warn

# ── RPC（需要用前端时再打开）──────────
#enable-rpc=true
#rpc-listen-all=false
#rpc-listen-port=6800
#rpc-secret=换成你自己的长随机串

# ── BT ────────────────────────────────
#bt-max-peers=100
#bt-request-peer-speed-limit=2M
#seed-ratio=1.0
#bt-tracker=udp://tracker.opentrackr.org:1337/announce,udp://open.demonii.com:1337/announce

# ── 代理 ──────────────────────────────
#all-proxy=http://127.0.0.1:7890
#no-proxy=localhost,127.0.0.1,192.168.0.0/16
```

> [!tip] 用 `--no-conf` 做临时覆盖
> 想临时忽略全局配置（比如跑基准测试）：
> ```bash
> aria2c --no-conf=true URL
> ```
> 想用一套**备用配置**：`aria2c --conf-path=./fast.conf URL`。

---

## 十四、退出码

下表取自 official man page 的 EXIT STATUS 段；**标注 ✅ 的已在本机 aria2 1.37.0 上实测复现**。

| 码 | 含义 | 实测 |
| --- | --- | --- |
| **0** | 全部下载成功 | ✅ |
| 1 | 未知错误 | |
| 2 | 超时 | ✅（连不可达地址） |
| **3** | 资源未找到（404） | ✅ |
| 4 | 达到 `--max-file-not-found` 指定的「未找到」次数 | ✅ |
| 5 | 下载速度过慢而被中止（`--lowest-speed-limit`） | |
| 6 | 网络问题 | |
| **7** | 存在未完成的下载（用户中断时，且其余的都成功了） | ✅ |
| 8 | 要求续传但远端不支持 | |
| 9 | 磁盘空间不足 | |
| 10 | 分片长度与控制文件不一致（`--allow-piece-length-change`） | |
| 11 | 同一文件正在被下载 | |
| 12 | 同一 info hash 的种子正在被下载 | |
| **13** | 文件已存在（`--auto-file-renaming=false` 时） | ✅ |
| 14 | 重命名文件失败 | |
| 15 | 无法打开已存在的文件 | |
| 16 | 无法创建/截断文件 | |
| 17 | 文件 I/O 错误 | |
| 18 | 无法创建目录 | |
| **19** | 域名解析失败 | ✅ |
| 20 | 无法解析 Metalink | |
| 21 | 无法解析 BitTorrent 元信息 | |
| 22 | HTTP 响应头异常 | |
| 23 | 重定向次数过多 | |
| 24 | HTTP 认证失败 | |
| 25 | 无法解析 bencode 文件（通常是 .torrent） | |
| 26 | .torrent 损坏或缺信息 | |
| 27 | 磁力链无效 | |
| **28** | 选项错误 / 参数不合法 | ✅ |
| 29 | 服务器暂时过载或维护 | |
| 30 | 无法解析 JSON-RPC 请求 | |
| 31 | 保留 | |
| **32** | 校验和验证失败 | ✅ |

脚本里判断成败，**别只判 `!= 0` 就完事**：`7`（中断但有进度）通常可以安全重跑续传，`3`/`19` 是可重试的网络问题，`13` 是文件已存在（可能说明你已经下过了）。

---

## 十五、常见场景配方

### 1. 单个大文件极速下载

```bash
aria2c -x16 -s16 -k1M --file-allocation=falloc -o big.iso https://mirror.example.com/big.iso
```

### 2. 多镜像接力（默认行为，不用 `-Z`）

```bash
aria2c -x4 -s16 \
  https://mirror1.example.com/big.iso \
  https://mirror2.example.com/big.iso \
  https://mirror3.example.com/big.iso
# 三个 URL 视为同一文件的镜像，共 16 段，每镜像最多 4 连接
```

### 3. 批量下载不同文件

```bash
aria2c -Z -j5 -d ~/Downloads URL1 URL2 URL3 URL4 URL5
```

或写输入文件（能逐个定制选项）：

```bash
cat > list.txt <<'EOF'
https://example.com/a.iso
  out=a.iso
  dir=/data/a
https://example.com/b.iso
  out=b.iso
  dir=/data/b
  max-connection-per-server=8
  split=8
EOF
aria2c -i list.txt
```

### 4. 数字序列批量（用通配）

```bash
aria2c -P -Z -x8 -s8 -j4 "https://example.com/img[001-100].jpg"
```

### 5. 限速后台跑，不占满带宽

```bash
aria2c -D --max-overall-download-limit=2M \
       --save-session=~/aria2.session -i list.txt
```

### 6. 需要登录态的下载

```bash
aria2c --load-cookies=~/cookies.txt \
       --referer="https://example.com/page" \
       -U "Mozilla/5.0 (X11; Linux x86_64) Gecko/20100101 Firefox/128.0" \
       --header="Authorization: Bearer eyJhbGci..." \
       https://example.com/private/file.zip
```

`cookies.txt` 必须是 Netscape 格式（用浏览器扩展导出，或 `--save-cookies` 生成）。

### 7. 只验证 URL 是否有效，不下载

```bash
aria2c --dry-run -i list.txt
# 输出 (OK)/(ERR)，磁盘无文件
```

### 8. 用磁力链拿种子文件（不下载内容）

```bash
aria2c --bt-metadata-only=true --bt-save-metadata=true \
       -d ~/torrents "magnet:?xt=urn:btih:..."
```

### 9. 只下 BT 里的某几个文件

```bash
aria2c -S ./pack.torrent                    # 1) 看索引
aria2c -T ./pack.torrent --select-file=1,3   # 2) 只下 1 和 3
```

### 10. 断点续传（保证用同一个文件名）

```bash
aria2c -c --auto-file-renaming=false --allow-overwrite=false \
       -o big.iso https://example.com/big.iso
```

### 11. 批量任务 + 中断恢复的完整骨架

```bash
# 第一次
aria2c -i list.txt --save-session=~/aria2.session -c
# Ctrl-C 之后，或者换了网络环境
aria2c -i ~/aria2.session -c --continue
```

### 12. 下载完成后自动做点什么

```bash
cat > ~/bin/notify-done.sh <<'EOF'
#!/bin/bash
# $1=GID  $2=文件数  $3=文件路径
notify-send "aria2 下载完成" "$3"
EOF
chmod +x ~/bin/notify-done.sh

aria2c --on-download-complete=~/bin/notify-done.sh URL
```

### 13. 和 `yt-dlp` 配合下视频（aria2c 当外部下载器）

```bash
yt-dlp --downloader aria2c \
       --downloader-args "aria2c:-x16 -s16 -k1M --file-allocation=falloc" \
       "URL"
```

---

## 十六、排错清单

| 症状 | 原因 | 处理 |
| --- | --- | --- |
| `CN:1`，速度上不去 | 没开 `-x`（默认 1），或文件太小被 `-k` 卡住 | 加 `-x16 -s16`，并调小 `-k`（如 `-k1M`） |
| `-s16` 设了但只有 1 个连接 | 服务器**不支持 Range 请求**（返回 200 完整体、无 `Accept-Ranges`） | 无解，只能单连接。可换镜像或换工具 |
| 报 `Unrecognized option` | 配置文件里写了 `--` 前缀或短选项 | 配置里改用不带 `--` 的长选项名 |
| 改了命令行参数却不生效 | `-i` 输入文件里的同名选项**优先级更高** | 检查输入文件里的行内选项 |
| `[1-3]` 通配没展开，报 404 | `-P, --parameterized-uri` 默认是 `false` | 显式加 `-P`（多文件时还需 `-Z`） |
| 退出码 13 | 目标文件已存在且 `--auto-file-renaming=false` | 加 `--allow-overwrite=true`，或换 `-o` |
| 退出码 7 | 被中断，有未完成任务 | 正常，直接重跑同命令即可续传 |
| 下载出 0 字节文件 + 有 `.aria2` | 中断在开头的典型表现 | 重跑续传 |
| `SSL certificate problem` | CA 不受信 | 配 `--ca-certificate`，不要关 `--check-certificate` |
| `falloc` 卡很久 | 在 ext3/FAT32 等不支持 `posix_fallocate()` 的 FS 上 | 换 `--file-allocation=trunc`（稀疏）或 `prealloc` |
| 找不到刚下的文件 | `--auto-file-renaming` 存成了 `name.1.ext` | 用 `ls -1 name*`，或 `--auto-file-renaming=false` |
| RPC 返回 `Unauthorized` | 没带 `token:` 前缀 | `params:["token:你的令牌", ...]` |
| BT 没速度 | peer 数太少 / 无 DHT / Tracker 被墙 | 调高 `--bt-request-peer-speed-limit`、加 `--bt-tracker` |
| 想看实时连接数 | — | 看读数里的 `CN:` 字段，或调大 `--summary-interval` |

---

## 十七、速查表

```bash
# ── 基本 ──────────────────────────────────────────
aria2c URL                                  # 简单下载
aria2c -d ~/Downloads -o name.bin URL       # 指定目录与文件名
aria2c -Z URL1 URL2                         # 多个不同文件，顺序下载
aria2c URL1 URL2                            # 同一文件的多个镜像

# ── 提速 ──────────────────────────────────────────
aria2c -x16 -s16 -k1M URL                   # 16 连接（-x 必须显式给）
aria2c -j5 -x16 -s16 -k1M URL1 ... URL5     # 5 个文件 × 16 连接
aria2c --file-allocation=falloc URL         # btrfs/xfs/ext4 快速预分配

# ── 续传 ──────────────────────────────────────────
aria2c -c -o big.iso URL                    # 无控制文件时接手
aria2c -i aria2.session --continue          # 从会话恢复

# ── 限速 ──────────────────────────────────────────
aria2c --max-overall-download-limit=2M URL  # 总限速
aria2c --max-download-limit=500K URL        # 单任务限速

# ── 批量 ──────────────────────────────────────────
aria2c -i list.txt                          # 从文件读任务列表
aria2c -P -Z "http://h/img[001-100].jpg"    # 通配展开（-P 必须）
aria2c -M file.meta4                        # Metalink

# ── BT ────────────────────────────────────────────
aria2c -T file.torrent                      # 下种子
aria2c -S file.torrent                      # 只看文件清单
aria2c -T file.torrent --select-file=1,3    # 只下部分文件
aria2c --bt-metadata-only --bt-save-metadata "magnet:?xt=urn:btih:..."

# ── 验证与调试 ────────────────────────────────────
aria2c --dry-run URL                        # 只验证不下载
aria2c --checksum=sha-256=<hex> URL         # 下载后校验
aria2c -V URL                               # 完整性检查
aria2c -l aria2.log --log-level=debug URL   # 详细日志
aria2c -q --summary-interval=0 URL          # 静默（写脚本时）

# ── RPC 服务 ──────────────────────────────────────
aria2c --enable-rpc --rpc-secret=TOKEN -D   # 后台服务

# ── 配置 ──────────────────────────────────────────
aria2c --conf-path=./custom.conf URL        # 指定配置
aria2c --no-conf=true URL                   # 忽略配置
```

---

## 十八、实测记录

本文中的行为描述均在**本机 aria2 1.37.0** 上实际跑过，而非照抄文档。关键验证点：

| 验证内容 | 结果 |
| --- | --- |
| `-P` 是否必需 | **必需**。不加 `-P` 时 `img0[1-3].txt` 按字面 URL 请求 → 404，exit 3；加 `-P -Z` 后正确展开为 3 个文件 |
| 选项优先级 | **`-i` 行内选项 > 命令行 > 配置文件**。命令行 `-d /srv` 被输入文件里的 `dir=` 覆盖 |
| 配置文件格式 | `--dir=...` 和 `-o=...` 均报 `Unknown option`；`dir=...` / `out=...` 正常 |
| `-x` 上限 | `-x20` → `errorCode=28 max-connection-per-server must be between 1 and 16.` |
| 文件已存在 | 默认自动改名为 `name.1.ext`；`--auto-file-renaming=false` → exit 13；`--allow-overwrite=true` → 覆盖 |
| 中断退出码 | `SIGINT` 中断未完成任务 → exit 7，保留 `.bin` + `.aria2` 控制文件 |
| 会话恢复 | `--save-session` 生成的会话文件经 `-i` 重放后文件完整（`cmp` 一致） |
| 续传 | 手工截断文件 + `-c` 续传后 `cmp` 与源文件一致 |
| 钩子参数 | `$1=GID $2=文件数 $3=文件路径`，start/complete 各触发一次 |
| RPC | 无 token → `{"error":{"code":1,"message":"Unauthorized"}}`；带 `token:` → 正常，`addUri` 返回 GID |
| `--dry-run` | 报告 `(OK):下载完成。` 但磁盘**无文件** |
| 退出码 | 0 / 2 / 3 / 4 / 7 / 13 / 19 / 28 / 32 逐项复现 |
| Content-Disposition | 默认即采用服务器给的文件名（含 RFC 5987 的 UTF-8 中文名） |
| 本地文件系统 | `/var/home` = **btrfs** → `--file-allocation=falloc` 适用 |
| Range 支持 | 用 `python -m http.server` 作服务端时**不支持 Range**，aria2 只能单连接（可作反例） |

---

## 参考

- 官方手册（英文，最全）：<https://aria2.github.io/manual/en/html/aria2c.html>
- 中文手册：<https://aria2.github.io/manual/zh-cn/html/aria2c.html>
- 源码与 issue：<https://github.com/aria2/aria2>
- 本机帮助：`aria2c --help=#all`、`aria2c --help=<关键词>`
