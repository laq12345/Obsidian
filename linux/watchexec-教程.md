# watchexec 实用教程

## 安装

```bash
# 用 pixi
pixi global add watchexec

# 或 cargo
cargo install watchexec-cli
```

## 基础用法

```bash
# 监控当前目录，文件变化时执行命令（变化一次跑一次）
watchexec echo "文件变了"

# 只监听特定扩展名
watchexec -e py -- pytest -x

# 进程重启模式（kill 旧进程重新跑，适合开发服务器）
watchexec -r -- flask run

# 监控多个目录
watchexec -w src -w tests -- pytest

# 忽略目录
watchexec --ignore .git --ignore __pycache__ -- pytest
```

## 核心参数速查

### `-e` / `--exts` — 扩展名过滤

```bash
# 多个扩展名用逗号
watchexec -e py,rs,toml -- cargo test
```

### `-w` / `--watch` — 指定监控目录

```bash
# 默认当前目录，可以多个
watchexec -w ./src -w ./config -- myapp
```

### `-r` / `--restart` — 进程重启模式

默认 watchexec 每次变化**只执行一次命令**（执行完就等下次）。`-r` 让它在进程**还活着**时发信号终止旧进程，再启动新的——适合 web 服务器、开发工具等持续运行的程序。

```bash
# 不加 -r：每变化一次，跑一次 pytest，跑完结束，等下次变化
watchexec -e py -- pytest

# 加 -r：启动 flask，变化时 kill 再重启
watchexec -e py -r -- flask run
```

### `--on-busy-update` — 命令正在跑、文件又变了怎么办

| 选项 | 行为 | 适合 |
|------|------|------|
| `queue`（默认） | 等当前跑完，再跑一次 | 确保每个变化都处理 |
| `do-nothing` | 忽略中间变化，只保最新的 | 保存文件很频繁时 |
| `restart` | 中断当前进程，重新跑 | 开发服务器 |
| `signal` | 给进程发信号（如 SIGHUP） | 需要热重载的守护进程 |

```bash
# 频繁保存文件时，丢掉中间变化，不排队
watchexec -e py --on-busy-update do-nothing -- pytest

# 开发 web 服务，立即重启
watchexec -e py -r --on-busy-update restart -- flask run
```

### `-1` / `--once` — 只检测一次，变化了就退出

```bash
# 检测到变化后跑一遍命令，然后退出
watchexec -1 -- pytest
```

### `--debounce` — 去抖（毫秒）

```bash
# 默认 100ms，改成 500ms 减少触发频率
watchexec --debounce 500 -e py -- pytest
```

### `--clear` — 每次跑命令前清屏

```bash
watchexec --clear -- pytest
```

### `-n` / `--notify` — 系统桌面通知

```bash
watchexec -n -- make
```

### `--stop-signal` / `--stop-timeout` — 控制如何终止进程

```bash
# 发 SIGHUP 而不是 SIGTERM
watchexec -r --stop-signal SIGHUP -- myapp

# 等不及 5 秒就强制杀
watchexec -r --stop-timeout 2s -- myapp
```

## 实用场景速查

```bash
# 1. 代码变化自动测试（最常用）
watchexec -e py -r -- pytest -x

# 2. 自动渲染文档
watchexec -e qmd -- quarto render

# 3. 自动编译 Rust
watchexec -e rs -- cargo check

# 4. 监控日志文件变化
watchexec -e log -w /var/log -- tail -n 5 /var/log/syslog

# 5. Web 开发热重载
watchexec -e py,js,css -r -- python app.py

# 6. 文件复制同步
watchexec -1 -- rsync -avz ./src/ user@server:/app/
```

## 和 watcher 的对应关系

| 你现在的用法 | watchexec 等价 |
|------------|---------------|
| `watcher watch -e py -c "pytest -x"` | `watchexec -e py -- pytest -x` |
| `watcher watch -e py -c "flask run"` | `watchexec -e py -r -- flask run` |
| `watcher watch -e py`（默认只监控） | watchexec 默认就是只跑命令 |
| `watcher poll -e csv -i 5` | `watchexec -e csv --poll 5s -- ls` |
| 日志文件 + 中文变化标签 | ❌ watchexec 没有 |

## watchexec 有但 watcher 没有的

- `--on-busy-update`：命令正在跑时变化来了该怎么做（queue / restart / do-nothing / signal）
- `--once`：检测一次即退出
- `--notify`：系统桌面通知
- `--clear`：运行前清屏
- 配置文件支持（`watchexec.toml`）

## watcher 有但 watchexec 没有的

- 内置日志文件（自动按大小轮转）
- 中文变化类型标签（新增 / 修改 / 删除）
- `poll` 模式 + `--processed` 归档（适合流水线处理）
