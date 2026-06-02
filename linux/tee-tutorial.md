---
time: 2026-06-02T13:54:00
lang: Linux
tags:
  - 工具
  - linux
  - shell
  - tee
---

# `tee` 命令完全教程

## 一、什么是 `tee`

`tee` 是一个将**标准输入同时输出到标准输出和文件**的命令。名字来源于水管工用的 T 型三通接头（T-splitter），形象地表示"一路输入、两路输出"。

```
         stdin ──→ TEE ──→ stdout（屏幕）
                      │
                      └──→ 文件
```

## 二、核心功能

> **边看边存** —— 既能在终端看到命令输出，又同步写入文件。

```bash
# 基本语法
command | tee [选项] 文件...
```

## 三、选项速查

| 选项 | 说明 | 示例 |
|------|------|------|
| `-a` / `--append` | 追加到文件而非覆盖 | `tee -a log.txt` |
| `-i` / `--ignore-interrupts` | 忽略 Ctrl+C 信号 | `tee -i log.txt` |
| `-p` | 写入管道错误时不退出 | `tee -p log.txt` |
| `--output-error` | 控制写入错误的处理行为 | 见 4.3 节 |

---

## 四、基础用法

### 4.1 最简单的用法

```bash
# 输出到屏幕的同时保存到文件
$ echo "hello world" | tee output.txt
hello world            # ← 屏幕也显示了

$ cat output.txt
hello world            # ← 文件也写入了
```

### 4.2 写入多个文件

```bash
# 同时写入 3 个文件
echo "important data" | tee file1.txt file2.txt file3.txt

# 用通配符不行（tee 不支持），但可以用这个模式
echo "data" | tee /backup/{copy1,copy2,copy3}.txt
```

### 4.3 追加模式 `-a`

```bash
# 默认：覆盖写入
echo "line1" | tee log.txt
echo "line2" | tee log.txt    # log.txt 内容变为 "line2"

# -a：追加写入
echo "line1" | tee -a log.txt
echo "line2" | tee -a log.txt # log.txt 内容变为 "line1\nline2"
```

---

## 五、实战场景

### 5.1 记录编译/安装日志

```bash
# 编译并保留完整日志，同时看到进度
make 2>&1 | tee build.log

# 安装软件并记录
./configure && make 2>&1 | tee -a install.log
```

### 5.2 编辑需要权限的系统文件（经典用法）

```bash
# ❌ 普通 sudo vim 可以，但 sudo echo > 不行（重定向是 shell 做的）
sudo echo "nameserver 8.8.8.8" > /etc/resolv.conf  # Permission denied!

# ✅ tee 在 sudo 下运行，有写入权限
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

# 追加到系统文件
echo "127.0.0.1 myapp.local" | sudo tee -a /etc/hosts
```

### 5.3 管道中间"偷看"数据

```bash
# 在管道中插入 tee，观察中间步骤的数据
# 正常管道：看不到中间结果
cat data.txt | grep "ERROR" | sort | uniq -c

# 插入 tee 查看 grep 的输出
cat data.txt | tee /dev/tty | grep "ERROR" | sort | uniq -c

# 或者保存到文件同时让数据继续流动
cat data.log | grep "ERROR" | tee errors.txt | wc -l
```

### 5.4 多路输出到不同位置

```bash
# 保存原始日志，同时传送到分析脚本
tail -f /var/log/nginx/access.log \
  | tee raw.log \
  | awk '{print $1}' \
  | tee ips.log \
  | sort | uniq -c | sort -rn
```

### 5.5 配合进程替换（bash/zsh）

```bash
# 一路写入文件，一路传给不同命令
echo "data" | tee >(gzip > data.gz) >(md5sum > data.md5) > /dev/null

# 同时压缩和计算校验和
cat large_file | tee >(gzip > large.gz) >(sha256sum > large.sha256) > /dev/null
```

### 5.6 分发给多个用户终端

```bash
# 向多个终端广播消息
echo "系统将在 5 分钟后重启" | tee /dev/pts/1 /dev/pts/2
```

### 5.7 Docker/K8s 场景

```bash
# 查看容器日志并保存
docker logs myapp 2>&1 | tee container.log

# kubectl 操作记录
kubectl get pods -A | tee cluster-pods.txt
```

### 5.8 数据库备份

```bash
# mysqldump 同时压缩和保存
mysqldump -u root mydb | tee dump.sql | gzip > dump.sql.gz

# 或同时保存压缩和未压缩版本
mysqldump -u root mydb | tee dump.sql | gzip > dump.sql.gz
```

---

## 六、`tee > /dev/null` 技巧

当只想写入文件、不想要屏幕输出时：

```bash
# 静默写入（等于普通重定向 >，但可用 sudo）
echo "config" | sudo tee /etc/app.conf > /dev/null

# 追加写入不显示
echo "config" | sudo tee -a /etc/app.conf > /dev/null
```

---

## 七、与 `>` 重定向的对比

| 特性 | `>` 重定向 | `tee` |
|------|-----------|-------|
| 写文件 | ✅ | ✅ |
| 屏幕也显示 | ❌ | ✅ |
| 需要 sudo 写系统文件 | ❌（shell 处理，无 sudo） | ✅（tee 本身用 sudo） |
| 写入多个文件 | ❌（需多次重定向） | ✅ |
| 追加模式 | `>>` | `tee -a` |
| 管道中间使用 | ❌ | ✅ |

```bash
# > 的本质
echo "hi" > file.txt     # shell 打开文件，把 echo 的 stdout 重定向

# tee 的本质
echo "hi" | tee file.txt # tee 自己读写文件，stdout 保持到终端
```

---

## 八、常见陷阱

### 陷阱 1：`sudo echo > file` 不工作

```bash
# ❌ 为什么失败？
sudo echo "data" > /etc/protected.conf
# 解释：sudo 只提升 echo 的权限，> 重定向是当前 shell 执行的，没有 sudo。

# ✅ 正确做法
echo "data" | sudo tee /etc/protected.conf
```

### 陷阱 2：管道中的数据流

```bash
# tee 会把数据原样传递到 stdout，不会消耗数据
echo "hello" | tee copy.txt | tr 'a-z' 'A-Z'
# 输出：HELLO
# copy.txt：hello（原始数据）

# 管道后面的命令处理的是 tee 传递的数据
```

### 陷阱 3：stderr 不会通过管道传给 tee

```bash
# 默认管道只传递 stdout，stderr 不会经过 tee
failing_command | tee log.txt
# log.txt 是空的！因为错误输出到了 stderr

# ✅ 把 stderr 合并到 stdout
failing_command 2>&1 | tee log.txt

# 或者分开处理
failing_command 2> >(tee errors.txt)
```

### 陷阱 4：`tee` 会覆盖，不是追加

```bash
# 循环中容易踩坑
for i in 1 2 3; do
  echo "iteration $i" | tee log.txt  # 每次覆盖，最终只有 "iteration 3"
done

# ✅ 用 -a
for i in 1 2 3; do
  echo "iteration $i" | tee -a log.txt
done
```

---

## 九、高级技巧

### 9.1 带时间戳的日志

```bash
# 每行加时间戳后写入
ping -c 4 google.com | while read line; do
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $line"
done | tee ping.log
```

### 9.2 条件写入（仅写入，不显示）

```bash
# 写入文件并丢弃 stdout
command | tee file.txt > /dev/null
```

### 9.3 监控命令执行并备份输出

```bash
# 运行耗时脚本，既能看到进度，又有完整日志
long_running_script.sh 2>&1 | tee -a /var/log/script_$(date +%Y%m%d).log
```

### 9.4 多级管道调试

```bash
# 调试复杂管道，在每个阶段保存中间结果
cat access.log \
  | tee step1_raw.log \
  | grep "500" \
  | tee step2_500.log \
  | awk '{print $7}' \
  | tee step3_urls.log \
  | sort | uniq -c | sort -rn
```

### 9.5 同时发给多个远程主机

```bash
# 将配置文件同步发送到多台服务器
cat config.yaml | tee >(ssh host1 "cat > /etc/config.yaml") \
                       >(ssh host2 "cat > /etc/config.yaml") \
                       >(ssh host3 "cat > /etc/config.yaml") \
                       > /dev/null
```

---

## 十、速查卡片

```bash
# 最常用的 6 种模式

# 1. 输出到屏幕 + 保存文件
command | tee output.log

# 2. sudo 写入系统文件
echo "config" | sudo tee /etc/app.conf

# 3. 追加模式
command | tee -a history.log

# 4. pipe 中观察中间数据
cat data | tee step1.log | grep foo | tee step2.log | wc -l

# 5. shell 脚本同时输出并记录
./script.sh 2>&1 | tee script.log

# 6. 写入文件静默模式（不显示到屏幕）
echo "config" | sudo tee /etc/app.conf > /dev/null
```

---

## 十一、`tee` vs 其他方案

| 方案 | 适用场景 |
|------|----------|
| `tee` | 边看边存，管道中间保存数据 |
| `>` 重定向 | 只要文件不要屏幕输出 |
| `>>` 追加 | 追加到文件 |
| `script` 命令 | 录制整个终端会话 |
| `|&` (bash) | 同时重定向 stdout + stderr 到管道 |

```bash
# script 命令：记录整个终端会话（比 tee 更全面）
script session.log
# ... 执行各种命令 ...
exit
# 整个会话的操作和输出都记录在 session.log
```

---

## 十二、总结

`tee` 的核心价值就是一句话：**让数据在流经管道时不中断，同时写入文件做记录**。

三个最常用的场景：
1. **`command | tee log`** — 看输出 + 存日志
2. **`echo "x" | sudo tee /etc/file`** — 提权写入系统文件
3. **`cmd1 | tee mid | cmd2`** — 管道中间保存数据供调试
