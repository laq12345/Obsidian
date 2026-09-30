---
time: 2026-09-30T12:53:43
lang: Linux
tags:
  - linux
  - 进程管理
  - 命令
  - 工具
---

# kill 相关命令详解

`kill` 不是「杀死」,而是**给进程发信号**。进程收到信号后做什么,由信号语义和进程自己的 handler 决定。理解这一点,后面所有命令都只是「怎么挑进程」的不同方式。

相关的还有 [[必掌握linux命令]]、[[systemd-fedora-notes]]。

---

## 1. 信号表

常用信号(Linux x86_64 编号):

| 编号 | 名字 | 默认行为 | 典型用途 |
|---|---|---|---|
| 1 | SIGHUP | 终止 | 让守护进程**重载配置**;终端关闭时发给前台进程组 |
| 2 | SIGINT | 终止 | 等价于 Ctrl-C |
| 3 | SIGQUIT | 终止 + core | 等价于 Ctrl-\ |
| 6 | SIGABRT | 终止 + core | `abort()` |
| 9 | SIGKILL | 终止 | **强杀,不可捕获/忽略/阻塞** |
| 10 | SIGUSR1 | 终止 | 自定义(如 nginx 日志重开) |
| 12 | SIGUSR2 | 终止 | 自定义 |
| 15 | SIGTERM | 终止 | **默认信号,礼貌请求退出** |
| 17 | SIGCHLD | 忽略 | 子进程状态变化 |
| 18 | SIGCONT | 继续 | 恢复被 STOP 的进程 |
| 19 | SIGSTOP | 暂停 | **不可捕获**,强暂停 |
| 20 | SIGTSTP | 暂停 | 等价于 Ctrl-Z |
| 28 | SIGWINCH | 忽略 | 终端窗口尺寸变化 |

要点:

- **9 / 19 由内核强制**,进程无法拦截,所以拿不到清理机会(不写日志、不删临时文件、不刷缓冲)。
- **先 TERM,不行再 KILL** 是标准礼节。
- 信号编号在 ARM、MIPS 等架构上不一样,写脚本**一律用名字**。
- 查看全部:`kill -l`;表格形式:`/bin/kill -L`(util-linux 版支持,shell 内建不支持 `-L`)。

---

## 2. `kill`

bash 里 `kill` 是**内建命令**(`type kill` 确认),`/bin/kill` 是 util-linux 的外部程序,两者选项略有差异。

```bash
kill PID                    # 默认 SIGTERM
kill 1234 5678 9012         # 一次发多个
kill -15 PID                # 按编号
kill -TERM PID              # 按名字
kill -s TERM PID            # 显式 -s
kill -s SIGTERM PID         # 带 SIG 前缀也行
```

其他常用形态:

```bash
kill -0 PID                        # 不发信号,只探测是否存在 / 有无权限
kill -HUP PID                      # 重载配置(nginx、sshd 等)
kill -STOP PID && kill -CONT PID   # 暂停 / 继续
kill -9 PID                        # 最后手段
```

### 发信号给一批进程

```bash
kill -- -1234               # 负数是进程组 ID(PGID),杀整组
kill -TERM -- -1234         # 要加 --,否则 -1234 可能被当成选项
kill -9 -1                  # ⚠️ 杀自己有权杀的所有进程
kill %1                     # shell 作业控制,杀 jobs 编号 1
kill %-                     # 上一个作业
kill %%                     # 当前作业
```

- `PID = 0` 表示**当前进程组**。
- `PID = -1` 表示**除 init 外所有你有权限的进程**,极度危险。
- PGID 用 `ps -o pid,pgid,cmd` 查;`kill -TERM -PGID` 是杀整棵进程树的常用手法,比 `pkill -P` 只杀一层更彻底。

### 等进程真正退出

```bash
kill -TERM "$pid"
for _ in $(seq 1 20); do
  kill -0 "$pid" 2>/dev/null || break
  sleep 0.5
done
kill -KILL "$pid" 2>/dev/null || true
```

比 `sleep 3 && kill -9` 这种固定等待靠谱。

---

## 3. `killall`(psmisc)

按**进程名**批量杀,Linux 上由 psmisc 提供。

```bash
killall firefox             # 杀所有名为 firefox 的进程,默认 SIGTERM
killall -9 firefox          # 强杀
killall -s HUP nginx        # 等价 killall -HUP nginx
killall -i firefox          # 逐个交互确认(y/n)
killall -w -9 firefox       # -w 等待进程真正退出
killall -u alice            # 只杀 alice 的进程
killall -e "my prog"        # 精确匹配(名字含空格时有用)
killall -r '^python3?$'     # -r 正则匹配
killall -I FOO              # 忽略大小写
killall -q firefox          # 安静模式,没匹配到也不报错
killall -v firefox          # 详细输出
```

> [!warning] 跨平台大坑
> Solaris / AIX 上的 `killall` 是「杀掉系统上所有进程」(等同关机),语义完全不同。
> 写可移植脚本别用 `killall`,用 `pkill`。

---

## 4. `pkill` / `pgrep`(procps-ng)

最灵活,也最容易误伤。`pgrep` 只查 PID,`pkill` = `pgrep` + 发信号,**选项完全一致**。

### 匹配方式

```bash
pkill nginx                             # 默认匹配进程名(comm)
pkill -x nginx                          # 精确匹配整个名字
pkill -f "python manage.py runserver"   # 匹配完整命令行
pkill -f "node .*server.js"             # ERE 正则,默认就是扩展正则
```

### 筛选条件

| 选项 | 含义 |
|---|---|
| `-u alice` | 按有效用户名 |
| `-U 1000` | 按真实 UID |
| `-G gid` | 按真实组 |
| `-P 1234` | 按父进程 PID(只杀直接子进程,一层) |
| `-t pts/3` | 按控制终端 |
| `-n` | 只选**最新**的一个 |
| `-o` | 只选**最老**的一个 |
| `-g pgrp` | 按进程组 |
| `-s sid` | 按会话 ID |
| `--older 1h` / `--younger 10m` | 按启动时长(新版 procps) |

### 信号与输出

```bash
pkill -9 -f myscript.sh     # 指定信号
pkill -TERM -u alice -f java
pgrep -a nginx              # -a 显示完整命令行
pgrep -l nginx              # -l 只显示名字
pgrep -c -f python          # -c 只输出匹配数量
pgrep -d, nginx             # -d 用逗号分隔 PID
pkill -e nginx              # -e 回显被杀进程
```

### 典型组合

```bash
# 先看再杀 —— 永远是好习惯
pgrep -af "$PATTERN"
pkill -TERM -f "$PATTERN"

# 只杀自己的进程
pkill -u "$USER" -f myscript

# 杀某个终端下的所有东西
pkill -t pts/3

# 杀某个脚本启动的一层子进程
pkill -P "$(pgrep -f start.sh | head -1)"
```

### 四个必须知道的坑

> [!danger] pkill 的坑
> 1. **`comm` 被截断到 15 字符**。`/proc/PID/comm` 最多 15 字符,超长进程名用默认方式匹配不到,必须 `-f`。
> 2. **`-f` 会匹配到不该匹配的**。`pkill -f python` 可能顺手杀掉编辑器、Jupyter、甚至父 shell(`pkill` 排除自己的 PID,但**不排除父 shell**)。
> 3. **脚本里别用宽泛的 `pkill -f`**。脚本自身命令行若含该 pattern,可能把自己或调用者干掉。加 `-x`、`-u`、`-P` 收窄,或用 PID 文件。
> 4. **没匹配到返回 1**,`set -e` 脚本里记得 `|| true`。

---

## 5. 按端口 / 文件 / cgroup 杀

比模糊匹配精确得多的替代品:

```bash
# 按端口找进程
ss -lptn 'sport = :8080'
lsof -i :8080
fuser 8080/tcp

# 直接杀掉占用端口的进程
fuser -k 8080/tcp
fuser -k -TERM 8080/tcp
lsof -ti :8080 | xargs -r kill -TERM

# 杀掉占用某文件的进程(如卸载失败时)
fuser -km /mnt/usb
```

`fuser -k` 基于内核的 inode / socket 归属,不会误伤,比 `pkill -f` 可靠。参见 [[xargs-tutorial]]。

---

## 6. systemd 场景(Fedora)

> [!important] 用 systemd 管理的服务不要直接 kill
> 否则 `Restart=` 策略会把它拉起来,状态也会不一致。

```bash
systemctl stop nginx                          # 正规停止
systemctl kill -s SIGKILL nginx               # 强行发信号(仍走 systemd)
systemctl kill --kill-who=main -s HUP nginx   # 只给主进程发
systemctl kill --kill-who=control nginx
```

- 服务的所有进程在一个 **cgroup** 里,`systemctl` 能一次全收,比 `pkill -f` 可靠。
- 查看 cgroup 成员:`systemd-cgls`,或 `systemctl status nginx` 的 `CGroup:` 段。
- 用户级服务:`systemctl --user stop foo.service`。

配合超时:

```bash
systemd-run --scope --user timeout 30m ./long-job   # 超时自动 SIGTERM
timeout -s KILL 60s ./job                           # 60 秒后强杀
```

详见 [[systemd-fedora-notes]]。

---

## 7. 特殊情形

| 情形 | 说明 |
|---|---|
| **僵尸进程(Zombie / Z)** | `kill` 无效。进程已死,只是父进程没 `wait()`。要么杀父进程,要么修父进程代码 |
| **D 状态(不可中断睡眠)** | 通常在等 IO / NFS。`kill -9` 也无效,要解决底层 IO 阻塞 |
| **权限不足** | 只能杀同 UID 的进程;root 或有 `CAP_KILL` 才能杀别人的。`kill -0` 返回 EPERM 说明进程存在但没权限 |
| **PID 复用** | 保存的 PID 可能已被回收重用。生产脚本配合 PID 文件 + 启动时间校验 |
| **终端关闭** | 内核向前台进程组发 SIGHUP;`nohup` / `setsid` / `disown` 可免疫 |
| **Ctrl-C 无效** | 目标捕获了 SIGINT。改 `kill -TERM`,再不行 `-KILL` |
| **Ctrl-Z 后卡住** | `kill -CONT PID`、`bg`、`fg`,或 `kill %1` |

作业控制速查:

```bash
jobs -l          # 看作业编号
kill %1          # 杀作业 1
kill -STOP %1    # 暂停
kill -CONT %1    # 继续
disown %1        # 从作业表移除,避免退出时收 SIGHUP
```

---

## 8. 跨平台差异

| 平台 | 说明 |
|---|---|
| Linux | `killall` 来自 psmisc,按名字杀;`pkill`/`pgrep` 来自 procps-ng |
| macOS / BSD | `pkill`/`pgrep` 有;`killall`(BSD 版)按名字杀,语义接近但选项可能不同 |
| Solaris / AIX | **`killall` = 杀光所有进程**,绝对不要碰 |
| Windows | `taskkill /PID 1234 /F`、`taskkill /IM notepad.exe /F`、`tasklist` 查看 |

---

## 9. 一页速查

```bash
# 查看
ps aux | grep foo
pgrep -af foo              # 完整命令行 + PID
ss -lptn                   # 端口占用
kill -l                    # 信号列表

# 终止(从礼貌到暴力)
kill -TERM PID
kill -9 PID
pkill -TERM -f 'pattern'
pkill -9 -f 'pattern'
killall -9 name

# 进程组 / 整棵树
kill -TERM -- -PGID
pkill -TERM -P PPID

# 端口
fuser -k 8080/tcp
lsof -ti :8080 | xargs -r kill

# 服务
systemctl stop svc
systemctl kill -s SIGKILL svc

# 探测
kill -0 PID && echo alive
```

---

## 三条铁律

1. 先 `pgrep` 确认匹配范围,再 `pkill`;
2. 先 `-TERM` 给清理机会,超时无果再 `-KILL`;
3. 能用 PID / 端口 / cgroup 定位的,不要用 `-f` 模糊匹配。

---

## 附:优雅终止 + 超时兜底函数

```bash
# 用法: graceful_kill 1234 [超时秒数]
graceful_kill() {
  local pid=$1 timeout=${2:-10} i=0
  if ! kill -0 "$pid" 2>/dev/null; then
    echo "进程 $pid 不存在"
    return 0
  fi

  kill -TERM "$pid" 2>/dev/null || true
  while kill -0 "$pid" 2>/dev/null; do
    if [ "$i" -ge $((timeout * 2)) ]; then
      echo "超时,发送 SIGKILL"
      kill -KILL "$pid" 2>/dev/null || true
      return 1
    fi
    sleep 0.5
    i=$((i + 1))
  done
  echo "进程 $pid 已优雅退出"
}
```

也可以直接:

```bash
timeout -k 5 30 ./job     # 30 秒后 SIGTERM,再过 5 秒 SIGKILL
```
