---
lang: Python
date: 2026-04-07
tags:
  - 数据分析
---
## Pandas 字符串方法（`Series.str`）完整对照表

| 方法                | 描述                                                       |
| ----------------- | -------------------------------------------------------- |
| **cat**           | **拼接**字符串，可指定分隔符，逐元素连接                                   |
| **contains**      | 检查每个字符串是否**包含**指定模式/正则表达式，返回布尔数组                         |
| **count**         | 统计**模式/子串出现的次数**                                         |
| **extract**       | 使用**带分组的正则表达式**从字符串中提取一个或多个子串；结果为 DataFrame，**每列对应一个分组** |
| **endswith**      | 等价于对每个元素调用 `x.endswith(pattern)`，检查是否以某后缀**结尾**          |
| **startswith**    | 等价于对每个元素调用 `x.startswith(pattern)`，检查是否以某前缀**开头**        |
| **findall**       | 计算每个字符串中**所有**匹配模式/正则的**出现列表**                           |
| **get**           | 对每个元素进行**索引取值**（获取第 i 个字符）                               |
| **isalnum**       | 等价于内置 `str.isalnum`，判断是否全为字母或数字                          |
| **isalpha**       | 等价于内置 `str.isalpha`，判断是否全为字母                             |
| **isdecimal**     | 等价于内置 `str.isdecimal`，判断是否全为十进制数字                        |
| **isdigit**       | 等价于内置 `str.isdigit`，判断是否全为数字                             |
| **islower**       | 等价于内置 `str.islower`，判断是否全为小写字母                           |
| **isnumeric**     | 等价于内置 `str.isnumeric`，判断是否全为数字字符（含中文数字等）                 |
| **isupper**       | 等价于内置 `str.isupper`，判断是否全为大写字母                           |
| **join**          | 用传入的分隔符**连接** Series 中每个元素内的字符串列表                        |
| **len**           | 计算每个字符串的**长度**                                           |
| **lower / upper** | **大小写转换**；等价于对每个元素调用 `x.lower()` 或 `x.upper()`           |
| **match**         | 对每个元素使用 `re.match` 进行正则匹配，返回 **True/False** 表示是否匹配       |
| **pad**           | 在字符串的**左侧、右侧或两侧添加空白字符**（填充）                              |
| **center**        | 等价于 `pad(side="both")`，**居中对齐**填充                        |
| **repeat**        | **重复**字符串值（如 `s.str.repeat(3)` 等价于每个字符串 `x * 3`）         |
| **replace**       | 将模式/正则的匹配项**替换**为另一个字符串                                  |
| **slice**         | 对 Series 中的每个字符串进行**切片**操作                               |
| **split**         | 按分隔符或正则**拆分**字符串                                         |
| **strip**         | 去除两侧的**空白字符**（含换行符）                                      |
| **rstrip**        | 去除**右侧**的空白字符                                            |
| **lstrip**        | 去除**左侧**的空白字符                                            |

---

### 快速分类记忆

```python
import pandas as pd
s = pd.Series(["Hello World", "Python 3.0", "  Pandas  "])

# ====== 判断类 (返回 bool) ======
s.str.contains('P')        # 是否包含
s.str.startswith('H')      # 是否以...开头
s.str.endswith('0')        # 是否以...结尾
s.str.match(r'\w+')        # 正则匹配
s.str.isnumeric()          # 是否为数字
s.str.islower()            # 是否全小写

# ====== 查找/提取类 ======
s.str.find('o')            # 查找位置（注意：pandas 用 findall 更常用）
s.str.findall(r'\w+')      # 找所有匹配 → 列表
s.str.extract(r'(\w+)\s(\w+)')  # 正则提取分组 → DataFrame
s.str.get(0)               # 取第 i 个字符

# ====== 转换/修改类 ======
s.str.lower()              # 转小写
s.str.upper()              # 转大写
s.str.strip()              # 去两边空格
s.str.replace('o', '0')    # 替换
s.str.repeat(2)            # 重复
s.str.slice(0, 5)          # 切片

# ====== 拆分/合并类 ======
s.str.split()              # 拆分为列表
s.str.cat(sep=',')         # 合并为一个字符串
s.str.join('-')            # 连接元素内各字符

# ====== 信息类 ======
s.str.len()                # 长度
s.str.count('l')           # 计数
```