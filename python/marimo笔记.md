# Marimo — 下一代 Python 交互式 Notebook

> 21.7k★ · Apache 2.0 · NumFOCUS · [marimo.io](https://marimo.io)
> 安装：`pip install marimo`

---

## 核心理念

**反应式 notebook**：改一个 cell，依赖它的所有 cell 自动重算。解决了 Jupyter 最烦人的"cell 顺序乱了报错"和"隐藏状态脏数据"问题。

---

## 快速入门

```bash
# 安装
pip install marimo

# 交互式教程（强烈推荐先跑这个）
marimo tutorial intro

# 新建 notebook
marimo edit

# 打开已有 notebook
marimo edit notebook.py

# 部署为 web app（隐藏代码）
marimo run notebook.py

# 从 Jupyter 迁移
marimo convert old.ipynb > new_notebook.py
```

---

## 和 Jupyter 的核心区别

| 对比 | Jupyter | Marimo |
|------|---------|--------|
| **执行方式** | 手动逐个执行 | **反应式**——改一个 cell，依赖者自动重算 |
| **隐藏状态** | 删 cell 变量还在内存 | 删 cell 自动清除变量 |
| **存储格式** | `.ipynb`（JSON，Git diff 灾难） | **`.py`**（纯 Python，可 diff、可测试、可 import） |
| **SQL 支持** | 需要 `%sql` magic | **内置 SQL cell** |
| **交互组件** | 需要 `ipywidgets` | **内置滑块/下拉框/表格**，绑定变量自动触发 |
| **导出脚本** | 麻烦（`jupyter nbconvert`） | 直接 `python notebook.py` |
| **测试** | 困难 | 支持 `pytest` |
| **部署** | 需要额外工具（voila） | `marimo run` 自带 |

---

## 基本用法

### Cell 操作

| 操作 | 快捷键 |
|------|--------|
| 新建 cell | `Ctrl+Shift+B` |
| 运行 cell | `Ctrl+Enter` |
| 运行并创建下一个 | `Shift+Enter` |
| 删除 cell | `Ctrl+Shift+D` |
| 上移/下移 | `Ctrl+Shift+↑/↓` |
| 合并/分割 | `Ctrl+Shift+M` / `Ctrl+Shift+S` |
| 格式化代码 | `Ctrl+Shift+F` |
| AI 修改 cell | `Ctrl+Shift+E` |

---

## 反应式编程

### 基本反应式

```python
# cell 1
x = 5

# cell 2（引用 x 的 cell 会自动运行）
y = x * 2
print(y)  # 改 x 为 10，这里自动输出 20
```

### Markdown 中嵌入变量

```python
# 用 mo.md 写动态 markdown
import marimo as mo

name = "TP53"
mo.md(f"## {name} 的表达分析")
```

### UI 组件绑定变量

```python
import marimo as mo

# 滑块值自动绑定到变量 threshold
threshold = mo.ui.slider(0.01, 0.05, step=0.005, label="p-value cutoff")

# 下拉框
gene = mo.ui.dropdown(["TP53", "BRCA1", "EGFR"], value="TP53", label="Gene")

# 显示组件（这行必须单独一个 cell）
threshold  # 显示滑块

gene       # 显示下拉框

# 下游 cell 引用 threshold 和 gene 的值
print(f"分析 {gene.value}，p < {threshold.value}")
```

### 全部 UI 组件

| 组件 | 用法 | 返回值（通过 `.value`） |
|------|------|------------------------|
| `mo.ui.slider(min, max, step)` | 滑块 | float |
| `mo.ui.text()` | 文本输入 | str |
| `mo.ui.number()` | 数字输入 | float |
| `mo.ui.dropdown(options)` | 下拉框 | str |
| `mo.ui.multiselect(options)` | 多选 | list |
| `mo.ui.checkbox()` | 复选框 | bool |
| `mo.ui.date()` | 日期选择 | str |
| `mo.ui.button()` | 按钮 | int（点击次数） |
| `mo.ui.dataframe(df)` | 可交互表格 | 筛选后的 DataFrame |
| `mo.ui.table(df)` | 只读表格 | 选中的行 |
| `mo.ui.plotly(fig)` | 交互式 plotly | — |
| `mo.ui.altair_chart(chart)` | 交互式 altair | 选中的数据点 |
| `mo.ui.chat()` | AI 聊天界面 | — |

### 交互式表格（非常实用）

```python
# 对百万行数据做筛选、排序，无需代码
mo.ui.dataframe(df)  # 直接在 cell 里显示
```

---

## SQL Cell

Marimo 内置 SQL 支持，可以直接查 DataFrame。

```python
# 先用 Python 加载数据
import pandas as pd
df = pd.read_csv("data.csv")
```

然后创建一个 **SQL cell**（在 marimo 编辑器里点 `+ SQL` 按钮创建），直接用 Python 变量：

```sql
-- 用 {} 引用 Python 变量
SELECT gene, log2fc, pvalue
FROM df
WHERE pvalue < 0.05
  AND abs(log2fc) > 1
ORDER BY abs(log2fc) DESC
```

SQL 支持的后端：

| 后端 | 说明 |
|------|------|
| **Pandas DataFrame** | 内存数据框，零配置 |
| **Polars DataFrame** | 同样支持 |
| **DuckDB** | `ATTACH 'database.db'` |
| **SQLite** | 内置 |
| **PostgreSQL** | 需配置连接 |
| **MySQL** | 需配置连接 |
| **CSV/Parquet** | 直接文件路径 |

---

## AI 辅助

### 配置 DeepSeek

1. 设置 → AI → LLM Provider → OpenAI-compatible
2. 填：

| 字段 | 值 |
|------|-----|
| **API URL** | `https://api.deepseek.com/v1` |
| **API Key** | 你的 key |
| **Model** | `deepseek-chat` |

### AI 功能

| 功能 | 触发方式 |
|------|----------|
| 生成 cell | 底部 "Generate with AI" 按钮 |
| 改 cell | `Ctrl+Shift+E` |
| 聊天面板 | 左侧 `💬` 图标 |
| 用 `@` 引用变量 | 在 prompt 里写 `@df` 传入 DataFrame |

### 自定义 AI 规则

设置里可以写规则，比如：

```
Use plotly for interactive visualizations and matplotlib for static plots
Use polars over pandas when possible
Include docstrings for all functions
```

---

## 配置

### 配置文件

`marimo.toml`（位置：`marimo config show | head` 查看）

```toml
[ai]
enabled = true

[ai.models]
completion_model = "deepseek/deepseek-chat"
```

### 常用 CLI 命令

```bash
marimo edit [file.py]        # 编辑 notebook
marimo run [file.py]         # 部署 web app（无代码编辑功能）
marimo new "分析 RNA-seq"    # 从提示词生成完整 notebook
marimo convert file.ipynb    # 从 Jupyter 转换
marimo tutorial [name]       # 启动教程
marimo config show           # 查看当前配置
```

---

## 部署与共享

```bash
# 方式一：在 notebook 目录运行，浏览器访问
marimo run notebook.py

# 方式二：生成 WASM HTML，离线可用
marimo export html notebook.py -o notebook.html
```

---

## VS Code / Cursor 集成

装扩展 `marimo-team.vscode-marimo`，然后：

```
命令面板 → marimo: New Notebook
```

或在 `.py` 文件上右键 → "Open with marimo"

---

## 从 Jupyter 迁移

```bash
# 转换整个目录
marimo convert jupyter_files/*.ipynb --output marimo_notebooks/

# 进入 marimo 编辑
marimo edit marimo_notebooks/my_notebook.py
```

---

## 最佳实践

1. **一个分析一个 notebook**——不要把所有东西塞进一个超大 notebook
2. **UI 组件单独一个 cell**——方便调试和复用
3. **SQL 和 Python 分 cell**——marimo 的 SQL cell 会自动把结果存入变量
4. **用 `@` 传递变量给 AI**——让 AI 知道你的 DataFrame 有哪些列
5. **大规模数据用延迟模式**——设置中开启 `lazy`，昂贵的 cell 标记为 stale 而不是自动重算
6. **用 pytest 测试 notebook**——marimo 文件是 `.py`，可以直接 `pytest` 测试里面的函数

---

## 常见问题

### 反应式循环依赖？

Marimo 会自动检测循环依赖并报错，不会死循环。

### 需要 GPU？

Marimo 支持在 GPU 机器上运行，也可以部署在云端。

### 和 Streamlit 比？

Marimo 是 notebook，Streamlit 是仪表盘工具。Marimo 更偏向分析和探索，Streamlit 更偏向部署。

### 可以多人协作吗？

Marimo 文件是 `.py`，用 Git 管理，和普通代码一样的协作流程。
