---
lang: Linux
date: 2026-03-17
tags:
  - 编程
---

## 基本语法

```bash
sed [选项] '命令' 文件
sed [选项] -e '命令1' -e '命令2' 文件
```

## 常用选项

| 选项 | 说明 |
|------|------|
| `-i` | 直接修改文件内容（in-place）|
| `-e` | 执行多个命令 |
| `-n` | 静默模式，只打印经过处理的行 |
| `-r` | 使用扩展正则表达式 |
| `-f` | 从脚本文件读取命令 |

## 核心命令

| 命令 | 说明 |
|------|------|
| `p` | 打印行 |
| `d` | 删除行 |
| `s` | 替换 |
| `a` | 在当前行后添加文本 |
| `i` | 在当前行前插入文本 |
| `c` | 替换整行 |
| `y` | 字符转换 |
| `q` | 退出 |

---

## 常用示例

### 1. 替换操作（最常用）

```bash
# 基本替换：将每行第一个 old 替换为 new
sed 's/old/new/' file.txt

# 全局替换（g）：将所有 old 替换为 new
sed 's/old/new/g' file.txt

# 替换第2个匹配项
sed 's/old/new/2' file.txt

# 替换第2个及之后的所有匹配项
sed 's/old/new/2g' file.txt

# 使用正则表达式
sed 's/^[0-9]*/XXX/' file.txt

# 使用分隔符（当替换内容含 / 时）
sed 's#/usr/local#/opt#g' file.txt    # 可用 # | 等替代 /
```

### 2. 直接修改文件（`-i` 选项）

```bash
# 直接修改文件（危险操作，建议先备份）
sed -i 's/old/new/g' file.txt

# 修改前创建备份
sed -i.bak 's/old/new/g' file.txt    # 生成 file.txt.bak

# 多文件处理
sed -i 's/foo/bar/g' *.txt
```

### 3. 删除行

```bash
# 删除第3行
sed '3d' file.txt

# 删除第2到5行
sed '2,5d' file.txt

# 删除包含 pattern 的行
sed '/pattern/d' file.txt

# 删除以 # 开头的行（注释行）
sed '/^#/d' file.txt

# 删除空行
sed '/^$/d' file.txt

# 删除最后一行
sed '$d' file.txt
```

### 4. 打印特定行

```bash
# 只打印第5行（-n 配合 p）
sed -n '5p' file.txt

# 打印第5到10行
sed -n '5,10p' file.txt

# 打印包含 pattern 的行
sed -n '/pattern/p' file.txt

# 打印奇数行
sed -n '1~2p' file.txt
```

### 5. 添加和插入文本

```bash
# 在第3行后添加（a 命令）
sed '3a\This is new line' file.txt

# 在第3行前插入（i 命令）
sed '3i\This is inserted' file.txt

# 在最后一行后添加
sed '$a\END OF FILE' file.txt

# 在包含 pattern 的行后添加
sed '/pattern/a\New line after pattern' file.txt
```

### 6. 替换整行

```bash
# 将包含 pattern 的行替换为新内容
sed '/pattern/c\REPLACED LINE' file.txt
```

### 7. 字符转换（y 命令）

```bash
# 小写转大写
sed 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' file.txt

# 简写（使用 tr 更方便，但 sed 也可以）
sed 'y/a-z/A-Z/' file.txt
```

### 8. 多重命令组合

```bash
# 使用分号分隔多个命令
sed 's/foo/bar/; s/baz/qux/' file.txt

# 使用 -e 连接多个命令
sed -e 's/foo/bar/' -e 's/baz/qux/' file.txt

# 从文件读取命令
sed -f script.sed file.txt
```

### 9. 从管道读取

```bash
# 结合其他命令使用
cat file.txt | sed 's/old/new/g'

# 处理命令输出
ps aux | sed -n '/nginx/p'

# 只显示 IP 地址
ifconfig | sed -n 's/.*inet \([0-9.]*\).*/\1/p'
```

### 10. 高级替换技巧

```bash
# 使用反向引用（括号需转义或使用 -r）
echo "John Smith" | sed 's/\([a-zA-Z]*\) \([a-zA-Z]*\)/\2, \1/'
# 输出: Smith, John

# 使用扩展正则（-r 或 -E，无需转义括号）
echo "John Smith" | sed -r 's/([a-zA-Z]+) ([a-zA-Z]+)/\2, \1/'

# 获取文件路径的目录名
echo "/usr/local/bin/app" | sed 's|/[^/]*$||'
# 输出: /usr/local/bin

# 获取文件名
echo "/usr/local/bin/app" | sed 's|.*/||'
# 输出: app
```

### 11. 行号相关操作

```bash
# 显示行号（= 命令）
sed '=' file.txt | sed 'N;s/\n/ /'

# 在匹配行前显示行号
sed -n '/pattern/{=;p}' file.txt

# 从第5行开始替换
sed '5,$s/old/new/' file.txt
```

### 12. 读取和写入文件

```bash
# 将包含 pattern 的行写入另一个文件
sed -n '/pattern/w output.txt' file.txt

# 在第5行后读取另一个文件内容
sed '5r other.txt' file.txt
```

---

## 实用组合案例

```bash
# 清理日志文件：删除空行和注释行
sed -i '/^#/d; /^$/d' config.conf

# 批量修改配置文件中的 IP
sed -i 's/192.168.1.1/10.0.0.1/g' *.conf

# 在文件开头添加一行
sed -i '1i\# Auto-generated config' file.txt

# 在文件末尾添加一行
sed -i '$a\# End of config' file.txt

# 提取特定范围内容到另一个文件
sed -n '10,50p' file.txt > newfile.txt

# 替换多行内容（使用 \n）
sed ':a;N;$!ba;s/pattern1\npattern2/replacement/' file.txt
```

---

## sed vs grep 对比

| 场景 | 推荐工具 |
|------|---------|
| 仅搜索查看 | `grep` |
| 搜索并修改文件 | `sed` |
| 复杂文本转换 | `sed` / `awk` |
| 数据提取计算 | `awk` |
