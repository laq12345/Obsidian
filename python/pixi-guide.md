# Pixi 完全教程

> 基于官方文档 https://pixi.prefix.dev/latest/
>
> Pixi 是一个**快速、现代、可复现**的包管理工具。
> 它能装 Python、C++、Node.js、Rust……几乎所有语言的工具和库。
>
> 一句话：**pixi = conda 的生态 + pip 的方便 + 自带任务管理器**

---

## 目录

1. [Pixi 是什么？为什么要用？](#1-pixi-是什么为什么要用)
2. [安装与升级](#2-安装与升级)
3. [第一个项目](#3-第一个项目)
4. [管理依赖](#4-管理依赖)
5. [包的版本规范（MatchSpec）](#5-包的版本规范matchspec)
6. [运行代码](#6-运行代码)
7. [任务系统（Tasks）](#7-任务系统tasks)
8. [全局工具（Global Tools）](#8-全局工具global-tools)
9. [环境（Environments）](#9-环境environments)
10. [多平台支持](#10-多平台支持)
11. [锁文件（Lock File）](#11-锁文件lock-file)
12. [Conda & PyPI 混合使用](#12-conda--pypi-混合使用)
13. [Python 项目详解](#13-python-项目详解)
14. [构建包（Preview 功能）](#14-构建包preview-功能)
15. [Docker 部署](#15-docker-部署)
16. [环境变量](#16-环境变量)
17. [pixi 命令速查表](#17-pixi-命令速查表)
18. [常见问题（FAQ）](#18-常见问题faq)

---

## 1. Pixi 是什么？为什么要用？

### 1.1 它解决什么问题

| 问题                                   | 例子               |
| ------------------------------------ | ---------------- |
| 项目 A 要 Python 3.11，项目 B 要 Python 3.9 | 系统只能装一个，冲突       |
| 同事装出来的环境和你的不一样                       | "我这是能跑的！"——但你跑不了 |
| 每次配环境要手打一堆命令                         | 没人记得清顺序          |
| 想装个 CLI 工具，`apt install` 版本太旧        | 系统包管理器跟不上        |
| 想装 CUDA 版 PyTorch，但 pip 装的是 CPU 版    | 需要 conda 的二进制包   |

**Pixi 一次解决所有问题：**

1. **隔离环境** — 每个项目有自己的一套依赖，互不干扰
2. **锁文件** — 精确记录每个包的版本，别人装出来和你一模一样
3. **跨语言** — 不只是 Python，C++、Rust、Node.js、R 都管
4. **任务系统** — 把常用命令配成任务，一行搞定
5. **conda + PyPI 双生态** — 二进制包走 conda，纯 Python 走 PyPI

### 1.2 和其他工具对比

| 功能            | Pixi | Conda | Mamba | pip | Poetry | uv  |
| ------------- | ---- | ----- | ----- | --- | ------ | --- |
| 装 Python      | ✅    | ✅     | ✅     | ❌   | ❌      | ✅   |
| 多语言支持         | ✅    | ✅     | ✅     | ❌   | ❌      | ❌   |
| 锁文件           | ✅    | ❌     | ❌     | ❌   | ✅      | ✅   |
| 任务管理器         | ✅    | ❌     | ❌     | ❌   | ❌      | ❌   |
| 项目管理          | ✅    | ❌     | ❌     | ❌   | ✅      | ✅   |
| 快速            | ✅    | ❌     | ✅     | ❌   | ❌      | ✅   |
| 不用 Python 也能用 | ✅    | ❌     | ✅     | ❌   | ❌      | ❌   |
| 构建包           | 🚧   | ❌     | ❌     | ✅   | ✅      | ❌   |

### 1.3 名字由来

"pixi" 好拼、好记、好念。在代码里写作 `pixi`，其他地方写作 `Pixi`。

---

## 2. 安装与升级

### 2.1 安装

```bash
curl -fsSL https://pixi.sh/install.sh | sh
```

装完后重启终端。

验证：

```bash
pixi --version
# → pixi 0.69.0
```

### 2.2 升级

```bash
pixi self-update
```

### 2.3 安装目录

pixi 装在 `~/.pixi/bin/pixi`。所有全局数据和环境也都在 `~/.pixi/` 下。

---

## 3. 第一个项目

### 3.1 创建项目

```bash
pixi init hello-world
cd hello-world
```

生成：

```
hello-world/
├── pixi.toml
├── .gitattributes
└── .gitignore
```

`pixi.toml` 内容：

```toml
[workspace]
name = "hello-world"
version = "0.1.0"
channels = ["conda-forge"]     # 去哪找包
platforms = ["linux-64"]       # 支持哪些平台

[tasks]                         # 任务

[dependencies]                 # 依赖
```

### 3.2 添加 Python 并运行

```bash
pixi add python
pixi run python -c "print('Hello, Pixi!')"
```

输出：

```
✨ Pixi task (default): python -c "print('Hello, Pixi!')"
Hello, Pixi!
```

### 3.3 创建项目时选择配置格式

```bash
pixi init my-project                  # 用 pixi.toml（默认）
pixi init my-project --format pyproject  # 用 pyproject.toml（Python 项目推荐）
pixi init my-project --format pixi     # 明确用 pixi.toml
```

`--format pyproject` 会生成 `src/` 目录结构和 `pyproject.toml`，更适合 Python 项目。

---

## 4. 管理依赖

### 4.1 添加依赖

```bash
# 从 conda-forge 装（默认）
pixi add numpy

# 指定版本
pixi add "python=3.12"
pixi add "numpy>=2.0,<3"
pixi add "python=3.11.*"          # 3.11.x 任意版本

# 从 PyPI 装
pixi add --pypi requests
pixi add --pypi "flask[async]==3.1.0"  # 带 extras

# 从指定频道装
pixi add pytorch::pytorch          # 从 pytorch 频道
pixi add --channel bioconda star   # 从 bioconda 频道

# 装特定构建版本（CUDA 版）
pixi add "pytorch=*=cuda*"

# 指定平台依赖
pixi add --platform win-64 posix     # 只在 Windows 上装
pixi add --platform linux-64 cuda     # 只在 Linux 上装
```

### 4.2 删除依赖

```bash
pixi remove numpy
```

### 4.3 查看已装依赖

```bash
pixi list            # 列表
pixi tree            # 树形（看依赖关系）
pixi list --explicit # 显示完整的下载 URL
```

`pixi list` 输出示例：

```
Package      Version       Build              Size      Kind   Source
python       3.12.2        h9f0c242_0_cpython  12.3 MiB  conda  conda-forge
numpy        2.2.6         py313h41a2e72_0     6.2 MiB   conda  conda-forge
pytest       8.3.5         pyhd8ed1ab_0        388 KiB   conda  conda-forge
requests     2.32.0        -                   335 KiB   pypi   PyPI
```

- **Kind** = conda 还是 pypi
- **Build** = conda 包的构建标识（包含 Python 版本、编译器、CUDA 等信息）

### 4.4 更新依赖

```bash
pixi update           # 更新所有（不改变版本范围）
pixi update numpy     # 更新单个

pixi upgrade numpy    # 升级到最新（强制改版本范围）
```

### 4.5 搜索包

```bash
pixi search numpy     # 在已配置的频道中搜索
pixi search "python=3.12"
```

### 4.6 依赖分组（Features）

```bash
# 创建一个 feature（依赖组）
pixi add --feature test pytest
pixi add --feature dev ipython ruff

# 根据 feature 创建环境
pixi workspace environment add default --solve-group default --force
pixi workspace environment add test --feature test --solve-group default
pixi workspace environment add dev --feature test --feature dev --solve-group default
```

在 `pixi.toml` 或 `pyproject.toml` 中生成：

```toml
[tool.pixi.environments]
default = { solve-group = "default" }
test = { features = ["test"], solve-group = "default" }
dev = { features = ["test", "dev"], solve-group = "default" }
```

使用：

```bash
pixi run --environment test pytest
pixi shell --environment dev
```

`solve-group` = 保证不同环境之间的依赖版本一致。

---

## 5. 包的版本规范（MatchSpec）

这是 conda 生态的版本写法，比 pip 的 PEP440 更丰富。

### 5.1 命令行写法

```bash
# = 语法（紧凑）
pixi add "python=3.11"          # 版本
pixi add "pytorch=2.0.*=cuda*"  # 版本=构建字符串
pixi add "numpy=*=py311*"       # 任意版本，但构建要匹配

# [ ] 语法（显式）
pixi add "pytorch [version='2.0.*', build='cuda*']"
pixi add "python [version='3.11.0', build_number='>=1']"
pixi add "numpy [version='>=1.21', build='py311*', channel='conda-forge']"
```

### 5.2 TOML 完整写法（最精确）

```toml
[tool.pixi.dependencies.pytorch]
version = "2.0.*"
build = "cuda*"
build-number = ">=1"
channel = "https://prefix.dev/pytorch"
sha256 = "1234567890abcdef..."
```

| 字段               | 作用    | 例子                           |
| ---------------- | ----- | ---------------------------- |
| `version`        | 版本范围  | `"2.0.*"`, `">=1.21,<2"`     |
| `build`          | 构建字符串 | `"cuda*"`, `"py311*"`        |
| `build-number`   | 构建编号  | `">=1"`                      |
| `channel`        | 指定频道  | `"pytorch"`, `"conda-forge"` |
| `sha256` / `md5` | 校验和   | 安装时验证文件完整性                   |

### 5.3 版本运算符

| 运算符         | 含义                  | 例子              |        |        |
| ----------- | ------------------- | --------------- | ------ | ------ |
| `==`        | 精确等于                | `==3.11.0`      |        |        |
| `!=`        | 不等于                 | `!=3.8`         |        |        |
| `>` / `<`   | 大于/小于               | `>3.9`          |        |        |
| `>=` / `<=` | 大于等于/小于等于           | `>=3.9,<3.12`   |        |        |
| `~=`        | 兼容版本（>=3.11, <3.12） | `~=3.11.0`      |        |        |
| `*`         | 通配符                 | `3.11.*`        |        |        |
| `,`         | 且                   | `">=3.9,<3.12"` |        |        |
| `           | `                   | 或               | `"3.10 | 3.11"` |

### 5.4 PyPI 版本写法

```bash
pixi add --pypi "requests>=2.20,<3.0"
pixi add --pypi "requests[security]==2.25.1"
```

---

## 6. 运行代码

### 6.1 四种方式

```bash
# ① pixi run — 跑命令，用完即退（最常用）
pixi run python main.py

# ② pixi shell — 进环境，多次操作
pixi shell
python main.py     # 随便跑
pytest
exit               # 退出

# ③ pixi exec — 临时环境，不需要项目
pixi exec python -c "print('hello')"
pixi exec --spec "python=3.12" python -VV

# ④ pixi run 任务
pixi run test
```

### 6.2 三种方式的适用场景

| 方式           | 最适场景                |
| ------------ | ------------------- |
| `pixi run`   | 跑一次性命令或任务           |
| `pixi shell` | 需要交互式操作（调试、Jupyter） |
| `pixi exec`  | 临时用某个工具，不想建项目       |

### 6.3 常用选项

```bash
# 在指定环境运行
pixi run --environment test pytest

# 冻结模式（不更新锁文件）
pixi run --frozen python main.py

# 锁定模式（锁文件不是最新就报错）
pixi run --locked python main.py
```

---

## 7. 任务系统（Tasks）

### 7.1 为什么需要任务？

没任务时你要记住一堆命令：

```bash
python src/detect_encoding/detect_encoding.py input.txt
pytest tests/ -v --tb=short
ruff format src/
```

有任务后：

```bash
pixi run detect
pixi run test
pixi run format
```

### 7.2 添加任务

```bash
pixi task add hello "echo Hello, World!"
```

配置文件里：

```toml
[tasks]
hello = "echo Hello, World!"
```

运行：

```bash
$ pixi run hello
✨ Pixi task (default): echo Hello, World!
Hello, World!
```

### 7.3 单行命令 vs 对象语法

```toml
[tasks]
# 简单任务——单行字符串
lint = "ruff check src/"

# 复杂任务——对象语法
test = {
    cmd = "pytest -v --tb=short",
    description = "跑测试",
    depends-on = ["lint"],
    cwd = "tests",
    env = { PYTHONWARNINGS = "ignore" },
}
```

### 7.4 完整字段

```toml
[tasks.build]
cmd = "make build"                     # 要运行的命令
description = "编译项目"                 # 描述（--help 时显示）
depends-on = ["configure"]             # 依赖的任务（先跑这些）
cwd = "scripts"                        # 工作目录（相对项目根目录）
env = { CXX = "g++" }                  # 环境变量
default-environment = "cuda"           # 默认在哪个环境跑
```

### 7.5 任务依赖链

```toml
[tasks]
configure = "cmake -G Ninja -S . -B .build"
build = { cmd = "ninja -C .build", depends-on = ["configure"] }
start = { cmd = ".build/bin/myapp", depends-on = ["build"] }
```

跑 `pixi run start` 时自动跑：configure → build → start。任何一个失败就停止。

### 7.6 任务别名（同时跑多个任务）

```bash
pixi task alias style fmt lint
```

等价于：

```toml
[tasks]
fmt = "ruff format src/"
lint = "ruff check src/"
style = [{ task = "fmt" }, { task = "lint" }]
```

跑 `pixi run style` 时 fmt 和 lint 都会执行。

### 7.7 带参数的任务

```toml
[tasks.greet]
cmd = "echo Hello, {{ name }}!"
args = ["name"]
```

```toml
[tasks.build]
cmd = "echo Building {{ project }} in {{ mode }} mode"
args = [
    { arg = "project", default = "my-app" },
    { arg = "mode", default = "development" },
]
```

使用：

```bash
pixi run greet World          # → Hello, World!
pixi run build my-app release # → Building my-app in release mode
```

### 7.8 限制参数值（choices）

```toml
[tasks.compile]
args = [{ arg = "mode", choices = ["debug", "release"] }]
cmd = "Compiling in {{ mode }} mode"
```

传错值会报错：`got 'fast' for argument 'mode', choose from: debug, release`

### 7.9 同一任务在不同环境跑

```toml
[tasks.test]
cmd = "pytest"

[feature.py311.dependencies]
python = "3.11.*"

[feature.py312.dependencies]
python = "3.12.*"

[tasks.test-all]
depends-on = [
    { task = "test", environment = "py311" },
    { task = "test", environment = "py312" },
]
```

`pixi run test-all` 会同时在 Python 3.11 和 3.12 两个环境跑测试。

---

## 8. 全局工具（Global Tools）

### 8.1 问题 vs 方案

```bash
# 传统做法
sudo apt install btop        # 要 root，版本旧
pip install typer             # 污染系统 Python
brew install ripgrep          # 又要多装一个包管理器

# pixi 做法
pixi global install btop typer ripgrep
```

每个工具装在**隔离环境**里，只暴露必要的命令到 PATH。

### 8.2 基本用法

```bash
# 装一个
pixi global install btop

# 装多个
pixi global install ripgrep typer

# 装特定版本
pixi global install "python=3.12"
```

装完直接敲命令：

```bash
btop
rg "pattern" file.txt
typer --help
```

### 8.3 安装带额外依赖但不暴露 CLI

```bash
pixi global install ipython --with numpy --with matplotlib
```

`ipython` 的命令暴露给终端，`numpy`/`matplotlib` 只能在 Python 里 import。

### 8.4 自定义命令名

```bash
# 把 python 3.12 暴露成 py3
pixi global install --expose py3=python "python=3.12"

# 只暴露特定命令，不暴露其他
pixi global install --expose jupyter jupyter
```

### 8.5 创建数据科学环境

```bash
pixi global install --environment data-science \
  --expose jupyter --expose ipython \
  jupyter numpy pandas matplotlib ipython
```

生成配置：

```toml
[envs.data-science]
channels = ["conda-forge"]
dependencies = { jupyter = "*", ipython = "*" }
exposed = { jupyter = "jupyter", ipython = "ipython" }
```

### 8.6 查看管理

```bash
pixi global list              # 查看所有全局工具
pixi global uninstall typer   # 卸载
pixi global update            # 更新所有全局工具
pixi global edit              # 编辑全局 manifest 文件
```

---

## 9. 环境（Environments）

### 9.1 环境存在哪

`.pixi/envs/` 目录下，每个环境一个子目录：

```
.pixi/envs/
├── default/          # 默认环境
│   ├── bin/          # 可执行文件
│   ├── lib/          # 库文件
│   └── ...
└── cuda/             # 其他环境
```

不要手动编辑这些文件，通过 `pixi add/remove` 操作。

### 9.2 环境激活

三种激活方式，效果一样：

```bash
pixi run python main.py    # 自动激活 → 跑 → 退出
pixi shell                  # 进环境，exit 退出
eval "$(pixi shell-hook)"   # 在当前 shell 激活（不启动子 shell）
```

激活时设置的环境变量：

```
PATH               = 加了项目环境的 bin/ 目录
CONDA_PREFIX       = 环境路径
PIXI_PROJECT_ROOT  = 项目根目录
PIXI_PROJECT_NAME  = 项目名
PIXI_ENVIRONMENT_NAME = 环境名（default 或其他）
```

### 9.3 自定义激活行为

```toml
[activation.env]
PYTHONIOENCODING = "utf-8"
PYTHONNOUSERSITE = "1"

[target.unix.activation]
scripts = ["setup.sh"]

[target.win.activation]
scripts = ["setup.bat"]
```

### 9.4 清理环境

```bash
pixi clean                  # 删所有环境
pixi clean --environment cuda  # 只删特定环境
rm -rf .pixi/envs           # 手动删（效果一样）
```

pixi 会在需要时自动重建。

### 9.5 多环境

场景：`default` 环境装核心依赖，`test` 环境多装 pytest，`cuda` 环境多装 PyTorch CUDA。

```toml
[tool.pixi.environments]
default = { solve-group = "default" }
test = { features = ["test"], solve-group = "default" }
cuda = { features = ["cuda"], solve-group = "default" }
```

使用：

```bash
pixi run --environment test pytest
pixi shell --environment cuda
```

---

## 10. 多平台支持

### 10.1 声明支持的平台

```toml
[workspace]
platforms = ["linux-64", "osx-arm64", "win-64"]
```

### 10.2 不同平台装不同依赖

```toml
[dependencies]
python = ">=3.8"

# Linux 上装 CUDA
[target.linux-64.dependencies]
cuda = "*"

# Windows 上装 MSMPI
[target.win-64.dependencies]
msmpi = "*"
```

**注意**：目标平台的配置会**覆盖**通用配置。比如上面 Linux 和 Windows 的 Python 版本会覆盖 `>=3.8`。

### 10.3 不同平台不同激活脚本

```toml
[activation]
scripts = ["setup.sh"]

[target.win-64.activation]
scripts = ["setup.bat"]
```

**注意**：如果某个平台指定了 `target` 的 activation，那通用 `[activation]` 里的对该平台**不生效**。

### 10.4 命令行添加

```bash
pixi add --platform win-64 posix    # 只在 Windows 装
pixi add --platform linux-64 cuda   # 只在 Linux 装
```

---

## 11. 锁文件（Lock File）

### 11.1 锁文件是什么

`pixi.lock` 记录了**所有依赖的精确版本、构建标识、下载 URL、校验和**。

| 文件 | 内容 |
|------|------|
| `pixi.toml` | 你写的依赖范围（`numpy>=2.0`） |
| `pixi.lock` | 实际安装的精确版本（`numpy-2.2.6-py313h41a2e72_0.conda`） |

### 11.2 提交到 git

**要提交。** 锁文件是项目的"可复现保证书"。

```bash
git add pixi.lock
```

不提交的话，别人 `pixi install` 可能因为频道更新了而装出不同版本。

### 11.3 锁文件结构（了解即可）

```yaml
version: 6
environments:
  default:
    packages:
      linux-64:
      - conda: https://prefix.dev/conda-forge/linux-64/python-3.12.2-...
      osx-64:
      - conda: https://prefix.dev/conda-forge/osx-64/python-3.12.2-...
packages:
- kind: conda
  name: python
  version: 3.12.2
  sha256: 7647ac06c3798a182a4bcb1ff58864f1ef81eb3acea6971295304c23e43252fb
  depends:
  - bzip2 >=1.0.8,<2.0a0
  - libffi >=3.4,<4.0a0
```

**不要手动编辑锁文件。**

### 11.4 锁文件版本

`pixi.lock` 有版本号（当前是 v6）。老版本 pixi 生成的锁文件可以被新 pixi 读，但新版本锁文件只能用新 pixi 读。

### 11.5 相关命令

```bash
pixi lock                    # 只更新锁文件，不装环境
pixi install --frozen        # 用现有锁文件（不更新）
pixi install --locked        # 锁文件必须最新，否则报错
```

`--frozen` 和 `--locked` 在 CI 中很有用：
- `--frozen`：快速安装，不改锁文件
- `--locked`：确保 lock file 是最新的

---

## 12. Conda & PyPI 混合使用

### 12.1 Pixi 的处理策略

Pixi 是 **conda-first** 的。解析顺序：

1. 先解析 conda 依赖
2. 把 conda 包映射到 PyPI 包名
3. 再解析剩下未解决的 PyPI 依赖

### 12.2 如果一个包两边都写了

```toml
[dependencies]
numpy = ">=1.21.0"

[pypi-dependencies]
numpy = ">=1.21.0"
```

结果：**只装 conda 版**，PyPI 版被忽略。

只有当你没有在 conda 里声明时，才会从 PyPI 装。

### 12.3 什么时候选 conda，什么时候选 PyPI

| 场景 | 推荐 |
|------|------|
| Python 本身 | conda |
| 有 C/C++ 扩展的库（numpy、pytorch、opencv） | conda（预编译，省去编译的麻烦） |
| 需要指定 CUDA 版本 | conda（`pytorch=*=cuda*`） |
| 纯 Python 库 | PyPI（更快、版本更新） |
| 私有包、公司内部包 | PyPI |
| 两者都有时 | conda 优先（更稳定） |

### 12.4 两阶段解析的冲突

因为 conda 和 PyPI 是分开解析的，可能遇到版本冲突：

```toml
[dependencies]
typing_extensions = "*"           # conda 解析出 4.15.0

[pypi-dependencies]
typing_extensions = "==4.14"      # PyPI 要 4.14，冲突
```

报错信息会提示哪个包被 conda 锁定了。

### 12.5 PyPI Overrides

```toml
[tool.pixi.pypi-options]
dependency-overrides = { numpy = ">=2.0" }
```

用 `pypi-options` 覆盖 PyPI 侧的依赖解析。

---

## 13. Python 项目详解

### 13.1 创建

```bash
pixi init pixi-py --format pyproject
cd pixi-py
```

生成：

```
pixi-py/
├── pyproject.toml
└── src/
    └── pixi_py/
        └── __init__.py
```

生成的 `pyproject.toml`：

```toml
[project]
name = "pixi-py"
version = "0.1.0"
requires-python = ">= 3.11"
dependencies = []

[build-system]
build-backend = "hatchling.build"
requires = ["hatchling"]

[tool.pixi.workspace]
channels = ["conda-forge"]
platforms = ["linux-64"]

[tool.pixi.***]
pixi_py = { path = ".", editable = true }

[tool.pixi.tasks]
```

### 13.2 配置文件字段对应

| 概念       | 在 `pixi.toml`    | 在 `pyproject.toml` 的 `[tool.pixi]` |
| -------- | ---------------- | ---------------------------------- |
| 项目信息     | `[workspace]`    | 用 `[project]`（标准 PEP 621）          |
| conda 依赖 | `[dependencies]` | `[tool.pixi.dependencies]`         |
| PyPI 依赖  | `[***]`          | `[project.dependencies]`           |
| 本地包      | —                | `[tool.pixi.***]`                  |
| 任务       | `[tasks]`        | `[tool.pixi.tasks]`                |
| 多环境      | —                | `[tool.pixi.environments]`         |
| 激活       | `[activation]`   | `[tool.pixi.activation]`           |

### 13.3 添加依赖

```bash
# conda 依赖 → [tool.pixi.dependencies]
pixi add numpy

# PyPI 依赖 → [project.dependencies]
pixi add --pypi rich

# 本地包可编辑安装 → [tool.pixi.***]
```

### 13.4 不需要手动创建 venv

`pixi install` 自动完成：
1. 创建 `.pixi/envs/default/`
2. 安装所有依赖
3. 生成 `pixi.lock`

### 13.5 Pixi 使用 uv 来管理 PyPI 包

Pixi 内置了 `uv` 库（不是 `uv` 命令行工具，而是 Astral 团队开发的 Python 库）来处理 PyPI 包。

```bash
# 这实际上是在用 uv 的能力
pixi add --pypi requests
```

---

## 14. 构建包（Preview 功能）

> ⚠️ 这是 Preview 功能，需要手动开启。

### 14.1 开启

在 `pixi.toml` 中加：

```toml
[workspace]
preview = ["pixi-build"]
```

### 14.2 完整示例

```toml
[workspace]
preview = ["pixi-build"]
channels = ["conda-forge"]
platforms = ["linux-64"]

[package]
name = "python_rich"
version = "0.1.0"

[package.build.backend]
name = "pixi-build-python"
version = "0.*"

[package.host-dependencies]
hatchling = "*"

[package.run-dependencies]
rich = "13.9.*"

[dependencies]
python_rich = { path = "." }
```

### 14.3 发布

```bash
pixi publish --target-channel my-channel
```

### 14.4 支持的构建后端

| 后端 | 语言 |
|------|------|
| `pixi-build-python` | Python |
| `pixi-build-cmake` | C/C++ |
| `pixi-build-rust` | Rust |
| `pixi-build-ros` | ROS |
| `pixi-build-r` | R |

---

## 15. Docker 部署

### 15.1 官方 Docker 镜像

```bash
docker pull ghcr.io/prefix-dev/pixi:latest  # Ubuntu 24.04 基底
```

其他标签：`focal`（Ubuntu 20.04）、`bullseye`（Debian 11）、`noble-cuda-12.9.1`（CUDA 版）。

### 15.2 多阶段构建示例

```dockerfile
# 构建阶段：用 pixi 环境
FROM ghcr.io/prefix-dev/pixi:0.70.2 AS build

WORKDIR /app
COPY . .

# 安装生产环境
RUN pixi install --locked -e prod
# 生成环境激活脚本
RUN pixi shell-hook -e prod -s bash > /shell-hook
RUN echo "#!/bin/bash" > /app/entrypoint.sh
RUN cat /shell-hook >> /app/entrypoint.sh
RUN echo 'exec "$@"' >> /app.entrypoint.sh

# 生产阶段：极简镜像
FROM ubuntu:24.04 AS production
WORKDIR /app

# 只复制环境和启动脚本
COPY --from=build /app/.pixi/envs/prod /app/.pixi/envs/prod
COPY --from=build --chmod=0755 /app/entrypoint.sh /app/entrypoint.sh
COPY ./my_project /app/my_project

EXPOSE 8000
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["uvicorn", "my_project:app", "--host", "0.0.0.0"]
```

关键是：**生产镜像不需要装 pixi**，只需要把装好的环境复制过去。

---

## 16. 环境变量

### 16.1 Pixi 可配置的环境变量

| 变量 | 作用 | 默认值 |
|------|------|--------|
| `PIXI_HOME` | 全局数据目录 | `~/.pixi` |
| `PIXI_CACHE_DIR` | 缓存目录 | `~/.cache/rattler` |
| `PIXI_NO_CONFIG` | 跳过配置文件（CI 模式） | 不设置 |
| `PIXI_FROZEN` | 冻结模式（不更新锁文件） | 不设置 |
| `PIXI_LOCKED` | 锁定模式（锁文件必须最新） | 不设置 |
| `PIXI_NO_INSTALL` | 只更新锁文件，不装环境 | 不设置 |
| `PIXI_OVERRIDE_PLATFORM` | 覆盖平台检测 | 自动检测 |

### 16.2 Pixi 设置的环境变量

这些变量由 `pixi run`、`pixi shell`、`pixi shell-hook` 自动设置：

| 变量 | 例子 |
|------|------|
| `PIXI_PROJECT_ROOT` | `/home/user/projects/myapp` |
| `PIXI_PROJECT_NAME` | `myapp` |
| `PIXI_PROJECT_MANIFEST` | `/home/user/projects/myapp/pixi.toml` |
| `PIXI_PROJECT_VERSION` | `0.1.0` |
| `PIXI_ENVIRONMENT_NAME` | `default` |
| `PIXI_ENVIRONMENT_PLATFORMS` | `linux-64,osx-arm64` |
| `CONDA_PREFIX` | `/home/user/projects/myapp/.pixi/envs/default` |
| `CONDA_DEFAULT_ENV` | `myapp` |

### 16.3 优先级（高 → 低）

1. `tasks.<name>.env`
2. `[activation.env]`
3. `[activation] scripts`
4. 依赖包的激活脚本
5. 系统环境变量

高优先级覆盖低优先级。

---

## 17. pixi 命令速查表

### 项目创建与管理

| 命令 | 作用 |
|------|------|
| `pixi init [name]` | 创建新项目（pixi.toml） |
| `pixi init [name] --format pyproject` | 创建 Python 项目（pyproject.toml） |
| `pixi install` | 安装/更新所有依赖 |
| `pixi reinstall` | 重新安装环境 |
| `pixi clean` | 清理环境 |
| `pixi info` | 查看项目信息 |
| `pixi config` | 查看/编辑全局配置 |

### 依赖管理

| 命令 | 作用 |
|------|------|
| `pixi add pkg` | 添加 conda 依赖 |
| `pixi add --pypi pkg` | 添加 PyPI 依赖 |
| `pixi add --feature test pkg` | 添加到 feature（依赖组） |
| `pixi add --platform linux-64 pkg` | 只对某个平台添加 |
| `pixi add --channel bioconda pkg` | 从指定频道添加 |
| `pixi remove pkg` | 删除依赖 |
| `pixi update [pkg]` | 更新（不改变版本范围） |
| `pixi upgrade [pkg]` | 升级到最新 |
| `pixi list` | 查看已装依赖 |
| `pixi tree` | 查看依赖树 |
| `pixi search keyword` | 搜索包 |
| `pixi lock` | 只更新锁文件 |

### 运行

| 命令 | 作用 |
|------|------|
| `pixi run cmd` | 运行命令或任务 |
| `pixi run --environment test cmd` | 在指定环境运行 |
| `pixi run --frozen cmd` | 冻结模式运行 |
| `pixi shell` | 进入项目环境 |
| `pixi shell-hook` | 打印环境激活脚本 |
| `pixi exec cmd` | 临时环境运行 |

### 任务

| 命令 | 作用 |
|------|------|
| `pixi task add name cmd` | 添加任务 |
| `pixi task add name cmd --depends-on other` | 添加带依赖的任务 |
| `pixi task alias name t1 t2` | 创建任务别名 |
| `pixi run name` | 运行任务 |

### 全局工具

| 命令 | 作用 |
|------|------|
| `pixi global install pkg` | 全局安装工具 |
| `pixi global uninstall pkg` | 卸载 |
| `pixi global list` | 查看所有全局工具 |
| `pixi global update` | 更新全局工具 |
| `pixi global edit` | 编辑全局 manifest |
| `pixi global sync` | 同步全局 manifest |

### 工作空间

| 命令 | 作用 |
|------|------|
| `pixi workspace environment add name` | 添加环境 |
| `pixi workspace platform add linux-64` | 添加平台 |
| `pixi workspace channel add conda-forge` | 添加频道 |

### 其他

| 命令 | 作用 |
|------|------|
| `pixi auth login` | 登录私有频道 |
| `pixi completion` | 生成 shell 补全 |
| `pixi self-update` | 更新 pixi 自身 |
| `pixi publish` | 构建并发布包 |

### 全局选项

| 选项 | 作用 |
|------|------|
| `-v` / `-vv` / `-vvv` / `-vvvv` | 日志详细程度 |
| `-q` | 安静模式 |
| `--color always/never/auto` | 颜色控制 |
| `--no-progress` | 隐藏进度条 |

---

## 18. 常见问题（FAQ）

### Q：pixi 和 conda/mamba 什么关系？

pixi 底层用的是 conda 生态（conda-forge 频道、rattler 解析器），但更快、更现代、自带锁文件和任务系统。相当于 conda 的**替代升级版**。

### Q：pixi 和 pip 什么关系？

pixi 包含 pip 的能力。`pixi add --pypi requests` 底层用 uv 解析 PyPI 包。pixi 是 conda-first，但无缝支持 PyPI。

### Q：pixi 和 poetry/uv 什么关系？

| 特性 | pixi | poetry | uv |
|------|------|--------|----|
| 多语言 | ✅ | ❌（仅 Python） | ❌（仅 Python） |
| conda 生态 | ✅ | ❌ | ❌ |
| 任务系统 | ✅ | ❌ | ❌ |
| Python 版本管理 | ✅ | ✅ | ✅ |

### Q：我应该在项目里用 pixi.toml 还是 pyproject.toml？

| 用 pixi.toml | 用 pyproject.toml |
|-------------|-------------------|
| 多语言项目 | 纯 Python 项目 |
| 不想和 Python 生态混一起 | 要和 setuptools/hatchling 兼容 |
| 简单项目 | 要发布到 PyPI |

### Q：为什么不用手动创建 venv？

pixi 的 `pixi install` 自动创建隔离环境（在 `.pixi/envs/` 下）。你不需要 `python -m venv`。

### Q：`.pixi/` 目录要提交到 git 吗？

**不要。** 已经被 `.gitignore` 忽略。你只需要提交 `pixi.toml`、`pixi.lock` 和源码。

### Q：`pixi.lock` 要提交到 git 吗？

**要。** 它是可复现的保证。别人 clone 项目后 `pixi install` 能装出和你完全一样的环境。

### Q：为什么我的 `pip install` 装到了 pixi 环境外面？

因为你用了系统的 `pip`。在 pixi 项目里应该用：

```bash
pixi add --pypi xxx    # 推荐
pixi run python -m pip install xxx
```

### Q：`python main.py` 和 `pixi run python main.py` 有啥区别？

前者用系统默认的 Python（可能不是你项目里的版本），后者用项目环境的 Python。

### Q：pixi 能管理 R、C++、Node.js 吗？

能。

```bash
pixi add r-base           # R 语言
pixi add clang            # C/C++ 编译器
pixi add nodejs           # Node.js
pixi add rust             # Rust
pixi add openjdk          # Java
```

### Q：pixi 能装 Jupyter 吗？

```bash
# 项目里
pixi add jupyter
pixi run jupyter lab

# 全局
pixi global install --expose jupyter jupyter lab
jupyter lab    # 在任何目录都能用
```

---

## 总结：Pixi 的核心理念

```
一个命令管理一切：

  项目级:  pixi init → pixi add → pixi run → pixi task
  全局级:  pixi global install xxx
  可复现:  pixi.lock + pixi install --frozen
  双生态:  conda-forge + PyPI，conda-first
  多平台:  一份配置，Linux/macOS/Windows 都能用
```
