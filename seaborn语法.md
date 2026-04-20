---
title: seaborn语法
date: 2026-04-16
lang: python
tags:
  - 绘图
  - 数据分析
---

# Seaborn 语法

## 基础导入与配置

```python
import seaborn as sns
import matplotlib.pyplot as plt
import pandas as pd

# 设置主题
sns.set_theme(style="darkgrid", context="notebook", font_scale=1.2)
```

> 可用样式: `darkgrid`, `whitegrid`, `dark`, `white`, `ticks`  
> 可用上下文: `paper`, `notebook`, `talk`, `poster`

---

## Figure-Level vs Axes-Level 函数

| 特性 | Axes-Level | Figure-Level |
|------|------------|-------------|
| **创建** | 单个子图 | 完整布局 |
| **返回** | matplotlib axes | FacetGrid/JointGrid |
| **参数** | 可用 `ax=` | 不能用 `ax=` |
| **示例** | `sns.histplot()` | `sns.catplot()` |

---

## 关系图 (Relational)

### 散点图
```python
sns.scatterplot(
    data=df,
    x="col1", y="col2",
    hue="category",      # 按类别着色
    size="size_col",     # 按数值设置大小
    style="style_col",   # 按类别设置样式
    palette="Set2"
)
```

### 折线图
```python
sns.lineplot(
    data=df, x="time", y="value",
    hue="group", markers=True, ci=95
)
```

### Figure-Level 关系图
```python
g = sns.relplot(
    data=df, x="x", y="y",
    col="facet_col", row="row_col",
    height=4, aspect=1.5
)
```

---

## 分布图 (Distribution)

### 直方图 + KDE
```python
sns.histplot(data=df, x="value", kde=True, bins=30)
```

### KDE 图
```python
sns.kdeplot(data=df, x="column", fill=True, color="blue")
```

### Figure-Level 分布图
```python
g = sns.displot(data=df, x="value", col="category", kde=True)
```

---

## 分类图 (Categorical)

### 条形图
```python
sns.barplot(data=df, x="category", y="value", palette="rocket")
```

### 箱线图
```python
sns.boxplot(data=df, x="category", y="value", hue="group")
```

### 小提琴图
```python
sns.violinplot(data=df, x="category", y="value", split=True)
```

### Figure-Level 分类图
```python
g = sns.catplot(data=df, x="cat", y="val", kind="box", col="facet")
```

---

## 回归图 (Regression)

### 回归图
```python
sns.regplot(data=df, x="x", y="y", scatter=True, line_kws={"color": "red"})
```

### Figure-Level 回归图
```python
g = sns.lmplot(data=df, x="x", y="y", col="category", height=4)
```

---

## 矩阵图 (Matrix)

### 热力图
```python
sns.heatmap(
    df.corr(),
    annot=True, fmt=".2f",
    cmap="coolwarm", center=0,
    square=True
)
```

### 聚类热力图
```python
g = sns.clustermap(df.corr(), cmap="vlag", center=0)
```

---

## 多图网格 (Multi-Plot Grids)

### FacetGrid
```python
g = sns.FacetGrid(data=df, col="col", row="row", height=3)
g.map(sns.scatterplot, "x", "y")
g.add_legend()
```

### Pairplot
```python
sns.pairplot(data=df, hue="category", diag_kind="kde")
```

### Jointplot
```python
g = sns.jointplot(data=df, x="x", y="y", kind="scatter")
```

---

## 样式与自定义

### 主题设置
```python
sns.set_style("whitegrid")
with sns.axes_style("white"):
    sns.scatterplot(data=df, x="x", y="y")
```

### 去除边框
```python
sns.despine()              # 去除上、右边框
sns.despine(left=True)     # 去除左边框
sns.despine(trim=True)     # 裁剪到数据范围
```

### 调色板
```python
sns.set_palette("husl")

# 预设调色板
# 渐变: rocket, viridis, mako
# 发散: coolwarm, vlag
# 定性: Set1, Set2, pastel

# 自定义调色板
colors = sns.color_palette("rocket", n_colors=5)
```

---

## 常用参数速查

| 参数 | 用途 |
|------|------|
| `data` | DataFrame 数据源 |
| `x`, `y` | 列名 |
| `hue` | 按类别着色 |
| `size` | 按数值设置大小 |
| `style` | 按类别设置样式 |
| `palette` | 颜色方案 |
| `col`, `row` | 分面 (figure-level) |
| `height`, `aspect` | 图形尺寸 |
| `ci` | 置信区间 |
| `kde` | 添加核密度估计曲线 |

---

## 绘图选择指南

```
关系图 (2个连续变量):
├─ scatterplot() - 散点图
└─ lineplot() - 折线图

分布图 (1个变量):
├─ histplot() - 直方图
├─ kdeplot() - 核密度估计
└─ displot() - 分布图 (figure-level)

分类图 (1分类 + 1连续):
├─ barplot() - 条形图
├─ boxplot() - 箱线图
├─ violinplot() - 小提琴图
└─ catplot() - 分类图 (figure-level)

回归图:
├─ regplot() - 回归图
└─ lmplot() - 回归图 (figure-level)

矩阵图:
├─ heatmap() - 热力图
└─ clustermap() - 聚类热力图

多图网格:
├─ FacetGrid - 自定义分面
├─ pairplot() - 配对图
└─ jointplot() - 联合图
```

---

## 参考

- [官方文档](https://seaborn.pydata.org/)
- [API 参考](https://seaborn.pydata.org/api.html)
- [教程](https://seaborn.pydata.org/tutorial.html)

