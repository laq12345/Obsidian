---
lang: Python
date: 2026-04-05
tags:
  - 数据分析
---
导入包：
```python
import numpy as np
```

创建数组：
```python
In [13]: data = np.array([[1.5, -0.1, 3], [0, -3, 6.5]])

In [14]: data
Out[14]: 
array([[ 1.5, -0.1,  3. ],
       [ 0. , -3. ,  6.5]])
##############################################
In [19]: data1 = [6, 7.5, 8, 0, 1]

In [20]: arr1 = np.array(data1)

In [21]: arr1
Out[21]: array([6. , 7.5, 8. , 0. , 1. ])

In [22]: data2 = [[1, 2, 3, 4], [5, 6, 7, 8]]

In [23]: arr2 = np.array(data2)

In [24]: arr2
Out[24]: 
array([[1, 2, 3, 4],
       [5, 6, 7, 8]])
```

每个数组都有一个`shape`，一个表示每个维度大小的元组，以及一个`dtype`，一个描述数组数据类型的对象：

```python
In [17]: data.shape
Out[17]: (2, 3)

In [18]: data.dtype
Out[18]: dtype('float64')
```

检查ndarray的维度：`ndim`和`shape`
```python
In [25]: arr2.ndim
Out[25]: 2

In [26]: arr2.shape
Out[26]: (2, 4)
```

`numpy.zeros` 和 `numpy.ones` 分别创建具有给定长度或形状的 0 或 1 数组。`numpy.empty` 创建一个数组，但不将其值初始化为任何特定值:
```python
In [29]: np.zeros(10)
Out[29]: array([0., 0., 0., 0., 0., 0., 0., 0., 0., 0.])

In [30]: np.zeros((3, 6))
Out[30]: 
array([[0., 0., 0., 0., 0., 0.],
       [0., 0., 0., 0., 0., 0.],
       [0., 0., 0., 0., 0., 0.]])

In [31]: np.empty((2, 3, 2))
Out[31]: 
array([[[0., 0.],
        [0., 0.],
        [0., 0.]],
       [[0., 0.],
        [0., 0.],
        [0., 0.]]])
```

`numpy.arange` 是内置 Python `range` 函数的数组值版本：
```python
In [32]: np.arange(15)
Out[32]: array([ 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14])
```

| 函数                         | 描述                                                                        |
| :------------------------- | :------------------------------------------------------------------------ |
| `array`                    | 将输入数据（列表、元组、数组或其他序列类型）转换为 `ndarray`，可以通过推断数据类型或显式指定数据类型；默认情况下复制输入数据       |
| `asarray`                  | 将输入转换为 `ndarray`，但如果输入已经是 `ndarray` 则不进行复制                                |
| `arange`                   | 类似于内置的 `range`，但返回 `ndarray` 而不是列表                                        |
| `ones`,  <br>`ones_like`   | 生成一个给定形状和数据类型的全 1 数组；`ones_like` 接受另一个数组并生成一个具有相同形状和数据类型的全 1 数组           |
| `zeros`,  <br>`zeros_like` | 类似于 `ones` 和 `ones_like`，但生成的是全 0 数组                                      |
| `empty`,  <br>`empty_like` | 通过分配新内存来创建新数组，但不像 `ones` 和 `zeros` 那样用任何值填充                               |
| `full`,  <br>`full_like`   | 生成一个给定形状和数据类型的数组，所有值都设置为指定的“填充值”；`full_like` 接受另一个数组并生成一个具有相同形状和数据类型的填充数组 |
| `eye`,  <br>`identity`     | 创建一个  N x N  的单位矩阵（对角线上为 1，其余位置为 0）                                       |
一些重要的 NumPy 数组创建函数

## ndarray 的数据类型

| 类型 (Type)                                         | 类型代码 (Type code)   | 描述 (Description)                                               |
| :------------------------------------------------ | :----------------- | :------------------------------------------------------------- |
| `int8`, `uint8`                                   | `i1`, `u1`         | 有符号和无符号 8 位（1 字节）整数类型                                          |
| `int16`, `uint16`                                 | `i2`, `u2`         | 有符号和无符号 16 位整数类型                                               |
| `int32`, `uint32`                                 | `i4`, `u4`         | 有符号和无符号 32 位整数类型                                               |
| `int64`, `uint64`                                 | `i8`, `u8`         | 有符号和无符号 64 位整数类型                                               |
| `float16`                                         | `f2`               | 半精度浮点数                                                         |
| `float32`                                         | `f4` 或 `f`         | 标准单精度浮点数；与 C 语言的 `float` 兼容                                    |
| `float64`                                         | `f8` 或 `d`         | 标准双精度浮点数；与 C 语言的 `double` 和 Python 的 `float` 对象兼容              |
| `float128`                                        | `f16` 或 `g`        | 扩展精度浮点数                                                        |
| `complex64`,  <br>`complex128`,  <br>`complex256` | `c8`, `c16`, `c32` | 复数，分别由两个 32、64 或 128 位的浮点数表示                                   |
| `bool`                                            | `?`                | 布尔类型，存储 `True` 和 `False` 值                                     |
| `object`                                          | `O`                | Python 对象类型；值可以是任何 Python 对象                                   |
| `string_`                                         | `S`                | 固定长度的 ASCII 字符串类型（每个字符 1 字节）；例如，要创建长度为 10 的字符串数据类型，请使用 `'S10'` |
| `unicode_`                                        | `U`                | 固定长度的 Unicode 类型（字节数取决于平台）；与 `string_` 具有相同的规范语义（例如，`'U10'`）   |
NumPy 数据类型

用ndarray的`astype`方法，显式地将一个数据类型转换或铸造一个数组到另一个类型：
```python
In [37]: arr = np.array([1, 2, 3, 4, 5])

In [38]: arr.dtype
Out[38]: dtype('int64')

In [39]: float_arr = arr.astype(np.float64)

In [40]: float_arr
Out[40]: array([1., 2., 3., 4., 5.])

In [41]: float_arr.dtype
Out[41]: dtype('float64')
```

- ! 如果你想要的是ndarray的切片而不是视图，你需要显式复制该数组——例如`arr[5:8].copy()`。正如你将看到的，pandas也是这样运作的。

转置：
```python
arr.T
```

## 伪随机数生成

`numpy.random` 模块补充了内置的 Python `random` 模块，提供了函数，能够高效地从多种概率分布中生成完整的样本数组。例如，你可以用`numpy.random.standard_normal`从标准正态分布中抽样。像`numpy.random.standard_normal`这样的函数使用`numpy.random`模块的默认随机数生成器，但你的代码可以配置为使用显式生成器：
```python
In [147]: rng = np.random.default_rng(seed=12345)

In [148]: data = rng.standard_normal((2, 3))
```
`seed` 参数决定了生成器的初始状态，每次使用`rng`对象生成数据时，状态都会变化。生成对象 `rng` 也与其他可能使用 `numpy.random` 模块的代码隔离：
```python
In [149]: type(rng)
Out[149]: numpy.random._generator.Generator
```

|方法 (Method)|描述 (Description)|
|:--|:--|
|`permutation`|返回序列的随机排列，或返回一个排列后的范围|
|`shuffle`|就地随机排列序列|
|`uniform`|从均匀分布中抽取样本|
|`integers`|从给定的低到高范围内抽取随机整数|
|`standard_normal`|从均值为 0、标准差为 1 的正态分布中抽取样本|
|`binomial`|从二项分布中抽取样本|
|`normal`|从正态（高斯）分布中抽取样本|
|`beta`|从贝塔分布中抽取样本|
|`chisquare`|从卡方分布中抽取样本|
|`gamma`|从伽马分布中抽取样本|
|`uniform`|从 [0, 1) 区间上的均匀分布中抽取样本|
NumPy 随机数生成器方法

`numpy.random` 是 NumPy 中用于生成随机数的核心模块，广泛应用于数据科学、模拟实验和机器学习等领域。它的功能主要可以分为三大类：**基础随机数生成**、**概率分布抽样**和**随机排列与采样**。

为了帮助你记笔记，这里对常用方法进行系统性的总结。

### 🎲 基础随机数生成

这类方法主要用于生成服从特定基础分布（如均匀分布、标准正态分布）的随机数。

- **`np.random.rand(d0, d1, ..., dn)`**
    
    - **功能**：生成一个在 `[0, 1)` 区间内服从**均匀分布**的随机浮点数数组。
    - **参数**：`d0, d1, ...` 是整数，用于指定输出数组的形状。
    - **示例**：`np.random.rand(2, 3)` 会生成一个 2x3 的数组。
- **`np.random.randn(d0, d1, ..., dn)`**
    
    - **功能**：生成一个服从**标准正态分布**（均值为0，方差为1）的随机浮点数数组。
    - **参数**：与 `rand` 相同，指定输出数组的形状。
    - **示例**：`np.random.randn(5)` 会生成一个包含5个元素的一维数组。
- **`np.random.randint(low, high=None, size=None)`**
    
    - **功能**：生成服从**离散均匀分布**的随机整数。
    - **参数**：
        - `low`: 最小值（包含）。
        - `high`: 最大值（不包含）。如果为 `None`，则 `low` 为最大值，最小值为0。
        - `size`: 输出数组的形状。
    - **示例**：`np.random.randint(1, 10, size=3)` 可能生成 `[3, 7, 2]`。

### 📈 概率分布抽样

`numpy.random` 提供了大量函数来从各种经典的概率分布中抽样。

- **`np.random.normal(loc=0.0, scale=1.0, size=None)`**
    
    - **功能**：从**正态分布（高斯分布）**中抽取样本。
    - **参数**：`loc` 是均值，`scale` 是标准差。
- **`np.random.uniform(low=0.0, high=1.0, size=None)`**
    
    - **功能**：从指定范围的**均匀分布**中抽取样本，比 `rand` 更灵活。
    - **参数**：`low` 和 `high` 定义了区间的上下界。
- **`np.random.binomial(n, p, size=None)`**
    
    - **功能**：从**二项分布**中抽取样本。
    - **参数**：`n` 是试验次数，`p` 是单次试验成功的概率。
- **`np.random.poisson(lam=1.0, size=None)`**
    
    - **功能**：从**泊松分布**中抽取样本。
    - **参数**：`lam` 是事件发生的期望次数（lambda）。

### 🔄 随机排列与采样

这类方法用于对现有数据进行随机打乱或抽样。

- **`np.random.shuffle(x)`**
    
    - **功能**：**原地**打乱数组 `x` 的顺序。它会直接修改原数组，没有返回值。
    - **注意**：只对数组的第一个轴进行打乱。
- **`np.random.permutation(x)`**
    
    - **功能**：返回一个打乱顺序后的**新数组**，不修改原数组 `x`。如果 `x` 是一个整数，则返回 `np.arange(x)` 的随机排列。
- **`np.random.choice(a, size=None, replace=True, p=None)`**
    
    - **功能**：从给定的一维数组 `a` 中生成一个随机样本。这是非常强大的一个函数。
    - **参数**：
        - `a`: 1D 数组或整数。
        - `size`: 输出样本的形状。
        - `replace`: 是否为放回抽样。
        - `p`: 与 `a` 中每个元素关联的概率，如果不提供则默认为均匀分布。

### 💡 重要提示：新版随机数生成器

从 NumPy 1.17 版本开始，官方推荐使用新的随机数生成器 `Generator`，因为它性能更好，且具有更好的统计特性。

**推荐的初始化方式：**

```python
import numpy as np

# 1. 创建一个 Generator 实例
rng = np.random.default_rng(seed=42)  # seed 可选，用于复现结果

# 2. 使用实例的方法，这些方法与旧版类似
random_array = rng.random((2, 3))       # 替代 np.random.rand
normal_array = rng.normal(0, 1, 100)    # 替代 np.random.normal
int_array = rng.integers(0, 10, 5)      # 替代 np.random.randint
shuffled_array = rng.permutation([1, 2, 3, 4]) # 替代 np.random.permutation
```

**总结一下，你的笔记可以这样整理：**

1. **基础生成**：`rand` (均匀), `randn` (正态), `randint` (整数)。
2. **分布抽样**：`normal`, `uniform`, `binomial`, `poisson` 等。
3. **排列采样**：`shuffle` (原地打乱), `permutation` (返回新数组), `choice` (灵活抽样)。
4. **最佳实践**：优先使用 `np.random.default_rng()` 创建生成器实例来调用上述功能。

## 通用函数：快速的按元素数组函数

| 函数                                                            | 描述                                                         |
| :------------------------------------------------------------ | :--------------------------------------------------------- |
| `abs`, `fabs`                                                 | 逐元素计算整数、浮点数或复数的绝对值                                         |
| `sqrt`                                                        | 计算每个元素的平方根（等价于 `arr 0.5`）                                  |
| `square`                                                      | 计算每个元素的平方（等价于 `arr 2`）                                     |
| `exp`                                                         | 计算每个元素的指数 $ e^x $                                          |
| `log`, `log10`, `log2`, `log1p`                               | 分别计算自然对数（底为 $ e $ ）、以 10 为底的对数、以 2 为底的对数以及 $ \log(1 + x) $ |
| `sign`                                                        | 计算每个元素的符号：1（正数）、0（零）或 -1（负数）                               |
| `ceil`                                                        | 计算每个元素的天花板值（即大于或等于该数字的最小整数）                                |
| `floor`                                                       | 计算每个元素的地板值（即小于或等于每个元素的最大整数）                                |
| `rint`                                                        | 将元素四舍五入到最接近的整数，并保留 `dtype`                                 |
| `modf`                                                        | 将数组的小数部分和整数部分作为单独的数组返回                                     |
| `isnan`                                                       | 返回布尔数组，指示每个值是否为 `NaN`（非数字）                                 |
| `isfinite`, `isinf`                                           | 分别返回布尔数组，指示每个元素是有限值（非 `inf`，非 `NaN`）还是无限值                  |
| `cos`, `cosh`, `sin`, `sinh`, `tan`, `tanh`                   | 普通三角函数和双曲三角函数                                              |
| `arccos`, `arccosh`, `arcsin`, `arcsinh`, `arctan`, `arctanh` | 反三角函数                                                      |
| `logical_not`                                                 | 逐元素计算 `not x` 的真值（等价于 `~arr`）                              |
一些一元通用函数

| 函数                                                           | 描述                                                        |
| :----------------------------------------------------------- | :-------------------------------------------------------- |
| `add`                                                        | 将数组中的对应元素相加                                               |
| `subtract`                                                   | 从第一个数组的元素中减去第二个数组的元素                                      |
| `multiply`                                                   | 将数组元素相乘                                                   |
| `divide, floor_divide`                                       | 除法或向下取整除法（截断余数）                                           |
| `power`                                                      | 将第一个数组中的元素提升到第二个数组中指示的幂次                                  |
| `maximum, fmax`                                              | 逐元素取最大值；`fmax` 忽略 `NaN`                                   |
| `minimum, fmin`                                              | 逐元素取最小值；`fmin` 忽略 `NaN`                                   |
| `mod`                                                        | 逐元素取模（除法的余数）                                              |
| `copysign`                                                   | 将第二个参数中值的符号复制到第一个参数中的值上                                   |
| `greater, greater_equal, less, less_equal, equal, not_equal` | 执行逐元素比较，生成布尔数组（等价于中缀运算符 `>`, `>=`, `<`, `<=`, `==`, `!=`） |
| `logical_and`                                                | 计算 AND (`&`) 逻辑运算的逐元素真值                                   |
| `logical_or`                                                 | 计算 OR (`\|`) 逻辑运算的逐元素真值                                   |
| `logical_xor`                                                | 计算 XOR (`^`) 逻辑运算的逐元素真值                                   |
一些二元通用函数

虽然不常见，但ufunc可以返回多个数组。`numpy.modf` 是一个例子：内置 Python `math.modf` 的矢量化版本，它返回浮点数组的分数部分和整数部分：

Ufunc接受一个可选的`out`参数，允许它们将结果分配到已有数组中，而无需创建新的数组：

```python
In [164]: arr
Out[164]: array([ 4.5146, -8.1079, -0.7909,  2.2474, -6.718 , -0.4084,  8.6237])

In [165]: out = np.zeros_like(arr)

In [166]: np.add(arr, 1)
Out[166]: array([ 5.5146, -7.1079,  0.2091,  3.2474, -5.718 ,  0.5916,  9.6237])

In [167]: np.add(arr, 1, out=out)
Out[167]: array([ 5.5146, -7.1079,  0.2091,  3.2474, -5.718 ,  0.5916,  9.6237])

In [168]: out
Out[168]: array([ 5.5146, -7.1079,  0.2091,  3.2474, -5.718 ,  0.5916,  9.6237])
```

## 面向数组的数组编程

`numpy.where()` 是 NumPy 库中一个非常强大且常用的函数，主要用于根据条件从数组中筛选元素或进行值的替换。它的核心功能可以根据你传入的参数数量，分为两种主要用法。

#### 🔎 用法一：`np.where(condition)`

当你只提供一个条件参数时，`np.where()` 的作用是 **查找满足条件的元素的位置**。

- **返回值**：它返回一个元组（tuple）。对于一维数组，元组中包含一个数组，该数组是满足条件的元素的索引。对于多维数组，元组中的每个数组分别代表一个维度上的坐标。

##### 示例：查找一维数组中的位置

```python
import numpy as np

arr = np.array([10, 25, 30, 15, 40])
# 找出所有大于 20 的元素的索引
indices = np.where(arr > 20)

print(indices)
# 输出: (array([1, 2, 4]),)
# 这是一个元组，indices[0] 才是包含索引的数组

print(indices[0])
# 输出: [1 2 4]
```

#### 🔄 用法二：`np.where(condition, x, y)`

当你提供三个参数时，`np.where()` 的作用类似于一个向量化的三元运算符，用于 **根据条件从 x 或 y 中选择元素**。

- **逻辑**：对于数组中的每个元素，如果满足 `condition`，则从 `x` 中选取对应位置的元素；否则，从 `y` 中选取。
- **返回值**：返回一个与条件数组形状相同的新数组。

##### 示例：根据条件替换值

```python
import numpy as np

arr = np.array([-2, -1, 0, 1, 2])
# 将正数替换为 1，非正数替换为 -1
new_arr = np.where(arr > 0, 1, -1)

print(new_arr)
# 输出: [-1 -1 -1  1  1]
# 原始数组 arr 并未被修改
```

#### ✨ 高级用法：多条件组合

你可以使用逻辑运算符（如 `&` 表示“与”，`|` 表示“或”）来组合多个条件。**请注意，每个条件都需要用括号 `()` 括起来**，以确保正确的运算优先级。

##### 示例：查找满足多个条件的元素

```python
import numpy as np

arr = np.array([5, 12, 18, 8, 25])
# 找出所有大于 10 且小于 20 的元素的索引
indices = np.where((arr > 10) & (arr < 20))

print(indices[0])
# 输出: [1 2]
```

### 数学与统计方法

| 方法               | 描述                        |
| :--------------- | :------------------------ |
| `sum`            | 数组中所有元素的和或沿轴的和；零长度数组的和为 0 |
| `mean`           | 算术平均值；在零长度数组上无效（返回 `NaN`） |
| `std, var`       | 分别为标准差和方差                 |
| `min, max`       | 最小值和最大值                   |
| `argmin, argmax` | 分别为最小和最大元素的索引             |
| `cumsum`         | 从 0 开始的元素累积和              |
| `cumprod`        | 从 1 开始的元素累积积              |
基本数组统计方法

### 布尔数组方法

`sum` 常被用作计数布尔数组中`True`值的方法：
```python
In [205]: arr = rng.standard_normal(100)

In [206]: (arr > 0).sum() # Number of positive values
Out[206]: 48

In [207]: (arr <= 0).sum() # Number of non-positive values
Out[207]: 52
```

`any` 测试数组中的一个或多个值是否为 `True`，而 `all` 检查每个值是否为 `True`：
```python
In [208]: bools = np.array([False, False, True, False])

In [209]: bools.any()
Out[209]: True

In [210]: bools.all()
Out[210]: False
```

### 排序

与 Python 内置的列表类型类似，NumPy 数组可以通过 `sort` 方法进行原地排序：
```python
In [211]: arr = rng.standard_normal(6)

In [212]: arr
Out[212]: array([ 0.0773, -0.6839, -0.7208,  1.1206, -0.0548, -0.0824])

In [213]: arr.sort()

In [214]: arr
Out[214]: array([-0.7208, -0.6839, -0.0824, -0.0548,  0.0773,  1.1206])
```

`arr.sort(axis=0)` 对每列内的值进行排序，而 `arr.sort(axis=1)` 则在每行之间进行排序：
```python
In [215]: arr = rng.standard_normal((5, 3))

In [216]: arr
Out[216]: 
array([[ 0.936 ,  1.2385,  1.2728],
       [ 0.4059, -0.0503,  0.2893],
       [ 0.1793,  1.3975,  0.292 ],
       [ 0.6384, -0.0279,  1.3711],
       [-2.0528,  0.3805,  0.7554]])
       
In [217]: arr.sort(axis=0)

In [218]: arr
Out[218]: 
array([[-2.0528, -0.0503,  0.2893],
       [ 0.1793, -0.0279,  0.292 ],
       [ 0.4059,  0.3805,  0.7554],
       [ 0.6384,  1.2385,  1.2728],
       [ 0.936 ,  1.3975,  1.3711]])

In [219]: arr.sort(axis=1)

In [220]: arr
Out[220]: 
array([[-2.0528, -0.0503,  0.2893],
       [-0.0279,  0.1793,  0.292 ],
       [ 0.3805,  0.4059,  0.7554],
       [ 0.6384,  1.2385,  1.2728],
       [ 0.936 ,  1.3711,  1.3975]])
```

顶层方法`numpy.sort`返回的是数组的排序副本（类似Python内置函数`sorted`），而不是原地修改数组。例如：
```python
In [221]: arr2 = np.array([5, -10, 7, 1, 0, -3])

In [222]: sorted_arr2 = np.sort(arr2)

In [223]: sorted_arr2
Out[223]: array([-10,  -3,   0,   1,   5,   7])
```

### unique及其它集合逻辑

NumPy 有一些一维 ndarray 的基本集合运算。常用的数组是`numpy.unique`，它返回数组中排序的唯一值：
```python
In [224]: names = np.array(["Bob", "Will", "Joe", "Bob", "Will", "Joe", "Joe"])

In [225]: np.unique(names)
Out[225]: array(['Bob', 'Joe', 'Will'], dtype='<U4')

In [226]: ints = np.array([3, 3, 3, 2, 2, 1, 1, 4, 4])

In [227]: np.unique(ints)
Out[227]: array([1, 2, 3, 4])
```

另一个函数`numpy.in1d`测试一个数组值在另一个数组中的成员关系，返回一个布尔数组：

```python
In [229]: values = np.array([6, 0, 0, 3, 2, 5, 6])

In [230]: np.in1d(values, [2, 3, 6])
Out[230]: array([ True, False, False,  True,  True, False,  True])
```

|方法|描述|
|:--|:--|
|`unique(x)`|计算 `x` 中排序后的唯一元素|
|`intersect1d(x, y)`|计算 `x` 和 `y` 中排序后的公共元素|
|`union1d(x, y)`|计算元素的排序并集|
|`in1d(x, y)`|计算一个布尔数组，指示 `x` 中的每个元素是否包含在 `y` 中|
|`setdiff1d(x, y)`|集合差，`x` 中不在 `y` 中的元素|
|`setxor1d(x, y)`|集合对称差；在任一数组中但不同时在两个数组中的元素|
数组集合操作

|NumPy 函数|Python 内置 `set` 操作 (或相关方法)|说明|
|:--|:--|:--|
|`unique(x)`|`set(x)`|去重|
|`intersect1d(x, y)`|`set(x) & set(y)` 或 `set(x).intersection(y)`|交集|
|`union1d(x, y)`|`set(x) \| set(y)` 或 `set(x).union(y)`|并集|
|`in1d(x, y)`|`[item in set_y for item in x]`|成员测试（列表推导式）|
|`setdiff1d(x, y)`|`set(x) - set(y)` 或 `set(x).difference(y)`|差集|
|`setxor1d(x, y)`|`set(x) ^ set(y)` 或 `set(x).symmetric_difference(y)`|对称差集|
### 带数组的文件输入和输出

`numpy.save` 和 `numpy.load` 是高效保存和加载数组数据到磁盘上的两个主力函数。数组默认保存为未压缩的原始二进制格式，文件扩展名为 .npy：
```python
In [231]: arr = np.arange(10)

In [232]: np.save("some_array", arr)
```

如果文件路径结尾还没有 .npy，则会附加扩展名。磁盘上的阵列随后可以加载为`numpy.load`：
```python
In [233]: np.load("some_array.npy")
Out[233]: array([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
```

可以在未压缩的压缩档中保存多个数组，使用 `numpy.savez` 并将这些数组作为关键词参数传递：
```python
In [234]: np.savez("array_archive.npz", a=arr, b=arr)
```

加载 .npz 文件时，你会返回一个类似字典的对象，懒惰地加载各个数组：
```python
In [235]: arch = np.load("array_archive.npz")

In [236]: arch["b"]
Out[236]: array([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
```

如果你的数据压缩良好，建议使用`numpy.savez_compressed`：
```python
In [237]: np.savez_compressed("arrays_compressed.npz", a=arr, b=arr)
```

## 线性代数

略