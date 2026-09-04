---
lang: Linux
date: 2026-09-04
tags:
  - 编程
  - Linux
  - SSH
---

# SSH 常用方法详解

> SSH（Secure Shell）用于远程登录、命令执行与安全传输。本文基于 OpenSSH（本机 10.2p1），涵盖日常 90% 场景。

## 基本语法

```bash
ssh [选项] [用户@]主机 [命令]
```

- 省略用户：默认用**当前本地用户名**登录
- 省略命令：进入交互式 shell
- 带命令：在远端执行单条命令后立即退出

## 基础连接

```bash
ssh user@example.com            # 普通登录
ssh example.com                 # 用本地用户名登录
ssh -p 2222 user@host           # 指定端口（默认 22）
ssh user@host 'uname -a'        # 远端执行命令，不进入 shell
ssh user@host 'ls; df -h'       # 远端执行多条命令
ssh -t user@host sudo systemctl restart nginx   # -t 分配伪终端，支持 sudo
```

## 常用选项

| 选项                | 说明                             |
| ----------------- | ------------------------------ |
| `-p 端口`           | 指定端口（默认 22）                    |
| `-i 密钥文件`         | 指定私钥文件（默认 `~/.ssh/id_*`）       |
| `-l 用户名`          | 指定登录用户（等价于 `user@host`）        |
| `-t` / `-tt`      | 强制分配伪终端；`-tt` 强制分配即使命令需要       |
| `-T`              | 禁用伪终端分配（适合纯脚本/管道）              |
| `-v` `-vv` `-vvv` | 调试输出，级别递增（排查连接问题时用）            |
| `-o 选项`           | 直接传配置项，如 `-o ConnectTimeout=5` |
| `-N`              | 不执行远程命令，只建立连接（专用于端口转发）         |
| `-f`              | 连接成功转入后台运行（配合 `-N` 做隧道）        |
| `-J 跳板`           | 通过跳板机连接（ProxyJump）             |
| `-L / -R / -D`    | 端口转发（见下文）                      |
| `-C`              | 压缩传输数据（慢速网络有用）                 |
| `-4` / `-6`       | 强制 IPv4 / IPv6                 |
| `-q`              | 安静模式，抑制大部分输出                   |

## 密钥认证（免密登录）

### 1. 生成密钥对

```bash
ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/id_ed25519
```

- `-t ed25519`：推荐算法（现代且快）；旧系统可用 `-t rsa -b 4096`
- `-C`：注释（通常写邮箱或用途，便于辨认）
- `-f`：指定文件名；不加则询问保存路径
- 按提示设置 passphrase（口令），可留空

### 2. 复制公钥到服务器

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@host
```

- 把公钥追加到远端的 `~/.ssh/authorized_keys`
- 首次仍会要求输入密码，之后即可免密登录

### 3. 手动追加（ssh-copy-id 不可用或想控制内容）

```bash
cat ~/.ssh/id_ed25519.pub | ssh user@host 'mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'
```

### 4. ssh-agent 管理密钥

```bash
eval "$(ssh-agent -s)"          # 启动 agent
ssh-add ~/.ssh/id_ed25519       # 把私钥加入（只输一次 passphrase）
ssh-add -l                      # 列出已加载的密钥
ssh-add -L                      # 列出已加载密钥的公钥
ssh-add -D                      # 清空所有已加载密钥
ssh-add -t 3600                 # 设置密钥在 agent 中的存活时间（单位秒）
```

> 好处：私钥带 passphrase 时，之后同一会话内不再反复输入；配合 `ForwardAgent` 可向跳板后的机器传递认证。

## 配置文件 `~/.ssh/config`（强烈推荐）

把常用主机写成别名，之后 `ssh myserver` 即可。

```bash
# 完整示例
Host myserver                 # 别名
    HostName 192.168.1.100    # 真实地址
    User alice                # 用户名
    Port 2222                 # 端口
    IdentityFile ~/.ssh/id_ed25519   # 指定私钥
    ServerAliveInterval 60    # 每 60s 发保活包，防止断线
    ServerAliveCountMax 3     # 连续 3 次无响应则断开

Host *.internal.example.com   # 通配符：整组主机共用配置
    User admin
    ProxyJump bastion         # 通过 bastion 跳板
    Compression yes           # 开启压缩

Host *                        # 全局默认（放最后）
    AddKeysToAgent yes        # 首次使用后自动加入 agent
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking ask
```

```bash
ssh myserver                  # 直接用别名连接
ssh -F 其他配置文件 user@host # 指定使用其他配置文件（-F）
```

**优先级**：命令行 `-o` 选项 > `~/.ssh/config` 中**靠前**的匹配项 > 系统 `/etc/ssh/ssh_config`。

## 端口转发（SSH 隧道）

把远端/本地的端口通过 SSH 安全转发，加密传输应用流量。

### 本地转发 `-L`（访问远端能访问的服务）

```bash
# 把本地 8080 端口，经 host 转发到 host 能访问的 192.168.1.50:80
ssh -L 8080:192.168.1.50:80 user@host
# 访问 http://localhost:8080 即相当于访问 http://192.168.1.50:80

# 常用场景：访问防火墙后的数据库
ssh -L 3306:localhost:3306 user@dbhost   # 本地 3306 -> 远端本机 3306
mysql -h 127.0.0.1 -P 3306 -u root -p
```

### 远程转发 `-R`（把本地服务暴露给远端）

```bash
# 把远端主机的 9000 端口，转发到本地 80 端口
ssh -R 9000:localhost:80 user@public_host
# 在 public_host 上访问 localhost:9000 即相当于访问本机 80 端口
```

### 动态转发 `-D`（SOCKS5 代理）

```bash
# 本机 1080 端口变为 SOCKS5 代理，所有流量经 host 出口
ssh -D 1080 user@host
# 配合浏览器/curl：curl --socks5 localhost:1080 https://example.com
```

### 后台隧道 + 关闭

```bash
ssh -fN -L 8080:localhost:80 user@host   # -N 不执行命令，-f 转后台
pgrep -af "ssh -fN"                      # 查找隧道进程
pkill -f "ssh -fN"                       # 关闭隧道
```

> 远端 SSH 服务默认允许转发；`AllowTcpForwarding` 与 `GatewayPorts` 可控制策略。

## 文件传输

### scp（复制文件/目录）

```bash
scp file.txt user@host:/home/user/          # 本地上传
scp user@host:/home/user/file.txt .         # 远端下载
scp -r ./dir user@host:/home/user/          # 递归复制目录
scp -P 2222 file.txt user@host:~/           # 指定端口（scp 用大写 -P）
scp -i ~/.ssh/id_ed25519 file.txt user@host:# 指定密钥
```

> 同目录同名会覆盖；初始化用 `-C` 压缩，慢速网络提速明显。

### sftp（交互式文件管理）

```bash
sftp user@host
# 交互命令：
#  ls / ll           列本地/远端
#  cd / lcd          切换远端/本地目录
#  put file          上传
#  get file          下载
#  put -r dir / get -r dir   递归
#  mput *.txt / mget *.log   批量
#  exit / bye        退出
```

### rsync（增量同步，推荐用于大目录）

```bash
rsync -avz --progress ./src/ user@host:/home/user/src/
rsync -avz --delete user@host:/data/ ./backup/   # --delete 双向保持一致
rsync -e "ssh -p 2222" ./src user@host:~/        # 指定 ssh 选项
```

## 跳板机连接（多跳）

一线通连（推荐，`-J` 或 `ProxyJump`）：

```bash
ssh -J user@bastion user@target     # 经 bastion 连 target
ssh -J host1,host2 user@target      # 多级跳板
# config 写法见上文 ProxyJump 示例
```

进程穿透不必在跳板机上留密钥；但注意安全——一般不要开 `ForwardAgent`，除非信任跳板机：

```bash
# 需要转发 agent 时才显式开启
ssh -A user@bastion
```

旧式写法（`ProxyCommand`，用 nc 转发）：

```bash
ssh -o ProxyCommand="ssh -W %h:%p user@bastion" user@target
# 或
ssh -o ProxyCommand="nc -X 5 -x proxy:1080 %h %p" user@target   # 经 HTTP/SOCKS 代理
```

## 调试与排错

```bash
ssh -v user@host          # 详细日志（-vv / -vvv 更详细）
ssh -o ConnectTimeout=5 user@host    # 5 秒超时，避免长时间卡住
ssh -o StrictHostKeyChecking=no user@host   # 首次跳过指纹确认（仅测试用，生产不建议）
```

常见问题速查：

| 现象 | 常见原因与对策 |
|------|----------------|
| `Permission denied (publickey)` | 密钥未配置/未指定；确认 `authorized_keys`、私钥权限 `600` |
| `Connection refused` | 端口错、服务未启动、防火墙拦截；试 `ssh -p 端口` 与 `nc -vz host 22` |
| `Connection timed out` | 网络不通、防火墙丢包；增大 `ConnectTimeout` 排查 |
| `Host key verification failed` | 主机指纹变化（重装/中间人风险）；先核实，再用 `ssh-keygen -R host` 清除旧指纹 |
| `Bad owner or permissions` | 本地 `~/.ssh` 权限：目录 700、文件 600；`chmod 700 ~/.ssh && chmod 600 ~/.ssh/*` |
| `Too many authentication failures` | 尝试密钥过多；用 `-o IdentitiesOnly=yes -i 指定密钥` |
| 连接后频繁断线 | 加 `ServerAliveInterval 60` |

本地目录权限一键修复：

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*(N.)   # 所有文件 600（zsh 语法）；bash: find ~/.ssh -type f -exec chmod 600 {} \;
```

## 安全实践要点

1. **禁用密码登录**（服务器端 `/etc/ssh/sshd_config`）：`PasswordAuthentication no`，仅密钥认证
2. **禁止 root 直连**：`PermitRootLogin no`
3. 私钥文件务必 `chmod 600`，云端/共享机器上不要裸存私钥
4. 定期 `ssh-keygen -y -f 私钥` 核对私钥与公钥配对，换机器/换 key 后记得清理旧授权
5. 生产服务器开启 fail2ban 或限制来源 IP，配合 `MaxAuthTries 3`
6. 不轻易开 `ForwardAgent`（会被跳板机窃取 agent 转发权限）
7. 指纹验证：登录前可用 `ssh-keyscan -t ed25519 host` 对比已知指纹

## 相关命令

- `ssh-keygen`：生成/管理密钥对（`-t` 算法、`-R` 清除指纹、`-p` 改口令）
- `ssh-copy-id`：一键复制公钥到服务器
- `ssh-agent` / `ssh-add`：密钥驻留内存，避免反复输入口令
- `scp` / `sftp`：基于 SSH 的文件传输
- `rsync -e ssh`：增量同步、断点续传
- `ssh-keyscan`：获取主机公钥指纹
- `sshfs`：把远程目录挂载为本地文件系统（`sshfs user@host:/path /mnt/point`）