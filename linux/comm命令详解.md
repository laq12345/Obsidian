---
time: 2026-09-19T17:00:00
lang: Linux
tags:
  - 工具
  - linux
  - coreutils
  - comm
  - 文本处理
---

# comm 命令

> 逐行比较两个**已排序**文件，一次给出「只在文件 1」「只在文件 2」「两边都有」三类结果，用来做交集、差集。
> 本机版本：GNU coreutils 9.10（`/usr/bin/comm`）。本文所有输出均为本机实跑结果。

## 语法

```bash
comm [选项]... 文件1 文件2
```

- 两个文件都必须**已经排序**，且用**同一个 locale** 排（见选项详解里 `--check-order` 一节）。`comm` 自己不排序，输入乱序时给的是**错的结果**，并报 `comm: 文件 1 没有被正确排序`、退出码 1。
- 输出**固定三列**：第 1 列 = 只在文件 1 的行，第 2 列 = 只在文件 2 的行，第 3 列 = 两边都有的行。
- 列之间用 **TAB 分隔，空列也会输出它对应的 TAB**：属于第 3 列的行前面有两个 TAB，属于第 2 列的行有一个，第 1 列的行没有。行尾永远没有 TAB。
- `-` 表示标准输入（两个不能都是 `-`）。

## 三列输出与集合运算

```bash
$ printf 'apple\nbanana\ncherry\ndate\n' > a
$ printf 'banana\ndate\nelderberry\n' > b
$ comm a b | cat -A          # cat -A 把 TAB 显示成 ^I
apple$                       # 第 1 列：只在 a，无前导 TAB
^I^Ibanana$                  # 第 3 列：两边都有，前面两个 TAB
cherry$
^I^Idate$
^Ielderberry$                # 第 2 列：只在 b，前面一个 TAB
```

想要哪个集合 = **抑制掉另外的列**。方向极易记反，记死一句：**只留第 3 列就是交集**。

| 想要的集合 | 抑制哪几列 | 命令 |
| --- | --- | --- |
| 交集（两边都有） | 1、2 | `comm -12 a b` |
| 只在 a（差集 a−b） | 2、3 | `comm -23 a b` |
| 只在 b（差集 b−a） | 1、3 | `comm -13 a b` |
| 差异（只在一侧） | 3 | `comm -3 a b` |

## 常用选项

| 选项 | 作用 |
| --- | --- |
| `-1` | 不输出第 1 列 |
| `-2` | 不输出第 2 列 |
| `-3` | 不输出第 3 列 |
| `--output-delimiter=字符串` | 换列分隔符（默认 TAB） |
| `--total` | 末尾追加汇总行 |
| `--check-order` / `--nocheck-order` | 是否检查输入排序 |
| `-z, --zero-terminated` | 行分隔符用 NUL |

## 选项详解

### -1 / -2 / -3

抑制（不输出）第 N 列。

- 默认值：不加选项时三列全输出。
- 组合含义（**方向容易记反**）：
  - `-12` → 只剩第 3 列 = **交集**（两边都有）
  - `-23` → 只剩第 1 列 = **只在文件 1**
  - `-13` → 只剩第 2 列 = **只在文件 2**
  - `-3`  → 第 1、2 列 = 两边的差异

```bash
$ printf 'apple\nbanana\ncherry\ndate\n' > a
$ printf 'banana\ndate\nelderberry\n' > b
$ comm -12 a b
banana
date
$ comm -23 a b
apple
cherry
```

注意：**记忆法 —— "只留第 3 列就是交集"**。想留哪列，就抑制**另外两列**。`-23` 里的 2 是**列号**，不是文件号。数字可拆开写（`comm -1 -2 a b` 等价 `-12`，实测输出相同）。

### --output-delimiter=字符串

把列分隔符从 TAB 换成指定字符串。

- 默认值：TAB；**空列照样输出它对应的分隔符**，所以第 3 列的行前面会变成两个分隔符。
- 取值：任意字符串；想用真正的 TAB 写 `$'\t'`，想用竖线注意它和 shell 管道转义。

```bash
$ comm --output-delimiter='|' a b | cat -A
apple$
||banana$         # 两边都有 → 两个分隔符
cherry$
||date$
|elderberry$      # 只在文件 2 → 一个分隔符
```

注意：主要用来把输出给别的程序或人工看。要干净单列输出，首选 `-12`/`-23`/`-13`，比事后去分隔符更稳。

### --total

在正常输出末尾追加一行汇总：第 1、2、3 列各有多少行，最后是 `总计`。

- 默认值：不输出汇总行。
- 取值：开关型，无参数。汇总行用 TAB 分隔。

```bash
$ comm --total a b | tail -1 | cat -A
2^I1^I2^IM-fM-^@M-;M-hM-.M-!$     # 即 2	1	2	总计
```

注意：想只看数字不要明细，把它和抑制选项组合，比如 `comm -12 --total a b` 只剩交集行 + 汇总行。配合 `-` 从管道读也没问题。

### --check-order / --nocheck-order

是否检查输入是否被正确排序。

- 默认值：`comm` **默认就检查**（等价于 `--check-order`），发现乱序时报 `comm: 文件 1 没有被正确排序`、退出码 1。`--check-order` 的区别是：即使所有行恰好都能匹配也照样检查。
- `--nocheck-order`：完全不检查，乱序输入不报错（结果照样是错的）。
- 取值：开关型，两者互斥。

```bash
$ printf 'zeta\nalpha\nmike\n' > u1        # 乱序
$ printf 'mike\n' > u2
$ comm u1 u2 | cat -A
^Imike$                                    # 错：mike 被判成「只在文件 2」
zeta$
alpha$
mike$                                      # 又被判成「只在文件 1」
comm: 文件 1 没有被正确排序                # （stderr）
comm: 输入没有被正确排序
$ comm --nocheck-order u1 u2 | cat -A      # 不检查：不报错，结果照样是错的
^Imike$
zeta$
alpha$
mike$
```

注意：两个文件内容完全一样且都乱序时，默认 `comm` **不警告、退出码 0**（实测 `printf 'banana\nalpha\n' | tee q1 > q2; comm q1 q2` 静默通过），别指望它替你发现排序问题。最稳的做法是两侧统一写 `LC_ALL=C sort`。

### -z, --zero-terminated

把行分隔符从换行符换成 NUL（`\0`）。

- 默认值：换行符分隔。
- 取值：开关型。**输入和输出同时改用 NUL**，必须和其它 NUL 工具（`sort -z`、`find -print0`、`xargs -0`）配套使用。

```bash
$ printf 'apple\0banana\0cherry\0date\0' > az
$ printf 'banana\0date\0elderberry\0'    > bz
$ comm -z az bz | cat -A                 # ^@ 即 NUL，整个输出连成一行
apple^@^I^Ibanana^@cherry^@^I^Idate^@^Ielderberry^@
```

注意：若输入文件里没有 NUL（还是普通换行文本），整个文件会被当成**一行**，结果完全不对——上例若直接拿 `a`、`b` 跑 `comm -z`，得到的就是两个文件各算作一行。必须先用 `tr '\n' '\0'` 或 `sort -z` 把输入变成 NUL 分隔。

## 使用示例

### 1. 求交集：两份清单里都有的行

```bash
$ comm -12 a b
banana
date
```

找两个目录都有的文件、两天都出现的 IP、两份软件包列表的共同项，都是它。结果没有前导 TAB，可直接用。

### 2. 求差集：新加了什么 / 少了什么

```bash
$ comm -13 旧清单 新清单      # 新增（只在新那份里）
elderberry
$ comm -23 旧清单 新清单      # 消失（只在旧那份里）
apple
cherry
```

### 3. 进程替换：不落临时文件，比两条命令的输出

```bash
$ comm -23 <(ls dirA | LC_ALL=C sort) <(ls dirB | LC_ALL=C sort)   # 只在 dirA
alpha.txt
gamma.txt
$ comm -13 <(ls dirA | LC_ALL=C sort) <(ls dirB | LC_ALL=C sort)   # 只在 dirB
delta.txt
```

`sort` 的代价一点没省，两边必须同一 locale，所以都写 `LC_ALL=C`。

## 注意事项

| 问题 | 说明/怎么办 |
| --- | --- |
| 输入没排序 | 结果**错**（同一行被算进两侧），报 `comm: 文件 1 没有被正确排序`、退出码 1；但两文件完全相同且都乱序时**不报警、退出码 0**。两侧统一 `LC_ALL=C sort` |
| 两边排序 locale 不一致 | 同一批数据被判「没排序」，交集甚至为空。排序和比较都受 `LC_COLLATE` 控制，两侧统一写 `LC_ALL=C` |
| 前导 TAB 干扰后处理 | 空列也输出 TAB，`comm -3 a b | cut -f1` 会让带 TAB 的行变空行丢失。先用 `sed 's/^\t*//'` 或直接用 `-12`/`-23`/`-13` 选列 |
| 退出码不表达比较结果 | 有无差异都是 0（实测相同/不同内容均返回 0）；打不开文件才是 1。判断差异用 `[ -z "$(comm -3 a b)" ]` 或数行数 |
| 文件打不开 | 退出码 1，**stdout 一个字节都没有**（不是输出一半），报错在 stderr |
| 重复行按次数一一配对 | 同一行在两侧出现次数不同会产生多余「差异」。清单类输入先 `sort -u` |
| CRLF 文件 | `\r` 算行内容，两边全对不上。先 `tr -d '\r'` |
| 大写字母大小 | 默认 locale 下 `Zebra` 和 `zebra` 排序/相等规则随 locale 变，跨机器脚本务必 `LC_ALL=C` |

## 全部选项

| 选项 | 说明 |
| --- | --- |
| `-1` | 不输出第 1 列（文件 1 特有的行） |
| `-2` | 不输出第 2 列（文件 2 特有的行） |
| `-3` | 不输出第 3 列（两个文件共有的行） |
| `--check-order` | 检查输入是否被正确排序，即使所有输入行都能匹配 |
| `--nocheck-order` | 不检查输入是否被正确排序 |
| `--output-delimiter=字符串` | 使用指定字符串分隔各列 |
| `--total` | 输出一份摘要信息 |
| `-z, --zero-terminated` | 以 NUL 而非换行符作为行分隔符 |
| `--help` | 显示帮助并退出 |
| `--version` | 输出版本信息并退出 |

> 注：本机 coreutils 9.10 中文 `comm --help` 有翻译 bug，把 `-3` 的标签印成了 `-2`（描述却是"不输出第 3 列"）。上表以实测行为为准。

## 速查表

```bash
# ── 集合运算（两侧都必须已排序）──────────────
comm -12 a b                      # 交集：两边都有
comm -23 a b                      # 只在文件 1
comm -13 a b                      # 只在文件 2
comm -3  a b                      # 差异（混两列，带前导 TAB）
comm a b | sed 's/^\t*//'         # 并集：单列、有序、去重
# ── 排序没保证时，现场排好再比 ──────────────
comm -12 <(LC_ALL=C sort a) <(LC_ALL=C sort b)
# ── 计数与判断 ──────────────────────────────
comm -23 a b | wc -l              # 只在文件 1 的行数
[ -z "$(comm -3 a b)" ] && echo 一致
# ── 显示辅助 ────────────────────────────────
comm a b | cat -A                 # 看清 TAB 列边界
comm --total -12 a b              # 交集 + 汇总行
```

## 相关笔记

[[sort命令详解]] · [[uniq命令详解]] · [[cut命令详解]] · [[paste命令详解]] · [[grep用法]] · [[xargs-tutorial]]
