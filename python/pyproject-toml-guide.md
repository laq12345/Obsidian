# pyproject.toml 完全指南

> pyproject.toml 是 Python 项目的"身份证 + 购物清单 + 说明书"。
> 从 Python 3.11 开始，所有 Python 项目都应该用这个文件。

---

## 目录

1. [它解决什么问题](#1-它解决什么问题)
2. [一个最小的 pyproject.toml](#2-一个最小的-pyprojecttoml)
3. [完整的字段逐个讲](#3-完整的字段逐个讲)
4. [三种常见场景的完整示例](#4-三种常见场景的完整示例)
5. [配置速查表](#5-配置速查表)
6. [常见问题](#6-常见问题)

---

## 1. 它解决什么问题

在 pyproject.toml 出现之前，Python 项目有 **N 种配置文件**：

- `setup.py` — 最老的，用 Python 代码写，很灵活但也容易写坑
- `setup.cfg` — 用 INI 格式写，比 setup.py 好点
- `requirements.txt` — 只写依赖，不写项目信息
- `Pipfile` / `Pipfile.lock` — pipenv 用的
- `MANIFEST.in` — 控制哪些文件打进包

**一团乱麻。** 新人学 Python 项目配置，光搞清楚该用哪个文件就懵了。

**pyproject.toml 一统天下：** 从此只需要一个文件，所有工具（pixi、pip、build、pytest、ruff...）都读这一个文件。

---

## 2. 一个最小的 pyproject.toml

```toml
[project]
name = "my-project"
version = "0.1.0"
dependencies = []
```

就这三行就够了。但实际项目中至少还会加上：

```toml
[project]
name = "my-project"
version = "0.1.0"
description = "我的项目"
requires-python = ">= 3.11"
dependencies = [
    "typer>=0.12",
]
```

---

## 3. 完整的字段逐个讲

### 3.1 `[project]` — 项目基本信息

```toml
[project]
name = "my-project"               # 项目名（必填）
version = "0.1.0"                 # 版本号（必填）
description = "一个 CLI 工具"      # 一句话描述
readme = "README.md"              # 项目说明文件
requires-python = ">= 3.11"       # 最低 Python 版本
license = {text = "MIT"}          # 许可证
authors = [                       # 作者
    {name = "Your Name", email = "you@example.com"},
]
dependencies = []                 # 依赖的第三方库（见下节）
```

#### name（必填）

```toml
name = "my-project"       # 只能用字母、数字、横线、下划线
name = "detect_encoding"  # 文件名里下划线常见
name = "mycli"            # 简单最好
```

规则：
- 只能用 `a-z`、`0-9`、`-`、`_`
- 区分大小写
- 不能以横线开头或结尾
- 不能和 PyPI 上已有的包重名（如果你要发布的话）

#### version（必填）

```toml
version = "0.1.0"    # 主版本.次版本.补丁
```

版本号规则（语义化版本）：`主版本.次版本.补丁`

| 版本变化 | 什么时候改 | 例子 |
|---------|-----------|------|
| 补丁 | 修了 bug，功能没变 | 0.1.0 → 0.1.1 |
| 次版本 | 加了新功能，但向后兼容 | 0.1.0 → 0.2.0 |
| 主版本 | 大改，不兼容旧版 | 0.1.0 → 1.0.0 |

#### dependencies — 依赖的第三方库

```toml
dependencies = [
    "typer>=0.12",          # 最低版本
    "rich>=13.0,<14",       # 版本范围
    "pandas",               # 随便什么版本
    "numpy>=1.24,<=2.0",    # 包两边
    "ruff>=0.1,!=0.3.0",    # 排除某个版本
]
```

版本号的写法规则：

| 写法 | 意思 |
|------|------|
| `typer` | 随便什么版本 |
| `typer>=0.12` | 最低 0.12，更高也行 |
| `typer>=0.12,<0.13` | 只能在 0.12.x 范围内 |
| `typer>=0.12,<=0.15` | 0.12 到 0.15 之间 |
| `typer==0.12` | **必须** 0.12，不能高不能低 |
| `typer!=0.12.3` | 除了这个版本其他都行 |

**建议**：写 `>=` 下限，不要锁死上限（除非你知道为什么需要），这样兼容性好。

#### requires-python — 最低 Python 版本

```toml
requires-python = ">= 3.11"    # 常见
requires-python = ">= 3.10"    # 如果你的项目需要 3.10+ 的特性
requires-python = ">= 3.9"     # 最老支持到 3.9
```

写法规则和依赖版本一样。

---

### 3.2 `[project.scripts]` — CLI 入口（重点）

这是把 Python 代码变成**系统命令**的关键：

```toml
[project.scripts]
# 格式: 命令名 = "包名.文件名:变量名"
mycli = "mycli.main:app"
```

对应关系：

```
你在终端敲的 ↓            Python 代码里的 ↓          Python 文件里的 ↓
mycli         =         mycli.main        :        app
                        ↑                           ↑
                    (= src/mycli/main.py)        (= typer.Typer() 或 def main)
```

**两种模式的具体写法：**

```toml
# 模式一：多命令（app = typer.Typer() + @app.command()）
# 用户: mycli hello Camila
[project.scripts]
mycli = "mycli.main:app"

# 模式二：单命令（def main() + typer.run(main)）
# 用户: mycli Camila
[project.scripts]
mycli = "mycli.main:main"
```

文件名对应关系：

```toml
mycli = "mycli.main:app"
         ↑       ↑
      包名    文件名（不加.py）

# 如果代码在 mycli/cli.py 里：
mycli = "mycli.cli:app"

# 如果代码在 mycli/tools/run.py 里：
mycli = "mycli.tools.run:app"
```

---

### 3.3 `[build-system]` — 构建工具

告诉 pip：**用什么工具来打包你的代码**。

```toml
[build-system]
requires = ["hatchling"]        # 构建工具需要什么库
build-backend = "hatchling.build"  # 用哪个工具来构建
```

常见的构建工具：

| 工具 | 适用场景 | 写法 |
|------|---------|------|
| **hatchling** | pixi 默认，现代轻量 | `build-backend = "hatchling.build"` |
| **setuptools** | 最老牌，兼容性好 | `build-backend = "setuptools.build_meta"` |
| **flit_core** | 纯 Python 包，简单 | `build-backend = "flit_core.buildapi"` |
| **pdm-backend** | PDM 项目用 | `build-backend = "pdm.backend"` |

**如果你用 pixi init，默认就是 hatchling，不需要改它。**

### 3.4 `[tool.xxx]` — 各类工具的配置

`pyproject.toml` 的优点是：**所有工具的配置都写在一个文件里**，不用每个工具单独一个配置文件。

```toml
# ── pixi 配置 ──────────────────────────────────────────────
[tool.pixi.workspace]
channels = ["conda-forge"]
platforms = ["linux-64"]

[tool.pixi.dependencies]
typer = ">=0.26.7"

[tool.pixi.tasks]

# ── pytest 配置 ─────────────────────────────────────────────
[tool.pytest.ini_options]
testpaths = ["tests"]

# ── ruff 配置（Python 代码格式化/检查） ─────────────────────
[tool.ruff]
line-length = 100

[tool.ruff.format]
quote-style = "double"

# ── setuptools 配置（如果用 src/ 目录） ─────────────────────
[tool.setuptools.packages.find]
where = ["src"]
```

---

### 3.5 关于 src/ 目录结构

有两种常见的项目结构：

```
# 结构一：平铺（简单项目用）
my-project/
├── pyproject.toml
└── mycli/
    ├── __init__.py
    └── main.py

# 结构二：src 布局（大型项目推荐）
my-project/
├── pyproject.toml
└── src/
    └── mycli/
        ├── __init__.py
        └── main.py
```

如果用 src 布局，需要告诉构建工具去哪里找包。

**使用 hatchling 时：**

```toml
[tool.hatch.build.targets.wheel]
packages = ["src/mycli"]
```

**使用 setuptools 时：**

```toml
[tool.setuptools.packages.find]
where = ["src"]
```

**使用 pixi 时**：pixi 自己知道 `src/` 在哪，不需要额外配置。但如果你要 `pip install` 这个包，就必须加上面配置之一。

### 3.6 `[tool.pixi.***]`

这是 pixi 自动生成的配置段。你的 `detect_encoding` 项目里是：

```toml
[tool.pixi.***]
detect_encoding = { path = ".", editable = true }
```

这行的意思：把当前目录下的项目（`.`）以可编辑模式（`editable = true`）安装到 pixi 环境里。效果等同于 `pip install -e .`，但由 pixi 管理，更干净。

---

## 4. 三种常见场景的完整示例

### 场景一：简单的脚本项目（用 pixi 管理）

```toml
[project]
name = "my-script"
version = "0.1.0"
description = "一个简单的脚本"
requires-python = ">= 3.11"
dependencies = []

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.pixi.workspace]
channels = ["conda-forge"]
platforms = ["linux-64"]

[tool.pixi.dependencies]
python = ">=3.11"
```

### 场景二：CLI 工具（多命令，用 Typer）

```toml
[project]
name = "mycli"
version = "0.1.0"
description = "一个 CLI 工具"
requires-python = ">= 3.11"
dependencies = [
    "typer>=0.12",
    "rich>=13",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project.scripts]
mycli = "mycli.main:app"

[tool.pixi.workspace]
channels = ["conda-forge"]
platforms = ["linux-64"]

[tool.pixi.dependencies]
typer = ">=0.12"
rich = ">=13"

[tool.pixi.***]
mycli = { path = ".", editable = true }

[tool.pixi.tasks]
test = "pytest tests/ -v"
run-hello = "mycli hello Camila"
```

### 场景三：要发布到 PyPI 的项目

```toml
[project]
name = "mycli"
version = "0.1.0"
description = "我的 CLI 工具"
readme = "README.md"
requires-python = ">= 3.10"
license = {text = "MIT"}
authors = [
    {name = "Your Name", email = "you@example.com"},
]
dependencies = [
    "typer>=0.12",
]

[project.urls]
Homepage = "https://github.com/you/mycli"
Repository = "https://github.com/you/mycli.git"

[project.scripts]
mycli = "mycli.main:app"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["src/mycli"]
```

---

## 5. 配置速查表

### 必填字段

| 字段 | 说明 | 例子 |
|------|------|------|
| `[project]` | 项目信息段 | — |
| `name` | 项目名 | `"mycli"` |
| `version` | 版本号 | `"0.1.0"` |
| `dependencies` | 依赖列表 | `["typer>=0.12"]` |

### 常用可选字段

| 字段 | 说明 | 例子 |
|------|------|------|
| `description` | 一句话描述 | `"一个 CLI 工具"` |
| `requires-python` | 最低 Python 版本 | `">= 3.11"` |
| `authors` | 作者信息 | `[{name="你"}]` |
| `license` | 许可证 | `{text = "MIT"}` |
| `readme` | 说明文档 | `"README.md"` |
| `[project.scripts]` | CLI 入口 | `mycli = "mycli.main:app"` |

### 常用 tool 段

| 段 | 用途 | 由谁生成 |
|----|------|---------|
| `[build-system]` | 打包工具配置 | 必须手动写 |
| `[tool.pixi.workspace]` | pixi 项目配置 | `pixi init` 自动生成 |
| `[tool.pixi.dependencies]` | pixi 管理的依赖 | `pixi add` 自动生成 |
| `[tool.pixi.tasks]` | pixi 任务 | 手动 |
| `[tool.pixi.***]` | 本地包安装 | `pixi init` 自动生成 |
| `[tool.pytest.ini_options]` | pytest 配置 | 手动 |
| `[tool.ruff]` | ruff 格式化配置 | 手动 |
| `[tool.hatch.build.targets.wheel]` | hatchling 打包配置 | 手动（src 布局时需要） |
| `[tool.setuptools.packages.find]` | setuptools 打包配置 | 手动（src 布局时需要） |

---

## 6. 常见问题

### Q：什么时候需要手动改 pyproject.toml？

| 场景 | 改什么 |
|------|--------|
| 加一个新依赖 | 运行 `pixi add 包名`（自动改） |
| 删除一个依赖 | 运行 `pixi remove 包名`（自动改） |
| 定义 CLI 命令 | 加 `[project.scripts]` |
| 改项目名 | 改 `name` 字段 |
| 升版本号 | 改 `version` 字段 |
| 配置测试路径 | 加 `[tool.pytest.ini_options]` |
| 配置格式化风格 | 加 `[tool.ruff]` |

### Q：我看到的 pyproject.toml 和教程里写的不一样？

正常。不同工具生成的 pyproject.toml 会有差异：

- `pixi init` → 生成 pixi 相关的 `[tool.pixi.*]`
- `pip install` 的模板 → 不带 `[tool.pixi.*]`
- 别人手动写的 → 可能只保留了必要的字段

核心是 `[project]` 和 `[build-system]`，其他都是可选的。

### Q：pyproject.toml 和 requirements.txt 什么关系？

| 文件 | 区别 |
|------|------|
| `pyproject.toml` | 项目的"元数据"——叫什么、谁写的、依赖什么、CLI 入口在哪 |
| `requirements.txt` | 纯依赖列表（通常用 `pip freeze > requirements.txt` 生成） |

**用 pixi 的项目不需要 requirements.txt**，pixi 直接从 pyproject.toml 读依赖。

### Q：version 是手动改还是自动改？

手动改。你可以在 pyproject.toml 里直接写 `version = "0.2.0"`。

### Q：`[tool.pixi.***]` 里面的星号是真的星号吗？

不是。这是你在终端里看到的显示问题，实际文件里是具体的段名，比如 `[tool.pixi.pypi-dependencies]`。你可以直接打开文件看真实的写法。
