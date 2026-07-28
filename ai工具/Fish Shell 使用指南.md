# Fish Shell 使用指南

## 简介

Fish（**F**riendly **I**nteractive **SH**ell）是一个注重可用性和交互体验的 shell。无需配置即可开箱使用，语法更简洁清晰。

当前版本：4.8.1  
官网：https://fishshell.com/

---

## 安装与启动

```bash
# Fedora Kinoite
sudo rpm-ostree install fish

# 启动
fish

# 退出
exit
```

---

## 基础语法

### 命令结构

```fish
echo hello world          # 命令 参数1 参数2
echo hello; echo world    # 分号分隔多条命令
```

### 注释

```fish
# 这是注释
echo hello  # 行尾注释
```

### 续行

```fish
echo hello \
world
```

---

## 引号与转义

### 单引号 `'`

不进行任何扩展，所见即所得：

```fish
echo '$HOME'    # 输出 $HOME（字面量）
```

### 双引号 `"`

只做变量扩展和命令替换（`$(cmd)`），不做其他扩展：

```fish
echo "$HOME"            # 输出 /home/smile
echo "Value: $(pwd)"    # 输出 Value: /current/path
echo "The price is $5"  # $5 被解释为变量
```

### 转义字符

| 序列 | 含义 |
|------|------|
| `\n` | 换行 |
| `\t` | Tab |
| `\\` | 反斜杠 |
| `\"` | 双引号 |
| `\xHH` | 十六进制字节 |

---

## 变量

### 赋值与读取

```fish
set name "张三"           # 赋值
echo $name               # 读取

set name "张三" "李四"    # 列表（多个元素）
echo $name               # 输出: 张三 李四
```

### 变量作用域

```fish
set -l name "局部"       # local，仅在当前函数/块内有效
set -g name "全局"       # global，整个 shell 可见
set -x name "导出"       # export，子进程可继承
set -U name "通用"       # universal，跨 shell 持久保存
set -e name              # 删除变量
```

### 变量是否存在

```fish
set -q name; and echo "存在"; or echo "不存在"
```

### 变量默认值

```fish
set -q XDG_CONFIG_HOME || set XDG_CONFIG_HOME $HOME/.config
```

### 列表操作

```fish
set list a b c d
echo $list[1]           # a（索引从 1 开始）
echo $list[2..3]        # b c
echo $list[1..-1]       # 所有元素
echo $list[-1]          # 最后一个元素
count $list             # 元素数量（代替 $#）
```

### 解引用

```fish
set foo a b c
set a 10; set b 20; set c 30
echo $$foo[1]           # 输出 10（即 $a 的值）
```

---

## 条件判断

### if / else if / else

```fish
if test -e /etc/os-release
    cat /etc/os-release
else if test "$uname" = Linux
    echo "Linux"
else
    echo "其他"
end
```

### switch

```fish
switch (uname)
case Linux
    echo "Linux"
case Darwin
    echo "macOS"
case '*'
    echo "其他"
end
```

### and / or（代替 && / ||）

```fish
# and = 成功时执行
command; and echo "成功"

# or = 失败时执行
command; or echo "失败"

# 组合
command; and echo "成功"; or echo "失败"
```

---

## 循环

### for

```fish
for file in *.txt
    echo "处理: $file"
end

for i in (seq 1 5)
    echo $i
end

for animal in {cat,}fish dog
   echo "I like $animal"
end
```

### while

```fish
while true
    echo "运行中"
    sleep 1
end
```

### break / continue

```fish
for i in (seq 1 10)
    if test $i -eq 5
        continue    # 跳过
    end
    if test $i -eq 8
        break       # 退出
    end
end
```

---

## 函数

### 定义与调用

```fish
function ll
    ls -l $argv
end

function hello
    echo "Hello, $argv[1]!"
end

hello "World"   # 调用
```

### 别名

```fish
# 用 alias 命令（实际创建函数）
alias ll "ls -l"

# 持久化保存
alias --save ll

# 或手动定义（注意用 command 避免递归）
function ls
    command ls --color=auto $argv
end
```

### 自动加载

函数放在 `~/.config/fish/functions/函数名.fish` 中即可自动加载。

---

## 重定向

```fish
# 输出到文件
echo hello > output.txt

# 追加
echo hello >> output.txt

# 错误输出
command 2> error.log

# 全部输出（stdout + stderr）
command &> all.log

# 输入重定向
cat < input.txt

# 管道
cat file.txt | head -10

# stderr 管道
make 2>| less

# 全部管道
command &| less
```

---

## 字符串处理

```fish
# 替换
string replace old new "hello old world"

# 分割
string split "," "a,b,c"

# 正则匹配
echo "hello123" | string match -r '\d+'

# 大小写
string lower "HELLO"
string upper "hello"

# 填充
string pad -c x -w 10 "hello"

# 修剪
string trim "  hello  "

# 子串
string sub --length 3 "hello"
```

---

## 数学运算

```fish
math 1 + 2
math 5 / 2          # 输出 2.5（支持浮点）
math '(5 + 2) * 4'  # 括号需要引号
math cos 2 x pi     # 三角函数
```

---

## 常用内置命令

| 命令 | 说明 | 示例 |
|------|------|------|
| `set` | 设置变量 | `set -l name "hello"` |
| `test` | 条件测试 | `test -f file.txt` |
| `string` | 字符串操作 | `string replace a b "abc"` |
| `math` | 数学计算 | `math 1 + 2` |
| `count` | 计数 | `count $list` |
| `contains` | 检查列表包含 | `contains -- a $list` |
| `type` | 检查命令类型 | `type -q git` |
| `funced` | 交互编辑函数 | `funced ll` |
| `funcsave` | 保存函数 | `funcsave ll` |
| `functions` | 查看函数定义 | `functions ll` |
| `abbr` | 缩写（输入时展开） | `abbr -a gco git checkout` |
| `alias` | 创建别名 | `alias ll "ls -l"` |
| `source` | 加载文件 | `source config.fish` |
| `status` | shell 状态 | `status is-interactive` |
| `fish_add_path` | 添加 PATH | `fish_add_path ~/.local/bin` |
| `fish_prompt` | 自定义提示符 | 见下方 |

---

## 进程与作业

```fish
# 后台运行
emacs &

# 查看作业
jobs

# 前台/后台切换
fg    # 调到前台
bg    # 放到后台

# 暂停（Ctrl+Z）
# 然后可以用 fg/bg 继续

# 分离（即使 shell 退出也继续）
disown
```

---

## 特殊变量

| Fish | Bash 对应 | 说明 |
|------|-----------|------|
| `$argv` | `$@` / `$*` / `$1` | 函数参数 |
| `$status` | `$?` | 上条命令退出码 |
| `$fish_pid` | `$$` | 当前 shell PID |
| `$last_pid` | `$!` | 后台进程 PID |
| `$CMD_DURATION` | - | 上条命令耗时（ms） |
| `$history` | - | 历史命令列表 |
| `count $argv` | `$#` | 参数个数 |

---

## 提示符自定义

```fish
function fish_prompt
    set -l user_char '►'
    fish_is_root_user; and set user_char '#'
    echo -s (set_color yellow) $PWD (set_color green) $user_char (set_color normal)
end
```

常用辅助函数：

```fish
prompt_hostname    # 短主机名
prompt_pwd         # 缩写路径（~代替$HOME）
set_color blue     # 设置颜色
fish_vcs_prompt    # Git 状态提示
```

---

## 配置文件

| 文件 | 说明 |
|------|------|
| `~/.config/fish/config.fish` | 主配置文件 |
| `~/.config/fish/functions/*.fish` | 自动加载的函数 |
| `~/.config/fish/conf.d/*.fish` | 自动执行的配置片段 |
| `~/.config/fish/fish_variables` | 通用变量存储 |

### 示例 config.fish

```fish
# 仅在交互式 shell 中执行
if status is-interactive
    fish_config theme choose catppuccin-macchiato
    starship init fish | source
end

# PATH
fish_add_path ~/.local/bin
fish_add_path ~/.cargo/bin

# 环境变量
set -x EDITOR hx
set -x PAGER less

# 缩写
abbr -a gco git checkout
abbr -a gst git status

# 别名
alias mpv "flatpak run io.mpv.Mpv"

# 提示符
function fish_prompt
    echo -s (set_color green) (prompt_pwd) (set_color cyan) ' ▶ ' (set_color normal)
end
```

---

## Fish 与 Bash 对照

| 操作 | Bash | Fish |
|------|------|------|
| 赋值 | `VAR=val` | `set VAR val` |
| 导出 | `export VAR=val` | `set -gx VAR val` |
| 删除 | `unset VAR` | `set -e VAR` |
| 条件 && | cmd1 && cmd2 | cmd1; and cmd2 |
| 条件 \|\| | cmd1 \|\| cmd2 | cmd1; or cmd2 |
| 命令替换 | `$(cmd)` 或 `` `cmd` `` | `$(cmd)` 或 `(cmd)` |
| 子shell | `(cmd)` | `fish -c "cmd"` |
| 数学 | `$((i+1))` | `math $i + 1` |
| 字符串替换 | `${i/old/new}` | `string replace old new $i` |
| 字符串长度 | `${#var}` | `string length $var` |
| 默认值 | `${var:-default}` | `set -q var \|\| set var default` |
| 条件测试 | `[ -f file ]` 或 `[[ -f file ]]` | `test -f file` |
| 函数 | `foo() { ... }` | `function foo; ...; end` |
| for 循环 | `for i in x; do; done` | `for i in x; ...; end` |
| while | `while true; do; done` | `while true; ...; end` |
| 变量个数 | `$#` | `count $argv` |
| 所有参数 | `$@` | `$argv` |
| heredoc | `cat << EOF` | `echo "..." \| cat`（用管道） |
| 提示符 | `PS1='\w \$ '` | `function fish_prompt; end` |
| source | `. file` 或 `source file` | `source file` |

---

## 常见问题

### PATH 变量

fish 中 PATH 是一个列表，用 `fish_add_path` 管理：

```fish
fish_add_path ~/.local/bin    # 添加到开头
fish_add_path -a ~/.local/bin  # 添加到末尾
```

### 脚本 shebang

```fish
#!/usr/bin/env fish
echo "Hello from fish $version"
```

### 调试

```fish
# 显示每条执行的命令
set -g fish_trace 1

# 性能分析
fish --profile profile.log myscript.fish
```

### 事件处理

```fish
function on_exit --on-event fish_exit
    echo "shell 退出"
end
```

### 函数中引用全局变量

```fish
set -g myvar "全局"
function print_var
    echo $myvar            # 全局变量可直接访问
    # 或使用解引用访问动态变量名
    echo $$argv[1]
end
```
