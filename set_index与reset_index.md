---
lang: Python
date: 2026-04-08
tags:
  - 数据分析
---
## `set_index()` 和 `reset_index()` 完整总结

---

### 一、核心概念

```
set_index:   把【列】变成【索引】  （列 → 索引）
reset_index: 把【索引】变回【列】  （索引 → 列）

它们是互逆操作！
```

---

### 二、`set_index()` — 列变索引

#### 基本用法

```python
import pandas as pd
import numpy as np

df = pd.DataFrame({
    '姓名': ['张三', '李四', '王五', '赵六'],
    '城市': ['北京', '上海', '北京', '广州'],
    '年龄': [25, 30, 28, 35],
    '薪资': [15000, 25000, 18000, 30000]
})

print('原始 DataFrame:')
print(df)
#    姓名  城市  年龄     薪资
# 0  张三  北京   25  15000
# 1  李四  上海   30  25000
# 2  王五  北京   28  18000
# 3  赵六  广州   35  30000

# 单列作为索引
df1 = df.set_index('姓名')
print('\nset_index("姓名") 后:')
print(df1)
#      城市  年龄     薪资
# 姓名                   
# 张三  北京   25  15000
# 李四  上海   30  25000
# ...
# 注意：姓名这一列从数据中"消失"了，变成了索引！
```

#### 多列作为索引（创建 MultiIndex）

```python
# 多列 → 多级索引
df2 = df.set_index(['城市', '姓名'])
print('多级索引:')
print(df2)
#          年龄     薪资
# 城市 姓名           
# 北京 张三   25  15000
#      王五   28  18000
# 上海 李四   30  25000
# 广州 赵六   35  30000
```

#### 关键参数

```python
# drop=False: 保留原列（索引和列同时存在！）
df3 = df.set_index('姓名', drop=False)
print('drop=False:')
print(df3)
#        姓名  城市  年龄     薪资
# 姓名                       
# 张三   张三  北京   25  15000
# ...

# append=True: 追加到现有索引上（而不是替换）
df4 = df.set_index('城市').set_index('姓名', append=True)
print('append=True (追加为二级索引):')
print(df4)
#           年龄     薪资
# 城市 姓名           
# 北京 张三   25  15000
#      王五   28  18000
# 上海 李四   30  25000
# 广州 赵六   35  30000

# inplace=True: 直接修改原 DataFrame（不返回新对象）
df_copy = df.copy()
df_copy.set_index('姓名', inplace=True)  # df_copy 被直接修改
```

---

### 三、`reset_index()` — 索引变列

#### 基本用法

```python
df_idx = df.set_index(['城市', '姓名'])
print('有索引的 DataFrame:')
print(df_idx)

# reset_index: 索引全部还原为列
df_reset = df_idx.reset_index()
print('\nreset_index() 后:')
print(df_reset)
#    城市  姓名  年龄     薪资
# 0  北京  张三   25  15000
# 1  北京  王五   28  18000
# 2  上海  李四   30  25000
# 3  广州  赵六   35  30000
# 索引变回了默认的 RangeIndex(0,1,2,3)，原来的多级索引变成了普通列
```

#### 关键参数

```python
# drop=True: 直接丢弃索引（不还原为列）
df_dropped = df_idx.reset_index(drop=True)
print('drop=True (丢弃索引):')
print(df_dropped)
#     年龄     薪资
# 0   25  15000
# 1   28  18000
# 2   30  25000
# 3   35  30000
# 城市和姓名信息完全丢失了！

# level 参数：只重置指定的级别
df_partial = df_idx.reset_index(level='姓名')  # 只把姓名级还原
print('level="姓名":')
print(df_partial)
#       姓名  年龄     薪资
# 城市                   
# 北京   张三   25  15000
# 北京   王五   28  18000
# ...

# level=0 或 level=[0,1] 用数字指定级别
df_partial2 = df_idx.reset_index(level=0)  # 只重置第一级（城市）

# col_level / col_insert: 控制还原后的列放在 MultiIndex 的哪一级
# （较少用，了解即可）
```

#### 处理重复索引名

```python
# 如果原 DataFrame 已经有一个叫"姓名"的列，再 reset_index 会怎样？
df_with_name_col = df.copy()
df_idx2 = df_with_name_col.set_index('城市')

# reset_index 时原列名和已有列冲突
# Pandas 会自动给还原的列加后缀
df_conflict = df_idx2.reset_index()
print('列名冲突时自动加后缀:')
print(df_conflict.columns)  # Index(['城市', '姓名', '年龄', '薪资'], ...)
```

---

### 四、互逆关系图解

```
原始 DataFrame:
┌─────┬─────┬─────┬───────┐
│ 姓名 │ 城市 │ 年龄 │  薪资  │
├─────┼─────┼─────┼───────┤
│ 张三 │ 北京 │  25 │ 15000 │
│ ...  │ ...  │ ... │  ...  │
└─────┴─────┴─────┴───────┘
         ↓ set_index('姓名')
带索引的 DataFrame:
         ┌─────┬─────┬───────┐
         │ 城市 │ 年龄 │  薪资  │  ← 少了一列（姓名变索引了）
姓名 ───┼─────┼─────┼───────┤
张三     │ 北京 │  25 │ 15000 │
...      │ ...  │ ... │  ...  │
         └─────┴─────┴───────┘
         ↓ reset_index()  （互逆操作）
原始 DataFrame (恢复):
┌─────┬─────┬─────┬───────┐
│ 姓名 │ 城市 │ 年龄 │  薪资  │  ← 索引又变回列了
├─────┼─────├─────┼───────┤
│ 张三 │ 北京 │  25 │ 15000 │
│ ...  │ ...  │ ... │  ...  │
└─────┴─────┴─────┴───────┘
```

---

### 五、典型使用场景

#### 场景 A：groupby + reset_index 还原结果

```python
df = pd.DataFrame({
    '部门': ['技术', '销售', '技术', '销售', '人事'],
    '员工': ['A', 'B', 'C', 'D', 'E'],
    '绩效': [90, 85, 92, 78, 88]
})

# groupby 默认结果以分组列为索引
result = df.groupby('部门')['绩效'].mean()
print('groupby 结果（索引是部门）:')
print(result)
# 部门
# 人事    88.0
# 技术    91.0
# 销售    81.5
# Name: 绩效, dtype: float64

# 想要转回普通 DataFrame？用 reset_index
result_df = result.reset_index()
print('\nreset_index 后:')
print(result_df)
#    部门    绩效
# 0  人事   88.0
# 1  技术   91.0
# 2  销售   81.5

# 或者一步到位：as_index=False
result2 = df.groupby('部门', as_index=False)['绩效'].mean()
print('\nas_index=False:')
print(result2)
```

#### 场景 B：排序后恢复原始顺序

```python
df = pd.DataFrame({'值': [3, 1, 4, 1, 5]})

# 排序前先保存原始索引信息
sorted_df = df.sort_values('值')

# 排序后的索引是乱的: [1, 3, 0, 2, 4]
print('排序后索引:', sorted_df.index.tolist())

# 想按原始顺序恢复？
recovered = sorted_df.sort_index()  # 按索引排序即可恢复
print('sort_index 恢复:', recovered['值'].tolist())  # [3, 1, 4, 1, 5]

# 或者用 reset_index(drop=True) 重置索引
clean = sorted_df.reset_index(drop=True)
print('reset_index 后:', clean.index.tolist())  # [0, 1, 2, 3, 4]
```

#### 场景 C：创建 MultiIndex 用于透视表

```python
df = pd.DataFrame({
    '班级': ['一班']*3 + ['二班']*3,
    '科目': ['数学', '英语', '语文']*2,
    '平均分': [88, 82, 79, 85, 80, 83]
})

# 创建多级索引便于 unstack
multi = df.set_index(['班级', '科目'])
print(multi)

# unstack 变成透视表
pivot = multi.unstack()
print(pivot)

# 操作完后想还原？reset_index
back = pivot.stack().reset_index()
print(back)
```

#### 场景 D：去重后保留完整信息

```python
df = pd.DataFrame({
    'ID': [1, 2, 2, 3, 3, 3],
    '姓名': ['A', 'B', 'B', 'C', 'C', 'C'],
    '分数': [90, 85, 87, 78, 80, 82]
})

# 按 ID 去重，保留每个 ID 的第一条记录
unique = df.drop_duplicates(subset='ID', keep='first')

# 此时索引可能不连续: [0, 1, 3]
unique_clean = unique.reset_index(drop=True)
print(unique_clean)
#    ID 姓名  分数
# 0   1   A   90
# 1   2   B   85
# 2   3   C   78
# 索引重新从 0 开始连续编号
```

---

### 六、常见坑

| 坑 | 说明 | 解决 |
|------|------|------|
| **链式赋值警告** | `df.set_index(...)` 不修改原对象 | 用 `inplace=True` 或重新赋值 |
| **丢失信息** | `reset_index(drop=True)` 丢弃索引数据 | 确认不需要再用 |
| **列名冲突** | 还原的索引名与已有列同名 | Pandas 自动加后缀 |
| **MultiIndex 部分还原** | `reset_index()` 还原所有级别 | 用 `level=` 指定要还原的级别 |
| **性能** | 频繁 set/reset 影响性能 | 尽量一次性设计好索引结构 |

```python
# 坑示例：链式赋值不生效
df.set_index('姓名')  # ❌ 这行什么都没做！df 没变
print(df)              # 还是原来的 df

# 正确做法
df = df.set_index('姓名')  # ✅ 重新赋值
# 或
df.set_index('姓名', inplace=True)  # ✅ 原地修改
```

---

### 七、速查代码卡

```python
# ====== set_index ======
df.set_index('列名')                    # 单列 → 索引
df.set_index(['列1', '列2'])             # 多列 → 多级索引
df.set_index('列名', drop=False)         # 保留原列
df.set_index('列名', append=True)        # 追加为二级索引
df.set_index('列名', inplace=True)       # 原地修改

# ====== reset_index ======
df.reset_index()                         # 全部索引 → 列
df.reset_index(drop=True)                # 丢弃索引（不还原为列）
df.reset_index(level='级别名')            # 只还原指定级别
df.reset_index(level=0)                  # 用数字指定级别
df.reset_index(inplace=True)             # 原地修改

# ====== 典型组合 ======
# groupby 结果转 DataFrame
df.groupby('x')['y'].sum().reset_index()

# 排序后重置连续索引
df.sort_values('col').reset_index(drop=True)

# 去重后重置索引
df.drop_duplicates().reset_index(drop=True)

# unstack 后还原
df.set_index(['a','b']).unstack().stack().reset_index()
```

### 八、方法对照表

| 方法                             | 方向     | 效果        |       是否保留原数据       |
| ------------------------------ | ------ | --------- | :-----------------: |
| `set_index('col')`             | 列→索引   | 列消失，变成索引  | 默认丢弃列 (`drop=True`) |
| `set_index('col', drop=False)` | 列→索引   | 列同时保留在数据中 |        ✅ 保留         |
| `reset_index()`                | 索引→列   | 索引变回普通列   |        ✅ 保留         |
| `reset_index(drop=True)`       | 索引→列   | 索引直接丢弃    |        ❌ 丢弃         |
| `reset_index(level='L1')`      | 部分索引→列 | 只还原指定级别   |       其他级别保留        |