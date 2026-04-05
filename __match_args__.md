---
lang: Python
date: 2026-04-02
tags:
  - 编程
---
`__match_args__` 是 Python 3.10 引入结构化模式匹配（`match...case` 语句）时新增的一个特殊类属性。

简单来说，它的作用是**定义类的“位置解构规则”**。它告诉 Python 解释器：当使用 `match` 语句对这个类的实例进行**位置参数匹配**时，应该按什么顺序去提取属性。

### 🤔 为什么需要它？

在没有 `match` 语句之前，我们提取对象属性通常是用 `obj.x` 或 `obj.y`。但在 `match` 语句中，我们希望能像解包列表或元组一样，直接通过位置来匹配和捕获变量。

如果没有 `__match_args__`，Python 就不知道你的类应该按什么顺序对应位置参数。

### 🛠️ 基本用法

`__match_args__` 必须是一个**元组**，里面包含属性名的字符串。

假设我们有一个 `Point` 类：

```python
class Point:
    # 1. 定义匹配顺序：第一个位置对应 x，第二个对应 y
    __match_args__ = ('x', 'y')

    def __init__(self, x, y):
        self.x = x
        self.y = y

p = Point(1, 2)
```

现在，我们可以在 `match` 语句中使用**位置模式**了：

```python
match p:
    # 这里的 Point(0, 0) 会自动去比对 p.x == 0 和 p.y == 0
    case Point(0, 0):
        print("原点")
        
    # 这里的 x 会被自动捕获并赋值为 p.x 的值
    case Point(x, 0):
        print(f"X轴上的点，x={x}")
        
    # 这里的 x 和 y 都会被捕获
    case Point(x, y):
        print(f"普通点：({x}, {y})")
```

**如果没有 `__match_args__ = ('x', 'y')`**，上面的 `case Point(x, 0):` 会直接报错或匹配失败，因为 Python 不知道 `Point` 括号里的第一个参数是指 `x` 属性。

### 💡 进阶：位置模式 vs 关键字模式

`__match_args__` 只影响**位置参数**的写法。即使不定义它，你依然可以使用**关键字参数**来匹配，只是代码会写得长一点。

|特性|位置模式 (需要 `__match_args__`)|关键字模式 (无需 `__match_args__`)|
|:--|:--|:--|
|**写法**|`case Point(x, 0):`|`case Point(x=x, y=0):`|
|**可读性**|⭐⭐⭐⭐⭐ (简洁)|⭐⭐⭐ (啰嗦)|
|**依赖**|依赖类定义中的 `__match_args__`|不依赖，直接匹配属性名|

### 🌟 最佳搭档：`@dataclass`

如果你使用 Python 的 `@dataclass` 装饰器，通常**不需要**手动写 `__match_args__`。

`@dataclass` 会自动根据 `__init__` 参数的顺序，帮你生成 `__match_args__`。

```python
from dataclasses import dataclass

@dataclass
class Point:
    x: int
    y: int

# 即使没写 __match_args__，下面也能直接跑
p = Point(10, 20)

match p:
    case Point(x, y): # 自动支持位置解构
        print(x, y)
```

### 📌 总结

- **作用**：让自定义类支持像元组那样，用 `ClassName(a, b)` 的方式在 `match` 语句中进行解构。
- **格式**：`__match_args__ = ('属性1', '属性2')`。
- **本质**：它建立了“位置索引”到“属性名”的映射关系。