# uniq 命令

> `uniq` 过滤**相邻的**内容相同的行：合并、计数、筛选，写到输出。
> 本机版本：GNU coreutils 9.10（/usr/bin/uniq）。本文所有输出均为本机实跑结果。

## 语法

```bash
uniq [选项]... [输入文件 [输出文件]]
```

只有**两个**位置参数，含义和 sort/comm 完全不同：

- 第 1 个：输入文件（缺省读标准输入）；第 2 个：**输出文件**（缺省写标准输出）
- `uniq f1 f2` 是「读 f1、**覆盖** f2」，**不是读两个输入文件**——这和 sort/comm 完全不同
- 写 3 个参数直接报错：`uniq: 多余的操作对象 "c"`，退出码 1

**最大的前提：uniq 只比较相邻行。** 乱序的重复行它看不见：

```bash
$ printf 'a\nb\na\na\n' | uniq
a
b
a
```

所以要统计频次必须先 `sort`（`--help` 原文也强调：除非重复的行是相邻的，否则 uniq 将无法检测到它们，您可能需要事先对输入进行排序）。

## 常用选项

| 选项 | 长选项 | 作用 | 默认值 |
| --- | --- | --- | --- |
| `-c` | `--count` | 行首加该组重复次数 | 关闭；开启后 `%7d ` 右对齐，最小宽度 7 |
| `-d` | `--repeated` | 只输出有重复的行，每组一次 | 关闭 |
| `-u` | `--unique` | 只输出从未重复的行 | 关闭 |
| `-i` | `--ignore-case` | 比较时忽略大小写（仅 ASCII） | 关闭；区分大小写 |
| `-f N` | `--skip-fields=N` | 比较前跳过 N 个字段 | 0（不跳）；N=0~行长 |
| `-s N` | `--skip-chars=N` | 跳完字段后再跳 N 个字符 | 0（不跳） |
| `-w N` | `--check-chars=N` | 只比较每行前 N 个字符 | 0（不限，整行都比较） |
| `-D` | `--all-repeated[=METHOD]` | 输出重复行的每一份 | 关闭 |

不带任何选项时：相邻相同行只输出一次（就是「去重」行为）。

## 选项详解

### -c, --count

在每行前面加上**该组相邻相同行出现的次数**。

- 默认值：关闭；开启后输出格式为 **`%7d` 右对齐 + 一个空格 + 原行**（计数字段最小宽度 7，超过 7 位按实际位数）
- 取值：无参数

```bash
$ printf 'a\na\nb\n' | uniq -c
      2 a
      1 b
```

注意：宽度是**逐行计算**的，同一次运行里不同组的宽度可能不同（如 7 位和 8 位混合），所以**别用 `cut -c8-` 取原行**（短计数时会多一个空格，实测 `printf 'a\na\nb\n' | uniq -c | cut -c8-` 输出的是 ` a`、` b`，行首多了空格），要用 `sed 's/^ *[0-9]* //'`。

### -d, --repeated

只输出**出现过重复**的行，每组输出一次。

- 默认值：关闭
- 取值：无参数

```bash
$ printf 'a\nb\na\nc\nb\n' | sort | uniq -d
a
b
```

注意：一组重复只输出**一份**，要每份都输出用 `-D`。`-d` 和 `-u` 互斥，同时写无意义。

### -u, --unique

只输出**从未重复**的行（该组只有一行的才输出）。

- 默认值：关闭
- 取值：无参数

```bash
$ printf 'a\nb\na\nc\nb\n' | sort | uniq -u
c
```

注意：判定基于**相邻组**，同一个值出现两次但不相邻，会各算一组、都被输出，不排序时结果反直觉。

### -i, --ignore-case

比较时忽略大小写，输出保留**第一次出现的写法**。

- 默认值：关闭（区分大小写）
- 取值：无参数

```bash
$ printf 'A\na\nB\nb\nb\n' | uniq -i -c
      2 A
      3 B
```

注意：**只做 ASCII 字母折叠**，非 ASCII 不参与（`printf 'É\né\n' | uniq -i -c` 实测得 `1 É`、`1 é`，没合并）。要按 locale 折叠，先 `tr '[:upper:]' '[:lower:]'` 再 `uniq`。

### -f N, --skip-fields=N

比较前跳过每行开头的 N 个**字段**（字段 = 一段空白 + 一段非空白）。

- 默认值：0（不跳）
- 取值范围：N ≥ 0；超过行长时比较区只剩行尾可能残留的空白，一般等于空串
- 报错写法：`-f` 后面没跟数字会把**下一个参数当 N**：`uniq -f N.txt` → `uniq: N.txt: 要跳过的字段数无效`，退出码 1；负数同样报 `要跳过的字段数无效`

```bash
$ printf '2024-01-01 ERROR disk full\n2024-01-02 ERROR disk full\n2024-01-03 WARN cpu high\n' | uniq -f1
2024-01-01 ERROR disk full
2024-01-03 WARN cpu high
```

注意：**跳完字段后，原来那段分隔空白仍参与比较**，所以 TAB 和空格不算同一回事（`printf 'x\t1\nx 1\n' | uniq -f1 -c` 实测不合并，得 1、1）；叠 `-s 1` 把那段空白也跳掉才合并，实测输出 `2 x<TAB>1`。

另外空行没有字段可跳，会和相邻行并成一组：`printf 'a\n\nb\n' | uniq -f1 -c` 输出 `      3 a`。

### -s N, --skip-chars=N

跳过每行开头的 N 个**字符**（在 `-f` 跳完字段之后继续跳）。

- 默认值：0（不跳）
- 取值范围：N ≥ 0；**超过行长时比较区为空，所有行视为相同**：`printf 'abc\nxyz\n' | uniq -s100 -c` → `      2 abc`
- 报错写法：负数 → `uniq: -1: 要跳过的字节数无效`，退出码 1

```bash
$ printf 'ID-001\nID-002\nID-003\n' | uniq -s3 -c
      3 ID-001
```

注意：多字节字符（如中文）按**字节**跳，从 UTF-8 字符中间起跳会产生乱码比较区，结果不可预期；对齐场景优先用 `-f`。

### -w N, --check-chars=N

只比较每行的**前 N 个字符**（跳过 `-f`/`-s` 之后开始数）。

- 默认值：0，表示**不限长度**（整行参与比较）；注意 N=0 显式写出时含义反转——比较长度为 0，**所有行视为相同**：`printf 'a\nb\nc\n' | uniq -w0 -c` → `      3 a`
- 取值范围：N ≥ 0；负数 → `uniq: -1: 要比较的字节数无效`，退出码 1
- N 超过行长不报错，等效于整行都比较

```bash
$ printf 'foo1\nfoo2\nbar1\n' | uniq -w3 -c
      2 foo1
      1 bar1
```

注意：`-w0` 是合法参数但几乎一定是 bug；输出保留的是**该组第一行**的原文。

### -D, --all-repeated

输出重复行的**每一份**（区别于 `-d` 的每组一份）。

- 默认值：关闭
- 取值：无参数，或 `--all-repeated[=METHOD]`，METHOD 为 `none`（默认）/`prepend`/`separate`，用空行分隔各组

```bash
$ printf 'a\na\nb\nb\nb\nc\n' | sort | uniq -D
a
a
b
b
b
```

注意：`-c` 和 `-D` 同时用直接报错：`uniq: 输出所有重复的行且输出重复次数是没有意义的`，退出码 1。

## 使用示例

### 1. 统计频次（最经典的用法）

```bash
$ printf 'apple\nbanana\napple\ncherry\nbanana\napple\n' > F.txt
$ sort F.txt | uniq -c
      3 apple
      2 banana
      1 cherry
```

### 2. Top-N（按频次倒序取前几名）
```bash
$ sort F.txt | uniq -c | sort -rn | head -3
      3 apple
      2 banana
      1 cherry
```

`sort -rn` 的 `-n` 必须加，否则按字符串比较，`10` 会排在 `9` 前面。

### 3. 去重：`sort -u` 还是 `sort | uniq`？
只要去重清单用 `sort -u`，少一个进程。**数据本来就有序时**直接 `uniq`，别再叠 `sort`：

```bash
$ sort F.txt | uniq
apple
banana
cherry
$ sort -u F.txt        # 等价结果
apple
banana
cherry
```

### 4. 游程压缩 / 游程计数（不用排序）

```bash
$ printf 'a\na\na\nb\nb\na\n' | uniq -c
      3 a
      2 b
      1 a
```

第二个 `a` 不和前面的相邻，单独成组——这是 RLE（游程编码）的正确行为，不是 bug。

### 5. 忽略行首日志前缀，合并相同事件

```bash
$ printf '10:00 ERROR disk\n10:05 ERROR disk\n10:07 WARN cpu\n' | uniq -f1 -c
      2 10:00 ERROR disk
      1 10:07 WARN cpu
```

## 注意事项

| 问题 | 说明/怎么办 |
| --- | --- |
| 不排序就 `uniq -c` | 只看相邻行，计数全是 1 的废数据。前面加 `sort` |
| `uniq f1 f2` | 第 2 个参数是**输出文件**，会覆盖 f2，不是读两个输入。多文件先 `cat f1 f2 \| sort \| uniq -c` |
| **`uniq f f`（同名）** | **文件被清空成 0 字节，退出码 0，没有任何警告**（实测）。原地改用 `uniq f f.tmp && mv f.tmp f` |
| `-w 0` | 比较长度 0，所有行视为相同，整个输入并成一组。不要写 `-w0` |
| `-f`/`-s` 超过行长 | 比较区为空，所有行合并成一组（`uniq -s100` → 全并） |
| `-f N` 忘写数字 | 吞掉下一个参数当 N：`uniq -f N.txt` → `N.txt: 要跳过的字段数无效`，rc=1；负数同样报 `字段数/字节数无效`，rc=1 |
| `-f` 遇到空行 | 空行无字段可跳，会和相邻行并成一组。先 `grep -v '^$'` |
| CRLF 输入 | `a\r` 和 `a` 是两个字符串（实测 `cat -A` 可见 `^M`），先 `tr -d '\r'` |
| 选项互斥 | `-c` 与 `-D` 同用、`--group` 与 `-c/-d/-D/-u` 同用均报错退出，rc=1 |
| 剥掉 `-c` 的计数 | 别用 `cut -c8-`（宽度可变会错位），用 `sed 's/^ *[0-9]* //'` |

## 全部选项

| 选项 | 说明 |
| --- | --- |
| `-c, --count` | 在每行之前加上该行的重复次数作为前缀 |
| `-d, --repeated` | 只输出重复的行，每组重复的行输出一次 |
| `-D` | 输出所有重复的行 |
| `--all-repeated[=METHOD]` | 同 `-D`，但可用空行分隔各组；METHOD={none(默认),prepend,separate} |
| `-f, --skip-fields=N` | 比较时避免比较前 N 个字段 |
| `--group[=METHOD]` | 显示所有行，组间用空行分隔；METHOD={separate(默认),prepend,append,both} |
| `-i, --ignore-case` | 比较时忽略大小写 |
| `-s, --skip-chars=N` | 不要比较前 N 个字符 |
| `-u, --unique` | 只输出不重复（内容唯一）的行 |
| `-z, --zero-terminated` | 以 NUL 空字符而非换行符作为行分隔符 |
| `-w, --check-chars=N` | 每行比较不超过 N 个字符 |
| `--help` | 显示此帮助并退出 |
| `--version` | 输出版本信息并退出 |

`-z` 配合 `find -print0` 处理含换行/空格的文件名；`--group` 适合分组展示原始数据。

## 速查表

```bash
# ── 先排序再用（统计类）──────────────────────────
sort f | uniq -c                                # 每个值出现几次
sort f | uniq -c | sort -rn | head -10          # Top-10
sort f | uniq -d                                # 重复出现过的值
sort f | uniq -u                                # 只出现一次的值
sort -u f                                       # 只要去重清单（等价 sort f | uniq）
sort f | uniq -i                                # 忽略大小写去重（仅 ASCII）

# ── 不排序（只关心相邻）──────────────────────────
uniq f                                          # 压缩连续重复行
uniq -c f                                       # 游程计数（RLE）
uniq -f 1 f                                     # 忽略前 1 个字段（日志时间戳）
uniq -f 1 -s 1 f                                # 连分隔空白一起跳（TAB/空格混用）
uniq -w 3 f                                     # 只比较前 3 个字符

# ── 剥计数、取列 ─────────────────────────────────
uniq -c | sed 's/^ *[0-9]* //'                  # 安全剥掉计数字段
cut -f2 f.tsv | sort | uniq -c | sort -rn       # 按第 2 列统计频次

# ── 输入输出文件（小心！）────────────────────────
uniq in.txt out.txt                             # out.txt 会被覆盖
uniq f f.tmp && mv f.tmp f                      # 原地修改的唯一安全写法
find . -print0 | xargs -0 cat | sort | uniq -c  # -z 配合 NUL 流
```

## 相关笔记

[[sort命令详解]] · [[comm命令详解]] · [[cut命令详解]] · [[paste命令详解]] · [[grep用法]] · [[xargs-tutorial]]
