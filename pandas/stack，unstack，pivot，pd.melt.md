---
lang: Python
date: 2026-04-09
tags:
  - 数据分析
---
## Pandas 数据重塑 — 完整总结

---

### 一、核心概念：长格式 vs 宽格式

```
宽格式 (Wide):                    长格式 (Long/Stacked):
         Q1   Q2   Q3   Q4           季度    销售额
北京     100  120  110  130        北京   Q1    100
上海      90  110  100  120        北京   Q2    120
                                 北京   Q3    110
                                 北京   Q4    130
                                 上海   Q1     90
                                 ...
```

**四个方法的核心方向：**

| 方法 | 方向 | 用途 |
|------|------|------|
| `stack()` | **宽→长** | 列 → 索引（增加索引层级） |
| `unstack()` | **长→宽** | 索引 → 列（减少索引层级） |
| `pivot()` | **长→宽** | 指定行列值，创建透视表 |
| `melt()` | **宽→长** | 把多列"融化"成两列（变量+值） |

---

### 二、`stack()` — 列压入索引

**作用：** 将**列**压缩到**索引**中，使 DataFrame 变得更"瘦长"，增加一个索引级别。

#### 基本用法

```python
import pandas as pd
import numpy as np

# 宽格式数据
df = pd.DataFrame({
    '数学': [90, 85, 78],
    '英语': [82, 88, 76],
    '物理': [88, 92, 80]
}, index=['张三', '李四', '王五'])

print('=== 原始（宽格式）===')
print(df)
#      数学  英语  物理
# 张三   90   82   88
# 李四   85   88   92
# 王五   78   76   80

# stack: 列 → 索引的最内层
result = df.stack()
print('\n=== stack 后（长格式）===')
print(result)
# 张三  数学    90
#       英语    82
#       物理    88
# 李四  数学    85
#       英语    88
#       物理    92
# 王五  数学    78
#       英语    76
#       物理    80
# dtype: int64  ← 变成了 Series!
```

#### 图解

```
stack 前:
         数学  英语  物理    ← 列（1级）
张三 ────┬────┬────┬
李四     │    │    │      ← 行索引（1级）
王五     └────┴────┘

stack 后:
              ↓ 列被压入索引
张三  数学 ─── 90       ← 2级索引 (姓名, 科目) → 值
      英语 ─── 82
      物理 ─── 88
李四  数学 ─── 85
      ...
```

#### MultiIndex 的 stack

```python
# 多级列的情况
df_multi = pd.DataFrame({
    ('期中', '数学'): [90, 85],
    ('期中', '英语'): [82, 88],
    ('期末', '数学'): [88, 92],
    ('期末', '英语'): [86, 90]
}, index=['张三', '李四'])

print('=== 多级列 ===')
print(df_multi.columns)
# MultiIndex([('期中', '数学'), ('期中', '英语'), ('期末', '数学'), ('期末', '英语')])

# 默认 stack 最内层（level=-1，即科目）
result1 = df_multi.stack()
print(result1.index.names)
# ['索引', None, 0]  ← 新增了最内层（科目）

# 指定 stack 哪一层
result2 = df_multi.stack(level=0)  # stack "期中/期末"
print(result2.columns)
# ['数学', '英语']  ← 只剩科目作为列
```

#### 参数详解

```python
df.stack(
    level=0,          # 要 stack 的层级（默认-1，即最内层）
    dropna=True,      # 是否丢弃全 NaN 的行（默认 True）
    sort=True,        # 是否对结果排序（默认 True）
    future_stack=False # Pandas 2.1+ 新参数，控制行为兼容性
)

# level 可以是：
# - 整数: 0, 1, -1（从外到内或从内到外）
# - 名称: '期中' / '数学'（层级名称）
# - 列表: [0, 1]（同时 stack 多层）
```

---

### 三、`unstack()` — 索引提升为列

**作用：** 将**索引**展开为**列**，使 DataFrame 变得更"宽扁"，减少一个索引级别。**是 `stack()` 的逆操作。**

#### 基本用法

```python
# 从上面的 stack 结果出发
s = df.stack()  # 有两级索引：(姓名, 科目)

print('=== unstack（默认最内层）===')
result = s.unstack()
print(result)
#      数学  英语  物理
# 张三   90   82   88
# 李四   85   88   92
# 王五   78   76   80
# ✅ 回到了原始形状！
```

#### 指定 unstack 的层级

```python
# 假设有三级索引
idx = pd.MultiIndex.from_tuples([
    ('北京', 2024, 'Q1'), ('北京', 2024, 'Q2'),
    ('上海', 2024, 'Q1'), ('上海', 2024, 'Q2'),
], names=['城市', '年份', '季度'])
s3 = pd.Series([100, 120, 90, 110], index=idx)

# unstack 不同层的效果:
s3.unstack(level='季度')   # 季度变列: 列=[Q1, Q2]
s3.unstack(level='年份')   # 年份变列: 列=[2024]
s3.unstack(level='城市')   # 城市变列: 列=[北京, 上海]
```

#### 图解 unstack

```
unstack 前 (长格式):
城市  年份  季度   值
北京  2024  Q1    100
           Q2    120
上海  2024  Q1     90
           Q2    110

unstack(季度):
城市  年份    Q1   QQ2    ← 季度变成列了
北京  2024  100  120
上海  2024   90  110

unstack(城市):
年份  季度   北京  上海    ← 城市变成列了
2024  Q1    100   90
      Q2    120  110
```

#### `fill_value` 参数

```python
# 数据不完整时会有 NaN
idx = pd.MultiIndex.from_tuples([
    ('A', 1), ('A', 2), ('B', 1)  # B 没有 2
])
s = pd.Series([10, 20, 30], index=idx)

print(s.unstack())
#     1     2
# A  10.0  20.0
# B  30.0   NaN  ← 缺失!

print(s.unstack(fill_value=0))
#    1   2
# A  10  20
# B  30   0  ← 填充了！
```

#### 连续 unstack 创建透视表

```python
# 三级索引连续 unstack
s3.unstack(level='季度').unstack(level='年份')
# 最终变成: 行=城市, 列=(年份,季度) 的 MultiIndex 列
```

---

### 四、`pivot()` — 创建透视表

**作用：** 根据指定的**行索引列**、**列索引列**和**值列**，将长格式数据重塑为宽格式的透视表。

#### 基本语法

```python
DataFrame.pivot(
    index=None,    # 作为行索引的列
    columns=None,  # 作为列的列
    values=None    # 作为值的列（可以多个）
)
```

#### 示例

```python
# 长格式原始数据
df_long = pd.DataFrame({
    '日期': ['1月', '1月', '1月', '2月', '2月', '2月'],
    '产品': ['A', 'B', 'C', 'A', 'B', 'C'],
    '销售额': [100, 200, 150, 120, 220, 170]
})

print('=== 长格式 ===')
print(df_long)
#    日期 产品  销售额
# 0  1月   A   100
# 1  1月   B   200
# ...

# pivot: 产品→列, 日期→行
pivot_df = df_long.pivot(index='日期', columns='产品', values='销售额')
print('\n=== pivot 后（宽格式/透视表）===')
print(pivot_df)
# 产品    A    B    C
# 日期                
# 1月   100  200  150
# 2月   120  220  170
```

#### 多个 values

```python
# 同时透视多列
df_multi_val = pd.DataFrame({
    '班级': ['一班']*3 + ['二班']*3,
    '科目': ['数学', '英语', '语文']*2,
    '平均分': [88, 82, 79, 85, 80, 83],
    '最高分': [95, 90, 88, 92, 87, 91]
})

pivot_multi = df_multi_val.pivot(index='班级', columns='科目')
print(pivot_multi)
#      平均分       最高分      
# 科目  数学 英语 语文 数学 英语 语文
# 班级                           
# 一班    88   82   79   95   90   88
# 二班    85   80   83   92   87   91
# 注意: 列变成了 MultiIndex (平均分/最高分 × 科目)
```

#### pivot vs pivot_table 的区别

| 特性 | `pivot()` | `pivot_table()` |
|------|----------|-----------------|
| 处理重复 | ❌ 不能有重复组合 | ✅ 自动聚合 |
| 聚合函数 | 无 | 可指定 `aggfunc` |
| 填充缺失 | 无 | 可用 `fill_value` |
| 边际汇总 | 无 | 可用 `margins` |

```python
# 如果有重复，pivot 会报错:
df_dup = pd.DataFrame({
    'x': ['a', 'a', 'b'],  # a 出现两次!
    'y': [1, 1, 2],
    'z': [10, 20, 30]
})
# df_dup.pivot(index='x', columns='y', values='z')  
# ❌ ValueError: Index contains duplicate entries

# pivot_table 则可以聚合:
df_dup.pivot_table(index='x', columns='y', values='z', aggfunc='mean')
# y     1     2
# x              
# a  15.0   NaN  ← (10+20)/2 = 15
# b   NaN  30.0
```

---

### 五、`pd.melt()` / `DataFrame.melt()` — 宽格式转长格式

**作用：** 将**宽格式**数据"融化"为**长格式**，将多列合并为两列：**变量列（variable）+ 值列（value）**。

**是 `pivot()` 的逆操作。**

#### 基本用法

```python
# 宽格式
df_wide = pd.DataFrame({
    '姓名': ['张三', '李四', '王五'],
    '数学': [90, 85, 78],
    '英语': [82, 88, 76],
    '物理': [88, 92, 80]
})

print('=== 宽格式 ===')
print(df_wide)
#    姓名  数学  英语  物理
# 0  张三   90   82   88
# 1  李四   85   88   92
# 2  王五   78   76   80

# melt: 数学/英语/物理 → 合并成一列
df_long = df_wide.melt(id_vars='姓名', var_name='科目', value_name='分数')
print('\n=== melt 后（长格式）===')
print(df_long)
#    姓名  科目  分数
# 0  张三  数学   90
# 1  李四  数学   85
# 2  王五  数学   78
# 3  张三  英语   82
# 4  李四  英语   88
# 5  王五  英语   76
# 6  张三  物理   88
# 7  李四  物理   92
# 8  王五  物理   80
```

#### 参数详解

```python
DataFrame.melt(
    id_vars=None,      # 保持不变的标识列（不被融化的列）
    value_vars=None,   # 要融化的列（默认全部非 id_vars 列）
    var_name='variable',  # 融化后的变量列名
    value_name='value',   # 融化后的值列名
    ignore_index=True     # 是否重置索引
)
```

#### 选择性 melt

```python
# 只融化部分列
df_wide.melt(id_vars='姓名', 
             value_vars=['数学', '英语'],  # 只融化这两科
             var_name='科目',
             value_name='分数')

# 多个 id_vars
df_wide.melt(id_vars=['姓名', '班级'], ...)  # 多个标识列保持不变
```

#### 宽格式 ↔️ 长格式 往返

```python
# 宽 → 长: melt
long = wide.melt(id_vars='姓名', var_name='科目', value_name='分数')

# 长 → 宽: pivot
wide_back = long.pivot(index='姓名', columns='科目', values='分数')

# ✅ round trip! 回到原来的形状
```

#### 实际应用场景

```python
# 场景1: 多个测量指标合为一列（便于绘图/分析）
measurements = pd.DataFrame({
    '样本ID': ['S1', 'S2', 'S3'],
    '温度': [25.1, 26.3, 24.8],
    '湿度': [60, 55, 65],
    '气压': [1013, 1015, 1012]
})

# melt 后便于用 seaborn 绘图
melted = measurements.melt(
    id_vars='样本ID', 
    var_name='指标', 
    value_name='读数'
)
# 样本ID   指标   读数
# S1     温度   25.1
# S1     湿度   60.0
# S1     气压  1013
# S2     温度   26.3
# ...

# 场景2: 时间序列从宽转长
sales_by_month = pd.DataFrame({
    '产品': ['A', 'B'],
    '1月': [100, 50],
    '2月': [120, 60],
    '3月': [110, 55]
})

sales_long = sales_by_month.melt(
    id_vars='产品', 
    var_name='月份', 
    value_name='销售额'
)
# 便于后续 groupby 或时间序列分析
```

---

### 六、`explode()` — 列表/元组列展开

**作用：** 将包含列表/元组的列**展开**，每个元素一行。

```python
df = pd.DataFrame({
    '学生': ['张三', '李四'],
    '课程': [['数学', '英语', '物理'], ['化学', '生物']],
    '成绩': [[90, 82, 88], [75, 80]]
})

print(df)
#    学生          课程       成绩
# 0  张三  [数学,英语,物理]  [90,82,88]
# 1  李四      [化学,生物]    [75,80]

# explode: 每门课一行
exploded = df.explode('课程').explode('成绩')
print(exploded)
#    学生  课程 成绩
# 0  张三  数学   90
# 0  张三  英语   82
# 0  张三  物理   88
# 1  李四  化学   75
# 1  李四  生物   80
```

---

### 七、四大方法关系图

```
                        宽格式 (Wide)
                       ┌─────────────┐
                       │  数学  英语  │
                       │ 张三  90   82│
                       └──────┬──────┘
                              │
            ┌─────────────────┼─────────────────┐
            ▼                 ▼                 ▼
      ┌──────────┐    ┌──────────┐    ┌──────────┐
      │ stack()  │    │  melt()  │    │ pivot()  │
      │ 列→索引  │    │ 宽→长    │    │ 长→宽    │
      └────┬─────┘    └────┬─────┘    └────▲─────┘
           │               │               │
           ▼               ▼               │
      ┌──────────┐    ┌──────────┐        │
      │unstack() │    │  pivot() │────────┘
      │ 索引→列  │    │ 长→宽    │
      └──────────┘    └──────────┘
      
      互逆操作:     互逆操作:
      stack ⟷ unstack   melt ⟷ pivot
```

---

### 八、速查代码卡

```python
# ====== stack (宽→长, 列→索引) ======
df.stack()                          # 所有列压入索引
df.stack(level=0)                   # 指定层级
df_multi_col.stack(level='名称')    # 用名称指定

# ====== unstack (长→宽, 索引→列) ======
s.unstack()                         # 最内层索引变列
s.unstack(level='城市')             # 指定层级
s.unstack(fill_value=0)             # NaN 填充

# ====== pivot (长→宽, 创建透视表) ======
df.pivot(index='行', columns='列', values='值')
df.pivot(index='行', columns='列')  # 多值 → MultiIndex 列

# ====== pivot_table (带聚合的透视表) ======
df.pivot_table(
    index='行', columns='列', values='值',
    aggfunc='mean',                 # 聚合函数
    fill_value=0,                   # 填充缺失
    margins=True                    # 显示总计
)

# ====== melt (宽→长, 融化) ======
df.melt(id_vars='标识列')
df.melt(id_vars=['id1','id2'], var_name='变量', value_name='值')
df.melt(id_vars='id', value_vars=['col1','col2'])  # 只融化部分列

# ====== explode (展开列表列) ======
df.explode('列表列')
df.explode(['列表1', '列表2'])  # 同时展开多列

# ====== 典型转换链 ======
# 宽 → 长 → 分析 → 宽
long_data = wide_data.melt(...)
result = long_data.groupby(...).agg(...)
wide_result = result.pivot(...)
```