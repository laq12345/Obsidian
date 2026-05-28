---
date: 2026-05-27
lang: Linux
tags:
  - 编程
  - 工具
  - linux
  - fish
  - shell
  - terminal
---

# Fish for Bash Users — 迁移速查

> 基于 [fish 官方文档](https://fishshell.com/docs/current/fish_for_bash_users.html)
> fish 刻意不兼容 POSIX，很多习惯用法需要改变。

---

## 命令替换

```bash
# bash
$(command)
`command`

# fish
$(command)         # 可用
(command)          # 可用
`command`          # ❌ 不支持
```

**关键差异：** fish 仅按换行符分割命令替换结果（不按 `$IFS`）。需要按其他分隔符分割时用 `string split`：

```fish
for i in (find . -print0 | string split0)
    echo $i
end
```

---

## 变量

### 基本操作

```bash
# bash
export PAGER=less
local foo=bar
unset PAGER
VAR=VAL command    # 环境覆盖

# fish
set -gx PAGER less          # 全局+导出（等价 export）
set -l foo bar               # 局部
set -e PAGER                 # 删除
PAGER=cat git log           # 环境覆盖（同 bash）
```

### 不存在词拆分

fish 不会对变量值按空格进一步拆分，`"$var"` 不是必需的：

```bash
# bash
foo="bar baz"
printf '"%s"\n' $foo     # 两行: "bar" "baz"（被拆分了）

# fish
set foo "bar baz"
printf '"%s"\n' $foo     # 一行: "bar baz"（不拆分）
```

### 所有变量都是列表

```fish
set var "foo bar" banana
printf '%s\n' $var           # 两行: foo bar / banana

# 等价 bash 的 "${var[@]}" 行为

# 取特定元素
echo $list[5..7]              # 索引从 1 开始

# 混合字面量和命令输出
set numbers 1 2 3 (seq 5 8) 9
```

### `set` 注意事项

```fish
set foo = bar     # ❌ foo 被设为两个值: "=" 和 "bar"
set foo=bar       # ❌ 报错
set foo bar       # ✓
```

---

## 通配符

| 特性    | bash                      | fish                           |
| ----- | ------------------------- | ------------------------------ |
| `*`   | 支持                        | 支持                             |
| `**`  | 需 `shopt -s globstar`     | 默认支持                           |
| `?`   | 支持                        | 已弃用                            |
| 无匹配行为 | 取决于 `failglob`/`nullglob` | 默认命令失败（`for`/`set`/`count` 除外） |
| 对变量展开 | 会                         | 不会                             |
| 符号链接  | 不跟随                       | 默认跟随                           |
| 排序方式  | 字典序                       | 自然排序（数字按数值比较）                  |

```fish
echo *.jpg          # 正常匹配
echo **.rs          # 递归匹配所有 .rs 文件
set foo "*"
echo $foo           # 输出 *，不展开
```

---

## 引号

```fish
echo "hello $USER"   # 双引号：展开变量
echo 'hello $USER'   # 单引号：不展开

# 没有 $'...'，转义序列在无引号时直接解析
echo a\nb           # 输出 a 换行 b
```

---

## 字符串处理

fish 没有 `${foo%bar}`、`${foo#bar}`、`${foo/bar/baz}`，用 `string` 命令：

```fish
# 替换
string replace bar baz "bar luhrmann"     # baz luhrmann

# 分割
string split "," "foo,bar"               # foo / bar

# 正则匹配
echo bababa | string match -r 'aba$'      # aba

# 填充
string pad -c x -w 20 "foo"              # xxxxxxxxxxxxxxxxxfoo

# 大小写
string lower Foo        # foo
string upper Foo        # FOO

# 重复
string repeat -n 5 "ha"  # hahahahaha

# 修剪
string trim "  hello  "   # hello

# 长度
string length "hello"     # 5
```

---

## 特殊变量对照表

| bash                | fish                                        | 说明           |
| ------------------- | ------------------------------------------- | ------------ |
| `$*`, `$@`, `$1`... | `$argv`                                     | 参数列表         |
| `$?`                | `$status`                                   | 退出状态码        |
| `$$`                | `$fish_pid`                                 | 当前 shell PID |
| `$#`                | `count $argv`                               | 参数个数         |
| `$!`                | `$last_pid`                                 | 最后一个后台进程 PID |
| `$0`                | `status filename`                           | 脚本文件名        |
| `$-`                | `status is-interactive` / `status is-login` | Shell 状态     |

---

## 进程替换

```bash
# bash
source <(command)
cmd >(other_cmd)

# fish（只有输入方向）
source (command | psub)     # psub = process substitution
cmd (command | psub)

# 更好的写法（fish 的 source 可从 stdin 读取）
command | source
```

没有 `>(command)` 输出方向等价物。

---

## Heredoc

fish 没有 `<<EOF` 语法，用以下方式替代：

```bash
# bash
cat <<EOF
some string
some more string
EOF

# fish
echo "some string
some more string"

# 或
printf '%s\n' "some string" "some more string"

# 多行带引号
echo "\
some string
some more string\
"

# 管道替代（heredoc 本质就是管道）
echo "xterm
rxvt-unicode" | pacman --remove -
```

---

## 条件测试

```bash
# bash
if [[ "$a" == "$b" ]]; then ... fi
if [ "$a" = "$b" ]; then ... fi

# fish（只有 POSIX test，没有 [[，== 不可用）
if test "$a" = "$b"; ...
end

# 检查变量是否存在 / 元素数量
if set -q foo
    echo "foo 已定义"
end

if set -q foo[2]
    echo "foo 至少有 2 个元素"
end

# test 支持浮点数比较
if test 3.14 -gt 2.0
    echo "yes"
end
```

---

## 算术展开

```bash
# bash
echo $((i + 1))

# fish（用 math 命令）
math $i + 1

# 支持浮点
math 5 / 2          # 2.5

# 三角函数
math cos 2 x pi     # 1

# 括号需要引号（因为 () 是命令替换）
math '(5 + 2) * 4'

# 乘法用 x 或 *，* 需引号（否则被当作通配符）
math 5 x 3
math '5 * 3'
```

---

## 提示符

```bash
# bash
PS1='\h\[\e[1;34m\]\w\[\e[m\] \[\e[1;32m\]\$\[\e[m\] '

# fish（用函数，不是变量）
function fish_prompt
    set -l prompt_symbol '$'
    fish_is_root_user; and set prompt_symbol '#'

    echo -s (prompt_hostname) \
    (set_color blue) (prompt_pwd) \
    (set_color yellow) $prompt_symbol (set_color --reset)
end
```

fish 没有 `PS2`（续行提示符），未完成的命令通过缩进表示。

---

## 块和循环

```fish
# for 循环
# bash: for i in 1 2 3; do echo $i; done
for i in 1 2 3
    echo $i
end

# while 循环
# bash: while true; do echo Weee; done
while true
    echo Weee
end

# 代码块分组
# bash: { echo Hello; }
begin
    echo Hello
end

# if 语句
# bash: if true; then ...; else ...; fi
if true
    echo Yes
else
    echo No
end

# 函数
# bash: foo() { echo foo; }
function foo
    echo foo
end
```

fish 没有 `until`，用 `while not` 或 `while !` 替代。

---

## 子 Shell

fish 没有子 shell。`()` 是命令替换，不是子 shell。

```bash
# bash
(foo; bar) | baz           # 子 shell
foo | while read bar; do
    VAR=VAL                 # 管道右侧也是子 shell
done

# fish：管道在同一进程中
foo | while read bar
    set -g VAR VAL         # ✓ 外部可见
end
echo $VAR                 # 可见

# 如确需子 shell
fish -c 'your code here'
```

---

## 内置命令对照

| bash 方式 | fish 等价 |
|---|---|
| `${var%pattern}` 等字符串变换 | `string replace/split/match/trim/...` |
| `$((i+1))` 算术 | `math $i + 1` |
| `{1..10}` 范围展开 | `seq 1 10` |
| `$#` 参数个数 | `count $argv` |
| `$-` 状态 | `status is-interactive` |
| `getopt` 选项解析 | `argparse` |
| `bash --norc` | `fish --no-config` |
| `set -x` 调试 | `set fish_trace 1` |
| 性能分析 | `fish --profile` |

---

## 来源命令

```bash
# bash
source file.sh
. file.sh

# fish
source file.fish
# . file.fish  ❌ 不支持
```

**重要：** 不能 source bash 脚本。需要翻译成 fish 或用 `bass` 包装。
