---
date: 2026-04-15
tags:
  - obsidian
---

# Obsidian CLI 命令行接口笔记

> 来源：https://obsidian.md/help/cli
> 抓取时间：2026-04-15

## 概述

Obsidian CLI 是一个命令行接口，让你可以通过终端控制 Obsidian，支持脚本编写、自动化和外部工具集成。

**要求**：Obsidian 1.12.7 或更高版本（安装版本，非 portable 版本）

---

## 安装步骤

1. 升级到 Obsidian 1.12.7 或更高版本
2. 在 Obsidian 中启用 CLI：
   - **Settings** → **General**
   - 启用 **Command line interface**
   - 按提示注册 Obsidian CLI

> [!warning]
> Obsidian 应用必须处于运行状态，CLI 才能工作。
> 如果 Obsidian 未运行，第一个命令会自动启动它。

---

## 使用方式

### 方式一：单命令模式

```bash
# 直接运行命令
obsidian help
obsidian daily
obsidian vault
```

### 方式二：交互式终端界面 (TUI)

```bash
obsidian
# 进入 TUI 后输入命令
help
daily
```

TUI 支持：
- 自动补全
- 命令历史
- 反向搜索 (`Ctrl+R`)

---

## 快速示例

### 日常使用

```bash
# 打开今日日记
obsidian daily

# 添加任务到日记
obsidian daily:append content="- [ ] Buy groceries"

# 搜索 vault
obsidian search query="meeting notes"

# 读取当前文件
obsidian read

# 列出日记中的所有任务
obsidian tasks daily

# 从模板创建新笔记
obsidian create name="Trip to Paris" template=Travel

# 列出 vault 中所有标签及计数
obsidian tags counts

# 比较文件两个版本
obsidian diff file=README from=1 to=3
```

### 开发者使用

```bash
# 打开开发者工具
obsidian devtools

# 重载正在开发的社区插件
obsidian plugin:reload id=my-plugin

# 截取应用截图
obsidian dev:screenshot path=screenshot.png

# 在应用控制台运行 JavaScript
obsidian eval code="app.vault.getFiles().length"
```

---

## 命令参数格式

### 参数 (Parameters)
```bash
# 基本格式
obsidian create name=Note content="Hello world"

# 带空格的值用引号包裹
obsidian create name=Note content="Hello world"

# 多行内容使用 \n 换行，\t 制表符
obsidian create name=Note content="# Title\n\nBody text"
```

### 标志 (Flags)
```bash
# 标志是布尔开关，包含即启用
obsidian create name=Note content="Hello" open overwrite
```

### 定位 Vault
```bash
# 指定 vault（必须在命令最前面）
obsidian vault=Notes daily
obsidian vault="My Vault" search query="test"
```

### 定位文件
```bash
# file=<name> - 按文件名解析（不需要完整路径或扩展名）
obsidian read file=Recipe

# path=<path> - 需要从 vault 根目录的完整路径
obsidian read path="Templates/Recipe.md"
```

### 复制输出
```bash
# 添加 --copy 将输出复制到剪贴板
obsidian read --copy
obsidian search query="TODO" --copy
```

---

## 命令速查表

### 通用命令

| 命令 | 作用 |
|------|------|
| `help <command>` | 显示帮助，可指定命令 |
| `version` | 显示 Obsidian 版本 |
| `reload` | 重载应用窗口 |
| `restart` | 重启应用 |

---

### 文件和文件夹

| 命令 | 作用 | 常用参数 |
|------|------|---------|
| `file` | 显示文件信息 | `file=<name>`, `path=<path>` |
| `files` | 列出所有文件 | `folder=<path>`, `ext=<extension>`, `total` |
| `folder` | 显示文件夹信息 | `path=<path>` (必填), `info=files\|folders\|size` |
| `folders` | 列出文件夹 | `folder=<path>`, `total` |
| `open` | 打开文件 | `file=<name>`, `path=<path>`, `newtab` |
| `create` | 创建/覆盖文件 | `name=<name>`, `path=<path>`, `content=<text>`, `template=<name>`, `overwrite`, `open`, `newtab` |
| `read` | 读取文件内容 | `file=<name>`, `path=<path>` |
| `append` | 追加内容到文件 | `file=<name>`, `path=<path>`, `content=<text>`, `inline` |
| `prepend` | 前置内容到文件 | `file=<name>`, `path=<path>`, `content=<text>`, `inline` |
| `move` | 移动/重命名文件 | `file=<name>`, `path=<path>`, `to=<path>` |
| `rename` | 重命名文件 | `file=<name>`, `path=<path>`, `name=<name>` |
| `delete` | 删除文件 | `file=<name>`, `path=<path>`, `permanent` |

---

### 日记 (Daily Notes)

| 命令 | 作用 |
|------|------|
| `daily` | 打开今日日记 |
| `daily:path` | 获取日记路径 |
| `daily:read` | 读取今日日记 |
| `daily:append` | 追加到今日日记 |
| `daily:prepend` | 前置到今日日记 |

```bash
# 参数
content=<text>      # 内容
paneType=tab|split|window  # 打开位置
inline              # 不换行追加
open                # 追加后打开
```

---

### 搜索

| 命令 | 作用 |
|------|------|
| `search` | 搜索文本，返回匹配文件路径 |
| `search:context` | 搜索并显示匹配行上下文 |
| `search:open` | 打开搜索视图 |

```bash
query=<text>        # 搜索查询 (必需)
path=<folder>       # 限制文件夹
limit=<n>           # 最大文件数
case                # 区分大小写
format=text|json    # 输出格式
```

---

### 标签 (Tags)

| 命令 | 作用 |
|------|------|
| `tags` | 列出 vault 中所有标签 |
| `tag` | 获取标签详情 |

```bash
# tags 参数
sort=count          # 按计数排序
total               # 返回标签数量
counts              # 包含计数
format=json|tsv|csv # 输出格式
file=<name>         # 指定文件
path=<path>         # 指定路径
active              # 当前文件的标签

# tag 参数
name=<tag>          # 标签名 (必需)
verbose             # 包含文件列表
```

---

### 任务 (Tasks)

| 命令 | 作用 |
|------|------|
| `tasks` | 列出 vault 中的任务 |
| `task` | 显示/更新任务 |

```bash
# tasks 参数
file=<name>         # 按文件过滤
path=<path>         # 按路径过滤
status="<char>"     # 按状态字符过滤
todo                # 只显示未完成任务
done                # 显示已完成任务
daily               # 从日记显示任务
verbose             # 按文件分组显示行号
format=json|tsv|csv # 输出格式

# task 参数
ref=<path:line>     # 任务引用
toggle              # 切换完成状态
done                # 标记完成
todo                # 标记为待办
```

---

### 链接 (Links)

| 命令 | 作用 |
|------|------|
| `backlinks` | 列出反向链接 |
| `links` | 列出正向链接 |
| `unresolved` | 列出未解析链接 |
| `orphans` | 列出孤立笔记（无反向链接） |
| `deadends` | 列出死胡同笔记（无正向链接） |
| `outline` | 显示当前文件大纲 |

```bash
# backlinks 参数
total               # 返回数量
counts              # 包含计数
format=json|tsv|csv # 输出格式

# outline 参数
format=tree|md|json # 输出格式
total               # 返回标题数量
```

---

### 插件管理

| 命令 | 作用 |
|------|------|
| `plugins` | 列出已安装插件 |
| `plugins:enabled` | 列出已启用插件 |
| `plugin` | 获取插件信息 |
| `plugin:enable` | 启用插件 |
| `plugin:disable` | 禁用插件 |
| `plugin:install` | 安装社区插件 |
| `plugin:uninstall` | 卸载插件 |
| `plugin:reload` | 重载插件 |

```bash
id=<id>             # 插件 ID (必需)
filter=core|community  # 插件类型
enable              # 安装后启用
versions            # 显示版本号
```

---

### 主题和代码片段

| 命令 | 作用 |
|------|------|
| `themes` | 列出已安装主题 |
| `theme` | 显示当前主题或获取详情 |
| `theme:set` | 设置主题 |
| `theme:install` | 安装社区主题 |
| `theme:uninstall` | 卸载主题 |
| `snippets` | 列出 CSS 片段 |
| `snippets:enabled` | 列出已启用的片段 |
| `snippet:enable` | 启用片段 |
| `snippet:disable` | 禁用片段 |

---

### 发布 (Publish)

| 命令 | 作用 |
|------|------|
| `publish:site` | 显示发布站点信息 |
| `publish:list` | 列出已发布文件 |
| `publish:status` | 查看发布状态 |
| `publish:add` | 添加到发布 |
| `publish:remove` | 取消发布 |
| `publish:open` | 在浏览器打开发布页面 |

```bash
# publish:status 参数
new                 # 只显示新文件
changed             # 只显示更改文件
deleted             # 只显示删除文件
total               # 返回数量
```

---

### 同步 (Sync)

| 命令 | 作用 |
|------|------|
| `sync` | 暂停/恢复同步 |
| `sync:status` | 显示同步状态和用量 |
| `sync:history` | 列出同步版本历史 |
| `sync:read` | 读取同步版本 |
| `sync:restore` | 恢复同步版本 |
| `sync:open` | 打开同步历史 |
| `sync:deleted` | 列出已删除文件 |

> 注意：这些命令控制运行中的 Obsidian 应用内的同步。如需命令行同步，参见 Obsidian Headless。

---

### 文件历史

| 命令 | 作用 |
|------|------|
| `diff` | 列出或比较版本 |
| `history` | 列出本地历史 |
| `history:list` | 列出所有有历史的文件 |
| `history:read` | 读取本地历史版本 |
| `history:restore` | 恢复本地历史版本 |
| `history:open` | 打开文件恢复 |

```bash
file=<name>         # 文件名
path=<path>         # 文件路径
from=<n>            # 比较起始版本
to=<n>              # 比较结束版本
filter=local|sync   # 按来源过滤
version=<n>         # 版本号
```

---

### 其他命令

| 命令 | 作用 | 分类 |
|------|------|------|
| `bases` | 列出 .base 文件 | Bases |
| `base:views` | 列出视图 | Bases |
| `base:create` | 创建 base 项 | Bases |
| `base:query` | 查询 base | Bases |
| `bookmarks` | 列出书签 | Bookmarks |
| `bookmark` | 添加书签 | Bookmarks |
| `commands` | 列出命令 ID | Command palette |
| `command` | 执行命令 | Command palette |
| `hotkeys` | 列出快捷键 | Hotkeys |
| `hotkey` | 获取命令快捷键 | Hotkeys |
| `random` | 打开随机笔记 | Random note |
| `random:read` | 读取随机笔记 | Random note |
| `templates` | 列出模板 | Templates |
| `template:read` | 读取模板内容 | Templates |
| `template:insert` | 插入模板 | Templates |
| `unique` | 创建唯一笔记 | Unique note |
| `vault` | 显示 vault 信息 | Vault |
| `vaults` | 列出已知 vaults | Vault |
| `vault:open` | 切换 vault (TUI) | Vault |
| `web` | 在 Web viewer 打开 URL | Web viewer |
| `wordcount` | 字数统计 | Word count |
| `workspace` | 显示工作区树 | Workspace |
| `workspaces` | 列出工作区 | Workspace |
| `workspace:save` | 保存工作区 | Workspace |
| `workspace:load` | 加载工作区 | Workspace |
| `tabs` | 列出标签页 | Tabs |
| `tab:open` | 打开标签页 | Tabs |
| `recents` | 最近打开的文件 | Recent files |
| `aliases` | 列出别名 | Properties |
| `properties` | 列出属性 | Properties |
| `property:set` | 设置属性 | Properties |
| `property:remove` | 移除属性 | Properties |
| `property:read` | 读取属性 | Properties |

---

### 开发命令 (Developer Commands)

| 命令 | 作用 |
|------|------|
| `devtools` | 打开开发者工具 |
| `dev:debug` | 调试模式 |
| `dev:cdp` | Chrome DevTools Protocol |
| `dev:errors` | 查看错误日志 |
| `dev:screenshot` | 截图 |
| `dev:console` | 开发者控制台 |
| `dev:css` | CSS 调试 |
| `dev:dom` | DOM 检查 |
| `dev:mobile` | 移动端视图 |
| `eval` | 运行 JavaScript |

```bash
# eval 示例
obsidian eval code="app.vault.getFiles().length"

# dev:screenshot 示例
obsidian dev:screenshot path=screenshot.png
```

---

### 工作区 (Workspace)

```bash
# 列出/保存/加载工作区
obsidian workspaces           # 列出所有工作区
obsidian workspace:save name="my-workspace"  # 保存当前布局
obsidian workspace:load name="my-workspace"  # 加载工作区
obsidian workspace:delete name="old-workspace"  # 删除工作区

# 标签页操作
obsidian tabs                 # 列出标签页
obsidian tab:open path="note.md"  # 打开文件到标签页
obsidian recents              # 最近打开的文件
```

---

## 故障排除

如果 CLI 无法运行：

1. 确认使用最新 Obsidian 安装版本 (1.12.7+)
2. 确认已在设置中启用 CLI
3. 确认 Obsidian 应用正在运行
4. 检查命令行是否正确注册

---

## 相关链接

- [Obsidian 官方文档](https://obsidian.md/help)
- [Obsidian Headless](https://obsidian.md/headless) - 无桌面应用同步方案
- [Bases 插件](https://obsidian.md/bases)
- [Update Obsidian > Installer updates](https://obsidian.md/help/updates#Installer updates)
