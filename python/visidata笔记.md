# VisiData — 终端里的 Excel

> 官网：https://www.visidata.org
> 安装：`pip install visidata`
> 许可证：GPLv3

---

## 是什么

VisiData 是在终端里浏览和操作表格数据的工具。它把 Excel 的直观和命令行的效率结合在一起，可以处理**百万行级别**的数据。

你不需要打开 Excel 或写 Python 代码，就能快速看一个 CSV 文件长什么样、做些简单统计和筛选。

```bash
vd data.csv    # 在终端里打开 CSV，像 Excel 一样浏览
```

---

## 快速入门（5 分钟上手）

### 安装

```bash
pip install visidata
```

### 打开文件

```bash
# 最基本的用法
vd data.csv

# 支持几十种格式
vd data.tsv           # 制表符分隔
vd data.json          # JSON
vd data.xlsx          # Excel
vd data.db            # SQLite 数据库
vd data.parquet       # Parquet（大数据格式）
vd .                  # 浏览目录（文件管理器模式）

# 从管道输入
ps aux | vd
cat data.csv | vd -f csv

# 一次打开多个文件切换查看
vd file1.csv file2.csv file3.csv
```

**支持的文件格式**：CSV、TSV、JSON、Excel、SQLite、Parquet、HTML 表格、YAML、HDF5、NumPy、Shapefile、Stata/SAS/SPSS、压缩包、pcap 网络包、甚至 PDF（文本部分）。

---

## 界面布局

打开文件后，你会看到：

```
┌─ gene_expression.csv ──────────────────────────────────────┐
│ Gene       log2FC     pvalue     padj        significant   │
│ ─────────────────────────────────────────────────────────── │
│ TP53       -2.34      0.001      0.012       True          │
│ BRCA1       1.56      0.008      0.045       True          │
│ EGFR       -0.45      0.230      0.480       False         │
│ KRAS        2.10      0.0003     0.005       True          │
│   ↓                                                       │
│ [2438 rows]                                               │
├─ 底部状态栏 ───────────────────────────────────────────────┤
│ gene_expression.csv │ 4/2438 rows │ Gene: ↑               │
└───────────────────────────────────────────────────────────┘
```

- 顶部：列名（灰色高亮）
- 中间：数据区域，滚动浏览
- 底部状态栏：当前文件、行数、当前列名

---

## 导航快捷键（Vim 风格）

| 按键 | 操作 |
|------|------|
| `↓` `j` | 向下移动一行 |
| `↑` `k` | 向上移动一行 |
| `→` `l` | 向右移动一列 |
| `←` `h` | 向左移动一列 |
| `PgDn` `Ctrl+F` | 向下翻页 |
| `PgUp` `Ctrl+B` | 向上翻页 |
| `Home` `g` | 跳到第一行 |
| `End` `G` | 跳到最后一行 |
| `gh` `gl` | 跳到最左/最右列 |
| `gj` `gk` | 跳到最底/最顶行 |
| `Tab` | 切换到下一个 sheet（如果有多个） |

---

## 搜索

| 按键 | 操作 |
|------|------|
| `/` 关键词 | 在当前列向前搜索 |
| `?` 关键词 | 在当前列向后搜索 |
| `g/` | 在所有列搜索 |
| `n` | 下一个匹配 |
| `N` | 上一个匹配 |
| `z/` Python表达式 | 用 Python 条件搜索（如 `pvalue < 0.05`） |

**搜索示例**：

```
/TP53          ← 找到 TP53 所在行
z/ pvalue < 0.05  ← 用 Python 条件搜索（列名作为变量）
```

---

## 基本操作

### 选择行（选中后批量操作）

| 按键 | 操作 |
|------|------|
| `s` | 选中当前行 |
| `t` | 切换选中/取消当前行 |
| `u` | 取消选中当前行 |
| `gs` | 选中所有行 |
| `gu` | 取消所有选中 |
| `|` 正则 | 选中当前列匹配正则的行 |
| `g|` 正则 | 选中所有列匹配正则的行 |
| `,` | 选中当前单元格值相同的所有行 |
| `z|` 表达式 | 用 Python 条件选中（如 `pvalue < 0.05`） |

### 筛选出选中的行

选中行后：

| 按键 | 操作 |
|------|------|
| `"` | 创建新 sheet，只包含选中的行（常用！） |
| `gd` | 删除选中的行 |
| `Enter` | 展开选中行（如查看分组详情） |

### 排序

| 按键 | 操作 |
|------|------|
| `[` | 按当前列升序排序 |
| `]` | 按当前列降序排序 |
| `z[` / `z]` | 在已有排序基础上追加排序条件 |
| `!` | 把当前列设为"关键列"（分组用） |

### 隐藏/显示列

| 按键 | 操作 |
|------|------|
| `-`（减号） | 隐藏当前列 |
| `gv` | 显示所有隐藏的列 |

### 打开/关闭其他界面

| 按键 | 操作 |
|------|------|
| `q` | 关闭当前 sheet / 返回上一级 |
| `Ctrl+^` | 跳到上一个 sheet（不关闭当前） |
| `Shift+S` | 查看所有打开的 sheet 列表 |
| `Ctrl+H` | 查看帮助（所有快捷键） |

---

## 数据类型

VisiData 默认把所有值当字符串。要正确处理数值、日期等，需要先设类型：

| 按键 | 类型 | 说明 |
|------|------|------|
| `~` | string | 文本（默认，不用设） |
| `#` | int | 整数（切换到此列后按） |
| `%` | float | 小数 |
| `$` | currency | 货币（过滤非数字字符） |
| `@` | date | 日期 |

```bash
# 操作流程：
# 1. 移到 pvalue 列
# 2. 按 % 设成浮点数
# 3. 按 [ 排序，从大到小看显著性
```

---

## 统计和分组

### 实时聚合统计

在列上按 `+` 加聚合函数，底部会显示整列的计算结果：

```bash
# 移到 log2FC 列
+ avg    → 底部显示平均值
+ min    → 显示最小值
+ max    → 显示最大值
+ sum    → 显示总和
+ count  → 计数
+ stdev  → 标准差
+ median → 中位数
+ distinct → 去重数
```

### 频次表（类似 Excel 的透视表）

移到某一列，按 `Shift+F`：

```bash
# 移到 condition 列
Shift+F  → 显示每个条件出现的次数
```

会打开一个新 sheet，显示：

```
│ condition │ count │
│ Control   │  120  │
│ Treatment │  120  │
```

### 描述性统计

按 `Shift+I` 打开 Describe sheet，显示当前数据集的概览：

```
│ Column          │ type │ count │ nulls │ min     │ max     │ mean    │
│ ────────────────────────────────────────────────────────────────── │
│ log2FC          │ float│ 2438  │  12   │ -5.23   │ 6.45    │ 0.23   │
│ pvalue          │ float│ 2438  │   0   │ 0.00003 │ 0.95    │ 0.12   │
│ significant     │ bool │ 2438  │   0   │         │         │        │
```

---

## 用 Python 表达式创建新列

这是 VisiData 最强的功能——按 `=` 输入 Python 表达式创建新列：

```bash
# 移到 log2FC 列
= abs(log2FC)          → 新建列，值为 log2FC 的绝对值
= log2FC > 1           → 新建列，判断是否为显著差异
= -log10(pvalue)       → 新建列，计算 -log10(p值)
= pvalue < 0.05        → 新建列，显示 True/False
```

表达式中可以直接用列名当变量名。`Tab` 键自动补全列名。

---

## 生信场景实战

### 场景 1：快速查看 DEG 结果

```bash
vd deg_results.csv
```

1. 移到 `pvalue` 列按 `%` 设浮点数
2. 移到 `log2FC` 列按 `%` 设浮点数
3. 按 `[` 排序看哪些基因上调最多
4. 按 `]` 看哪些基因下调最多
5. 选中 | 输入 `pvalue < 0.05` → `s` 选中
6. `"` 新建一个只含显著基因的 sheet

### 场景 2：基因表达相关性快速查看

```bash
vd expression_matrix.csv
```

1. 按 `Shift+I` 看描述统计
2. 按 `z/` 输入 `gene == 'TP53'` 定位特定基因
3. 用 `,` 选中同一行所有值？不行——`g,` 选中当前整行

### 场景 3：多文件切换

```bash
vd deg_results.csv sample_info.csv pathway_enrichment.csv
```

`Tab` 键在三个文件之间切换查看。

---

## 转换格式

无需打开文件即可转换格式：

```bash
# CSV → TSV 转换（-b 是批量模式，不进入交互界面）
vd -b data.csv -o data.tsv

# CSV → JSON
vd -b data.csv -o data.json

# Excel → CSV
vd -b data.xlsx -o data.csv

# JSON → TSV
vd -b data.json -o data.tsv
```

---

## 批量模式（不进入交互界面）

```bash
# 执行命令后自动退出
vd -b data.csv -c "select-col 'pvalue < 0.05' && open-selected"
```

---

## VS Code 集成

VS Code 扩展市场搜 **VisiData**，安装后可以在 VS Code 终端里直接使用 `vd`。

---

## 常用操作速查表

| 想做什么 | 按键 |
|---------|------|
| 打开文件 | `vd file.csv` |
| 退出 | `q` |
| 上下左右 | `j` `k` `h` `l` |
| 搜索 | `/` 关键词 |
| 按 Python 条件搜索 | `z/` 表达式 |
| 选当前行 | `s` |
| 取消选择 | `u` |
| 只看选中的行 | `"` |
| 排序升序/降序 | `[` `]` |
| 设数值类型 | `#` 整数, `%` 浮点, `@` 日期 |
| 加聚合统计 | `+ sum` / `+ avg` / `+ count` |
| 频次表 | `Shift+F` |
| 描述统计 | `Shift+I` |
| 隐藏列 | `-` |
| 显示所有列 | `gv` |
| 创建新列（Python） | `=` 表达式 |
| 切换到其他 sheet | `Tab` |
| 查看所有 sheet | `Shift+S` |
| 保存 | `Ctrl+S` |
| 撤销 | `Ctrl+Z` |

---

## 跟 pandas 对比

| 场景 | pandas | VisiData |
|------|--------|----------|
| 快速看一个 CSV 长什么样 | `df.head()` | `vd file.csv` |
| 简单筛选 | `df[df.pvalue < 0.05]` | `z/ pvalue < 0.05` → `"` |
| 分组计数 | `df.groupby('gene').count()` | `Shift+F` |
| 描述统计 | `df.describe()` | `Shift+I` |
| 格式转换 | `df.to_json()` | `vd -b file.csv -o file.json` |
| 百万行数据 | 可能内存不够 | 轻松处理 |
| 深入学习曲线 | 中等 | 半小时 |

**适用场景**：数据量不大、只是想快速看一眼、做简单探索性分析时，VisiData 比写 pandas 代码快得多。需要复杂分析时再切回 Python/pandas。
