# re — 正则表达式

正则是一套在文本中匹配模式的规则语言。Python 用 `re` 模块支持它。主要做三件事：**找 → 提取 → 替换**。

## 最常用的三个函数

```python
import re

text = "Sample: SRR1234567, Coverage: 98.5%, Platform: Illumina"

# ① re.search — 找到第一个匹配
match = re.search(r"SRR\d+", text)
if match:
    print(match.group())   # "SRR1234567"

# ② re.findall — 找到所有匹配
ids = re.findall(r"SRR\d+", "SRR111, SRR222, ERR333")
print(ids)  # ['SRR111', 'SRR222']

# ③ re.sub — 替换
result = re.sub(r"Coverage: [\d.]+%", "Coverage: **%", text)
```

## 常用语法速查

| 语法 | 含义 | 例子 |
|------|------|------|
| `.` | 任意一个字符（除换行） | `b.t` → "bat", "b3t" |
| `\d` | 数字 | `\d\d\d` → "123" |
| `\w` | 字母/数字/下划线 | `\w+` → "gene1" |
| `\s` | 空白字符（空格/Tab/换行） | 分隔符匹配 |
| `+` | 前面字符出现 **1次或多次** | `\d+` → "123", "7" |
| `*` | 前面字符出现 **0次或多次** | `\d*` → 可空 |
| `?` | 前面字符出现 **0次或1次** | `colou?r` → "color", "colour" |
| `[]` | 字符集，匹配其中任意一个 | `[ACTG]+` → DNA 序列 |
| `\|` | 或 | `TP53\|BRCA1` |
| `()` | 分组，提取特定部分 | 见下 |

## 分组提取 — 最实用的技能

```python
# 从 GFF 提取信息
line = "chr1\t.\tgene\t11869\t14409\t.\t+\t.\tgene_id ENSG00000223972"
pattern = r"chr(\w+).*\tgene\t(\d+)\t(\d+).*\[+-]"

match = re.search(pattern, line)
if match:
    chrom  = match.group(1)  # "1"
    start  = match.group(2)  # "11869"
    end    = match.group(3)  # "14409"

# 命名分组更清晰
pattern = r"chr(?P<chrom>\w+).*gene\t(?P<start>\d+)\t(?P<end>\d+)"
match = re.search(pattern, line)
match.group("chrom")
```

## 编译正则（多次重复时提速）

```python
# ✅ 推荐：只编译一次
header_pattern = re.compile(r">(\S+)")
for line in fasta_lines:
    match = header_pattern.search(line)
    if match:
        print(match.group(1))
```

## 生信场景实战

```python
import re

# 提取 FASTQ ID
fastq = "@SRR1234567.1 ABC-123 length=150"
re.search(r"@(\S+)", fastq).group(1)  # "SRR1234567.1"

# 提取所有样本名
text = "Sample: WT_01, Sample: KO_03"
re.findall(r"Sample: (\w+)", text)   # ['WT_01', 'KO_03']

# 从文件名提取信息
fname = "SRR1234567_L001_R1_001.fastq.gz"
m = re.search(r"(SRR\d+)_L(\d+)_R([12])_", fname)
srr  = m.group(1)  # "SRR1234567"
lane = m.group(2)  # "001"
read = m.group(3)  # "1"

# 替换多个空格为单个制表符
re.sub(r"\s+", "\t", "chr1  11869  14409  gene")

# 验证 FASTQ ID 格式
def is_valid_id(s: str) -> bool:
    return bool(re.match(r"^@[A-Z]{3}\d{7}\.\d+", s))
```

## 快速调试

正则写不对很正常。三步调试法：

```python
text = "Gene: TP53, logFC: -2.34, pvalue: 0.001"

# 从简单开始，逐步增加
re.search(r"Gene:", text)                       # 先匹配固定文本
re.search(r"Gene: (\w+)", text)                 # 再提取参数
re.search(r"logFC: (-?\d+\.?\d*)", text)        # 加数字匹配
re.search(r"pvalue: ([\d.e-]+)", text)          # 加科学计数法

# 最后拼成完整模式
p = r"Gene: (\w+), logFC: (-?\d+\.?\d*), pvalue: ([\d.e-]+)"
re.search(p, text).groups()
# ('TP53', '-2.34', '0.001')
```

## 什么时候用哪个

| 场景 | 函数 |
|------|------|
| "有没有 XXX？" | `re.search()` |
| "提取所有 XXX" | `re.findall()` |
| "替换 XXX 成 YYY" | `re.sub()` |
| "按规则拆分" | `re.split()` |
| "验证格式" | `re.fullmatch()` |
