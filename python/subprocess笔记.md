---
created: 2026-07-10
tags:
  - python
  - subprocess
lang: Python
---

# Python subprocess 笔记

> 标准库模块：启动子进程、连接管道、获取退出码。
> 核心原则：默认**不走 shell**，命令与参数用列表逐个传递（直接 execvp，无解析歧义、无注入风险）。
> 示例基于 Python 3.14；参数/特性标注了最低版本。

## 一、参数介绍表

### 1. subprocess.run() 参数

| 参数 | 默认 | 说明 |
|------|------|------|
| `args` | 必填 | 命令与参数。列表 `["ls", "-l"]` 最推荐；字符串仅用于 `shell=True` 或单命令 |
| `stdin` | `None` | 标准输入：`None` 继承当前进程；`PIPE`；`DEVNULL`；文件对象；fd 整数 |
| `stdout` | `None` | 标准输出，取值同上 |
| `stderr` | `None` | 标准错误，取值同上；另可用 `subprocess.STDOUT` 合并到 stdout |
| `capture_output` | `False` | `True` 等价 `stdout=PIPE, stderr=PIPE`（3.7+）；不能与 `stdout`/`stderr` 同时给 |
| `input` | `None` | 写入 stdin 的数据（bytes；`text=True` 时为 str）；不能与 `stdin` 同时给 |
| `timeout` | `None` | 秒数。超时先 kill 子进程，再抛 `TimeoutExpired` |
| `check` | `False` | `True` 时退出码非 0 抛 `CalledProcessError` |
| `text` | `False` | `True` 按文本模式处理 I/O（自动编码解码，3.7+；别名 `universal_newlines`） |
| `encoding` | `None` | 显式指定编码（隐含 text=True；3.6+），如 `"utf-8"` |
| `errors` | `None` | 解码错误处理：`"strict"`(默认) / `"replace"` / `"ignore"` 等（3.6+） |
| `cwd` | `None` | 子进程工作目录 |
| `env` | `None` | 环境变量字典。**整体替换**而非追加（见用法 8） |
| `shell` | `False` | `True` 时经 `/bin/sh -c` 执行（args 应为字符串） |
| `bufsize` | `-1` | 缓冲：0 无缓冲、1 行缓冲、-1 默认、其他值为字节数 |
| `executable` | `None` | 替换实际执行的程序（如 `shell=True` 时换用 bash） |
| `start_new_session` | `False` | `True` 时在子进程调 `setsid()`（新会话 + 新进程组） |
| `process_group` | `None` | 3.11+，指定进程组；`0` = 新建进程组（pgid = pid） |
| `user` / `group` / `extra_groups` | `None` | 3.9+（POSIX），以指定用户/组身份运行，需相应权限 |
| `umask` | `-1` | 3.9+（POSIX），子进程 umask |
| `close_fds` | `True` | POSIX 下关闭除 0/1/2 外的所有 fd |
| `pass_fds` | `()` | 白名单：保留给子进程的 fd（POSIX） |
| `preexec_fn` | `None` | exec 前回调。多线程环境下危险，尽量别用 |
| `restore_signals` | `True` | 把子进程中被 Python 忽略的信号恢复为默认处理 |

> `Popen` 与上表绝大多数参数通用；Popen 另有 `pipesize`（3.10+，Linux，管道缓冲区字节数），而 `capture_output` / `check` / `input` / `timeout` 是 run() 封装出来的便利参数。

### 2. 返回值 CompletedProcess

| 属性 | 说明 |
|------|------|
| `args` | 原始命令参数 |
| `returncode` | 退出码；0 成功，负值 `-N` 表示被信号 N 终止 |
| `stdout` / `stderr` | 捕获到的输出（bytes 或 str，取决于 text/encoding 设置） |

### 3. 异常

| 异常 | 触发条件 | 可读属性 |
|------|----------|----------|
| `CalledProcessError` | `check=True` 且退出码非 0 | `returncode` `cmd` `stdout` `stderr`（`output` 同 stdout） |
| `TimeoutExpired` | `timeout` 超时 | `cmd` `timeout` `stdout` `stderr`（已收到的部分输出） |
| `FileNotFoundError` | 命令不存在 | — |
| `PermissionError` | 无执行权限 | — |

## 二、常见用法详解

### 1. 基本执行

```python
import subprocess

# 跑完才返回；stdout/stderr 直接显示在当前终端
subprocess.run(["make", "-j4"])
```

### 2. 捕获输出

```python
r = subprocess.run(["git", "status", "--short"], capture_output=True, text=True)
print(r.stdout)
print(r.returncode)

# 编码要稳定，显式指定（text=True 默认按 locale 解码）
r = subprocess.run(["git", "log", "-1"], capture_output=True,
                   encoding="utf-8", errors="replace")
```

### 3. 失败即抛异常

```python
try:
    subprocess.run(["false"], check=True, capture_output=True, text=True)
except subprocess.CalledProcessError as e:
    print("退出码:", e.returncode)
    print("stderr:", e.stderr)
```

不写 `check=True` 时手动判断 `r.returncode`：0 为成功；Linux 上被信号杀死为负值 `-N`。

### 4. 超时

```python
try:
    r = subprocess.run(["sleep", "10"], timeout=1, capture_output=True, text=True)
except subprocess.TimeoutExpired as e:
    print("超时，已收到的输出:", e.stdout)
```

注意：`run` 超时只会 kill **直接子进程**，它再 fork 的孙子进程会残留（清理办法见用法 11）。

### 5. 喂输入

```python
r = subprocess.run(["cat"], input="你好\n", capture_output=True, text=True)
print(r.stdout)      # 你好

# bytes 模式（不写 text=True）
r = subprocess.run(["cat"], input=b"hello\n", capture_output=True)
```

### 6. 静音 / 合并 / 既要看又要拿

```python
# 全部丢弃
subprocess.run(["make"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

# stderr 合并进 stdout
r = subprocess.run(["make"], stderr=subprocess.STDOUT, capture_output=True, text=True)

# 既要实时看又要留全文：跑完后统一打印，或用 Popen 边读边写文件
print(r.stdout)
```

### 7. shell=True 的使用与安全

```python
# 需要管道/通配符/变量展开时才用 shell
subprocess.run("ls / | wc -l", shell=True)

# 想指定具体 shell，又不想让 shell=True 接管
subprocess.run(["bash", "-c", "ls / | wc -l"])
```

安全红线：**用户输入绝不能拼进 shell 字符串**。

```python
name = "x; rm -rf ~"
subprocess.run(f"echo {name}", shell=True)   # 危险：命令注入
subprocess.run(["echo", name])               # 安全：参数原样传递
```

- `shell=True` 时传列表：Linux 上只有第一个元素被当作命令。
- 手里只有整条命令字符串：拆用 `shlex.split()`，拼接用 `shlex.quote()`。

### 8. 环境变量与工作目录

```python
import os

env = os.environ.copy()
env["LANG"] = "C.UTF-8"
subprocess.run(["python", "-c", "print('hi')"], env=env, cwd="/tmp")
```

`env` 是整体替换：只传 `{"FOO": "bar"}` 会丢掉 `PATH` 等所有变量，导致命令找不到。要"追加"就先复制 `os.environ` 再改。

### 9. 流式输出（Popen）

```python
# 实时逐行读取
with subprocess.Popen(
    ["ping", "-c", "3", "example.com"],
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True,
) as p:
    for line in p.stdout:
        print(line, end="")

# 一次性读完（双向通信的唯一安全姿势）
p = subprocess.Popen(["some-cmd"], stdout=subprocess.PIPE, text=True)
out, _ = p.communicate()   # 防死锁
rc = p.wait()              # 回收；p.poll() 可非阻塞查看是否结束
```

两个坑：

- **缓冲**：子进程发现 stdout 不是终端会改用块缓冲，看不到"实时"输出。C 程序加 `stdbuf -oL`，Python 子进程加 `-u` 或设 `PYTHONUNBUFFERED=1`。
- **死锁**：同时有 stdout、stderr 两个 PIPE 时，不要手动分别 `read()`；一律 `communicate()`。

### 10. 管道

```python
# 方案 A：借 shell（简单）
r = subprocess.run("ls / | wc -l", shell=True, capture_output=True, text=True)

# 方案 B：显式链式（不走 shell，可控）
p1 = subprocess.Popen(["ls", "/"], stdout=subprocess.PIPE)
p2 = subprocess.Popen(["wc", "-l"], stdin=p1.stdout,
                      stdout=subprocess.PIPE, text=True)
p1.stdout.close()          # 关键：关闭父进程持有的读端，保证 p1 能收到 SIGPIPE
out, _ = p2.communicate()
p1.wait()                  # 回收 p1
print(out)
```

### 11. 终止进程与清理整套进程树

```python
# 简单终止
p = subprocess.Popen(["sleep", "100"])
p.terminate()              # SIGTERM
p.wait()
# p.kill()                 # SIGKILL
# p.send_signal(signal.SIGINT)

# 超时后连孙子进程一起清理：让子进程自成进程组，然后杀组
import os, signal

p = subprocess.Popen(["bash", "-c", "sleep 100 & wait"], start_new_session=True)
try:
    p.wait(timeout=5)
except subprocess.TimeoutExpired:
    os.killpg(p.pid, signal.SIGTERM)   # start_new_session 后 pgid == pid
    p.wait()
```

Python 3.11+ 也可以用 `process_group=0` 代替 `start_new_session=True`（只建新进程组，不建新会话）。

### 12. 以其他用户运行（3.9+，POSIX）

```python
subprocess.run(["id"], user="nobody", group="nogroup")   # 需要相应权限
```

### 13. 常见坑清单

1. `capture_output` 与显式 `stdout`/`stderr` 互斥；`input` 与 `stdin` 互斥。
2. `text=True` 的默认编码随 locale（中文 Windows 是 GBK）；要确定性就显式 `encoding="utf-8"`。
3. `env` 整体替换，记得 `os.environ.copy()`。
4. `run(timeout=...)` 只杀直接子进程，孙子会残留（见用法 11）。
5. PIPE 用不好会死锁，双向通信一律 `communicate()`。
6. `shell=True` + 用户输入 = 命令注入；参数优先列表传递。
7. 实时输出看不到，多半是子进程块缓冲（`-u` / `stdbuf -oL`）。
8. 遗留接口 `os.system` / `os.popen` / `subprocess.getoutput` 都不要再用了：返回值、信号、注入问题多，统一用 `run`。

## 三、速查表

常用常量：`subprocess.PIPE`（管道）、`subprocess.STDOUT`（合并到 stdout）、`subprocess.DEVNULL`（丢弃）。

| 需求 | 写法 |
|------|------|
| 跑命令、等结束 | `subprocess.run(["cmd", "arg"])` |
| 捕获输出 | `run([...], capture_output=True, text=True)` |
| 显式 UTF-8 | `run([...], encoding="utf-8", errors="replace")` |
| 非零退出即抛异常 | `run([...], check=True)` |
| 限时 | `run([...], timeout=10)` |
| 喂 stdin | `run([...], input="text", text=True)` |
| 丢弃输出 | `stdout=subprocess.DEVNULL` |
| stderr 合并 | `stderr=subprocess.STDOUT` |
| 换目录 / 补环境变量 | `cwd="/tmp"`；`env={**os.environ, "K": "V"}` |
| 走 shell（管道等） | `run("ls \| wc -l", shell=True)` |
| 安全拆分命令字符串 | `shlex.split(s)` |
| 逐行流式读取 | `Popen([...], stdout=PIPE, text=True)` + `for line in p.stdout` |
| 一次性读完、防死锁 | `p.communicate()` |
| 后台跑 + 终止 | `p = Popen([...])`；`p.terminate()`；`p.wait()` |
| 超时清理整组进程 | `start_new_session=True` + `os.killpg(p.pid, ...)` |
| 判断是否还在跑 | `p.poll()`（None 表示还在跑） |
| 模拟终端 | 不设 `capture_output`，输出直接继承当前终端 |
