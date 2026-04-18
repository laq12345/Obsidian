---
lang: Python
date: 2026-04-06
tags:
  - 数据分析
---
导入规范：
```python
In [1]: import numpy as np

In [2]: import pandas as pd

In [3]: from pandas import Series, DataFrame
```

|类型|说明|
|:--|:--|
|2D ndarray|数据矩阵，传递可选的行和列标签|
|数组、列表或元组的字典|每个序列成为 DataFrame 中的一列；所有序列必须长度相同|
|NumPy 结构化/记录数组|被视为“数组字典”的情况处理|
|Series 的字典|每个值成为一列；如果没有传递显式索引，则每个 Series 的索引会联合在一起形成结果的行索引|
|字典的字典|每个内部字典成为一列；键会像“Series 字典”的情况一样联合形成行索引|
|字典或 Series 的列表|每个项目成为 DataFrame 中的一行；字典键或 Series 索引的并集成为 DataFrame 的列标签|
|列表或元组的列表|被视为“2D ndarray”的情况处理|
|另一个 DataFrame|使用 DataFrame 的索引，除非传递了不同的索引|
|NumPy MaskedArray|类似于“2D ndarray”的情况，只是被掩码的值在 DataFrame 结果中是缺失的|
DataFrame构造函数可能的数据输入

|方法/属性|描述|
|:--|:--|
|`append()`|与额外的 Index 对象连接，生成一个新的 Index|
|`difference()`|计算集差（作为 Index）|
|`intersection()`|计算集交集|
|`union()`|计算集并集|
|`isin()`|计算布尔数组，指示每个值是否包含在传入的集合中|
|`delete()`|计算一个新的 Index，其中删除了索引 `i` 处的元素|
|`drop()`|通过删除传入的值计算一个新的 Index|
|`insert()`|通过在索引 `i` 处插入元素计算一个新的 Index|
|`is_monotonic`|如果每个元素都大于或等于前一个元素，则返回 `True`|
|`is_unique`|如果 Index 没有重复值，则返回 `True`|
|`unique()`|计算 Index 中唯一值的数组|
部分Index方法和属性

|参数|描述|
|:--|:--|
|`labels`|用作索引的新序列。可以是 Index 实例或任何其他类似序列的 Python 数据结构。Index 将被直接使用，不进行任何复制。|
|`index`|将传入的序列用作新的索引标签。|
|`columns`|将传入的序列用作新的列标签。|
|`axis`|要重新索引的轴，可以是 `"index"`（行）或 `"columns"`。默认为 `"index"`。您也可以交替使用 `reindex(index=new_labels)` 或 `reindex(columns=new_labels)`。|
|`method`|插值（填充）方法；`"ffill"` 向前填充，而 `"bfill"` 向后填充。|
|`fill_value`|在通过重新索引引入缺失数据时使用的替代值。当您希望结果中缺失的标签具有空值时，使用 `fill_value="missing"`（默认行为）。|
|`limit`|在向前填充或向后填充时，要填充的最大间隙大小（以元素数量计）。|
|`tolerance`|在向前填充或向后填充时，对于不精确匹配要填充的最大间隙大小（以绝对数值距离计）。|
|`level`|在 MultiIndex 的某一层级上匹配简单 Index；否则选择子集。|
|`copy`|如果为 `True`，即使新索引等同于旧索引，也总是复制底层数据；如果为 `False`，当索引等同时则不复制数据。|
reindex函数参数

## drop
`drop()` 方法是 Pandas 中用于删除 `DataFrame` 或 `Series` 中指定行或列的常用工具。其核心特点是**默认不修改原始数据**，而是返回一个删除指定标签后的新对象。

### 📖 核心语法与参数

`drop()` 方法的基本语法结构如下：

`DataFrame.drop(labels=None, axis=0, index=None, columns=None, inplace=False, errors='raise')`

以下是几个关键参数的说明：

- **`labels`**: 指定要删除的行索引标签或列名。可以是单个标签，也可以是标签列表。
- **`axis`**: 指定删除的方向。`axis=0` (默认) 表示按行索引删除；`axis=1` 表示按列名删除。
- **`index` / `columns`**: 这两个参数是 `axis` 参数的替代写法，可以更直观地指定要删除的行 (`index`) 或列 (`columns`)。
- **`inplace`**: 如果设置为 `True`，则直接在原始数据上进行修改，不返回新对象。默认为 `False`。
- **`errors`**: 当要删除的标签在数据中不存在时的处理方式。`'raise'` (默认) 会引发 `KeyError` 错误；`'ignore'` 则会忽略不存在的标签。

### 💡 基本用法示例

#### 删除列

删除列是 `drop()` 最常见的使用场景之一。

```python
import pandas as pd

# 创建一个示例 DataFrame
df = pd.DataFrame({
    'A': [1, 2, 3],
    'B': [4, 5, 6],
    'C': [7, 8, 9]
})

# 方法一：使用 labels 和 axis 参数
df_new = df.drop(labels='B', axis=1)

# 方法二：使用 columns 参数（更推荐）
df_new = df.drop(columns='B')

# 同时删除多列
df_new = df.drop(columns=['B', 'C'])
```

#### 删除行

删除行通常基于行的索引标签。

```python
# 假设 DataFrame 的索引是默认的 0, 1, 2
# 方法一：使用 labels 参数（默认 axis=0）
df_new = df.drop(labels=0)

# 方法二：使用 index 参数（更推荐）
df_new = df.drop(index=0)

# 同时删除多行
df_new = df.drop(index=[0, 1])
```

#### 原地修改 (inplace)

如果希望直接修改原始 `DataFrame` 而不是创建新对象，可以使用 `inplace=True`。

```python
# 这会直接修改 df，df 本身会发生变化，方法返回值为 None
df.drop(columns='B', inplace=True)
```

### ⚠️ 常见错误与注意事项

- **标签不存在**: 如果尝试删除一个不存在的列名或行索引，默认会报 `KeyError`。如果希望忽略这种错误，可以设置 `errors='ignore'`。
- **链式操作**: 由于 `drop()` 默认返回新对象，因此它非常适合链式操作。例如：`df.drop(columns='A').drop(index=0)`。
- **inplace 的使用**: 虽然 `inplace=True` 可以节省内存，但在进行复杂的数据处理流程时，不推荐使用，因为它会使代码的调试和回溯变得困难。通常更推荐将结果赋值给一个新变量。

DataFrame的索引选项

|类型|说明|
|:--|:--|
|`df[column]`|从 DataFrame 中选择单列或列序列；特殊情况的便捷用法：布尔数组（过滤行）、切片（切片行）或布尔 DataFrame（根据某些条件设置值）|
|`df.loc[rows]`|通过标签从 DataFrame 中选择单行或行子集|
|`df.loc[:, cols]`|通过标签选择单列或列子集|
|`df.loc[rows, cols]`|通过标签同时选择行和列|
|`df.iloc[rows]`|通过整数位置从 DataFrame 中选择单行或行子集|
|`df.iloc[:, cols]`|通过整数位置选择单列或列子集|
|`df.iloc[rows, cols]`|通过整数位置同时选择行和列|
|`df.at[row, col]`|通过行和列标签选择单个标量值|
|`df.iat[row, col]`|通过行和列位置（整数）选择单个标量值|
|`reindex` 方法|通过标签选择行或列|
DataFrame的索引选项

## 算术与数据对齐

## 带填充值的算术方法

|方法|描述|
|:--|:--|
|`add`, `radd`|加法运算方法 (+)|
|`sub`, `rsub`|减法运算方法 (-)|
|`div`, `rdiv`|除法运算方法 (/)|
|`floordiv`, `rfloordiv`|地板除（整除）运算方法 (//)|
|`mul`, `rmul`|乘法运算方法 (*)|
|`pow`, `rpow`|幂运算方法 ()|
灵活的算术方法

## apply

`apply` 方法是 Pandas 中一个非常强大且灵活的工具，它允许你将自定义函数应用到 DataFrame 的行、列或 Series 的每个元素上。

当 Pandas 的内置方法（如 `sum()`, `mean()`）或向量化操作（如 `df['A'] + df['B']`）无法满足你复杂的、个性化的数据处理逻辑时，`apply` 就是你的首选方案。

### 🎯 核心作用

`apply` 的核心作用是作为一个“调度器”，它本身不处理数据，而是将你提供的函数批量地应用到数据上，从而替代显式的 Python 循环，使代码更简洁、更具 Pandas 风格。

### 📚 基本语法

`apply` 方法既可以用于 DataFrame，也可以用于 Series。

- **DataFrame.apply(func, axis=0, raw=False, result_type=None, args=(), ...)**
- **Series.apply(func, args=(), ...)**

**关键参数说明：**

- **`func`**: 要应用的函数。可以是 Python 内置函数、自定义函数或 `lambda` 匿名函数。
- **`axis`**: 控制应用函数的方向，这是最常用的参数。
    - `axis=0` (默认): 将函数应用到**每一列**。函数接收的参数是代表一列的 Series。
    - `axis=1`: 将函数应用到**每一行**。函数接收的参数是代表一行的 Series。
- **`args`**: 用于向 `func` 传递额外的位置参数。
- **`raw`**: 设置为 `True` 时，会将行或列作为 NumPy 数组而非 Pandas Series 传递给函数，这在某些情况下可以提高性能。
- **`result_type`**: 当 `axis=1` 时，用于控制结果的格式，例如 `'expand'` 可以将返回列表展开为多列。

### 🛠️ 常见用法与示例

#### 1. 对 Series 应用函数

这是最简单的用法，函数会作用于 Series 的每一个元素。

```python
import pandas as pd

s = pd.Series()
# 使用 lambda 函数将每个元素平方
result = s.apply(lambda x: x**2)
print(result)
# 输出: 0     1
#       1     4
#       2     9
#       3    16
#       4    25
```

#### 2. 对 DataFrame 按列应用函数 (axis=0)

默认情况下，`apply` 会沿着列的方向操作，常用于聚合计算。

```python
df = pd.DataFrame({
    'A': ,
    'B': 
})

# 计算每列的和
column_sums = df.apply(lambda col: col.sum())
print(column_sums)
# 输出: A    10
#       B    100
```

#### 3. 对 DataFrame 按行应用函数 (axis=1)

当你需要根据一行中多个列的值来计算一个新值时，这个功能非常有用。

```python
# 基于 'A' 和 'B' 列计算新值
def custom_calc(row):
    return row['A'] * 10 + row['B']

df['C'] = df.apply(custom_calc, axis=1)
print(df)
# 输出:    A   B   C
#       0  1  10  20
#       1  2  20  40
#       2  3  30  60
#       3  4  40  80
```

#### 4. 展开列表结果 (result_type='expand')

如果应用的函数返回一个列表，可以使用 `result_type='expand'` 将其展开成多个新列。

```python
# 返回一个包含两个值的列表
df_new = df.apply(lambda row: [row['A'] + row['B'], row['A'] - row['B']], axis=1, result_type='expand')
df_new.columns = ['Sum', 'Diff'] # 为新列命名
print(df_new)
# 输出:    Sum  Diff
#       0   11    -9
#       1   22   -18
#       2   33   -27
#       3   44   -36
```

### ⚠️ 性能考虑

虽然 `apply` 非常方便，但需要注意其性能问题：

- **本质是循环**：`apply` 并不是真正的向量化操作。特别是在使用 `axis=1` 时，它本质上是在 Python 层面进行循环，处理大型数据集时可能会比较慢。
- **优先使用向量化**：对于简单的操作，应始终优先使用 Pandas 的内置方法或向量化运算，因为它们由高效的 C 代码实现，速度更快。

**性能对比示例：**

```python
# ✅ 推荐：向量化操作，速度快
df['RunDiff'] = df['RunsScored'] - df['RunsAllowed']

# ⚠️ 备选：apply 操作，在逻辑复杂时使用，速度较慢
def compute_diff(row):
    return row['RunsScored'] - row['RunsAllowed']
df['RunDiff'] = df.apply(compute_diff, axis=1)
```

总而言之，`apply` 是处理复杂、非标准化数据转换的强大工具，但在使用时应权衡其灵活性与性能开销。

## 排序与排名

这两个方法是 Pandas 数据整理中最基础也最常用的工具。简单来说，**`sort_index()` 是“按位置/标签排座次”，而 `sort_values()` 是“按实力/数值排座次”**。

为了帮你更好地记笔记，我将它们的核心区别、常用参数和代码示例整理成了结构化的总结：

### ⚔️ 核心区别速览

|特性|**`sort_index()`**|**`sort_values()`**|
|:--|:--|:--|
|**排序依据**|**索引** (行名) 或 **列名**|**具体的数值** (某一行或某一列的内容)|
|**核心参数**|`axis` (轴向), `level` (多级索引)|`by` (指定列/行), `ascending` (升降序)|
|**应用场景**|恢复数据原始顺序、按时间序列索引排序、按字母顺序排列列|找最大值/最小值、排行榜、多条件筛选（如先按班级再按分数）|

---

### 1. sort_index()：按索引排序

顾名思义，它是根据 DataFrame 的**行索引**（index）或**列索引**（columns）进行排序。

- **默认行为**：按行索引（axis=0）升序排列。
- **常用场景**：
    - 数据被打乱后，想恢复成导入时的顺序（如果索引是连续的）。
    - 时间序列数据，索引是日期，需要按时间先后排列。
    - 列名乱序，想要按字母顺序整理列。

**代码笔记：**

```python
import pandas as pd

df = pd.DataFrame({'A': , 'B': }, index=['b', 'a'])

# 1. 按行索引排序 (默认升序)
df.sort_index() 
# 结果: 索引变为 a, b

# 2. 按列名排序 (axis=1)
df.sort_index(axis=1, ascending=False) 
# 结果: 列顺序变为 B, A (降序)
```

---

### 2. sort_values()：按数值排序

这是数据分析中最常用的方法，根据**某一列或多列**的具体数值大小进行排序。

- **核心参数 `by`**：必须指定，告诉 Pandas 依据哪一列（或哪一行）来排。
- **核心参数 `ascending`**：
    - `True` (默认)：升序（从小到大）。
    - `False`：降序（从大到小）。
- **多列排序（重点）**：
    - 可以传入列表，例如 `by=['班级', '分数']`。
    - 逻辑：先按“班级”排，班级相同的，再按“分数”排。

**代码笔记：**

```python
df = pd.DataFrame({
    '姓名': ['张三', '李四', '王五'],
    '部门': ['A', 'B', 'A'],
    '工资': 
})

# 1. 单列排序：按工资降序
df.sort_values(by='工资', ascending=False)

# 2. 多列排序：先按部门升序，部门相同再按工资降序
df.sort_values(by=['部门', '工资'], ascending=[True, False])
```

---

### 💡 避坑指南（通用参数）

在做笔记时，这两个参数对于两个方法都适用，非常重要：

1. **`inplace=True`**：
    - 默认是 `False`，意味着排序后会返回一个新的 DataFrame，原数据不变。
    - 如果设置 `True`，则**直接修改原数据**，不返回新对象（省内存，但不可逆）。
2. **`na_position`**：
    - 处理缺失值（NaN）。默认是 `'last'`（排在最后），可以设为 `'first'`（排在最前）。

**一句话总结：** 想看谁大谁小、做排行榜，用 **`sort_values`**；想整理表格结构、按标签对齐，用 **`sort_index`**。

---

Pandas 中的 `rank()` 方法是用于计算数据排名的强大工具。与 `sort_values()` 等方法不同，它**不改变数据的原始顺序**，而是返回一个与原始数据形状相同的 Series 或 DataFrame，其中的值被替换为它们在排序后所处的**排名**。

这个方法在处理重复值（即“平局”）时提供了多种灵活的策略，使其能够适应不同的排名规则。

### 🎯 核心作用

`rank()` 方法的核心作用是为数据中的每个元素分配一个表示其相对大小的排名值。它常用于：

- 计算考试成绩、销售业绩等的排名。
- 识别数据中的异常值（排名最高或最低的值）。
- 进行统计分析和数据比较。

### 📚 基本语法与关键参数

`Series.rank()` 和 `DataFrame.rank()` 的用法类似，以下是其关键参数：

- **`method`**: 指定处理相同值（平局）的策略。这是 `rank()` 方法最核心和灵活的参数。
- **`ascending`**: 指定排名顺序。`True`（默认）为升序（值越小排名越靠前），`False` 为降序（值越大排名越靠前）。
- **`na_option`**: 指定如何处理缺失值（NaN）。`'keep'`（默认）会将 NaN 的排名也设为 NaN，`'top'` 和 `'bottom'` 则分别将 NaN 排在最前或最后。
- **`pct`**: 是否计算百分比排名。`True` 时返回的是排名占总数的百分比，而非具体名次。

### 🧩 `method` 参数详解

`method` 参数决定了当遇到相同数值时，如何分配排名。理解这一点是掌握 `rank()` 的关键。

为了清晰说明，我们以一个学生成绩表为例，假设有两个学生（Bob 和 Charlie）都考了 85 分。

|学生|成绩|
|:--|:--|
|Alice|90|
|Bob|85|
|Charlie|85|
|David|75|

在理想的顺序排名中，Alice 是第 1 名，Bob 是第 2 名，Charlie 是第 3 名，David 是第 4 名。不同的 `method` 策略会基于这个顺序产生不同的结果。

|`method` 值|描述|Bob 和 Charlie 的排名|排名序列特点|
|:--|:--|:--|:--|
|**`'average'`** (默认)|相同值的元素获得它们所占名次的**平均值**。|**3.5** (即 (3+4)/2)|可能出现小数。|
|**`'min'`**|相同值的元素获得它们所占名次中的**最小值**。|**3**|排名可能出现跳跃（如 1, 3, 3, 5）。|
|**`'max'`**|相同值的元素获得它们所占名次中的**最大值**。|**4**|排名可能出现跳跃（如 1, 4, 4, 5）。|
|**`'first'`**|按照元素在数据中**出现的顺序**分配名次。|Bob: **3**, Charlie: **4**|排名是连续的整数，先到先得。|
|**`'dense'`**|与 `'min'` 类似，但排名是**连续**的，不会跳跃。|**3**|排名是连续的整数（如 1, 2, 2, 3）。|

### 🛠️ 常见用法示例

```python
import pandas as pd

# 创建一个示例 DataFrame
df = pd.DataFrame({
    'Name': ['Alice', 'Bob', 'Charlie', 'David'],
    'Score': 
})

# 1. 默认排名 (升序, method='average')
df['Rank_Avg'] = df['Score'].rank()
# 结果: David(1.0), Bob(3.5), Charlie(3.5), Alice(5.0)

# 2. 降序排名 (常用于成绩排名)
df['Rank_Desc'] = df['Score'].rank(ascending=False)
# 结果: Alice(1.0), Bob(2.5), Charlie(2.5), David(4.0)

# 3. 降序 + 密集排名 (无跳跃)
df['Rank_Dense'] = df['Score'].rank(ascending=False, method='dense')
# 结果: Alice(1), Bob(2), Charlie(2), David(3)

# 4. 降序 + 'first' 排名 (按出现顺序)
df['Rank_First'] = df['Score'].rank(ascending=False, method='first')
# 结果: Alice(1), Bob(2), Charlie(3), David(4)
```

总而言之，`rank()` 方法通过其灵活的 `method` 参数，能够精确地实现各种复杂的排名需求，是数据分析中处理序数关系的必备工具。

---
索引的`is_unique`性质可以告诉你其标签是否唯一：
```python
In [260]: obj.index.is_unique
Out[260]: False
```

## 描述性统计的总结与计算

|方法|描述|
|:--|:--|
|`count`|非 NA (非空) 值的数量|
|`describe`|计算一组摘要统计数据|
|`min, max`|计算最小值和最大值|
|`argmin, argmax`|分别计算获得最小值或最大值的索引位置（整数）；不适用于 DataFrame 对象|
|`idxmin, idxmax`|分别计算获得最小值或最大值的索引标签|
|`quantile`|计算样本分位数，范围从 0 到 1（默认值：0.5）|
|`sum`|值的总和|
|`mean`|值的平均数|
|`median`|值的算术中位数（50% 分位数）|
|`mad`|平均绝对偏差（相对于平均值）|
|`prod`|所有值的乘积|
|`var`|值的样本方差|
|`std`|值的样本标准差|
|`skew`|值的样本偏度（三阶矩）|
|`kurt`|值的样本峰度（四阶矩）|
|`cumsum`|值的累积和|
|`cummin, cummax`|分别计算值的累积最小值或最大值|
|`cumprod`|值的累积乘积|
|`diff`|计算一阶算术差分（对时间序列很有用）|
|`pct_change`|计算百分比变化|
描述性统计和摘要统计

|方法|描述|
|:--|:--|
|`axis`|进行归约的轴；"index" 表示 DataFrame 的行，"columns" 表示列|
|`skipna`|排除缺失值；默认为 `True`|
|`level`|如果轴是分层索引（MultiIndex），则按级别分组进行归约|
归约（或聚合）方法的选项

### 相关性与协方差

略

###  Unique, value counts, and set membership methods

|方法|描述|
|:--|:--|
|`isin`|计算一个布尔数组，指示每个 Series 或 DataFrame 的值是否包含在传递的值序列中|
|`get_indexer`|计算数组中每个值在另一个由不同值组成的数组中的整数索引；有助于数据对齐和连接类型的操作|
|`unique`|计算 Series 中的唯一值数组，按观察到的顺序返回|
|`value_counts`|返回一个 Series，以唯一值为索引，频率为值，并按计数降序排列|
 Unique, value counts, and set membership methods