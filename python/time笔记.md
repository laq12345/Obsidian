---
created: 2026-06-18
tags:
  - python
  - time
  - 标准库
  - 笔记
source: hermes-agent
---

# Python time 库完全教程

> 标准库，无需安装。处理时间戳、休眠、格式化、计时等基础操作。

---

## 一、核心概念：三种时间表示

Python 的时间操作绕不开这三种形式，搞懂它们就掌握了 90%：

| 形式 | 类型 | 例子 | 说明 |
|------|------|------|------|
| **时间戳** | float | `1687075200.0` | 1970-01-01 到现在的秒数（Unix 时间戳） |
| **结构化时间** | `time.struct_time` | `tm_year=2026, tm_mon=6, ...` | 9 字段的命名元组，便于取年/月/日 |
| **格式化字符串** | str | `"2026-06-18 20:30:00"` | 给人看的 |

**三者的转换关系：**

```
字符串  ──strptime()──→  结构化  ──mktime()──→  时间戳
字符串  ←─strftime()──  结构化  ←─localtime()/gmtime()──  时间戳
```

---

## 二、最常用函数 TOP 5

### 1. `time.sleep(sec)` — 让程序暂停

```python
import time

print("Start")
time.sleep(2)      # 停 2 秒
print("2 seconds later")

time.sleep(0.5)    # 停 0.5 秒（毫秒级）
```

> 这是 time 库中使用频率最高的函数，没有之一。

---

### 2. `time.time()` — 当前时间戳

```python
import time

t = time.time()
print(t)           # 1687075200.123456（秒）
```

**常见用途：**

```python
# 计时
start = time.time()
...  # 执行代码
elapsed = time.time() - start
print(f"Elapsed: {elapsed:.2f}s")

# 生成唯一标识
timestamp = int(time.time())  # 1687075200
```

---

### 3. `time.localtime([secs])` — 时间戳 → 结构化时间（本地时区）

```python
import time

# 当前时间
t = time.localtime()
print(t)
# time.struct_time(tm_year=2026, tm_mon=6, tm_mday=18,
#                   tm_hour=20, tm_min=30, tm_sec=0,
#                   tm_wday=3, tm_yday=169, tm_isdst=0)

# 访问各字段
t.tm_year   # 2026
t.tm_mon    # 6
t.tm_mday   # 18
t.tm_hour   # 20
t.tm_min    # 30
t.tm_sec    # 0
t.tm_wday   # 3  (0=周一, 6=周日)
t.tm_yday   # 169 (一年中的第几天)
```

**对应 `gmtime()`** 返回 UTC 时间：

```python
time.gmtime()  # 格林威治标准时间，中国差 8 小时
```

---

### 4. `time.strftime(format, [t])` — 结构化 → 字符串

```python
import time

t = time.localtime()

time.strftime("%Y-%m-%d %H:%M:%S", t)
# '2026-06-18 20:30:00'

time.strftime("%Y/%m/%d", t)
# '2026/06/18'

time.strftime("%H:%M:%S", t)
# '20:30:00'
```

常用格式码：

| 格式码 | 含义 | 示例 |
|--------|------|------|
| `%Y` | 四位年份 | 2026 |
| `%y` | 两位年份 | 26 |
| `%m` | 月份（01-12） | 06 |
| `%d` | 日期（01-31） | 18 |
| `%H` | 小时（00-23） | 20 |
| `%M` | 分钟（00-59） | 30 |
| `%S` | 秒（00-59） | 00 |
| `%w` | 星期几（0=周日） | 4 |
| `%A` | 星期全名 | Thursday |
| `%B` | 月份全名 | June |
| `%j` | 一年第几天 | 169 |
| `%%` | 百分号本身 | % |

> **捷径：** `time.strftime("%Y-%m-%d %H:%M:%S")` —— 不传第二个参数默认用当前时间。

---

### 5. `time.strptime(string, format)` — 字符串 → 结构化

```python
import time

t = time.strptime("2026-06-18 20:30:00", "%Y-%m-%d %H:%M:%S")
# time.struct_time(tm_year=2026, tm_mon=6, tm_mday=18, ...)

# 再转时间戳
ts = time.mktime(t)
# 1687075200.0
```

---

## 三、其他有用函数

### `time.mktime(t)` — 结构化 → 时间戳

```python
import time

t = (2026, 6, 18, 20, 30, 0, 3, 169, 0)
ts = time.mktime(t)  # 传元组或 struct_time 都行
```

### `time.perf_counter()` — 高精度计时（推荐）

```python
import time

start = time.perf_counter()
... # 执行代码
elapsed = time.perf_counter() - start

print(f"{elapsed*1000:.2f} ms")
```

> **`time.time()` vs `time.perf_counter()`：**
> - `time.time()` 可能受系统时间调整（NTP 同步、闰秒）影响
> - `time.perf_counter()` 单调递增，专为测量间隔设计
> 
> **计时一律用 `perf_counter()`**，避免意外的负值。

### `time.ctime([secs])` — 时间戳 → 可读字符串（快速调试用）

```python
import time

time.ctime()             # 'Thu Jun 18 20:30:00 2026'
time.ctime(1687075200)   # 指定时间戳
```

### `time.asctime([t])` — 结构化 → 可读字符串

```python
import time

t = time.localtime()
time.asctime(t)   # 'Thu Jun 18 20:30:00 2026'
```

---

## 四、struct_time 字段一览

| 属性 | 索引 | 范围 | 含义 |
|------|------|------|------|
| `tm_year` | 0 | 4位数字 | 年份 |
| `tm_mon` | 1 | 1-12 | 月份 |
| `tm_mday` | 2 | 1-31 | 日期 |
| `tm_hour` | 3 | 0-23 | 小时 |
| `tm_min` | 4 | 0-59 | 分钟 |
| `tm_sec` | 5 | 0-61\* | 秒 |
| `tm_wday` | 6 | 0-6 | 星期（0=周一） |
| `tm_yday` | 7 | 1-366 | 一年第几天 |
| `tm_isdst` | 8 | 0/1/-1 | 夏令时标志 |

> \* tm_sec 允许到 61 是因为闰秒（实际极少见）。

---

## 五、实用组合技

### 1. 简单计时器

```python
import time

class Timer:
    """上下文管理器计时器"""
    def __enter__(self):
        self.start = time.perf_counter()
        return self

    def __exit__(self, *args):
        self.elapsed = time.perf_counter() - self.start
        print(f"Elapsed: {self.elapsed:.3f}s")

# 使用
with Timer() as t:
    time.sleep(1.5)
# 输出: Elapsed: 1.501s
```

### 2. 带时间戳的日志

```python
import time

def log(msg):
    ts = time.strftime("%H:%M:%S")
    print(f"[{ts}] {msg}")

log("Processing started")
time.sleep(1)
log("50% complete")
time.sleep(1)
log("Done")
# [20:30:01] Processing started
# [20:30:02] 50% complete
# [20:30:03] Done
```

### 3. 超时控制

```python
import time

deadline = time.time() + 5  # 5 秒后超时
while time.time() < deadline:
    ...  # 尝试操作
print("Timed out")
```

### 4. 倒计时

```python
import time

for i in range(5, 0, -1):
    print(f"\r{i}...", end="", flush=True)
    time.sleep(1)
print("\rGo!")
```

---

## 六、time 与 datetime 的选择

| 场景 | 推荐库 |
|------|--------|
| 暂停程序 | `time.sleep()` |
| 代码计时 | `time.perf_counter()` |
| 获取时间戳 | `time.time()` |
| 格式化当前时间 | `time.strftime()` |
| **日期运算（加/减天数）** | `datetime.timedelta` |
| **时区转换** | `datetime + zoneinfo`（3.9+） |
| **解析多种日期格式** | `dateutil.parser`（第三方） |

> 简单格式化/休眠/计时 → `time`
> 日期加减、时区、复杂解析 → `datetime`

---

## 七、速查表

```python
import time

# 休眠
time.sleep(1.5)

# 计时
start = time.perf_counter()
elapsed = time.perf_counter() - start

# 当前时间戳
time.time()              # 1687075200.123

# 格式化当前时间
time.strftime("%Y-%m-%d %H:%M:%S")          # '2026-06-18 20:30:00'
time.strftime("%Y%m%d_%H%M%S")              # '20260618_203000'（文件名友好）

# 字符串 → 时间戳
ts = time.mktime(time.strptime("2026-06-18", "%Y-%m-%d"))

# 快速调试
time.ctime()             # 'Thu Jun 18 20:30:00 2026'
```
