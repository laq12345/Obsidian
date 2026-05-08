---
lang: Linux
date: 2026-03-17
tags:
  - 编程
---

## 基本语法

```bash
grep [选项] "搜索模式" [文件]
```

## 常用选项

| 选项 | 说明 |
|------|------|
| `-i` | 忽略大小写 |
| `-v` | 反向匹配（显示不匹配的行）|
| `-n` | 显示行号 |
| `-c` | 只显示匹配行数 |
| `-l` | 只显示包含匹配内容的文件名 |
| `-r` / `-R` | 递归搜索目录 |
| `-w` | 匹配整个单词 |
| `-E` | 使用扩展正则表达式（等同于 `egrep`）|
| `-F` | 固定字符串匹配（等同于 `fgrep`）|
| `-o` | 只显示匹配的部分 |
| `-A n` | 显示匹配行及后 n 行 |
| `-B n` | 显示匹配行及前 n 行 |
| `-C n` | 显示匹配行及前后 n 行 |
| `--color` | 高亮显示匹配内容 |

## 常用示例

### 1. 基础搜索
```bash
grep "error" log.txt          # 在文件中搜索 "error"
grep "error" *.log            # 在多个文件中搜索
```

### 2. 忽略大小写
```bash
grep -i "error" log.txt       # 匹配 Error, ERROR, error 等
```

### 3. 显示行号
```bash
grep -n "error" log.txt       # 输出: 10:error message
```

### 4. 反向匹配
```bash
grep -v "error" log.txt       # 显示不包含 "error" 的行
```

### 5. 递归搜索目录
```bash
grep -r "error" /var/log/     # 在目录中递归搜索
grep -ri "error" .            # 当前目录递归，忽略大小写
```

### 6. 匹配整个单词
```bash
grep -w "error" log.txt       # 只匹配 "error"，不匹配 "errors"
```

### 7. 显示上下文
```bash
grep -C 3 "error" log.txt     # 显示匹配行及前后3行
grep -A 5 "error" log.txt     # 显示匹配行及后5行
```

### 8. 只显示匹配部分
```bash
grep -o "[0-9]\+" log.txt     # 只提取数字
```

### 9. 使用正则表达式
```bash
grep -E "^[0-9]{3}-[0-9]{4}$" file.txt    # 匹配电话号码格式
grep -E "error\|warning" log.txt          # 匹配 error 或 warning
```

### 10. 结合管道使用
```bash
ps aux | grep "nginx"         # 在进程列表中查找
cat log.txt | grep -i error | grep -v "debug"  # 组合过滤
```

### 11. 统计匹配行数
```bash
grep -c "error" log.txt       # 统计包含 error 的行数
```

### 12. 只列出文件名
```bash
grep -l "error" *.log         # 只显示包含 error 的文件名
```

## 常用组合技巧

```bash
# 查找并显示颜色（大多数系统默认已启用）
grep --color=auto "error" log.txt

# 排除二进制文件
grep -I "text" /path/*

# 排除特定文件类型
grep -r "pattern" . --exclude="*.min.js"

# 从文件中读取搜索模式
grep -f patterns.txt log.txt
```

## 相关命令

- `egrep` = `grep -E`（扩展正则表达式）
- `fgrep` = `grep -F`（固定字符串，更快）
- `zgrep`：在压缩文件中搜索
- `pgrep`：按名称查找进程 ID
