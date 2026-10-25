---
date: 2026-10-22
lang: Linux
tags:
  - systemd
  - linux
  - systemd用户服务
  - timer
  - journalctl
  - fedora
  - silverblue
---

# systemd 使用与单元文件编写

面向日常桌面使用。前 5 章讲操作和日志，第 6 章讲单元文件怎么写，第 7 章 timer，第 8 章用户单元。

验证环境：Fedora Silverblue 45 / systemd 262 (262-3.fc45)。文中数字都标了来源：

- **man 原文** —— 引用 `man` 页：版本与本机一致，优先于在线文档。
- **Arch Wiki** —— 交叉核对，文末给出具体页面。
- **本机实测** —— 实际跑出来的输出。

姊妹篇：[[systemd-fedora-notes]]（服务器 / root 视角，cgroup 限制、SELinux、socket 激活）。

---

## 1. systemd 是什么

systemd 是内核启动后执行的第一个进程（PID 1），负责四件事：

| 职责     | 实现                                             |
| ------ | ---------------------------------------------- |
| 启动顺序   | 单元之间的依赖图（`Requires=` / `After=` 等），能并行的并行      |
| 进程生命周期 | 每个单元一个 cgroup，停止单元 = 杀掉整组进程                    |
| 日志     | 程序 stdout/stderr 统一进 journald，用 `journalctl` 查 |
| 定时     | `.timer` 单元，替代 cron                            |

被管理的对象统称 **unit（单元）**，文件名后缀区分类型：

| 后缀                      | 用途                      |
| ----------------------- | ----------------------- |
| `.service`              | 服务、脚本                   |
| `.timer`                | 定时器                     |
| `.socket`               | 套接字激活（有连接才启动服务）         |
| `.target`               | 一组单元的集合，用于分组和同步点        |
| `.mount` / `.automount` | 挂载点                     |
| `.path`                 | 监视文件或目录变化               |
| `.slice`                | cgroup 层级分组             |
| `.scope`                | 外部创建的进程组（systemd 只管不启动） |

日常写的基本只有 `.service` 和 `.timer`。

---

## 2. 基本操作

### 2.1 启停

```bash
systemctl status  NAME.service     # 状态，排查第一步
systemctl start   NAME.service     # 立即启动（本次开机有效）
systemctl stop    NAME.service     # 停止
systemctl restart NAME.service     # 重启
systemctl reload  NAME.service     # 让程序重读配置，不重启进程；需程序支持（ExecReload=）
systemctl enable  NAME.service     # 设为开机自启（下次开机生效，现在不启动）
systemctl disable NAME.service     # 取消自启（现在不停）
systemctl enable --now NAME.service  # 两步合一
```

`enable` 和 `start` 是两件事，不能互相替代：

- `enable` 只是在 `<target>.wants/` 里建一个符号链接，决定下次开机要不要拉起。
- `start` 是现在就拉起。
- 所以 `enable` 之后进程没跑是正常的，需要 `start` 或 `enable --now`。

### 2.2 enable 具体做了什么

```console
$ systemctl --user enable --now hello-loop.service
Created symlink '/var/home/smile/.config/systemd/user/default.target.wants/hello-loop.service'
         → '/var/home/smile/.config/systemd/user/hello-loop.service'.
```

系统级对应 `multi-user.target.wants/` 下的链接。`disable` 就是删这个链接。

### 2.3 mask

| 操作 | 效果 | 场景 |
| --- | --- | --- |
| `disable` | 取消自启，仍可手动启动，也可被其他单元依赖拉起 | 不再需要 |
| `mask` | 链接到 `/dev/null`，任何方式都无法启动 | 彻底禁用某个单元 |
| `unmask` | 解除 | 撤销 |

### 2.4 查询

```bash
systemctl list-units --type=service --state=running   # 正在运行的服务
systemctl list-unit-files --state=enabled             # 开机自启清单
systemctl --failed                                    # 失败的单元
systemctl list-units --type=target                    # 当前 target
systemctl get-default                                 # 默认 target
systemctl list-dependencies NAME.service              # 依赖树
```

### 2.5 系统级与用户级

所有命令都分两套：不带 `--user` 是系统级（root，需要 sudo），带 `--user` 是当前用户的实例。

```bash
systemctl --user status  hermes-gateway.service
systemctl --user restart hermes-gateway.service
journalctl --user -u hermes-gateway.service -f
```

判断标准：**不需要 root 的东西就放 `--user`**。区别详见第 8 章。

---

## 3. status 输出怎么读

本机真实输出（`hello-loop.service`）：

```text
● hello-loop.service - 每5秒打印一次时间
     Loaded: loaded (/var/home/smile/.config/systemd/user/hello-loop.service; enabled; preset: disabled)
    Drop-In: /usr/lib/systemd/user/service.d
             └─10-timeout-abort.conf
     Active: active (running) since Thu 2026-10-22 16:24:59 CST; 10s ago
 Invocation: f824b9a3e3b74284baac522b359b145c
   Main PID: 33274 (bash)
      Tasks: 2 (limit: 56662)
     Memory: 1.8M (peak: 2.6M)
        CPU: 28ms
     CGroup: /user.slice/user-1000.slice/user@1000.service/app.slice/hello-loop.service
             ├─33274 /usr/bin/bash -c "while true; do echo \"$(date)\"; sleep 5; done"
             └─33357 sleep 5
```

| 行 | 含义 |
| --- | --- |
| `●` / `×` | 实心圆正常，`×` 表示 failed |
| `Loaded:` | 从哪个文件加载；`enabled` = 已设自启；`preset:` = 发行版出厂默认是否启用（Fedora 由 preset 文件决定），与 `enabled` 不一致是正常的 |
| `Drop-In:` | 叠加在这个单元上的补丁文件（第 5 章）。出现它说明配置被改过 |
| `Active:` | 宏观状态：`active (running)` 常驻；`active (exited)` 一次性任务跑完；`failed`；`inactive (dead)` |
| `Main PID` | 主进程号，其他进程在下面的 CGroup 树里 |
| `Tasks` / `Memory` / `CPU` | 实时资源，`peak` 是峰值 |
| `CGroup:` | 这个单元包含的全部进程。停止单元杀的是这一整组，不是单个 PID |

`bad-setting` 需要单独注意：`Loaded: bad-setting` 表示配置文件解析失败，单元**不会被启动**。但 `Active:` 那一行可能仍是 `active (running)`——因为 `daemon-reload` 不会杀掉已经在跑的旧进程。不要被 `active` 误认为配置正常。

`--failed` 里出现的东西不一定真故障。本机长期有一条：

```text
● systemd-remount-fs.service loaded failed failed Remount Root and Kernel File Systems
mount: /: fsconfig() failed: overlay: No changes allowed in reconfigure.
```

Silverblue 的根是只读 overlay，remount 必然失败，属于预期噪声。判断方法：看它的 journal，报错内容与你的使用无关就忽略。

---

## 4. 日志：journald 与 journalctl

> 本节只列日常最高频的几条。`journalctl` **全部选项**、字段体系、`journald.conf` 调优、限流与磁盘管理见专篇：[[journalctl与journald详解]]。

### 4.1 常用查询

```bash
journalctl -u NAME.service                   # 某个单元
journalctl -u NAME.service -b                # 本次开机
journalctl -u NAME.service -f                # 实时跟随
journalctl -u NAME.service -n 200            # 最近 200 条
journalctl -u NAME.service --since today     # 今天
journalctl -p warning..emerg -b              # 优先级区间：warning 到 emerg
journalctl --since "30 min ago" --until now  # 时间窗口，支持自然语言
journalctl -b -1                             # 上一次开机的全部日志
journalctl -b -1 -u NAME.service             # 上次开机时这个单元说了什么
journalctl -k                                # 内核日志（= dmesg）
journalctl -t bash                           # 按 SYSLOG_IDENTIFIER
journalctl --list-boots                      # 所有启动记录，供 -b 编号
```

### 4.2 输出格式

| `-o`                   | 输出                | 用途                |
| ---------------------- | ----------------- | ----------------- |
| `short`（默认）            | 时间 主机 进程[pid]: 内容 | 日常                |
| `short-precise`        | 带微秒               | 看时序               |
| `cat`                  | 只有内容              | 配合 `wc -l`、`grep` |
| `verbose`              | 全部元数据字段           | 排查归属、环境、优先级问题     |
| `json` / `json-pretty` | 结构化               | 交给 `jq`           |

### 4.3 用户单元必须加 `--user`

这是最常见的误判来源。`hello-loop` 是用户单元：

```console
$ journalctl -u hello-loop.service
-- No entries --

$ journalctl --user -u hello-loop.service | wc -l
67
```

`man journalctl` 对匹配规则的说明：

> `-u, --unit=`：For each unit name, a match is added for messages from the unit (`_SYSTEMD_UNIT=UNIT`) ...
> `--user-unit=`：This will add a match for messages from the unit (`_SYSTEMD_USER_UNIT=` and `_UID=`)

用户单元的记录带的是 `_SYSTEMD_USER_UNIT`，`-u` 只找 `_SYSTEMD_UNIT`，所以匹配不到。

判断方法：带上 `--user` 后能否看到 `Started ...` 那一行。看得到说明作用域正确；看不到就是漏了 `--user`。

`--user-unit` 是等价写法，语义更明确：

```bash
journalctl --user-unit hello-loop.service -f
```

### 4.4 持久化与清理

```bash
ls -d /var/log/journal     # 存在即已持久化
journalctl --disk-usage    # 当前占用（本机实测 961.4M）
journalctl --verify        # 校验日志文件完整性
journalctl --flush         # 把 /run 里的日志刷入 /var
```

清理：

```bash
sudo journalctl --vacuum-size=500M     # 只留最近 500M
sudo journalctl --vacuum-time=14d      # 只留 14 天
sudo journalctl --vacuum-files=20      # 只留最近 20 个归档
```

永久限制写在 `/etc/systemd/journald.conf` 的 `SystemMaxUse=` / `MaxRetentionSec=`，改完 `sudo systemctl restart systemd-journald`。

默认只存内存（`/run/log/journal`），重启即丢。开启持久化：

```bash
sudo mkdir -p /var/log/journal
sudo systemctl restart systemd-journald
```

### 4.5 字段检索

每条记录都带元数据，字段分两类：

| 类别 | 字段 | 生成方式 | 进程退出后是否还在 |
| --- | --- | --- | --- |
| 内核盖章 | `_PID` `_UID` `_GID` `_SELINUX_CONTEXT` | 连接建立时内核随数据附带（`SCM_CREDENTIALS`） | 在 |
| journald 事后查 `/proc` | `_COMM` `_EXE` `_CMDLINE` `_SYSTEMD_CGROUP` `_SYSTEMD_UNIT` `_SYSTEMD_USER_UNIT` | journald 按 PID 反查 | **可能缺失** |

`man systemd.journal-fields` 对第二类的定义是「the name, the executable path, and the command line of **the process** the journal entry originates from」「the control group path ... the systemd unit name ... **of the process**」。这些字段描述的是**写日志那个进程的归属**，不是内容的来源。

用法：

```bash
journalctl _COMM=hermes                  # 按进程名
journalctl _PID=1351                     # 按 PID
journalctl _UID=1000 --since today       # 按用户
journalctl -o json --since today | jq -r 'select(._TRANSPORT=="stdout") | .MESSAGE'
```

### 4.6 归属字段缺失：`-u` 查不到但日志存在

现象：服务在运行，`journalctl --user -u` 只有一行 `Started ...`，之后什么都没有。

用 `--user` 和 `-o verbose` 对比两类记录：

```text
# systemd 自己产生的（能被 -u 匹配）
_TRANSPORT=journal
_COMM=systemd
_SYSTEMD_UNIT=user@1000.service
_SYSTEMD_USER_UNIT=init.scope
USER_UNIT=hello-loop.service          ← 依赖这个字段命中

# 该服务输出的记录（不能被 -u 匹配）
_TRANSPORT=stdout
_PID=27457
SYSLOG_IDENTIFIER=bash
（没有 _COMM、没有 _SYSTEMD_CGROUP、没有 _SYSTEMD_USER_UNIT）
```

内容没丢，丢的是归属字段。触发条件是**写日志的进程存活时间极短**：`hello-loop` 最初用的是

```ini
ExecStart=/usr/bin/bash -c 'while true; do date; sleep 5; done'
```

真正向 journal 写入的是 `bash` fork 出来的 `date`，它写完 1 毫秒就退出，journald 事后查 `/proc` 时已经查不到它的 cgroup。

#### 这不是必然结果，是竞态

对照实验（临时单元，跑完即删）：

| 实验 | 写日志的进程 | 结果 |
| --- | --- | --- |
| `systemd-run --user --wait /usr/bin/date` | `date` 当主进程，存活 1ms | 字段齐全（`_COMM=date`、`_SYSTEMD_CGROUP=.../diag-A.service`） |
| `systemd-run --user --wait /bin/bash -c 'date'` | `date` 是 bash 子进程，存活 1ms | 字段齐全 |
| `systemd-run --user /bin/bash -c 'for i in 1 2 3; do date; sleep 1; done'` | 同上，连续 3 条 | 3 条全部缺 unit |
| `hello-loop.service`（`date` 版），运行 20 分钟 | 同上，每 5 秒一条 | 253 条全部缺 `_SYSTEMD_USER_UNIT` |

固定窗口 10:38:00–11:00:00 内全部 `_TRANSPORT=stdout` 记录：

| 写入者 | 条数 | 有 `_COMM` | 有 `_SYSTEMD_USER_UNIT` |
| --- | --- | --- | --- |
| `hello-loop` 的 `date` | 253 | 11 | **0** |
| `diag-E` 的 `date` | 3 | 3 | **0** |
| `diag-A` / `diag-G` 的 `date` | 2 | 2 | 2 |
| `diag-P` 的 bash 内建 `printf` | 5 | 5 | 5 |
| 长命服务 `hermes` 自身输出 | 1 | 1 | 1 |

同一个 1 毫秒的 `date`，有的记录补上了、有的没补上，说明这是竞态而非固定规则。`hello-loop` 这种"每 5 秒产生一个瞬时写手"的结构稳定地输掉竞态。**关键字段是 `_SYSTEMD_USER_UNIT`，`_COMM` 补上没有意义。**

#### 处理方式

一、让常驻进程自己写。`printf` 是 bash 内建，不再 fork 子进程：

```ini
ExecStart=/usr/bin/bash -c 'while true; do printf "%%(%%F %%T %%Z)T\n" -1; sleep 5; done'
```

注意 `%%`（见 6.10）。不想处理转义就用不含 `%` 的等价写法：

```ini
ExecStart=/usr/bin/bash -c 'while true; do echo "$(date)"; sleep 5; done'
```

这里 `date` 依然被 fork，但它的输出走管道被 `$(...)` 取回，**真正写 journal 的是 bash 自己**。实测两种写法各 3 条记录全部带 `_SYSTEMD_USER_UNIT`。

二、不走 journald：

```ini
StandardOutput=append:%h/hello-loop.log
```

`StandardOutput=` 的全部取值（`man systemd.exec`）：`inherit` / `null` / `tty` / `journal`（默认）/ `kmsg` / `journal+console` / `kmsg+console` / `file:path` / `append:path` / `truncate:path` / `socket` / `fd:name`。

三、接受现状，换过滤方式：

```bash
journalctl --user -t bash                       # 按 SYSLOG_IDENTIFIER，会混入其他 bash 输出
journalctl --user _STREAM_ID=389bb17da17849eda846e361f579a2a0    # 精确，但重启服务后 ID 变化
```

`_STREAM_ID` 的定义（`man systemd.journal-fields`）：

> Only applies to `_TRANSPORT=stdout` records: specifies a randomized 128-bit ID assigned to the stream connection when it was first created. This ID is useful to reconstruct individual log streams from the log records.

#### 适用范围

只有"服务的全部输出都由 fork 出来的短命命令产生"时才会遇到。长命主进程自己写日志的服务不受影响（本机 `hermes-gateway.service` 16730 条全部带归属字段）。

### 4.7 排错顺序

```bash
systemctl status NAME.service            # 1. 退出码、失败原因、LoadState
journalctl --user -u NAME -b -n 100      # 2. 它自己说了什么
systemctl cat NAME.service               # 3. 实际生效的配置（含 drop-in）
```

大部分问题这三步能定位。仍然不清楚时：

```bash
systemd-analyze verify /path/to/NAME.service   # 语法
systemctl show NAME.service                    # 全部生效属性
journalctl --user -o verbose -n 20             # 字段是否完整
```

---

## 5. 配置文件：放在哪、怎么覆盖

### 5.1 加载路径

**系统级**（root）：

| 路径 | 说明 |
| --- | --- |
| `/usr/lib/systemd/system/` | 软件包提供的原始文件，不要修改（Silverblue 上是只读的） |
| `/run/systemd/system/` | 运行时覆盖，重启丢失 |
| `/etc/systemd/system/` | 管理员配置，优先级最高 |

**用户级**：

| 路径 | 说明 |
| --- | --- |
| `/usr/lib/systemd/user/` | 软件包提供 |
| `/run/user/1000/systemd/user/` | 运行时 |
| `~/.config/systemd/user/` | 自己的配置，优先级最高 |

本机实际的搜索顺序（`systemctl --user show -p UnitPath --value`）：

```text
/var/home/smile/.config/systemd/user.control
/run/user/1000/systemd/user.control
/run/user/1000/systemd/transient
/run/user/1000/systemd/generator.early
/var/home/smile/.config/systemd/user          ← 放这里
/var/home/smile/.config/systemd/user.attached
/etc/systemd/user
/run/user/1000/systemd/user
/run/systemd/user
/usr/lib/systemd/user
```

### 5.2 drop-in：不改原文件

```bash
systemctl --user edit NAME.service
```

打开一个空文件，只写要改的行，保存后生成 `~/.config/systemd/user/NAME.service.d/override.conf`。系统级对应 `/etc/systemd/system/NAME.service.d/override.conf`。原文件不动，发行版更新不会覆盖。

| 命令 | 生成 | 用途 |
| --- | --- | --- |
| `systemctl edit NAME` | `NAME.d/override.conf`，只写差异 | 改几行时首选 |
| `systemctl edit --full NAME` | `/etc/systemd/system/NAME.service` 完整副本 | 大改或重写 |
| `systemctl edit --runtime NAME` | `/run/...` 临时覆盖，重启失效 | 调试 |

注意：`systemctl edit` 需要 tty，脚本里调用会报 `Cannot edit units interactively if not on a tty.`。自动化场景直接手写 override 文件，效果相同：

```console
$ mkdir -p ~/.config/systemd/user/probe2.service.d
$ printf '[Service]\nEnvironment=PROBE_FLAG=on\n' > ~/.config/systemd/user/probe2.service.d/override.conf
$ systemctl --user daemon-reload
$ systemctl --user show probe2.service -p Environment --value
PROBE_FLAG=on
```

### 5.3 看最终生效的配置

```bash
systemctl cat NAME.service        # 原文件 + 所有 drop-in，按加载顺序拼接
systemctl show NAME.service       # 解析后的全部属性（最准确）
systemctl show NAME.service -p ExecStart -p Restart -p KillMode
```

`systemctl cat` 的输出示例（注意 drop-in 叠加在原文件之后）：

```text
# /var/home/smile/.config/systemd/user/probe2.service
[Service]
Type=oneshot
ExecStart=/usr/bin/true

# /usr/lib/systemd/user/service.d/10-timeout-abort.conf
[Service]
TimeoutStopFailureMode=abort

# /var/home/smile/.config/systemd/user/probe2.service.d/override.conf
[Service]
Environment=PROBE_FLAG=on
```

中间那段没人写过——Fedora 给所有用户服务统一叠了一层补丁。

`show -p ExecStart` 显示的是实际执行的 argv，验证参数是否按预期拆解时用它：

```console
$ systemctl --user show hello-loop.service -p ExecStart
ExecStart={ path=/usr/bin/bash ; argv[]=/usr/bin/bash -c while true; do echo "$(date)"; sleep 5; done ; ... }
```

### 5.4 什么时候要 daemon-reload

| 改了什么 | 需要 `daemon-reload` |
| --- | --- |
| 新建、删除、修改 `.service` / `.timer` 文件 | 需要 |
| 新建或修改 `.d/override.conf` | 需要 |
| 用 `systemctl edit` 修改 | 不需要（它会自动 reload） |
| 只改 unit 引用的外部脚本内容 | 不需要，但要 `restart` 那个服务 |

标准流程：

```bash
systemctl --user daemon-reload
systemctl --user restart NAME.service
systemctl --user status NAME.service
```

### 5.5 撤销

```bash
systemctl revert NAME.service        # 删除所有 drop-in 和完整覆盖
systemctl revert --runtime NAME.service
```

---

## 6. 单元文件怎么写

### 6.1 三个段

```ini
[Unit]        # 描述、依赖、条件
[Service]     # 怎么执行（.service 专有；.timer 换成 [Timer]）
[Install]     # 什么时候自启（只有 enable 用到）
```

`.service` 必须有 `[Service]`，`.timer` 必须有 `[Timer]`；`[Unit]` 和 `[Install]` 两者通用。

### 6.2 `[Unit]`：描述类指令

| 指令 | 作用 |
| --- | --- |
| `Description=` | 一句话说明，显示在 `status` 和日志里 |
| `Documentation=` | 文档链接，`man:xxx(5)` 或 `https://...`，可多行 |
| `After=` / `Before=` | 仅定义**启动顺序**，不定义依赖 |
| `Requires=` / `Wants=` | 定义依赖，见 6.3 |
| `Conflicts=` | 互斥，见 6.3 |
| `OnFailure=` | 本单元进入 failed 时激活的单元（可用来发通知） |
| `StartLimitIntervalSec=` / `StartLimitBurst=` | 启动频率限制，见 6.7 |
| `Condition...` / `Assert...` | 条件判断，见 6.4 |

### 6.3 `[Unit]`：依赖关系

systemd 把"要不要对方在"和"谁先谁后"分成两类指令，**必须分开写**。

| 指令 | 类型 | 含义（man 原文要点） |
| --- | --- | --- |
| `Wants=` | 弱依赖 | 希望对方也启动，对方起不来不影响本单元 |
| `Requires=` | 强依赖 | 对方起不来则本单元失败；对方被停止时本单元也停止 |
| `Requisite=` | 强依赖 | 对方**必须已经在运行**，否则立即失败；不隐含顺序 |
| `BindsTo=` | 最强依赖 | 同 `Requires=`，且对方意外消失（不只是被停止）时本单元也停止 |
| `PartOf=` | 单向传播 | 对方被停止/重启时本单元跟着停/重启；反向不传播 |
| `Conflicts=` | 互斥 | 启动本单元会停掉对方，反之亦然 |
| `After=` | 顺序 | 本单元在对方**之后**启动 |
| `Before=` | 顺序 | 本单元在对方**之前**启动 |

常见错误：只写 `After=` 不写 `Wants=`。`After=network-online.target` 只表示"如果它也在启动队列里，我排在它后面"；如果它根本不在队列里，这个顺序约束不产生任何效果。需要网络就两者都写：

```ini
[Unit]
After=network-online.target
Wants=network-online.target
```

`After=` 和 `Before=` 只影响顺序，不影响启停：单独一个 `After=` 不会让对方启动。

`After=` 指向自身所属于的 target（例如 `WantedBy=default.target` 又写 `After=default.target`）没有实际意义，`systemd-analyze verify` 也不会报错，属于可删的冗余配置。

### 6.4 `[Unit]`：条件与断言

`Condition...=` 不满足时跳过本单元（视为成功），`Assert...=` 不满足时直接失败。

| 指令 | 判断什么 |
| --- | --- |
| `ConditionPathExists=` / `ConditionPathIsDirectory=` | 路径是否存在 |
| `ConditionFileNotEmpty=` | 文件非空 |
| `ConditionUser=` | 运行者是否为指定用户 |
| `ConditionHost=` / `ConditionArchitecture=` | 主机名 / 架构 |
| `ConditionACPower=` | 是否接电源（笔记本电池策略） |
| `ConditionCapability=` | 是否具备某 capability |

取反在值前加 `!`。多个 `Condition=` 之间是逻辑与。

典型用法：只在接电源时跑重负载任务。

```ini
[Unit]
ConditionACPower=true
```

### 6.5 `[Service]`：`Type=`

| Type | 何时算启动成功 | 适用 |
| --- | --- | --- |
| `simple`（默认） | fork 出去就算成功 | 前台程序 |
| `exec` | `execve()` 成功才算成功 | 比 `simple` 严格，新服务推荐 |
| `oneshot` | 命令**执行完毕**才算成功 | 一次性任务、timer 的配套服务 |
| `notify` | 程序通过 sd_notify 报告就绪 | 支持通知的现代守护进程 |
| `forking` | 程序自己 daemonize 后父进程退出 | 兼容老程序，新服务不要用 |
| `idle` | 同 `simple`，但延迟到其他任务完成后 | 避免开机时抢占输出 |

一次性任务跑完后希望保持 `active (exited)` 状态（而不是立刻变 `inactive`），加：

```ini
Type=oneshot
RemainAfterExit=yes
```

`Type=oneshot` 的两条限制（`man systemd.service` 原文）：

- 「Type=oneshot are the only service units that may have more than one `ExecStart=` specified.」
- 「For Type=oneshot, `Restart=always` and `Restart=on-success` are not allowed.」

### 6.6 `[Service]`：Exec 家族

| 指令 | 执行时机 |
| --- | --- |
| `ExecStartPre=` | 启动前，可多个 |
| `ExecStart=` | 主命令 |
| `ExecStartPost=` | 启动成功后 |
| `ExecReload=` | 收到 `systemctl reload` 时 |
| `ExecStop=` | 收到 `systemctl stop` 时 |
| `ExecStopPost=` | 停止后，无论成功失败 |

`ExecStart=` 的规则（`man systemd.service` 原文）：

> Unless `Type=` is oneshot, exactly one command must be given. When `Type=oneshot` is used, this setting may be used multiple times... **If the empty string is assigned to this option, the list of commands to start is reset, prior assignments of this option will have no effect.**

这条"赋空值即清空"的规则在 drop-in 里很关键：**要替换原有的 `ExecStart=`，必须先清空**。

```ini
# ~/.config/systemd/user/NAME.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/local/bin/new-command --flag
```

只写第二行会得到两条 `ExecStart=`，对 `Type=simple` 直接报错。

四条硬性规则：

1. **必须是绝对路径**，systemd 不查 `PATH`。
2. **不经过 shell**：`|`、`>`、`&&`、`~`、通配符都不生效。需要这些就显式调用 shell：`ExecStart=/usr/bin/bash -c '...'`，或者写成脚本文件再调用脚本。
3. **`%` 必须写成 `%%`**，否则被当作说明符（见 6.10）。
4. 一个单元可以有多个 `ExecStart=`，仅限 `Type=oneshot`（见上）。

多命令失败时的行为：命令按书写顺序执行，某个失败（且没有 `-` 前缀）后其余不执行，单元标记为失败。前缀 `-` 表示忽略该命令的退出码。

### 6.7 `[Service]`：重启与停止

`Restart=` 的取值：

| 取值 | 重启条件 |
| --- | --- |
| `no`（默认） | 不重启 |
| `on-success` | 仅干净退出（exit 0、SIGHUP/SIGINT/SIGTERM/SIGPIPE、`SuccessExitStatus=` 列出的） |
| `on-failure` | 非零退出、被信号杀死、超时、看门狗超时 |
| `on-abnormal` | 仅信号、超时、看门狗；非零退出**不算** |
| `on-watchdog` / `on-abort` | 仅看门狗超时 / 仅未捕获信号 |
| `always` | 除 `systemctl stop` 之外全部 |

`man systemd.service` 原文：

> When the death of the process is a result of systemd operation (e.g. service stop or restart), the service will not be restarted.

所以**不要用 `systemctl stop` 验证 `Restart=`**，要用 `kill -9 <MainPID>`。另外 `RestartSec=` 默认只有 **100ms**。

启动频率限制在 `[Unit]` 段，不在 `[Service]`：

```ini
[Unit]
StartLimitIntervalSec=10s     # 统计窗口
StartLimitBurst=5             # 窗口内最多启动次数
```

超出后单元进入 `failed`，日志中出现 `start-limit-hit`。设为 `0` 表示不限速（本机 `hermes-gateway.service` 用 `StartLimitIntervalSec=0` 保持无限重启）。

停止相关默认值（本机 `systemctl show` 实测）：

| 参数 | 默认值 | 含义 |
| --- | --- | --- |
| `TimeoutStopSec=` | **45s** | 等待自行退出的时间，超时发 `SIGKILL` |
| `KillSignal=` | 15（`SIGTERM`） | 先发的信号 |
| `KillMode=` | `control-group` | 停止时杀掉整个 cgroup |
| `SendSIGKILL=` | `yes` | 超时后是否补 `SIGKILL` |

45s 不是随手写的：`man systemd-system.conf` 说明 `DefaultTimeoutStartSec=` 和 `DefaultTimeoutStopSec=` 在 system manager 和 user manager 中**默认都是 45s**（旧文档里的 90s 已不适用）。

`KillMode=control-group` 就是"停止服务 = 杀掉整组进程"的实现。因此停服务用 `systemctl stop`，不要用 `killall`。

### 6.8 `[Service]`：环境变量

服务不继承 shell 的配置（`.bashrc`、`config.fish` 都不读）。本机对比：

```console
$ systemctl --user show-environment | grep PATH
PATH=/var/home/smile/.pixi/bin:/var/home/smile/.local/share/mise/...:/usr/bin:...
```

而 `hermes-gateway.service` 里显式写的 `PATH` 只有十几个目录。差别意味着 `~/.local/bin`、mise / pixi 装的可执行文件在服务里可能找不到。

四种设置方式：

| 方式 | 写法 | 适用范围 |
| --- | --- | --- |
| `Environment=` | `Environment="PATH=/a:/usr/bin:/bin"` | 单个单元 |
| `EnvironmentFile=` | `EnvironmentFile=%h/.config/foo.env`（文件内 `KEY=VALUE` 每行一条） | 单个单元，可放权限 600 的密钥文件 |
| `PassEnvironment=` | `PassEnvironment=PATH LANG` | 从 user manager 环境透传指定变量 |
| `environment.d` | `~/.config/environment.d/*.conf` | 所有用户单元（系统级单元读不到） |

Arch Wiki 的说明：

> Units started by user instance of systemd do not inherit any of the environment variables set in places like `.bashrc` etc.
> systemd does not look at the set `PATH` when resolving non-absolute binaries itself.

会话中途修改环境：

```bash
systemctl --user import-environment PATH     # 导入当前 shell 的 PATH
systemctl --user set-environment FOO=bar     # 直接设置
systemctl --user show-environment            # 查看
```

这些只影响设置之后启动的单元，已经在跑的不会变。

### 6.9 `[Service]`：资源限制

常用项（详见 `man systemd.resource-control`）：

| 指令 | 作用 |
| --- | --- |
| `MemoryMax=` | 内存上限，超出触发 OOM |
| `MemoryHigh=` | 内存软上限，超出后限速回收 |
| `CPUQuota=` | CPU 上限，如 `50%` 表示单核一半 |
| `IOWeight=` | IO 相对权重（1–10000） |
| `TasksMax=` | 进程数上限 |
| `LimitNOFILE=` | 文件描述符上限 |
| `Nice=` | 调度优先级（-20–19） |
| `OOMScoreAdjust=` | OOM 被杀优先级（-1000–1000） |

示例：限制某个后台任务不超过 1G 内存、50% 单核：

```ini
[Service]
MemoryMax=1G
CPUQuota=50%
```

### 6.10 说明符（Specifiers）与 `%%`

`%` 开头的字符串会在加载时被替换（`man systemd.unit` 的 SPECIFIERS 一节）。常用项：

| 说明符 | 展开为 | 本机值 |
| --- | --- | --- |
| `%h` | 用户家目录 | `/var/home/smile` |
| `%u` / `%U` | 用户名 / UID | `smile` / `1000` |
| `%t` | 运行时目录 | `/run/user/1000` |
| `%S` | 状态目录 | `~/.local/state` |
| `%C` | 缓存目录 | `~/.cache` |
| `%E` | 配置目录 | `~/.config` |
| `%D` | 数据目录 | `~/.local/share` |
| `%i` / `%I` | 模板单元实例名（原始 / 反转义） | 见 6.11 |
| `%n` / `%N` | 完整单元名 / 不含后缀 | `foo.service` / `foo` |
| `%p` | 前缀名（`@` 前） | `foo` |
| `%f` | 反转义后的实例路径 | — |
| `%%` | 一个字面 `%` | `%` |

任何不需要被替换的 `%` 都必须写成 `%%`。写错时 `systemd-analyze verify` 会报错（本机真实报错）：

```text
hello-loop.service:7: Failed to resolve unit specifiers in
  'while true; do printf "%(%F %T %Z)T\n" -1; sleep 5; done': 无效的 slot
hello-loop.service: Unit configuration has fatal error, unit will not be started.
```

正确写法：

```ini
ExecStart=/usr/bin/bash -c 'while true; do printf "%%(%%F %%T %%Z)T\n" -1; sleep 5; done'
```

不需要说明符时，让它完全不出现更省事：

```ini
ExecStart=/usr/bin/bash -c 'while true; do echo "$(date)"; sleep 5; done'
```

`systemctl status` 在 `bad-setting` 时仍可能显示 `active (running)`（旧进程还在），判断配置是否有效要看 `Loaded:` 行或跑 `systemd-analyze verify`。

### 6.11 `[Install]` 与模板单元

`WantedBy=` 决定 `enable` 时链接到哪个 target 的 `wants/` 目录：

| 目标 | 含义 |
| --- | --- |
| `multi-user.target` | 系统级服务，进入多用户模式时启动（无图形也起） |
| `graphical.target` | 需要图形环境 |
| `timers.target` | timer 的标准写法 |
| `default.target` | 用户单元的标准写法，随用户实例启动 |

Arch Wiki 的 user 单元示例同样使用：

```ini
[Install]
WantedBy=default.target
```

漏掉 `[Install]` 时 `enable` 无效。

`Alias=` 给单元加别名链接；`RequiredBy=` 等价于强依赖反向声明（少用）。

#### 模板单元

文件名含 `@` 即成模板，实例名通过 `%i` 取得：

```ini
# ~/.config/systemd/user/backup@.service
[Unit]
Description=备份 %i

[Service]
Type=oneshot
ExecStart=%h/bin/backup.sh %i
```

```bash
systemctl --user start backup@obsidian      # 实例名 obsidian
systemctl --user status backup@obsidian     # 单元名 backup@obsidian.service
```

同一个模板可带不同参数启动多个实例，省去复制文件。`%i` 是原始字符串，`%I` 是反转义后的版本（实例名含 `/` 等字符时使用）。

### 6.12 写完怎么验证

```bash
systemd-analyze verify /path/to/NAME.service   # 语法、说明符、依赖
systemd-analyze --user verify NAME.service     # 用户单元
systemctl --user cat NAME.service              # 合并后的配置
systemctl --user show NAME.service             # 生效属性
systemctl --user show NAME.service -p ExecStart   # 实际 argv
```

`verify` 通过不代表能跑起来（运行期问题它看不出来），但语法和说明符错误一定会被拦下，先跑它省时间。

### 6.13 示例一：常驻服务

`~/.config/systemd/user/hello-loop.service`：

```ini
[Unit]
Description=每 5 秒打印一次时间

[Service]
Type=simple
ExecStart=/usr/bin/bash -c 'while true; do echo "$(date)"; sleep 5; done'
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
```

```bash
systemctl --user daemon-reload
systemctl --user enable --now hello-loop.service
systemctl --user status hello-loop.service
journalctl --user -u hello-loop.service -f
```

如果写成 `ExecStart=/usr/bin/bash -c 'while true; do date; sleep 5; done'`：

- 服务本身完全正常，`Active: active (running)`，时间也在打印。
- 但 `journalctl --user -u` 只显示一行 `Started ...`，看不到输出。

原因是写日志的是 `date` 而不是 bash，见 4.6。两种写法的字段对比：

| | `date` 直接写 | `echo "$(date)"` |
| --- | --- | --- |
| `_COMM` | 253 条中 11 条有 | 全部有，值为 `bash` |
| `_SYSTEMD_USER_UNIT` | 0 条 | 全部有 |
| `journalctl --user -u` | 一行 `Started` | 每 5 秒一条 |

### 6.14 示例二：读一个真实单元

`systemctl --user cat hermes-gateway.service`（本机，删节）：

```ini
[Unit]
Description=Hermes Agent Gateway - Messaging Platform Integration
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=0

[Service]
Type=simple
ExecStart="/var/home/smile/.hermes/hermes-agent/.hermes/bin/hermes" "gateway" "run"
WorkingDirectory=/var/home/smile/.hermes
Environment="PATH=/var/home/smile/.hermes/...:/usr/bin:/bin"
Environment="HERMES_HOME=/var/home/smile/.hermes"

[Install]
WantedBy=default.target
```

| 行 | 作用 |
| --- | --- |
| `After=` + `Wants=` 成对 | 顺序 + 弱依赖，缺一不可（6.3） |
| `StartLimitIntervalSec=0` | 关闭启动频率限制，允许无限重启（6.7） |
| `Type=simple` | fork 出去即视为启动成功 |
| `ExecStart=` 带引号 | 路径或参数含空格时需要；必须是绝对路径 |
| `WorkingDirectory=` | 相对路径的基准，不写则是 `/` |
| `Environment="PATH=..."` | 显式指定 PATH（6.8） |

### 6.15 可直接复制的模板

```ini
[Unit]
Description=（一句话说明）
# 需要网络时成对写：
# After=network-online.target
# Wants=network-online.target
# 关闭重启频率限制（需要无限重启时）：
# StartLimitIntervalSec=0

[Service]
Type=simple
ExecStart=/absolute/path/to/binary --arg
WorkingDirectory=%h
Restart=on-failure
RestartSec=3
# 显式 PATH，避免找不到 ~/.local/bin 里的程序：
# Environment="PATH=%h/.local/bin:/usr/local/bin:/usr/bin:/bin"
# 资源限制：
# MemoryMax=1G
# CPUQuota=50%

[Install]
WantedBy=default.target
```

检查清单：

1. `ExecStart=` 是绝对路径？
2. 有没有用到 `%`？该写成 `%%` 的都写了？
3. 要 shell 特性（管道、重定向）时有没有加 `bash -c`？
4. `[Install]` 有 `WantedBy=`？
5. `systemd-analyze --user verify` 通过？
6. `daemon-reload` 跑过了？

---

## 7. timer

### 7.1 结构

一个定时任务由两个单元组成：`.timer` 定义时间，`.service` 定义动作。timer 到点后启动同名 service。

```mermaid
graph LR
  T["hello.timer"] -->|到点激活| S["hello.service"]
  S -->|stdout/stderr| J["journald"]
```

规则：

- `enable` 的是 `.timer`，不是 `.service`。
- `.service` 可以省略 `[Install]`。
- `list-timers` 里显示的是 timer；对应的 service 平时是 `inactive (dead)`，这是正常状态。

### 7.2 两类计时

| 类型 | 指令 | 起点 | 适用 |
| --- | --- | --- | --- |
| 墙钟（realtime） | `OnCalendar=` | 日历时间 | 每天 3 点、每周一 |
| 单调（monotonic） | `OnBootSec=` / `OnStartupSec=` / `OnUnitActiveSec=` / `OnUnitInactiveSec=` / `OnActiveSec=` | 开机、上次激活等事件 | 开机后 5 分钟、每隔 10 分钟 |

单调计时器在休眠或重启后重置，因此不适合"每天固定时刻"的任务。

### 7.3 `OnCalendar=` 语法

格式：

```text
DayOfWeek Year-Month-Day Hour:Minute:Second
```

`*` 任意值，`,` 列举，`..` 范围，`/` 步长。

| 表达式 | 含义 |
| --- | --- |
| `daily` / `hourly` / `weekly` / `monthly` / `yearly` | 简写 |
| `*-*-* 03:00:00` | 每天 03:00 |
| `Mon..Fri 09:00` | 工作日 09:00 |
| `*-*-* *:00/15:00` | 每 15 分钟 |
| `*-*-01 00:00:00` | 每月 1 号零点 |
| `Sat *-*-1..7 18:00:00` | 每月第一个周六 18:00 |
| `*-*-* 02:00:00 Europe/Paris` | 指定时区 |
| `2026-11-01 08:00` | 一次性绝对时间 |

写多行 `OnCalendar=` 取并集（例如每天 8 点和 20 点各一次）。

写完必须验证：

```console
$ systemd-analyze calendar "Mon..Fri 09:00" --iterations=3
  Original form: Mon..Fri 09:00
Normalized form: Mon..Fri *-*-* 09:00:00
    Next elapse: Fri 2026-10-23 09:00:00 CST
       From now: 21h left
   Iteration #2: Mon 2026-10-26 09:00:00 CST
```

### 7.4 修饰项

| 指令 | 作用 | 注意 |
| --- | --- | --- |
| `Persistent=true` | 关机期间错过的任务，开机后补跑一次 | 只对 `OnCalendar=` 生效（man 原文：only has an effect on timers configured with `OnCalendar=`）。状态存于 `~/.local/share/systemd/timers/`（系统级 `/var/lib/systemd/timers/`）；清理用 `systemctl --user clean --what=state NAME.timer`，不要手动删文件 |
| `AccuracySec=` | 允许的误差窗口 | **默认 `1min`**。Arch Wiki 建议写 `AccuracySec=1us`；日常用 `1s` 也可。不写的话 03:00:00 的任务可能 03:00:47 才跑 |
| `RandomizedDelaySec=` | 在窗口内随机延迟 | 多机部署避免整点集中；单机可写 `5min` 求稳 |
| `Unit=` | 显式指定被触发的服务 | 不写按同名匹配（`x.timer` → `x.service`）。改名后不加 `Unit=` 会得到 `Job failed` |

### 7.5 示例：每天备份

`~/.config/systemd/user/backup.service`：

```ini
[Unit]
Description=每日备份脚本

[Service]
Type=oneshot
WorkingDirectory=%h
ExecStart=%h/bin/backup.sh
```

`~/.config/systemd/user/backup.timer`：

```ini
[Unit]
Description=每天 03:00 跑备份

[Timer]
OnCalendar=*-*-* 03:00:00
Persistent=true
RandomizedDelaySec=5min
AccuracySec=1min

[Install]
WantedBy=timers.target
```

```bash
systemctl --user daemon-reload
systemctl --user enable --now backup.timer
systemctl --user list-timers --all          # 看 NEXT / LAST / PASSED
systemctl --user start backup.service       # 手工跑一次，验证脚本本身
journalctl --user -u backup.service -n 50
```

### 7.6 临时任务：systemd-run

```bash
systemd-run --user --on-active=10min --unit=remind /usr/bin/notify-send "起来走走"
systemd-run --user --on-calendar="tomorrow 09:00" --unit=daily-report %h/bin/report.sh
systemd-run --user --pty bash               # 临时单元里的隔离 shell
systemctl --user list-timers --all          # 查看临时 timer
```

本机实测：

```console
$ systemd-run --user --on-active=5s --unit=probe-at-demo bash -c 'date +%T > /tmp/x'
Running timer as unit: probe-at-demo.timer
Will run service as unit: probe-at-demo.service
```

### 7.7 与 cron 对照

| cron / at | systemd |
| --- | --- |
| `crontab -e` | 一个 `.timer` + 一个 `.service` |
| `0 3 * * * cmd` | `OnCalendar=*-*-* 03:00:00` |
| `*/15 * * * * cmd` | `OnCalendar=*-*-* *:00/15:00` |
| `0 9 * * 1-5 cmd` | `OnCalendar=Mon..Fri 09:00:00` |
| `@reboot cmd` | `OnBootSec=1min`，或直接写 service 配 `WantedBy=default.target` |
| `at now + 10min` | `systemd-run --user --on-active=10min cmd` |
| `at 09:00` | `systemd-run --user --on-calendar="09:00" cmd` |

timer 相对 cron 的差别：每个任务有独立 service，可单独启动调试、可设环境、可进 cgroup、可设依赖、日志进 journal、可补跑。代价是需要两个文件，且没有 cron 的 `MAILTO` 邮件通知（用 `OnFailure=` 挂一个通知单元替代）。

### 7.8 排错

| 症状 | 检查 |
| --- | --- |
| `list-timers` 里没有它 | 没 `enable`、没 `daemon-reload`、`[Install]` 缺 `WantedBy=timers.target` |
| 有 NEXT 但到点没跑 | service 启动失败：`journalctl --user -u xxx.service -n 50` |
| `Unit not found` | timer 与服务名不匹配且没写 `Unit=` |
| 时间不准 | `AccuracySec` 默认 1 分钟；或时区错，查 `timedatectl` |
| 关机期间没补跑 | 缺 `Persistent=true` |

---

## 8. 用户单元（`--user`）

### 8.1 系统级与用户级

| | 系统级（默认） | 用户级（`--user`） |
| --- | --- | --- |
| 运行者 | root | 你自己 |
| 配置路径 | `/etc/systemd/system/` | `~/.config/systemd/user/` |
| 需要 sudo | 是 | 否 |
| 环境变量 | 极简 | 继承用户会话（含 `DISPLAY`、`WAYLAND_DISPLAY`、`DBUS_SESSION_BUS_ADDRESS`） |
| 访问图形界面 | 默认不能 | 能 |
| 系统更新影响 | 可能被覆盖 | 不受影响 |

判断：不需要 root 就用 `--user`。需要绑定 1024 以下端口、改防火墙、挂载文件系统时才写系统单元。

### 8.2 linger：不登录也运行

用户实例随登录启动、随最后一个会话结束而停止。要让它常驻（开机即跑，无需登录）：

```bash
loginctl show-user smile -p Linger        # 本机实测 Linger=yes
sudo loginctl enable-linger <用户名>       # 启用
loginctl list-users                       # LINGER 列查看
sudo loginctl disable-linger <用户名>      # 关闭
```

状态记录在 `/var/lib/systemd/linger/`。

Arch Wiki 的两条提醒：

1. `user@.service` 随最后一个会话结束而终止，因此用户 timer 默认只在有活动登录会话时运行；linger 解决这个问题。
2. **不要用 linger 实现开机自动登录**，systemd 服务不是登录会话（Arch Wiki 原文：Do not use lingering to enable automatic login as it will break the session）。

### 8.3 user manager 与图形会话不是一回事

```console
$ systemctl --user list-units --all | grep graphical-session
graphical-session.target   loaded active active   Current graphical user session
```

- `user@1000.service` 是**用户管理器**，管理该用户的所有单元，登录即启动（开了 linger 则开机启动）。
- `graphical-session.target` 是**图形会话**，登录桌面后才 active。

因此依赖 `graphical-session.target` 的服务在 SSH 或纯文本控制台下不会启动；依赖 `default.target` 的则在用户实例启动时就起。

需要 `WAYLAND_DISPLAY`、`notify-send` 之类图形资源的服务，应挂到图形会话上：

```ini
[Unit]
After=graphical-session.target
PartOf=graphical-session.target
```

`PartOf=` 让它在登出时一起停止。

### 8.4 环境变量注入位置

| 位置 | 影响范围 | 备注 |
| --- | --- | --- |
| `Environment=` / `EnvironmentFile=` | 单个单元 | 最直接 |
| `~/.config/environment.d/*.conf` | 该用户所有用户单元 | 系统级单元读不到 |
| `/etc/systemd/user.conf` 的 `DefaultEnvironment=` | 所有用户单元 | 全局 |
| `user@.service.d/` 里的 `Environment=` | 所有用户单元 | 需 root 修改 |
| `systemctl --user import-environment` | 设置后启动的单元 | 常配合 `dbus-update-activation-environment --systemd` 使用 |

### 8.5 适用范围

适合放用户单元：

- 开机自启的同步、代理、网盘客户端
- 每日备份、清理、git 自动提交
- 定时提醒、日志归档
- 常驻小工具（剪贴板守护、输入法辅助）

不适合：需要绑定特权端口、改防火墙、挂载文件系统的任务。

---

## 9. 诊断工具

| 命令 | 用途 |
| --- | --- |
| `systemd-analyze time` | 开机耗时分布。本机实测：7.950s firmware + 10.049s loader + 791ms kernel + 6.222s initrd + 8.215s userspace = 33.229s |
| `systemd-analyze blame` | 各单元耗时排序。本机前几名都是 device（`sys-module-fuse.device` 8.597s），属于硬件等待，不是软件问题 |
| `systemd-analyze critical-chain` | 关键路径，真正影响开机的串行链 |
| `systemd-analyze verify FILE` | 单元语法、说明符、依赖检查 |
| `systemd-analyze calendar "表达式"` | 计算下次触发时间 |
| `systemd-analyze security UNIT` | 沙箱严格度评分 |

其余：

```bash
systemctl list-dependencies NAME.service
systemctl list-dependencies --after NAME.service
systemd-cgls                 # 按 cgroup 分组的进程树
systemd-cgtop                # 类似 top，按单元聚合资源
systemd-run --user --pty bash   # 在临时单元里获得隔离 shell
```

关于 `security` 的评分：本机 `hermes-gateway.service` 测得 `9.4 UNSAFE`。这个分数衡量沙箱严格程度，不是漏洞数量。per-user 单元天生分数低，因为许多加固项（`ProtectSystem`、`RemoveIPC` 等）对用户服务无意义，报告里会自己标注 `has no effect on per-user services`。个人服务不必追这个分数；要跑不受信任的第三方服务时再逐项加 `NoNewPrivileges=`、`PrivateTmp=`、`ProtectSystem=strict` 等。

---

## 10. Fedora Silverblue 特有事项

1. **`/usr` 只读**。自定义配置只能放 `/etc/systemd/system/`（系统级）或 `~/.config/systemd/user/`（用户级），不要改 `/usr/lib/systemd/` 下的文件。

2. **没有 cron、没有 at**。本机实测：

   ```console
   $ rpm -q cronie at
   未安装软件包 cronie
   $ systemctl status crond
   Unit crond.service could not be found.
   ```

   定时任务用 timer。用 `rpm-ostree install cronie at` 可以装，但会叠进系统镜像，每次更新都要多走一遍，不建议。

3. **layered 包自带的单元不要改**。`helix`、`ibus-rime`、`virt-manager` 等通过 rpm-ostree 层叠安装的包，其单元在 `/usr/lib/systemd/`，只能用 drop-in 覆盖。

4. **系统更新后检查**：

   ```bash
   rpm-ostree status          # 层叠冲突
   systemctl --failed         # 新增失败单元（remount-fs 属于预期）
   ```

5. **preset 机制**。Fedora 用 preset 文件决定新装的单元默认是否启用。`list-unit-files` 的 `PRESET` 列即此。`STATE=enabled` 而 `PRESET=disabled` 说明是自己开的，不是发行版默认——本机 `hello-loop.service` 和 `hermes-gateway.service` 都是这种情况。

---

## 11. 常见错误与原因

| # | 现象 | 原因 | 处理 |
| --- | --- | --- | --- |
| 1 | 改了配置没生效 | 没有 `daemon-reload` | reload 后再 restart |
| 2 | `Job failed`，没有细节 | 具体错误在 journal 里 | `journalctl --user -u NAME -n 50` |
| 3 | 启动即失败 | `ExecStart=` 用了相对路径 | 改成绝对路径 |
| 4 | `bad-setting`，报 `invalid slot` | `ExecStart=` 里的 `%` 没写成 `%%` | 用 `%%`；或改成不含 `%` 的写法 |
| 5 | timer 到点不跑 | timer 名与 service 名不匹配，且缺 `Unit=` | 名字对齐，或显式写 `Unit=` |
| 6 | `enable` 了但不开机启动 | 缺 `[Install] WantedBy=` | 补上后重新 enable |
| 7 | 脚本手工能跑，服务里失败 | PATH 或环境变量不同 | `Environment="PATH=..."` 或绝对路径 |
| 8 | `Persistent=true` 没补跑 | 误以为对单调 timer 有效 | 只对 `OnCalendar=` 生效 |
| 9 | 服务停了但进程还在 | 用 `killall` 杀主进程 | 用 `systemctl stop`，它按 cgroup 杀 |
| 10 | 自定义单元升级后消失 | 改的是 `/usr/lib/` 下的文件 | 只改 `/etc` 或 `~/.config` 的 drop-in |
| 11 | 服务在跑，`journalctl -u` 却没有输出 | 日志由短命子进程写出，归属字段缺失（4.6） | `-o verbose` 确认；改由常驻进程写，或 `-t` / `_STREAM_ID` / `StandardOutput=append:` |
| 12 | `systemctl stop` 测 `Restart=` 没生效 | systemd 主动停止不触发重启（6.7） | 用 `kill -9 <MainPID>` 测 |
| 13 | 设了 `Restart=always` 仍停在 failed | 命中 `StartLimitBurst` | 日志找 `start-limit-hit`；调大 burst 或 `StartLimitIntervalSec=0` |
| 14 | `journalctl -u` 对用户单元输出 `-- No entries --` | 少了 `--user` | `journalctl --user -u NAME` |
| 15 | `disable` 后进程还在跑 | `disable` 只影响下次开机 | 需要停止就 `stop` |
| 16 | 定时任务时间偏 | `AccuracySec` 默认 1 分钟；或时区错 | 设 `AccuracySec=1s`，`timedatectl` 核对时区 |

---

## 附录 A：命令速查

```bash
# 状态
systemctl --user status NAME.service
systemctl --user --failed
systemctl --user list-timers --all
systemd-analyze time

# 操作
systemctl --user start|stop|restart|reload NAME.service
systemctl --user enable --now NAME.service
systemctl --user disable --now NAME.service
systemctl --user mask|unmask NAME.service

# 配置
systemctl --user edit NAME.service          # 生成 .d/override.conf
systemctl --user edit --full NAME.service   # 完整副本
systemctl --user cat NAME.service           # 合并后结果
systemctl --user show NAME.service          # 生效属性
systemctl --user revert NAME.service        # 撤销改动
systemctl --user daemon-reload              # 改完必跑

# 日志
journalctl --user -u NAME.service -b -n 100
journalctl --user -u NAME.service -f
journalctl --user -u NAME.service -o verbose
journalctl --user-unit NAME.service         # 等价写法
journalctl -p warning..emerg -b
journalctl -b -1
journalctl --list-boots
journalctl --disk-usage
sudo journalctl --vacuum-size=500M

# 验证
systemd-analyze verify ./foo.service
systemd-analyze --user verify foo.service
systemd-analyze calendar "Mon..Fri 09:00" --iterations=3
systemd-analyze security --user NAME.service
systemctl --user show NAME.service -p Restart -p RestartUSec -p TimeoutStopUSec -p KillMode
systemctl --user clean --what=state NAME.timer

# 一次性任务
systemd-run --user --on-active=10min --unit=任务 命令
systemd-run --user --on-calendar="tomorrow 09:00" --unit=任务 命令
systemd-run --user --pty bash
```

---

## 附录 B：练习清单

| # | 内容 | 验收 |
| --- | --- | --- |
| 1 | `status`、`list-units`、`list-unit-files`、`--failed` 各看一遍本机 5 个单元 | 能说清 `Loaded:` 里 `enabled` 与 `preset` 的区别 |
| 2 | `journalctl` 的 `-u` `-b` `-f` `-p` `--since` 各用一次 | 能查出某服务今天最早的一条报错 |
| 3 | 给某个服务加 drop-in `Environment=TEST=1`，reload，`cat` 确认，再 `revert` | `cat` 里 override 排最后 |
| 4 | 写 `hello-loop`（6.13），分别用 `date` 版和 `echo "$(date)"` 版 | 能用 `-o verbose` 说出两者字段差异；`kill -9` 后能自动重拉 |
| 5 | 写 `hello-timer`（7.5 改成 `OnActiveSec=10s`） | 能解释为什么 `list-timers` 里有它、`status` 里 service 是 inactive |
| 6 | 故意制造三个错误：删掉 `[Install]`、`ExecStart` 用相对路径、`%` 不转义 | 三个错误都能用 `verify` + `journalctl` 定位 |
| 7 | 把日常备份写成 timer（参考本机 `pi-session-prune.timer`） | `list-timers` 有 NEXT，手工 `start` 有日志 |

---

## 参考资料

抓取日期 2026-10-22。

### man（版本与本机一致，优先使用）

```bash
man systemd.index        # 所有 systemd man 页索引
man systemd.directives   # 配置指令 → 对应 man 页
man systemd.unit         # [Unit] 段、依赖、Specifiers
man systemd.service      # [Service] 段、Exec 家族、Restart
man systemd.exec         # 环境变量、StandardOutput、沙箱
man systemd.timer        # [Timer] 段
man systemd.time         # OnCalendar 语法
man systemd.kill         # KillMode、信号
man systemd.resource-control  # 资源限制
man systemd.journal-fields    # journal 字段定义
man journalctl           # -u 与 --user-unit 的匹配规则
```

在线镜像（带小节锚点）：<https://man.archlinux.org/man/systemd.service.5>

### 官方文档

- systemd 项目主页 — <https://systemd.io/>（设计文档、API）
- freedesktop man 页面 — <https://www.freedesktop.org/software/systemd/man/latest/>
- Fedora：Understanding and administering systemd — <https://docs.fedoraproject.org/en-US/quick-docs/systemd-understanding-and-administering/>

### Arch Wiki

- systemd — <https://wiki.archlinux.org/title/Systemd>
  引用过：「`ExecStart` must be cleared before being re-assigned」（6.6 的清空规则）。
- systemd/Timers — <https://wiki.archlinux.org/title/Systemd/Timers>
  引用过：「Add the option `AccuracySec=1us` ... to avoid the inaccuracy of the _1m_ default value」（7.4）；「user timer units will only run during an active user login session by default」（8.2）。
- systemd/User — <https://wiki.archlinux.org/title/Systemd/User>
  引用过：「When a systemd user instance starts, it brings up the per user target `default.target`」（6.11）；「Do not use lingering to enable automatic login as it will break the session」（8.2）；「Units started by user instance of systemd do not inherit any of the environment variables set in places like `.bashrc`」「systemd does not look at the set `PATH` when resolving non-absolute binaries itself」（6.8）。
- 中文站 <https://wiki.archlinuxcn.org/wiki/Systemd>：内容同源，有 Cloudflare 人机校验，命令行抓取会被拦，浏览器正常。

### 设计动机

- Lennart Poettering: systemd for Administrators 1–4 — <https://0pointer.net/blog/projects/systemd-for-admins-1.html>
  解释并行启动、依赖图、集中日志的设计取舍。技术细节偏旧。
- systemd by example — <https://seb.jambor.dev/posts/systemd-by-example-part-1-minimization/>
  从零构建最小系统，配套沙盒 <https://systemd-by-example.com/> 可在浏览器里试验。
- Red Hat RHEL 9: Managing systemd — <https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_basic_system_settings/managing-systemd_configuring-basic-system-settings>

---

## 相关笔记

- [[systemd-fedora-notes]] — 同主题进阶内容（cgroup 限制、SELinux、socket 激活）
- [[必掌握linux命令]]
- [[kill相关命令详解]] — 为什么 systemd 里用 `systemctl kill` 而不是 `killall`
- [[使用Snapper进行快照]]
- [[Helix笔记]]
