---
date: 2026-05-27
tags:
  - 编程
  - 工具
  - linux
  - shell
  - terminal
  - fish
lang: Linux
---

# Fish Shell 使用指南

> 基于 [fish 官方教程](https://fishshell.com/docs/current/tutorial.html)

---

## 为什么选择 Fish？

Fish 是开箱即用的现代 Shell，内置语法高亮、自动建议和 Tab 补全，不需要额外配置。

---

## 快速上手

```fish
# 进入 fish
fish

# 查看帮助（浏览器）
help

# 查看手册
man set
```

---

## 语法高亮

- 有效命令显示为一种颜色，无效命令显示为红色
- 有效文件路径会显示下划线
- 可通过 `fish_config theme choose none` 关闭，或 `fish_config theme show` 查看所有主题

---

## 自动建议

输入时灰色文字为基于历史记录的自动建议。

| 操作 | 快捷键 |
|---|---|
| 接受建议 | → 或 Ctrl+F |
| 接受一个词 | Alt+→ |
| 忽略建议 | 继续输入 |

```fish
# 关闭自动建议
set -g fish_autosuggestion_enabled 0
```

---

## Tab 补全

按 Tab 完成命令、参数或路径。多个候选项时列出全部，再按 Tab 循环选择。

---

## 变量

```fish
set name 'Mister Noodle'  # 设置
echo $name                # 取值 → Mister Noodle
set -e name               # 删除

# 单引号不展开变量
echo '$HOME'   # $HOME
echo "$HOME"   # /home/user
```

**关键差异：** fish 不会对变量值进一步按空格拆分。在 bash 中 `mkdir $name` 会创建两个目录，fish 只创建一个。

---

## 导出环境变量

```fish
set -x PAGER less       # 导出
env | grep PAGER         # 验证

# 通常设为全局导出
set -gx EDITOR nvim
```

---

## 列表

fish 中所有变量都是列表：

```fish
# PATH 是列表（不是冒号分隔的字符串）
echo $PATH          # /usr/bin /bin /usr/local/bin

# 元素计数
count $PATH         # 5

# 索引（从 1 开始）
echo $PATH[1]       # /usr/bin
echo $PATH[-1]      # /usr/local/bin

# 切片
echo $PATH[1..2]    # /usr/bin /bin

# 遍历
for val in $PATH
    echo "entry: $val"
end

# 追加
set PATH $PATH /usr/local/bin
```

以 PATH 结尾的变量自动以冒号分割/拼接（兼容外部工具）。

---

## 通配符

```fish
ls *.jpg           # 可包含多个 *
ls l*.p*           # l 开头，中间任意，p 结尾
ls /var/**.log     # ** 递归搜索
```

---

## 管道和重定向

```fish
cmd1 | cmd2                     # 管道
cmd < input.txt                 # 输入重定向
cmd > output.txt                # 输出重定向
cmd 2> errors.txt               # 错误重定向
cmd &> all_output.txt           # stdout + stderr
```

---

## 命令替换

```fish
# 用 () 替代反引号（或 $()）
echo In (pwd), running $(uname)

# 捕获到变量
set os (uname)
echo $os

# 在双引号内必须用 $()
touch "testing_$(date +%s).txt"

# 只按换行分割结果（不按空格），这是与 bash 的区别
```

---

## 退出状态

```fish
# fish 用 $status 而非 $?
false
echo $status    # 1
true
echo $status    # 0

# 管道中多个命令的状态
echo $pipestatus
```

---

## 组合命令

```fish
# && 和 || 可用
./configure && make && sudo make install

# and / or 优先级更低
cp file1 file1_bak; and echo "成功"; or echo "失败"

# ! 取反
! test -f /tmp/foo && echo "不存在"
```

---

## 条件判断

```fish
if grep fish /etc/shells
    echo "发现 fish"
else if grep bash /etc/shells
    echo "发现 bash"
else
    echo "没有"
end

# 用 test 判断字符串/数字/文件
if test "$fish" = "flounder"
    echo FLOUNDER
end

if test "$number" -gt 5
    echo "$number > 5"
end

if test -e /etc/hosts
    echo "hosts 文件存在"
end

# 组合条件
if command -sq fish; and grep fish /etc/shells
    echo "已安装并配置"
end
```

### switch

```fish
switch (uname)
    case Linux
        echo "Hi Tux!"
    case Darwin
        echo "Hi Hexley!"
    case FreeBSD NetBSD DragonFly
        echo "Hi Beastie!"
    case '*'
        echo "Hi, stranger!"
end
```

---

## 函数

```fish
function say_hello
    echo Hello $argv
end

# 调用
say_hello             # Hello
say_hello everybody!  # Hello everybody!

# 查看函数定义
functions say_hello

# 列出所有函数
functions
```

**注意：** `$argv` 替代 bash 的 `$1 $2 ...`，是一个列表。`$argv[1]` 获取第一个参数。

### 别名

fish 的 `alias` 实际上是创建函数的快捷方式。还可以用 `abbr` 创建缩写展开。

```fish
alias ll='ls -lh'
abbr --add gs 'git status'
```

---

## 循环

```fish
# while
while true
    echo "loop"
end

# for 遍历文件
for file in *.txt
    cp $file $file.bak
end

# for 遍历数字
for x in (seq 5)
    touch file_$x.txt
end
```

---

## 提示符

fish 通过函数 `fish_prompt` 定义提示符，不使用 `PS1`：

```fish
function fish_prompt
    set_color purple
    date "+%m/%d/%y"
    set_color FF0000
    echo (pwd) '>' (set_color --reset)
end

funcsave fish_prompt    # 保存到 ~/.config/fish/functions/

# 选择内置提示符
fish_config prompt choose

# 网页版选择
fish_config
```

---

## $PATH

```fish
# PATH 是列表
echo $PATH    # /usr/bin /bin ...

# 前置添加
set PATH /usr/local/bin $PATH

# 永久添加（推荐）
fish_add_path /usr/local/bin

# 移除
set PATH (string match -v /usr/local/bin $PATH)
```

`fish_add_path` 通过修改 `$fish_user_paths` 通用变量实现，一次执行永久生效，自动去重。

---

## 配置文件

| 文件/目录 | 作用 |
|---|---|
| `~/.config/fish/config.fish` | 主配置（等价 .bashrc） |
| `~/.config/fish/conf.d/*.fish` | 配置片段，按文件名排序加载 |
| `~/.config/fish/functions/` | 函数文件，按需自动加载 |
| `~/.config/fish/completions/` | 自定义补全 |

**注意：** fish 不读取 `.profile`、`.bashrc`、`.zshenv` 等文件。

---

## 函数自动加载

把函数存为独立文件放在 `~/.config/fish/functions/`，fish 会在首次调用时自动加载，比全写在 config.fish 更高效。

```fish
# 创建/编辑函数
funced myfunc

# 保存到文件
funcsave myfunc

# 手动创建
echo 'function ll
    ls -lh $argv
end' > ~/.config/fish/functions/ll.fish
```

---

## 通用变量（Universal Variables）

持久化变量，跨所有 fish 会话共享，重启后仍保留。

```fish
set -U EDITOR nvim    # 一次设定，永久生效
set -Ux JAVA_HOME ... # 同时设为通用和导出

# 查看所有通用变量
set -U

# 删除
set -e EDITOR
```

通用变量的优势：一次性设置，无需写入 config.fish。

---

## 常见 bash → fish 迁移速查

| bash/zsh | fish |
|---|---|
| `export VAR=val` | `set -x VAR val` |
| `VAR=val` | `set VAR val` |
| `$?` | `$status` |
| `$1, $2, $@` | `$argv[1], $argv[2], $argv` |
| `$(cmd)` 或 `` `cmd` `` | `(cmd)` 或 `$(cmd)` |
| `[ "$a" = "$b" ]` | `test "$a" = "$b"` |
| `if [ -z "$var" ]` | `if not set -q var` |
| `case ... esac` | `switch ... case ... end` |
| `PATH=...:...` | `set PATH ... ...` |
| `.bashrc` | `~/.config/fish/config.fish` |
| 变量按空格拆分 | 不拆分 |

---

## 不能 source bash/zsh 脚本

fish 语法不兼容 POSIX。需要：
- 找对应的 fish 插件（如 fisher）
- 或用 `bass` 包装 bash 脚本
- 或用 `source` 时先检查命令是否存在：`command -q x && x init fish | source`
