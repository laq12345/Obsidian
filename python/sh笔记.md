# sh 库 (v2.x) — 用 Python 函数的方式调用 shell 命令

> GitHub：https://github.com/amoffat/sh
> 安装：`pip install sh`
> 版本：2.3.0（2026年6月发布，v1.x → v2.x API 有重大变化）

---

## 1. 它解决什么问题

`subprocess` 功能强大但啰嗦。**sh 把 shell 命令变成 Python 函数：**

```python
import sh

sh.ls("-la", "/tmp")     # 等价于 ls -la /tmp
sh.echo("hello world")   # 等价于 echo hello world
sh.which("python")       # 等价于 which python
```

---

## 2. 基本用法

### 2.1 命令 = 函数

```python
import sh

# 系统命令直接当函数调用
sh.ls("/tmp")
sh.echo("hello")
sh.date()
sh.pwd()
sh.which("python")
sh.cat("/etc/passwd")
sh.wc("-l", "/etc/passwd")
```

命令名里有连字符，用下划线代替：

```python
sh.docker_compose("up", "-d")     # docker-compose up -d
sh.apt_get("install", "python")   # apt-get install python
```

### 2.2 传参数

```python
# 方式一：分开传（推荐）
sh.ls("-la", "/tmp")

# 方式二：字符串拆开
sh.ls("-la /tmp")

# 长参数
sh.ls("--all", "--human-readable", "/tmp")
```

### 2.3 返回值（纯字符串）

**v2.x 返回值是纯 `str`，不再有 `.exit_code`、`.ok`、`.stderr` 等属性：**

```python
out = sh.ls("-la")
print(type(out))    # <class 'str'>
print(out)          # 输出内容

lines = out.strip().split("\n")  # 直接当成字符串处理
```

---

## 3. 错误处理（改用异常）

### 按退出码细分

```python
try:
    sh.ls("/nonexistent")
except sh.ErrorReturnCode_2:   # 退出码 2
    print("目录不存在")
except sh.ErrorReturnCode_1:   # 退出码 1
    print("通用错误")
```

### 通用捕获

```python
try:
    sh.ls("/nonexistent")
except sh.ErrorReturnCode as e:
    print(f"退出码: {e.exit_code}")
    print(f"输出: {e.stdout}")
    print(f"错误: {e.stderr}")
```

### 允许特定退出码

```python
# 用 _ok_code 声明哪些退出码不算异常
out = sh.ls("/nonexistent", _ok_code=[0, 1, 2])

# 但 out 只是字符串，没有 .exit_code 属性
# 如果想检查是否成功，只能看 out 的内容
```

---

## 4. 管道操作

函数嵌套即可，和 v1.x 一样：

```python
# Shell:  ls /tmp | sort -r
sh.sort(sh.ls("/tmp"), "-r")

# Shell:  cat /etc/passwd | grep root
sh.grep(sh.cat("/etc/passwd"), "root")

# Shell:  ls /tmp | wc -l
sh.wc(sh.ls("/tmp"), "-l")
```

异步管道（大数据量并发处理）：

```python
sh.cat(sh.echo("a\nb\nc\n", _piped=True))
```

---

## 5. 特殊参数（以 `_` 开头）

| 参数 | 作用 | 例子 |
|------|------|------|
| `_cwd` | 指定工作目录 | `sh.ls(".", _cwd="/tmp")` |
| `_env` | 设置环境变量 | `sh.echo("hello", _env={"VAR": "val"})` |
| `_ok_code` | 允许的退出码 | `sh.ls("/x", _ok_code=[0, 1])` |
| `_timeout` | 超时秒数 | `sh.sleep("10", _timeout=3)` |
| `_bg` | 后台运行 | `sh.nginx("-c", "/etc/nginx.conf", _bg=True)` |
| `_out` | 输出到文件 | `sh.ls("/tmp", _out="output.txt")` |
| `_err` | 错误输出到文件 | `sh.ls("/x", _err="error.log")` |
| `_in` | 输入字符串 | `sh.grep("root", _in="root:x:0:0\n")` |
| `_tty_in` | 模拟终端输入 | `sh.passwd("user", _tty_in="newpass\n")` |
| `_piped` | 异步管道模式 | `sh.cat(sh.cmd(_piped=True))` |
| `_fg` | 前台运行（直连终端） | `sh.top(_fg=True)` |

```python
# 后台运行
p = sh.ping("google.com", _bg=True)
# 做其他事...
p.wait()

# 超时
try:
    sh.sleep("10", _timeout=3)
except sh.TimeoutException:
    print("超时了")
```

---

## 6. 高级功能

### baking（预绑定参数）

```python
# 绑定 -la 参数
ll = sh.ls.bake("-la")
# 等效于 sh.ls("-la", "/")
ll("/")

# 绑 SSH 服务器地址
my_server = sh.ssh.bake("user@10.0.0.1")
my_server("whoami")     # 等效于 ssh user@10.0.0.1 whoami
my_server.ifconfig()    # 等效于 ssh user@10.0.0.1 ifconfig
```

### 子命令（属性访问自动变成参数）

```python
# 等效
sh.git("show", "HEAD")
sh.git.show("HEAD")

# 多个子命令
sh.apt.get("install", "python")
```

### 更改目录

```python
# v2.x 不支持 sh.cd()，改用 pushd 上下文
with sh.pushd("/tmp"):
    sh.ls(".")    # 在 /tmp 下执行
```

### 输出重定向

```python
# 直接输出到文件
sh.ls(_out="/tmp/file_list.txt")

# 输出到文件对象
with open("/tmp/file_list.txt", "w") as f:
    sh.ls(_out=f)

# 输出到内存
from io import StringIO
buf = StringIO()
sh.ls(_out=buf)
```

### 实时迭代输出

```python
# _iter=True 让阻塞命令变成可迭代的
for line in sh.tail("-f", "info.log", _iter=True):
    if "ERROR" in line:
        print("发现错误:", line)
```

### 输出回调

```python
def on_line(line, stdin):
    if "password:" in line:
        stdin.put("mypass\n")

sh.ssh("host", _out=on_line, _out_bufsize=0, _tty_in=True)
```

---

## 7. 实用场景

### 结合 Python 变量

```python
path = "/tmp"
sh.ls(path)

# 直接处理输出
files = sh.ls("/tmp").strip().split("\n")
csv_files = [f for f in files if f.endswith(".csv")]
```

### 检查命令是否存在

```python
# v2.x 用 sh.which 返回路径字符串
docker_path = sh.which("docker")
if docker_path:
    print(f"Docker 在: {docker_path}")
else:
    print("Docker 未安装")
```

### 批量处理 FASTQ

```python
import sh
from pathlib import Path

fastq_files = list(Path(".").glob("*.fastq"))
for f in fastq_files:
    out = sh.fastp("-i", str(f), "-o", f"qc_{f.name}")
    print(f"{f.name} 完成")

# 打包结果
sh.tar("czf", "results.tar.gz", "*.html")
```

### 并行运行

```python
p1 = sh.ping("google.com", "-c", "1", _bg=True)
p2 = sh.ping("baidu.com", "-c", "1", _bg=True)
p1.wait()
p2.wait()
```

---

## 8. v1.x → v2.x 迁移速查

| v1.x 写法 | v2.x 写法 |
|-----------|-----------|
| `out.exit_code` | `try/except sh.ErrorReturnCode as e: e.exit_code` |
| `out.ok` | ❌ 已移除，用 try/except |
| `out.stderr` | ❌ 已移除，从异常对象获取 `e.stderr` |
| `sh.cd("/tmp")` | `with sh.pushd("/tmp"):` |
| `str(out)` | 已是字符串，直接 `out` |
| `sh.which("cmd").ok` | `bool(sh.which("cmd"))` |

---

## 9. sh vs subprocess

| 场景 | `subprocess` | `sh` |
|------|-------------|------|
| 简单调个命令 | 啰嗦 | `sh.ls("/")` |
| 捕获输出 | 要设 capture_output | 自动返回字符串 |
| 管道 | 串多个 Popen | 函数嵌套 |
| 在 .py 脚本里用 | ✅ | ✅ |
| 错误处理 | try/except | try/except |
| 传 Python 变量 | 拼接字符串 | 直接传 |

**结论：**
- 脚本里调系统命令 → `sh` 最简洁
- 需要精细控制进程 → `subprocess`
