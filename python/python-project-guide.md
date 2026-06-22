# Python 项目开发从零入门

> 写给从未开发过 Python 项目的新手。
> 不讲废话，每步都能跟着做。

---

## 目录

1. [一个 Python 项目长什么样？](#1-一个-python-项目长什么样)
2. [第零步：先搞清楚你在哪](#2-第零步先搞清楚你在哪)
3. [第一步：创建项目目录](#3-第一步创建项目目录)
4. [第二步：初始化项目（pyproject.toml）](#4-第二步初始化项目pyprojecttoml)
5. [第三步：写代码](#5-第三步写代码)
6. [第四步：装依赖](#6-第四步装依赖)
7. [第五步：运行](#7-第五步运行)
8. [第六步：测试](#8-第六步测试)
9. [第七步：版本控制（git）](#9-第七步版本控制git)
10. [第八步：重复](#10-第八步重复)
11. [常见问题](#11-常见问题)

---

## 1. 一个 Python 项目长什么样？

一个 Python "项目" 说白了就是**一个文件夹**，里面放你的 `.py` 文件和配套的配置文件。

最小的项目只要两个文件：

```
my-project/
├── main.py           ← 你的 Python 代码
└── pyproject.toml    ← 项目的"身份证"（告诉别人这个项目叫什么、需要什么）
```

大一点的项目会长这样：

```
my-project/
├── pyproject.toml     ← 项目配置
├── README.md          ← 项目说明（写给人类看的）
├── justfile           ← 常用命令快捷方式（可选）
├── src/               ← 源码目录
│   └── mycli/
│       ├── __init__.py
│       └── main.py
├── tests/             ← 测试目录
│   └── test_main.py
└── .gitignore         ← git 忽略文件清单
```

别被吓到——这些不是一次性要你全部搞懂的。你从"两个文件"开始，慢慢加。

---

## 2. 第零步：先搞清楚你在哪

打开终端，先看你当前在哪个目录：

```bash
pwd
```

大概率你会看到 `/var/home/smile` 或者 `~`（这俩是同一个地方，你的家目录）。

**一个原则**：所有项目都放在 `~/Developer/` 里。你已经有这个目录了。

```bash
cd ~/Developer    # 进到 Developer 目录
ls                # 看看里面有什么
```

---

## 3. 第一步：创建项目目录

```bash
cd ~/Developer
mkdir my-first-project    # 创建项目文件夹
cd my-first-project       # 进去
```

现在你在 `~/Developer/my-first-project/` 里，这就是你的项目根目录。

> **原则**：一个项目一个文件夹，别把多个项目混在一起。

---

## 4. 第二步：初始化项目（pyproject.toml）

### 4.1 什么是 pyproject.toml？

它是 Python 项目的"身份证"和"购物清单"。写清楚三件事：

1. **这个项目叫什么名字**
2. **它依赖哪些第三方库**
3. **它需要哪个 Python 版本**

用 pixi 初始化最简单：

```bash
cd ~/Developer/my-first-project
pixi init
```

这会自动生成一个 `pyproject.toml`，内容类似：

```toml
[project]
name = "my-first-project"
version = "0.1.0"
description = "我的第一个 Python 项目"
requires-python = ">= 3.11"
dependencies = []

[tool.pixi.workspace]
channels = ["conda-forge"]
platforms = ["linux-64"]
```

### 4.2 pyproject.toml 里的每个字段

| 字段 | 意思 | 例子 |
|------|------|------|
| `name` | 项目名，别人 pip install 用的名字 | `my-first-project` |
| `version` | 版本号 | `0.1.0` |
| `description` | 一句话描述 | `"我的第一个 CLI"` |
| `requires-python` | 最低 Python 版本 | `">= 3.11"` |
| `dependencies` | 依赖的第三方库列表 | `["typer>=0.12", "rich>=13"]` |
| `[project.scripts]` | CLI 入口（如果你的项目是命令行工具） | `mycli = "mycli.main:app"` |

### 4.3 手动添加依赖

假设你的项目要用 typer，在 pyproject.toml 里改：

```toml
dependencies = [
    "typer>=0.12",
]
```

或者在终端用 pixi 加：

```bash
pixi add typer
```

效果是一样的——pixi 会自动修改 pyproject.toml 并安装。

---

## 5. 第三步：写代码

创建 `main.py`：

```python
def main():
    print("Hello, world!")


if __name__ == "__main__":
    main()
```

就这么简单。你现在有了一个"Python 项目"，里面有一个能跑的脚本。

> **关于 `if __name__ == "__main__"`：** 这行的意思是"如果这个文件是被直接运行的，就执行下面的代码"。如果这个文件是被别的文件 `import` 的，就不执行。这是 Python 的标准写法，每个脚本都加上它。

---

## 6. 第四步：装依赖

如果是用 pixi 初始化的项目，pixi 已经自动创建了一个隔离环境。

你不需要手动装东西。添加依赖用：

```bash
pixi add typer        # 安装 typer
pixi add rich         # 安装 rich
pixi add pytest       # 安装 pytest（测试用）
```

运行代码用：

```bash
pixi run python main.py
```

**为什么不用 `python main.py` 直接跑？**

因为你的系统可能装了多个 Python 版本。`pixi run` 保证使用的是项目隔离环境里的 Python，不会和系统其他项目打架。

---

## 7. 第五步：运行

```bash
$ cd ~/Developer/my-first-project
$ pixi run python main.py
Hello, world!
```

如果你想运行时不打 `pixi run`，可以先进 pixi 环境：

```bash
pixi shell    # 进入项目环境
python main.py  # 直接跑
exit          # 退出环境
```

---

## 8. 第六步：测试

### 8.1 安装测试工具

```bash
pixi add pytest
```

### 8.2 写第一个测试

在项目根目录创建 `test_main.py`：

```python
"""测试 main.py 里的功能"""
from main import main


def test_main():
    """测试 main 函数能正常执行"""
    assert main() is None  # main() 没返回值，所以结果是 None
```

### 8.3 运行测试

```bash
pixi run python -m pytest -v
```

输出：

```
====================== test session starts ======================
collected 1 item

test_main.py::test_main PASSED                               [100%]

======================= 1 passed in 0.02s =======================
```

**以后每次改了代码，跑一下 `pixi run python -m pytest` 就知道有没有搞坏东西。**

---

## 9. 第七步：版本控制（git）

### 9.1 什么是 git？

git 就像你项目的"时光机"。每次你改完一个重要功能，可以"拍照"（commit）保存当前状态。以后可以随时回到任何一个历史版本。

### 9.2 初始化

```bash
cd ~/Developer/my-first-project
git init        # 告诉 git：这个文件夹我要开始管了
```

### 9.3 创建 .gitignore

有些文件不需要进版本控制（比如缓存、临时文件），用 `.gitignore` 告诉 git 忽略它们：

```bash
# .gitignore
__pycache__/
.pixi/
*.pyc
.env
```

### 9.4 第一次提交

```bash
git add .               # 把所有文件加入暂存区
git commit -m "第一次提交：初始化项目"  # 拍照保存
```

以后每次改完代码：

```bash
git add .
git commit -m "加了 XXX 功能"
```

### 9.5 查看历史

```bash
git log          # 看所有历史记录
git status       # 看当前有哪些文件被改了
```

**新手只需要记住三个命令：**

| 场景 | 命令 |
|------|------|
| 我想保存当前进度 | `git add .` 然后 `git commit -m "写个备注"` |
| 我想看看改了啥 | `git status` |
| 我想回到之前的版本 | `git log` 找到版本号 → `git checkout 版本号` |

---

## 10. 第八步：重复

项目开发的真实流程就是一个循环：

```
写代码 → 跑一下 → 写测试 → 跑测试 → git 提交 → 再写代码 → ...
```

你不需要一次搞定所有事。**先让代码跑起来，再慢慢优化。**

---

## 11. 一个完整的项目生命周期示例

让我带你完整走一遍：

```bash
# 1. 创建项目
cd ~/Developer
mkdir my-tool
cd my-tool
pixi init

# 2. 添加依赖
pixi add typer

# 3. 写代码（main.py）
```

```python
# main.py
import typer

app = typer.Typer()


@app.command()
def hello(name: str):
    print(f"Hello {name}!")


@app.command()
def goodbye(name: str):
    print(f"Goodbye {name}!")


if __name__ == "__main__":
    app()
```

```bash
# 4. 运行
pixi run python main.py hello Camila
# → Hello Camila!

# 5. 写测试（test_main.py）
```

```python
# test_main.py
from typer.testing import CliRunner
from main import app

runner = CliRunner()


def test_hello():
    result = runner.invoke(app, ["hello", "Camila"])
    assert result.exit_code == 0
    assert "Hello Camila" in result.output
```

```bash
# 6. 跑测试
pixi add pytest
pixi run python -m pytest -v
# → PASSED

# 7. git 保存
echo "__pycache__/\n.pixi/\n*.pyc" > .gitignore
git init
git add .
git commit -m "我的第一个 Python CLI 项目"

# 8. 以后每次改完代码
git add .
git commit -m "加了 goodbye 功能"
pixi run python -m pytest    # 确认没搞坏
```

---

## 附：你常用的 pixi 命令速查

| 场景 | 命令 |
|------|------|
| 创建一个新项目 | `pixi init` |
| 安装一个库 | `pixi add typer` |
| 运行 Python 脚本 | `pixi run python main.py` |
| 跑测试 | `pixi run python -m pytest` |
| 进入项目环境 | `pixi shell` |
| 查看装了哪些库 | `pixi list` |

## 附：项目目录结构速查

```
my-project/
├── pyproject.toml    ← 项目的身份证和购物清单
├── .gitignore        ← git 忽略清单
├── main.py           ← 你的代码
├── test_main.py      ← 你的测试
├── .pixi/            ← pixi 自动生成的，别动它
└── src/              ← (可选) 大项目把源码放这里
    └── mycli/
        ├── __init__.py
        └── main.py
```

## 总结：开发的五个习惯

1. **所有项目放 `~/Developer/`**，不乱
2. **每个项目一个文件夹**，不混
3. **用 pixi 管理依赖**，不污染系统
4. **写测试**，不改坏东西
5. **用 git 提交**，能回退
