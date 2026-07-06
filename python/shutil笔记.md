# shutil — 文件高级操作

`os` 模块只能做最基础的：重命名、删除。`shutil` 是文件操作的**升级版**——复制、移动、归档、磁盘信息一键搞定。

## 文件/目录复制

```python
import shutil

shutil.copy("source.txt", "dest.txt")               # 复制文件
shutil.copy2("source.txt", "dest.txt")              # 复制文件 + 保留元数据
shutil.copytree("src_dir", "dst_dir")               # 复制整个目录
shutil.copytree("src", "dst", dirs_exist_ok=True)   # 允许目标已存在
```

## 移动和删除

```python
shutil.move("file.txt", "archive/")          # 移动文件（mv）
shutil.move("data/", "backups/data_2024/")   # 移动目录
shutil.rmtree("temp_dir")                    # 删除非空目录（rm -rf）
```

## 压缩/解压

```python
# 打包
shutil.make_archive("project_backup", "zip", "project/")        # → .zip
shutil.make_archive("project_backup", "gztar", "project/")      # → .tar.gz

# 解包
shutil.unpack_archive("project_backup.zip", "extracted/")
shutil.unpack_archive("project_backup.tar.gz", "extracted/")
```

## 其他实用函数

```python
shutil.disk_usage("/")                  # (total, used, free) 单位 bytes
shutil.which("samtools")               # 相当于 which，返回路径
shutil.get_terminal_size()             # (columns, lines) 终端大小
```

## 生信场景示例

```python
import shutil
from pathlib import Path

# 归档分析结果
output_dir = Path("backup/analysis_2026/")
output_dir.mkdir(parents=True, exist_ok=True)
for f in Path("results/").glob("*.csv"):
    shutil.copy2(f, output_dir / f.name)

# 临时文件安全清理
shutil.rmtree("temp_star_output", ignore_errors=True)
```
