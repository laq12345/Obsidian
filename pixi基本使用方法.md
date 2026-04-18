---
lang: Python
date: 2026-04-12
tags:
  - 工具
---
### Pixi 的基本用法

Pixi 功能丰富，但设计上力求简单易用。让我们来了解一下 Pixi 的基本用法。

#### 管理工作区
- **pixi init** - 在当前目录创建一个新的 Pixi 清单文件
- **pixi add** - 向你的清单文件添加依赖
- **pixi remove** - 从你的清单文件中移除依赖
- **pixi update** - 更新清单文件中的依赖
- **pixi upgrade** - 将清单文件中的依赖升级到最新版本，即使你已将它们锁定到特定版本
- **pixi lock** - 为你的清单文件创建或更新锁文件
- **pixi info** - 显示关于你的工作区的信息
- **pixi run** - 运行清单文件中定义的任务或当前环境中的任何命令
- **pixi shell** - 在当前环境中启动一个 Shell
- **pixi list** - 列出当前环境中的所有依赖
- **pixi tree** - 显示当前环境中的依赖树
- **pixi clean** - 从你的机器上移除环境

#### 管理全局安装
Pixi 可以在全局环境中管理工具的全局安装。它将环境安装在中心位置，以便你可以从任何地方使用它们。

- **pixi global install** - 将包安装到全局空间中的独立环境里。
- **pixi global uninstall** - 从全局空间中卸载一个环境。
- **pixi global add** - 向现有的全局环境添加包。
- **pixi global sync** - 将全局安装的环境与描述你想要安装的所有环境的全局清单进行同步。
- **pixi global edit** - 编辑全局清单。
- **pixi global update** - 更新全局环境
- **pixi global list** - 列出所有全局环境
- 更多信息：全局工具

#### 运行一次性命令
Pixi 可以在特定环境中运行一次性命令。

- **pixi exec** - 在临时环境中运行命令。
- **pixi exec --spec** - 在具有特定规范的临时环境中运行命令。

例如：

```bash
> pixi exec python -VV
Python 3.13.5 | packaged by conda-forge | (main, Jun 16 2025, 08:24:05) [Clang 18.1.8 ]
> pixi exec --spec "python=3.12" python -VV
Python 3.12.11 | packaged by conda-forge | (main, Jun  4 2025, 14:38:53) [Clang 18.1.8 ]
```

#### 多环境支持
Pixi 工作区允许你管理多个环境。一个环境由一个或多个特性构建而成。

- **pixi add --feature** - 向一个特性添加包
- **pixi task add --feature** - 向特定特性添加任务
- **pixi workspace environment add** - 向工作区添加环境
- **pixi run --environment** - 在特定环境中运行命令
- **pixi shell --environment** - 激活特定环境
- **pixi list --environment** - 列出特定环境中的依赖
- 更多信息：多环境支持

#### 任务
Pixi 可以使用其内置的任务运行器运行跨平台任务。这可以是预定义的任务，也可以是任何普通可执行文件。

- **pixi run** - 运行任务或命令
- **pixi task add** - 向清单文件添加新任务

任务可以拥有其他任务作为依赖。这是一个更复杂任务用例的示例：

`pixi.toml`

```toml
[tasks]
build = "make build"
# 使用 toml 表格视图
[tasks.test]
cmd = "pytest"
depends-on = ["build"]
```

更多信息：任务

#### 多平台支持
Pixi 开箱即支持多平台。你可以指定你的工作区支持哪些平台，Pixi 将确保依赖与这些平台兼容。

- **pixi add --platform** - 仅向特定平台添加包
- **pixi workspace platform add** - 向工作区添加你想要支持的平台
- 更多信息：多平台支持

#### 实用工具
Pixi 附带了一系列实用工具来帮助你调试或管理你的设置。

- **pixi info** - 显示当前工作区和全局设置的信息。
- **pixi config** - 显示或编辑 Pixi 配置。
- **pixi tree** - 显示当前环境中的依赖树。
- **pixi list** - 列出当前环境中的所有依赖。
- **pixi clean** - 从你的机器上移除工作区环境。
- **pixi help** - 显示 Pixi 命令的帮助信息。
- **pixi help ** - 显示特定 Pixi 命令的帮助信息。
- **pixi auth** - 管理 Conda 频道的认证。
- **pixi search** - 在已配置的频道中搜索包。
- **pixi completion** - 为 Pixi 命令生成 Shell 补全脚本。
