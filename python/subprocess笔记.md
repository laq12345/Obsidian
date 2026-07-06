# subprocess — 调外部命令

你写的 Python 只能做 Python 自己的事。`subprocess` 让你调用任何命令行工具，是连接 Python 和外部世界的桥梁。

## 核心三板斧

```python
import subprocess

# ① 简单执行（不需要输出）
subprocess.run(["ls", "-la", "/tmp"])

# ② 拿输出
result = subprocess.run(
    ["echo", "hello world"],
    capture_output=True,   # 捕获 stdout/stderr
    text=True,             # 返回字符串，而不是 bytes
    check=True             # 非 0 退出码就抛异常
)
print(result.stdout)     # "hello world\n"
print(result.stderr)     # ""
print(result.returncode) # 0

# ③ shell 模式（懒人写法，有风险）
result = subprocess.run(
    "ls -la /tmp | head -3",
    shell=True,
    capture_output=True, text=True
)
```

## 参数说明

| 参数                    | 说明                         | 常用        |
| --------------------- | -------------------------- | --------- |
| `capture_output=True` | 捕获标准输出和错误                  | ✅ 几乎每次都用  |
| `text=True`           | 输出为字符串而非 bytes             | ✅         |
| `check=True`          | 命令失败抛 `CalledProcessError` | ✅ 流程中断言   |
| `shell=True`          | 用 shell 执行，支持管道/重定向        | ⚠️ 外部输入别用 |
| `timeout=30`          | 超时自动终止                     | 防卡死       |

## 调工具读输出（生信最常用模式）

```python
import subprocess

# run + check 是最常用的组合
result = subprocess.run(
    ["samtools", "flagstat", "sample.bam"],
    capture_output=True, text=True, check=True
)
for line in result.stdout.splitlines():
    if "mapped" in line and "%" in line:
        print(line)
```

## 管道

```python
# ✅ 推荐：Python 管理管道，每个命令独立可控
p1 = subprocess.Popen(
    ["cut", "-f1", "data.tsv"],
    stdout=subprocess.PIPE, text=True
)
result = subprocess.run(
    ["sort", "-u"],
    stdin=p1.stdout,
    capture_output=True, text=True
)
p1.stdout.close()
```

## 工作目录和环境变量

```python
# 指定工作目录
result = subprocess.run(["snakemake", "--cores", "4"], cwd="/path/to/project")

# 自定义环境变量
result = subprocess.run(
    ["bwa", "mem", "ref.fa", "sample.fastq"],
    env={"PATH": "/usr/local/bin:/usr/bin"}
)
```

## 实用技巧

```python
import subprocess

# 静默执行（不看输出）
subprocess.run(["touch", "f.txt"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

# 实时输出（给用户看进度）
process = subprocess.Popen(
    ["STAR", "--genomeDir", "index", "--readFilesIn", "sample.fastq"],
    stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True
)
for line in process.stdout:
    print(line, end="")

# 超时保护
try:
    subprocess.run(["long_task"], timeout=60, check=True)
except subprocess.TimeoutExpired:
    print("超时")
except subprocess.CalledProcessError:
    print("失败")
```

## 一句话总结

```python
subprocess.run(["你的", "命令"], check=True, capture_output=True, text=True)
```
