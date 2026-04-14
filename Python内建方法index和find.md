---
lang: Python
date: 2026-04-07
tags:
  - 编程
---
## Python 字符串 `index()` vs `find()` 详解

### 一句话区别

| | `find()` | `index()` |
|--|---------|-----------|
| **找不到时** | 返回 **`-1`** | **抛出 `ValueError` 异常** |
| **其他方面** | 完全相同 | 完全相同 |

---

### 基本用法

```python
s = "hello world, hello python"

# ====== find() ======
print(s.find("world"))      # 6   → 找到，返回起始索引
print(s.find("java"))       # -1  → 找不到，返回 -1（不报错）

# ====== index() ======
print(s.index("world"))     # 6   → 找到，返回起始索引
print(s.index("java"))      # 💥 ValueError! 找不到直接报错
```

---

### 完整参数

```python
str.find(sub, start, end)
str.index(sub, start, end)
```

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `sub` | 要查找的子串 | 必填 |
| `start` | 开始搜索的位置（包含） | `0` |
| `end` | 结束搜索的位置（不包含） | 字符串末尾 |

```python
s = "hello world, hello python"

# 指定搜索范围 [start, end)
print(s.find("lo", 3))        # 从索引3开始找 → 3
print(s.find("lo", 4))        # 从索引4开始找 → 14（跳过第一个lo）

print(s.find("o", 0, 8))      # 在 [0,8) 范围内找 → 4（第二个o在位置7，但world的o在7）
print(s.find("python", 0, 12)) # 在 [0,12) 范围内找 → -1（python不在此范围）
```

---

### 从右边找：`rfind()` 和 `rindex()`

```python
s = "hello world, hello python"

# find / index → 从左往右，找到第一个
print(s.find("hello"))    # 0
print(s.index("hello"))   # 0

# rfind / rindex → 从右往左，找到最后一个
print(s.rfind("hello"))   # 13
print(s.rindex("hello"))  # 13
```

---

### 四个方法对比表

| 方法 | 方向 | 找不到时 | 返回值 |
|------|------|---------|--------|
| `find(sub)` | 从左→右 | 返回 `-1` | 首次出现的索引 |
| `rfind(sub)` | 从右→左 | 返回 `-1` | 最后出现的索引 |
| `index(sub)` | 从左→右 | **抛异常** `ValueError` | 首次出现的索引 |
| `rindex(sub)` | 从右→左 | **抛异常** `ValueError` | 最后出现的索引 |

---

### 实际应用场景

#### 场景 1：判断子串是否存在 ⭐ 最常用

```python
url = "https://www.example.com/api/users"

# 用 find 判断（返回 -1 表示不存在）
if url.find("https://") != -1:
    print("是 HTTPS 安全连接")

# 更推荐用 in（更简洁）
if "https://" in url:
    print("是 HTTPS 安全连接")
```

#### 场景 2：提取字符串中的关键信息

```python
filename = "report_2025_q4_final.pdf"

# 找到扩展名的位置
dot_pos = filename.rfind(".")     # 最后一个点的位置
ext = filename[dot_pos:]          # 提取 .pdf
name = filename[:dot_pos]         # 提取文件名
print(f"文件名: {name}")           # report_2025_q4_final
print(f"扩展名: {ext}")            # .pdf

# 找到下划线分隔的部分
first_underscore = filename.find("_")   # 6
second_underscore = filename.find("_", first_underscore + 1)  # 11
third_underscore = filename.find("_", second_underscore + 1)  # 14

year = filename[first_underscore+1 : second_underscore]
quarter = filename[second_underscore+1 : third_underscore]
print(f"年份: {year}, 季度: {quarter}")   # 年份: 2025, 季度: q4
```

#### 场景 3：替换指定位置的文本

```python
template = "Dear {name}, your order #{order_id} has been shipped."

# 找到占位符位置并替换
start = template.find("{name}")
end = template.find("}", start) + 1
result = template[:start] + "张三" + template[end:]
print(result)
# Dear 张三, your order #{order_id} has been shipped.
```

> 💡 当然实际中更推荐用 `str.format()` 或 f-string，这里只是演示 find 的用法。

#### 场景 4：解析日志/固定格式数据

```python
log = "[2025-04-07 22:30:15] ERROR: Connection timeout at line 42"

# 提取时间戳
ts_start = log.find("[") + 1
ts_end = log.find("]")
timestamp = log[ts_start:ts_end]
print(f"时间: {timestamp}")        # 2025-04-07 22:30:15

# 提取日志级别
level_start = log.find("]") + 2
level_end = log.find(":", level_start)
level = log[level_start:level_end].strip()
print(f"级别: {level}")             # ERROR

# 提取行号
line_num = log[log.rfind(" ") + 1:]
print(f"行号: {line_num}")           # 42
```

---

### `in` 操作符 vs `find()` vs `index()`

```python
s = "hello world"

# 判断是否存在 —— 三种写法
"world" in s                # ✅ 推荐！最简洁，返回 True/False
s.find("world") != -1      # 可以，但啰嗦
try:
    s.index("world")       # 不推荐，大材小用
except ValueError:
    False
```

| 需求 | 推荐方法 |
|------|---------|
| 只判断**有没有** | `"sub" in s` ✅ |
| 需要**知道位置** | `s.find("sub")` 或 `s.index("sub")` |
| 找不到时**要报错提醒** | `s.index("sub")` ✅ |
| 找不到时**静默处理** | `s.find("sub")` ✅ |

---

### 速查代码卡

```python
s = "hello world, hello python"

# 基本查找
s.find("world")        # 6（从左找第一个）
s.rfind("hello")       # 13（从右找最后一个）
s.index("world")       # 6（找不到则抛异常）
s.rindex("hello")      # 13（找不到则抛异常）

# 指定范围
s.find("l", 3, 10)     # 在 [3,10) 范围内查找

# 判断存在
s.find("xyz") == -1     # False（不存在）
"hello" in s            # True（推荐写法）

# 常见模式：提取子串
pos = s.find(", ")      # 找分隔符位置
before = s[:pos]        # 分隔符前的部分
after = s[pos+2:]       # 分隔符后的部分
```