---
date: 2026-04-23
tags:
  - yazi
  - linux
  - file
---


# Quick Start

> Source: https://yazi-rs.github.io/docs/quick-start  
> Version: 26.1.22  
> Description: A quick guide on the basic usage of Yazi.

Once you've [installed Yazi](/docs/installation), start the program with:

```sh
yazi
```

Press <kbd>q</kbd> to quit, <kbd>F1</kbd> or <kbd>~</kbd> to open the help menu.

## Shell wrapper

We suggest using this `y` shell wrapper that provides the ability to change the current working directory when exiting Yazi.

### Bash / Zsh

```bash
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}
```

### Fish

```sh
function y
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	command yazi $argv --cwd-file="$tmp"
	if read -z cwd < "$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
		builtin cd -- "$cwd"
	end
	rm -f -- "$tmp"
end
```

### Nushell

```sh
def --env y [...args] {
	let tmp = (mktemp -t "yazi-cwd.XXXXXX")
	^yazi ...$args --cwd-file $tmp
	let cwd = (open $tmp)
	if $cwd != $env.PWD and ($cwd | path exists) {
		cd $cwd
	}
	rm -fp $tmp
}
```

### POSIX

```sh
y() {
	set -- "$@" --cwd-file "$(mktemp -t yazi-cwd.XXXXXX)"
	command yazi "$@"
	shift $(($# - 1))
	set -- "$(command cat < "$1"; printf .; rm -f -- "$1")"
	set -- "${1%.}"
	[ "$1" != "$PWD" ] && [ -d "$1" ] && command cd -- "$1"
}
```

### Elvish

```elvish
edit:add-var y~ {|@argv|
	use str
	use os
	use file
	var tmp = (os:temp-file)
	e:yazi $@argv --cwd-file=$tmp[name]
	var cwd = (slurp < $tmp)
	file:close $tmp
	os:remove $tmp[name]
 	if (and (not-eq $cwd $pwd) (os:is-dir $cwd)) {
 		cd $cwd
 	}
}
```

### PowerShell

```powershell
function y {
	$tmp = (New-TemporaryFile).FullName
	yazi.exe $args --cwd-file="$tmp"
	$cwd = Get-Content -Path $tmp -Encoding UTF8
	if ($cwd -and $cwd -ne $PWD.Path -and (Test-Path -LiteralPath $cwd -PathType Container)) {
		Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
	}
	Remove-Item -Path $tmp
}
```

### Command Prompt

Create the file `y.cmd` and place it in your `%PATH%`.

```cmd
@echo off

set tmpfile=%TEMP%\yazi-cwd.%random%

yazi.exe %* --cwd-file="%tmpfile%"

:: If the file does not exist, then exit
if not exist "%tmpfile%" exit /b 0

:: If the file exist, then read the content and change the directory
set /p cwd=<"%tmpfile%"
if not "%cwd%"=="" if exist "%cwd%\" (
	cd /d "%cwd%"
)
del "%tmpfile%"
```

### Xonsh

```xonsh
def _y(args):
	tmp = $(mktemp -t "yazi-cwd.XXXXXX")
	args.append(f"--cwd-file={tmp}")
	$[!yazi @(args)]
	with open(tmp) as f:
		cwd = f.read()
	import os
	if cwd != $PWD and os.path.isdir(cwd):
		cd @(cwd)
	rm -f -- @(tmp)

aliases["y"] = _y
```

To use it, copy the function into the configuration file of your respective shell.

Then use `y` instead of `yazi` to start, and press <kbd>q</kbd> to quit, you'll see the CWD changed. Sometimes, you don't want to change, press <kbd>Q</kbd> to quit.

## Keybindings

> Tip: For all keybindings, see the [default `keymap.toml` file](https://github.com/sxyazi/yazi/blob/shipped/yazi-config/preset/keymap-default.toml).

### Navigation

To navigate between files and directories you can use the arrow keys <kbd>←</kbd>, <kbd>↓</kbd>, <kbd>↑</kbd> and <kbd>→</kbd> or Vim-like keys such as <kbd>h</kbd>, <kbd>j</kbd>, <kbd>k</kbd>, <kbd>l</kbd>:

| Key binding  | Alternate key | Action (中文) |
| ------------ | ------------- | ------------- |
| <kbd>k</kbd> | <kbd>↑</kbd>  | 光标上移 |
| <kbd>j</kbd> | <kbd>↓</kbd>  | 光标下移 |
| <kbd>l</kbd> | <kbd>→</kbd>  | 进入当前悬停目录 |
| <kbd>h</kbd> | <kbd>←</kbd>  | 离开当前目录并进入父目录 |

Further navigation commands can be found in the table below.

| Key binding                     | Action (中文) |
| ------------------------------- | ------------- |
| <kbd>K</kbd>                    | 在预览中向上跳 5 个单位 |
| <kbd>J</kbd>                    | 在预览中向下跳 5 个单位 |
| <kbd>g</kbd> ⇒ <kbd>g</kbd>     | 将光标移动到顶部 |
| <kbd>G</kbd>                    | 将光标移动到底部 |
| <kbd>z</kbd>                    | 通过 fzf 切换目录（[Cd][mgr.cd]）或定位并显示文件（[reveal][mgr.reveal]） |
| <kbd>Z</kbd>                    | 通过 zoxide 切换目录（[Cd][mgr.cd]） |
| <kbd>g</kbd> ⇒ <kbd>Space</kbd> | 通过交互提示切换目录（[Cd][mgr.cd]）或定位并显示文件（[reveal][mgr.reveal]） |

[mgr.cd]: /docs/configuration/keymap#mgr.cd
[mgr.reveal]: /docs/configuration/keymap#mgr.reveal

### Selection

To select files and directories, the following commands are available.

| Key binding                    | Action (中文)    |
| ------------------------------ | -------------- |
| <kbd>Space</kbd>               | 切换悬停文件/目录的选中状态 |
| <kbd>v</kbd>                   | 进入可视模式（选择模式）   |
| <kbd>V</kbd>                   | 进入可视模式（取消模式）   |
| <kbd>Ctrl</kbd> + <kbd>a</kbd> | 全选文件           |
| <kbd>Ctrl</kbd> + <kbd>r</kbd> | 反选所有文件         |
| <kbd>Esc</kbd>                 | 取消选择           |

### File operations

To interact with selected files/directories use any of the commands below.

| Key binding                         | Action (中文) |
| ----------------------------------- | ------------- |
| <kbd>o</kbd>                        | 打开选中文件 |
| <kbd>O</kbd>                        | 交互式打开选中文件 |
| <kbd>Enter</kbd>                    | 打开选中文件 |
| <kbd>Shift</kbd> + <kbd>Enter</kbd> | 交互式打开选中文件（部分终端暂不支持） |
| <kbd>Tab</kbd>                      | 显示文件信息 |
| <kbd>y</kbd>                        | 复制（yank）选中文件 |
| <kbd>x</kbd>                        | 剪切（yank）选中文件 |
| <kbd>p</kbd>                        | 粘贴已 yank 的文件 |
| <kbd>P</kbd>                        | 粘贴已 yank 的文件（目标已存在时覆盖） |
| <kbd>Y</kbd> or <kbd>X</kbd>        | 取消 yank 状态 |
| <kbd>d</kbd>                        | 将选中文件移入回收站 |
| <kbd>D</kbd>                        | 永久删除选中文件 |
| <kbd>a</kbd>                        | 创建文件（以 / 结尾可创建目录） |
| <kbd>r</kbd>                        | 重命名选中的文件 |
| <kbd>.</kbd>                        | 切换隐藏文件可见性 |

Further file operation commands can be found in the table below.

| Key binding                    | Action (中文) |
| ------------------------------ | ------------- |
| <kbd>;</kbd>                   | 运行 shell 命令 |
| <kbd>:</kbd>                   | 运行 shell 命令（阻塞直到完成） |
| <kbd>-</kbd>                   | 为已 yank 文件创建绝对路径符号链接 |
| <kbd>\_</kbd>                  | 为已 yank 文件创建相对路径符号链接 |
| <kbd>Ctrl</kbd> + <kbd>-</kbd> | 为已 yank 文件创建硬链接 |

### Copy paths

To copy paths, use any of the following commands below.

_Observation: <kbd>c</kbd> ⇒ <kbd>d</kbd> indicates pressing the <kbd>c</kbd> key followed by pressing the <kbd>d</kbd> key._

| Key binding                 | Action (中文) |
| --------------------------- | ------------- |
| <kbd>c</kbd> ⇒ <kbd>c</kbd> | 复制文件路径 |
| <kbd>c</kbd> ⇒ <kbd>d</kbd> | 复制目录路径 |
| <kbd>c</kbd> ⇒ <kbd>f</kbd> | 复制文件名 |
| <kbd>c</kbd> ⇒ <kbd>n</kbd> | 复制不含扩展名的文件名 |

### Filter files

| Key binding  | Action (中文) |
| ------------ | ------------- |
| <kbd>f</kbd> | 过滤文件 |

### Find files

| Key binding  | Action (中文) |
| ------------ | ------------- |
| <kbd>/</kbd> | 查找下一个文件 |
| <kbd>?</kbd> | 查找上一个文件 |
| <kbd>n</kbd> | 跳转到下一个匹配项 |
| <kbd>N</kbd> | 跳转到上一个匹配项 |

### Search files

| Key binding                    | Action (中文) |
| ------------------------------ | ------------- |
| <kbd>s</kbd>                   | 使用 [fd](https://github.com/sharkdp/fd) 按文件名搜索文件 |
| <kbd>S</kbd>                   | 使用 [ripgrep](https://github.com/BurntSushi/ripgrep) 按文件内容搜索文件 |
| <kbd>Ctrl</kbd> + <kbd>s</kbd> | 取消正在进行的搜索 |

### Sorting

To sort files/directories use the following commands.

_Observation: <kbd>,</kbd> ⇒ <kbd>a</kbd> indicates pressing the <kbd>,</kbd> key followed by pressing the <kbd>a</kbd> key._

| Key binding                 | Action (中文) |
| --------------------------- | ------------- |
| <kbd>,</kbd> ⇒ <kbd>m</kbd> | 按修改时间排序 |
| <kbd>,</kbd> ⇒ <kbd>M</kbd> | 按修改时间排序（倒序） |
| <kbd>,</kbd> ⇒ <kbd>b</kbd> | 按创建时间排序 |
| <kbd>,</kbd> ⇒ <kbd>B</kbd> | 按创建时间排序（倒序） |
| <kbd>,</kbd> ⇒ <kbd>e</kbd> | 按文件扩展名排序 |
| <kbd>,</kbd> ⇒ <kbd>E</kbd> | 按文件扩展名排序（倒序） |
| <kbd>,</kbd> ⇒ <kbd>a</kbd> | 按字母顺序排序 |
| <kbd>,</kbd> ⇒ <kbd>A</kbd> | 按字母顺序排序（倒序） |
| <kbd>,</kbd> ⇒ <kbd>n</kbd> | 按自然顺序排序 |
| <kbd>,</kbd> ⇒ <kbd>N</kbd> | 按自然顺序排序（倒序） |
| <kbd>,</kbd> ⇒ <kbd>s</kbd> | 按大小排序 |
| <kbd>,</kbd> ⇒ <kbd>S</kbd> | 按大小排序（倒序） |
| <kbd>,</kbd> ⇒ <kbd>r</kbd> | 随机排序 |

### Multi-tab

| Key binding                                   | Action (中文) |
| --------------------------------------------- | ------------- |
| <kbd>t</kbd>                                  | 以当前工作目录（CWD）新建标签页 |
| <kbd>1</kbd>, <kbd>2</kbd>, ..., <kbd>9</kbd> | 切换到第 N 个标签页 |
| <kbd>[</kbd>                                  | 切换到上一个标签页 |
| <kbd>]</kbd>                                  | 切换到下一个标签页 |
| <kbd>\{</kbd>                                 | 将当前标签页与前一个标签页交换 |
| <kbd>}</kbd>                                  | 将当前标签页与后一个标签页交换 |
| <kbd>Ctrl</kbd> + <kbd>c</kbd>                | 关闭当前标签页 |

## Flavors

Pick a color scheme you like from our [flavors repository](https://github.com/yazi-rs/flavors), or [cook a flavor](/docs/flavors/overview#cooking)!
