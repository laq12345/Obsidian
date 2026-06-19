---
created: 2026-06-18
tags:
  - python
  - tqdm
  - 进度条
  - 笔记
source: hermes-agent
---

# tqdm 完全教程

> 快速、可扩展的 Python 进度条库。名称来自阿拉伯语 *taqaddum*（تقدّم）= "progress"。

安装：`pip install tqdm` 或 `pixi add tqdm`（无外部依赖，轻量）

---

## 一、最简用法：一行代码搞定

```python
from tqdm import tqdm
import time

for i in tqdm(range(100)):
    time.sleep(0.01)  # 模拟耗时操作
```

效果：

```
100%|████████████████████████████████| 100/100 [00:01<00:00, 99.87it/s]
```

> 把 `range(...)` 包进 `tqdm()` 就行，其他什么都不用改。

---

## 二、三种常用导入方式

| 方式 | 适用场景 |
|------|---------|
| `from tqdm import tqdm` | 普通迭代器进度条 |
| `from tqdm import trange` | 快速替代 `tqdm(range(n))` |
| `from tqdm.auto import tqdm` | **推荐** — 自动选择最佳显示方式（终端/Jupyter/notebook 等） |

```python
from tqdm import trange

for i in trange(100):
    time.sleep(0.01)
# 等价于 for i in tqdm(range(100))
```

**实际项目中推荐用 `tqdm.auto.tqdm`**，不挑环境。

---

## 三、核心参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `iterable` | iterable | — | 要包装的迭代对象 |
| `desc` | str | `None` | 进度条左侧描述文字 |
| `total` | int | `None` | 总迭代次数（自动从 len(iterable) 获取，生成器需手动指定） |
| `leave` | bool | `True` | 完成后是否保留进度条（设为 False 则完成后消失） |
| `ncols` | int | `None` | 进度条宽度（字符数，None=自动适应终端） |
| `miniters` | int | 1 | 最小更新间隔（迭代次数） |
| `mininterval` | float | 0.1 | 最小更新间隔（秒） |
| `maxinterval` | float | 10.0 | 最大更新间隔（秒） |
| `unit` | str | `'it'` | 单位名称（如 'B', 'samples'） |
| `initial` | int | 0 | 初始计数值 |
| `position` | int | 0 | 多进度条时的行位置 |
| `bar_format` | str | `None` | 自定义格式字符串 |
| `colour` | str | `None` | 进度条颜色（如 'green', '#00ff00'） |
| `smoothing` | float | 0.3 | 速度估算平滑系数（0=瞬时, 1=平均） |
| `disable` | bool | `False` | 设为 True 完全关闭进度条，方便条件控制 |

---

## 四、进阶用法

### 1. 加描述文字

```python
for i in tqdm(range(100), desc="Processing samples"):
    ...
# 输出: Processing samples: 100%|███████| 100/100 [00:01<00:00, 99.87it/s]
```

### 2. 手动控制进度

用于**无法直接包装迭代器**的场景（如 while 循环、逐块读取文件）：

```python
from tqdm import tqdm

pbar = tqdm(total=100, desc="Loading")
for i in range(10):
    time.sleep(0.1)
    pbar.update(10)   # 每次增加 10
pbar.close()          # 推荐手动关闭，或用 with

# 或 with 上下文（自动 close）
with tqdm(total=100, desc="Processing") as pbar:
    for i in range(10):
        time.sleep(0.1)
        pbar.update(10)
```

### 3. 自定义单位

```python
from tqdm import tqdm

for _ in tqdm(range(1000), unit="B", unit_scale=True, desc="Downloading"):
    ...
# 输出: Downloading: 100%|██████████| 1000/1000 [00:00<00:00, 9999.99B/s]

# 自动显示 K/M/G
for _ in tqdm(range(10**6), unit="B", unit_scale=True, desc="Processing"):
    ...
# 输出: Processing: 100%|█████████| 976.56KiB/976.56KiB [00:00<00:00, 10.24MiB/s]
```

### 4. 多进度条

```python
from tqdm import tqdm
import time

# position 决定行位置，leave 决定完成后是否保留
for i in tqdm(range(5), desc="Outer", position=0, leave=True):
    for j in tqdm(range(100), desc=f"Inner {i}", position=1, leave=False):
        time.sleep(0.01)
```

### 5. 嵌套进度条（tqdm.contrib）

```python
from tqdm.contrib.concurrent import thread_map, process_map
import time

def process_item(x):
    time.sleep(0.1)
    return x * 2

# 多线程 + 进度条
results = thread_map(process_item, range(20), max_workers=4, desc="Threaded")

# 多进程 + 进度条
results = process_map(process_item, range(20), max_workers=4, desc="Multiprocess")
```

### 6. 更新描述文字（动态显示当前状态）

```python
from tqdm import tqdm
import time

pbar = tqdm(range(50), desc="Starting...")
for i, item in enumerate(pbar):
    time.sleep(0.05)
    pbar.set_description(f"Processing sample {i}")
    pbar.set_postfix(loss=round(1/(i+1), 4), acc=round(i/(i+1), 4))
```

输出类似：`Processing sample 23: 48%|████ | 24/50 [00:01<00:01, 19.98it/s, loss=0.0417, acc=0.9583]`

### 7. 控制进度条显示/隐藏

```python
import logging

# 根据条件关闭进度条（如非交互模式）
verbose = False
for i in tqdm(range(100), disable=not verbose):
    ...

# 重定向到 logger
from tqdm import tqdm
tqdm.write("This message won't break the progress bar")
```

### 8. 写入文件

```python
# 用 file 参数指定输出流（默认 stderr）
with open("progress.log", "w") as f:
    for i in tqdm(range(100), file=f, desc="Batch"):
        ...
```

### 9. 配合 pandas

```python
import pandas as pd
from tqdm import tqdm

# 启用 pandas 进度条
tqdm.pandas(desc="Processing")

df = pd.DataFrame({"a": range(1000)})
df["b"] = df["a"].progress_apply(lambda x: x ** 2)
```

### 10. 配合 enumerate / zip

```python
# tqdm 包在外面即可
for i, item in enumerate(tqdm(samples, desc="Samples")):
    ...

for a, b in tqdm(zip(list_a, list_b), total=len(list_a), desc="Pairs"):
    ...
```

---

## 五、bar_format 自定义

```python
from tqdm import tqdm

# 仅显示百分比
for i in tqdm(range(100), bar_format="{l_bar}{bar}| {n_fmt}/{total_fmt}"):
    ...

# 只显示当前/总数，不显示进度条
for i in tqdm(range(100), bar_format="{l_bar}{n_fmt}/{total_fmt}  "):
    ...

# 去掉速度显示
for i in tqdm(range(100), bar_format="{l_bar}{bar}| {percentage:3.0f}%"):
    ...
```

**bar_format 变量对照**：

| 变量 | 含义 |
|------|------|
| `{l_bar}` | 左侧描述（desc + 百分比） |
| `{bar}` | 进度条本身（████） |
| `{r_bar}` | 右侧（已用时间 + 剩余时间 + 速度） |
| `{n}` | 当前值 |
| `{n_fmt}` | 当前值（格式化，如 12.3M） |
| `{total}` | 总数 |
| `{total_fmt}` | 总数（格式化） |
| `{percentage}` | 百分比（浮点） |
| `{elapsed}` | 已用时间 |
| `{remaining}` | 预计剩余时间 |
| `{rate}` | 原始速率 |
| `{rate_fmt}` | 格式化速率 |
| `{rate_noinv}` | 原始速率（不反转） |
| `{rate_noinv_fmt}` | 格式化速率（不反转） |
| `{desc}` | 描述文字 |
| `{desc_pre}` | 描述文字（前置） |

---

## 六、三目运算符风格的 tqdm 条件控制

```python
# 一行开启/关闭进度条
iterable = range(10000)
show_progress = True

for i in (tqdm(iterable, desc="Processing") if show_progress else iterable):
    ...
```

---

## 七、生成器场景（手动指定 total）

```python
def read_lines(filepath):
    with open(filepath) as f:
        for line in f:
            yield line.strip()

# 生成器没有 __len__，必须手动传 total
# 可用 wc -l 提前获取行数
lines = read_lines("large_file.txt")
for line in tqdm(lines, total=1000000, desc="Reading"):
    ...
```

---

## 八、trange + 断点续跑（initial 参数）

```python
from tqdm import trange

start = 50  # 假设已经处理到 50
for i in trange(100, initial=start, desc="Processing"):
    ...
# 进度从 50/100 开始，而不是 0/100
```

---

## 九、性能建议

1. **`mininterval=1`** — 对于超快循环，1 秒更新一次就够了，减少 print 开销
2. **`miniters=1000`** — 或等每 1000 次更新一次
3. **`disable=not verbose`** — 非交互模式直接关闭
4. **避免在超快循环（<0.01s 每项）中使用默认参数**——进度条本身的 I/O 开销可能占主导

```python
# 超快循环优化
for i in tqdm(range(10**7), mininterval=5, miniters=10000):
    ...
```

---

## 十、Jupyter / Notebook 专用

```python
# tqdm.auto 会自动检测环境
from tqdm.auto import tqdm

for i in tqdm(range(100)):
    ...
```

Jupyter 中如果进度条显示异常，显式用：

```python
from tqdm.notebook import tqdm
```
