---
created: 2026-06-18
tags:
  - python
  - pathlib
  - 笔记
source: hermes-agent
---

# pathlib 完全教程

> Python 3.4+ 标准库，3.6+ 推荐使用，**3.12+ 正式推荐替代 os.path**

---

## 一、pathlib vs os.path：核心区别

| 维度 | `os.path` | `pathlib` |
|------|-----------|-----------|
| 数据类型 | 字符串 str | 专用对象 `Path()` |
| 拼接 | `os.path.join(a, b)` 易忘参数 | `a / b` 运算符，直观 |
| 可读性 | 嵌套函数调用 | 方法链式调用 |
| 类型安全 | 字符串混用，路径/非路径难分 | `Path` 对象自文档化 |
| 跨平台 | 自动处理分隔符 | 同样自动处理 |
| 方法数量 | 散落 `os`、`os.path`、`shutil` | 集中在一个对象上 |

**一句话**：`os.path` 是函数式（传入字符串返回字符串），`pathlib` 是面向对象（路径即对象，自带方法）。

---

## 二、只掌握 pathlib 足够吗？

**足够覆盖 95% 的日常场景。** 具体来说：

### ✅ pathlib 能做的
- 路径拼接 / 解析 / 判断
- 文件读写（`read_text`、`write_text`、`read_bytes`、`write_bytes`）
- 遍历目录（`iterdir`、`glob`、`rglob`）
- 创建/删除目录和文件
- 文件属性（大小、修改时间、权限）
- 解析后缀、文件名、父目录
- 符号链接操作
- 相对路径 / 绝对路径转换

### ⚠️ 少数仍需 os.path 的场景
1. **`os.path.commonpath()`** — pathlib 没有直接替代，需自己实现
2. **`os.path.commonprefix()`** — 同上，但极少用
3. **`os.path.expandvars()`** — 展开 `$HOME` 等环境变量（pathlib 只有 `expanduser()` 展开 `~`）
4. **某些第三方库的接口** — 旧库只接受字符串路径，需 `str(path)` 转换

### 推荐策略
```python
from pathlib import Path

# 95% 的情况
p = Path("data/samples/file.txt")

# 遇到只吃字符串的旧库时
old_library_function(str(p))

# 真需要 os.path 时，混用也不冲突
import os.path
os.path.commonpath([str(p1), str(p2)])
```

**结论**：是的，只掌握 pathlib 足够。它是 Python 官方推荐的现代路径处理方式。

---

## 三、pathlib 详细用法

### 0. 导入

```python
from pathlib import Path
```

> 日常只用 `Path` 类。`PurePath`（纯路径，不访问文件系统）极少需要，跳过不影响。

---

### 1. 构造路径

```python
# 当前目录
p = Path()               # -> PosixPath('.')

# 相对路径
p = Path("data/raw")
p = Path("data", "raw")  # 效果同上

# 绝对路径
p = Path("/home/user/data")
p = Path.home()          # -> /home/xxx
p = Path.cwd()           # 当前工作目录
```

---

### 2. 路径拼接：`/` 运算符（核心优势）

```python
base = Path("data")
p = base / "samples" / "2024" / "file.txt"
# -> data/samples/2024/file.txt

# 等价于 os.path.join
# os.path.join("data", "samples", "2024", "file.txt")

# 可以和字符串混用
p = base / "raw" / f"batch_{i}.csv"

# 追加后缀
p = p.with_suffix(".bak")  # 替换后缀
```

---

### 3. 路径分解

```python
p = Path("/home/user/Developer/project/data/raw/sample01.fastq.gz")

p.parts       # ('/', 'home', 'user', 'Developer', 'project', 'data', 'raw', 'sample01.fastq.gz')
p.parent      # /home/user/Developer/project/data/raw
p.parents     # 生成器，从近到远列出所有父目录
list(p.parents)
# [PosixPath('/home/user/Developer/project/data/raw'),
#  PosixPath('/home/user/Developer/project/data'),
#  PosixPath('/home/user/Developer/project'),
#  ...]

p.name        # 'sample01.fastq.gz'
p.stem        # 'sample01.fastq'    (去掉最后一个后缀)
p.suffix      # '.gz'
p.suffixes    # ['.fastq', '.gz']   (所有后缀)
```

**实用技巧**：处理双后缀文件（`.fastq.gz`、`.tar.gz`）

```python
p = Path("sample01.fastq.gz")

# 去掉全部后缀
p.stem                # 'sample01.fastq'  ← 只去最后一个
p.name.removesuffix(''.join(p.suffixes))  # 'sample01'

# 或自定义
def remove_all_suffixes(path: Path) -> str:
    return path.name[: -len(''.join(path.suffixes))]

remove_all_suffixes(p)  # 'sample01'
```

---

### 4. 绝对路径与相对路径

```python
p = Path("data/file.txt")

p.absolute()           # /home/user/Developer/data/file.txt
p.resolve()            # 同上，且解析符号链接+规范化
p.is_absolute()        # False

# 相对化
base = Path("/home/user/Developer")
p = Path("/home/user/Developer/data/raw/file.txt")
p.relative_to(base)    # PosixPath('data/raw/file.txt')
```

---

### 5. 文件读写

```python
p = Path("notes.txt")

# 文本
p.write_text("Hello, world!")       # 写入 str
content = p.read_text()             # 读取 -> str

# 二进制
p.write_bytes(b"\x00\x01\x02")      # 写入 bytes
data = p.read_bytes()               # 读取 -> bytes

# 追加
with p.open("a") as f:
    f.write("more content\n")
```

> **没有 `read_lines()`**，用 `p.read_text().splitlines()` 或 `p.open()` 配合上下文管理器。

---

### 6. 目录遍历

```python
data = Path("data")

# 列出直接子项
for child in data.iterdir():
    print(child.name, child.is_file(), child.is_dir())

# 通配符匹配（当前目录）
for f in data.glob("*.csv"):
    print(f.name)

# 递归匹配
for f in data.rglob("*.fastq.gz"):   # 等价于 glob("**/*.fastq.gz")
    print(f)

# 递归匹配目录
for d in data.rglob("*"):
    if d.is_dir():
        print(d)
```

**glob 模式速查**：

| 模式 | 含义 |
|------|------|
| `*.csv` | 当前目录下所有 CSV |
| `**/*.csv` | 递归所有 CSV |
| `*[0-9].csv` | 以数字结尾的 CSV |
| `[abc]*.py` | a/b/c 开头的 Python 文件 |
| `*.{py,md}` | Python 或 Markdown 文件 |

---

### 7. 文件/目录判断

```python
p = Path("data/file.txt")

p.exists()          # 是否存在
p.is_file()         # 是文件？
p.is_dir()          # 是目录？
p.is_symlink()      # 是符号链接？
p.is_absolute()     # 是绝对路径？
p.is_mount()        # 是挂载点？
```

---

### 8. 创建目录

```python
# 单级
Path("output").mkdir(exist_ok=True)

# 递归创建（类似 mkdir -p）
Path("output/2024/run01").mkdir(parents=True, exist_ok=True)
```

> **`parents=True`** = 递归创建父目录；**`exist_ok=True`** = 目录已存在时不报错。两者组合 = `mkdir -p`，建议任何时候都带上。

---

### 9. 删除

```python
# 删除文件
p = Path("temp.txt")
p.unlink(missing_ok=True)     # missing_ok=True: 文件不存在不报错 (3.8+)

# 删除空目录
d = Path("empty_dir")
d.rmdir()                     # 只能删空目录，非空报错

# 删除非空目录 → 用 shutil
import shutil
shutil.rmtree(str(d))         # 注意：旧版 shutil 吃字符串
shutil.rmtree(d)              # Python 3.12+ 直接吃 Path 对象
```

---

### 10. 重命名与移动

```python
p = Path("old_name.txt")

# 重命名（同一目录下）
p.rename("new_name.txt")                    # 传 str
p.rename(Path("new_name.txt"))              # 传 Path

# 移动到其他目录
p.rename(Path("archive") / p.name)

# 替换（覆盖已有文件）
p.replace(Path("target/file.txt"))          # 原子替换
```

---

### 11. 文件信息

```python
p = Path("data/file.txt")

p.stat()              # os.stat 结果包装
p.stat().st_size      # 文件大小（字节）
p.stat().st_mtime     # 修改时间戳

# 人类可读时间
from datetime import datetime
mtime = datetime.fromtimestamp(p.stat().st_mtime)

# 更方便的写法
p.lstat()             # 不追踪 symlink 的 stat

# 文件权限
oct(p.stat().st_mode)  # 如 0o100644
```

---

### 12. 符号链接

```python
target = Path("real_file.txt")
link = Path("my_link.txt")

# 创建
link.symlink_to(target)              # 符号软链接
link.hardlink_to(target)             # 硬链接

# 读取链接目标
link.readlink()                      # 3.9+

# 判断
link.is_symlink()
```

---

### 13. 修改文件名/后缀

```python
p = Path("data/sample01.fastq.gz")

# 改名不改后缀
p.rename(p.parent / f"{p.stem}_processed.gz")

# 只改后缀（.with_suffix 只操作最后一个后缀）
p.with_suffix(".bam")                # PosixPath('data/sample01.fastq.bam')

# 注意双后缀问题
p.with_suffix("")                    # PosixPath('data/sample01.fastq')

# 更名不换目录
p.with_name("sample02.fastq.gz")     # PosixPath('data/sample02.fastq.gz')
p.with_stem("sample02")              # PosixPath('data/sample02.fastq.gz')  (3.9+)
```

---

### 14. 跨平台与格式

```python
# Windows 路径转 POSIX（或反之）
from pathlib import PurePosixPath, PureWindowsPath

# 解析 Windows 网络路径
p = PureWindowsPath(r"\\server\share\file.txt")
p.parts          # ('\\\\server', 'share', 'file.txt')
p.drive          # ''（Windows 会返回 '\\\\server\\share'）

# POSIX 路径
pp = PurePosixPath("/data/file.txt")
pp.as_posix()    # "/data/file.txt" — 始终用 / 分隔
```

> Linux/macOS 用户基本不需要关心这些。

---

### 15. 实用组合技

#### 批量重命名扩展名

```python
from pathlib import Path

for f in Path("data").glob("*.txt"):
    f.rename(f.with_suffix(".md"))
```

#### 按修改时间排序

```python
from pathlib import Path

files = sorted(Path("data").iterdir(), key=lambda p: p.stat().st_mtime, reverse=True)
latest = files[0]
```

#### 递归收集特定文件

```python
from pathlib import Path

fastq_files = list(Path("raw_data").rglob("*.fastq.gz"))
print(f"Found {len(fastq_files)} FASTQ files")
```

#### 确保输出目录存在

```python
out = Path("results/figures")
out.mkdir(parents=True, exist_ok=True)
```

#### 安全读取（文件可能不存在）

```python
p = Path("config.yaml")
content = p.read_text() if p.exists() else "default"
```

#### 获取文件名（去后缀）

```python
p = Path("sample01_R1.fastq.gz")
sample_id = p.name.split("_R1")[0]  # 'sample01'
# 或
sample_id = p.stem.split(".fastq")[0]  # 'sample01_R1'
```

---

## 四、os.path → pathlib 对照速查表

| os.path | pathlib |
|---------|---------|
| `os.path.join(a, b)` | `Path(a) / b` |
| `os.path.basename(p)` | `Path(p).name` |
| `os.path.dirname(p)` | `Path(p).parent` |
| `os.path.splitext(p)` | `Path(p).suffix`（还有 `.stem`） |
| `os.path.exists(p)` | `Path(p).exists()` |
| `os.path.isfile(p)` | `Path(p).is_file()` |
| `os.path.isdir(p)` | `Path(p).is_dir()` |
| `os.path.abspath(p)` | `Path(p).resolve()` |
| `os.path.relpath(p, start)` | `Path(p).relative_to(start)` |
| `os.path.getsize(p)` | `Path(p).stat().st_size` |
| `os.path.getmtime(p)` | `Path(p).stat().st_mtime` |
| `os.listdir(d)` | `Path(d).iterdir()` |
| `glob.glob("**/*.py")` | `Path().rglob("*.py")` |
| `os.makedirs(d, exist_ok=True)` | `Path(d).mkdir(parents=True, exist_ok=True)` |
| `os.remove(f)` | `Path(f).unlink()` |
| `os.rename(src, dst)` | `Path(src).rename(dst)` |
| `os.path.expanduser("~")` | `Path.home()` |

---

## 五、实战：bioinfo 场景示例

### 场景 1：组织 FASTQ 文件

```python
from pathlib import Path

raw = Path("raw_data")
processed = Path("processed")

for f in raw.rglob("*.fastq.gz"):
    # 解析样本信息
    parts = f.stem.split("_")  # sample01_R1_001 -> ["sample01", "R1", "001"]
    sample_id = parts[0]
    read_pair = parts[1]       # R1 / R2
    
    # 构建输出路径
    out_dir = processed / sample_id
    out_dir.mkdir(parents=True, exist_ok=True)
    
    # 移动并改名
    dest = out_dir / f"{sample_id}_{read_pair}.fastq.gz"
    f.rename(dest)
```

### 场景 2：批量处理结果文件

```python
from pathlib import Path
import pandas as pd

results = []
for f in Path("results").glob("*_counts.csv"):
    sample = f.stem.replace("_counts", "")
    df = pd.read_csv(f)
    results.append({"sample": sample, "path": str(f), "n_genes": len(df)})

summary = pd.DataFrame(results)
```

### 场景 3：项目路径管理

```python
from pathlib import Path

class ProjectPaths:
    """项目路径管理，不在代码里写死路径字符串"""
    def __init__(self, root: Path):
        self.root = Path(root).resolve()
        self.raw_data = self.root / "data" / "raw"
        self.processed = self.root / "data" / "processed"
        self.figures = self.root / "results" / "figures"
        self.tables = self.root / "results" / "tables"
        self.logs = self.root / "logs"

    def ensure_dirs(self):
        for d in [self.raw_data, self.processed, self.figures, self.tables, self.logs]:
            d.mkdir(parents=True, exist_ok=True)

    def sample_fastq(self, sample_id: str, read: str = "R1") -> Path:
        return self.raw_data / f"{sample_id}_{read}.fastq.gz"

# 使用
paths = ProjectPaths(Path.cwd())
paths.ensure_dirs()
fastq = paths.sample_fastq("SAMPLE01", "R1")
```

---

## 六、最佳实践总结

1. **始终用 Path 对象**，不要混用 str 和 Path（旧库接口除外）
2. **用 `/` 拼接路径**，比 `os.path.join` 直观且少犯错
3. **`mkdir(parents=True, exist_ok=True)`** 是创建目录的标准写法
4. **`rglob` > `glob("**/*")`**，更明确
5. **`unlink(missing_ok=True)`** 抗删除不存在的文件
6. **拒绝字符串硬编码**路径，用 `Path.home()`、`Path.cwd()`、`Path(__file__).parent`
7. 项目路径封装成类（或 dataclass），一处定义全局使用

---

## 七、参考

- [PEP 428](https://peps.python.org/pep-0428/) — pathlib 最初提案
- [PEP 519](https://peps.python.org/pep-0519/) — 文件系统路径协议（PathLike）
- Python 文档: `python -c "import pathlib; help(pathlib.Path)"`
