---
date: 2026-10-26
lang: Linux
tags:
  - journald
  - journalctl
  - linux
  - systemd
  - 日志
  - fedora
  - 命令
---

# journald 与 journalctl 详解

`journald` 是 systemd 的日志收集守护进程（`systemd-journald.service`），`journalctl` 是它唯一的官方查询前端。和 `rsyslog` 的纯文本日志不同，journald 存的是**带字段的结构化二进制日志**：每条记录除了 `MESSAGE`，还带写日志那一刻的进程名、PID、UID、cgroup、unit 名、优先级、facility、时间戳等元数据。所以后面能做“按 unit 过滤”“按字段过滤”“导出 JSON 给 jq”这些 syslog 做不到的事。

姊妹篇与分工：

- [[systemd日常使用教程]] —— 面向桌面日常，journal 只讲最常用的几条；**入门先看那篇**。
- [[systemd-fedora-notes]] —— 服务器 / root 视角，journal 在 systemd 全局里的位置。
- **本篇** —— 只讲日志：journald 的存储模型、journalctl **全部**选项、字段体系、配置调优、排障配方。想彻底搞懂日志看这篇。

验证环境：Fedora Silverblue 45 / systemd 262 (262-3.fc45)。标注说明：**本机实测** = 命令真跑出来的输出；**man** = 引用 man 页；未标注的为通用行为。

---

## 目录

1. [journald 在系统里是什么](#1-journald-在系统里是什么)
2. [日志存在哪里：存储模型](#2-日志存在哪里存储模型)
3. [两条日志线：system journal 与 user journal](#3-两条日志线system-journal-与-user-journal)
4. [过滤选项（Filtering）](#4-过滤选项filtering)
5. [输出格式 -o 全表](#5-输出格式--o-全表)
6. [输出控制选项](#6-输出控制选项)
7. [字段体系：一条日志到底有什么](#7-字段体系一条日志到底有什么)
8. [往里写：怎么让程序产出好日志](#8-往里写怎么让程序产出好日志)
9. [磁盘管理与维护](#9-磁盘管理与维护)
10. [journald.conf 配置全表](#10-journaldconf-配置全表)
11. [容器、镜像、命名空间](#11-容器镜像命名空间)
12. [排障配方](#12-排障配方)
13. [陷阱清单](#13-陷阱清单)
14. [速查表](#14-速查表)

---

## 1. journald 在系统里是什么

四个进程/角色别搞混：

| 名字 | 是什么 |
| --- | --- |
| `systemd-journald` | 守护进程，接收并落盘日志 |
| `journalctl` | 查询 CLI（本篇主角） |
| `systemd-cat` | 把任意命令的 stdout 塞进 journal 的小工具 |
| `rsyslog` / `syslog-ng` | 传统 syslog 守护进程，与 journald 并存但**不是必须** |

**日志来源**（`_TRANSPORT` 字段记录的就是这个，本机实测 6 种）：

| `_TRANSPORT` | 含义 |
| --- | --- |
| `kernel` | 内核 `/dev/kmsg` |
| `audit` | 内核审计子系统 |
| `stdout` | 进程 stdout/stderr（systemd 服务最常见） |
| `syslog` | 通过 `/dev/log` 的 syslog 协议 |
| `journal` | 通过原生 journal 协议写入（`sd_journal_send()`） |
| `driver` | systemd 内部（如 `systemd-coredump`） |

```bash
journalctl -F _TRANSPORT          # -F FIELD：列出该字段出现过的所有值
```

> [!info] journald 取代 rsyslog 了吗
> 功能上可以，Fedora 默认没装 rsyslog。但 `/etc/rsyslog.conf` 存在时两者并存：journald 通过 `ForwardToSyslog=yes` 转发给 rsyslog 再落 `/var/log/messages`。判断本机有没有：

```bash
systemctl status rsyslog --no-pager    # 或 rpm -q rsyslog
```

---

## 2. 日志存在哪里：存储模型

### 2.1 两个目录

| 路径 | 性质 | 生命周期 |
| --- | --- | --- |
| `/run/log/journal/<machine-id>/` | tmpfs，**易失** | 重启即消失 |
| `/var/log/journal/<machine-id>/` | 磁盘，**持久** | 跨越重启，受 vacuum 策略约束 |

`Storage=` 决定用哪个：

| 值 | 行为 |
| --- | --- |
| `volatile` | 只用 `/run`，重启丢 |
| `persistent` | 优先 `/var`，早期启动或磁盘不可写时回落 `/run`（**本机默认**） |
| `auto` | `/var/log/journal` 目录存在 → persistent，否则 volatile |
| `none` | 全部丢弃（但转发到 console/kmsg/syslog 仍生效） |

man 里一个容易漏的点：**journald 启动时先按 volatile 走**，直到 `systemd-journal-flush.service`（开机时自动执行）或手动 `journalctl --flush` 把数据搬进 `/var`。所以 `/var/log/journal` 只在你创建过这个目录、或用 `Storage=persistent` 让 journald 自建后才存在。

```bash
ls -d /var/log/journal                 # 存在 = 持久化已启用
journalctl --disk-usage                # 当前占用（本机实测 1009.4M）
```

### 2.2 本机实际配置

Fedora Silverblue 上没有 `/etc/systemd/journald.conf`，配置来自：

```
/usr/lib/systemd/journald.conf
/usr/lib/systemd/journald.conf.d/10-persistent.conf   # 内容: [Journal] Storage=persistent
```

所以这台机器开箱即持久化。**要改自己的配置，不要动 `/usr/lib`**（rpm-ostree 的只读区），放 `/etc/systemd/journald.conf` 或 `/etc/systemd/journald.conf.d/*.conf`，后者覆盖前者。

### 2.3 文件长什么样

```
/var/log/journal/<machine-id>/
├── system.journal                          # 活动文件（当前正在写）
├── system@0000000bd7eb-00065af6b9a83a85.journal   # 归档文件（@ = archived，只读）
└── user-1000.journal                       # 用户级日志（SplitMode=uid 时按 UID 拆）
```

命名规则（man systemd-journald）：

- **归档**：journald 不再写某个文件时，把它改名成 `原名@<起序>-<止序>.journal`，这份从此只读。
- **`~` 后缀**：只出现在**异常**情况下——守护进程非正常停止，或文件被检测到损坏，会被改名成 `.journal~`，然后 journald 另开一个新文件继续写。所以看到 `xxx.journal~` 说明那次关机不干净或文件有问题，`journalctl --verify` 值得跑一下。

不要 `cat`、不要 `grep` 这些文件，二进制专用格式。想读用 `journalctl -D <dir>` 或 `journalctl --file=xxx.journal`。

两个机制值得知道：

- **轮转**：单个文件到 `SystemMaxFileSize=` 或被时间 `MaxFileSec=`（默认 1 month）切分，旧文件变 `@` 归档。
- **FSS（Forward Secure Sealing，`Seal=yes` 默认开）**：定期用密钥给日志签名，防止事后篡改。验证需要 `--setup-keys` 预先生成的验证密钥，验证时配 `--verify-key=`。个人桌面基本不用动；合规/取证场景才需要。

```bash
journalctl --verify                    # 校验文件一致性（能查出截断/损坏）
journalctl --header                    # 打印日志文件头部元信息
```

---

## 3. 两条日志线：system journal 与 user journal

这是最容易踩的一节，也是上一篇那个 `hello-loop` 报 `-- No entries --` 的根因。

| 服务范围 | 配置文件位置 | 查询方式 |
| --- | --- | --- |
| 系统级（root 的 systemd） | `/etc/systemd/system/`、`/usr/lib/systemd/system/` | `journalctl -u NAME` |
| 用户级（每个登录用户一份） | `~/.config/systemd/user/` | `journalctl --user -u NAME` |

**user journal 是独立的日志流**，不带 `--user` 查 system journal 永远查不到。反过来加了 `--user` 也看不到系统服务。

### 3.1 三个相关选项

```bash
journalctl --system                  # 显式选 system journal（默认行为）
journalctl --user                    # 当前用户的 journal
journalctl --user-unit=hello-loop    # 等价于 --user -u hello-loop
```

`--user-unit` 是**单独一个选项**，自己就隐含了 `--user`（本机实测：不加 `--user` 也能查到），这个是记起来最省事的写法。

### 3.2 顺序陷阱（必读）

```bash
journalctl -u --user hello-loop          # ✗ 错
# Failed to add match '--user': 无效的参数
```

原因：`-u` 是**需要参数的选项**，紧跟的下一个 token 一律被当成它的值。于是 `--user` 被当作 unit 名传给了 match。正确写法把 `--user` 放前面或用 `--user-unit`：

```bash
journalctl --user -u hello-loop          # ✓
journalctl --user-unit hello-loop        # ✓
```

同类问题不止出现在 `-u`：任何需要参数的短选项后接长选项都会这样，`-p --user`、`-t --user` 同理。

### 3.3 用户 journal 的前提

man journald.conf 原文：*"per-user journal files are not supported unless persistent storage is enabled, thus making `journalctl --user` unavailable."*

也就是说 `Storage=volatile`/`none` 时，`journalctl --user` 直接没东西可看。查不到用户日志先看 `ls -d /var/log/journal`。

---

## 4. 过滤选项（Filtering）

多个过滤条件**可以叠加**（AND 关系），同一选项写多次是 OR：

```bash
journalctl -u nginx -u postgres        # 两个 unit 的并集
journalctl -u nginx -p err --since today   # 三个条件同时满足
```

### 4.1 按单元

```bash
-u, --unit=UNIT             # 幂等单元名，可简写（-u sshd == -u sshd.service）
--user-unit=UNIT            # 用户单元（隐含 --user）
-I                          # 只看该 unit 最近一次 invocation（必须配 -u）
--invocation=ID             # 按 invocation ID 精确选一次运行
--list-invocations          # 列出某 unit 的所有 invocation
```

`invocation ID` 是 systemd 257 起引入的查询维度：每次 `systemctl restart` 生成一个新 ID，日志带 `_SYSTEMD_INVOCATION_ID` 字段。排障时很有用——服务重启了十次，你只想看**最后那次**的日志：

```bash
journalctl --user -u hello-loop -I          # 最新一次（本机实测）
journalctl --user -u hello-loop --invocation=-1   # 上一次（本机实测）
journalctl --user --list-invocations -u hello-loop
journalctl --user --invocation=e31387401fbb47f1bafa9b525e18d798
journalctl --user -u NAME -I -b             # 配合 -b 只在本次开机里找
```

完整语义（man，比看起来复杂）：`-I` 等价于 `--invocation=0`；**正偏移从日志开头数**（`1` = 历史上第一次运行，`2` = 第二次……），**零和负偏移从末尾数**（`0` = 最近一次，`-1` = 上一次）。写 32 位 ID 之后还能跟 `±offset` 做相对定位。只要指定了偏移，就必须同时给 `-u`/`--user-unit`，否则报 `Using -I/--invocation= with an offset requires a unit`（本机实测）。**负偏移必须写成 `--invocation=-1` 的长格式**，`-I-1` 这种短选项贴值写法会报 `unrecognized option '--'`（本机实测），`-I 1` 也不行（`1` 被当成 match）。

### 4.2 按标识与来源

```bash
-t, --identifier=ID         # SYSLOG_IDENTIFIER，即 syslog 标签（-t bash、-t sshd）
-T, --exclude-identifier=ID # 排除某标签
-k, --dmesg                 # 只看内核日志（= dmesg，等价 _TRANSPORT=kernel）
```

`-t` 和 `-u` 的区别：一个 unit 可能 fork 出多个不同 identifier 的进程（如 `systemd`、`CROND`），`-u` 抓整个 unit 的 cgroup，`-t` 只抓标签。反过来说，容器/脚本起的进程可能没有 unit，只有 identifier。

### 4.3 按优先级

```bash
-p, --priority=RANGE
```

syslog 优先级，**数字越小越严重**：

| 数字 | 名字 | 含义 |
| --- | --- | --- |
| 0 | `emerg` | 系统不可用 |
| 1 | `alert` | 必须立刻处理 |
| 2 | `crit` | 严重 |
| 3 | `err` | 错误 |
| 4 | `warning` | 警告 |
| 5 | `notice` | 正常但重要 |
| 6 | `info` | 一般信息（**默认级别**） |
| 7 | `debug` | 调试 |

两种写法语义**不同**（man）：

```bash
journalctl -p 3                  # 单个值 = err「及更严重」，即 0-3
journalctl -p err                 # 同上
journalctl -p err..crit           # 区间 = 3 到 2，闭区间；注意方向，FROM..TO 写反没结果
journalctl -p 5..7                # 反过来筛 notice/info/debug
```

注意 `-p` 的“及更严重”语义：想**只要** err 不用 `-p 3`，得自己再筛或看输出。常见误用是以为 `-p 3` 只出 err。

### 4.4 按 facility

```bash
--facility=FACILITY         # 可多次给，逗号分隔也可以
```

数字对照（本机实测出现的值：0 1 3 4 5 7 10 18）：

| 值 | 名字 | 值 | 名字 |
| --- | --- | --- | --- |
| 0 | kern | 5 | syslog |
| 1 | user | 6 | lpr |
| 2 | mail | 7 | news |
| 3 | daemon | 8 | uucp |
| 4 | auth | 9 | cron |
| 10 | authpriv | 11 | ftp |
| 16–23 | local0–local7 | 18 = local2 | |

```bash
journalctl --facility=user -n 2          # 本机实测有输出
journalctl --facility=auth,authpriv --since today    # 认证相关
```

### 4.5 按时间与开机

```bash
-b, --boot[=ID]              # 本次开机；-b -1 上一次；-b <BOOT_ID> 指定
--list-boots                 # 列出所有开机记录（配 -b 的编号来源）
-S, --since=DATE
-U, --until=DATE
```

`--since/--until` 的时间格式很宽松，都试过可用：

```bash
journalctl --since today
journalctl --since yesterday --until "today 08:00"
journalctl --since "2026-10-26 00:00:00" --until "2026-10-26 12:00:00"
journalctl --since "-1h"                  # 相对量
journalctl --since "30 min ago"           # 自然语言
journalctl --since "2 min ago"            # 本机实测可用
journalctl --since @1792945324            # Unix 时间戳（@ 前缀）
```

`-b` 的编号来源是本机 `--list-boots` 的 IDX 列（本机实测有 -170 这种很老的记录，说明持久化存了很久）：

```
IDX  BOOT ID                          FIRST ENTRY                 LAST ENTRY
-170 f4e90504d80741e09818431e463d458d Tue 2026-09-08 19:06:23 CST ...
 -1  ...
  0  86d2643493954ec0...               Mon 2026-10-26 00:04:00 CST ...
```

`0` = 当前，`-1` = 上一次。排“上次开机为什么没启动起来”就靠 `-b -1`。

### 4.6 按条数与游标

```bash
-n, --lines[=INTEGER]        # 条数，默认 10；-n +N 表示从最旧的第 N 条开始
-c, --cursor=CURSOR          # 从指定游标处开始
--after-cursor=CURSOR        # 从游标之后
--cursor-file=FILE           # 用文件记录进度，下次从这里继续
--show-cursor                # 输出末尾打印游标
```

`-n` 的细节（本机实测）：`-n 20` 出**最后** 20 条；`-n +2` 出**从第 2 条开始往后的全部**（第 2 条是最旧的，输出直接跳到 2026-10-22）。`+` 号是“从头”，不带是“从尾”。

游标（cursor）是不透明字符串，标识日志流中的一个绝对位置，比时间戳精确（同一微秒多条日志时不会漏/重）：

```bash
journalctl --user -u hello-loop -n 1 --show-cursor
# -- cursor: s=59b930...;i=1e94c4;b=86d264...;m=e83484a8;t=65eac9e56b889;x=c3ac1...

journalctl --cursor-file=/tmp/jc.cursor --user -u hello-loop   # 增量拉取
cat /tmp/jc.cursor
```

`--cursor-file` 是做“每次只取新增日志”脚本的正解，比记时间戳可靠。

### 4.7 全文搜索

```bash
-g, --grep=PATTERN           # 对 MESSAGE 做 PCRE2 正则匹配
--case-sensitive[=BOOL]      # 强制大小写敏感/不敏感
```

默认**大小写不敏感**（本机实测 `-g CST` 和 `-g cst` 结果一样）。journalctl 262 编译带 `+PCRE2`，所以支持完整正则：

```bash
journalctl -g 'timeout|timed out' -b
journalctl --case-sensitive=yes -g 'Failed to set mode'
```

`-g` 只搜 `MESSAGE` 字段。要搜别的字段用字段匹配或 `-o json` + jq。

### 4.8 字段匹配（最强力）

任何字段都能直接当过滤器写，格式 `FIELD=value`，多个是 AND：

```bash
journalctl _COMM=bash                    # 按进程名（可执行文件名，可能被截断到 15 字符）
journalctl _PID=1351                     # 按 PID
journalctl _UID=1000 --since today       # 按用户
journalctl _GID=1000
journalctl _SYSTEMD_UNIT=hello-loop.service
journalctl _SYSTEMD_USER_UNIT=hello-loop.service
journalctl _TRANSPORT=stdout             # 只要 stdout 来的
journalctl PRIORITY=3 SYSLOG_IDENTIFIER=bluetoothd
```

`_` 开头的字段是 journald **自动附加**的（写日志那一刻的进程属性）；不带 `_` 的（`MESSAGE`、`PRIORITY`、`SYSLOG_IDENTIFIER`、`SYSLOG_FACILITY`）是**写入方提供**的。这个区别在过滤的可信度上有意义，见 [第 7 节](#7-字段体系一条日志到底有什么)。

---

## 5. 输出格式 -o 全表

```bash
journalctl -o FORMAT    # 长格式 --output=FORMAT
```

一共 **16 种**：`--help` 里列了 15 种，另外 `short-delta` 未列入 help 但本机实测可用。（右列为本机实测样例）

| FORMAT | 用途 | 本机实测样例 |
| --- | --- | --- |
| `short` | **默认**，syslog 风格 | `10月 26 00:22:24 fedora bash[31761]: ...` |
| `short-precise` | 加微秒 | `10月 26 00:22:19.127179 fedora bash[31761]: ...` |
| `short-iso` | ISO 8601 时间 | `2026-10-26T00:22:24+0800 fedora bash[31761]: ...` |
| `short-iso-precise` | ISO + 微秒 | 同上带 `.127179` |
| `short-full` | 完整星期/日期/时区 | `Mon 2026-10-26 00:22:24 CST fedora bash[31761]: ...` |
| `short-monotonic` | 相对本次开机的秒数 | `[38757.383831] fedora bash[31761]: ...` |
| `short-unix` | Unix 时间戳 | `1792945344.133257 fedora bash[31761]: ...` |
| `short-delta` | 与上条的时间差（262 新增） | 带 `(+0.005s)` |
| `verbose` | 全字段逐行（旧格式） | 见下 |
| `export` | 二进制安全导出，`\n\n` 分隔 | 给程序消费 |
| `json` | 每行一个 JSON | 给 jq |
| `json-pretty` | 格式化 JSON | 人读 |
| `json-sse` | Server-Sent Events | 浏览器流 |
| `json-seq` | RFC 7464 `\x1e` 前缀 | 严格流解析 |
| `cat` | **只出 MESSAGE** | `2026年 10月 26日 星期一 00:22:19 CST` |
| `with-unit` | short + 完整 unit 路径 | `... fedora user@1000.service/hello-loop.service[31761]: ...` |

选型建议：

- 人看日常 → `short` 或 `short-full`（跨天看日志一定要 `short-full`，`short` 不带年份）
- 脚本解析 → `cat`（只要消息）或 `json` + jq
- 排查 unit 归属混乱 → `with-unit`（user 服务的 `_SYSTEMD_UNIT` 是 `user@1000.service`，`with-unit` 才把真正的用户单元显示出来）
- 校准时序 → `short-monotonic` 或 `short-delta`

`verbose` 实测长这样（每字段一行，适合看清到底带哪些元数据）：

```
Mon 2026-10-26 00:22:24.133257 CST [s=59b930fa...;i=1e94c4;b=86d264...]
    SYSLOG_FACILITY=3
    _UID=1000
    _GID=1000
    _SELINUX_CONTEXT=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
    _AUDIT_SESSION=1
    _SYSTEMD_UNIT=user@1000.service
    _MACHINE_ID=6d8f51bc6a14456c9baa1cddb2e4763c
    _HOSTNAME=fedora
    ...
```

`json` 字段裁剪（`verbose`/`export`/`json*` 都支持）：

```bash
journalctl -o json-pretty --output-fields=MESSAGE,PRIORITY,_PID,SYSLOG_IDENTIFIER -n 1
```

---

## 6. 输出控制选项

| 选项 | 作用 |
| --- | --- |
| `-r, --reverse` | 最新在前（`-n` 变成“最近 N 条倒序”） |
| `--utc` | 时间用 UTC（跨时区对比、对服务器日志必备） |
| `-x, --catalog` | 附加消息解释（来自 message catalog，覆盖命中才有） |
| `-W, --no-hostname` | 隐藏主机名，省宽度 |
| `--no-full` | 长字段省略号截断（默认行为，配合 `-a` 反之） |
| `-a, --all` | 显示全部字段，含超长与不可打印字符 |
| `--truncate-newline` | 多行消息只留第一行 |
| `-f, --follow` | 实时跟踪尾部（等价 `tail -f`） |
| `--no-tail` | 跟进模式下**先打印全部历史**再实时（默认只打印尾部 10 条） |
| `-q, --quiet` | 不打印“普通用户查系统日志”之类的提示与权限警告 |
| `--show-cursor` | 末尾打印游标 |
| `--no-pager` | 不调用 less（脚本里必加） |
| `-e, --pager-end` | 打开分页器时直接跳到末尾 |
| `--synchronize-on-exit[=BOOL]` | 退出前等待日志同步落盘（258 起，仅 `-f` 模式） |

几个组合的实战意义：

```bash
# 服务重启中实时看，且要看到之前的历史
journalctl --user -u hello-loop -f --no-tail

# 每天早上把昨天的错误整段转存
journalctl --utc --since yesterday --until today -p err -x > /tmp/daily.log

# 日志里有超长 JSON 参数，默认被截断，要看全
journalctl -a -n 1 -o cat

# 一行里塞了多行 stack trace，只要首行
journalctl -u myapp --truncate-newline -n 50
```

`-x` 的实测提醒：message catalog 只覆盖 systemd 自己产生的一部分消息 ID，第三方程序的消息（如 `bluetoothd: Failed to set mode`）不会有解释。别指望它是万能说明。

`-f` + `-n` 的关系：`-f` 默认内置 `-n 10`；`-n 0 -f` 只要新增；`--no-tail -f` 要全部历史再跟进。

---

## 7. 字段体系：一条日志到底有什么

本机 `journalctl --fields` 输出 **331 个**字段名。别背，按类别理解 + 会用 `-N`/`-F` 探索就行。

### 7.1 探索命令

```bash
journalctl -N                      # == --fields，列出当前日志里出现过的所有字段名
journalctl -F PRIORITY             # == --field=，列出该字段的所有取值
journalctl -F _TRANSPORT
journalctl -o json --since today | jq -r 'keys[]' | sort -u   # 也一样
```

### 7.2 三类字段

**① 基础字段（写入方给）**

| 字段 | 含义 |
| --- | --- |
| `MESSAGE` | 正文 |
| `PRIORITY` | 0–7，见 4.3 |
| `SYSLOG_IDENTIFIER` | syslog 标签，`-t` 过滤的就是它 |
| `SYSLOG_FACILITY` | facility 数字，`--facility` 过滤 |
| `SYSLOG_RAW` | 原始未解析的 syslog 行（原样保留） |
| `TID` / `PID` | 线程/进程号（写入方自己报的，可能与 `_PID` 不同） |
| `CODE_FILE` / `CODE_LINE` / `CODE_FUNC` | 代码位置（用 `sd_journal_send` 时可带） |

**② 信任字段（`_` 前缀，journald 自己采集）**

这些是**内核/系统替你填的**，进程伪造不了，所以叫 trusted：

| 字段 | 含义 |
| --- | --- |
| `_PID` `_UID` `_GID` | 真实进程/用户/组 |
| `_COMM` | 进程名（comm，最长 15 字符，会被截断） |
| `_EXE` | 可执行文件绝对路径 |
| `_CMDLINE` | 完整命令行 |
| `_HOSTNAME` | 主机名 |
| `_TRANSPORT` | 日志来源，见第 1 节 |
| `_SYSTEMD_UNIT` | **系统** unit 名 |
| `_SYSTEMD_USER_UNIT` | **用户** unit 名（user 服务看这个） |
| `_SYSTEMD_CGROUP` | cgroup 路径（定位真实归属最可靠） |
| `_SYSTEMD_SLICE` / `_SYSTEMD_USER_SLICE` | slice |
| `_SYSTEMD_INVOCATION_ID` | 本次运行 ID，配 `--invocation` |
| `_BOOT_ID` | 本次开机 ID，配 `-b` |
| `_MACHINE_ID` | 机器 ID |
| `_SELINUX_CONTEXT` | SELinux 上下文 |
| `_AUDIT_SESSION` / `_AUDIT_LOGINUID` | 审计会话 / 登录 UID |
| `_CAP_EFFECTIVE` | 有效 capabilities |
| `_RUNTIME_SCOPE` | system / user |

> [!warning] `_` 字段描述的是“写日志的那个进程”，不是“日志内容是关于谁”
> 例如 `sudo` 执行的脚本里个进程的 `_UID` 是 1000 还是 0，取决于实际 exec 的进程身份，不是你以为的调用者。另外，日志经管道/子进程转发时（`echo | systemd-cat`），`_PID`/`_EXE` 指向的是 `systemd-cat`，不是产生内容的那一方；某些字段（`_CMDLINE` 等）可能根本缺失。想精确定位归属，看 `_SYSTEMD_CGROUP`。

**③ 特殊/内部字段（`__` 双下划线）**

`__CURSOR`、`__REALTIME_TIMESTAMP`（微秒）、`__MONOTONIC_TIMESTAMP`、`__SEQNUM`、`__SEQNUM_ID` —— 这些是 journal 文件格式的内部记账字段，`-o json` 里能看到，一般不用手写过滤。

### 7.3 用 jq 做字段级分析

```bash
# 统计最近一天各进程的日志条数 top 10
journalctl --since today -o json --no-pager \
  | jq -r '._COMM // "unknown"' | sort | uniq -c | sort -rn | head

# 只挖 stdout 来的、且包含 error 的消息
journalctl -o json --since today --no-pager \
  | jq -r 'select(._TRANSPORT=="stdout") | select(.MESSAGE|test("error";"i")) | .MESSAGE'

# 找出所有级别的分布，确认 -p 该设到哪
journalctl -o json --since today --no-pager | jq -r '.PRIORITY' | sort | uniq -c

# 按 unit 汇总今天每条日志
journalctl -o json --since today --no-pager \
  | jq -r '._SYSTEMD_USER_UNIT // ._SYSTEMD_UNIT // "-"' | sort | uniq -c | sort -rn
```

---

## 8. 往里写：怎么让程序产出好日志

### 8.1 服务：什么都不用做

systemd 服务把 stdout/stderr 直接接到 journal，`StandardOutput=journal` 是默认值。所以程序 **`print` / `console.log` 就行**，不要自己写文件、不要自己加时间戳——journald 会自动加。

```ini
[Service]
ExecStart=/usr/local/bin/myapp
# 默认即 StandardOutput=journal / StandardError=journal
# 想让 stderr 进 err 级别而 stdout 进 info：
StandardError=journal
LogExtraFields=APP=myapp ENV=prod   # 给每条日志附加自定义字段，超好用
```

`LogExtraFields=`（systemd 240+）是排障利器：给某服务的所有日志打上标记，之后 `journalctl APP=myapp` 一把捞全，哪怕它 fork 了子进程。

### 8.2 `systemd-cat`：临时命令也进 journal

```bash
echo "hello from systemd-cat" | systemd-cat -t mytest-tag       # 本机实测
systemd-cat -t mytest-tag2 env TESTVAR=1 bash -c 'echo "with field"'
journalctl -t mytest-tag -n 3
```

常用参数：`-t TAG`（identifier）、`-p PRIORITY`（如 `-p err`）、`--stderr-priority=`。适合把 cron/备份脚本的输出纳入统一日志，而不是散在 `/var/log`。

### 8.3 `logger`：syslog 协议

```bash
logger -t backup "备份完成"
logger -p local0.err -t myapp "出错了"
logger -i "带 PID"
```

`logger` 走 `/dev/log` 的 syslog socket，`_TRANSPORT=syslog`。和 `systemd-cat` 的区别：前者是 syslog 兼容层，后者是原生 journal 协议。

### 8.4 原生 API（带自定义字段）

C 用 `sd_journal_send()`，Python 用 `systemd.journal`：

```python
# pip install systemd-python   （或直接用 systemd-cat 兜底）
from systemd import journal
journal.send("任务失败", PRIORITY=journal.LOG_ERR, JOB="nightly", RETRY=3)
```

```bash
journalctl -o json JOB=nightly | jq .
```

自定义字段（全大写、无 `_` 前缀）会原样保存，可以拿来做业务维度过滤。注意：**不能被 `-g` 搜到**（`-g` 只搜 MESSAGE），要用 `FIELD=` 匹配。

---

## 9. 磁盘管理与维护

日志能吃掉不少空间。本机实测 `journalctl --disk-usage` = **1009.4M**。

### 9.1 查看

```bash
journalctl --disk-usage                # 总计
du -sh /var/log/journal                # 目录视角
ls -la /var/log/journal/<machine-id>/  # 文件列表与时间
journalctl --verify                    # 完整性校验（损坏会报 FSE 错误）
journalctl --header                    # 单文件元信息
```

### 9.2 清理（三种口径，二选一）

```bash
sudo journalctl --vacuum-size=500M     # 总量压到 500M 以下，从最旧删
sudo journalctl --vacuum-time=14d      # 只留 14 天
sudo journalctl --vacuum-files=20      # 只留最近 20 个文件
```

`--vacuum-*` 只删**归档**文件，正在写的活动文件不受影响；也不能删掉当前 boot 的日志。加 `--rotate` 先手动切一刀再删，能删得更彻底：

```bash
sudo journalctl --rotate && sudo journalctl --vacuum-time=7d
```

### 9.3 其它维护命令

```bash
journalctl --flush             # /run → /var 迁移（开机时 systemd-journal-flush 自动做）
journalctl --sync              # 强制把未落盘的消息写到磁盘
journalctl --rotate            # 立即切分活动文件
journalctl --relinquish-var    # 停止写磁盘，退回 volatile（磁盘满时的应急手段）
journalctl --smart-relinquish-var   # 同上，但日志目录不在根分区时不做
```

`--relinquish-var` 的典型场景：磁盘被日志写满、连 `sudo` 都动不了。先让它别写了，再想办法清。

### 9.4 定时清理的正确姿势

不要用 cron + vacuum 脚本，用配置里的 `SystemMaxUse=` 让 journald 自己滚动删除（见下节）。`--vacuum-*` 是应急手搓工具。

---

## 10. journald.conf 配置全表

文件：`/etc/systemd/journald.conf`（不存在就新建），或 `/etc/systemd/journald.conf.d/xxx.conf`。改完：

```bash
sudo systemctl restart systemd-journald
journalctl --disk-usage          # 确认生效
```

### 10.1 关键选项

**存储与容量**

| 选项 | 默认 | 说明 |
| --- | --- | --- |
| `Storage=` | `persistent`（本机） | `volatile`/`persistent`/`auto`/`none`，见 2.1 |
| `SystemMaxUse=` | 空＝10% 文件系统，上限 4G | 持久日志**总量上限**，如 `500M`、`2G` |
| `SystemKeepFree=` | 空＝15% 文件系统，上限 4G | 保证磁盘至少剩这么多可用空间 |
| `SystemMaxFileSize=` | 空 | 单个文件上限，决定 vacuum 的粒度 |
| `RuntimeMaxUse=` | 空＝10%，上限 4G | `/run` 里易失日志的上限 |
| `RuntimeKeepFree=` | 空＝15%，上限 4G | 同上，保留空闲空间 |
| `RuntimeMaxFileSize=` | 空 | 同上，单文件 |
| `MaxRetentionSec=` | `0`（不限） | 按**时间**淘汰，`1month`、`2weeks`；注意是“保留多久” |
| `MaxFileSec=` | `1month` | 单文件最长跨多久就轮转 |
| `Compress=yes` | `yes` | 压缩归档文件（本机编译带 LZ4/XZ/ZSTD） |
| `Seal=yes` | `yes` | FSS 签名，防篡改 |
| `SplitMode=` | `uid` | `uid`=按 UID 分 `user-1000.journal`；`none`=全塞 system.journal；`login`=按会话 |
| `SyncIntervalSec=` | `5m` | 内存缓冲刷盘间隔（err 及以上会立即刷） |

> [!tip] `SystemMaxUse` 怎么给
> 桌面机 500M–1G 够用；服务器按“日志保留天数 × 日均量”估，并且**一定**设 `SystemKeepFree`，否则日志能把根分区塞满导致整机挂掉。`MaxRetentionSec=1month` + `SystemMaxUse=1G` 一起用是最省心的组合：谁先到按谁删。

**转发（与 rsyslog / 控制台共存）**

| 选项 | 默认 | 说明 |
| --- | --- | --- |
| `ForwardToSyslog=` | `no` | 转发给 rsyslog（装了才需要开） |
| `ForwardToKMsg=` | `no` | 转发进内核环形缓冲 |
| `ForwardToConsole=` | `no` | 转发到当前控制台 TTY |
| `ForwardToWall=` | `yes` | `wall` 广播（重要消息会“弹”到所有终端） |
| `MaxLevelStore=` | `debug` | 存储的最低级别（`info` = 不存 debug） |
| `MaxLevelSyslog=` | `debug` | 转发 syslog 的最低级别 |
| `MaxLevelKMsg=` | `notice` | 转发 kmsg 的最低级别 |
| `MaxLevelConsole=` | `info` | 转发 console 的最低级别 |
| `MaxLevelWall=` | `emerg` | 广播的最低级别 |
| `ReadKMsg=` | `yes` | 读 `/dev/kmsg`（`-k` 能有内容靠它） |
| `Audit=` | `yes` | 接收内核审计消息 |

**限流（日志“莫名少了一段”的元凶）**

| 选项 | 默认 | 说明 |
| --- | --- | --- |
| `RateLimitIntervalSec=` | `30s` | 限流窗口 |
| `RateLimitBurst=` | `10000` | 窗口内每服务最多条数 |

超限后 journald 会**丢弃**该服务在这个窗口内的后续日志，并在日志里留一条 `Suppressed N messages from <service>`（由 `systemd-journald` 自己写）。排查“程序明明狂打日志但 journal 里只有零星几条”，先看这个：

```bash
journalctl -t systemd-journald -g "Suppressed" -b
# 或者直接关掉限流（不推荐长期）
# /etc/systemd/journald.conf: RateLimitIntervalSec=0
```

对单个服务限流更精准，写在 unit 里：

```ini
[Service]
LogRateLimitIntervalSec=0
LogRateLimitBurst=0
```

**查看当前实际生效值**（配置文件里的默认是注释掉的，要知道真值）：

```bash
systemd-analyze cat-config systemd/journald.conf
```

---

## 11. 容器、镜像、命名空间

| 选项 | 用途 |
| --- | --- |
| `-M, --machine=NAME` | 查本地一台 systemd-nspawn / podman 容器的 journal |
| `-m, --merge` | 合并本机所有可见 journal（含容器） |
| `-D, --directory=PATH` | 直接指定 journal 目录 |
| `-i, --file=PATH` | 直接指定单个 `.journal` 文件 |
| `--root=PATH` | 以另一个文件系统根来解析（救援/离线分析） |
| `--image=PATH` | 以磁盘镜像为根（不做挂载，直接读） |
| `--namespace=NAME` | 查某个 journal namespace（`LogNamespace=`） |

```bash
# 从另一台机器拷来的日志文件直接读
journalctl --file=/mnt/usb/system.journal -p err

# 离线修一台起不来的系统，看它的日志
journalctl --root=/mnt/sysroot -b -1 -p err

# 看容器
journalctl -M mycontainer -n 50
```

`--file` / `--root` 的价值：不用把日志灌进本机 journald，直接读文件，也不会污染本机日志。

---

## 12. 排障配方

以下是最常用的十几条，按场景列。

**① 服务起不来**

```bash
systemctl status NAME --no-pager -l     # 先看状态与最后几行
journalctl -u NAME -b -n 100 --no-pager # 本次开机该 unit 全部相关
journalctl -u NAME -x -b                # 带 catalog 解释
journalctl -b -p err                     # 同期全局错误
```

**② 用户服务（`--user`）** —— 别忘了 `--user`

```bash
journalctl --user -u NAME -f
journalctl --user-unit NAME -b -n 200
```

**③ 重启后想看上一次为什么挂的**

```bash
journalctl --list-boots
journalctl -b -1 -p err -x
journalctl -b -1 -u NAME --no-pager
```

**④ 只关心最近一次重启后的日志（服务反复重启）**

```bash
journalctl --user --list-invocations -u NAME
journalctl --user -u NAME -I --no-pager
```

**⑤ 实时跟踪 + 只看错误**

```bash
journalctl -fu NAME -p err          # -fu = -f -u
```

**⑥ 日志被限流了（打了看不到）**

```bash
journalctl -t systemd-journald -b -g Suppressed
systemd-analyze cat-config systemd/journald.conf | grep RateLimit
```

**⑦ 磁盘满 / journal 占太多**

```bash
journalctl --disk-usage
du -sh /var/log/journal
sudo journalctl --rotate && sudo journalctl --vacuum-size=500M
grep -E 'SystemMaxUse|MaxRetention' /etc/systemd/journald.conf
```

**⑧ 内核层问题（硬件、OOM、驱动）**

```bash
journalctl -k -b -p warning..err
journalctl -k -g 'oom|Out of memory'
journalctl -b -g 'thermal|throttl'
```

**⑨ 认证 / sudo / 登录问题**

```bash
journalctl --facility=auth,authpriv --since today
journalctl _COMM=sudo -b
journalctl -u sshd -b -p info
```

**⑩ 程序说它写日志了，但 journal 里没有**

按顺序排除：

```bash
systemctl cat NAME | grep -E 'StandardOutput|StandardError|Type='
# ① Type=forking 没接上 stdout？改成 Type=simple 或显式重定向
# ② 程序自己写文件了？日志不走 stdout，journald 就无从知道
journalctl -t systemd-journald -b | tail -30       # 看 journald 自身报错
journalctl --user -u NAME                          # 用户服务没加 --user 的经典误判
```

**⑪ 想按天归档日志**

```bash
journalctl --since yesterday --until today --utc --no-pager > /tmp/$(date -d yesterday +%F).log
```

**⑫ 导出给别的系统分析**

```bash
journalctl --since "7 days ago" -o export > /tmp/week.journal
journalctl --file=/tmp/week.journal -p err        # 对方机器上读
```

---

## 13. 陷阱清单

1. **`-u --user NAME` 参数错位** —— `-u` 吃掉 `--user`。用 `--user-unit NAME` 或把 `--user` 放最前。
2. **用户服务用系统 journal 查** —— 服务在跑、`-- No entries --`，99% 是漏了 `--user`。
3. **`Storage=volatile/none` 时 `journalctl --user` 无内容** —— man 明确写不支持。
4. **`-p 3` 不是“只要 err”** —— 是“err 及更严重（0–3）”。
5. **`-p FROM..TO` 方向写反** —— 只会得到空结果，不报错。
6. **`short` 格式不带年份** —— 翻跨年日志会看错时间，用 `short-full`。
7. **`_COMM` 被截到 15 字符** —— 长程序名匹配不全，改用 `_EXE`。
8. **`-g` 只搜 MESSAGE** —— 自定义字段、unit 名搜不到，用 `FIELD=value`。
9. **限流悄悄丢日志** —— 默认 `10000/30s`，狂打日志的服务要单独放开。
10. **`SystemMaxUse` 不设 + 磁盘被写满** —— 一定要配 `SystemKeepFree`。
11. **不要 `grep` `/var/log/journal/*.journal`** —— 二进制。用 `journalctl --file`。
12. **`/etc/systemd/journald.conf` 在 Silverblue 上不存在是正常的** —— 默认值在 `/usr/lib/systemd/journald.conf`，自己改就新建 `/etc` 那份。
13. **`echo x | journalctl` 不存在的用法** —— 写日志是 `systemd-cat`，`journalctl` 只读。
14. **`-x` 不是万能的** —— catalog 只覆盖 systemd 自己的消息 ID。
15. **脚本里忘 `--no-pager`** —— 输出会进 less，管道里卡住或格式错乱。

---

## 14. 速查表

```bash
# —— 基本 ——
journalctl                              # 全部日志（从最旧到最新，交给 pager 翻）
journalctl -n 100                       # 最后 100 条
journalctl -f                           # 实时跟踪
journalctl -r                           # 倒序
journalctl -e                           # 直接跳到末尾

# —— 选择范围 ——
journalctl -u NAME                      # 系统 unit
journalctl --user -u NAME               # 用户 unit
journalctl --user-unit NAME             # 同上，更短
journalctl -u NAME -I                   # 该 unit 最近一次运行
journalctl -t TAG                       # 按 syslog 标签
journalctl -k                           # 内核（dmesg）
journalctl -b                           # 本次开机
journalctl -b -1                        # 上次开机
journalctl --list-boots                 # 开机清单
journalctl --since "1 hour ago"
journalctl --since today --until "12:00"
journalctl -p err                       # err 及更严重
journalctl -p warning..err              # 区间
journalctl --facility=auth
journalctl -g 'regex'                   # 搜 MESSAGE
journalctl _PID=1234                    # 字段匹配
journalctl _TRANSPORT=stdout

# —— 输出 ——
journalctl -o cat                       # 只要消息
journalctl -o json-pretty -n 1          # 结构化
journalctl -o with-unit                 # 显示完整 unit 路径
journalctl --output-fields=MESSAGE,PRIORITY -o json
journalctl --utc                        # UTC 时间
journalctl -x                           # 带 catalog 解释
journalctl -a                           # 不截断
journalctl -W                           # 不显示主机名
journalctl --no-pager                   # 脚本必加
journalctl --show-cursor
journalctl --cursor-file=/tmp/c         # 增量

# —— 探索 ——
journalctl -N                           # 所有字段名
journalctl -F PRIORITY                  # 某字段所有取值

# —— 维护 ——
journalctl --disk-usage
journalctl --verify
sudo journalctl --vacuum-size=500M
sudo journalctl --vacuum-time=14d
sudo journalctl --rotate && sudo journalctl --vacuum-files=20
journalctl --flush                      # /run -> /var
journalctl --sync
systemd-analyze cat-config systemd/journald.conf    # 实际生效配置

# —— 写入 ——
echo msg | systemd-cat -t TAG
logger -t TAG -p local0.err "msg"
```

---

## 参考

- `man journalctl`、`man journald.conf`、`man systemd.journal-fields`、`man systemd-cat`、`man logger`（版本与本机一致，优先于在线文档）
- `journalctl --help`（选项列表，本文档的选项分类即按此组织）
- Arch Wiki: *systemd/Journal*、*Systemd#Journal*
- 相关笔记：[[systemd日常使用教程]]、[[systemd-fedora-notes]]、[[必掌握linux命令]]、[[grep用法]]
