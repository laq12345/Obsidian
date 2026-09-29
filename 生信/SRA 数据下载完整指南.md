---
created: 2026-09-29
tags:
  - 生信
  - 数据获取
  - SRA
  - ENA
  - prefetch
  - fasterq-dump
  - aria2c
  - kingfisher
  - 测序数据
aliases:
  - SRA 下载
  - SRA 数据下载
  - prefetch 用法
  - fasterq-dump 用法
  - kingfisher 用法
  - 下载测序原始数据
  - 下载 FASTQ
---

# SRA 数据下载完整指南

> **一句话结论**
> 小数据 / 受控数据 → `prefetch` + `fasterq-dump`（NCBI 官方）
> 大数据 / 公共数据 → **ENA 镜像 + `aria2c`**（跳过 `.sra` 和转换）
>
> 本机实测同一条链路：单线程 **0.03 MB/s** vs `aria2c -x16` **40.8 MB/s** —— 差 3 个数量级。

相关：[[aria2c使用教程]]、[[Cell Ranger 使用笔记]]

> [!note] 单位约定
> 本文容量**统一用 GiB（1024 进制）**，与 `df -h` / `du -h` 口径一致，避免拿"十进制 GB"的数据去比"1024 进制的空闲空间"。
> 换算：64.96 GiB = 69.75 GB（十进制） = 69,745,319,519 字节。

---

## 0. 坐标系：SRA / ENA / 云端 是同一批数据的三个出口

这是理解一切下载方案的前提。

| 出口 | 是什么 | 给什么文件 | 能不能多连接 |
| --- | --- | --- | --- |
| **NCBI SRA** | 美国，原始档案 | `.sra`（专有格式，需转换） | 官方工具走单连接 |
| **EBI ENA** | 欧洲，**同一批数据的镜像** | **`fastq.gz` + `md5`**（拿来即用） | ✅ 支持 HTTP Range |
| **AWS / GCP ODP** | NCBI 的云开放数据副本 | `.sra` | ✅ 但只拿到 `.sra` |

两个关键推论：

1. **公共数据不必从 NCBI 下**。ENA 是 SRA 的镜像，而且直接给 `fastq.gz` —— 省掉 `.sra` 落地和 `fasterq-dump` 转换两大步。
2. **ENA 支持 `Accept-Ranges: bytes`**（本机实测探测到 `206 Partial Content`），所以 `aria2c -x16` 的多连接分片对它有效。这是后面所有提速的基础。

> [!important] 什么时候**不能**走 ENA
> - 受控访问数据（dbGaP / 需授权）
> - 只提交到 SRA、未同步到 ENA 的 run
> - 需要原始 submitter 文件（BAM/CRAM/custom）
> - `.sra` 里有但 ENA 未生成 fastq 的数据类型（部分长读长 / 新平台）
>
> 这些情况回退到 `prefetch`。

---

## 1. 工具速查表（常用 / 重要 / 稳定）

### 1.1 核心必学

| 工具 | 出处 | 作用 | 说明 |
| --- | --- | --- | --- |
| **`prefetch`** | sra-tools | 按 accession 下载 `.sra` | 官方主力。**可断点续传**，默认下载后自动校验 |
| **`fasterq-dump`** | sra-tools | `.sra` → `fastq` | 官方推荐的转换工具，多线程 |
| **`vdb-validate`** | sra-tools | 校验下载完整性 | 逐列 md5 校验，下完必跑 |
| **`vdb-dump --info`** | sra-tools | **下之前先查大小 / 平台 / read 数** | 算盘利器 |
| **`srapath`** | sra-tools | **accession → 真实 URL** | 打通「NCBI 官方 ↔ aria2c 多连接」的桥 |
| **`aria2c`** | aria2 | 通用多连接下载器 | 配 ENA 效率最高，见 [[aria2c使用教程]] |

### 1.2 辅助 / 特定场景

| 工具                  | 出处        | 作用                                      |
| ------------------- | --------- | --------------------------------------- |
| `vdb-config`        | sra-tools | 配置缓存目录、远端访问开关                           |
| `sam-dump`          | sra-tools | `.sra` → SAM/BAM（含比对信息时有用）              |
| `sra-stat`          | sra-tools | 统计 run 的 read 数 / 碱基数                   |
| `kingfisher`        | wwood     | 给 accession，自动在 ENA/SRA/AWS/GCP 多源间按序尝试 |
| `fastq-dl`          | rpetit3   | 轻量 Python 版 ENA/SRA 下载器（`ena-dl` 继任者）   |
| `aws` / `gsutil`    | 云厂商       | 云端 ODP 直取                               |
| `sra-explorer.info` | 网页        | 浏览选样 → 生成下载脚本                           |

### 1.3 已废弃 / 不要再用

| 工具 | 状态 | 替代 |
| --- | --- | --- |
| `fastq-dump` | ⚠️ 官方标注 **deprecated** | `fasterq-dump` |
| `parallel-fastq-dump` | ⚠️ 第三方包装，本质是并行调 `fastq-dump` | `fasterq-dump -e N` |
| **Aspera / `ascp` / fasp** | ❌ **NCBI 侧已废弃** | `prefetch`（https） |

> [!warning] Aspera 已经死了（实测证据）
> `srapath -a fasp SRR11955372` 在 sra-tools 3.4.1 下直接报错：
> ```
> srapath.3.4.1 err: Protocol 'fasp' is retired. Only 'https' is supported ( 400 )
> ```
> NCBI 文档里那句「批量下载强烈推荐 Aspera Connect」**已经过期**。`prefetch -t fasp` 还留着选项但服务端不再支持。不要再为配 `ascp` 折腾。

---

## 2. 路线 A：NCBI 官方 sra-tools

### 2.1 版本坑

| 事实 | 影响 |
| --- | --- |
| 当前最新 **3.4.1** | — |
| **`centos_linux64` 构建在 3.2.1 起被砍掉** | 只剩 `alma_linux64` 和 `ubuntu64` |
| `sdk/current/sratoolkit.current-centos_linux64.tar.gz` 仍在，但**拿到的是 ≤ 3.2.0 的旧版** | 教程里常见的这个链接会静默给你旧版本 |

⇒ 用 `ubuntu64` / `alma_linux64` 官方包，或走 conda（bioconda），别用 centos 链接。

### 2.2 两步法（官方推荐路径）

```bash
# 1) 下载 .sra（可续传：失败就重跑同一条命令）
prefetch -X 200G -O . SRR11955372

# 2) 校验
vdb-validate SRR11955372

# 3) 转换（10x 数据必须拆 R1/R2）
fasterq-dump --split-files -e 16 -O out/ SRR11955372

# 4) 压缩 —— 注意 fasterq-dump 没有 --gzip！
pigz -p 16 out/SRR11955372_*.fastq
```

> [!warning] `fasterq-dump` 与 `fastq-dump` 的三个致命差异
> 1. **没有 `--gzip` / `--bzip2`**。必须事后自己压（所以最终还得 `pigz`）。
> 2. **`-Z / --stdout` 对 `split-3` / `split-files` 无效**，工具会退回写文件。
> 3. **只接受一个 accession**（`fastq-dump` 可以多个）；但支持 `--option-file <file>`。
>
> 另外：`fastq-dump` 用 `--threads`，**`fasterq-dump` 用 `-e`**（默认 6），写错会静默用默认值。

### 2.3 一步法（省磁盘）

```bash
# --download：边下边转，不落地 .sra。小样本省掉一份 .sra 的空间
fasterq-dump --download --split-files -e 16 -O out/ SRR11955372
```

### 2.4 `prefetch` 关键选项（本机实测 3.4.1 `--help`）

| 选项 | 默认 | 说明 |
| --- | --- | --- |
| `-X, --max-size <size>` | **20G** | 单位 **KB**。超过就拒下。支持 `k/m/g/t` 后缀和 `u`（无限制） |
| `-N, --min-size <size>` | — | 小于此值不下载（批量时跳过小 run 有用） |
| `-r, --resume <yes\|no>` | `yes` | 断点续传。失败重跑即可 |
| `-C, --verify <yes\|no>` | `yes` | 下载后自动校验 |
| `-O, --output-directory` | cwd | 目录名必须**等于 accession**，否则转换工具找不到 |
| `-p, --progress` | 关 | 显示进度 |
| `-H, --heartbeat <min>` | 1 | 进度心跳间隔（分钟），`0` = 关闭 |
| `-f, --force <yes\|no\|all\|ALL>` | `no` | **`all` = 忽略残留 lock**（见下方坑） |
| `-t, --transport <http\|fasp\|both>` | `both` | fasp 已废弃，实际只会走 http |
| `-T, --type <value>` | `sra` | 文件类型 |
| `--eliminate-quals` | 关 | 改下 **SRA Lite**（简化质量值，体积小很多） |

> [!note] `-X 200GB` 这种写法**是合法的**
> 实测 `prefetch -X 200GB ...` 与 `-X 200G ...` 都能正常解析，不报错。教程里这么写没问题。

> [!warning] 残留 lock 文件坑
> `prefetch` 被中断（Ctrl-C / timeout / 进程被杀）会留下 `<acc>.sra.lock`。下次运行会报：
> ```
> warn: lock exists while copying file - Lock file .../ERR10037751.sra.lock exists: download canceled
> ```
> 并发跑多个 `prefetch` 时尤其容易撞上。解决：`prefetch -f all <acc>`。

### 2.5 下之前先算盘

```bash
vdb-dump SRR11955372 --info          # 查大小/平台/read 数，不用先下载
```
```
acc    : SRR11955372
path   : https://sra-pub-run-odp.s3.amazonaws.com/sra/SRR11955372/SRR11955372
size   : 1,346,864,089
platf  : SRA_PLATFORM_ILLUMINA
SEQ    : 11,709,324
```

`SEQ` 就是 read 数，和 ENA 的 `read_count` 一致。

### 2.6 `srapath`：把 accession 还原成真实 URL ★

```bash
$ srapath SRR11955372
https://sra-pub-run-odp.s3.amazonaws.com/sra/SRR11955372/SRR11955372
```

拿到后就能**用 aria2c 多连接下 `.sra`**：

```bash
aria2c -x 16 -s 16 -k 4M -c "$(srapath SRR11955372)"
```

适用场景：「数据不在 ENA、只能从 NCBI 侧拿 `.sra`」时的提速（本机实测 AWS ODP 单线程 0.004 MB/s → aria2c 60.3 MB/s）。

---

## 3. 路线 B：ENA 镜像 + aria2c（大数据量首选）★

### 3.1 为什么这条路更优

| 维度 | prefetch 路线 | ENA + aria2c |
| --- | --- | --- |
| 下载内容 | `.sra`（50.55 GiB） | **`fastq.gz`（64.96 GiB）** |
| 下载连接数 | 单连接 | **16+ 连接聚合** |
| 转换步骤 | 需要 `fasterq-dump` | **不需要** |
| 峰值磁盘 | **≈ 17 × `.sra`** | 只有最终 fastq |
| 完整性校验 | `vdb-validate` | ENA 提供 `md5` |
| 拿来即可用 | 否 | **是**（直接喂 cellranger / salmon） |

省下的流量只有约 20%（`.sra` 比 `fastq.gz` 小），但**省掉的转换时间和峰值磁盘是数量级的**（见 §6）。

### 3.2 拿 URL：ENA Portal REST API

```bash
curl -s "https://www.ebi.ac.uk/ena/portal/api/filereport?accession=SRR11955372&result=read_run&fields=run_accession,fastq_ftp,fastq_md5,fastq_bytes&format=tsv"
```
```
run_accession	fastq_ftp	fastq_md5	fastq_bytes
SRR11955372	ftp.sra.ebi.ac.uk/vol1/fastq/SRR119/072/SRR11955372/SRR11955372_1.fastq.gz;ftp.sra.ebi.ac.uk/.../SRR11955372_2.fastq.gz	fb68110d...;e7b771f1...	910394560;802757043
```

要点：
- 多个文件用 `;` 分隔，`fastq_ftp` / `fastq_md5` / `fastq_bytes` **按位一一对应**
- 返回的路径是 `ftp.sra.ebi.ac.uk/...`，**前面加 `https://` 即可**
- 批量查：`result=read_run` + `accession` 一次一个；或用 `query=` 表达式

### 3.3 ⚠️ ENA API 会静默降级（本笔记最重要的一节）

实测 ENA 的 `filereport` 会在**服务端降级窗口**内返回各种"看起来正常"的响应，而且 `curl -f` **不会报错**。实测遇过的形态：

| 形态 | HTTP | body | 危险之处 |
| --- | --- | --- | --- |
| (a) 空响应 | 200 | **0 字节** | 容易被当成"查询失败"或"没有数据" |
| (b) 字段缺失 | 200 | 有数据行，但 `fastq_ftp`/`fastq_md5` **为空** | 太像"该 run 确实没有 fastq" |
| (c) 只有表头 | 200 | 仅表头，无数据行 | **和"该 run 不在 ENA"完全同形** |
| 正常 | 200 | 表头 + 数据行 | — |

而真正"该 run 不在 ENA"的响应就是 **(c) 只有表头**。

**后果**：任何把"没拿到数据"直接当成"ENA 里没有 → 跳过"的脚本，会在降级窗口里**静默丢样本**。本机实测一次丢了 2/16 个文件（约 1/8），而且脚本还报成功。

> [!important] 正确的处理方式
> - 形态 (a)(b)(c) **全部当作可重试**，退避重试若干次
> - 只有**连续 N 次（本脚本取 5）都只有表头**，才敢判定"该 run 确实不在 ENA"
> - 重试耗尽 → **非 0 退出**，不要报成功
> - 独立核对每个期望文件**存在且非空**，不要只信下载器的退出码
>
> 这些都是血泪教训换来的，`fetch_sra.sh` 已按此实现。

### 3.4 下载 + 校验

```bash
aria2c -x 16 -s 16 -k 1M -j 2 -c \
  --file-allocation=none \
  -i urls.txt -d fastq/

md5sum -c md5.txt      # md5.txt 由 API 的 fastq_md5 生成
```

`-x 16 -k 1M` 是 aria2 的上限组合（`-x` 范围 1–16，`-k` 范围 1M–1G），详见 [[aria2c使用教程]]。

### 3.5 现成脚本 `fetch_sra.sh`

位置：`bioinfo/learn/20CellRanger/fetch_sra.sh`

```bash
./fetch_sra.sh -i SRR_Acc_List.txt -o fastq/    # 批量（走 ENA API）
./fetch_sra.sh SRR11955372 SRR11955373          # 单个 / 多个
./fetch_sra.sh -i SRR_Acc_List.txt -n           # dry-run，只列会下什么、共多少 GiB
./fetch_sra.sh -i list.txt -j 2 -x 16           # 调并发
```

**退出码约定**（便于放进流水线）：

| 退出码 | 含义 | 该做什么 |
| --- | --- | --- |
| `0` | 成功（或 dry-run 正常） | — |
| `1` | 用法错误 / 下载或 md5 校验未通过 / ENA 确实无此 run | 看提示：改命令，或改用 `prefetch` |
| `2` | **ENA 服务端降级**，重试耗尽 | **直接重跑**（脚本幂等，aria2c 断点续传） |

其它已处理的鲁棒性问题：
- 容忍 accession 列表的 CRLF、空行、`#` 注释、**末尾无换行符**（NCBI 导出的列表经常没有尾换行，`while read` 会静默丢最后一行）
- 支持位置参数与选项混排（`fetch_sra.sh SRR123 -o out/` 也正确）
- ENA 里没有的 run 会明确告警并提示改用 `prefetch`，不静默跳过
- 可重复执行；每个文件独立核对存在性与非空

> [!note] 实测验证
> 用 mock ENA 服务注入 6 种响应形态 + 3 种下载故障，共 11 个场景，全部通过（期望退出码 vs 实际退出码一致）。真实 ENA 连跑 12 次无误判。

---

## 4. 路线 C：云端 ODP（AWS / GCP）

```bash
# 方式1：sra-tools 内建
prefetch --type aws -X 200G SRR11955372

# 方式2：直接下 S3 桶（无需 AWS 账号，公开只读）
aria2c -x 16 -s 16 -k 4M -c \
  "https://sra-pub-run-odp.s3.amazonaws.com/sra/SRR11955372/SRR11955372"
```

注意：**只拿到 `.sra`**，仍需 `fasterq-dump`。所以它解决"NCBI 主站太慢"，不解决"还要转换"。遍历 bucket（批量取）需要 AWS 凭证。

---

## 5. 路线 D：封装工具 kingfisher

给一个 accession，自动在多个源之间按顺序尝试（本机实测 0.5.0）：

```bash
kingfisher get -r ERR1739691 -m ena-ascp aws-http prefetch
kingfisher get -r ERR1739691 -m aws-http -f fasta --download-threads 8
```

可用方法（`-m`）：
`aws-http`、`prefetch`、`aws-cp`、`gcp-cp`、`ena-ascp`、`ena-ftp`、`ngdc-ascp`、`ngdc-http`

- `ena-ascp` / `ena-ftp` → 直接下 `fastq.gz`（最省事）
- `prefetch` / `aws-http` / `aws-cp` / `gcp-cp` → 下 `.sra`，需再转换
- `gcp-cp` / `aws-cp` 走付费/需凭证源，要加 `--allow-paid`
- 子命令：`get`（下载）、`extract`（`.sra` 转 FASTQ/FASTA）、`annotate`（run 元数据）、`authorship`（找文章的 accession 归属）

内部就是调 `curl / aria2 / prefetch / aws`，所以提速逻辑和手写脚本一致；价值在于**省掉自己拼 URL**。

---

## 6. 容量估算：下之前先算，否则一定爆盘 ★

### 6.1 NCBI 官方经验公式（`fasterq-dump` wiki）

```
未压缩 fastq   ≈ 7   × .sra
转换期 scratch ≈ 1.5 × 未压缩 fastq
转换峰值总需求 ≈ 17  × .sra
```

**含义**：`.sra` 落地只占 1 份，但转成 fastq 的过程中，峰值要吃 **17 倍 `.sra` 的空间**。

### 6.2 套到本项目的数据上（8 个 run，实测）

`.sra` 合计 **50.55 GiB** ⇒ 转换峰值需求 ≈ **859 GiB**。

本机 `/var/home` 只有 **433 GiB 空闲** ⇒ **一次性全转必然爆盘**。

| 做法 | 磁盘峰值 | 可行性 |
| --- | --- | --- |
| 8 个 run 一起 `prefetch` 再一起 `fasterq-dump` | ~859 GiB | ❌ 爆盘 |
| 逐个 run 单独转（最大 `.sra` 13.55 GiB） | ~230 GiB | ✅ 可行但吃紧 |
| **走 ENA 直下 `fastq.gz`** | **64.96 GiB** | ✅ 舒服 |

> [!caution] 公式的适用边界
> 「7×」是**全库平均**，对**很小的 run 会严重偏高**。
> 本机实测：一个 113,471 字节的 `.sra` 只产出 122,858 字节未压缩 fastq（比例 **1.08×**，不是 7×）——因为小 run 里元数据占比过大。
> 结论：**小数据别信这个公式；大数据（本项目这种）按它算盘。**

### 6.3 用 `--disk-limit` 兜底

`fasterq-dump` 支持 `--disk-limit` / `--disk-limit-tmp` 显式设上限，宁可失败也别把盘写满。

---

## 7. 实测数据（本机，2026-09-29）

### 7.1 单线程 vs 多连接

同样下 20 秒：

| 源 | 单线程 `curl` | `aria2c -x16 -s16` | 倍率 |
| --- | --- | --- | --- |
| ENA `ftp.sra.ebi.ac.uk` | 0.03 MB/s | **40.8 MB/s** | ~1250× |
| NCBI AWS ODP | 0.004 MB/s | **60.3 MB/s** | ~14000× |

> 单线程 60 秒只拿到 2.5 MB。典型的「单条 TCP 到海外质量差，多连接能聚合出带宽」。
> ⚠️ 这是本机本网络的结果，不代表所有环境，但趋势普遍成立。

### 7.2 `.sra` vs `fastq.gz` 的真实体量（SRR11955372–379）

| accession | `.sra` (GiB) | `fastq.gz` (GiB) | read 数 |
| --- | --- | --- | --- |
| SRR11955372 | 1.25 | 1.60 | 11,709,324 |
| SRR11955373 | 9.35 | 12.02 | 89,088,710 |
| SRR11955374 | 10.73 | 13.81 | 102,161,749 |
| SRR11955375 | 1.36 | 1.73 | 12,535,965 |
| SRR11955376 | 1.11 | 1.40 | 10,327,565 |
| SRR11955377 | 1.60 | 2.03 | 14,889,814 |
| SRR11955378 | 11.59 | 14.92 | 108,951,596 |
| SRR11955379 | 13.55 | 17.44 | 128,718,187 |
| **合计** | **50.55** | **64.96** | **478 M** |

⇒ `.sra ≈ 0.78 × fastq.gz`（`.sra` 来自 HTTP `Content-Range`；`fastq.gz` 来自 ENA 的 `fastq_bytes`）

> [!important] 纠正一个流传很广的说法
> 「fasterq-dump 出来的 fastq 是 `.sra` 的 3–5 倍」—— **这只对未压缩 fastq 成立**。
> 和 `fastq.gz` 比，`.sra` 只小约 20%。10x 数据尤其如此（barcode/UMI 重复度极高，gzip 也能压得很好）。
> 所以「先下 `.sra` 再转」省下的**下载量**很有限，真正的代价在转换时间和峰值磁盘。
>
> 顺带解释 `.sra` 为什么能压这么小：`prefetch` 默认取 **SRA Normalized Format**（保留完整质量值），
> 内部按参考序列重排 + 质量值压缩。启动日志会说：*"Current preference is set to retrieve SRA Normalized Format files with full base quality scores"*。

---

## 8. 常见坑清单

| # | 坑 | 现象 | 解法 |
| --- | --- | --- | --- |
| 1 | `fasterq-dump` 没有 `--gzip` | 以为能直接出 `.fastq.gz` | 事后 `pigz` |
| 2 | `--threads` 写错 | `fasterq-dump` 静默用默认 6 线程 | 用 `-e N` |
| 3 | 30 秒就放弃 | `prefetch` 单连接极慢，被 timeout 杀掉 | 给足超时；或改用 ENA + aria2c |
| 4 | 残留 `.sra.lock` | 重跑报 `lock exists ... download canceled` | `prefetch -f all` |
| 5 | accession 列表末尾无换行 | **静默丢掉最后一行** | `while IFS= read -r l \|\| [[ -n "$l" ]]` |
| 6 | 一次全转 | 峰值 17 × `.sra`，爆盘 | 逐个转 / 走 ENA |
| 7 | `prefetch -X` 没给 | 默认上限 20G，大于此的 run 拒下 | `-X 200G` |
| 8 | `-O` 目录名不等于 accession | 转换工具找不到文件 | 保持 `<acc>/` 目录名 |
| 9 | 移动 `.sra` 后改名 | `fasterq-dump` 找不到 | 整目录移动，**不要改名** |
| 10 | 还在配 Aspera | 白费功夫 | fasp 已废弃，用 https |
| 11 | 教程里的 centos tar 链接 | 静默拿到 ≤3.2.0 旧版 | 用 `ubuntu64`/`alma_linux64`，或 bioconda |
| 12 | **把 ENA API 降级当成"没有数据"** | **静默丢样本且报成功** | 见 §3.3，重试 + 非 0 退出 |
| 13 | 只信下载器退出码 | 文件缺失/为空却报成功 | 独立核对每个文件存在且非空 |
| 14 | `set -e` + 命令替换 | `x=$(f); case $? in` 里的判定全是死代码 | 用 `if x=$(f); then ... else rc=$?; fi` |

---

## 9. 安装

### 9.1 pixi（推荐）

> [!warning] 必须同时给 conda-forge 和 bioconda，且 conda-forge 在前
> sra-tools 的依赖（`ca-certificates` / `curl` / `perl` / `zstd`）全在 conda-forge，bioconda 只有包本体。
> 只给 bioconda 的后果很隐蔽：
> ```console
> $ pixi exec -c bioconda -s sra-tools -- prefetch --version
> prefetch : 2.8.2          # ← 不报错，但给你个远古版本！
>
> $ pixi exec -c conda-forge -c bioconda -s sra-tools -- prefetch --version
> prefetch : 3.4.1          # ← 正确
> ```

> [!warning] pixi bug：对**已存在**的全局环境，`-c` 通道参数被忽略（0.76.1 实测）
> ```console
> # 新建环境 → 成功
> $ pixi global install --environment seqtktest -c conda-forge -c bioconda seqtk
> └── seqtktest (installed)   ✅
>
> # 往已有环境装同一个包 → 失败
> $ pixi global install --environment tool -c conda-forge -c bioconda seqtk
> ╰─▶ Cannot solve the request because of: No candidates were found for seqtk *   ❌
> ```
> 绕过办法：先手动把通道写进 `~/.pixi/manifests/pixi-global.toml` 的 `[envs.<name>] channels`，再装。
> 更简单的做法是**直接建专用环境**（下方即是）。

> [!tip] `sra-tools` 会把 ~90 个二进制全部暴露到 `~/.pixi/bin`
> 装完 `pixi global list` 会看到一大串 `abi-dump`、`bam-load`、`illumina-dump`… 把 PATH 弄得很乱。
> 用 **`--expose`** 只暴露真正要用的：
> ```bash
> pixi global install --environment sra \
>   -c conda-forge -c bioconda \
>   --expose prefetch --expose fasterq-dump --expose fastq-dump \
>   --expose vdb-validate --expose vdb-dump --expose vdb-config \
>   --expose srapath --expose sam-dump --expose sra-stat --expose sratools \
>   --expose kingfisher \
>   sra-tools kingfisher
> ```
> 90 个 → 11 个。

其它常用形式：

```bash
pixi exec -c conda-forge -c bioconda -s sra-tools -- prefetch --version   # 只跑一次，不落地
pixi global uninstall <env>            # 删掉整个全局环境
pixi global remove -e <env> <pkg>      # 只删某个包
```

### 9.2 官方 tar 包手动装

```bash
# 注意：3.2.1 起没有 centos 构建了
curl -LO https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/3.4.1/sratoolkit.3.4.1-ubuntu64.tar.gz
tar -xzf sratoolkit.3.4.1-ubuntu64.tar.gz -C ~/.local/share/
ln -s ~/.local/share/sratoolkit.3.4.1-ubuntu64/bin/* ~/.local/bin/
```

### 9.3 本机状态（2026-09-29 已装好）

| 项 | 值 |
| --- | --- |
| 全局环境名 | **`sra`**（专用，独立于 `tool`） |
| 依赖 | `sra-tools 3.4.1`、`kingfisher 0.5.0` |
| 通道 | `["conda-forge", "bioconda"]` |
| 暴露命令 | 11 个：`prefetch`、`fasterq-dump`、`fastq-dump`、`vdb-validate`、`vdb-dump`、`vdb-config`、`srapath`、`sam-dump`、`sra-stat`、`sratools`、`kingfisher` |
| 入口 | `~/.pixi/bin/<命令>` → `~/.pixi/envs/sra/bin/<命令>` |
| 清单 | `~/.pixi/manifests/pixi-global.toml` |
| 下载脚本 | `bioinfo/learn/20CellRanger/fetch_sra.sh` |
| 备份 | `~/.pixi/manifests/pixi-global.toml.bak-before-bioconda`（改通道前留的，确认无误后可删） |

> 安装过程中踩的坑：一开始按"并进现有 `tool` 环境"的思路走，先撞上 `-c` 被忽略的 bug，
> 手动加通道后仍失败（`INSTALL_RC=1`），且 `sra-tools` 会把 90 个二进制塞进 PATH —— 于是改为专用环境 + `--expose`。
> `tool` 环境已还原为纯 `conda-forge`，未残留 sra-tools / kingfisher。

---

## 10. 参考

- SRA Toolkit wiki — prefetch 与 fasterq-dump（**最权威**，含 7×/1.5×/17× 磁盘公式）
  <https://github.com/ncbi/sra-tools/wiki/08.-prefetch-and-fasterq-dump>
- SRA Toolkit wiki — Access SRA Data / Download On Demand
  <https://github.com/ncbi/sra-tools/wiki/HowTo:-Access-SRA-Data>
- NCBI — SRA Data Formats（SRA Normalized / SRA Lite 的区别）
  <https://www.ncbi.nlm.nih.gov/sra/docs/sra-data-formats>
- NCBI — SRA Cloud 数据
  <https://www.ncbi.nlm.nih.gov/sra/docs/sra-cloud/>
- ENA Portal API（`filereport` 的所有可用字段）
  <https://www.ebi.ac.uk/ena/portal/api/doc>
- kingfisher
  <https://wwood.github.io/kingfisher-download/>
- aria2c 选项细节 → [[aria2c使用教程]]

> **参数取值原则**：本文的选项与默认值以 **sra-tools 3.4.1 / kingfisher 0.5.0 二进制的 `--help` 实际输出**为准（已逐条实测校对），官方 wiki 只作解释性补充。升级后请重新 `--help` 校对。
