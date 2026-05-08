# Matplotlib 绘图基础

## 简介

Matplotlib 是 Python 最流行的数据可视化库，可以创建各种静态、动态和交互式图表。

```python
import matplotlib.pyplot as plt
import numpy as np
```

---

## 基本图表类型

### 1. 折线图 (Line Plot)

```python
x = np.linspace(0, 10, 100)
y = np.sin(x)

plt.plot(x, y)
plt.title('Sine Wave')
plt.xlabel('X axis')
plt.ylabel('Y axis')
plt.show()
```

**常用参数：**
- `color` / `c`: 颜色 ('r', 'g', 'b', '#FF0000')
- `linewidth` / `lw`: 线宽
- `linestyle` / `ls`: 线型 ('-', '--', '-.', ':')
- `marker`: 标记点 ('o', 's', '^', '*')
- `label`: 图例标签

---

### 2. 散点图 (Scatter Plot)

```python
x = np.random.rand(50)
y = np.random.rand(50)
colors = np.random.rand(50)
sizes = 1000 * np.random.rand(50)

plt.scatter(x, y, c=colors, s=sizes, alpha=0.5)
plt.show()
```

**常用参数：**
- `c`: 颜色（可以是数组，用于颜色映射）
- `s`: 点的大小
- `alpha`: 透明度 (0-1)
- `cmap`: 颜色映射 ('viridis', 'plasma', 'coolwarm')

---

### 3. 柱状图 (Bar Chart)

```python
categories = ['A', 'B', 'C', 'D']
values = [23, 45, 56, 78]

# 垂直柱状图
plt.bar(categories, values, color='skyblue')

# 水平柱状图
plt.barh(categories, values, color='lightcoral')

plt.show()
```

**分组柱状图：**
```python
x = np.arange(4)
width = 0.35

plt.bar(x - width/2, values1, width, label='Group 1')
plt.bar(x + width/2, values2, width, label='Group 2')
plt.xticks(x, categories)
plt.legend()
```

---

### 4. 直方图 (Histogram)

```python
data = np.random.randn(1000)

plt.hist(data, bins=30, edgecolor='black', alpha=0.7)
plt.title('Histogram')
plt.show()
```

**常用参数：**
- `bins`: 柱子的数量
- `density`: 是否显示概率密度
- `cumulative`: 是否显示累积分布

---

### 5. 饼图 (Pie Chart)

```python
sizes = [30, 25, 25, 20]
labels = ['A', 'B', 'C', 'D']
colors = ['gold', 'yellowgreen', 'lightcoral', 'lightskyblue']
explode = (0.1, 0, 0, 0)  # 突出显示第一个

plt.pie(sizes, explode=explode, labels=labels, colors=colors,
        autopct='%1.1f%%', shadow=True, startangle=90)
plt.axis('equal')  # 确保圆形
plt.show()
```

---

### 6. 箱线图 (Box Plot)

```python
data = [np.random.normal(0, std, 100) for std in range(1, 5)]

plt.boxplot(data, labels=['A', 'B', 'C', 'D'])
plt.title('Box Plot')
plt.show()
```

---

## 图形美化

### 设置中文字体

```python
plt.rcParams['font.sans-serif'] = ['SimHei', 'DejaVu Sans']
plt.rcParams['axes.unicode_minus'] = False  # 解决负号显示问题
```

### 添加网格和图例

```python
plt.grid(True, linestyle='--', alpha=0.7)
plt.legend(loc='best', fontsize=12)
```

### 设置坐标轴

```python
plt.xlim(0, 10)      # X轴范围
plt.ylim(-1, 1)      # Y轴范围
plt.xticks([0, 5, 10], ['start', 'middle', 'end'])  # 自定义刻度标签
```

---

## 多子图 (Subplots)

### 方式1：plt.subplot()

```python
plt.subplot(2, 2, 1)  # 2行2列的第1个
plt.plot(x, y1)

plt.subplot(2, 2, 2)  # 2行2列的第2个
plt.plot(x, y2)

plt.subplot(2, 1, 2)  # 2行1列的第2个（占满整行）
plt.plot(x, y3)

plt.tight_layout()  # 自动调整布局
plt.show()
```

### 方式2：plt.subplots()（推荐）

```python
fig, axes = plt.subplots(2, 2, figsize=(10, 8))

axes[0, 0].plot(x, y1)
axes[0, 0].set_title('Plot 1')

axes[0, 1].scatter(x, y2)
axes[0, 1].set_title('Plot 2')

axes[1, 0].bar(categories, values)
axes[1, 0].set_title('Plot 3')

axes[1, 1].hist(data)
axes[1, 1].set_title('Plot 4')

plt.tight_layout()
plt.show()
```

---

## 保存图片

```python
plt.savefig('figure.png', dpi=300, bbox_inches='tight')
# 参数：
# dpi: 分辨率
# bbox_inches='tight': 去除白边
# format: 'png', 'pdf', 'svg', 'jpg'
```

---

## 常用颜色

| 缩写 | 颜色 |
|------|------|
| 'b' | 蓝色 (blue) |
| 'g' | 绿色 (green) |
| 'r' | 红色 (red) |
| 'c' | 青色 (cyan) |
| 'm' | 品红 (magenta) |
| 'y' | 黄色 (yellow) |
| 'k' | 黑色 (black) |
| 'w' | 白色 (white) |

---

## 常用线型

| 线型 | 说明 |
|------|------|
| '-' | 实线 |
| '--' | 虚线 |
| '-.' | 点划线 |
| ':' | 点线 |

---

## 快速参考

```python
import matplotlib.pyplot as plt
import numpy as np

# 最基本的三行代码
x = np.linspace(0, 10, 100)
y = np.sin(x)
plt.plot(x, y)
plt.show()
```

---

## 相关资源

- 官方文档：https://matplotlib.org/
- 示例画廊：https://matplotlib.org/stable/gallery/index.html
