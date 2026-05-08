---
lang: Python
date: 2026-04-07
tags:
  - 数据分析
---
## Pandas Categorical（分类类型）完整总结

### 一、什么是 Categorical？

**Categorical** 是 Pandas 的一种**特殊数据类型**，用于存储**具有有限个离散值**的数据（如性别、等级、星期等）。

```python
import pandas as pd
import numpy as np

# 普通字符串类型（每个值都存一份完整的字符串）
s = pd.Series(['low', 'high', 'medium', 'high', 'low'])
print(s.dtype)  # object 或 string

# 分类类型（只存一次类别名 + 每个值的整数索引）
s_cat = pd.Categorical(s)
# 或者
s_cat = pd.Series(s, dtype='category')
```

---

### 二、为什么要用 Categorical？三大优势

| 优势 | 说明 | 示例 |
|------|------|------|
| **节省内存** | 只存整数索引 + 类别表 | 100万行数据可减少 **70-90% 内存** |
| **提升性能** | 分组/排序操作更快 | groupby 可快 **10-100 倍** |
| **语义明确** | 表达"有序"或"无序"的类别 | `low < medium < high` |

---

### 三、创建 Categorical

#### 方式一：直接创建

```python
# 创建无序分类
cat = pd.Categorical(['a', 'b', 'a', 'c', 'b'])
print(cat)
# ['a', 'b', 'a', 'c', 'b']
# Categories (3, object): ['a', 'b', 'c']

# 创建有序分类 ⭐
cat = pd.Categorical(
    ['low', 'high', 'medium', 'high'],
    categories=['low', 'medium', 'high'],   # 指定所有可能的类别
    ordered=True                              # 标记为有序
)
print(cat)
# ['low', 'high', 'medium', 'high']
# Categories (3, object): ['low' < 'medium' < 'high']  ← 注意 < 符号！
```

#### 方式二：从 Series 创建

```python
s = pd.Series(['M', 'F', 'M', 'F', 'M'])

# 转为 category 类型
s = s.astype('category')
print(s.dtype)       # category

# 指定类别顺序
s = pd.Series(
    pd.Categorical(
        ['M', 'F', 'M'],
        categories=['F', 'M'],
        ordered=False
    )
)

# 链式写法
s = pd.Series(['a','b','a']).astype(
    pd.CategoricalDtype(categories=['a','b','c'], ordered=True)
)
```

#### 方式三：用 `pd.cut()` / `pd.qcut()` 自动生成

```python
ages = [15, 25, 35, 45, 55, 65]

# cut 自动返回 Categorical
bins = pd.cut(ages, bins=[0, 18, 35, 60, 100],
              labels=['青少年', '青年', '中年', '老年'])
print(bins)
# [青少年, 青年, 青年, 中年, 中年, 老年]
# Categories (4, object): ['青少年' < '青年' < '中年' < '老年']
print(type(bins))     # <class 'pandas.core.arrays.categorical.Categorical'>
```

---

### 四、核心属性

```python
cat = pd.Categorical(
    ['low', 'high', 'medium', 'high'],
    categories=['low', 'medium', 'high'],
    ordered=True
)

# ====== 查看属性 ======
cat.categories           # Index(['low', 'medium', 'high']) → 所有类别
cat.codes                # array([0, 2, 1, 2])            → 底层整数编码
cat.ordered              # True                          # 是否有序
len(cat.categories)      # 3                             # 类别数量
cat.dtype                # CategoricalDtype(categories=..., ordered=True)

# ====== 理解底层结构 ======
# 实际存储:
#   categories: ['low', 'medium', 'high']  （存一次）
#   codes:      [0, 2, 1, 2]               （每行一个整数）
#   显示时:    codes[i] → categories[codes[i]]
```

---

### 五、常用操作

#### 5.1 重命名类别

```python
cat = pd.Categorical(['a', 'b', 'a'])

# 方法一：rename_categories
cat.rename_categories({'a': 'A', 'b': 'B'})
# ['A', 'B', 'A']

# 方法二：列表映射（按位置）
cat.rename_categories(['alpha', 'beta'])
# ['alpha', 'beta', 'alpha']
```

#### 5.2 添加 / 删除未使用的类别

```python
cat = pd.Categorical(['a', 'b', 'a'], categories=['a', 'b', 'c'])

# 添加新类别（不影响现有数据）
cat = cat.add_categories('d')
# categories: ['a', 'b', 'c', 'd']

# 删除未使用的类别
cat = cat.remove_unused_categories()
# 如果数据中没有 'c' 和 'd'，则删除它们

# 设置新的类别集合（会重新编码）
cat = cat.set_categories(['a', 'x', 'y'])
# 原来的 'b' 会变成 NaN（因为不在新类别中）
```

#### 5.3 排序（有序分类的核心优势）

```python
# 无序分类 → 排序按字母顺序
cat_unordered = pd.Categorical(['high', 'low', 'medium'])
pd.Series(cat_unordered).sort_values()
# high    → 排在前面（h 在 l 前面）

# 有序排序 → 按定义的顺序排！⭐
cat_ordered = pd.Categorical(
    ['high', 'low', 'medium', 'high'],
    categories=['low', 'medium', 'high'],
    ordered=True
)
s = pd.Series(cat_ordered)
s.sort_values()
# low      ← 最小，排在最前
# medium
# high
# high     ← 最大，排在最后
```

#### 5.4 比较（只有有序分类才能比较大小）

```python
cat = pd.Categorical(
    ['low', 'high', 'medium'],
    categories=['low', 'medium', 'high'],
    ordered=True
)

# 有序分类可以比较大小 ⭐
cat > 'medium'
# array([False, True, False])

cat <= 'medium'
# array([True, False, True])

# 无序分类不能比较大小 ❌
cat_unordered = pd.Categorical(['low', 'high'], ordered=False)
cat_unordered > 'medium'    # TypeError!
```

---

### 六、实际应用场景

#### 场景 A：节省内存

```python
import numpy as np

# 模拟大数据
n = 1_000_000
cities = np.random.choice(['北京', '上海', '广州', '深圳', '杭州'], size=n)

# 字符串版本
df_str = pd.DataFrame({'city': cities})
print(f"object 类型内存: {df_str.memory_usage(deep=True)['city'] / 1024 / 1024:.2f} MB")
# 约 45 MB

# 分类版本
df_cat = df_str.astype('category')
print(f"category 类型内存: {df_cat.memory_usage(deep=True)['city'] / 1024 / 1024:.2f} MB")
# 约 1 MB  ← 节省了 98%！
```

#### 场景 B：有序数据的正确处理

```python
df = pd.DataFrame({
    'rating': pd.Categorical(
        ['差', '优', '中', '良', '优', '中', '差'],
        categories=['差', '中', '良', '优'],
        ordered=True
    ),
    'sales': [100, 500, 300, 450, 520, 280, 90]
})

# 按自定义顺序排序 ✅
df.sort_values('rating')
# rating  sales
# 差       100
# 差        90
# 中       300
# 中       280
# 良       450
# 优       500
# 优       520

# 按条件筛选 ✅
df[df['rating'] >= '良']
# rating  sales
# 良       450
# 优       500
# 优       520

# groupby 统计
df.groupby('rating')['sales'].mean()
# rating
# 差      95.0
# 中     290.0
# 良     450.0
# 优     510.0
# Name: sales, dtype: float64
```

#### 场景 C：固定类别的调查问卷数据

```python
# 问卷调查：满意度 1-5 分
survey = pd.DataFrame({
    '满意度': pd.Categorical(
        [5, 4, 3, 5, 2, 4, 1, 5, 3, 4],
        categories=[1, 2, 3, 4, 5],
        ordered=True
    ),
    '年龄组': pd.Categorical(
        ['青年', '中年', '青年', '老年', '青年', '中年', '青年', '老年', '中年', '青年'],
        categories=['青年', '中年', '老年'],
        ordered=False
    )
})

# 统计各等级人数
survey['满意度'].value_counts().sort_index()  # 按 1→5 顺序显示
# 5    3
# 4    3
# 3    2
# 2    1
# 1    1

# 交叉分析
pd.crosstab(survey['年龄组'], survey['满意度'])
```

---

### 七、CategoricalDtype（Pandas 扩展类型）

```python
from pandas.api.types import CategoricalDtype

# 定义一个可复用的分类类型
size_type = CategoricalDtype(
    categories=['S', 'M', 'L', 'XL'],
    ordered=True
)

# 多处使用同一类型定义
df['shirt_size'] = df['shirt_size'].astype(size_type)
df['pants_size'] = df['pants_size'].astype(size_type)

# 检查是否为分类类型
from pandas.api.types import is_categorical_dtype
is_categorical_dtype(df['shirt_size'])   # True
```

---

### 八、注意事项 & 常见坑

```python
# ====== 坑 1：赋值不存在的值会变 NaN ======
cat = pd.Categorical(['a', 'b'], categories=['a', 'b', 'c'])
cat[1] = 'd'          # 不报错，但变成 NaN！

# 解决：先添加类别再赋值
cat = cat.add_categories('d')
cat[1] = 'd'          # ✅ 正常

# ====== 坑 2：合并不同类别集的 Series ======
s1 = pd.Series(pd.Categorical(['a', 'b'], categories=['a', 'b']))
s2 = pd.Series(pd.Categorical(['b', 'c'], categories=['b', 'c']))

pd.concat([s1, s2])
# 结果的 categories 是两者的并集: ['a', 'b', 'c']

# ====== 坑 3：转回普通类型 ======
s = pd.Series(pd.Categorical([1, 2, 1]))
s.astype(int)         # ✅ 转为整数
s.astype(str)         # ✅ 转为字符串
s.tolist()            # ✅ 转 Python 列表
```

---

### 九、速查代码卡

```python
import pandas as pd
import numpy as np

# ====== 创建 ======
pd.Categorical(['a', 'b', 'a'])                    # 无序
pd.Categorical(['a', 'b'], ordered=True)            # 有序
pd.CategoricalDtype([...], ordered=True)             # 类型定义
s.astype('category')                                 # Series 转分类
pd.cut(data, bins, labels)                           # 分箱自动生成分类

# ====== 属性 ======
cat.categories    # 类别列表
cat.codes         # 整数编码
cat.ordered       # 是否有序

# ====== 操作 ======
cat.rename_categories({...})    # 重命名
cat.add_categories('x')        # 添加类别
cat.remove_unused_categories()  # 删除未使用类别
cat.set_categories([...])       # 重新设置类别
cat.as_ordered()                # 变为有序
cat.as_unordered()              # 变为无序

# ====== 使用场景 ======
# 节省内存（重复值多的列）
# 自定义排序顺序（如：差<中<良<优）
# 固定选项的调查数据（如：性别、血型、评级）
```

---

### 十、一句话总结

> **Categorical = 用整数索引 + 类别表 来代替重复存储字符串。** 适合"取值范围有限且大量重复"的列，能省内存、加速运算、还能表达语义顺序。


## 表 7.7：Pandas 中 Series 的 Categorical 方法

| 方法 | 描述 |
|------|------|
| **add_categories** | 在现有类别**末尾追加**新的（未使用的）类别 |
| **as_ordered** | 将类别设为**有序**（ordered） |
| **as_unordered** | 将类别设为**无序**（unordered） |
| **remove_categories** | **移除指定类别**，被移除类别的值变为 `null`（空值/缺失值） |
| **remove_unused_categories** | 移除**数据中未出现**的任何类别值 |
| **rename_categories** | 用指定的新名称**替换**类别；**不能改变类别的数量** |
| **reorder_categories** | 行为类似 `rename_categories`，但**还可以将结果设置为有序类别**（可同时调整顺序和设置有序性） |
| **set_categories** | 用指定的新类别集合**替换**原类别；可以**添加或删除**类别 |

---

### 快速对比记忆

```python
import pandas as pd

cat = pd.Categorical(['a', 'b', 'a'], categories=['a', 'b', 'c'])

# ====== 增 ======
cat.add_categories('d')              # 追加新类别 → ['a','b','c','d']

# ====== 删 ======
cat.remove_categories('c')           # 删除指定类别，c 的值变 NaN
cat.remove_unused_categories()       # 删除没出现过的类别（如 c）

# ====== 改 ======
cat.rename_categories({'a': 'A'})    # 重命名（不能增减数量）
cat.set_categories(['a', 'x'])       # 替换整个类别集（可增可删，不在新集中的值变 NaN）
cat.reorder_categories(['c','a','b'], ordered=True)  # 调整顺序 + 设为有序

# ====== 序 ======
cat.as_ordered()                     # 变为有序
cat.as_unordered()                   # 变为无序
```

### 关键区别速查

| 方法 | 能否改类别名？ | 能否增删类别？ | 能否改变顺序？ | 能否设为有序？ |
|------|:---:|:---:|:---:|:---:|
| `add_categories` | ❌ | ➕ 只能加 | ❌ | ❌ |
| `remove_categories` | ❌ | ➖ 只能删指定 | ❌ | ❌ |
| `remove_unused_categories` | ❌ | ➖ 自动删无用 | ❌ | ❌ |
| `rename_categories` | ✅ | ❌ | ✅（隐式） | ❌ |
| `reorder_categories` | ✅ | ❌ | ✅ 显式 | ✅ |
| `set_categories` | ✅（整体替换） | ✅ 可增可删 | ✅ | ❌ |
| `as_ordered` / `as_unordered` | ❌ | ❌ | ❌ | ✅ |