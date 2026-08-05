---
title: DVC 使用指南
date: 2026-04-16
tags:
  - 工具
  - DVC
  - ML
  - 数据版本控制
aliases:
  - DVC
  - Data Version Control
  - dvc用法
source: https://doc.dvc.org/
---

# DVC 使用指南（Data Version Control）

> [!info] 简介
> **DVC（Data Version Control）** 是面向 AI/ML 和数据基础设施的版本控制工具，被誉为 **"Git for data"**。它让大型数据集和机器学习模型可以与代码一起被版本化管理，绕过 Git 存储大文件的限制。克隆仓库后即可看到数据集、checkpoint 和模型；`git checkout` 切换到不同版本，即使文件有 100GB，切换也只需不到 1 秒。

> [!warning] DVC 不是要取代 Git，而是扩展 Git
> DVC 本身不是版本控制系统，它操纵 `.dvc` 元数据文件，其内容定义了数据文件的版本。**Git 继续版本化你的代码，现在也能顺带版本化你的数据**。数据实际存放在缓存（cache）中，不入 Git 仓库。

---

## 一、核心概念

| 概念 | 说明 |
|------|------|
| **缓存 (Cache)** | 数据实际存放的地方，位于 `.dvc/cache`，按内容哈希组织（如 `files/md5/22/a1a293...`） |
| **.dvc 文件** | `dvc add` 生成的轻量元数据文件（如 `data.xml.dvc`），是数据的"占位符"，可提交到 Git |
| **dvc.yaml** | 定义管道（pipeline）：stages、参数、指标、图表的 YAML 文件 |
| **dvc.lock** | 记录管道各 stage 实际运行时的依赖/输出哈希，由 DVC 自动维护 |
| **Remote** | 外部存储（S3、SSH、本地目录等），用于共享和备份数据，类似 Git remote |
| **实验 (Experiments)** | 基于当前 Git HEAD 创建的变体，用 Git 引用（`.git/refs/exps`）追踪，不污染常规提交 |
| **Stage** | 管道中的一个执行步骤，包装一条 shell 命令及其依赖和输出 |

---

## 二、安装

```bash
# 推荐方式：uv 或 pipx 隔离安装
uv tool install dvc      # 或
pipx install dvc

# 验证
dvc --help
```

> [!tip] 其他安装方式
> - `pip install dvc`（普通 pip，会污染环境）
> - 安装远程存储支持：`pip install "dvc[s3]"`、`"dvc[azure]"`、`"dvc[gdrive]"`、`"dvc[gs]"`、`"dvc[ssh]"`、`"dvc[oss]"`、`"dvc[hdfs]"`、`"dvc[webdav]"` 等
> - VS Code 有官方 [DVC Extension](https://marketplace.visualstudio.com/items?itemName=Iterative.dvc)，提供 GUI 操作实验和管道

---

## 三、快速上手：数据版本化工作流

### 3.1 初始化项目

```bash
mkdir example-get-started && cd example-get-started
git init

# 在 Git 项目内初始化 DVC（DVC 也可脱离 Git 使用，但版本化功能依赖 Git）
dvc init

# 提交 DVC 内部文件（.dvc/.gitignore、.dvc/config 等）
git add .dvc
git commit -m "Initialize DVC"
```

### 3.2 跟踪数据（dvc add）

```bash
# dvc get 可以从任意 DVC 仓库（"数据注册表"）下载文件
dvc get https://github.com/treeverse/dataset-registry get-started/data.xml -o data/data.xml

# 跟踪数据集：生成 data/data.xml.dvc，数据本身移入缓存并被 .gitignore
dvc add data/data.xml

# 只提交元数据，不提交数据本体
git add data/data.xml.dvc data/.gitignore
git commit -m "Add raw data"
```

> [!note] 背后发生了什么
> `dvc add` 会把数据移动到项目缓存（`.dvc/cache/files/md5/22/a1a293...`），再链接回工作区。`.dvc` 文件内容形如：
> ```yaml
> outs:
>   - md5: 22a1a2931c8370d3aeedd7183606fd7f
>     path: data.xml
> ```

### 3.3 配置远程存储并推送

```bash
# 本地远程（本地目录，最简示例）
mkdir /tmp/dvcstore
dvc remote add -d myremote /tmp/dvcstore

# 常见云存储示例
dvc remote add -d storage s3://mybucket/dvcstore

# 上传数据
dvc push

# 常规做法：代码变更也一并提交推送
git add -A && git commit -m "..." && git push
```

### 3.4 拉取数据

```bash
# 通常先 git pull 再 dvc pull
dvc pull
```

### 3.5 修改数据并重新跟踪

```bash
cp data/data.xml /tmp/data.xml
cat /tmp/data.xml >> data/data.xml   # 模拟新数据

dvc add data/data.xml                # 重新跟踪最新版本
dvc push                             # 上传变更
git commit data/data.xml.dvc -m "Dataset updates"
```

### 3.6 切换数据版本

```bash
# git checkout 切换分支/历史，然后 dvc checkout 同步数据到工作区
git checkout <rev>
dvc checkout

# 回到上一个版本
git checkout HEAD~1 data/data.xml.dvc
dvc checkout
git commit data/data.xml.dvc -m "Revert dataset updates"
```

---

## 四、项目结构

```text
.dvc/                 # DVC 内部文件
  ├── config          # 本地配置（远程存储定义等）
  ├── config.local    # 敏感配置（Git 忽略，如凭据）
  ├── cache/          # 数据缓存（默认位置）
  └── .gitignore
dvc.yaml              # 定义 stages/参数/指标/图表 → 管道
dvc.lock              # 记录 stage 实际执行的依赖和输出哈希
.dvc 文件             # 数据占位符（data.xml.dvc）
.dvcignore            # （可选）忽略列表，提高性能
params.yaml           # 参数文件（默认）
```

这些元文件（metafiles）通常随 Git 版本化。

---

## 五、dvc.yaml 详解

`dvc.yaml` 使用 YAML 1.2 格式，用于配置 **artifacts、metrics、params、plots、stages**，是管道的核心。文件设计得足够小，方便随 Git 版本化。

### 5.1 Artifacts（工件元数据）

```yaml
artifacts:
  cv-classification:          # 工件 ID（只能含字母数字和 '-'）
    path: models/resnet.pt    # 必填：仓库相对路径或外部存储完整路径
    type: model               # 类型，DVC 模型注册表默认展示 type: model
    desc: 'CV classification model, ResNet50'
    labels:
      - resnet50
      - classification
    meta:                     # 任意附加信息，DVC 忽略其内容
      framework: pytorch
```

### 5.2 Metrics / Params / Plots

```yaml
metrics:            # 标量指标文件（键值对 → 数值）
  - metrics.json
params:             # 参数文件（文件级，包含所有参数）
  - params.yaml
plots:              # 图表配置，每个 plot 必须有唯一 ID（路径或任意字符串）
  - regression_hist.csv:
      y: mean_squared_error
  - classifier_hist.csv:
      y: [acc, loss]
      x: epoch
      template: linear    # 可选：linear、confusion 等
      title: 训练历史
  - roc_vs_prc:           # 任意字符串 ID 时需用 dict 映射文件路径
      y:
        precision_recall.json: precision
        roc.json: tpr
      x:
        precision_recall.json: recall
        roc.json: fpr
```

### 5.3 Stages（管道阶段）

```yaml
stages:
  prepare:
    cmd: python src/prepare.py data/data.xml   # 唯一必填字段
    deps:                       # 文件/目录依赖：内容变了 stage 失效
      - data/data.xml
      - src/prepare.py
    params:                     # 参数依赖：只在该部分参数变化时失效
      - prepare.seed
      - prepare.split
    outs:                       # 输出：自动缓存、自动追踪（无需手动 dvc add）
      - data/prepared
  train:
    cmd: python src/train.py data/prepared model.pkl
    deps:
      - data/prepared           # 依赖上一 stage 的输出 → 形成 DAG
    params:
      - train.epochs
    outs:
      - model.pkl
    always_changed: true        # 每次都运行（即使无变化）
    persist: true               # 运行时不删除输出（默认每次运行前删除输出）
```

> [!tip] 关键机制
> - **依赖失效**：DVC 对依赖内容计算哈希（而非像 make 只看时间戳），内容变了 stage 才需重跑
> - **参数依赖是细粒度的**：只有 params.yaml 中对应部分变化才失效
> - **执行顺序由 DAG 决定**，与 dvc.yaml 中书写顺序无关
> - 也可用 `dvc stage add --name train --deps src/model.py --outs data/predict.dat "python src/model.py data/clean.csv"` 生成 stage（会校验参数，但高级特性如模板不可用）

### 5.4 模板（Templating）

dvc.yaml 支持模板变量（`${...}`），可结合参数文件实现复杂配置：

```yaml
vars:
  - params.yaml
stages:
  train:
    cmd: python train.py ${train.arch}
```

---

## 六、数据管理

### 6.1 远程存储（Remotes）

DVC remotes 类似 Git remote（GitHub/GitLab），但存的是缓存数据而非代码。

**支持的存储类型：**

| 类别 | 存储 |
|------|------|
| 云 | Amazon S3 及 S3 兼容（MinIO）、Azure Blob、GCS、Google Drive、阿里云 OSS |
| 自建 | SSH/SFTP、HDFS/WebHDFS、HTTP、WebDAV |
| 本地 | 系统目录、挂载盘、NAS（称 "local remote"） |

```bash
# 添加远程
dvc remote add myremote s3://mybucket
dvc remote add -d myremote /tmp/dvcstore   # -d 设为默认远程

# 修改远程配置（认证等敏感信息用 --local 写入 config.local，避免泄密）
dvc remote modify --local myremote credentialpath ~/.aws/alt
dvc remote modify myremote connect_timeout 300

# 列出/切换默认远程
dvc remote list
dvc remote default myremote
```

> [!warning] 凭据安全
> `--local` 选项把敏感配置写入 Git 忽略的 `.dvc/config.local`，不会泄露密钥。每份仓库拷贝需重新配置这些值。

### 6.2 缓存文件链接类型（大数据集优化）

为避免工作区与缓存重复存储大文件，DVC 可用文件链接：

| cache.type | 速度 | 省空间 | 可原地编辑 | 说明 |
|-----------|------|--------|-----------|------|
| `reflink` | ✅ | ✅ | ✅ | 写时复制，最理想；支持的文件系统有限（Linux: Btrfs/XFS/OCFS2；macOS: APFS） |
| `hardlink` | ✅ | ✅ | ❌ | 同分区最高效；不能原地编辑（需先删除再替换） |
| `symlink` | ✅ | ✅ | ❌ | 仓库和缓存跨文件系统时最佳（如 SSD 仓库 + HDD 缓存） |
| `copy` | ❌ | ❌ | ✅ | 所有文件系统可用，直接复制（默认回退方案） |

```bash
# 配置链接类型
dvc config cache.type hardlink,symlink

# 用 dvc version 查看当前文件系统支持的链接类型
dvc version

# 重新按当前配置链接工作区文件
dvc checkout --relink
```

> [!warning] 注意
> hardlink/symlink 下，工作区文件为**只读**以保护缓存不被破坏。需要修改时先 `dvc unprotect <file>`。重排链接或修改受保护文件后记得重新 `dvc add` 并 push。

### 6.3 发现和访问数据（跨项目复用）

```bash
# 列出 DVC 仓库内容（Git+DVC 跟踪的文件都可见）
dvc list https://github.com/treeverse/dataset-registry get-started

# 直接下载（适合仓库外的部署场景，如 CI 部署模型）
dvc get https://github.com/treeverse/dataset-registry use-cases/cats-dogs

# 导入到项目（生成含来源信息的 .dvc 文件，可用 dvc update 同步上游变更）
dvc import https://github.com/treeverse/dataset-registry get-started/data.xml -o data/data.xml

# 从数据库导入
dvc import-db --sql "SELECT * FROM table" --file-format csv sqlite:///db.sqlite3 data.csv
```

**Python API（应用内直接访问数据）：**

```python
import dvc.api

with dvc.api.open(
    'get-started/data.xml',
    repo='https://github.com/treeverse/dataset-registry'
) as f:
    # f 是 file-like 对象，可正常处理
    data = f.read()

# 其他 API：get_url()、metrics_show()、params_show()、exp_show()
```

### 6.4 停止跟踪数据

```bash
# 从缓存移除并停止跟踪（保留工作区文件）
dvc remove data/data.xml.dvc

# 彻底删除：git rm 元数据文件 + dvc gc 清理缓存
```

---

## 七、数据管道（Pipelines）

### 7.1 定义管道

```yaml
stages:
  prepare:
    cmd: python src/prepare.py data/data.xml
    deps: [data/data.xml, src/prepare.py]
    params: [prepare.seed, prepare.split]
    outs: [data/prepared]
  featurize:
    cmd: python src/featurization.py data/prepared data/features
    deps: [data/prepared, src/featurization.py]
    params: [featurize.max_features, featurize.ngrams]
    outs: [data/features]
  train:
    cmd: python src/train.py data/features model.pkl
    deps: [data/features, src/train.py]
    outs: [model.pkl]
```

### 7.2 运行管道

```bash
# dvc repro：按 DAG 重跑过期 stage（数据版本化工作流）
dvc repro

# dvc exp run：运行管道并保存为实验（推荐用于 ML 实验）
dvc exp run --set-param featurize.ngrams=3

# 只重跑部分目标 / 单 stage
dvc repro <stage-name>
dvc exp run --single-item <stage-name>
```

**执行输出示例：**

```text
Reproducing experiment 'funny-dado'
'data/data.xml.dvc' didn't change, skipping
Stage 'prepare' didn't change, skipping
Running stage 'featurize':
> python src/featurization.py data/prepared data/features
Updating lock file 'dvc.lock'
...
Ran experiment(s): funny-dado
```

### 7.3 运行缓存（Run Cache）

DVC 会尽量避免重复计算：

```text
Stage 'prepare' is cached - skipping run, checking out outputs
```

- 相同依赖+命令+参数的 stage 命中 run cache，直接从缓存恢复输出
- 需要每次都运行：`always_changed: true`

### 7.4 可视化 DAG

```bash
dvc dag                 # 文本/ASCII 图
dvc dag --md            # Markdown 格式
dvc dag --dot           # Graphviz DOT 格式
```

### 7.5 缺失数据场景

```bash
# --pull：按需下载缺失数据（无需预先 dvc pull 全部数据）
# --allow-missing：跳过除数据缺失外无其他变化的 stage
dvc exp run --pull --allow-missing --set-param evaluate.n_samples_to_save=20

# CI 场景只检查管道状态，不运行：--dry
dvc repro --dry --allow-missing

# 查看哪些 stage 过期/数据缺失
dvc status
```

---

## 八、实验管理（Experiments）

### 8.1 保存实验

实验是基于当前分支 HEAD 的变体，通过 Git 引用（`.git/refs/exps`）保存，**不会污染常规 Git 提交树**，默认也不推送到 Git remote。

```bash
# 方式一：有管道 → dvc exp run 运行并保存
dvc exp run

# 方式二：无管道 → 用 DVCLive 在 Python 中实时记录
#   from dvclive import Live
#   live = Live()  # log_metric() / log_param() / log_image() 等
```

自动生成名字（如 `puffy-daks`），也可自定义：`dvc exp run -n my-exp`。

### 8.2 调参运行

```bash
# 修改 params.yaml 中的参数并运行（-S 快捷选项）
dvc exp run -S train.fine_tune_args.base_lr=0.001

# 一次设置多个参数
dvc exp run -S train.img_size=1024 -S train.batch_size=512
```

### 8.3 实验队列（网格搜索）

```bash
# 入队（不立即运行）
dvc exp run --queue -S train.fine_tune_args.base_lr=0.001

# 网格搜索：列表/range 语法
dvc exp run --queue \
    -S train.arch='resnet18,shufflenet_v2_x2_0' \
    -S 'train.fine_tune_args.base_lr=range(0.001, 0.01, 0.001)'

# 启动队列（默认串行，--jobs N 并行；在隔离临时目录中执行）
dvc queue start
dvc queue start --jobs 4

# 队列管理
dvc queue status
dvc queue logs <task-id>
dvc queue remove --queued   # 清空未运行队列
```

> [!tip] 实验隔离
> 队列实验在 `.dvc/tmp/exps/` 的临时工作区副本中运行，共享项目缓存。`dvc exp run --temp` 可让长实验后台运行而不阻塞你继续工作。Git 忽略的文件不会进入队列运行，未跟踪文件需先 `git add`。

### 8.4 对比实验

```bash
# 表格展示所有实验的指标（黄）、参数（蓝）、依赖（紫）
dvc exp show
dvc exp show --only-changed    # 只显示有变化的列
dvc exp show -A                # 显示所有提交的实验
dvc exp show --csv             # CSV 输出，便于 csvkit/pandas 分析

# 对比两个版本的指标
dvc metrics diff <rev1> <rev2>

# 对比参数
dvc params diff <rev1> <rev2>

# 叠加多个实验的图表
dvc plots diff $(dvc exp list --name-only)
```

**Python API 获取实验表：**

```python
import dvc.api
import pandas as pd

exps = dvc.api.exp_show()        # 返回 dict 列表
df = pd.DataFrame(exps)
```

### 8.5 应用/共享/删除实验

```bash
# 把某实验结果恢复到工作区（冲突改动会被覆盖，但可恢复）
dvc exp apply ochre-dook

# 将实验固化为 Git 分支/提交
dvc exp branch <exp-name> <branch-name>

# 推送实验到远程（默认实验不推送）
dvc exp push origin <exp-name>

# 列出/删除实验
dvc exp list
dvc exp remove <exp-name>

# 工作区实验结果撤销：dvc exp apply <baseline> 或 git 重置 + dvc checkout
```

> [!warning] 提交实验到 Git 的常规流程
> `dvc exp apply` 之后，用标准 Git 命令（git add/commit/push）固化；DVC 数据已在缓存中，但需 `dvc push` 才能共享或备份缓存内容。

---

## 九、常用命令速查表

### 数据版本化

| 命令 | 作用 |
|------|------|
| `dvc init` | 初始化 DVC 项目 |
| `dvc add <path>` | 跟踪数据文件/目录，生成 .dvc 文件 |
| `dvc checkout` | 按 .dvc 文件把数据同步到工作区 |
| `dvc push` / `dvc pull` | 上传/下载数据到远程 |
| `dvc status` | 查看数据/管道与缓存/远程的差异 |
| `dvc remove <file.dvc>` | 停止跟踪（可选 --outs 只删数据） |
| `dvc get <repo> <path>` | 从 DVC 仓库下载文件（不跟踪） |
| `dvc import <repo> <path>` | 导入并跟踪外部数据（可 dvc update） |
| `dvc list <repo>` | 列出 DVC 仓库内容 |
| `dvc diff` | 比较两个版本间的数据/指标差异 |

### 管道

| 命令 | 作用 |
|------|------|
| `dvc repro` | 重跑管道中过期的 stage |
| `dvc stage add` | 命令行创建 stage |
| `dvc dag` | 可视化管道 DAG |
| `dvc freeze/unfreeze <stage>` | 冻结/解冻 stage（跳过其执行） |
| `dvc run --single-item` | 只运行单个 stage |

### 实验

| 命令 | 作用 |
|------|------|
| `dvc exp run [-S key=val] [--queue]` | 运行管道并保存实验 |
| `dvc exp show [--csv]` | 展示实验表格 |
| `dvc exp apply <name>` | 恢复实验到工作区 |
| `dvc exp branch <name> <branch>` | 实验固化为 Git 分支 |
| `dvc exp push/pull <remote>` | 共享实验 |
| `dvc exp diff` | 查看实验间指标/参数差异 |
| `dvc queue start/stop/status/logs/remove/kill` | 实验队列管理 |

### 远程与配置

| 命令 | 作用 |
|------|------|
| `dvc remote add [-d] <name> <url>` | 添加远程（-d 设为默认） |
| `dvc remote modify <name> <opt> <val>` | 修改远程配置 |
| `dvc remote default/list/remove/rename` | 远程管理 |
| `dvc config` | 查看/修改配置（cache.type、core.* 等） |
| `dvc gc` | 清理缓存中未被引用的数据 |
| `dvc doctor` | 环境诊断 |
| `dvc version` | 版本及支持的文件链接类型 |

### 导入/导出辅助

| 命令 | 作用 |
|------|------|
| `dvc get-url <url> <out>` | 直接下载任意 URL 文件（不生成 .dvc） |
| `dvc import-url <url> <out>` | 导入 URL 文件并生成 .dvc |
| `dvc import-db` | 从数据库导入快照 |
| `dvc update <file.dvc>` | 更新导入的数据到上游最新版本 |

---

## 十、最佳实践清单

> [!success] 工作流建议
> 1. **小文件交给 Git，大文件交给 DVC**：代码、小配置用 Git；数据集、模型、中间产物用 DVC
> 2. **元数据必须提交 Git**：`.dvc` 文件、`dvc.yaml`、`dvc.lock` 都随代码版本化，否则他人无法还原数据
> 3. **敏感凭据用 `--local`**：写入 `.dvc/config.local`，勿提交
> 4. **管道优先于手动 add**：让 stage 的 outs 自动缓存追踪，减少手动 `dvc add`
> 5. **实验用 `-S` 调参 + `--queue` 批量**：避免反复手改 params.yaml
> 6. **CI/CD 用 `dvc repro --dry --allow-missing`** 检查管道状态
> 7. **团队共享**：配置好远程后，成员只需 `git clone && dvc pull`
> 8. **大数据集**：配置 `cache.type`（hardlink/symlink）避免空间浪费；按目录粒度跟踪
> 9. **代码规范**：stage 的代码只读写声明的 deps/outs；输出要完全重写（不要 append），否则 DVC 的哈希校验可能失效

---

## 十一、生态系统

| 工具 | 作用 |
|------|------|
| **DVCLive** | Python 库，训练中实时记录指标/参数/图表/工件，自动生成 dvc.yaml |
| **DVC Studio** | 云端平台：模型注册表、实验对比 UI、CI/CD 集成 |
| **VS Code Extension** | IDE 内运行实验、对比表格、查看图表 |
| **GTO** | Git Tag 驱动模型注册（semantic version + dev/stage/prod 生命周期） |
| **lakeFS** | 姊妹项目：数据湖级别的 Git 式版本控制（PB 级场景） |
| **dvc-task / Celery** | 实验队列的后端任务管理 |

### DVCLive 最小示例

```python
from dvclive import Live

with Live() as live:
    for epoch in range(10):
        train(...)
        live.log_metric("acc", accuracy)
        live.log_metric("loss", loss)
        live.log_param("epochs", 10)
        live.next_step()
```

---

## 相关链接

- [DVC 官方文档](https://doc.dvc.org/)
- [Get Started 教程](https://doc.dvc.org/doc/start)
- [数据管道教程](https://doc.dvc.org/doc/start/data-pipelines)
- [实验管理](https://doc.dvc.org/doc/user-guide/experiment-management)
- [命令参考](https://doc.dvc.org/doc/command-reference)
- [DVCLive 文档](https://dvc.org/doc/dvclive)
- [DVC GitHub](https://github.com/iterative/dvc)

*整理自 DVC 官方文档（2026-04-16）*
