---
lang: Python
date: 2026-04-01
tags:
  - 编程
---
在 Python 中，`@property` 装饰器是一个非常强大的工具，它的核心作用是**将类的方法伪装成属性**，让你能够像访问普通属性一样访问方法，同时还能在背后执行逻辑（如数据验证、计算等）。

简单来说，它让你在保持代码简洁（像访问变量一样）的同时，拥有了对数据控制的“上帝视角”。

以下是 `@property` 的主要作用和应用场景：

### 1. 数据验证（保护数据安全）

这是 `@property` 最常见的用途。通过定义 setter 方法，你可以在给属性赋值时进行检查，防止无效数据被存入。

- **作用**：确保属性值符合特定规则（如年龄不能为负数，邮箱必须包含 @ 等）。
- **效果**：如果赋值不合法，直接抛出异常，阻断错误发生。

```python
class Person:
    def __init__(self, name):
        self._name = name  # 内部私有属性

    @property
    def name(self):
        return self._name

    @name.setter
    def name(self, value):
        if not isinstance(value, str) or len(value) == 0:
            raise ValueError("名字不能为空")
        self._name = value

p = Person("Alice")
p.name = "Bob"  # ✅ 合法，赋值成功
# p.name = ""   # ❌ 报错：ValueError: 名字不能为空
```

### 2. 计算属性（动态生成数据）

有些数据不是固定存储的，而是需要根据其他属性实时计算得出的。使用 `@property` 可以让这些计算逻辑看起来像普通的属性访问。

- **作用**：将需要计算的方法转换为只读属性。
- **效果**：调用时不需要加括号 `()`，代码更易读，且每次访问都会获取最新的计算结果。

```python
class Circle:
    def __init__(self, radius):
        self.radius = radius

    @property
    def area(self):
        # 每次访问 area 时实时计算
        return 3.14159 * self.radius ** 2

c = Circle(10)
print(c.area)  # ✅ 像访问属性一样获取面积，输出 314.159...
```

### 3. 实现只读属性

如果你希望某个属性在对象创建后就不能被修改，可以只定义 getter 方法，而不定义 setter 方法。

- **作用**：锁定属性，防止外部代码意外修改。
- **效果**：尝试赋值时会抛出 `AttributeError`。

```python
class User:
    def __init__(self, user_id):
        self._user_id = user_id

    @property
    def user_id(self):
        return self._user_id

u = User("12345")
print(u.user_id)  # ✅ 可以读取
# u.user_id = "999" # ❌ 报错：AttributeError: can't set attribute
```

### 4. 延迟加载（优化性能）

对于耗时操作（如读取大文件、查询数据库），你可以利用 `@property` 实现“懒加载”。即：只有当第一次访问该属性时才执行加载操作，之后将结果缓存起来。

- **作用**：避免在对象初始化时执行不必要的耗时任务。
- **效果**：提高程序启动速度，按需加载数据。

```python
class DataHandler:
    def __init__(self):
        self._data = None

    @property
    def data(self):
        if self._data is None:
            print("正在从数据库加载大量数据...")
            # 模拟耗时操作
            self._data = "加载完成的数据"
        return self._data

dh = DataHandler()
# 此时并没有加载数据
print(dh.data)  # 第一次访问：打印提示并加载
print(dh.data)  # 第二次访问：直接返回缓存，不打印提示
```

### 总结：为什么要用 @property？

|特性|传统方法 (get_xxx / set_xxx)|使用 @property|
|:--|:--|:--|
|**调用方式**|`obj.get_xxx()` / `obj.set_xxx(val)`|`obj.xxx` / `obj.xxx = val`|
|**代码可读性**|较差，像在执行动作|**极佳**，像在操作数据|
|**封装性**|暴露了内部实现细节|**高**，隐藏了内部逻辑|
|**接口维护**|修改实现需要改接口|**无需修改接口**，平滑升级|

**一句话总结**：`@property` 让你既能享受直接访问属性的便捷语法，又能拥有方法调用的逻辑控制能力，是 Python 面向对象编程中实现**封装**的最佳实践。