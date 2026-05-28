---
time: 2026-05-28T21:42:00
lang: Linux
tags:
  - 编程
  - 工具
  - fish
  - linux
  - shell
---

# fish 语言教程

本文档是对 fish 脚本语言的全面概述。

交互式功能请参阅 [交互式使用](interactive.html) 文档。

---

## 语法概述

像 fish 这样的 shell 通过向其提供命令来使用。命令的执行方式是写入命令名称后跟参数。例如：

```fish
echo hello world
```

[echo](cmds/echo.html) 命令将其参数写入屏幕。在此示例中，输出为 `hello world`。

在 fish 中，一切都通过命令来完成。有用于重复执行其他命令的命令、用于分配变量的命令、用于将一组命令视为单个命令的命令等。所有这些命令都遵循相同的基本语法。

您计算机上的每个程序都可以作为 fish 中的命令使用。如果程序文件位于 [`PATH`](#环境变量-PATH) 目录中，您只需键入程序名称即可使用它。否则，需要完整的文件名，包括目录（如 `/home/me/code/checkers/checkers` 或 `../checkers`）。

以下是一些有用的命令列表：

-   **cd**：更改当前目录
-   **ls**：列出文件和目录
-   **man**：显示手册页 —— 尝试 `man ls` 获取"ls"命令的帮助，或 `man mv` 获取有关 "mv" 的信息
-   **mv**：移动（重命名）文件
-   **cp**：复制文件
-   **open**：使用与每种文件类型关联的默认应用程序打开文件
-   **less**：显示文件内容

命令和参数由空格字符 `' '` 分隔。每个命令以换行符（按回车键）或分号 `;` 结尾。多个命令可以通过用分号分隔来写在同一行上。

**开关（Switch）** 是一种非常常见的特殊参数类型。开关几乎总是以一个或多个连字符 `-` 开头，并改变命令的操作方式。例如，`ls` 命令通常列出当前工作目录中所有文件和目录的名称。通过使用 `-l` 开关，`ls` 的行为被改变为不仅显示文件名，还显示每个文件的大小、权限、所有者和修改时间。

开关因命令而异，通常记录在命令的手册页上。然而，有一些开关是大多数命令通用的，例如 `--help` 通常显示帮助文本，`--version` 通常显示命令版本，`-i` 通常在执行操作前启用交互式提示。尝试 `man your-command-here` 获取命令开关的信息。

因此，fish 的基本思想与其他 Unix shell 相同：它获取命令行，运行[扩展](#参数扩展)，然后将结果作为命令运行。

## 术语

以下定义了本页面及 fish 文档其余部分中使用的一些术语：

-   **参数（Argument）**：传递给命令的参数。在 `echo foo` 中，"foo" 是一个参数。
-   **内置命令（Builtin）**：由 shell 实现的命令。内置命令与 shell 的操作紧密相关，无法将它们实现为外部命令。在 `echo foo` 中，"echo" 是一个内置命令。
-   **命令（Command）**：shell 可以运行的程序，或更具体地说，shell 在另一个进程中运行的外部程序。外部命令由系统以可执行文件的形式提供。在 `echo foo` 中，"echo" 是内置命令；在 `command echo foo` 中，"echo" 是由 /bin/echo 等文件提供的外部命令。
-   **函数（Function）**：可以作为单个命令调用的一组命令。通过使用函数，可以将多个简单命令组合成一个更高级的命令。
-   **作业（Job）**：一个正在运行的管道或命令。
-   **管道（Pipeline）**：一组串联的命令，其中一个命令的输出是下一个命令的输入。`echo foo | grep foo` 是一个管道。
-   **重定向（Redirection）**：更改与作业关联的输入或输出流之一的操作。
-   **开关/选项（Switch/Option）**：改变命令行为的特殊参数。开关几乎总是以一个或两个连字符开头。在 `echo -n foo` 中，"-n" 是一个选项。

## 引号

有时您想给命令传递一个包含 fish 特殊字符的参数，如空格、`$` 或 `*`。为此，您可以使用引号：

```fish
rm "my file.txt"
```

这会删除名为 `my file.txt` 的文件，而不是尝试删除 `my` 和 `file.txt` 两个文件。

Fish 理解两种引号：单引号 (`'`) 和双引号 (`"`)，两者的工作方式略有不同。

在**单引号**之间，fish 不执行任何扩展。在**双引号**之间，fish 只执行 `$(command)` 形式的[变量扩展](#变量扩展)和[命令替换](#命令替换)。不执行其他类型的扩展（包括[大括号扩展](#大括号扩展)或参数扩展），并且忽略转义序列（例如 `\n`）。在引号内，空格不用于分隔参数，允许引号内的参数包含空格。

单引号中唯一有意义的转义序列是 `\'`（转义单引号）和 `\\`（转义反斜杠符号）。双引号中唯一有意义的转义序列是 `\"`（转义双引号）、`\$`（转义美元符号）、`\` 后跟换行符（删除反斜杠和换行符），以及 `\\`（转义反斜杠符号）。

单引号在双引号内没有特殊含义，反之亦然。

更多示例：

```fish
grep 'enabled)$' foo.txt
```

在 `foo.txt` 中搜索以 `enabled)` 结尾的行（`$` 对 `grep` 有特殊意义：它匹配行尾）。

```fish
apt install "postgres-*"
```

安装所有名称以 "postgres-" 开头的包，而不是在当前目录中查找名为 "postgres-something" 的文件。

## 转义字符

有些字符不能直接写在命令行上。对于这些字符，提供了所谓的转义序列。这些包括：

-   `\a` 表示警报字符。
-   `\e` 表示 escape 字符。
-   `\f` 表示换页字符。
-   `\n` 表示换行字符。
-   `\r` 表示回车字符。
-   `\t` 表示制表符。
-   `\v` 表示垂直制表符。
-   `\xHH` 或 `\XHH`，其中 `HH` 是十六进制数，表示具有指定值的字节数据。例如，`\x9` 是制表符。如果您使用多字节编码，这可用于输入无效字符串。通常 fish 以 ASCII 或 UTF-8 编码运行，因此直到 `\X7f` 的任何内容都是 ASCII 字符。
-   `\ooo`，其中 `ooo` 是八进制数，表示具有指定值的 ASCII 字符。例如，`\011` 是制表符。允许的最高值是 `\177`。
-   `\uXXXX`，其中 `XXXX` 是十六进制数，表示具有指定值的 16 位 Unicode 字符。例如，`\u9` 是制表符。
-   `\UXXXXXXXX`，其中 `XXXXXXXX` 是十六进制数，表示具有指定值的 32 位 Unicode 字符。例如，`\U9` 是制表符。允许的最高值是 U10FFFF。
-   `\cX`，其中 `X` 是字母表中的字母，表示按下控制键和指定字母生成的控制序列。例如，`\ci` 是制表符。

有些字符对 shell 有特殊意义。例如，撇号 `'` 会禁用扩展（参见[引号](#引号)）。要告诉 shell 将这些字符视为字面字符，请用反斜杠转义它们。例如，命令：

```fish
echo \'hello world\'
```

输出 `'hello world'`（包括撇号），而命令：

```fish
echo 'hello world'
```

输出 `hello world`（不含撇号）。在前一种情况下，shell 将撇号视为字面 `'` 字符，而在后一种情况下，将其视为特殊的扩展修饰符。

特殊字符及其转义序列如下：

-   `\ `（反斜杠空格）转义空格字符。这可以防止 shell 在转义的空格处分割参数。
-   `\$` 转义美元字符。
-   `\\` 转义反斜杠字符。
-   `\*` 转义星号字符。
-   `\?` 转义问号字符（如果启用了 `qmark-noglob` [特性标志](#未来特性标志)，则不需要转义）。
-   `\~` 转义波浪号字符。
-   `\#` 转义井号字符。
-   `\(` 转义左括号字符。
-   `\)` 转义右括号字符。
-   `\{` 转义左花括号字符。
-   `\}` 转义右花括号字符。
-   `\[` 转义左方括号字符。
-   `\]` 转义右方括号字符。
-   `\<` 转义小于号字符。
-   `\>` 转义大于号字符。
-   `\&` 转义 & 符号字符。
-   `\|` 转义竖线字符。
-   `\;` 转义分号字符。
-   `\"` 转义引号字符。
-   `\'` 转义撇号字符。

作为一个特殊情况，`\` 后紧跟着字面换行是一个"续行符"，告诉 fish 忽略换行并在下一行开头继续输入（不引入任何空格或终止标记）。

## 输入/输出重定向

大多数程序使用三个输入/输出（I/O）流：

-   **标准输入（stdin）**用于读取。默认从键盘读取。
-   **标准输出（stdout）**用于写入输出。默认写入屏幕。
-   **标准错误（stderr）**用于写入错误和警告。默认写入屏幕。

每个流都有一个称为文件描述符（FD）的编号：0 表示 stdin，1 表示 stdout，2 表示 stderr。

流的去向可以使用*重定向*来更改。例如，`echo hello > output.txt` 将 `echo` 命令的标准输出重定向到文本文件。

-   从文件读取标准输入，使用 `<源文件`。
-   从文件读取标准输入，如果无法读取则使用 /dev/null，使用 `<?源文件`。
-   向文件写入标准输出，使用 `>目标`。
-   向文件写入标准错误，使用 `2>目标`。（注意：旧版 fish 也允许使用 `^目标`，但已废弃并移除。）
-   向文件追加标准输出，使用 `>>目标文件`。
-   向文件追加标准错误，使用 `2>>目标文件`。
-   不覆盖现有文件（"noclobber"），使用 `>?目标` 或 `2>?目标`。

`目标` 可以是以下之一：

-   写入输出的文件名。通常使用 `>/dev/null` 将输出写入特殊的"黑洞"文件来消除输出。
-   `&` 后跟另一个文件描述符的编号，如 `&2` 表示标准错误。输出将写入目标描述符。
-   `&` 后跟减号 (`&-`)。文件描述符将被关闭。注意：这可能导致程序失败，因为其写入将不成功。

为方便起见，重定向 `&>` 可用于将 stdout 和 stderr 都指向同一目标。例如，`echo hello &> all_output.txt` 将 stdout 和 stderr 都重定向到文件 `all_output.txt`。这等价于 `echo hello > all_output.txt 2>&1`。您也可以使用 `&>>` 将 stdout 和 stderr 都追加到同一目标。

任何任意文件描述符都可以在重定向中使用，方法是在重定向前加上 FD 编号。

-   重定向描述符 N 的输入，使用 `N<目标`
-   重定向描述符 N 的输出，使用 `N>目标`
-   将描述符 N 的输出追加到文件，使用 `N>>目标文件`

文件描述符不能用于 `<?` 输入重定向，只能用于常规的 `<`。

例如：

```fish
# 将 `foo` 的标准错误（文件描述符 2）
# 写入名为 "output.stderr" 的文件：
foo 2> output.stderr

# 如果 $num 不包含数字，
# 此测试将为 false 并打印错误，
# 因此通过忽略错误，我们可以确保
# 在 "if" 块中处理的是数字：
if test "$num" -gt 2 2>/dev/null
    # 当 $num 是大于 2 的数字时执行
else
    # 当 $num <= 2 或不是数字时执行
end

# 将 `make` 的输出保存到文件：
make &>/log

# 重定向可以堆叠，并可用于块：
begin
    echo stdout
    echo stderr >&2 # <- 这发送到 stderr！
end >/dev/null # 忽略 stdout，因此只打印 "stderr"

# 从 myfile 中打印包含 "foo" 的所有行，如果文件不存在则不打印任何内容。
string match '*foo*' <?myfile
```

将内置命令、函数或块重定向到大于 2 的文件描述符是错误的。但外部命令支持此操作。

## 管道

另一种重定向流的方法是*管道*。管道将流相互连接。通常，一个命令的标准输出与另一个命令的标准输入相连。这通过用管道字符 `|` 分隔命令来完成。例如：

```fish
cat foo.txt | head
```

命令 `cat foo.txt` 将 `foo.txt` 的内容发送到 stdout。此输出作为 `head` 程序的输入提供，该程序打印其输入的前 10 行。

可以通过在管道前加上 FD 编号和输出重定向符号来管道传输不同的输出文件描述符。例如：

```fish
make fish 2>| less
```

将尝试构建 `fish`，任何错误将使用 `less` 分页器显示。（"分页器"是一个接收输出并"分页"的程序。`less` 不仅可以分页，还允许任意滚动，甚至可以向前滚动。）

为方便起见，管道 `&|`（以及 Bash 也支持的 `|&` 别名）将 stdout 和 stderr 都重定向到同一个进程。

## 组合管道和重定向

可以同时使用多个重定向和一个管道。在这种情况下，它们按以下顺序读取：

1.  首先设置管道。
2.  然后从左到右评估重定向。

当任何重定向使用 `&N` 语法引用其他文件描述符时，这一点很重要。当您写 `>&2` 时，这将把 stdout 重定向到 stderr *当时*指向的位置。

考虑这个辅助函数：

```fish
# 创建一个向 stdout 和 stderr 打印内容的函数
function print
    echo out
    echo err >&2
end
```

现在看几种情况：

```fish
# 将 stderr 和 stdout 都重定向到 less
print 2>&1 | less
# 或
print &| less

# 在 stderr 上显示 "out"，消除 "err"
print >&2 2>/dev/null

# 消除两者
print >/dev/null 2>&1
```

## 作业控制

当您在 fish 中启动作业时，fish 本身会暂停，并将终端控制权交给刚刚启动的程序。有时，您希望继续使用命令行，并让作业在后台运行。要创建后台作业，请在命令后附加 `&`（& 符号）。这将告诉 fish 在后台运行作业。当运行具有图形用户界面的程序时，后台作业非常有用。

示例：

```fish
emacs &
```

将在后台启动 emacs 文本编辑器。[fg](cmds/fg.html) 可在需要时将其调回前台。

大多数程序允许您通过按 ctrl-z（也写作 `^Z`）暂停程序执行并将控制权返回给 fish。回到 fish 命令行后，您可以启动其他程序并执行任何操作。如果之后您想回到暂停的命令，可以使用 [fg](cmds/fg.html)（foreground）命令。

如果要将暂停的作业放入后台，请使用 [bg](cmds/bg.html) 命令。

要获取当前所有已启动作业的列表，请使用 [jobs](cmds/jobs.html) 命令。这些列出的作业可以使用 [disown](cmds/disown.html) 命令移除。

目前，函数不能在后台启动。停止然后使用 [bg](cmds/bg.html) 命令在后台重新启动的函数将无法正确执行。

如果 `&` 字符后跟非分隔字符，则不会被解释为后台操作符。分隔字符包括空格和字符 `;<>&|`。

## 函数

函数是用 fish 语法编写的程序。它们使用单个名称将各种命令及其参数组合在一起。

例如，这里有一个简单的列出目录的函数：

```fish
function ll
    ls -l $argv
end
```

第一行告诉 fish 定义一个名为 `ll` 的函数，因此可以通过在命令行上写 `ll` 来使用它。第二行告诉 fish，当调用 `ll` 时应调用命令 `ls -l $argv`。[$argv](#参数处理) 是一个[列表变量](#列表)，始终包含发送给函数的所有参数。在上面的示例中，这些参数被传递给 `ls` 命令。第三行的 `end` 结束了定义。

以 `ll /tmp/` 调用将最终运行 `ls -l /tmp/`，列出 /tmp 的内容。

这也是一种被称为[别名](#定义别名)的函数。

Fish 的提示符也定义在一个函数中，称为 [fish_prompt](cmds/fish_prompt.html)。它在提示符即将显示时运行，其输出构成提示符：

```fish
function fish_prompt
    # 一个简单的提示符。显示当前目录
    # （fish 将其存储在 $PWD 变量中）
    # 然后显示一个用户符号 —— 普通用户为 '►'，root 为 '#'。
    set -l user_char '►'
    if fish_is_root_user
        set user_char '#'
    end

    echo (set_color yellow)$PWD (set_color purple)$user_char
end
```

要编辑函数，可以使用 [funced](cmds/funced.html)；要保存函数，使用 [funcsave](cmds/funcsave.html)。这会将其存储在函数文件中，fish 将在需要时[自动加载](#自动加载函数)。

[functions](cmds/functions.html) 内置命令可以显示函数的当前定义（[type](cmds/type.html) 也可以显示，如果给定的是函数的话）。

有关函数的更多信息，请参阅 [function](cmds/function.html) 内置命令的文档。

### 定义别名

函数最常见的用途之一是略微改变已有命令的行为。例如，有人可能想重新定义 `ls` 命令以显示颜色。在 GNU 系统上打开颜色的开关是 `--color=auto`。围绕 `ls` 的别名可能如下所示：

```fish
function ls
    command ls --color=auto $argv
end
```

关于别名，有几点重要事项需要注意：

-   始终注意将 [$argv](#参数处理) 变量添加到被包装命令的参数列表中。这确保如果用户为函数指定了任何额外参数，它们会被传递给底层命令。
-   如果别名的名称与别名的命令相同，则需要在程序调用前加上 `command` 前缀，告诉 fish 该函数不应调用自身，而应调用同名命令。如果忘记这样做，函数将一直调用自身。通常 fish 足够聪明，能够识别这一点并会避免这样做。

要轻松创建这种形式的函数，可以使用 [alias](cmds/alias.html) 命令。与其他 shell 不同，这只是创建函数 —— fish 没有单独的"别名"概念，我们只是用这个词来表示这样的简单包装函数。[alias](cmds/alias.html) 立即创建函数。考虑使用 `alias --save` 或 [funcsave](cmds/funcsave.html) 将创建的函数保存到自动加载文件中，而不是每次重新创建别名。

作为替代方案，可以尝试[缩写](interactive.html#abbreviations)。这些是在您键入时展开的单词，而不是 shell 内部的实际函数。

### 自动加载函数

函数可以在命令行或配置文件中定义，但也可以自动加载。这有一些优点：

-   自动加载的函数自动对所有正在运行的 shell 可用。
-   如果函数定义发生更改，所有正在运行的 shell 将在一段时间后自动重新加载修改后的版本。
-   启动时间和内存使用得到改善等。

当 fish 需要加载函数时，它会在[列表变量](#列表) `$fish_function_path` 中的所有目录中搜索文件，文件名由函数名称加上后缀 `.fish` 组成，并加载找到的第一个文件。

例如，如果您尝试执行名为 `banana` 的内容，fish 将遍历 $fish_function_path 中的所有目录，寻找名为 `banana.fish` 的文件，并加载找到的第一个文件。

默认情况下，`$fish_function_path` 包含以下内容：

-   用户存放自己函数的目录，通常为 `~/.config/fish/functions`（由 `XDG_CONFIG_HOME` 环境变量控制）。
-   系统上所有用户的函数目录，通常为 `/etc/fish/functions`（实际上是 `$__fish_sysconfdir/functions`）。
-   其他软件存放其函数的目录。这些在 `$__fish_user_data_dir`（通常为 `~/.local/share/fish`，由 `XDG_DATA_HOME` 环境变量控制）下的目录中，以及 `XDG_DATA_DIRS` 环境变量中的名为 `fish/vendor_functions.d` 的子目录中。`XDG_DATA_DIRS` 的默认值通常为 `/usr/share/fish/vendor_functions.d` 和 `/usr/local/share/fish/vendor_functions.d`。

如果不确定，您的函数可能应该放在 `~/.config/fish/functions` 中。

如我们所述，自动加载文件是*按名称*加载的，因此，虽然您可以将多个函数放入一个文件，但只有在您尝试执行与文件名相同名称的函数时，该文件才会被自动加载。

自动加载也不适用于[事件处理器](#事件处理器)，因为 fish 在尚未加载函数时无法知道该函数应在事件发生时执行。有关更多信息，请参阅[事件处理器](#事件处理器)部分。

如果具有正确名称的文件没有定义该函数，fish 将不读取其他自动加载文件，而是继续尝试内置命令，最后尝试命令。这允许屏蔽 $fish_function_path 中后面定义的函数，例如，如果您的管理员在 /etc/fish/functions 中放了一些您想跳过的内容。

如果您正在开发另一个程序，并想为其安装 fish 函数，请将它们安装到 "vendor" 函数目录中。由于此路径因系统而异，可以使用 `pkg-config --variable functionsdir fish` 的输出通过 `pkgconfig` 发现它。您的安装系统应支持自定义路径来覆盖 pkgconfig 路径，因为其他发行者可能需要轻松更改它。

## 注释

`#` 之后直到行尾的任何内容都是注释。这意味着它纯粹是为了读者的利益，fish 会忽略它。

这对于解释您正在做什么以及为什么这样做很有用：

```fish
function ls
    # 函数名为 ls，
    # 所以我们必须显式调用 `command ls` 来避免调用自身。
    command ls --color=auto $argv
end
```

没有多行注释。如果想让注释跨越多行，请每行都以 `#` 开头。

注释也可以出现在一行之后，如下所示：

```fish
set -gx EDITOR emacs # 我不喜欢 vim。
```

## 条件

Fish 有一些内置命令，允许您仅在满足特定条件时执行命令：[if](cmds/if.html)、[switch](cmds/switch.html)、[and](cmds/and.html) 和 [or](cmds/or.html)，以及熟悉的 [&&/||](#组合器-and--or) 语法。

### `if` 语句

[if](cmds/if.html) 语句在条件为真时运行命令块。

与其他 shell 一样，但与您可能了解的典型编程语言不同，这里的条件是一个*命令*。Fish 运行它，如果它返回真[退出状态](#状态变量)（即 0），则运行 if 块。例如：

```fish
if test -e /etc/os-release
    cat /etc/os-release
end
```

这使用 [test](cmds/test.html) 命令查看文件 /etc/os-release 是否存在。如果存在，则运行 `cat`，将其打印在屏幕上。

与其他 shell 不同，条件命令在第一个作业后结束，这里没有 `then`。`and` 和 `or` 等组合器可以扩展条件。

一个更复杂的示例，带有[命令替换](#命令替换)：

```fish
if test "$(uname)" = Linux
    echo I like penguins
end
```

由于 `test` 可用于许多不同的测试，因此引用变量和命令替换很重要。如果 `$(uname)` 没有被引用，且 `uname` 没有打印任何内容，它将运行 `test = Linux`，这是一个错误。

`if` 还可以带有额外的 `else if` 子句和一个 `else` 子句，该子句在所有其他条件均为 false 时执行：

```fish
if test "$number" -gt 10
   echo 您的数字大于 10
else if test "$number" -gt 5
   echo 您的数字大于 5
else if test "$number" -gt 1
   echo 您的数字大于 1
else
   echo 您的数字小于或等于 1
end
```

[not](cmds/not.html) 关键字可用于反转状态：

```fish
# 检查文件是否包含 "fish" 字符串。
# 执行 `grep` 命令，该命令搜索字符串，
# 如果找到则返回状态 0。
# `not` 然后将 0 变为 1，或将任何其他值变为 0。
# `-q` 开关阻止其打印任何匹配项。
if not grep -q fish myanimals
    echo "您没有 fish！"
else
    echo "您有 fish！"
end
```

if 条件中常用的其他命令：

-   [contains](cmds/contains.html) —— 查看列表是否包含特定元素（`if contains -- /usr/bin $PATH`）
-   [string](cmds/string.html) —— 例如匹配字符串（`if string match -q -- '*-' $arg`）
-   [path](cmds/path.html) —— 检查某些条件的路径是否存在（`if path is -rf -- ~/.config/fish/config.fish`）
-   [type](cmds/type.html) —— 查看命令、函数或内置命令是否存在（`if type -q git`）

### `switch` 语句

[switch](cmds/switch.html) 命令用于根据字符串的值执行可能多个命令块中的一个。它可以接受多个 [case](cmds/case.html) 块，当字符串匹配时执行它们。它们可以使用[通配符](#通配符)。例如：

```fish
switch (uname)
case Linux
    echo 嗨 Tux！
case Darwin
    echo 嗨 Hexley！
case DragonFly '*BSD'
    echo 嗨 Beastie！ # 这也适用于 FreeBSD 和 NetBSD
case '*'
    echo 嗨，陌生人！
end
```

与其他 shell 或编程语言不同，没有穿透 —— 第一个匹配的 `case` 块被执行，然后控制跳出 `switch`。

### 组合器 (`and` / `or` / `&&` / `||`)

对于简单检查，可以使用组合器。[and](cmds/and.html) 或 `&&` 在第一个命令成功时运行第二个命令，而 [or](cmds/or.html) 或 `||` 在第一个命令失败时运行第二个命令。例如：

```fish
# $XDG_CONFIG_HOME 是存储配置的标准位置。
# 如果未设置，应用程序应使用 ~/.config。
set -q XDG_CONFIG_HOME; and set -l configdir $XDG_CONFIG_HOME
or set -l configdir ~/.config
```

请注意，组合器是*惰性*的 —— 只运行确定最终状态所必需的部分。

比较：

```fish
if sleep 2; and false
    echo '我怎么到这里了？这应该是不可能的'
end
```

和：

```fish
if false; and sleep 2
    echo '我怎么到这里了？这应该是不可能的'
end
```

它们基本上做同样的事情，但前者需要多花 2 秒，因为 `sleep` 总是需要运行。

或者您可能遇到需要提前停止的情况：

```fish
if command -sq foo; and foo
```

如果这在看到命令 "foo" 不存在后继续，它将尝试运行 `foo` 并因未找到而出错！

组合器逐步执行，因此不建议构建较长的组合器链，因为它们可能会做出您不希望的事情。考虑：

```fish
test -e /etc/my.config
or echo "糟糕，我们需要配置文件"
and return 1
```

这也将在 `test` 成功时执行 `return 1`。这是因为 fish 运行 `test -e /etc/my.config`，将 $status 设置为 0，然后跳过 `echo`，保持 $status 为 0，然后因为 $status 仍然为 0 而执行 `return 1`。

因此，如果您有更复杂的条件，或想在失败后运行多个内容，请考虑使用 [if](#if-语句)。这里应该写成：

```fish
if not test -e /etc/my.config
    echo "糟糕，我们需要配置文件"
    return 1
end
```

## 循环和块

与大多数编程语言一样，fish 也有熟悉的 [while](cmds/while.html) 和 [for](cmds/for.html) 循环。

`while` 像重复的 [if](#if-语句)一样工作：

```fish
while true
    echo 仍在运行
    sleep 1
end
```

将每秒打印 "仍在运行"。您可以使用 ctrl-c 中止它。

`for` 循环的工作方式与其他 shell 一样，更像 Python 的 for 循环，而不是 C 的：

```fish
for file in *
    echo 文件：$file
end
```

将打印当前目录中的每个文件。`in` 之后的部分是参数列表，因此您可以在那里使用任何[扩展](#参数扩展)：

```fish
set moreanimals bird fox
for animal in {cat,}fish dog $moreanimals
   echo 我喜欢 $animal
end
```

如果需要数字列表，可以使用 `seq` 命令创建：

```fish
for i in (seq 1 5)
    echo $i
end
```

[break](cmds/break.html) 可用于跳出循环，[continue](cmds/continue.html) 用于跳转到下一次迭代。

[输入和输出重定向](#输入输出重定向)（包括[管道](#管道)）也可以应用于循环：

```fish
while read -l line
    echo 行：$line
end < file
```

此外，还有一个 [begin](cmds/begin.html) 块，它只是将命令分组在一起，以便您可以重定向到块或使用新的[变量作用域](#变量作用域)，而无需重复：

```fish
begin
   set -l foo bar # 此变量仅在此块中可用！
end
```

## 参数扩展

当 fish 收到命令行时，它在将参数发送到命令之前对其进行扩展。有几种不同类型的扩展：

-   [通配符](#通配符)，用于从模式创建文件名 —— `*.jpg`
-   [变量扩展](#变量扩展)，使用变量的值 —— `$HOME`
-   [命令替换](#命令替换)，使用另一个命令的输出 —— `$(cat /path/to/file)`
-   [大括号扩展](#大括号扩展)，以更短的方式编写带有公共前/后缀的列表 —— `{/usr,}/bin`
-   [波浪号扩展](#主目录扩展)，将路径开头的 `~` 转换为主目录路径 —— `~/bin`

参数扩展限制为 524288 个项目。操作系统允许任何命令的参数数量有限制，而 524288 远高于该限制。这是防止 shell 因无用的计算而挂起的措施。

### 通配符（"Globbing"）

当参数包含[未加引号](#引号)的 `*` 星号或 `?` 问号时，fish 将其用作匹配文件的通配符。

-   `*` 匹配文件名中的任意数量的字符（包括零个），不包括 `/`。
-   `**` 匹配任意数量的字符（包括零个），并递归到子目录中。如果 `**` 本身是一个段，该段可以匹配零次，以与其他 shell 兼容。
-   `?` 可以匹配除 `/` 以外的任何单个字符。这已被弃用，可以通过 `qmark-noglob` [特性标志](#未来特性标志)禁用，使 `?` 成为普通字符。

通配符匹配按不区分大小写排序。当排序包含数字的匹配项时，它们被自然排序，以便字符串 '1'、'5' 和 '12' 会按 1、5、12 的顺序排序。

隐藏文件（名称以点开头的文件）在通配符匹配时不会被考虑，除非通配符字符串在该位置有一个点。

示例：

-   `a*` 匹配当前目录中以 'a' 开头的任何文件。
-   `**` 匹配当前目录及其所有子目录中的任何文件和目录。
-   `~/.*` 匹配您主目录中的所有隐藏文件（也称为"dotfiles"）和目录。

对于大多数命令，如果任何通配符无法扩展，命令不会被执行，[$status](#状态变量) 被设置为非零，并打印警告。此行为类似于 bash 中 `shopt -s failglob` 的效果。有一些例外，即 [set](cmds/set.html) 和 [path](cmds/path.html)，在[重写变量](#重写单条命令的变量)中重写变量，[count](cmds/count.html) 和 [for](cmds/for.html)。它们的通配符将扩展为零个参数（因此命令根本看不到它们），类似于 bash 中的 `shopt -s nullglob`。

示例：

```fish
# 列出 .foo 文件，如果没有则警告。
ls *.foo

# 列出 .foo 文件（如果有的话）。
set foos *.foo
if count $foos >/dev/null
    ls $foos
end
```

与 bash 不同（默认情况下），fish 在未找到匹配项时不会传递字面通配符，因此对于像 `apt install` 这样自己进行匹配的命令，您需要添加引号：

```fish
apt install "ncurses-*"
```

### 变量扩展

fish 中最重要的扩展之一是"变量扩展"。这是用变量的*值*替换美元符号 (`$`) 后跟的变量名。

一个简单的例子：

```fish
echo $HOME
```

这将用当前用户的主目录替换 `$HOME`，并将其传递给 [echo](cmds/echo.html)，然后 echo 将其打印出来。

有些变量如 `$HOME` 已经设置，因为 fish 默认设置它们，或者因为 fish 的父进程在启动 fish 时将它们传递给了 fish。您可以通过 [set](cmds/set.html) 设置来定义自己的变量：

```fish
set my_directory /home/cooluser/mystuff
ls $my_directory
# 显示 /home/cooluser/mystuff 的内容
```

有关变量设置如何工作的更多信息，请参阅 [Shell 变量](#shell-变量)及其后续部分。

有时变量由于未定义或为空而没有值，它将扩展为空：

```fish
echo $nonexistentvariable
# 不打印任何输出。
```

要将变量名与文本分开，您可以将变量括在双引号或花括号中：

```fish
set WORD cat
echo $WORD 的复数是 "$WORD"s
# 打印 "The plural of cat is cats"，因为 $WORD 设置为 "cat"。
echo $WORD 的复数是 {$WORD}s
# 同上
```

如果没有引号或花括号，fish 将尝试扩展一个名为 `$WORDs` 的变量，它可能不存在。

后一种语法 `{$WORD}` 是[大括号扩展](#大括号扩展)的一个特例。

如果此处的 $WORD 未定义或为空列表，则不会打印 "s"。然而，如果 $WORD 是空字符串（如在 `set WORD ""` 之后），则会打印 "s"。

有关 shell 变量的更多信息，请阅读 [Shell 变量](#shell-变量)部分。

#### 引用变量

变量扩展也会发生在双引号字符串中。在双引号 (`"这些"`) 内，变量将始终扩展为恰好一个参数。如果它们为空或未定义，将产生空字符串。如果它们有一个元素，将扩展为该元素。如果它们有多个元素，元素将以空格连接，除非该变量是[路径变量](#路径变量) —— 在这种情况下将使用冒号 (`:`) 连接。

Fish 变量都是[列表](#列表)，它们在*设置*时被分割成元素 —— 这意味着使用 [set](cmds/set.html) 时决定是否使用引号很重要：

```fish
set foo 1 2 3 # 一个有三个元素的变量
rm $foo # 运行等价于 `rm 1 2 3` —— 尝试删除三个文件：1、2 和 3。
rm "$foo" # 运行 `rm '1 2 3'` —— 尝试删除一个名为 '1 2 3' 的文件

set foo # 一个空变量
rm $foo # 运行没有参数的 `rm`
rm "$foo" # 运行等价于 `rm ''`

set foo "1 2 3"
rm $foo # 运行等价于 `rm '1 2 3'` —— 尝试删除一个文件
rm "$foo" # 相同
```

这与其他 shell 不同，其他 shell 进行所谓的"单词分割"，在扩展中*使用*变量时进行分割。例如在 bash 中：

```fish
foo="1 2 3"
rm $foo # 运行等价于 `rm 1 2 3`
rm "$foo" # 运行等价于 `rm '1 2 3'`
```

这是 bash 脚本中处理带空格文件名的常见问题原因。

在 fish 中，未加引号的变量将扩展为与其元素数量一样多的参数。这意味着空列表将扩展为空，有一个元素的变量将扩展为该元素，而有多个元素的变量将分别扩展为每个元素。

如果变量扩展为空，它将取消附加到其上的任何其他字符串。有关更多信息，请参阅[组合列表](#组合列表)部分。

大多数情况下，不引用变量是正确的。例外情况是当您需要确保变量作为一个元素传递时，即使它可能未设置或有多个元素。这经常发生在 [test](cmds/test.html) 中：

```fish
set -l foo one two three
test -n $foo
# 打印错误，说它得到了太多参数，因为它被执行为
test -n one two three

test -n "$foo"
# 有效，因为它被执行为
test -n "one two three"
```

#### 解引用变量

`$` 符号也可以多次使用，作为一种"解引用"操作符（类似 C 或 C++ 中的 `*`），如以下代码所示：

```fish
set foo a b c
set a 10; set b 20; set c 30
for i in (seq (count $$foo))
    echo $$foo[$i]
end

# 输出为：
# 10
# 20
# 30
```

`$$foo[$i]` 是"由 `$foo[$i]` 命名的变量的值"。

这也可用于将变量名传递给函数：

```fish
function print_var
    for arg in $argv
        echo 变量 $arg 的值是 $$arg
    end
end

set -g foo 1 2 3
set -g bar a b c

print_var foo bar
# 打印 "Variable foo is 1 2 3" 和 "Variable bar is a b c"
```

当然，变量必须能从函数中访问，因此它需要是[全局/通用](#变量作用域)的或[导出](#导出变量)的。它也不能与函数内部使用的变量名冲突。因此，如果我们在此处将 $foo 设为局部变量，或将其命名为 "arg"，它将无法工作。

当与[切片](#切片)一起使用此功能时，切片将从内到外使用。`$$foo[5]` 将使用 `$foo` 的第五个元素作为变量名，而不是给出 `$foo` 引用的所有变量的第五个元素。后者应表示为 `$$foo[1..-1][5]`（获取 `$foo` 的所有元素，将它们用作变量名，然后给出这些变量中每一个的第五个元素）。

更多示例：

```fish
set listone 1 2 3
set listtwo 4 5 6
set var listone listtwo

echo $$var
# 输出为 1 2 3 4 5 6

echo $$var[1]
# 输出为 1 2 3

echo $$var[2][3]
# $var[2] 是 listtwo，其第三个元素是 6，输出为 6

echo $$var[..][2]
# 每个变量的第二个元素，因此输出为 2 5
```

#### 变量作为命令

像其他 shell 一样，您可以将变量的值作为命令运行。

```fish
> set -g EDITOR emacs
> $EDITOR foo # 打开 emacs，可能是 GUI 版本
```

如果要将命令的参数放在变量内，它需要是一个单独的元素：

```fish
> set EDITOR emacs -nw
> $EDITOR foo # 即使安装了 GUI，也在终端中打开 emacs
> set EDITOR "emacs -nw"
> $EDITOR foo # 尝试查找名为 "emacs -nw" 的命令
```

同样像其他 shell 一样，这只适用于命令、内置命令和函数 —— 它不适用于关键字，因为它们具有语法重要性。

例如 `set if $if` 不允许您创建 if 块，`set cmd command` 不允许您使用 [command](cmds/command.html) 装饰器，只能像 `$cmd -q foo` 这样使用。

### 命令替换

`命令替换`是一种扩展，它使用命令的*输出*作为另一个命令的参数。例如：

```fish
echo $(pwd)
```

这将执行 [pwd](cmds/pwd.html) 命令，获取其输出（更具体地说，它写入标准输出 "stdout" 流的内容），并将其用作 [echo](cmds/echo.html) 的参数。因此，内部命令（`pwd`）首先运行，并且在外部命令可以启动之前必须完成。

如果内部命令打印多行，fish 将把每行作为外部命令的单独参数。与其他 shell 不同，不使用 `$IFS` 的值（一个例外：将 `$IFS` 设置为空将禁用行分割。这已被弃用，请改用 [string split](cmds/string-split.html)），fish 在换行符上分割。

命令替换也可以使用双引号：

```fish
echo "$(pwd)"
```

使用双引号时，命令输出不会被行分割，但尾随空行仍然会被移除。

如果输出作为最后一步通过管道传递给 [string split 或 string split0](cmds/string-split.html)，则这些分割将按原样使用，而不是分割行。

Fish 也允许不写美元的写法，如 `echo (pwd)`。此变体不会在双引号中扩展（`echo "(pwd)"` 将打印 `(pwd)`）。

最后一次运行的命令替换的退出状态可在 [status](#状态变量) 变量中找到，前提是该替换发生在 [set](cmds/set.html) 命令的上下文中（因此 `if set -l (something)` 检查 `something` 是否返回 true）。

要仅使用输出的某些行，请参考[切片](#切片)。

示例：

```fish
# 输出 'image.png'。
echo (basename image.jpg .jpg).png

# 使用 'convert' 程序将当前目录中的
# 所有 JPEG 文件转换为 PNG 格式。
for i in *.jpg; convert $i (basename $i .jpg).png; end

# 将 ``data`` 变量设置为 'data.txt' 的内容，
# 不分割为列表。
set data "$(cat data.txt)"

# 将 ``$data`` 设置为数据的内容，在 NUL 字节上分割。
set data (cat data | string split0)
```

有时您想将命令的输出传递给另一个只接受文件的命令。如果只有一个文件，通常可以通过管道传递，例如：

```fish
grep fish myanimallist1 | wc -l
```

但如果需要多个文件，或者命令不从标准输入读取，则"进程替换"很有用。其他 shell 通过 `foo <(bar) <(baz)` 允许这样做，而 fish 使用 [psub](cmds/psub.html) 命令：

```fish
# 比较两个文件中包含 "fish" 的行：
diff -u (grep fish myanimallist1 | psub) (grep fish myanimallist2 | psub)
```

这会创建一个临时文件，将命令的输出存储在该文件中并打印文件名，因此它被传递给外部命令。

Fish 对命令替换中读取的数据有 1 GiB 的默认限制。如果达到该限制，命令（整个命令，不仅仅是命令替换 —— 外部命令根本不会执行）失败，`$status` 被设置为 122。这是为了使命令替换不会导致系统内存不足，因为通常您的操作系统有更低的限制，因此读取超过该限制将是无用且有害的。此限制可以通过 `fish_read_limit` 变量调整（0 表示无限制）。此限制也影响 [read](cmds/read.html) 命令。

### 大括号扩展

花括号可用于编写逗号分隔的列表。它们将被扩展，每个元素成为新参数，并附加周围的字符串。这对于节省输入和将变量名与周围文本分开很有用。

示例：

```fish
> echo input.{c,h,txt}
input.c input.h input.txt

# 将所有后缀为 '.c' 或 '.h' 的文件移动到子目录 src。
> mv *.{c,h} src/

# 在 `file.bak` 处创建 `file` 的副本。
> cp file{,.bak}

> set -l dogs hot cool cute "good "
> echo {$dogs}dog
hotdog cooldog cutedog good dog
```

如果花括号之间没有 "," 或变量扩展，它们将不会被扩展：

```fish
# 这个 {} 不是特殊字符
> echo foo-{}
foo-{}
# 这将 "HEAD@{2}" 传递给 git
> git reset --hard HEAD@{2}
> echo {{a,b}}
{a} {b} # 因为内部花括号对被扩展，但外部没有被扩展。
```

如果扩展后花括号之间没有任何内容，参数将被移除（请参阅[组合列表](#组合列表)部分）：

```fish
> echo foo-{$undefinedvar}
# 输出为空行，就像裸 `echo`。
```

如果花括号和逗号之间或两个逗号之间没有任何内容，它被解释为空元素：

```fish
> echo {,,/usr}/bin
/bin /bin /usr/bin
```

要将 "," 用作元素，请[引用](#引号)或[转义](#转义字符)它。

命令标记的第一个字符永远不会被解释为扩展花括号，因为它是[复合语句](cmds/begin.html)的开头：

```fish
> {echo hello, && echo world}
hello,
world
```

### 组合列表

Fish 像[大括号扩展](#大括号扩展)一样扩展列表：

```fish
>_ set -l foo x y z
>_ echo 1$foo
# $foo 的任何元素与 "1" 组合：
1x 1y 1z

>_ echo {good,bad}" apples"
# {} 的任何元素与 " apples" 组合：
good apples bad apples

# 或者我们可以混合两者：
>_ echo {good,bad}" "$foo
good x bad x good y bad y good z bad z
```

附加到列表的任何字符串都将连接到每个元素。

两个列表将以所有组合扩展 —— 第一个列表的每个元素与第二个列表的每个元素：

```fish
>_ set -l a x y z; set -l b 1 2 3
>_ echo $a$b # 等同于 {x,y,z}{1,2,3}
x1 y1 z1 x2 y2 z2 x3 y3 z3
```

这样做的结果是，如果列表没有元素，这会将字符串与零个元素组合，这意味着整个标记被移除！

```fish
>_ set -l c # <- 此列表为空！
>_ echo {$c}word
# 输出为空行 —— "word" 部分消失了
```

这可能很有用。例如，如果您想遍历 [`PATH`](#环境变量-PATH) 中所有目录中的所有文件，请使用：

```fish
for file in $PATH/*
```

因为 [`PATH`](#环境变量-PATH) 是一个列表，这会扩展到其中所有目录中的所有文件。如果 [`PATH`](#环境变量-PATH) 中没有目录，正确的答案是扩展为空。

有时这可能不是想要的，特别是标记在扩展后可能消失。在这些情况下，您应该用双引号引用变量 —— `echo "$c"word`。

这也发生在[命令替换](#命令替换)之后。为避免标记在那里消失，请使内部命令返回尾随换行符，或用双引号引用它：

```fish
>_ set b 1 2 3
>_ echo (echo x)$b
x1 x2 x3
>_ echo (printf '%s' '')banana
# printf 不打印任何内容，所以这是零个元素乘以 "banana"，
# 结果是空。
>_ echo (printf '%s\n' '')banana
# printf 打印一个换行符，
# 所以命令替换扩展为空字符串，
# 所以这是 `''banana`
banana
>_ echo "$(printf '%s' '')"banana
# 引号意味着这是一个参数，banana 保留
```

### 切片

有时需要仅访问[列表](#列表)的部分元素（所有 fish 变量都是列表），或仅访问[命令替换](#命令替换)输出的部分行。在 fish 中，两者都可以通过在方括号中写入一组索引来实现，例如：

```fish
# 将 $var 设为四个元素的列表
set var one two three four
# 打印第二个：
echo $var[2]
# 打印 "two"
# 或打印前三个：
echo $var[1..3]
# 打印 "one two three"
```

在索引括号中，fish 理解写成 `a..b` 的范围（'a' 和 'b' 是索引）。它们被扩展为从 a 到 b 的索引序列（即 `a a+1 a+2 ... b`），如果 b 较大则向上，如果 a 较大则向下。也可以使用负索引 —— 它们从列表末尾计算，因此 `-1` 是最后一个元素，`-2` 是倒数第二个。如果索引不存在，范围将夹紧到下一个可能索引。

如果列表有 5 个元素，索引从 1 到 5，因此 `2..16` 的范围只会从元素 2 到元素 5。

如果结束索引为负，范围始终向上，因此 `2..-2` 将从元素 2 到 4，而 `2..-16` 不会去任何地方，因为在向上时无法从第二个元素到不存在的元素。如果起始索引为负，范围始终向下，因此 `-2..1` 将从元素 4 到 1，而 `-16..2` 不会去任何地方，因为在向下时无法从不存在的元素到第二个元素。

范围中缺少的起始索引默认为 1。如果范围是序列的第一个索引表达式，这是允许的。同样，序列中最后一个索引的缺少结束索引默认为 -1。

也可以使用多个范围，用空格分隔。

一些示例：

```fish
echo (seq 10)[1 2 3]
# 打印：1 2 3

# 限制命令替换输出
echo (seq 10)[2..5]
# 使用从 2 到 5 的元素
# 输出为：2 3 4 5

echo (seq 10)[7..]
# 打印：7 8 9 10

# 使用重叠范围：
echo (seq 10)[2..5 1..3]
# 获取元素 2 到 5，然后是元素 1 到 3
# 输出为：2 3 4 5 1 2 3

# 反转输出
echo (seq 10)[-1..1]
# 使用从最后一个输出行到第一个的元素，反向
# 输出为：10 9 8 7 6 5 4 3 2 1

# 命令替换只有一行，
# 因此这些将产生空输出：
echo (echo one)[2..-1]
echo (echo one)[-3..1]
```

在设置或扩展变量时也可以同样使用：

```fish
# 反转路径变量
set PATH $PATH[-1..1]
# 或
set PATH[-1..1] $PATH

# 仅使用 PATH 的最后 n 项
set n -3
echo $PATH[$n..-1]
```

变量可以用作变量扩展的索引，如下所示：

```fish
set index 2
set letters a b c d
echo $letters[$index] # 返回 'b'
```

然而，目前不支持使用变量作为命令替换的索引，因此：

```fish
echo (seq 5)[$index] # 这不起作用

set sequence (seq 5) # 需要像这样写在两行上。
echo $sequence[$index] # 返回 '2'
```

当使用间接变量扩展与多个 `$` (`$$name`) 时，您必须提供直到要切片的变量的所有索引：

```fish
> set -l list 1 2 3 4 5
> set -l name list
> echo $$name[1]
1 2 3 4 5
> echo $$name[1..-1][1..3] # 或 $$name[1][1..3]，因为 $name 只有一个元素。
1 2 3
```

### 主目录扩展

参数开头的 `~`（波浪号）字符后跟用户名，将扩展为指定用户的主目录。单独的 `~`，或后跟斜杠的 `~`，将扩展为进程所有者的主目录：

```fish
ls ~/Music # 列出我的音乐目录

echo ~root # 打印 root 的主目录，可能是 "/root"
```

### 组合不同的扩展

以上所有扩展都可以组合使用。如果多个扩展导致多个参数，将创建所有可能的组合。

组合多个参数扩展时，扩展按以下顺序执行：

1.  命令替换
2.  变量扩展
3.  方括号扩展
4.  通配符扩展

扩展从右到左执行，嵌套的方括号扩展和命令替换从内到外执行。

示例：

如果当前目录包含文件 'foo' 和 'bar'，命令 `echo a(ls){1,2,3}` 将输出 `abar1 abar2 abar3 afoo1 afoo2 afoo3`。

## 操作符表

以下是 fish 操作符的快速参考，包含所有特殊符号：

| 符号 | 含义 | 示例 |
|------|------|------|
| `$` | [变量扩展](#变量扩展) | `echo $foo` |
| `$()` 和 `()` | [命令替换](#命令替换) | `cat (grep foo bar)` 或 `cat $(grep foo bar)` |
| `<` 和 `>` | [重定向](#输入输出重定向)，如 `command > file` | `git shortlog -nse . > authors` |
| `\|` | [管道](#管道)，连接两个或多个命令 | `foo \| grep bar \| grep baz` |
| `;` | 命令结束，代替换行符 | `command1; command2` |
| `&` | [后台执行](#作业控制) | `sleep 5m &` |
| `{}` | [大括号扩展](#大括号扩展) | `ls {/usr,}/bin` |
| `&&` 和 `\|\|` | [组合器](#组合器-and--or) | `mkdir foo && cd foo` 或 `rm foo \|\| exit` |
| `*` 和 `**` | [通配符](#通配符) | `cat *.fish` 或 `count **.jpg` |
| `\` | [转义](#转义字符) | `echo foo\nbar` 或 `echo \$foo` |
| `''` 和 `""` | [引号](#引号) | `rm "file with spaces"` 或 `echo '$foo'` |
| `~` | [主目录扩展](#主目录扩展) | `ls ~/` 或 `ls ~root/` |
| `#` | [注释](#注释) | `echo Hello # 这不会被打印` |

## Shell 变量

变量是一种保存数据和传递数据的方式。它们可以仅在 shell 中使用，也可以"[导出](#导出变量)"，以便 shell 启动的任何外部命令都可以使用该变量的副本。导出的变量称为"环境变量"。

要设置变量值，使用 [set](cmds/set.html) 命令。变量名不能为空，只能包含字母、数字和下划线。它可以以这些字符中的任何一个开头和结尾。

示例：

要将变量 `smurf_color` 设置为值 `blue`，请使用命令 `set smurf_color blue`。

设置变量后，可以通过[变量扩展](#变量扩展)在 shell 中使用变量的值。

示例：

```fish
set smurf_color blue
echo 蓝精灵通常是 $smurf_color
set pants_color red
echo 蓝爸爸，他是 $smurf_color 的，穿着 $pants_color 裤子
```

因此，您用 `set` 设置变量，用 `$` 和名称来使用它。

### 变量作用域

Fish 中的所有变量都有作用域。例如，它们可以是全局的，也可以是函数或块的局部变量：

```fish
# 此变量是全局的，我们可以在任何地方使用它。
set --global name Patrick
# 此变量是局部的，在我们从这里调用的函数中不可见。
set --local place "在蟹堡王"

function local
    # 这可以找到 $name，但找不到 $place
    echo 你好，这是 $name $place

    # 此变量是局部的，在此函数外部不可用
    set --local instrument 蛋黄酱
    echo 我最喜欢的乐器是 $instrument
    # 这创建了一个局部的 $name，不会触及全局的那个
    set --local name 海绵宝宝
    echo 我最好的朋友是 $name
end

local
# 将打印：
# 你好，这是 Patrick
# 我最喜欢的乐器是 蛋黄酱
# 我最好的朋友是 海绵宝宝

echo $name, 我在 $place，我的乐器是 $instrument
# 将打印：
# Patrick, 我在蟹堡王，我的乐器是
```

fish 中有四种变量作用域：通用变量、全局变量、函数变量和局部变量。

-   **通用变量**在同一台计算机上用户运行的所有 fish 会话之间共享。它们存储在磁盘上，即使在重启后也会持久存在。
-   **全局变量**特定于当前 fish 会话。它们可以通过显式请求 `set -e` 来擦除。
-   **函数变量**特定于当前正在执行的函数。当当前函数结束时，它们被擦除（"超出作用域"）。在函数之外，它们不会超出作用域。
-   **局部变量**特定于当前命令块，并在特定块超出作用域时自动擦除。命令块是一系列命令，以 `for`、`while`、`if`、`function`、`begin` 或 `switch` 命令之一开头，以 `end` 命令结束。在块之外，这与函数作用域相同。

可以使用 `-U` 或 `--universal` 开关显式将变量设置为通用变量，使用 `-g` 或 `--global` 设置为全局变量，使用 `-f` 或 `--function` 设置为函数作用域，使用 `-l` 或 `--local` 设置为当前块的局部变量。创建或更新变量时的作用域规则如下：

-   当显式给出作用域时，将使用它。如果不同作用域中存在同名变量，该变量不会被更改。
-   当未给出作用域，但存在该名称的变量时，将修改最小作用域的变量。作用域不会被改变。
-   当未给出作用域且不存在该名称的变量时，如果在函数内部，则在函数作用域中创建变量；如果没有函数执行，则在全局作用域中创建。

可以有多个同名但不同作用域的变量。当您[使用变量](#变量扩展)时，将使用该名称的最小作用域变量。如果存在局部变量，它将代替同名的全局或通用变量被使用。

示例：

不同作用域有一些可能的用途。

通常在函数内部，您应该使用局部作用域：

```fish
function something
    set -l file /path/to/my/file
    if not test -e "$file"
        set file /path/to/my/otherfile
    end
end

# 或

function something
    if test -e /path/to/my/file
        set -f file /path/to/my/file
    else
        set -f file /path/to/my/otherfile
    end
end
```

如果要在 config.fish 中设置某些内容，或在函数中设置某些内容并使其在会话的其余部分中可用，全局作用域是一个不错的选择：

```fish
# 不要在提示符中缩短工作目录
set -g fish_prompt_pwd_dir_length 0

# 设置我偏好的光标样式：
function setcursors
   set -g fish_cursor_default block
   set -g fish_cursor_insert line
   set -g fish_cursor_visual underscore
end

# 设置我的语言
set -gx LANG de_DE.UTF-8
```

下面是局部变量与函数作用域变量的示例：

```fish
function test-scopes
    begin
        # 这是一个很好的局部作用域，所有变量都将消失
        set -l pirate '山里有宝藏'
        set -f captain 太空，最后的疆域
        # 如果没有定义该名称的变量，则它是函数局部的。
        set gnu "起初什么都没有，然后它爆炸了"
    end

    # 这将不输出任何内容，因为 pirate 是局部的
    echo $pirate
    # 这将输出好船长的演讲，因为 $captain 具有函数作用域。
    echo $captain
    # 这将输出 Sir Terry 的智慧。
    echo $gnu
end
```

当一个函数调用另一个函数时，局部变量不可见：

```fish
function shiver
    set phrase '颤抖吧我的船板'
end

function avast
    set --local phrase '停船，伙计们'
    # 在这里调用 shiver 函数不能更改局部作用域中的任何变量
    # 因此 phrase 保持我们在此处设置的值。
    shiver
    echo $phrase
end
avast

# 输出 "停船，伙计们"
```

如有疑问，使用函数作用域变量。当需要使变量在任何地方都可访问时，将其设为全局。当需要持久存储配置时，将其设为通用。当只想在短块中使用变量时，将其设为局部。

### 重写单条命令的变量

如果要为单条命令重写变量，可以在命令前使用 "var=val" 语句：

```fish
# 在另一个目录上调用 git status
# （也可以通过 `git -C somerepo status` 完成）
GIT_DIR=somerepo git status
```

与其他 shell 不同，fish 将首先设置变量，然后对行执行其他扩展，因此：

```fish
set foo banana
foo=gagaga echo $foo
# 打印 gagaga，而在其他 shell 中可能打印 "banana"
```

可以在[大括号扩展](#大括号扩展)中给出多个元素：

```fish
# 使用合理的默认路径调用 bash。
PATH={/usr,}/{s,}bin bash
```

或使用[通配符](#通配符)：

```fish
# 在当前目录中的所有 mp3 文件上运行 vlc
# 如果不存在文件，它仍将以无参数方式运行
mp3s=*.mp3 vlc $mp3s
```

与其他 shell 不同，这*不会*抑制任何查找（别名或类似物）。设置变量重写后调用命令将导致完全相同的命令被运行。

此语法自 fish 3.1 起支持。

### 通用变量

通用变量是在计算机上用户的所有 fish 会话之间共享的变量。对通用变量的所有更改都是持久的，并立即在 fish 会话之间传播。

[通用变量](#通用变量)存储在文件 `.config/fish/fish_variables` 中。不要直接编辑此文件，因为您的编辑可能会被覆盖。请通过 fish 脚本或交互式使用 fish 来编辑变量。

不要在 [config.fish](#配置文件) 中向通用变量追加内容，因为这些变量会随着每个新 shell 实例而变长。相反，请在命令行上一次设置它们。

### 导出变量

Fish 中的变量可以导出，因此它们将被 fish 启动的任何命令继承。特别是，这对于用于配置外部命令（如 `PAGER` 或 `GOPATH`）的变量是必要的，但也适用于包含一般系统设置（如 `PATH` 或 `LANGUAGE`）的变量。如果外部命令需要知道一个变量，则该变量需要被导出。导出的变量也常被称为"环境变量"。

这也适用于 fish —— 当它启动时，它会从其父进程（通常是终端）接收环境变量。这些通常包括系统配置，如 [`PATH`](#环境变量-PATH) 和[区域设置变量](#区域设置变量)。

变量可以使用 `-x` 或 `--export` 开关显式设置为导出，或使用 `-u` 或 `--unexport` 开关设置为不导出。设置变量时的导出规则类似于变量的作用域规则 —— 当传递选项时，会遵循该选项；否则使用变量的现有状态。如果未传递选项且变量尚不存在，则不被导出。

作为命名约定，导出的变量使用大写字母，未导出的变量使用小写字母。

例如：

```fish
set -gx ANDROID_HOME ~/.android # /opt/android-sdk
set -gx CDPATH . ~ (test -e ~/Videos; and echo ~/Videos)
set -gx EDITOR emacs -nw
set -gx GOPATH ~/dev/go
set -gx GTK2_RC_FILES "$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
set -gx LESSHISTFILE "-"
```

注意：导出不是[作用域](#变量作用域)，而是一个附加状态。通常将导出的变量也设为全局是有意义的，但如果需要比重写更具体的内容，局部导出的变量也很有用。它们被*复制*到函数中，因此函数无法在外部更改它们，但仍然可用于命令。全局变量无论是否导出，函数都可访问。

### 列表

Fish 可以在变量中存储多个字符串的列表（或"数组"）：

```fish
> set mylist first second third
> printf '%s\n' $mylist # 在一行上打印每个元素
first
second
third
```

要访问列表的一个元素，在方括号内使用元素的索引，如下所示：

```fish
echo $PATH[3]
```

在 fish 中，列表索引从 1 开始，而不是像其他语言那样从 0 开始。这是因为这样需要的 1 减法更少，而且许多常见的 Unix 工具（如 `seq`）与此配合得更好（`seq 5` 打印 1 到 5，而不是 0 到 5）。无效索引会被静默忽略，导致没有值（甚至不是空字符串，根本没有参数）。

如果不使用任何方括号，列表的所有元素将作为单独项目传递给命令。这意味着您可以使用 `for` 遍历列表：

```fish
for i in $PATH
    echo $i 在路径中
end
```

这会分别遍历 [`PATH`](#环境变量-PATH) 中的每个目录，并打印一行，说明它在路径中。

要创建包含项目 `blue` 和 `small` 的变量 `smurf`，请写入：

```fish
set smurf blue small
```

也可以设置或擦除列表的单个元素：

```fish
# 将 smurf 设置为包含元素 'blue' 和 'small' 的列表
set smurf blue small

# 将 smurf 的第二个元素更改为 'evil'
set smurf[2] evil

# 擦除第一个元素
set -e smurf[1]

# 输出 'evil'
echo $smurf
```

如果在扩展或赋值列表变量时指定负索引，索引将从列表*末尾*计算。例如，索引 -1 是列表的最后一个元素：

```fish
> set fruit apple orange banana
> echo $fruit[-1]
banana

> echo $fruit[-2..-1]
orange
banana

> echo $fruit[-1..1] # 反转列表
banana
orange
apple
```

如您所见，您可以使用索引范围，详情请参阅[切片](#切片)。

所有列表都是一维的，不能包含其他列表，尽管可以使用解引用来模拟嵌套列表 —— 请参阅[变量扩展](#变量扩展)。

当列表作为环境变量导出时，它将以空格或冒号分隔，具体取决于它是否是[路径变量](#路径变量)：

```fish
> set -x smurf blue small
> set -x smurf_PATH forest mushroom
> env | grep smurf
smurf=blue small
smurf_PATH=forest:mushroom
```

Fish 会自动从名称以 `PATH` 结尾的所有环境变量（如 [`PATH`](#环境变量-PATH)、[`CDPATH`](#环境变量-CDPATH) 或 `MANPATH`）创建列表，通过在冒号上分割它们来实现。其他变量不会自动分割。

列表可以使用 [count](cmds/count.html) 或 [contains](cmds/contains.html) 命令进行检查：

```fish
> count $smurf
2

> contains blue $smurf
# 找到了 blue，因此它以状态 0 退出
# （不打印任何内容）

> echo $status
0

> contains -i blue $smurf
1
```

列表的一个好处是，它们将每个元素作为一个参数传递给命令，因此一旦设置了列表，就可以传递它：

```fish
set -l grep_args -r "my string"
grep $grep_args . # 将运行与 `grep -r "my string"` . 相同的结果
```

与其他 shell 不同，fish 不进行"单词分割" —— 列表中的元素保持原样，即使它们包含空格或制表符。

### 参数处理

一个重要的列表是 `$argv`，它包含函数或脚本的参数。例如：

```fish
function myfunction
    echo $argv[1]
    echo $argv[3]
end
```

此函数获取它收到的任何参数并打印第一个和第三个：

```fish
> myfunction first second third
first
third

> myfunction apple cucumber banana
apple
banana
```

这涵盖了位置参数，但命令行工具通常会获得各种选项和标志，而 $argv 会将它们与位置参数混在一起。典型的 Unix 参数处理允许短选项（`-h`，也可以组合，如 `ls -lah`）、长选项（`--help`），并允许这些选项接受参数（`--color=auto` 或 `--position anywhere` 或 `complete -C"git "`），以及用于表示选项结束的 `--` 分隔符。手动处理所有这些既棘手又容易出错。

更健壮的选项处理方法是 [argparse](cmds/argparse.html)，它检查定义的选项并将它们放入各种变量中，只在 $argv 中保留位置参数。下面是一个简单的示例：

```fish
function mybetterfunction
    # 我们告诉 argparse 关于 -h/--help 和 -s/--second
    # —— 这些是同一选项的短格式和长格式。
    # 这里的 "--" 是必需的，
    # 它告诉它从哪里读取参数。
    argparse h/help s/second -- $argv
    # 如果 argparse 失败（因为它发现了不认识的选项）
    # 则退出 —— 它将打印错误
    or return

    # 如果给出 -h 或 --help，我们打印一小段帮助文本并返回
    if set -ql _flag_help
        echo "mybetterfunction [-h|--help] [-s|--second] [参数 ...]"
        return 0
    end

    # 如果给出 -s 或 --second，我们打印第二个参数，
    # 而不是第一个和第三个。
    # （因为短版本，这也作为 _flag_s 可用）
    if set -ql _flag_second
        echo $argv[2]
    else
        echo $argv[1]
        echo $argv[3]
    end
end
```

选项将从 $argv 中*移除*，因此 $argv[2] 现在是第二个*位置*参数：

```fish
> mybetterfunction first -s second third
second
```

有关 argparse 的更多信息，例如如何处理选项参数，请参阅 [argparse 文档](cmds/argparse.html)。

### 路径变量

路径变量是一种特殊的变量，用于支持冒号分隔的路径列表，包括 [`PATH`](#环境变量-PATH)、[`CDPATH`](#环境变量-CDPATH)、`MANPATH`、`PYTHONPATH`、[`LANGUAGE`](#环境变量-LANGUAGE)（用于[本地化](cmds/_.html)）等。默认情况下，所有以 "PATH" 结尾的变量（区分大小写）都成为路径变量。

路径变量的行为与普通列表相同，但它们会隐式地在冒号上进行合并和分割。

```fish
set MYPATH 1 2 3
echo "$MYPATH"
# 1:2:3
set MYPATH "$MYPATH:4:5"
echo $MYPATH
# 1 2 3 4 5
echo "$MYPATH"
# 1:2:3:4:5
```

路径变量也将以冒号形式导出，因此 `set -x MYPATH 1 2 3` 会使外部命令将其视为 `1:2:3`。

```fish
> set -gx MYPATH /bin /usr/bin /sbin
> env | grep MYPATH
MYPATH=/bin:/usr/bin:/sbin
```

这是为了与其他工具兼容。Unix 没有多元素变量，最接近的是像 [`PATH`](#环境变量-PATH) 这样的冒号列表。出于显而易见的原因，这意味着没有元素可以包含 `:`。

变量可以通过 `set` 的 `--path` 和 `--unpath` 选项标记或取消标记为路径变量。

### 特殊变量

您可以通过更改某些变量的值来更改 fish 的设置。

#### 环境变量 PATH

在其中搜索命令的目录列表。这是一个常见的 Unix 变量，也被其他工具使用。

#### 环境变量 CDPATH

[cd](cmds/cd.html) 内置命令在其中查找新目录的目录列表。

#### 区域设置变量

如 [`LANG`](#环境变量-LANG)、[`LC_ALL`](#环境变量-LC_ALL)、[`LC_MESSAGES`](#环境变量-LC_MESSAGES)、[`LC_NUMERIC`](#环境变量-LC_NUMERIC) 和 [`LC_TIME`](#环境变量-LC_TIME) 等区域设置变量为 shell 和子程序设置语言选项。请参阅[区域设置变量](#区域设置变量)部分和 [status language](cmds/status.html#status-language) 了解更多信息。

#### 颜色变量

许多以 `fish_color` 和 `fish_pager_color` 前缀开头的变量。请参阅[更改高亮颜色的变量](interactive.html#variables-color)了解更多信息。

#### 环境变量 fish_term24bit

如果设置为 0，fish 将不输出 24 位 RGB 真彩色序列，而是输出 256 色调色板上最接近的颜色（如果 [`fish_term256`](#环境变量-fish_term256) 为 0，则输出 16 色调色板上的颜色）。另请参阅 [set_color](cmds/set_color.html)。默认值为 1，但由于历史原因，在某些已知不支持真彩色序列的终端上，fish 默认表现得像设置为 0。

#### 环境变量 fish_term256

如果设置为 0 且 [`fish_term24bit`](#环境变量-fish_term24bit) 为 0，则将 RGB 颜色降级到 16 色调色板。此外，如果设置为 0，`set_color ff0000 red` 等 [set_color](cmds/set_color.html) 命令将优先使用命名颜色。

#### 环境变量 fish_ambiguous_width

控制模糊宽度字符的计算宽度。如果您的终端将这些字符渲染为单宽度（典型），则设置为 1；如果为双宽度，则设置为 2。

#### 环境变量 fish_emoji_width

控制 fish 假设 emoji 渲染为 2 个单元格还是 1 个单元格宽。这是必要的，因为在 Unicode 9 中正确的值从 1 变为 2，而某些终端可能不知道。如果您看到与 emoji（或其他"特殊"字符）相关的图形故障，请设置此项。默认值为 2。

#### 环境变量 fish_autosuggestion_enabled

控制是否启用[自动建议](interactive.html#autosuggestions)。设置为 0 禁用，其他任何值启用。默认情况下是开启的。

#### 环境变量 fish_transient_prompt

如果设置为 1，fish 将在运行命令行之前使用 `--final-rendering` 参数重新绘制提示符，允许您在将其推送到回滚之前更改它。这启用了[瞬态提示符](prompt.html#transient-prompt)。

#### 环境变量 fish_handle_reflow

确定 fish 是否应在终端调整大小时尝试重绘命令行。在回流文本的终端中，应禁用此选项。设置为 1 启用，其他任何值禁用。

#### 环境变量 fish_key_bindings

设置[命令行编辑器](interactive.html#editor)键盘快捷键的函数的名称。

#### 环境变量 fish_escape_delay_ms

设置 fish 在看到 escape 后等待另一个按键的时间，以区分按下 escape 键和 escape 序列的开始。默认值为 30ms。增加它会增加延迟，但允许为 alt+字符绑定按 escape 而不是 alt。有关更多信息，请参阅 [bind 文档中的章节](cmds/bind.html#cmd-bind-escape)。

#### 环境变量 fish_sequence_key_delay_ms

设置 fish 在看到作为较长序列一部分的键后等待另一个键的时间，以消除歧义。例如，如果您将 `\cx\ce` 绑定为打开编辑器，fish 将在 ctrl-x 之后等待这么多毫秒以查看 ctrl-e。如果时间到期，它将按 ctrl-x 处理（默认情况下这会复制当前命令行到剪贴板）。另请参阅[键序列](interactive.html#interactive-key-sequences)。

#### 环境变量 fish_complete_path

确定 fish 在哪里查找补全。当尝试为命令补全时，fish 在此变量的目录中查找文件。

#### 环境变量 fish_cursor_selection_mode

控制选择是包含还是排除光标下的字符（请参阅[复制和粘贴](interactive.html#killring)）。

#### 环境变量 fish_function_path

确定 fish 在哪里查找函数。当 fish [自动加载](#自动加载函数)函数时，它将在这些目录中查找文件。

#### 环境变量 fish_greeting

启动时打印的问候消息。这由同名函数打印，可以重写以进行更复杂的更改（请参阅 [funced](cmds/funced.html)）。

#### 环境变量 fish_history

当前历史记录会话名称。如果设置，交互式 fish 会话中的所有后续命令将记录到由该变量值标识的单独文件中。如果未设置，使用默认会话名称 "fish"。如果设置为空字符串，历史记录不保存到磁盘（但在交互式会话中仍然可用）。

#### 环境变量 fish_trace

如果设置且不为空，将导致 fish 在执行命令之前打印它们，类似于 bash 中的 `set -x`。跟踪输出打印到 fish 的 `--debug-output` 选项或 [`FISH_DEBUG_OUTPUT`](#环境变量-FISH_DEBUG_OUTPUT) 变量给定的路径。默认情况下输出到 stderr。设置为 `all` 也会跟踪按键绑定、事件处理器以及提示符和标题函数的执行。

#### 环境变量 FISH_DEBUG

控制 fish 为输出启用哪些调试类别，类似于 `--debug` 选项。

#### 环境变量 FISH_DEBUG_OUTPUT

指定将调试输出定向到的文件。

#### 环境变量 fish_user_paths

一个目录列表，会添加到 [`PATH`](#环境变量-PATH) 的前面。这可以是通用变量。

#### 环境变量 umask

当前文件创建掩码。更改 umask 变量的首选方式是通过 [umask](cmds/umask.html) 函数。尝试将 umask 设置为无效值将始终失败。

#### 环境变量 SHELL_PROMPT_PREFIX

如果设置，此字符串将自动添加到左侧提示符的前面。这是一个标准环境变量，可能由 systemd 的 `run0` 等工具设置，以指示特殊的 shell 会话。

#### 环境变量 SHELL_PROMPT_SUFFIX

如果设置，此字符串将自动添加到左侧提示符的后面。这是一个标准环境变量，可能由 systemd 的 `run0` 等工具设置，以指示特殊的 shell 会话。

#### 环境变量 SHELL_WELCOME

如果设置，此字符串将在交互式 shell 启动时，在问候语之后显示。这是一个标准环境变量，可能由 systemd 的 `run0` 等工具设置，以显示会话信息。

#### 环境变量 BROWSER

您偏好的 Web 浏览器。如果设置此变量，fish 将使用指定的浏览器而不是系统默认浏览器来显示 fish 文档。

Fish 还通过某些环境变量的值提供额外信息。大多数这些变量是只读的，其值不能用 `set` 更改。

#### 环境变量 _

当前正在运行的命令的名称（尽管这已被弃用，建议使用 `status current-command`）。

#### 环境变量 argv

shell 或函数的参数列表。`argv` 仅在函数调用内定义，或者在 fish 以参数列表调用时定义，如 `fish myscript.fish foo bar`。此变量可以被更改。

#### 环境变量 argv_opts

[argparse](cmds/argparse.html) 将此设置为成功解析的选项列表，包括选项参数。此变量可以被更改。

#### 环境变量 CMD_DURATION

最后一个命令的运行时间，以毫秒为单位。

#### 环境变量 COLUMNS 和 LINES

终端当前的高度和宽度大小。这些值仅在操作系统不报告终端大小时由 fish 使用。这两种情况下都必须设置这两个变量，否则将使用 80x24 的默认值。它们会在窗口大小更改时更新。

#### 环境变量 fish_kill_signal

终止最后一个前台作业的信号，如果作业正常退出则为 0。

#### 环境变量 fish_killring

fish 剪切文本[剪切环](interactive.html#killring)中的条目列表。

#### 环境变量 fish_read_limit

fish 在 [read](cmds/read.html) 或[命令替换](#命令替换)中处理的最大字节数。

#### 环境变量 fish_pid

shell 的进程 ID（PID）。

#### 环境变量 fish_terminal_color_theme

一个只读变量；当终端分别使用浅色或深色主题时，设置为 `light` 或 `dark`；如果终端未[报告其颜色](terminal-compatibility.html#term-compat-query-background-color)，则设置为 `unknown`。与 [status terminal](cmds/status.html#status-terminal) 一样，此变量仅在第一个交互式提示符显示后填充。这在 [--on-variable 事件处理器](#事件处理器)中用于在终端的颜色主题更改时更新[语法高亮](interactive.html#syntax-highlighting)变量。请参阅[此处](cmds/fish_config.html#fish-config-theme-files)了解如何在主题中指定 `light` 和 `dark` 变体。

#### 环境变量 history

包含最后输入的命令的列表。

#### 环境变量 HOME

用户的主目录。此变量可以被更改。

#### 环境变量 hostname

机器的主机名。

#### 环境变量 IFS

用于 [read](cmds/read.html) 内置命令进行单词分割的内部字段分隔符。将其设置为空字符串也会禁用[命令替换](#命令替换)中的行分割。此变量可以被更改。

#### 环境变量 last_pid

最后一个后台进程的进程 ID（PID）。

#### 环境变量 PWD

当前工作目录。

#### 环境变量 pipestatus

构成最后一个执行管道的所有进程的退出状态列表。请参阅[退出状态](#状态变量)。

#### 环境变量 SHLVL

shell 嵌套的层次。Fish 在交互式 shell 中递增此值，否则只传递它。

#### 环境变量 status

最后一个退出的前台作业的[退出状态](#状态变量)。如果作业通过信号终止，退出状态将为 128 加上信号编号。

#### 环境变量 status_generation

`$status` 的"代数"计数。仅当前一个命令产生显式状态时才会递增。（例如，后台作业不会递增此值。）

#### 环境变量 USER

当前用户名。此变量可以被更改。

#### 环境变量 EUID

当前有效用户 ID，由 fish 在启动时设置。此变量可以被更改。

#### 环境变量 version

当前运行的 fish 的版本（为了向后兼容，也可作为 `FISH_VERSION` 使用）。

作为约定，大写名称通常用于导出的变量，而小写变量不导出。（`CMD_DURATION` 是历史原因导致的例外）。此规则不由 fish 强制执行，但使用大小写区分导出和未导出变量是一种良好的编码实践。

Fish 还在内部使用一些变量，其名称通常以 `__fish` 开头。这些是内部变量，通常不应直接修改。

### 状态变量

每当进程退出时，退出状态会返回给启动它的程序（通常是 shell）。此退出状态是一个整数，告诉调用应用程序命令的执行情况。通常，零退出状态意味着命令执行没有问题，但非零退出状态意味着存在某种形式的问题。

Fish 将最后一个退出作业中的最后一个进程的退出状态存储在 `status` 变量中。

如果 fish 在执行命令时遇到问题，status 变量也可能被设置为特定值：

-   **0** 通常是命令成功执行请求操作时的退出状态。
-   **1** 通常是命令未能执行请求操作时的退出状态。
-   **121** 通常是命令被提供无效参数时的退出状态。
-   **123** 意味着命令未执行，因为命令名称包含无效字符。
-   **124** 意味着命令未执行，因为命令中的通配符模式没有产生任何匹配。
-   **125** 意味着虽然找到了具有指定名称的可执行文件，但操作系统无法实际执行该命令。
-   **126** 意味着虽然找到了具有指定名称的文件，但它不可执行。
-   **127** 意味着找不到具有给定名称的函数、内置命令或命令。

如果进程通过信号退出，退出状态将为 128 加上信号编号。

状态可以用 [not](cmds/not.html)（或 `!`）取反，这在[条件](#条件)中很有用。这将状态 0 变为 1，将任何非零状态变为 0。

还有 `$pipestatus`，它是管道中所有进程的所有 `status` 值的列表。一个区别是 [not](cmds/not.html) 适用于 `$status`，但不适用于 `$pipestatus`，因为这会丢失信息。

例如：

```fish
not cat file | grep -q fish
echo status 是：$status pipestatus 是 $pipestatus
```

这里 `$status` 反映 `grep` 的状态，如果找到则返回 0，通过 `not` 取反（因此如果找到则为 1，否则为 0）。`$pipestatus` 反映 `cat`（例如在找不到文件时返回非零）和 `grep` 的状态，没有取反。

因此，如果 `cat` 和 `grep` 都成功，`$status` 将为 1（因为有 `not`），`$pipestatus` 将为 0 和 0。

有可能第一个命令失败而第二个命令成功。一个常见示例是当第二个程序提前退出时。

例如，如果您有这样的管道：

```fish
cat file1 file2 | head -n 50
```

这将告诉 `cat` 逐个打印两个文件，"file1" 和 "file2"，然后 `head` 仅打印前 50 行。在这种情况下，您可能经常看到这种组合：

```fish
> cat file1 file2 | head -n 50
# 50 行输出
> echo $pipestatus
141 0
```

这里，"141" 表示 `cat` 被信号编号 13（128 + 13 == 141）—— 即 `SIGPIPE` 终止。您也可以使用 [`fish_kill_signal`](#环境变量-fish_kill_signal) 查看信号编号。这是因为它仍在工作，然后 `head` 关闭了管道，因此 `cat` 收到了一个它没有忽略的信号，因此死亡了。

`cat` 在这里是否会看到 SIGPIPE 取决于文件多长以及它一次写入多少，因此根据实现，您可能会看到 pipestatus 为 "0 0"。这是一个通用的 Unix 问题，不是 fish 特有的。一些 shell 具有 "pipefail" 功能，如果管道中的一个进程失败，则将整个管道视为失败，这是一个大问题。

### 区域设置变量

程序的"区域设置"是其语言和地区设置的集合。在 UNIX 中，这些由多个类别组成。fish 使用的类别有：

#### 环境变量 LANG

这是指定区域设置的典型环境变量。用户可以设置此变量来表达他们说的语言、所在地区以及字符编码。编码部分被忽略，fish 始终假定 UTF-8。实际值是特定于平台的，除了像 `C` 或 `POSIX` 这样的特殊值。

`LANG` 的值用于每个类别，除非设置了该类别的变量或设置了 `LC_ALL`。因此通常只需要设置 LANG。

示例值：`en_US.UTF-8` 用于美式英语，`de_AT.UTF-8` 用于奥地利德语。您的操作系统可能有一个 `locale` 命令，可以调用 `locale -a` 来查看已定义区域设置的列表。

#### 环境变量 LANGUAGE

这被视为类似于 [`LC_MESSAGES`](#环境变量-LC_MESSAGES)，但它可以包含多个值，允许为翻译指定语言优先级列表。它是一个[路径变量](#路径变量)，类似于 [GNU gettext](https://www.gnu.org/software/gettext/manual/html_node/The-LANGUAGE-variable.html)。

没有指定地区的语言标识符（例如 `zh`）会导致以任意顺序尝试该语言的所有可用变体。在此示例中，我们可能首先在 `zh_CN` 目录中查找消息，然后查找 `zh_TW`，或反过来。这与 GNU gettext 不同，后者改用该语言的"默认"变体。如果您偏好某个变体，请在列表中更早指定它，例如如果您偏好的语言是 `zh_TW`，并且您偏好任何其他 `zh` 变体而非英语默认值，则指定 `zh_TW:zh`。如果 `zh_TW` 是您想要的唯一 `zh` 变体，在 `LANGUAGE` 变量中指定 `zh_TW` 将导致 `zh_TW` 中不可用的消息以英语显示。

另请参阅 [内置 _ (下划线)](cmds/_.html)。

#### 环境变量 LC_ALL

覆盖 [`LANG`](#环境变量-LANG) 和所有其他 `LC_*` 变量。请仅将 `LC_ALL` 用作临时覆盖。

#### 环境变量 LC_MESSAGES

确定显示消息的语言，请参阅[内置 _ (下划线)](cmds/_.html)。

#### 环境变量 LC_NUMERIC

设置[格式化数字](cmds/printf.html)的区域设置。

#### 环境变量 LC_TIME

确定日期和时间的显示方式。在 [history](cmds/history.html#history-show-time) 内置命令中使用。

## 内置命令

Fish 在 shell 中直接包含许多命令。我们称这些为"内置命令"。这些包括：

-   操纵 shell 状态的内置命令 —— [cd](cmds/cd.html) 更改目录，[set](cmds/set.html) 设置变量
-   处理数据的内置命令，如 [string](cmds/string.html) 处理字符串，[math](cmds/math.html) 处理数字，[count](cmds/count.html) 计数行或参数，[path](cmds/path.html) 处理路径
-   [status](cmds/status.html) 用于询问 shell 的状态
-   [printf](cmds/printf.html) 和 [echo](cmds/echo.html) 用于创建输出
-   [test](cmds/test.html) 用于检查条件
-   [argparse](cmds/argparse.html) 用于解析函数参数
-   [source](cmds/source.html) 在当前 shell 中读取脚本（因此变量更改会保留），[eval](cmds/eval.html) 将字符串作为脚本执行
-   [random](cmds/random.html) 获取随机数或从列表中随机选择元素
-   [read](cmds/read.html) 用于从管道或终端读取

要列出所有内置命令，请使用 `builtin -n`。

要获取 fish 附带的所有内置命令、函数和命令的列表，请参阅[命令列表](commands.html)。也可以使用 `--help` 开关获取文档。

## 命令查找

当 fish 被告知运行某些内容时，它会经过多个步骤来查找它。

如果包含 `/`，fish 尝试从当前目录开始执行给定的文件。

如果不包含 `/`，它可能是函数、内置命令或外部命令，因此 fish 会进行完整的查找。

按顺序：

1.  尝试将其解析为[函数](#函数)。
    -   如果函数已知，则使用它
    -   如果在 [`fish_function_path`](#环境变量-fish_function_path) 中存在以 ".fish" 为后缀的同名文件，则[加载它](#自动加载函数)。（如果有多于一个文件，只使用第一个）
    -   如果现在函数已定义，则使用它
2.  尝试将其解析为[内置命令](#内置命令)。
3.  尝试在 [`PATH`](#环境变量-PATH) 中查找可执行文件。
    -   如果找到文件，告诉内核运行它。
    -   如果内核知道如何运行该文件（例如通过 `#!` 行 —— `#!/bin/sh` 或 `#!/usr/bin/python`），它就这么做。
    -   如果内核报告由于缺少解释器而无法运行它，且文件通过基本检查，fish 告诉 `/bin/sh` 运行它。

如果以上都失败，fish 运行函数 [fish_command_not_found](cmds/fish_command_not_found.html) 并将 [`status`](#环境变量-status) 设置为 127。

您可以使用 [type](cmds/type.html) 查看 fish 如何解析某些内容：

```fish
> type --short --all echo
echo is a builtin
echo is /usr/bin/echo
```

## 查询用户输入

有时，您想询问用户输入，例如确认某事。这可以使用 [read](cmds/read.html) 内置命令完成。

让我们构造一个示例。此函数将对它作为[参数](#参数处理)获取的所有目录中的文件进行[通配符](#通配符)匹配，如果文件[超过五个](cmds/test.html)，它将询问用户是否应显示它们，但仅当它连接到终端时才如此：

```fish
function show_files
    # 这将对所有参数进行通配符匹配。任何非目录都将被忽略。
    set -l files $argv/*

    # 如果有超过 5 个文件
    if test (count $files) -gt 5
        # 且 stdin（用于读取输入）
        # 和 stdout（用于写入提示符）
        # 都是终端
        and isatty stdin
        and isatty stdout
        # 一直询问直到获得有效响应
        while read --nchars 1 -l response --prompt-str="您确定吗？(y/n)"
              or return 1 # 如果读取被 ctrl-c/ctrl-d 中止
            switch $response
                case y Y
                    echo 好的
                    # 我们跳出 while 循环并继续函数
                    break
                case n N
                    # 我们从函数返回而不打印
                    echo 不显示
                    return 1
                case '*'
                    # 我们继续 while 循环并再次询问
                    echo 无效输入
                    continue
            end
        end
    end

    # 现在打印文件
    printf '%s\n' $files
end
```

如果以 `show_files /` 运行，它很可能会一直询问直到您按 Y/y 或 N/n。如果以 `show_files / | cat` 运行，它将在不询问的情况下打印文件。如果以 `show_files .` 运行，它可能在不询问的情况下打印某些内容，因为文件少于五个。

## Shell 变量和函数名称

给变量和函数指定的名称（所谓的"标识符"）必须遵循某些规则：

-   变量名不能为空。只能包含字母、数字和下划线。它可以以这些字符中的任何一个开头和结尾。
-   函数名不能为空。不能以连字符（"-"）开头，也不能包含斜杠（"/"）。所有其他字符，包括空格，都是有效的。函数名也不能与保留关键字或基本内置命令（如 `if` 或 `set`）相同。
-   绑定模式名（例如 `bind -m abc ...`）必须是有效的变量名。

其他事物有其他限制。例如文件名的允许内容取决于您的系统，但至少不能包含 "/"（因为那是路径分隔符）或 NULL 字节（因为那是 UNIX 结束字符串的方式）。

## 配置文件

当 fish 启动时，它读取并运行其配置文件。这些文件的位置取决于构建配置和环境变量。

主文件是 `~/.config/fish/config.fish`（或更确切地说 `$XDG_CONFIG_HOME/fish/config.fish`）。

配置文件按以下顺序运行：

-   **配置片段**（名为 `*.fish` 的文件）位于以下目录中：
    -   `$__fish_config_dir/conf.d`（默认情况下为 `~/.config/fish/conf.d/`）
    -   `$__fish_sysconf_dir/conf.d`（默认情况下为 `/etc/fish/conf.d/`）
    -   供其他软件放置其配置片段的目录：
        -   `$__fish_user_data_dir` 下的目录（通常为 `~/.local/share/fish`，由 `XDG_DATA_HOME` 环境变量控制）
        -   `$XDG_DATA_DIRS` 中列出的目录中的 `fish/vendor_conf.d` 目录（默认为 `/usr/share/fish/vendor_conf.d` 和 `/usr/local/share/fish/vendor_conf.d`）
        
        这些目录在 `$__fish_vendor_confdirs` 中也可访问。请注意，在运行中的 fish 中更改它不会有任何效果，因为到那时这些目录已经被读取了。
    
    如果这些目录中有多个同名文件，只有第一个会被执行。它们按文件名顺序执行，以自然顺序排序（即 "01" 排在 "2" 之前）。

-   **系统级配置文件**，管理员可以为系统上所有用户包含初始化设置 —— 类似于 POSIX 风格 shell 的 `/etc/profile` —— 位于 `$__fish_sysconf_dir`（通常为 `/etc/fish/config.fish`）。

-   **用户配置**，通常位于 `~/.config/fish/config.fish`（由 `XDG_CONFIG_HOME` 环境变量控制，可作为 `$__fish_config_dir` 访问）。

`~/.config/fish/config.fish` 在配置片段*之后*被加载。这样您可以复制片段并覆盖其中某些行为。

这些文件都在每个 shell 启动时执行。如果只想在启动交互式 shell 时运行命令，请使用命令 `status --is-interactive` 的退出状态来确定 shell 是否是交互式的。如果只想在使用登录 shell 时运行命令，请改用 `status --is-login`。这将加快非交互式或非登录 shell 的启动。

如果您正在开发另一个程序，可能希望为系统上所有 fish 用户添加配置。这不受鼓励；如果不小心编写，可能会产生副作用或减慢 shell 的启动。此外，其他 shell 的用户不会从 fish 特定的配置中受益。然而，如果确实需要，您可以将它们安装到 "vendor" 配置目录中。由于此路径可能因系统而异，应使用 `pkg-config` 来发现它：`pkg-config --variable confdir fish`。

对于系统集成，fish 还附带一个名为 `__fish_build_paths.fish` 的文件。这可以在构建时自定义，例如因为您的系统需要使用特殊路径。

## 未来特性标志

特性标志是 fish 如何对可能破坏脚本的更改进行分阶段处理的方式。破坏性更改作为可选引入，在几个版本后变为默认启用，最终旧行为被移除。

您可以通过 `status features` 查看当前特性列表：

```fish
> status features
stderr-nocaret          on  3.0 ^ 不再重定向 stderr
qmark-noglob            on  3.0 ? 不再进行通配符匹配
regex-easyesc           on  3.1 string replace -r 需要更少的 \\'
ampersand-nobg-in-token on  3.4 & 仅在后跟分隔字符时执行后台操作
remove-percent-self     off 4.0 %self 不再扩展（请使用 $fish_pid）
test-require-arg        off 4.0 内置 test 需要一个参数
mark-prompt             on  4.0 将 OSC 133 提示标记写入终端
ignore-terminfo         on  4.1 不在 terminfo 数据库中查找 $TERM
query-term              on  4.1 查询 TTY 以启用额外功能
omit-term-workarounds   off 4.3 跳过对不兼容终端的变通方案
```

以下是它们的含义：

-   **`stderr-nocaret`** 在 fish 3.0 中引入，自 fish 3.5 起无法关闭。它仍可用于兼容性测试，但 `no-stderr-nocaret` 值将被忽略。该标志使 `^` 成为普通字符，而不是表示 stderr 重定向。请改用 `2>`。
-   **`qmark-noglob`** 也在 fish 3.0 中引入（并在 4.0 中成为默认）。它使 `?` 成为普通字符，而不是单字符通配符。请改用 `*`（将匹配多个字符）或寻找其他匹配文件的方法，如 `find`。
-   **`regex-easyesc`** 在 3.1 中引入（并在 3.5 中成为默认）。它使 `string replace -r` 中的替换表达式少做一轮转义。之前，要转义反斜杠，您需要使用 `string replace -ra '([ab])' '\\\\\\\\$1'`。之后，只需 `'\\\\$1'` 就足够了。如果您在任何地方使用了此功能，请检查您的 `string replace` 调用。
-   **`ampersand-nobg-in-token`** 在 fish 3.4 中引入（并在 3.5 中成为默认）。它使 `&` 在标记中间不再被解释为后台操作符，因此处理 URL 变得更加容易。可以在 `&` 之后放置空格或分号。这本来就是推荐的格式，`fish_indent` 会帮您完成。
-   **`remove-percent-self`** 关闭特殊的 `%self` 扩展。它在 4.0 中引入。要获取 fish 的 pid，可以使用 [`fish_pid`](#环境变量-fish_pid) 变量。
-   **`test-require-arg`** 移除[内置 test](cmds/test.html) 的单参数形式（`test "string"`）。它在 4.0 中引入。要测试字符串是否非空，请使用 `test -n "string"`。如果禁用，任何会导致更改的 `test` 调用会发送类别为 "deprecated-test" 的[调试消息](cmds/fish.html#debugging-fish)，因此以 `fish --debug=deprecated-test` 启动 fish 可用于查找有问题的调用。
-   **`mark-prompt`** 使 fish 向终端报告 shell 提示符和命令输出的开始和结束。
-   **`ignore-terminfo`** 在 fish 4.1 中引入，自 fish 4.5 起无法关闭。它仍可用于兼容性测试，但 `no-ignore-terminfo` 值将被忽略。该标志禁用了在 terminfo 数据库中查找 $TERM。
-   **`query-term`** 允许 fish 通过写入转义序列并读取终端的响应来查询终端。这启用了诸如[滚动](terminal-compatibility.html#term-compat-cursor-position-report)等功能。如果使用不兼容的终端，您可以 —— 暂时的 —— 通过运行（一次）`set -Ua fish_features no-query-term` 来解决。
-   **`omit-term-workarounds`** 防止 fish 尝试去变通解决不兼容终端的问题。

这些更改默认关闭。它们可以按会话启用：

```fish
> fish --features qmark-noglob,regex-easyesc
```

或为用户全局选择加入：

```fish
> set -U fish_features regex-easyesc qmark-noglob
```

特性仅在启动时设置，因此此变量仅在它是通用或导出时才生效。

您也可以使用版本作为组，因此 `3.0` 等价于 "stderr-nocaret" 和 "qmark-noglob"。特殊组 `all` 启用所有特性，而不是指定版本。

在前加 `no-` 前缀可以关闭某个特性。例如，要重新启用 `?` 单字符通配符：

```fish
set -Ua fish_features no-qmark-noglob
```

## 事件处理器

在 fish 中定义新函数时，可以将其设为事件处理器，即在特定事件发生时自动运行的函数。目前可以触发处理器的事件有：

-   当信号被传递时
-   当作业退出时
-   当变量的值被更新时
-   当提示符即将显示时

示例：

要为 WINCH 信号指定信号处理器，请写入：

```fish
function my_signal_handler --on-signal WINCH
    echo 收到 WINCH 信号！
end
```

Fish 已经为 `--on-event` 开关定义了以下命名事件：

-   **`fish_prompt`** 在每次新的 fish 提示符即将显示时发出。
-   **`fish_preexec`** 在执行交互式命令之前发出。命令行作为第一个参数传递。如果命令为空则不会发出。
-   **`fish_posterror`** 在执行有语法错误的命令之后发出。命令行作为第一个参数传递。
-   **`fish_postexec`** 在执行交互式命令之后发出。命令行作为第一个参数传递。如果命令为空则不会发出。
-   **`fish_exit`** 在 fish 退出之前发出。
-   **`fish_cancel`** 当命令行被清除时发出。
-   **`fish_focus_in`** 当 fish 的终端获得焦点时发出。
-   **`fish_focus_out`** 当 fish 的终端失去焦点时发出。

事件可以使用 [emit](cmds/emit.html) 命令触发，而不需要提前定义。名称只需匹配即可。例如：

```fish
function handler --on-event imdone
    echo 生成器已完成 $argv
end

function generator
    sleep 1
    # "imdone" 是事件的名称
    # 其余是传递给处理器的参数
    emit imdone with $argv
end
```

如果事件有多个处理器，它们将全部运行，但顺序可能在 fish 版本之间更改，因此不应依赖它。

请注意，事件处理器仅在函数被加载时才变为活动状态，这意味着您需要以其他方式 [source](cmds/source.html) 或执行函数，而不是依赖[自动加载](#自动加载函数)。一种方法是将其放入您的[配置文件](#配置文件)中。

有关如何定义新事件处理器的更多信息，请参阅 [function](cmds/function.html) 命令的文档。

## 调试 fish 脚本

Fish 包含基本的内置调试设施，允许您在任意点停止脚本的执行。当发生这种情况时，您会看到一个交互式提示符，可以在其中执行任何 fish 命令来检查或更改状态（不存在专门的调试命令）。例如，您可以使用 [printf](cmds/printf.html) 和 [set](cmds/set.html) 检查或更改任何变量的值。另一个例子是，您可以运行 [status print-stack-trace](cmds/status.html) 来查看当前断点是如何到达的。要恢复正常脚本执行，请键入 [exit](cmds/exit.html) 或 ctrl-d。

要启动调试会话，在函数或脚本中您希望获得控制权的地方插入[内置命令](cmds/breakpoint.html) `breakpoint`，然后运行该函数或脚本。此外，`TRAP` 信号的默认操作是调用此内置命令，这意味着可以通过向其发送 `TRAP` 信号（`kill -s TRAP <PID>`）来主动调试正在运行的脚本。从此调试提示符交互式设置或修改断点的支持有限：可以使用 `funced` 函数编辑函数的定义，在其他函数中插入新断点（或从中删除旧断点），但无法在当前加载并正在执行的函数/脚本中添加或删除断点。

调试脚本问题的另一种方法是设置 [`fish_trace`](#环境变量-fish_trace) 变量，例如 `fish_trace=1 fish_prompt` 来查看 fish 在运行 [fish_prompt](cmds/fish_prompt.html) 函数时执行了哪些命令。

### 性能分析 fish 脚本

如果您特别想调试性能问题，**fish** 可以使用 `--profile /path/to/profile.log` 选项运行，将性能分析保存到指定路径。此性能分析日志包括执行中每个步骤所花费时间的分解。

例如：

```fish
> fish --profile /tmp/sleep.prof -ic 'sleep 3s'
> cat /tmp/sleep.prof
Time    Sum     Command
3003419 3003419 > sleep 3s
```

这将在第一列中显示每个命令本身的时间，第二列显示命令及其所有子命令（如[函数](#函数)内的命令或[命令替换](#命令替换)中的命令）的累计时间，第三列显示命令本身，用制表符分隔。

时间以微秒为单位给出。

要最后查看最慢的命令，`sort -nk2 /path/to/logfile` 很有用。

对于性能分析 fish 的启动，还有 `--profile-startup /path/to/logfile`。

有关更多信息，请参阅 [fish](cmds/fish.html)。

---

> 本文档翻译自 [fish-shell 官方语言教程](https://fishshell.com/docs/current/language.html)（fish-shell 4.7.1）。
> 版权所有 &copy; fish-shell 开发者。
