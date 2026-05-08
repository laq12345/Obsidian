---
lang: Python
date: 2026-04-08
tags:
  - 数据分析
---
## Pandas 多级索引（MultiIndex）完整总结

---

### 一、什么是 MultiIndex？

**MultiIndex（多级索引）** 是 Pandas 中用于表示**二维以上维度**的索引结构，让数据可以在行或列方向上有多个层级。

```
普通索引:          多级索引:
Index(['a','b'])  MultiIndex([('X',1), ('X',2), ('Y',1), ('Y',2)])
                    ↑   ↑     ↑   ↑
                   一级 二级  一级 二级
```

---

### 二、创建 MultiIndex

#### 方式一：`pd.MultiIndex.from_arrays()` ⭐ 最常用

```python
import pandas as pd
import numpy as np

# 用多个数组（列表）分别指定每一级的值
index = pd.MultiIndex.from_arrays(
    [['北京', '北京', '上海', '上海'],      # 第一级：城市
     ['2024', '2025', '2024', '2025']],     # 第二级：年份
    names=['城市', '年份']                    # 给每层命名
)

df = pd.DataFrame({'GDP': [4.0, 4.3, 4.5, 4.8], '人口': [2200, 2250, 2500, 2550]},
                 index=index)
print(df)
#              GDP    人口
# 城市 年份               
# 北京 2024   4.0  2200
#      2025   4.3  2250
# 上海 2024   4.5  2500
#      2025   4.8  2550
```

#### 方式二：`pd.MultiIndex.from_tuples()`

```python
# 用元组列表，每个元组是一个索引位置的所有级别值
index = pd.MultiIndex.from_tuples(
    [('A', 1, 'x'), ('A', 1, 'y'), ('A', 2, 'x'), ('B', 1, 'y')],
    names=['一级', '二级', '三级']
)
```

#### 方式三：`pd.MultiIndex.from_product()` ⭐ 笛卡尔积

```python
# 自动生成所有组合（笛卡尔积）
index = pd.MultiIndex.from_product(
    [['北京', '上海'],           # 第一级的所有可能值
     ['Q1', 'Q2', 'Q3', 'Q4']], # 第二级的所有可能值
    names=['城市', '季度']
)
# 结果: 北京Q1, 北京Q2, 北京Q3, 北京Q4, 上海Q1, ..., 上海Q4 (共8行)
```

#### 方式四：创建时直接用 `set_index()`

```python
df = pd.DataFrame({
    '城市': ['北京', '北京', '上海', '上海'],
    '年份': [2024, 2025, 2024, 2025],
    'GDP': [4.0, 4.3, 4.5, 4.8]
})

# 把列变成索引
df_multi = df.set_index(['城市', '年份'])
print(df_multi.index)
# MultiIndex([('北京', 2024), ('北京', 2025), ('上海', 2024), ('上海', 2025)],
#           names=['城市', '年份'])
```

#### 方式五：DataFrame 的列也支持 MultiIndex

```python
# 列的多级索引
arrays = [
    ['数学', '数学', '英语', '英语'],
    ['期中', '期末', '期中', '期末']
]
columns = pd.MultiIndex.from_arrays(arrays, names=['科目', '考试'])

df = pd.DataFrame(
    [[90, 85, 78, 82], [88, 92, 80, 76]],
    index=['张三', '李四'],
    columns=columns
)
print(df)
# 科目  数学       英语      
# 考试  期中 期末  期中 期末
# 张三   90   85   78   82
# 李四   88   92   80   76
```

---

### 三、MultiIndex 的属性

```python
index = df_multi.index

index.levels          # 每一级的唯一值列表 [Index(['北京','上海']), Index([2024,2025])]
index.level_names     # 各级名称 ['城市', '年份']
index.names           # 同上
index.nlevels         # 级数 (2)
index.codes           # 底层整数编码（类似 Categorical）
index.shape           # 总长度 (4,)
index.values          # 显示用的元组数组
```

---

### 四、数据选取（核心重点）

#### 4.1 基础选取 `.loc[]`

```python
df = pd.DataFrame({
    'value': range(6)},
    index=pd.MultiIndex.from_product([['A', 'B', 'C'], [1, 2]], names=['L1', 'L2']))

# ====== 选单个值 ======
df.loc[('A', 1)]        # L1=A 且 L2=1 的行
df.loc['A']             # L1=A 的所有行（返回子 DataFrame）

# ====== 选多行 ======
df.loc[['A', 'B']]      # L1=A 或 B 的所有行
df.loc[('A', [1, 2])]   # L1=A, L2=1 或 2

# ====== 切片 ======
df.loc['A':'B']         # L1 从 A 到 B（按顺序）
df.loc[('A', 1):('B', 1)]  # 从 (A,1) 到 (B,1)

# ====== 条件筛选 ======
df[df['value'] > 2]     # 正常布尔索引仍然可用
```

#### 4.2 `xs()` 方法 — 跨级别选取 ⭐ 非常实用

```python
# xs 可以指定从哪一级选取
df.xs('A', level='L1')              # 等价于 df.loc['A']
df.xs(1, level='L2')                # 所有 L2=1 的行（跨 L1！）

# drop_level=False: 保留被选中的级别
df.xs(1, level='L2', drop_level=False)  # 保留 L2 列
```

#### 4.3 列的多级索引选取

```python
# 选取特定级别的列
df['数学']              # 选取 数学 下的所有子列 → DataFrame
df[('数学', '期中')]    # 选取精确的一列 → Series

# df.loc 对列也可以用多级索引
df.loc[:, '数学']               # 数学下的所有子列
df.loc[:, ('数学', '期中')]     # 精确一列
df.loc[:, ('数学', ['期中', '期末'])]  # 多个子列
```

---

### 五、层级操作

#### 5.1 交换级别 `swaplevel()`

```python
df.swaplevel('城市', '年份')
# 原来: 城市→年份
# 之后: 年份→城市
```

#### 5.2 排序 `sort_index()`

```python
# 按指定级别排序
df.sort_index(level='年份')

# 按多级排序
df.sort_index(level=['城市', '年份'])

# ascending 分别控制每级排序方向
df.sort_index(level=['城市', '年份'], ascending=[True, False])
```

#### 5.3 堆叠/展开 `stack()` / `unstack()` ⭐ 核心方法

```python
df = pd.DataFrame({
    '城市': ['北京', '北京', '上海', '上海'],
    '年份': [2024, 2025, 2024, 2025],
    'GDP': [4.0, 4.3, 4.5, 4.8]
}).set_index(['城市', '年份'])

# stack(): 将列压入索引（增加一个索引级别）
# unstack(): 将索引级别提升为列（减少一个索引级别）
```

**图解 `unstack()`:**

```
unstack 前 (两级索引):
            GDP
城市 年份          
北京 2024   4.0
    2025   4.3
上海 2024   4.5
    2025   4.8

unstack(默认最内层='年份'):
年份    2024  2025
城市            
北京     4.0   4.3
上海     4.5   4.8

unstack(level='城市'):
城市     北京   上海
年份              
2024     4.0   4.5
2025     4.3   4.8
```

```python
df.unstack()             # 默认把最内层索引变列
df.unstack(level='年份')  # 指定把哪一层变列
df.unstack(fill_value=0)  # 缺失值填充为 0

# stack(): 反向操作，列变索引
df.unstack().stack()      # 还原回原来的形状
```

#### 5.4 重命名级别

```python
# 重命名级别名
df.index.set_names(['省', '市'], inplace=True)

# 或者 rename_axis
df.rename_axis(index=['省份', '城市'], columns=['科目', '类型'])
```

---

### 六、聚合与分组

#### 6.1 按级别聚合

```python
# 按某一级 groupby + agg
df.groupby(level='城市').sum()
df.groupby(level='年份').mean()

# 多级 groupby
df.groupby(level=['城市', '年份']).agg({'GDP': ['sum', 'mean']})
```

> ⚠️ **Pandas 3.0 注意：** `groupby(axis='columns')` 已移除，需要用 `.T` 转置替代：
> ```python
> # 旧版: df.groupby(level='color', axis='columns').sum()
> # 新版: df.T.groupby(level='color').sum().T
> ```

#### 6.2 `pivot_table()` — 自动生成 MultiIndex

```python
df = pd.DataFrame({
    '城市': ['北京', '北京', '上海', '上海', '广州', '广州'],
    '年份': [2024, 2025, 2024, 2025, 2024, 2025],
    '季度': ['Q1', 'Q2', 'Q1', 'Q2', 'Q1', 'Q2'],
    '销售额': [100, 120, 90, 110, 70, 85]
})

# pivot_table 自动生成行列多级索引
pt = df.pivot_table(
    values='销售额',
    index='城市',        # 行索引
    columns=['年份', '季度'],  # 列多级索引
    aggfunc='sum'
)
print(pt)
# 年份    2024       2025    
# 季度    Q1  Q2    Q1   Q2
# 城市                       
# 广州     70 NaN    85 NaN
# 上海     90  95   NaN  110
# 北京    100 120   NaN NaN
```

---

### 七、实际应用场景

#### 场景 A：时间序列多粒度分析

```python
dates = pd.date_range('2024-01-01', periods=12, freq='ME')
df = pd.DataFrame({
    '日期': dates,
    '销售额': np.random.randint(50, 200, size=12),
    '区域': ['北区']*6 + ['南区']*6
})
df['年'] = df['日期'].dt.year
df['月'] = df['日期'].dt.month
df['季度'] = df['日期'].dt.quarter

# 多级索引便于按不同粒度分析
indexed = df.set_index(['区域', '年', '季度', '月'])

# 按区域看总额
indexed.groupby(level='区域')['销售额'].sum()

# 按区域+季度看
indexed.groupby(level=['区域', '季度'])['销售额'].sum()

# unstack 变成透视表
indexed.groupby(['区域', '季度'])['销售额'].sum().unstack()
```

#### 场景 B：实验数据多条件记录

```python
data = []
for exp in ['exp_A', 'exp_B']:
    for cond in ['control', 'treatment']:
        for rep in range(3):
            data.append({
                '实验': exp,
                '条件': cond,
                '重复': rep+1,
                '结果': np.random.normal(loc=100 if cond=='treatment' else 80, scale=10)
            })

df = pd.DataFrame(data).set_index(['实验', '条件', '重复'])
print(df.unstack(level='条件'))  # 实验结果对比表
```

---

### 八、常见坑与注意事项

| 坑 | 说明 |
|------|------|
| 未排序的 MultiIndex | 某些操作要求索引已排序，先 `sort_index()` |
| `groupby(axis=...)` | Pandas 3.0 已移除，用 `.T` 替代 |
| `xs()` vs `loc[]` | `xs()` 可跨级别选，`loc[]` 更直观但需写全 |
| `unstack()` 产生 NaN | 组合不完整时会出 NaN，用 `fill_value` 处理 |
| 层级名称重复 | 不同级别不能用相同名字 |

```python
# 坑示例：未排序导致的问题
idx = pd.MultiIndex.from_tuples([('B', 1), ('A', 2)])
df = pd.DataFrame({'v': [1, 2]}, index=idx)

# 这可能报错或行为异常
df.loc['A':'B']  # ❌ 索引未排序！

# 解决
df = df.sort_index()
df.loc['A':'B']  # ✅ 正常工作
```

---

### 九、速查代码卡

```python
import pandas as pd
import numpy as np

# ====== 创建 ======
pd.MultiIndex.from_arrays([[...], [...]], names=[...])     # 最常用
pd.MultiIndex.from_tuples([...], names=[...])              # 元组列表
pd.MultiIndex.from_product([[...], [...]], names=[...])     # 笛卡尔积
df.set_index(['col1', 'col2'])                              # 从列创建

# ====== 属性 ======
index.levels          # 每级唯一值
index.names           # 级别名称
index.nlevels         # 级别数量

# ====== 选取 ======
df.loc[('L1val', 'L2val')]   # 精确选取
df.loc['L1val']              # 选取第一级的所有
df.xs(val, level='name')     # 跨级别选取 ⭐
df.xs(val, level='name', drop_level=False)  # 保留该级

# ====== 层级操作 ======
df.swaplevel('L1', 'L2')     # 交换级别
df.sort_index(level='L1')     # 按级别排序
df.unstack(level='L2')        # 索引级别 → 列 ⭐
df.stack()                    # 列 → 索引级别
df.rename_axis(...)           # 重命名级别

# ====== 聚合 ======
df.groupby(level='L1').sum()  # 按级别聚合
df.pivot_table(...)           # 透视表自动生成 MultiIndex

# ====== 注意 (Pandas 3.0) ======
# df.groupby(..., axis='columns')  ❌ 改用 .T
# df.fillna(method='ffill')        ❌ 改用 ffill()
```