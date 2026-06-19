---
created: 2026-06-18
tags:
  - python
  - loguru
  - 日志
  - 笔记
source: hermes-agent
---

# loguru 完全教程

> 让 Python 日志不再痛苦的库。相比标准库 `logging`，loguru 开箱即用，零配置。

安装：`pip install loguru` 或 `pixi add loguru`

---

## 一、为什么用 loguru（vs logging）

| 维度 | `logging` 标准库 | `loguru` |
|------|-----------------|----------|
| 配置量 | 至少 5 行模板代码 | 1 行 `add()` |
| 格式化 | 手写 Formatter | 直接用 `{}` 格式化 |
| 文件轮转 | `RotatingFileHandler` 配置繁琐 | `rotation="1 day"` 一行搞定 |
| 异常追溯 | 基本无 | 自动捕获、显示变量值 |
| 结构化日志 | 需要额外库 | 内置 `bind()`、`contextualize()` |
| 类型安全 | 字符串拼接 | `logger.info("{} {}", a, b)` |

**一句话**：`logging` 是"你要告诉我怎么工作"，`loguru` 是"我已经知道怎么工作，你用就行"。

---

## 二、最简入门

```python
from loguru import logger

logger.debug("这是一条调试信息")
logger.info("用户 {} 登录成功", "admin")
logger.warning("磁盘剩余空间 {} GB", 1.5)
logger.error("文件不存在: {}", "/path/to/file")
logger.critical("系统即将崩溃")
```

输出：

```
2026-06-18 20:30:00.123 | DEBUG    | __main__:<module>:3 - 这是一条调试信息
2026-06-18 20:30:00.124 | INFO     | __main__:<module>:4 - 用户 admin 登录成功
2026-06-18 20:30:00.125 | WARNING  | __main__:<module>:5 - 磁盘剩余空间 1.5 GB
2026-06-18 20:30:00.126 | ERROR    | __main__:<module>:6 - 文件不存在: /path/to/file
2026-06-18 20:30:00.127 | CRITICAL | __main__:<module>:7 - 系统即将崩溃
```

> **注意**：loguru 用 `logger.info("变量 {}", x)` 而不是 `logger.info(f"变量 {x}")`。前者是惰性求值，不影响性能。

---

## 三、5 个日志级别

| 级别 | 数值 | 方法 | 含义 |
|------|------|------|------|
| TRACE | 5 | `logger.trace()` | 最细粒度，基本不用 |
| DEBUG | 10 | `logger.debug()` | 开发调试 |
| INFO | 20 | `logger.info()` | 正常运行信息 |
| SUCCESS | 25 | `logger.success()` | 显式标注成功（loguru 独有） |
| WARNING | 30 | `logger.warning()` | 警告，但不影响运行 |
| ERROR | 40 | `logger.error()` | 错误，功能受影响 |
| CRITICAL | 50 | `logger.critical()` | 严重错误，可能崩溃 |

```python
# SUCCESS 是 loguru 特有的级别，标准库没有
logger.success("数据清洗完成，共处理 {} 行", 15000)
```

---

## 四、配置输出（核心：add/remove）

### 1. 基本配置

```python
from loguru import logger

# 清空默认的 stderr 输出
logger.remove()

# 添加自定义输出
logger.add("app.log")                          # 写入文件
logger.add("app_{time:YYYY-MM-DD}.log")         # 文件名带日期
logger.add("app.log", level="INFO")             # 只记录 INFO 及以上
```

### 2. 日志轮转

```python
# 按时间轮转
logger.add("app.log", rotation="1 day")        # 每天一个新文件
logger.add("app.log", rotation="12:00")         # 每天中午 12 点轮转
logger.add("app_{time}.log", rotation="1 week") # 每周轮转

# 按大小轮转
logger.add("app.log", rotation="100 MB")        # 超过 100MB 自动轮转
logger.add("app.log", rotation="500 MB")        # 500MB
```

### 3. 日志保留与压缩

```python
# 保留策略
logger.add("app.log", retention="10 days")     # 只保留最近 10 天
logger.add("app.log", retention=5)             # 只保留 5 个文件
logger.add("app.log", retention="1 week, 3")   # 每天保留最多 3 个

# 自动压缩旧日志
logger.add("app.log", rotation="100 MB", compression="zip")
logger.add("app.log", rotation="1 day", compression="gz")
```

### 4. 完整配置示例

```python
import sys
from loguru import logger

# 移除默认 handler
logger.remove()

# 终端：显示彩色，INFO 及以上
logger.add(sys.stderr, level="INFO", colorize=True)

# 文件：完整日志，每天轮转，保留 7 天
logger.add(
    "logs/app_{time:YYYY-MM-DD}.log",
    level="DEBUG",
    rotation="1 day",
    retention="7 days",
    compression="gz",
    encoding="utf-8",
)

# 错误单独一个文件
logger.add(
    "logs/error_{time:YYYY-MM-DD}.log",
    level="ERROR",
    rotation="1 day",
    retention="30 days",
)
```

### 5. `add()` 完整参数

```python
logger.add(
    sink,               # 输出目标：文件路径 (str/Path)、IO 流、可调用对象
    level="DEBUG",      # 最低日志级别
    format="...",       # 自定义格式字符串
    filter=None,        # 过滤器函数
    colorize=False,     # 是否彩色输出
    serialize=False,    # 输出 JSON 格式
    backtrace=False,    # 是否显示完整堆栈
    diagnose=False,     # 是否显示变量值
    enqueue=False,      # 是否异步写入（多线程安全）
    catch=True,         # 日志自身错误是否捕获
    rotation=None,      # 轮转策略
    retention=None,     # 保留策略
    compression=None,   # 压缩格式
    delay=False,        # 是否延迟创建文件
    mode="a",           # 文件打开模式
    encoding="utf-8",   # 文件编码
)
```

---

## 五、自定义格式

### 1. 格式字符串

```python
logger.add(sys.stderr, format="{time} | {level: <8} | {name}:{function}:{line} - {message}")

# 更简洁的常用格式
logger.add(sys.stderr, format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {message}")
```

### 2. 格式标签速查

| 标签 | 含义 | 示例 |
|------|------|------|
| `{time}` | 时间 | `2026-06-18T20:30:00.123456+0800` |
| `{time:YYYY-MM-DD}` | 自定义时间格式 | `2026-06-18` |
| `{level}` | 级别名 | `INFO` |
| `{level.icon}` | 级别图标 | `ℹ️`、`⚠️`、`❌` |
| `{name}` | 模块名 | `__main__` |
| `{function}` | 函数名 | `my_func` |
| `{line}` | 行号 | `42` |
| `{message}` | 日志消息 | |
| `{file}` | 文件名 | `app.py` |
| `{thread}` | 线程 ID | |
| `{process}` | 进程 ID | |
| `{extra}` | 绑定的额外字段 | `{"user": "admin"}` |

### 3. 颜色

```python
# 自动颜色
logger.add(sys.stderr, colorize=True)

# 手动颜色标签
logger.add(sys.stderr, format="<green>{time}</green> | <level>{level: <8}</level> | <cyan>{name}</cyan> - <level>{message}</level>")
```

颜色标签：`<red>`、`<green>`、`<yellow>`、`<blue>`、`<cyan>`、`<magenta>`、`<white>`、`<bold>`、`<underline>`

---

## 六、异常捕获

### 1. `logger.exception()`

```python
try:
    1 / 0
except ZeroDivisionError:
    logger.exception("除法出错了")
```

输出包含完整的 traceback + 变量值。

### 2. `@logger.catch` 装饰器

```python
from loguru import logger

@logger.catch
def divide(a, b):
    return a / b

divide(1, 0)  # 自动捕获异常，打印详细信息
```

```python
# 自定义异常消息
@logger.catch(message="函数执行失败: {function}")
def risky():
    ...
```

### 3. `catch=True` 参数

```python
# 日志系统本身出错时不崩溃
logger.add("app.log", catch=True)
```

---

## 七、绑定上下文数据

### 1. `bind()` — 静态绑定

```python
logger_a = logger.bind(user="admin", request_id="abc-123")
logger_b = logger.bind(user="guest")

logger_a.info("登录成功")   # 自动带上 user=admin
logger_b.info("登录成功")   # 自动带上 user=guest
```

输出（需在 format 中包含 `{extra}`）：

```
2026-06-18 20:30:00 | INFO | user=admin | 登录成功
2026-06-18 20:30:01 | INFO | user=guest | 登录成功
```

### 2. `contextualize()` — 上下文绑定

```python
# 在 with 块内自动带上上下文
with logger.contextualize(task="data_cleaning", batch=5):
    logger.info("开始处理")    # 自动带 task=batch
    logger.info("完成处理")

logger.info("处理完毕")        # 上下文已失效，不带 extra
```

### 3. 打印 extra 字段

```python
logger.add(sys.stderr, format="{time} | {level} | {extra} | {message}")

logger_a = logger.bind(user="admin")
logger_a.info("登录")
# 2026-06-18 | INFO | {'user': 'admin'} | 登录
```

---

## 八、过滤器

```python
# 方法1：字符串过滤模块
logger.add("app.log", filter="my_module")      # 只记录 my_module 的日志

# 方法2：函数过滤
def my_filter(record):
    if "敏感信息" in record["message"]:
        return False  # 丢弃
    return True

logger.add("app.log", filter=my_filter)

# 方法3：lambda
logger.add("app.log", filter=lambda r: "DEBUG" not in r["level"].name)
```

---

## 九、惰性求值与优化

```python
# ❌ 不好：即使 level=WARNING，也会先算 f-string
logger.info(f"处理了 {expensive_func()} 条数据")

# ✅ 好：惰性求值，level 不满足时完全不执行 expensive_func
logger.info("处理了 {} 条数据", expensive_func())
```

---

## 十、实用组合技

### 1. 多模块日志

```python
# main.py
from loguru import logger

logger.add("app.log", level="DEBUG")

# module_a.py
from loguru import logger
# 自动继承 main.py 的配置，不需要额外配置

# 模块间区分
logger.info("来自 module_a 的日志")  # 自动带文件名
```

### 2. 禁用日志

```python
logger.disable("__main__")   # 禁用某个模块的日志
logger.enable("__main__")    # 重新启用

# 条件控制
if not DEBUG:
    logger.remove()          # 移除所有 handler
    logger.add("app.log")    # 只写文件
```

### 3. 发送到多个目标

```python
import sys
from loguru import logger

# 终端：彩色
logger.add(sys.stderr, level="INFO", colorize=True)

# 文件：全部日志
logger.add("logs/debug.log", level="DEBUG", rotation="100 MB")

# 文件：仅错误
logger.add("logs/error.log", level="ERROR", rotation="1 day")

# Slack / 企业微信（通过自定义 sink）
def notify_slack(message):
    requests.post("https://hooks.slack.com/...", json={"text": message})

logger.add(notify_slack, level="CRITICAL")
```

### 4. JSON 结构化日志

```python
logger.add("app.json", serialize=True)
logger.info("用户登录", user="admin")

# app.json 内容
# {"text": "用户登录", "record": {"level": "INFO", "time": ..., "extra": {"user": "admin"}, ...}}
```

---

## 十一、完整项目配置模板

```python
import sys
from pathlib import Path
from loguru import logger

def setup_logger(log_dir: str = "logs", debug: bool = False):
    """一键配置项目日志"""
    log_path = Path(log_dir)
    log_path.mkdir(exist_ok=True)

    logger.remove()  # 清空默认

    # 终端输出（开发用）
    level = "DEBUG" if debug else "INFO"
    logger.add(
        sys.stderr,
        level=level,
        colorize=True,
        format="<green>{time:HH:mm:ss}</green> | <level>{level: <8}</level> | <cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> - <level>{message}</level>",
    )

    # 完整日志文件
    logger.add(
        log_path / "app_{time:YYYY-MM-DD}.log",
        level="DEBUG",
        rotation="1 day",
        retention="7 days",
        compression="gz",
        encoding="utf-8",
    )

    # 错误日志文件
    logger.add(
        log_path / "error_{time:YYYY-MM-DD}.log",
        level="ERROR",
        rotation="1 day",
        retention="30 days",
        compression="gz",
        encoding="utf-8",
    )

    return logger


# 使用
if __name__ == "__main__":
    log = setup_logger(debug=True)
    log.info("项目启动")
    log.debug("调试信息")
    log.success("配置完成")
```

---

## 十二、速查表

```python
from loguru import logger

# 基本使用
logger.debug("msg")
logger.info("msg")
logger.success("msg")      # loguru 特有
logger.warning("msg")
logger.error("msg")
logger.critical("msg")

# 格式化（惰性，推荐）
logger.info("用户 {} 登录，IP: {}", user, ip)

# 配置
logger.remove()                           # 清空默认
logger.add("app.log")                     # 写文件
logger.add("app.log", level="WARNING")    # 过滤级别
logger.add("app.log", rotation="100 MB")  # 按大小轮转
logger.add("app.log", rotation="1 day")   # 按天轮转
logger.add("app.log", retention="7 days") # 保留策略
logger.add("app.log", compression="zip")  # 压缩旧日志
logger.add(sys.stderr, colorize=True)     # 终端彩色输出

# 异常
@logger.catch
def func(): ...

try:
    ...
except:
    logger.exception("出错了")

# 绑定上下文
logger.bind(user="admin").info("登录")
with logger.contextualize(request_id="abc"):
    logger.info("处理请求")
```
