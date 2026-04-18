---
lang: Python
date: 2026-04-08
tags:
  - 数据分析
---
## 表 8.2：`pandas.merge()` 函数参数

| 参数 | 描述 |
|------|------|
| **left** | 位于**左侧**进行合并的 DataFrame |
| **right** | 位于**右侧**进行合并的 DataFrame |
| **how** | 合并的**连接方式**：取值为 `"inner"`、`"outer"`、`"left"` 或 `"right"` 之一；默认为 `"inner"` |
| **on** | 用于连接的**列名**。必须在两个 DataFrame 对象中都存在。如果未指定且没有给出其他连接键，将使用 `left` 和 `right` 中列名的**交集**作为连接键 |
| **left_on** | **左侧** DataFrame 中用作连接键的列。可以是单个列名或列名列表 |
| **right_on** | 与 `left_on` 类似，用于**右侧** DataFrame |
| **left_index** | 使用 **left 的行索引**作为连接键（如果是 MultiIndex 则使用多个键） |
| **right_index** | 与 `left_index` 类似 |
| **sort** | 按连接键对合并后的数据进行**字典序排序**；默认为 `False`（不排序） |
| **suffixes** | 当列名重叠时，追加到列名后的**字符串元组**；默认为 `("_x", "_y")`（例如：如果 `"data"` 同时出现在两个 DataFrame 中，结果中会显示为 `"data_x"` 和 `"data_y"`） |
| **copy** | 如果为 `False`，在某些特殊情况下**避免将数据复制到结果数据结构中**；默认始终复制数据 |
| **validate** | 验证合并是否属于指定类型：一对一（one-to-one）、一对多（one-to-many）或多对多（many-to-many）。详见文档字符串中关于各选项的完整说明 |
| **indicator** | 添加一个特殊的 `_merge` 列，用于指示每行数据的**来源**；每行的值根据连接数据的来源不同，将为 `"left_only"`、`"right_only"` 或 `"both"` |

---

### 补充说明

#### `how` 参数的四种连接方式图解：

```
left:              right:           inner (交集):     left (左连):
   A  B               B  C                A  B  C          A  B  C
0  a1  b1          0  b1  c1         0  a1  b1  c1     0  a1  b1  c1
1  a2  b2          1  b2  c2         1  a2  b2  c2     1  a2  b2  c2
2  a3  b3          2  b4  c4                               2  a3  b3 NaN
                                         outer (并集):    right (右连):
                                           A  B  C        A  B  C
                                        0  a1  b1  c1    0  a1  b1  c1
                                        1  a2  b2  c2    1  a2  b2  c2
                                        2  a3  b3 NaN    2  NaN b4  c4
                                        3  NaN b4  c4
```

#### `indicator` 参数示例：

```python
import pandas as pd
df1 = pd.DataFrame({'key': ['a', 'b', 'c'], 'val1': [1, 2, 3]})
df2 = pd.DataFrame({'key': ['b', 'c', 'd'], 'val2': [20, 30, 40]})

pd.merge(df1, df2, on='key', how='outer', indicator=True)
#   key  val1  val2      _merge
# 0   a   1.0  NaN   left_only
# 1   b   2.0  20.0       both
# 2   c   3.0  30.0       both
# 3   d  NaN  40.0  right_only
```

# Pandas 数据合并与连接 — 学习笔记

## 一、四大方法总览

| 方法                   | 连接方式               | 默认行为           | 典型场景        |
| -------------------- | ------------------ | -------------- | ----------- |
| `pd.merge()`         | 按列值匹配（类似 SQL JOIN） | inner join（交集） | 数据库表关联      |
| `df.join()`          | 按索引匹配（merge 的简写版）  | left join      | 同索引的多表合并    |
| `pd.concat()`        | 沿轴堆叠（不匹配，直接拼）      | 纵向拼接（axis=0）   | 追加数据、合并同类文件 |
| `df.combine_first()` | 用非 NaN 值填充缺失位      | 调用者优先          | 数据补全、缺失值修复  |

**选择决策树：**

```
需要合并数据？
├─ 要按"键"匹配？ → merge 或 join
│   ├─ 键在列中 → merge
│   └─ 键在索引中 → join
├─ 直接堆叠？ → concat
└─ 填充缺失值？ → combine_first
```

---

## 二、`pd.merge()` — 数据库风格合并

### 2.1 基本语法

```python
pd.merge(left, right, on='键名', how='inner')
```

### 2.2 四种连接方式

```
df1 (键: 1, 2, 3, 4)    df2 (键: 1, 2, 3, 5)

inner (交集):  只保留两边都有的 → 1, 2, 3
left  (左连):  保留左边全部     → 1, 2, 3, 4 (4的右表值为NaN)
right (右连):  保留右边全部     → 1, 2, 3, 5 (5的左表值为NaN)
outer (并集):  保留所有         → 1, 2, 3, 4, 5 (缺失处填NaN)
```

```python
import pandas as pd
import numpy as np

df1 = pd.DataFrame({'key': [1, 2, 3, 4], 'val1': ['a', 'b', 'c', 'd']})
df2 = pd.DataFrame({'key': [1, 2, 3, 5], 'val2': ['w', 'x', 'y', 'z']})

# inner（默认）
pd.merge(df1, df2, on='key')                    # 3行: key=1,2,3

# left
pd.merge(df1, df2, on='key', how='left')        # 4行: key=1,2,3,4 (val2有NaN)

# right
pd.merge(df1, df2, on='key', how='right')       # 4行: key=1,2,3,5 (val1有NaN)

# outer
pd.merge(df1, df2, on='key', how='outer')       # 5行: key=1,2,3,4,5
```

### 2.3 不同列名作连接键：`left_on` / `right_on`

```python
df_a = pd.DataFrame({'id': [1, 2, 3], 'name': ['A', 'B', 'C']})
df_b = pd.DataFrame({'emp_id': [2, 3, 4], 'salary': [100, 200, 300]})

pd.merge(df_a, df_b, left_on='id', right_on='emp_id')
# 结果: id=1 被排除(匹配不上), id=4 被排除(匹配不上)
```

### 2.4 多键合并

```python
pd.merge(left, right, on=['列1', '列2'], how='left')
# 同时按 列1+列2 的组合进行匹配
```

### 2.5 处理重叠列名：`suffixes`

```python
pd.merge(df_x, df_y, on='key', suffixes=['_左', '_右'])
# 当两表有同名非连接键列时，自动加后缀区分
# 默认后缀为 _x 和 _y
```

### 2.6 标记数据来源：`indicator=True`

```python
pd.merge(df1, df2, on='key', how='outer', indicator=True)
# 新增 _merge 列，值为:
#   "left_only"  → 只在左表存在
#   "right_only" → 只在右表存在
#   "both"       → 两边都存在
```

### 2.7 验证关系类型：`validate`

```python
pd.merge(dept, emp, on='dept_id', validate='one_to_many')
# 可选值:
#   'one_to_one'   一对一（每边键都唯一）
#   'one_to_many'  一对多（左唯一，右可重复）
#   'many_to_one'  多对一（左可重复，右唯一）
#   'many_to_many' 多对多（默认不验证）
# 关系不符合时抛出 MergeError
```

### 2.8 常用参数速查

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `on` | 共同的连接键列名 | 两表同名时自动推断 |
| `left_on` / `right_on` | 左/右表各自的连接键 | - |
| `how` | 连接方式 | `'inner'` |
| `suffixes` | 重叠列名的后缀 | `('_x', '_y')` |
| `indicator` | 是否添加来源标记列 | `False` |
| `validate` | 验证关系类型 | 不验证 |
| `copy` | 是否复制数据 | `True` |

---

## 三、`DataFrame.join()` — 基于索引的合并

### 3.1 基本用法

```python
# join 默认基于索引合并（相当于 merge + left_index=True + right_index=True）
result = df_a.join(df_b, lsuffix='_a', rsuffix='_b')
```

### 3.2 与 merge 的等价写法

```python
# 这两种写法完全等价:
df1.join(df2, lsuffix='_x', rsuffix='_y', how='outer')

pd.merge(df1, df2, left_index=True, right_index=True,
         how='outer', suffixes=['_x', '_y'])
```

### 3.3 `on` 参数 — 用列而非索引连接

```python
df_left.join(df_right.set_index('key'), on='key')
# 左表用列 'key'，右表用索引匹配
```

### 3.4 同时 join 多个 DataFrame

```python
df_main.join([df_a, df_b, df_c], lsuffix='')
# 一次性将多个 DataFrame 合并到主表
```

### 3.5 常用参数速查

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `other` | 要合并的另一个 DataFrame（或列表） | 必填 |
| `on` | 左表的连接列名（可选） | 使用索引 |
| `how` | 连接方式 | `'left'` |
| `lsuffix` / `rsuffix` | 重叠列名的左右后缀 | `('','')` |
| `sort` | 是否按结果排序 | `False` |

---

## 四、`pd.concat()` — 沿轴拼接

### 4.1 纵向拼接（axis=0，默认）

```python
pd.concat([df1, df2])               # 保留原索引（可能重复）
pd.concat([df1, df2], ignore_index=True)  # 重置索引为 0,1,2...
```

### 4.2 横向拼接（axis=1）

```python
pd.concat([df1, df2], axis=1)       # 按索引左右对齐
pd.concat([df1, df2], axis=1, join='inner')  # 只保留交集索引
```

### 4.3 `keys` — 创建多级索引

```python
# 纵向拼接时 keys 作为外层标签:
pd.concat([q1, q2], keys=['Q1', 'Q2'])
# 结果 MultiIndex: ('Q1', 0), ('Q1', 1), ..., ('Q2', 0), ...

# 横向拼接时 keys 作为列的外层标签:
pd.concat([s1, s2], axis=1, keys=['A', 'B'])
# 结果列 MultiIndex: ('A', col), ('B', col), ...
```

### 4.4 `join` — 控制对齐方式

```python
pd.concat([df1, df2], axis=1, join='outer')   # 并集（默认），缺失填 NaN
pd.concat([df1, df2], axis=1, join='inner')   # 交集，只保留共同索引
```

### 4.5 `verify_integrity` — 检查重复索引

```python
pd.concat([df1, df2], verify_integrity=True)
# 如果拼接后索引有重复则抛出 ValueError
# 通常配合 ignore_index=True 使用
```

### 4.6 `ignore_index` — 丢弃原索引

```python
pd.concat([df1, df2], ignore_index=True)
# 结果索引从 0 开始连续编号，不管原来索引是什么
```

### 4.7 常用参数速查

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `objs` | 要拼接的对象列表 | 必填 |
| `axis` | 拼接方向（0=纵向，1=横向） | `0` |
| `join` | 对齐方式（'inner'/'outer'） | `'outer'` |
| `keys` | 为各部分添加标签（创建 MultiIndex） | 无 |
| `ignore_index` | 是否重置索引 | `False` |
| `verify_integrity` | 是否检查重复索引 | `False` |
| `sort` | 是否排序非连接轴 | `False` |

---

## 五、`combine_first()` — 缺失值填充合并

### 5.1 核心逻辑

```
调用者 (a.combine_first(b)):
  a 的某个位置不是 NaN → 保留 a 的值
  a 的某个位置是 NaN    → 用 b 对应位置的值填充
```

```python
import numpy as np

a = pd.DataFrame({'X': [1, np.nan, 3], 'Y': [np.nan, 20, np.nan]})
b = pd.DataFrame({'X': [10, 200, 30], 'Y': [100, 2, 300]})

result = a.combine_first(b)

# 结果:
#      X      Y
# 0  1.0  100.0    ← X保留1, Y用100填补
# 1 200.0   20.0    ← X用200填补, Y保留20
# 2  3.0  300.0    ← X保留3, Y用300填补
```

### 5.2 实际应用场景

**场景一：数据补全**

```python
# 主数据有缺失，用备份数据填充
main_data.combine_first(backup_data)
```

**场景二：数据更新**

```python
# 新数据覆盖旧数据的空缺（新数据优先）
new_data.combine_first(old_data)
```

### 5.3 与 `update()` 的区别

| 方法 | 是否原地修改 | 处理方式 |
|------|:-----------:|---------|
| `combine_first()` | 否，返回新对象 | 调用者优先，NaN 用另一侧填充 |
| `update()` | 是，原地修改 | 直接覆盖已有值，不新增行列 |

```python
# combine_first: 返回新 DataFrame
new_df = df1.combine_first(df2)

# update: 原地修改 df1
df1.update(df2)
```

### 5.4 Series 也能用

```python
s1 = pd.Series([1, np.nan, 3], index=['a', 'b', 'c'])
s2 = pd.Series([10, 20, 30], index=['a', 'b', 'c'])

s1.combine_first(s2)
# a    1.0
# b   20.0    ← s1[b]是NaN, 用s2[b]=20
# c    3.0
```

---

## 六、merge vs join vs concat vs combine_first 对比图解

### 场景对比

```
【merge】数据库风格关联
  表A (员工ID, 姓名)  +  表B (员工ID, 薪资)
       ↓ 按 员工ID 匹配
  结果 (员工ID, 姓名, 薪资)


【join】基于索引的合并
  表A (index=姓名, 数学)  +  表B (index=姓名, 英语)
       ↓ 按索引 匹配
  结果 (index=姓名, 数学, 英语)


【concat】简单堆叠
  Q1数据 (月份, 销售额)  +  Q2数据 (月份, 销售额)
       ↓ 上下叠在一起
  结果 (月份, 销售额)  -- 6行数据


【combine_first】缺失值填充
  主数据 (有NaN)  +  备份数据 (完整)
       ↓ NaN处用备份数据填充
  结果 (完整数据)
```

---

## 七、常见坑与注意事项

### 7.1 Pandas 3.0 变化

```python
# ⚠️ groupby(axis=...) 已移除
# 旧版: df.groupby(level='L1', axis='columns').sum()
# 新版: df.T.groupby(level='L1').sum().T
```

### 7.2 索引重复问题

```python
# concat 后索引可能重复
r = pd.concat([df1, df2])  # 索引 0,1,2,0,1,2
# 解决: ignore_index=True 或 reset_index()
```

### 7.3 内存键 vs 列键

```python
# merge 默认找列作为键
pd.merge(df1, df2, on='key')

# 如果要用索引作为键
pd.merge(df1, df2, left_index=True, right_index=True)
# 或者更简洁地用 join
df1.join(df2)
```

### 7.4 合并后的数据类型变化

```python
# 合并可能导致 int 变 float（因为 NaN 只能存在于 float 中）
# 例如 left join 时，无匹配的行会产生 NaN，整列变为 float64
```

### 7.5 大数据量合并的性能建议

```python
# 1. 提前确保连接键的数据类型一致
df1['key'] = df1['key'].astype(str)
df2['key'] = df2['key'].astype(str)

# 2. 合并前先过滤不需要的数据
df1_filtered = df1[df1['date'] > '2024-01-01']

# 3. 对于超大文件，考虑分块处理
for chunk in pd.read_csv('large.csv', chunksize=10000):
    result = pd.merge(chunk, other_df, on='key')
```

---

## 八、速查代码卡

```python
# ====== merge ======
pd.merge(a, b, on='key')                          # inner join
pd.merge(a, b, on='key', how='left')              # left join
pd.merge(a, b, left_on='id', right_on='emp_id')   # 不同列名
pd.merge(a, b, on=['k1', 'k2'])                   # 多键合并
pd.merge(a, b, indicator=True)                    # 标记来源
pd.merge(a, b, validate='one_to_many')            # 验证关系

# ====== join ======
a.join(b, lsuffix='', rsuffix='')                 # 基于索引
a.join(b.set_index('key'), on='key')              # 基于列
a.join([b, c, d])                                 # 多表同时join

# ====== concat ======
pd.concat([a, b])                                 # 纵向拼接
pd.concat([a, b], ignore_index=True)              # 重置索引
pd.concat([a, b], axis=1)                         # 横向拼接
pd.concat([a, b], keys=['A', 'B'])                # 加标签(MultiIndex)
pd.concat([a, b], verify_integrity=True)          # 检查重复索引

# ====== combine_first ======
a.combine_first(b)                                # 用b填充a的NaN
s1.combine_first(s2)                              # Series也支持

# ====== 实用组合 ======
# 分组聚合后转回普通DataFrame
df.groupby('col').agg({...}).reset_index()

# 多表先concat再merge
all_data = pd.concat([df1, df2, df3])
result = pd.merge(all_data, info_df, on='key')

# 缺失值填充链式操作
clean = raw.combine_first(backup).fillna(0).astype(int)
```
