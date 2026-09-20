# sort 命令

> 把输入的所有行按指定的规则重新排序，输出到标准输出（或用 `-o` 写回文件）。
> 本机版本：GNU coreutils 9.10（/usr/bin/sort）。本文所有输出均为本机实跑结果（locale `zh_CN.UTF-8`）。

## 语法

```bash
sort [选项]... [文件]...
sort [选项]... --files0-from=F
```

- 可跟多个文件，连在一起统一排序；不给文件或给 `-` 读标准输入；结果默认写标准输出，用 `-o` 写进文件。**原地排序用 `sort -o f f`**，不要写 `sort f > f`（会清空文件，见注意事项）。
- 不加选项时按当前 locale 的字典序排整行。

## 常用选项

| 选项 | 长选项 | 作用 | 默认值 |
|---|---|---|---|
| `-k` | `--key=KEYDEF` | 指定排序键（起,止位置） | 无：整行做键 |
| `-t` | `--field-separator=SEP` | 字段分隔符 | 无：按「空白→非空白」的转换切字段 |
| `-n` | `--numeric-sort` | 按数值大小比较 | 无：按字符逐个比（`10` 会排在 `9` 前） |
| `-r` | `--reverse` | 结果倒序 | 无：正序 |
| `-u` | `--unique` | 键相同的行只输出第一条 | 无：全部输出 |
| `-h` | `--human-numeric-sort` | 按人类可读大小比（`2K` `1G`） | 无 |
| `-V` | `--version-sort` | 版本号/自然数字顺序 | 无 |
| `-o` | `--output=FILE` | 输出写到文件（可原地排序） | 无：写标准输出 |
| `-c` | `--check` | 只检查是否已排序，不排序 | 无 |
| `-b` | `--ignore-leading-blanks` | 忽略键的前导空白 | 无：前导空白算进键 |
| `-f` | `--ignore-case` | 比较时忽略大小写 | 无：区分大小写 |
| `-s` | `--stable` | 稳定排序，关闭「回退到整行比较」 | 无：键相等时按整行比 |
| `-m` | `--merge` | 归并已排序的文件，不重新排 | 无：完整排序 |

## 选项详解

### -k, --key=KEYDEF

按**指定的键**排序，而不是整行。KEYDEF 是 `起始位置[,停止位置]`。

- 默认值：无（不写 `-k` 时用**整行**做键）
- 取值：`F`、`F,C`、`F.C`（列内字符位置）、`F,C` 后可加修饰符 `n`/`r`/`b` 等
- **停止位置省略时，默认排到行尾** —— 这是最容易踩的坑

```bash
$ printf 'a,2,x\nb,1,y\n' | sort -t, -k2,2
b,1,y
a,2,x
```

注意：**`-k2` 不是「只按第 2 列」，而是「从第 2 列到行尾」**。实测：

```bash
$ printf 'alice,10,zebra\nbob,10,apple\n' | sort -t, -k2
bob,10,apple        # 键是 "10,zebra" / "10,apple"，第 3 列反而成了主排序依据
alice,10,zebra
$ printf 'alice,10,zebra\nbob,10,apple\n' | sort -t, -k2,2
alice,10,zebra      # 键是 "10" / "10"，相等后回退到整行比较
bob,10,apple
```

- 位置从 1 开始数，**要只按某一列排必须把结束列也写上**；`-k3,3n` = 第 3 列、按数值比；`n`/`r` 等修饰符**贴在列号后面**，只作用于该键（`-k2,2r -k1,1` 可让不同键不同方向）。
- 键相等时默认**回退到整行比较**，不想回退加 `-s`（见 `-s` 小节）。
- `-k1.3,1.3` 表示第 1 列内的第 3 个字符；拿不准键取了哪段，用 `--debug` 看（下划线画出键范围）。

### -t, --field-separator=SEP

指定字段分隔符，配合 `-k` 按列排。

- 默认值：无。默认分隔符是「非空白到空白的转换」：连续空格/TAB 算一个分隔，且字段前的空白归属**后面那个字段**。
- 取值：**只能一个字符**。TAB 要写 `-t$'\t'`。

```bash
$ printf 'alice:x:1001\nbob:x:27\ncarol:x:1000\n' | sort -t: -k3,3n
bob:x:27
carol:x:1000
alice:x:1001
```

1. **只能一个字符**，写多了直接报错（rc=2）：

```bash
$ sort -t'  ' f
sort: 分隔符 “  ” 含有多个字符
```

2. **`-t' '` 和默认分隔符不等价**。默认把连续空白当一个分隔符；`-t' '` 严格按单个空格切，`a  10`（两个空格）的第 2 列会是空字符串：

```bash
$ printf 'a  10\nb 9\n' | sort -k2,2n     # 默认：键是 "10" / "9"
b 9
a  10
$ printf 'a  10\nb 9\n' | sort -t' ' -k2,2n   # -t' '：a 行第 2 列是空串
a  10
b 9
```

### -n, --numeric-sort

按字符串表示的**数值**比较，而不是逐字符比较。

- 默认值：无。
- 取值：认前导空白、正负号、数字、小数点；`1e3` 这种科学计数法**不认**（要用 `-g`）。想按某列的数值排，`n` 贴在键上：`-k2,2n`；全局 `-n` 对所有键生效。

```bash
$ printf '10\n9\n100\n' | sort
10
100
9
$ printf '10\n9\n100\n' | sort -n
9
10
100
```

### -r, --reverse

把比较结果倒过来，大的在前。

- 默认值：无（正序）。
- 注意：`-r` 反转**整个比较**，包括键相等后回退的整行比较；只想让某一个键倒序，把 `r` 贴在键上（`-k2,2r`），全局 `-r` 管所有键。

```bash
$ printf '10\n9\n100\n' | sort -rn
100
10
9
```

### -u, --unique

**键相同**的行只输出第一条（默认是全部输出）。

- 默认值：无。
- 去重的单位是「键」不是「整行」：不带 `-k` 时键是整行（常规去重）；`sort -u -k2,2` 会把第 2 列相同的行只留一条，哪怕整行不同。只要去重就用 `sort -u`，不要求重复行先挨在一起（`uniq` 只认相邻行）；要数次数得 `sort | uniq -c`，见使用示例。

```bash
$ printf 'banana\napple\napple\ncherry\napple\n' | sort -u
apple
banana
cherry
```

### -h, --human-numeric-sort

按「人类可读的数值大小」比较，专门对付 `du -h`、`df -h`、`ls -lh` 输出的 `2K` `481M` `2.3G`。

- 默认值：无。
- 取值：后缀认 `K M G T P E Z Y R Q`（大小写均可）及 `KiB` 系；`10M` > `1.5M` > `500K`。不用 `-h` 就按字符串比，`500K` 会排到 `10M` 后面。找最大的目录直接 `du -sh * | sort -rh | head`。

```bash
$ printf '500K\n1G\n10M\n' | sort -h
500K
10M
1G
```

### -V, --version-sort

版本号 / 自然排序：把字符串按「数字段 + 非数字段」切开来比，数字段按数值比。

- 默认值：无。
- 效果：`img9` < `img10` < `img100`；`1.9` < `1.10` < `2.0`。默认逐字符比会把 `img10.png` 排在 `img9.png` 前面；给带编号的文件名、软件版本号排序直接用它。

```bash
$ printf 'img10.png\nimg9.png\nimg1.png\n' | sort -V
img1.png
img9.png
img10.png
```

### -o, --output=FILE

把结果写到指定文件，而不是标准输出。

- 默认值：无（写标准输出）。
- 关键特性：**输入文件可以就是输出文件**，`sort -o f f` 是安全的原地排序（sort 内部先写临时文件再替换）；`sort f > f` 则会清空文件。`-o` 的位置随意（`sort f -o out` 也行）。

```bash
$ printf 'b\na\n' > o.txt && sort -o o.txt o.txt && cat o.txt
a
b
```

### -c, --check

只检查输入是否已排序，**不排序、不输出**。

- 默认值：无（正常排序）。
- 退出码：已排序为 `0`；未排序 `-c` 打印第一处乱序并返回 `1`，`-C` 静默只给退出码。检查标准与排序选项一致：检查「按第 2 列数值排好的」CSV，就得带上同样的 `-t, -k2,2n`。脚本里先 `sort -C f || sort -o f f` 可以避免对已排序文件做白工。

```bash
$ printf 'b\na\nc\n' | sort -c 2>&1; echo $?
sort: -:2: 无序：a
1
```

### -b, --ignore-leading-blanks

找键时忽略**前导空白**。

- 默认值：无。默认分隔符下，字段前的空白算进键里，多一个空格键就不同：两行键值相同但空格数不同，键其实不相等，会按整行比出「意外」结果；加 `-b` 后键才真正相等。`--debug` 可对比加 `-b` 前后的键范围；`-t` 指定分隔符时，分隔符后的前导空白仍算进键，想忽略同样加 `-b`。

```bash
$ printf 'a 1\nb  1\n' | sort -k2,2
b  1        # 键是 " 1" / "  1"，长度不同，按字符串比 b 行在前
a 1
$ printf 'a 1\nb  1\n' | sort -k2,2 -b
a 1         # 键都是 "1"，相等，回退整行比较，a 行在前
b  1
```

### -s, --stable

稳定排序：**关闭「键相等时回退到整行比较」**。

- 默认值：无。默认键相等的行还会按整行再比一次，输入的先后顺序保不住。先按 A 排好、再按 B 排时，想让 B 相同的行保持上一次 A 的顺序，第二次排序必须加 `-s`。

```bash
$ printf 'b 1\na 1\n' | sort -k2,2
a 1         # 第 2 列相等，回退整行比较，顺序被重排
b 1
$ printf 'b 1\na 1\n' | sort -k2,2 -s
b 1         # 保持输入顺序
a 1
```

### -m, --merge

归并模式：假定输入文件**已经各自排好序**，只做归并，不重新排序。

- 默认值：无（完整排序）。大文件场景下比完整排序快得多、省内存（只需顺序读入）；输入没排好序时**不报错**，但输出顺序是错的，用之前要保证输入确实有序。

```bash
$ printf '3\n5\n' > m1.txt; printf '1\n4\n' > m2.txt
$ sort -m m1.txt m2.txt
1
3
4
5
```

## 使用示例

**1. 多列排序：先按第 2 列数字，再按第 1 列（前面的键优先级高）：**

```bash
$ printf 'b 2\nc 1\na 2\n' | sort -k2,2n -k1,1
c 1
a 2
b 2
```

**2. 找占空间最大的几个目录（`du -h` 的输出必须用 `-h` 排）：**

```bash
$ du -sh /usr/* 2>/dev/null | sort -rh | head -3
4.6G	/usr/share
2.3G	/usr/lib
2.2G	/usr/lib64
```

**3. 词频统计三连：sort 聚集 → uniq -c 计数 → 按次数倒序：**

```bash
$ printf 'apple\nbanana\napple\ncherry\napple\n' | sort | uniq -c | sort -rn
      3 apple
      1 cherry
      1 banana
```

**4. CSV 第一行是表头，只排数据部分：**

```bash
$ printf 'name,age\nbob,9\nalice,30\n' > p.csv
$ { head -1 p.csv; tail -n +2 p.csv | sort -t, -k2,2n; }
name,age
bob,9
alice,30
```

## 注意事项

| 问题 | 说明/怎么办 |
|---|---|
| 默认按 locale 规则排序 | `zh_CN.UTF-8` 下 `a` 排在 `A` 前、`10` 排在 `9` 前。脚本里要稳定可预期的顺序写 `LC_ALL=C sort`（按字节比），而且**快得多**：实测 100 万行 6.9M，默认 0.320s，`LC_ALL=C` 0.120s |
| `-k2` 排序结果不对 | `-k2` 是「第 2 列到行尾」，只按第 2 列要写 `-k2,2`；拿不准用 `--debug` 看键范围 |
| `sort f > f` 清空文件 | 重定向在命令运行前就截断了文件（实测剩 0 字节）。原地排序用 `sort -o f f` |
| `-t` 报「含有多个字符」 | `-t` 只能一个字符，rc=2；TAB 写 `-t$'\t'`；`-t' '` 严格单空格切与默认不等价，多空格分隔靠默认行为 |
| 数字没按大小排 | 默认逐字符比，`100` 排在 `9` 前。数值加 `-n`，`du -h` 输出加 `-h`，版本号加 `-V` |
| CSV 表头被排进数据 | 用 `{ head -1 f; tail -n +2 f \| sort -t, -k2,2n; }` 把表头拎出来 |
| 键相等时顺序被重排 | 默认回退到整行比较。要保住输入顺序（二次排序场景）加 `-s` |
| 想按某列去重却去多了/少了 | `-u` 按**键**去重：不带 `-k` 去重整行，`-u -k2,2` 只按第 2 列去重 |

## 全部选项

| 选项 | 说明 |
|---|---|
| `-b`, `--ignore-leading-blanks` | 找键时忽略前导空白 |
| `-c`, `--check` | 检查输入是否已排序，不排序（报告第一处乱序） |
| `-C`, `--check=quiet` | 同 `-c`，但不报告第一处乱序 |
| `-d`, `--dictionary-order` | 只考虑空白、字母和数字 |
| `-f`, `--ignore-case` | 比较时忽略大小写 |
| `-g`, `--general-numeric-sort` | 通用数值比较（认科学计数法，比 `-n` 慢） |
| `-h`, `--human-numeric-sort` | 按人类可读数值比较（如 2K 1G） |
| `-i`, `--ignore-nonprinting` | 只考虑可打印字符 |
| `-k`, `--key=KEYDEF` | 按指定的键排序 |
| `-m`, `--merge` | 归并已排序的文件，不重新排序 |
| `-M`, `--month-sort` | 按月份名比较（JAN < FEB < … < DEC） |
| `-n`, `--numeric-sort` | 按字符串数值比较 |
| `-o`, `--output=文件` | 结果写入指定文件而非标准输出 |
| `-r`, `--reverse` | 逆序输出排序结果 |
| `-R`, `--random-sort` | 随机打乱，但相同的键聚在一起（另见 shuf） |
| `--random-source=文件` | 从指定文件获取随机字节（配合 `-R`） |
| `-s`, `--stable` | 禁用最后的整行比较，成为稳定排序 |
| `-S`, `--buffer-size=大小` | 指定内存缓冲区大小（可加 %/K/M/G 后缀） |
| `-t`, `--field-separator=分隔符` | 指定字段分隔符（单个字符） |
| `-T`, `--temporary-directory=目录` | 指定临时文件目录（默认 $TMPDIR 或 /tmp） |
| `-u`, `--unique` | 键相同的行只输出第一条；配合 `-c` 检查严格有序 |
| `-V`, `--version-sort` | 文本中（版本）数字的自然排序 |
| `-z`, `--zero-terminated` | 用 NUL 而非换行符作为行分隔符 |
| `--batch-size=NMERGE` | 一次最多归并的输入数，超出的用临时文件 |
| `--compress-program=程序` | 用指定程序压缩临时文件（解压用 程序 -d） |
| `--debug` | 标注每行实际用于排序的键，并对可疑用法告警 |
| `--files0-from=文件` | 从以 NUL 分隔的文件名列表文件读取输入 |
| `--parallel=N` | 设置排序并发线程数为 N |
| `--sort=WORD` | 按类型排序：general-numeric(-g)、human-numeric(-h)、month(-M)、numeric(-n)、random(-R)、version(-V) |
| `--help` | 显示帮助并退出 |
| `--version` | 输出版本信息并退出 |

## 速查表

```bash
# 基础
sort f                        # 整行按 locale 字典序
LC_ALL=C sort f               # 按字节排：稳定、可预期、快
sort -u f                     # 排序 + 按键去重

# 按列
sort -k2,2n f                 # 第 2 列按数值（只按一列必须写结束列）
sort -k2,2n -k1,1 f           # 先第 2 列数字，再第 1 列
sort -t, -k3,3n f             # CSV 按第 3 列数值
sort -k2,2 -s f               # 稳定排序，保持输入顺序

# 特殊数值
sort -rh f                    # 1K / 2M / 1G 从大到小（du -h、df -h 输出）
sort -V f                     # 版本号：img9 < img10

# 检查 / 输出 / 调试
sort -c f                     # 检查是否已排序，乱序报第一处，rc=1
sort -o f f                   # 原地排序（安全；不要 sort f > f）

# 经典管道
du -sh * | sort -rh | head            # 最大的几个目录
sort f | uniq -c | sort -rn           # 词频统计
{ head -1 f; tail -n +2 f | sort -t, -k2,2n; }   # 带表头的 CSV 排序
```

## 相关笔记

[[uniq命令详解]]、[[comm命令详解]]、[[cut命令详解]]、[[paste命令详解]]、[[grep用法]]、[[xargs-tutorial]]
