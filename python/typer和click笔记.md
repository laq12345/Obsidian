---
created: 2026-06-18
tags:
  - python
  - typer
  - click
  - CLI
  - 笔记
source: hermes-agent
---

# Typer & Click 完全教程

> 两个 Python CLI 库，解决同一个问题：**把函数变成命令行工具**。

---

## 一、Click vs Typer：怎么选

| 维度 | Click | Typer |
|------|-------|-------|
| 作者 | Armin Ronacher（Flask 作者） | Sebastián Ramírez（FastAPI 作者） |
| 底层 | 纯独⽴实现 | **底层基于 Click** + type hints |
| 风格 | 装饰器 + 回调 | 类型注解 + 自动推导 |
| 代码量 | 中等 | **更少**（`fastapi` 风格） |
| 自动补全 | 需手动配置 | shell 补全内置 |
| 适用人群 | 喜欢显式配置 | 喜欢 type hints + 少写代码 |

**一句话**：Click 是 Typer 的底层引擎。如果你用 Click，需要手动声明参数类型；用 Typer，Python 的 type hints 自动帮你搞定。

---

## 二、快速对比

同样一个命令 `greet --name 张三 --count 3`：

### Click 写法
```python
import click

@click.command()
@click.option("--name", prompt="你的名字", help="姓名")
@click.option("--count", default=1, type=int, help="重复次数")
def greet(name, count):
    for _ in range(count):
        click.echo(f"你好，{name}！")

if __name__ == "__main__":
    greet()
```

### Typer 写法
```python
import typer

app = typer.Typer()

@app.command()
def greet(name: str = typer.Option(prompt="你的名字", help="姓名"),
           count: int = typer.Option(1, help="重复次数")):
    for _ in range(count):
        typer.echo(f"你好，{name}！")

if __name__ == "__main__":
    app()
```

**区别在哪？**
- Click：`@click.option` 声明参数名、类型、默认值
- Typer：直接用 Python 函数参数 + 类型注解，`typer.Option()` 只补充 CLI 细节

---

## 三、安装

```bash
pip install typer        # 装 Typer（会自动装 Click）
# 或
pip install click        # 只装 Click
```

```bash
# 推荐安装 typer[all]，带 shell 补全等额外功能
pip install "typer[all]"
```

pixi 环境：
```bash
pixi add typer
```

---

## 四、Typer 详细用法

### 0. 最低入门

```python
import typer

def main(name: str):
    typer.echo(f"Hello {name}!")

if __name__ == "__main__":
    typer.run(main)
```

保存为 `hello.py`，运行：
```bash
python hello.py 张三
# Hello 张三!

python hello.py --help
# Usage: hello.py [OPTIONS] NAME
#
# Arguments:
#   NAME  [required]
#
# Options:
#   --help  Show this message and exit.
```

> `typer.run()` 是最简单的入口，一个函数就够了。
> 多个命令时用 `app = typer.Typer()` + `@app.command()`。

---

### 1. 参数类型

Typer 自动根据 type hints 推导 CLI 参数类型：

```python
import typer
from pathlib import Path
from typing import Optional
from enum import Enum

class Color(str, Enum):
    red = "red"
    green = "green"
    blue = "blue"

def main(
    name: str,               # 字符串参数
    age: int = 18,           # 整数，默认 18
    score: float = 0.0,      # 浮点数
    active: bool = False,    # 布尔值（--active 开启）
    path: Path = Path("."),  # 路径对象
    color: Color = Color.red, # 枚举选择
):
    typer.echo(f"{name} ({age}), {color}")
```

运行效果：
```bash
python demo.py 张三 --age 25 --active --color green --path /data
```

---

### 2. 参数（Arguments）vs 选项（Options）

| 特性 | Arguments | Options |
|------|-----------|---------|
| 写法 | `name: str` | `name: str = typer.Option(...)` |
| 是否必填 | 默认必填 | 默认可选 |
| 使用方式 | `cmd 值` | `cmd --name 值` |
| 顺序 | 按位置 | 不依赖顺序 |

```python
import typer
from typing import Optional

def main(
    # ── Arguments（位置参数）──
    input_file: str,                          # 必填位置参数
    output_file: str = "output.txt",          # 可选位置参数（带默认值）

    # ── Options（-- 选项）──
    verbose: bool = typer.Option(False, "--verbose", "-v", help="详细输出"),
    threads: int = typer.Option(4, "--threads", "-t", help="线程数"),
    config: Optional[str] = typer.Option(None, "--config", "-c"),
):
    ...
```

```bash
python demo.py input.bam output.bam -v -t 8 --config conf.yaml
```

---

### 3. `typer.Option()` 常用参数

```python
typer.Option(
    default,                # 默认值
    "--name", "-n",         # CLI 长格式和短格式
    help="说明文字",         # --help 时显示
    prompt="请输入姓名",     # 没传时交互式提示输入
    confirmation_prompt=True, # 二次确认（用于密码）
    hide_input=True,        # 隐藏输入（密码场景）
    show_default=True,      # --help 时显示默认值
    show_choices=True,      # --help 时显示可选值（Enum 自动生效）
    envvar="MY_ENV_VAR",    # 从环境变量读取
    rich_help_panel="面板名", # 分组（需 rich）
    hidden=False,           # 在 --help 中隐藏
)
```

---

### 4. `typer.Argument()` 常用参数

```python
typer.Argument(
    default,                # 默认值（不传则必填）
    help="说明文字",
    show_default=True,
    envvar="ENV_VAR",
    hidden=False,
)
```

示例：
```python
def main(
    input_file: str = typer.Argument(..., help="输入文件路径"),
    output: str = typer.Argument("output.txt", help="输出文件路径"),
):
    ...
```

> `...`（Ellipsis）表示"必填"，是 Typer 的约定。

---

### 5. 多个命令（子命令）

```python
import typer

app = typer.Typer()

@app.command()
def hello(name: str):
    """打招呼"""
    typer.echo(f"Hello {name}")

@app.command()
def goodbye(name: str, formal: bool = False):
    """说再见"""
    if formal:
        typer.echo(f"Goodbye {name}")
    else:
        typer.echo(f"Bye {name}!")

@app.command()
def process(
    input_file: str,
    output_dir: str = typer.Option("./output", help="输出目录"),
):
    """处理数据"""
    typer.echo(f"Processing {input_file} -> {output_dir}")

if __name__ == "__main__":
    app()
```

```bash
python cli.py hello 张三
python cli.py goodbye 李四 --formal
python cli.py process data.txt
python cli.py --help
# 会列出所有子命令：hello, goodbye, process
```

---

### 6. 回调函数（生命周期钩子）

```python
import typer

app = typer.Typer()

@app.callback()
def main_callback(
    verbose: bool = typer.Option(False, "--verbose", "-v"),
):
    """全局设置，在所有命令前执行"""
    if verbose:
        typer.echo("Verbose mode enabled")

@app.command()
def run(name: str):
    """实际命令"""
    typer.echo(f"Running for {name}")
```

```bash
python cli.py --verbose run 张三
# Verbose mode enabled
# Running for 张三
```

> `@app.callback()` 定义的参数对所有子命令共享。

---

### 7. 退出与错误

```python
import typer
import sys

def main(path: str):
    if not path.endswith(".bam"):
        typer.echo("错误：需要 .bam 文件", err=True)   # 输出到 stderr
        raise typer.Exit(code=1)                       # 退出码 1

    # 或者直接退出
    raise typer.Exit()                                 # 退出码 0

    # 打印错误并退出（简写）
    typer.echo("错误信息", err=True)
    raise typer.Abort()                                # 退出码 1 + 显示 Aborted!
```

---

### 8. 进度条

```python
import typer
import time

def main(total: int = 100):
    with typer.progressbar(range(total), label="Processing") as progress:
        for _ in progress:
            time.sleep(0.02)
```

Typer 的进度条底层是 rich.progress，支持嵌套、彩色、自定义。

---

### 9. 确认提示

```python
import typer

def main(output: str):
    if typer.confirm(f"确认覆盖 {output}？"):
        typer.echo("执行中...")
    else:
        typer.echo("已取消")
```

---

### 10. 启动器（launch）

```python
import typer

def main():
    # 用系统默认程序打开文件
    typer.launch("result.pdf")
```

---

### 11. 输出样式（需要 rich）

```python
import typer
from typing import Optional

def main(
    name: str = typer.Option(..., help="The name to say hi to", rich_help_panel="My panel"),
    age: int = typer.Option(20, help="The age of the person"),
):
    typer.echo(f"Name: {name}, Age: {age}")
```

安装 `typer[all]` 后，`--help` 输出会带颜色和表格格式。

---

## 五、Click 核心用法（了解即可）

### 1. 基本命令

```python
import click

@click.command()
@click.option("--name", "-n", default="world", help="姓名")
@click.option("--count", "-c", default=1, type=int)
@click.argument("file", type=click.Path(exists=True))
def greet(name, count, file):
    """一个简单的问候命令"""
    for _ in range(count):
        click.echo(f"你好，{name}！正在处理 {file}")

if __name__ == "__main__":
    greet()
```

### 2. Click 独有但 Typer 没有的功能

| 功能 | Click 用法 | 说明 |
|------|-----------|------|
| 命令分组 | `@click.group()` | Typer 的 `Typer()` 实现相同效果 |
| 参数文件 | `@click.option("--cfg", type=click.File())` | 直接以文件对象传入 |
| 密码输入 | `@click.option("--pwd", prompt=True, hide_input=True, confirmation_prompt=True)` | Typer 也一样 |
| Choice | `click.Choice(["a", "b"])` | Typer 用 Enum 更优雅 |

---

## 六、实战：一个完整的 bioinfo CLI

```python
#!/usr/bin/env python
"""RNA-seq 差异分析 CLI"""

from pathlib import Path
from typing import Optional
import typer

app = typer.Typer(help="RNA-seq 差异分析工具")


@app.command()
def align(
    input_dir: Path = typer.Argument(..., help="FASTQ 目录"),
    output_dir: Path = typer.Argument(..., help="输出目录"),
    index: Path = typer.Option(..., "--index", "-i", help="比对索引路径"),
    threads: int = typer.Option(8, "--threads", "-t", help="线程数"),
    verbose: bool = typer.Option(False, "--verbose", "-v"),
):
    """比对 FASTQ 到参考基因组"""
    output_dir.mkdir(parents=True, exist_ok=True)
    typer.echo(f"Aligning {input_dir} -> {output_dir} with {threads} threads")
    if verbose:
        typer.echo(f"Using index: {index}")


@app.command()
def quant(
    bam_dir: Path = typer.Argument(..., help="BAM 文件目录"),
    gtf: Path = typer.Option(..., "--gtf", help="注释文件"),
    method: str = typer.Option("featureCounts", "--method", "-m"),
):
    """基因定量"""
    typer.echo(f"Quantifying BAM files in {bam_dir} using {method}")


@app.command()
def diff(
    counts_file: Path = typer.Argument(..., help="表达矩阵 CSV"),
    group_col: str = typer.Option("group", "--group", "-g"),
    out: Path = typer.Option(Path("diff_results.csv"), "--out", "-o"),
):
    """差异表达分析"""
    typer.echo(f"Running DE analysis: {counts_file}")
    typer.echo(f"Group column: {group_col}, Output: {out}")


@app.callback()
def main(
    verbose: bool = typer.Option(False, "--verbose", "-v"),
):
    """全局配置"""
    if verbose:
        typer.echo("Verbose mode on")


if __name__ == "__main__":
    app()
```

使用：
```bash
# 查看帮助
python rnaseq_cli.py --help
python rnaseq_cli.py align --help
python rnaseq_cli.py quant --help

# 执行
python rnaseq_cli.py -v align ./fastq/ ./bam/ --index /ref/index
python rnaseq_cli.py quant ./bam/ --gtf /ref/genes.gtf
```

---

## 七、速查表

### Typer 速查

```python
import typer
from pathlib import Path
from typing import Optional
from enum import Enum

# 单命令（最简单）
def main(name: str):
    ...
typer.run(main)

# 多命令
app = typer.Typer()
@app.command()
def cmd1(): ...
@app.command()
def cmd2(): ...
app()

# 参数类型（自动推导）
name: str                       # 字符串参数
count: int = 1                  # 整数，默认1
ratio: float = 0.5              # 浮点
verbose: bool = False           # --verbose 标志
path: Path = Path(".")          # 路径对象

# 选项（--xxx）
opt: str = typer.Option("默认值", "--name", "-n", help="说明")
flag: bool = typer.Option(False, "--verbose", "-v")

# 必填选项
req: str = typer.Option(..., "--input", "-i")

# 环境变量
val: str = typer.Option("default", envvar="MY_VAR")

# 交互提示
val: str = typer.Option(..., prompt="请输入密码", hide_input=True, confirmation_prompt=True)

# 输出
typer.echo("消息")              # stdout
typer.echo("错误", err=True)     # stderr
typer.confirm("继续？")          # 确认提示 (y/n)

# 退出
raise typer.Exit(code=1)
raise typer.Abort()

# 进度条
with typer.progressbar(range(100)) as p:
    for i in p: ...

# 启动文件
typer.launch("result.pdf")
```

---

## 八、最佳实践

1. **新项目用 Typer**，不要用 Click。Typer 更现代，代码更少
2. **函数参数加 type hints**，让 Typer 自动推导 CLI 类型
3. **子命令用 `@app.command()` 组织**，一个文件一个入口
4. **必填参数用 Argument，可选参数用 Option**
5. **`--help` 应该清晰完整**，每个参数写 `help="..."`，typer 会自动生成
6. **复杂管线用 Typer + rich** 做漂亮的终端输出
7. **脚本入口统一**：`if __name__ == "__main__": app()`
