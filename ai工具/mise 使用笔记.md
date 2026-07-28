# mise 使用笔记

## 简介

mise（读作 "meezay"）是一个多语言版本管理器 + 环境变量管理 + 任务运行器，相当于 **asdf + direnv + make** 三合一。

GitHub：https://github.com/jdx/mise

## 安装

```bash
curl https://mise.run | sh
```

激活（Fish）：

```fish
echo '/var/home/smile/.local/bin/mise activate fish | source' >> ~/.config/fish/config.fish
```

验证：

```bash
mise doctor    # activated: yes 即为成功
```

## 与 pixi 的分工

| 工具 | 定位 | 适用场景 |
|------|------|----------|
| **pixi** | conda 生态 + 项目环境隔离 | Python/R 数据科学、生信分析 |
| **mise** | 通用语言运行时版本切换 | Node.js、Go、Rust、Java 等开发语言 |

## 核心命令

### 版本管理

```bash
# 安装工具
mise install node@latest
mise install node@20
mise install go@latest
mise install rust@stable

# 设置全局默认版本
mise use -g node@20
mise use -g go@latest

# 查看已安装
mise list

# 查看远程可用版本
mise ls-remote node

# 当前使用的版本
mise current node
```

### 项目级配置（`mise.toml`）

在项目根目录创建 `mise.toml`，自动切换版本：

```toml
[tools]
node = "20"
python = "3.11"
go = "latest"

[env]
DATABASE_URL = "postgres://localhost:5432/myapp"
API_KEY = "development-key"

[tasks]
build = "go build -o bin/app"
test = "go test ./..."
lint = "golangci-lint run"
```

### 任务运行

```bash
mise run build    # 运行 build 任务
mise run test     # 运行 test 任务
mise run          # 列出所有任务
```

### 环境变量

```bash
# 查看项目环境变量
mise env

# 在当前 shell 加载项目环境
eval "$(mise env)"
```

## 常用工具安装示例

```bash
# 语言运行时
mise install node@22
mise install python@3.12
mise install go@1.22
mise install rust@stable

# 开发工具
mise install jq
mise install ripgrep
mise install fd
mise install bat

# 云/运维工具
mise install terraform
mise install kubectl
mise install awscli
```

## 升级 mise

```bash
mise self-update
```

## 排错

| 问题 | 原因 | 解决 |
|------|------|------|
| `activated: no` | mise 未激活 | 检查 fish config 中是否有 activate 行，重新 source |
| 找不到命令 | PATH 未更新 | `mise doctor` 检查 `shims_on_path`，或重启 shell |
| 安装慢 | GitHub 下载限速 | 换代理或设 `MISE_NODE_MIRROR` 等镜像变量 |
