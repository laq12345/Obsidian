# just 命令运行器—— 完整参考笔记

> 项目级命令编排工具。把常用命令写进 `justfile`，一键调用。
> 官网：[just.systems/man/en/](https://just.systems/man/en/)

---

## 一、安装与基础

### 安装

```fish
pixi global install just
just --version        # 验证
```

### 查找规则

`just` 从当前目录向上查找 `justfile`（大小写不敏感，`.justfile` 也支持）。

### 最基本 justfile

```makefile
hello:
    @echo "你好，世界！"
```

```fish
just          # 执行第一个 recipe
just hello    # 执行指定 recipe
```

---

## 二、Recipe（配方）

### 语法

```makefile
recipe-name:
    要执行的命令
```

每行一条独立命令（默认 `sh -cu`），失败即停。

### 前缀修饰符

| 前缀   | 含义                                | 示例               |
| ---- | --------------------------------- | ---------------- |
| `@`  | 不打印命令本身，只打印输出                     | `@echo "hi"`     |
| `-`  | 忽略此行错误，继续执行                       | `-rmdir temp`    |
| `?`  | 退出码 1 时跳过本 recipe（需 `set guards`） | `?[[ -f file ]]` |
| `@-` | 安静 + 忽略错误                         | `@-rmdir temp`   |

```makefile
demo1:
    @echo "安静模式"          # 只输出"安静模式"

demo2:
    -false                    # 忽略 false 的失败
    @echo "继续执行"

demo3:
    ?[[ -f config.yml ]]      # guard：文件存在时才继续
    @echo "config 存在"
```

### 跨行

行尾加 `\`：

```makefile
build:
    cargo build --release \
        --features "all"
```

### 私有 Recipe

以 `_` 开头或用 `[private]`，不出现在 `--list` 中。

```makefile
[private]
@helper:
    @echo "辅助"

build: helper
    @echo "构建"
```

### 别名

```makefile
alias b := build

build:
    cargo build
```

```fish
just b
```

---

## 三、参数传递

### 位置参数

```makefile
greet name:
    @echo "你好，{{ name }}"
```

```fish
just greet 小明          # ✅ 按顺序传
```

> **Recipe 参数是位置参数**——按声明顺序传值，不支持 `参数名=值` 写法。

### 默认值

```makefile
cluster resolution="1.0":
    @echo "分辨率：{{ resolution }}"
```

```fish
just cluster             # 用默认值 1.0
just cluster 0.5         # 传入新值
```

### 多变参

```makefile
# + 表示一个或多个
backup +FILES:
    scp {{ FILES }} server:/backup/

# * 表示零个或多个
commit *FLAGS:
    git commit {{ FLAGS }} -m "msg"
```

### 参数导出为环境变量

```makefile
test $RUST_BACKTRACE="1":
    cargo test
```

### 命令行标志（v1.46+）

```makefile
[arg("target", long="target")]
build target:
    echo "Building {{ target }}"

[arg("verbose", short="v")]
run verbose:
    echo "verbose"

[arg("force", long="force", value="true")]
clean force:
    rm -rf *
```

```fish
just build --target my_app
just run -v
just clean --force
```

### 参数校验（v1.45+）

```makefile
[arg('n', pattern='\\d+')]
double n:
    echo $((${{ n }} * 2))
```

---

## 四、变量

### 定义与插值

```makefile
name    := "Alice"
version := "1.0"

show:
    @echo "{{ name }} {{ version }}"
```

### 字符串类型

```makefile
s1 := '单引号字符串'                       # 无转义
s2 := "双引号支持 \\n \\t"                 # 支持转义
s3 := '''三重引号自动去除公共缩进'''          # 三重引号
s4 := f'格式字符串，支持 {{插值}}'          # f-string（v1.44+）
s5 := x'~/projects/$NAME'                 # shell 展开（编译时）
```

### 环境变量

```makefile
home := env("HOME")                     # 获取，不存在则报错
mode := env("MODE", "dev")              # 获取，带默认值

export API_KEY := "abc123"              # 导出到 recipe 的环境变量
unexport SECRET                         # 取消导出

set export                              # 全局：所有变量自动导出
```

### 引用环境变量

直接 `$VAR_NAME` 在 recipe 中使用：

```makefile
serve:
    @echo "Starting on port $PORT"
```

### 变量覆盖（命令行）

```fish
just os=plan9 build                     # 变量名=值 recipe名
just --set os bsd build                 # 等价写法
```

> 注意：这仅对顶层变量（`:=` 定义）生效，不是 recipe 参数。

### 运行时传递变量

```makefile
os := "linux"

build:
    ./build {{ os }}
```

```fish
just os=plan9 build                     # 临时改成 plan9
```

### 惰性求值（v1.47+）

```makefile
set lazy

token := `expensive-command`            # 只有在用到时才执行
```

---

## 五、内置函数

### 系统信息

| 函数 | 返回 |
|------|------|
| `arch()` | CPU 架构（x86_64, aarch64...） |
| `os()` | 操作系统（linux, macos, windows...） |
| `os_family()` | unix 或 windows |
| `num_cpus()` | 逻辑 CPU 核心数 |

### 环境与文件

| 函数 | 说明 |
|------|------|
| `env(key)` / `env(key, default)` | 获取环境变量 |
| `require(name)` | 查找可执行文件，找不到则报错 |
| `which(name)` | 查找可执行文件，找不到返回 `[]` |
| `path_exists(path)` | 路径是否存在（返回 `"true"` / `"false"`） |
| `read(path)` | 读取文件内容 |
| `sha256(s)` / `sha256_file(path)` | SHA-256 哈希 |
| `uuid()` | 生成 UUID v4 |
| `datetime(format)` / `datetime_utc(format)` | 当前时间（strftime 格式） |

### 字符串处理

| 函数 | 说明 |
|------|------|
| `quote(s)` | 单引号包裹 + 转义 |
| `replace(s, from, to)` | 字符串替换 |
| `replace_regex(s, regex, repl)` | 正则替换 |
| `trim(s)` | 去除首尾空白 |
| `append(sfx, s)` | 给每个单词加后缀 |
| `prepend(pfx, s)` | 给每个单词加前缀 |
| `lowercase(s)` / `uppercase(s)` | 大小写 |
| `snakecase(s)` / `kebabcase(s)` / `titlecase(s)` 等 | 命名风格转换 |

### 路径操作

```makefile
path := "data" / "raw" / "file.txt"       # data/raw/file.txt
abs  := / "usr" / "bin" / "just"          # /usr/bin/just
```

| 函数 | 说明 |
|------|------|
| `absolute_path(path)` | 转绝对路径 |
| `canonicalize(path)` | 解析符号链接和 `.` `..` |
| `extension(path)` | 扩展名（如 `txt`） |
| `file_name(path)` | 文件名（`bar.txt`） |
| `file_stem(path)` | 文件名无扩展（`bar`） |
| `parent_directory(path)` | 父目录 |
| `join(a, b...)` | 路径拼接 |

### 目录

| 函数 | 说明 |
|------|------|
| `invocation_directory()` | 运行 `just` 时的目录 |
| `justfile_directory()` | justfile 所在目录 |
| `home_directory()` | 用户家目录 |
| `source_directory()` | 当前源文件（import/mod）目录 |

### 控制

| 函数 | 说明 |
|------|------|
| `assert(cond, msg)` | 条件为假时报错 |
| `error(msg)` | 直接报错中止 |
| `is_dependency()` | 当前 recipe 是否作为依赖运行 |
| `recipe_name()` | 当前 recipe 名称 |
| `semver_matches(ver, req)` | 语义版本匹配 |

---

## 六、依赖

### 前置依赖

```makefile
test: build
    ./test

build:
    cc -o main main.c
```

`just test` → 先 `build`，再 `test`

### 带参数的依赖

```makefile
default: (build "release")

build target:
    echo "Building {{ target }}"
```

### 依赖只执行一次

```makefile
B: A
C: A
```

`just B C` → A 执行一次，B 和 C 各执行一次。

### 后置依赖

`&&` 后的 recipe 在当前 recipe **之后**执行：

```makefile
deploy: build && notify
    rsync -avz dist/ server:

build:
    npm run build

notify:
    curl -X POST https://hooks.slack.com/...
```

执行顺序：`build` → `deploy` → `notify`

### 并行依赖（v1.42+）

```makefile
[parallel]
test: test-frontend test-backend
```

---

## 七、条件表达式

```makefile
# if/else 变量赋值
os := if arch() == "x86_64" { "amd64" } else { "arm64" }

# recipe 体内的条件
check target:
    @echo {{ if target == "prod" { "production" } else { "staging" } }}

# 正则匹配
foo := if "hello" =~ 'hel+o' { "match" } else { "mismatch" }

# 链式
build_mode := if env("CI", "false") == "true" {
    "release"
} else {
    "debug"
}

# 错误中止
assert(arch() == "x86_64", "unsupported arch")
```

---

## 八、Shebang Recipe 与 Script Recipe

### Shebang Recipe（`#!` 开头）

```makefile
# Python
analyze:
    #!/usr/bin/env python3
    import scanpy as sc
    print(f"Data: {sc.read('data.h5ad').shape}")

# R
plot:
    #!/usr/bin/env Rscript
    library(Seurat)
    DimPlot(pbmc_small)
    ggsave("umap.pdf")

# Node.js
hello:
    #!/usr/bin/env node
    console.log("Hello from JS")
```

### Script Recipe（v1.32+）

```makefile
[script]
hello:
    print("Hello from Python!")
```

配置解释器：

```makefile
set script-interpreter := ['uv', 'run', '--script']

[script]
hello:
    # /// script
    # requires-python = ">=3.11"
    # dependencies=["pandas"]
    # ///
    import pandas as pd
    print(pd.__version__)
```

---

## 九、模块化

### import（内容合并）

```makefile
# justfile
import 'tasks/analysis.just'

# 导入后，analysis.just 的内容直接可见
full: preprocess cluster

# 可选导入（文件不存在时不报错）
import? 'optional/shared.just'
```

### mod（独立命名空间）

```makefile
# justfile
mod qc
mod cluster

# 子模块文件：qc.just 或 qc/justfile
# 子模块中的 recipe 用路径调用
just qc::run
just cluster run        # 空格分隔也可以
```

| 对比 | import | mod |
|------|--------|-----|
| 效果 | 内容合并 | 独立命名空间 |
| 调用 | 直接名字 | `模块名::recipe` |
| 变量 | 共享 | 隔离 |

---

## 十、设置与属性

### 全局设置

```makefile
set shell := ["bash", "-uc"]              # 更改默认 shell
set dotenv-load                           # 加载 .env 文件
set dotenv-filename := ".env.prod"        # 指定 .env 文件名
set dotenv-path := "/etc/myapp/.env"      # 指定完整路径
set positional-arguments                  # 开启位置参数模式
set export                                # 所有变量自动导出到环境
set quiet                                 # 全局安静模式
set lazy                                  # 惰性求值
set default-list := true                  # 默认列出 recipe
set no-cd                                 # 全局不切换目录
set working-directory := "src"            # 全局工作目录
set tempdir := "/tmp/just"                # 临时文件目录
set allow-duplicate-recipes               # 允许同名 recipe（后者覆盖前者）
```

### Recipe 属性

```makefile
[confirm]                                    # 执行前询问确认
[confirm("确定删除全部？")]                   # 自定义提示

[linux] / [macos] / [windows] / [unix]        # 仅在某平台启用

[no-cd]                                      # 不切换目录

[private]                                    # 不在 --list 显示

[parallel]                                   # 依赖并行执行

[group('lint')]                              # 分组

[doc('运行单元测试')]                         # 文档注释

[env("API_KEY", "abc123")]                   # 设置环境变量

[working-directory: 'src']                   # 设置工作目录

[positional-arguments]                       # 单 recipe 启用位置参数

[metadata("foo", "bar")]                     # 附加元数据
```

```makefile
# 多属性合并
[no-cd, private, linux]
build:
    cargo build
```

### dotenv 文件

```makefile
# .env 文件内容
DATABASE_URL=localhost:6379
SERVER_PORT=1337
```

```makefile
# justfile
set dotenv-load

serve:
    @echo "Starting on port $SERVER_PORT"
```

---

## 十一、命令行

### 基本

```fish
just                       # 执行默认 recipe
just recipe                # 执行指定 recipe
just r1 r2                 # 按序执行多个
just r1 r2 r3              # 第3个前面会停住等待确认
```

### 传参

```fish
just recipe 值1 值2        # 位置参数
just k=v recipe            # 变量覆盖（k 必须是变量）
just --set k v recipe      # 等价的变量覆盖写法
just recipe --flag value   # 命令行标志（需 [arg] 属性）
```

### 信息

```fish
just -l                    # 列出 recipe
just -s recipe             # 查看 recipe 内容
just -n recipe             # 干跑（只打印不执行）
just -e                    # 编辑 justfile
just --summary             # 更简洁的列表
just --evaluate            # 查看所有变量
just --evaluate name       # 查看某变量
just --usage recipe        # 查看用法
just --dump                # JSON 输出
just --groups              # 列出分组
```

### 控制

```fish
just --yes                 # 自动确认
just --one                 # 只允许执行一个 recipe
just -f path/to/justfile   # 指定 justfile
just -d src recipe         # 指定工作目录
just --dotenv-path .env    # 指定 .env 文件
just --completions fish    # 生成 shell 补全
```

---

## 十二、完整实战模板

```makefile
# justfile — 单细胞分析管线
# 用法：just                 → 列出所有 recipe
#       just run-all         → 一键全跑
#       just cluster 0.5     → 改分辨率

# ── 变量（可用命令行覆盖） ──
sample  := env("SAMPLE", "GSE160936")
threads := env("THREADS", "8")

# ── 默认行为 ──
set default-list := true

# ── 核心流程 ──
preprocess:
    pixi run python 01_preprocess.py \
        --sample {{ sample }} \
        --threads {{ threads }}

cluster resolution="1.0":
    pixi run python 02_cluster.py \
        --resolution {{ resolution }}

[doc('寻找各 cluster 的标记基因')]
markers:
    pixi run python 03_markers.py

[confirm]
report:
    pixi run quarto render report.qmd

# ── 聚合 ──
run-all: preprocess cluster markers

# ── 辅助 ──
[private]
clean:
    @rm -rf data/intermediate/*
    @echo "已清理"

info:
    @echo "样本：{{ sample }}"
    @echo "线程：{{ threads }}"

# ── 别名 ──
alias p := preprocess
alias c := cluster
alias f := run-all
```

---

## 十三、速查

### 语法元素

| 写法 | 含义 |
|------|------|
| `recipe:` | 定义 recipe |
| `@cmd` | 安静执行 |
| `-cmd` | 忽略错误 |
| `?cmd` | guard 模式 |
| `# 注释` | 注释 |
| `dep: dep1 dep2` | 前置依赖 |
| `dep: dep1 && dep2` | 前置 + 后置依赖 |
| `var := "value"` | 定义变量 |
| `\` 续行 | 跨行命令 |
| `{{ expr }}` | 插值 |
| `` `cmd` `` | 命令结果赋值 |
| `set k := v` | 设置 |
| `[attr]` | 属性 |
| `import 'path'` | 导入 |
| `mod name` | 子模块 |
| `alias x := y` | 别名 |
| `export v := "x"` | 导出环境变量 |

### 参数传递对比

```makefile
# 这是变量（顶层，:= 定义）
version := "1.0"

build:
    echo {{ version }}

# 这是参数（recipe 行）
build target:
    echo {{ target }}
```

```fish
# 变量覆盖（名=值，recipe 名前）
just version=2.0 build

# 参数传递（位置，recipe 名后）
just build my-app
```

### 内置常量

```makefile
CLEAR   NORMAL  BOLD    ITALIC
RED     GREEN   BLUE    CYAN  # 终端颜色
HEX     HEXLOWER         # 十六进制字符
PATH_SEP                  # 路径分隔符
```

---

> 官方文档：[just.systems/man/en/](https://just.systems/man/en/)
> 仓库：[github.com/casey/just](https://github.com/casey/just)
