---
created: 2026-09-26
tags:
  - 生信
  - 单细胞
  - cellranger
---
# Cell Ranger 使用笔记（10.1.0）

> 10x Genomics 官方单细胞上游流程：一条命令完成 `fastq → 比对 + 拆细胞 + UMI 去重 → 计数矩阵`。
> 下载页：<https://www.10xgenomics.com/support/software/cell-ranger/downloads>
> 本机状态：已装 **10.1.0**（2026-09-26），`cellranger testrun` 官方自检**通过**。

> [!important] 本文的取值原则
> **参数与默认值一律以 `cellranger <子命令> --help` 的实际输出为准**，官方文档只作解释性补充。原因是实测发现了文档与二进制不一致的地方（见 §5.3）。升级 Cell Ranger 后请重新执行 help 校对。

---

## 0. 坐标系：它和 bulk 上游的对应关系

| bulk（如 airway 项目）                   | 单细胞（10x 液滴法）                                         |
| ----------------------------------- | ---------------------------------------------------- |
| `fastqc` 质控                         | 仍有，cellranger 的 `web_summary.html` 覆盖                |
| `trim_galore` / `fastp` 去接头         | **通常不做**：R1 是条码+UMI 区，剪掉就毁了细胞信息                      |
| `hisat2` 比对 → `samtools sort/index` | **`cellranger count` 一条命令**                          |
| `featureCounts -t exon` 定量          | 上游直接产出计数矩阵，**不再需要**                                  |
| `Salmon` 定量                         | `kallisto\|bustools` / `alevin-fry`（也支持 barcode+UMI） |
| `edgeR` / `DESeq2` 差异分析             | 需先 pseudobulk 再用，或改 Wilcoxon/MAST                    |

**本质差异**：单细胞的每条 read 多带两层信息 —— **细胞条码 CB**（16 bp，在 R1）和 **UMI**（10~12 bp，在 R1）。上游新增的活儿全在这两件事上：拆分细胞、按 UMI 去重（消除 PCR 重复）。所以 bulk 里的"比对完再定量"被压缩成"比对同时计数"。

---

## 1. 安装（本机实际记录）

### 1.1 本机现状

```console
$ cellranger --version
cellranger 10.1.0

$ ls -l ~/.local/bin/cellranger
~/.local/bin/cellranger -> ~/.local/share/cellranger-10.1.0/cellranger
```

| 项 | 值 |
|---|---|
| 版本 | 10.1.0（官方发布日期 2026-06-30） |
| 工具本体 | `~/.local/share/cellranger-10.1.0/`，解压后 **2.6 GB** |
| PATH 入口 | `~/.local/bin/cellranger` 软链（该目录已在 PATH，无需改配置） |
| 压缩包 | `cellranger-10.1.0.tar.xz` 636 MB，md5 `bb88407acb40cd9e4cd2749b6d774743` |
| 许可 | 包内 `LICENSE`：*"By accessing the contents of this package, you are agreeing to the terms at support.10xgenomics.com/license"* |

### 1.2 为什么工具本体不放在 `~/.local/bin`

`~/.local/bin` 按 XDG 约定**只放可执行文件/软链**。Cell Ranger 是一整棵树：

```
cellranger-10.1.0/
├── bin/                     # 真正的可执行文件（ELF 22 MB）+ 各子命令脚本
├── lib/  external/  mro/  etc/
└── cellranger -> bin/cellranger   # 官方自带相对软链
```

整棵树塞进 `~/.local/bin` 的代价：PATH 目录被上千文件拖慢补全、多版本无法共存、目录语义混乱。本机既有约定就是"工具本体放 `~/.local/share/`、入口放 `~/.local/bin/`"（如 `~/.local/share/mise/installs/`、`~/.local/share/nature-skills`）。

### 1.3 安装三步（换机器照做）

```bash
# 1. 下载（官方页面的 curl 命令带签名，过期需重新获取；.tar.xz 比 .tar.gz 小 300 MB）
cd ~/.cache
aria2c -c -x 16 -s 16 -k 4M --file-allocation=none \
  -o cellranger-10.1.0.tar.xz \
  "https://cf.10xgenomics.com/releases/cell-exp/cellranger-10.1.0.tar.xz?<签名参数>"
md5sum cellranger-10.1.0.tar.xz   # 应为 bb88407acb40cd9e4cd2749b6d774743

# 2. 解压到 ~/.local/share/
mkdir -p ~/.local/share ~/.local/bin
tar -xJf ~/.cache/cellranger-10.1.0.tar.xz -C ~/.local/share/

# 3. 在 PATH 里放出入口
ln -sf ~/.local/share/cellranger-10.1.0/cellranger ~/.local/bin/cellranger
cellranger --version
```

> 官方文档写的是 `export PATH=/opt/cellranger-x.y.z:$PATH`，本质一样：把**解压出来那一层目录**加进 PATH。软链方式更省事，且实测软链能被正确解析（`bin/cellranger` 内部用 `readlink -f` 定位自身）。

### 1.4 为什么不能用 conda / pixi 装

官方维护者在 GitHub issue #52 的原话：

> *"it is not distributed as part of the anaconda ecosystem"* / *"At present 10X only supports a direct download or a clone of this code repository"*

原因是许可：EULA 不允许再分发，所以进不了 bioconda。**每次升级或换机器都要手工下载。**

### 1.5 三层验证（推荐按顺序）

```bash
cellranger --version        # 1. 最基本的可用性
cellranger sitecheck        # 2. 系统自检，输出可发给 10x 支持
cellranger testrun --id=check_install --localcores=8 --localmem=32   # 3. 官方端到端自检
```

`testrun` 会用自带的迷你参考（`external/cellranger_tiny_ref`）跑一遍完整管线，**成功判据是最后一行 `Pipestance completed successfully!`**。

> [!warning] `.mri.tgz` 不代表失败
> 结束时会生成 `check_install.mri.tgz`（调试包），**成功和失败都会生成**。别看到它就以为挂了，要看 `Pipestance completed successfully!`。

### 1.6 许可要点（官方 EULA 原话归纳）

- 授予 *"limited, non-exclusive, non-transferable, non-sublicensable license"*，**仅以可执行形式提供**，*"Licensee is granted no rights with respect to the Licensed Software source code"*
- 权利*"may be exercised only in connection with a 10x Genomics Product"*，即**只能用于分析 10x 平台产生的数据**
- *"You agree not to redistribute or sublicense the Software"* —— 不能重新分发
- **FOR RESEARCH USE ONLY**
- GitHub 上公开的源码 README 明说 *"made available only for informational purposes. 10x does not provide support for interpreting, modifying, building, or running this code."* —— **不是开源软件**

### 1.7 升级与卸载

```bash
# 升级：平行安装新版本，只改软链（旧版本随时可回退）
tar -xJf cellranger-10.2.0.tar.xz -C ~/.local/share/
ln -sf ~/.local/share/cellranger-10.2.0/cellranger ~/.local/bin/cellranger

# 卸载
rm ~/.local/bin/cellranger && rm -rf ~/.local/share/cellranger-10.1.0
```

---

## 2. 系统要求 vs 本机

官方要求（[system requirements](https://www.10xgenomics.com/support/software/cell-ranger/downloads/cr-system-requirements)）：

| 项   | 官方                                             | 本机                                          | 结论                              |
| --- | ---------------------------------------------- | ------------------------------------------- | ------------------------------- |
| OS  | Ubuntu 20.04/22.04/24.04、Debian 12、RHEL 8/9/10 | Fedora 44 Silverblue（kernel 7.2、glibc 2.43） | 实测可用（跑通 testrun）                |
| CPU | ≥8 核，支持 **AVX+**（AVX2 为未来要求）                   | Ryzen 7 255，16 核，AVX2+AVX512                | ✅                               |
| 内存  | **64 GB（建议 128 GB）**                           | **46 GB**                                   | ⚠️ 低于推荐 → **必须显式 `--localmem`** |
| 磁盘  | **1.5 TB 空闲**                                  | 952 GB 总 / 约 505 GB 空闲                      | ⚠️ 低于推荐 → 单样本够用，别并发多样本          |
| 容器  | 文档未说明支持 Docker/Singularity                     | —                                           | 官方替代方案是 10x Cloud Analysis      |

> [!warning] 默认会吃掉 90% 内存
> local 模式下 Cell Ranger **默认使用 90% 可用内存和全部核心**。本机 46 GB 内存若不限制，容易把机器压死甚至 OOM。固定用法：
> ```bash
> --localcores=8 --localmem=32      # 留出余量，单任务顺序执行
> ```

官方建议的 ulimit（核数大时尤其重要，否则每核 spawn 的进程会撞上限）：

| 项 | 建议值 |
|---|---|
| user open files | ≥ 16384 |
| system max files | ≥ 10000 × 可用 GB 内存 |
| user processes | ≥ 64 × 核数 |

```bash
ulimit -n          # 查当前值
ulimit -n 16384    # 临时提高（写进 shell 配置可持久）
```

---

## 3. 参考基因组

### 3.1 本机选择：官方预构建 2024-A（已装好并校验）

```
~/.cache/refdata-gex-GRCh38-2024-A.tar.gz      下载包 11.5 GB
  md5 a7b5b7ceefe10e435719edc1a8b8b2fa         ← 与官方公布值一致（已核对）
→ ~/Developer/bioinfo/database/refdata-gex-GRCh38-2024-A/    解压后 16 GB
```

理由：`count` 的参考版本会被审稿人追问，官方预构建版本可复现、与已发表结果可比。

解压后核到的实际信息：

| 项 | 值 |
|---|---|
| `reference.json` → `version` / `genomes` | `2024-A` / `GRCh38` |
| `mkref_version` | **8.0.0**（即用 Cell Ranger 8.0.0 构建，在 10.1.0 下正常） |
| 输入注释 | `gencode.v44.primary_assembly.annotation.gtf.filtered`（**GENCODE v44**，已 `mkgtf` 过滤） |
| 输入序列 | `Homo_sapiens.GRCh38.dna.primary_assembly.fa.modified`（Ensembl release-109 FASTA，改过序列头以对齐 GENCODE 命名） |
| 过滤后基因数 | **38,606**（对比全量 Ensembl 116 的 78,941，约减半） |
| STAR 版本 / 索引内容 | 2.7.1a；194 条 contig、38,607 个基因、1,586,951 个外显子、386,483 个剪接位点 |
| 体积构成 | 总计 16 GB = `star/` 13 G（**SA 8.2 G + Genome 3.0 G + SAindex 1.5 G**）+ `fasta/` 3.0 G + `genes/` 59 M |

> [!warning] 染色体命名带 `chr` 前缀
> 2024-A 的 FASTA 与 GTF 都用 **`chr1`/`chr2`** 命名（这是官方把 Ensembl FASTA 头改成 GENCODE 风格的目的）。
> 你 bulk 用的 `GRCh38.116` 是 Ensembl 原生命名 **`1`/`2`**。两边不要把染色体名混着用（例如把参考 `chrName.txt` 跟 `samtools faidx` 出来的名字混拼），否则会找不到序列。

> [!tip] 如何校验参考包完整性（不用重新下载）
> `reference.json` 里记录了 `fasta_hash` 与 `gtf_hash.gz`，用 `sha1sum` 直接比对即可：
> ```bash
> cd ~/Developer/bioinfo/database/refdata-gex-GRCh38-2024-A
> sha1sum fasta/genome.fa genes/genes.gtf.gz
> # 2024-A 实际值：
> # b6f131840f9f337e7b858c3d1e89d7ce0321b243  fasta/genome.fa
> # 432db3ab308171ef215fac5dc4ca40096099a4c6  genes/genes.gtf.gz
> ```
> 两者与 `reference.json` 里的值逐字一致 —— 说明参考包没在传输/解压中损坏。压缩包的 md5 只能证明"下载完整"，这个 sha1 才能证明"解压后内容正确"。

| 版本         | 注释                        | 兼容下限              | 说明     |
| ---------- | ------------------------- | ----------------- | ------ |
| **2024-A** | GENCODE v44 / Ensembl 110 | 不兼容 CR v5.0.1 及更早 | 当前推荐   |
| 2020-A     | GENCODE v32 / Ensembl 98  | 兼容 v3.1.0 及更早     | 老项目复现用 |

### 3.2 为什么官方 2024-A 用 Ensembl **release-109** 的 FASTA（值得记住的坑）

官方 build notes 的原文注释：

```
# Using release 109 for GRCh38 instead of release 110 FASTA
# -- release 110 moved from GRCh38.p13 to GRCh38.p14,
# which unmasked the pseudo-autosomal region. This causes ambiguous mappings to PAR locus genes.
# No other sequence changes were made to the primary assembly.
```

在 GRCh38.**p13** 里 chrY 的 PAR 被硬屏蔽成 `N`，PAR 区 reads 只能唯一比对到 X；**p14 解开了屏蔽**，X 与 Y 的 PAR 序列逐字相同，reads 会两边都命中。本机实测（`database/GRCh38.116/` 的 FASTA 是 p14）：

```console
$ samtools faidx Homo_sapiens.GRCh38.dna.primary_assembly.fa Y:100001-100200
CTAGGGCCAGTGCAGACTCTAAAGGTTGCATAGTCTGCTC      # N=0
$ samtools faidx Homo_sapiens.GRCh38.dna.primary_assembly.fa X:100001-100200
CTAGGGCCAGTGCAGACTCTAAAGGTTGCATAGTCTGCTC      # 与 Y 完全相同
```

配套地，官方 2024-A 还把 **Y 染色体上的 PAR 基因从 GTF 里删掉**，只保留 X 上的拷贝。

> [!note] 对我们的影响
> 用 GRCh38.116（p14）自建 CR 参考时，chrY PAR1 区间有 51 个 gene 注释（实测 `gene_id` 与 X 上无重复，不会触发"重复 gene_id"报错），这些基因会分走一部分本属于 X 的 PAR reads。影响面约 3.2 Mb / 3.1 Gb ≈ **0.1%**，只涉及几十个基因 —— 不是错误，但这是官方为了结果可复现刻意避开的。

### 3.3 附录：自建参考完整流程（备查）

如果将来要用自己的注释版本（比如与 bulk 的 Ensembl 116 严格对齐）：

```bash
# 第 1 步：用 mkgtf 按 biotype 过滤 GTF（可直接吃 .gtf.gz，无需先解压；输出是未压缩 GTF）
cellranger mkgtf input.gtf.gz output.filtered.gtf \
  --attribute=gene_biotype:protein_coding \
  --attribute=gene_biotype:lncRNA \
  --attribute=gene_biotype:antisense \
  --attribute=gene_biotype:IG_LV_gene \
  --attribute=gene_biotype:IG_V_gene \
  --attribute=gene_biotype:IG_V_pseudogene \
  --attribute=gene_biotype:IG_D_gene \
  --attribute=gene_biotype:IG_J_gene \
  --attribute=gene_biotype:IG_J_pseudogene \
  --attribute=gene_biotype:IG_C_gene \
  --attribute=gene_biotype:IG_C_pseudogene \
  --attribute=gene_biotype:TR_V_gene \
  --attribute=gene_biotype:TR_V_pseudogene \
  --attribute=gene_biotype:TR_D_gene \
  --attribute=gene_biotype:TR_J_gene \
  --attribute=gene_biotype:TR_J_pseudogene \
  --attribute=gene_biotype:TR_C_gene

# 第 2 步：建参考包（人类 3 Gb ≈ 8 核时 + 32 GB 内存）
cellranger mkref \
  --genome=GRCh38-116 \
  --fasta=Homo_sapiens.GRCh38.dna.primary_assembly.fa \
  --genes=output.filtered.gtf \
  --nthreads=16 --memgb=32 \
  --output-dir=/var/home/smile/Developer/bioinfo/database/GRCh38.116/cellrangerRef
```

`mkref` 的默认值**对人是偏小的**，必须显式调：`--nthreads` 默认 **1**、`--memgb` 默认 **16**（且必须大于 FASTA 的 gigabase 数）。成功标志：`>>> Reference successfully created! <<<`。

产物结构：`fasta/genome.fa(.fai)`、`genes/genes.gtf.gz`、`reference.json`、`star/`（STAR 索引）。

> [!tip] 上述 16 个 biotype 只是官方清单
> 清单里有些 biotype 在你的注释版本里可能**根本不存在**（如 Ensembl 116 已把 `antisense` 合并进 `lncRNA`，实测 `gene_biotype "antisense"` 出现 0 次）。匹配不到不等于出错，是正常的空集。

**参考版本纪律**：`cellranger aggr` 要求所有输入用**完全相同**的参考文件，混用会报 `TXRNGR10019/10020`。同一个项目从头到尾只用一个参考。

---

### 3.4 参考包内部结构 vs bulk 参考目录（实测）

**常见误解**：以为 10x 的 `refdata-*` 也是"基因组 FASTA + cdna FASTA + gff3 + gtf"那种下载物。**不是** —— 它已经是一个**可直接使用的参考包**（FASTA + 过滤后的 GTF + 预构建 STAR 索引），同一个格式也可以在本地用 `mkref` 生成。

用自带的迷你参考实测（结构与 2024-A 完全一致）：

```
cellranger_tiny_ref/
├── fasta/genome.fa  +  genome.fa.fai
├── genes/genes.gtf.gz
├── reference.json
└── star/                                  ← 预构建的 STAR 索引，占体积大头
    ├── Genome  SA  SAindex
    ├── chrLength.txt  chrName.txt  chrNameLength.txt  chrStart.txt
    ├── exonGeTrInfo.tab  exonInfo.tab  geneInfo.tab  transcriptInfo.tab
    ├── sjdbInfo.txt  sjdbList.out.tab  sjdbList.fromGTF.out.tab
    └── genomeParameters.txt
```

两类目录的对应关系：

| 内容 | bulk 参考目录（`GRCh38.116/`） | Cell Ranger 参考包 |
|---|---|---|
| 基因组 FASTA | `Homo_sapiens.GRCh38.dna.primary_assembly.fa(.gz)` | `fasta/genome.fa` |
| 转录本 FASTA | `Homo_sapiens.GRCh38.cdna.all.fa.gz`（salmon 用） | **不需要** |
| gff3 | `Homo_sapiens.GRCh38.116.gff3.gz` | **不需要**（Cell Ranger 只用 GTF） |
| GTF | `Homo_sapiens.GRCh38.116.gtf.gz`（**全量**） | `genes/genes.gtf.gz`（**已用 `mkgtf` 按 biotype 过滤**） |
| 索引 | `Hisat2Index/`（你自己跑 `hisat2-build`） | `star/`（**10x 已构建好**） |
| 元数据 | — | `reference.json`（记录 fasta/gtf 哈希、mkref 版本、内存） |

`reference.json` 实例（自带迷你参考）：

```json
{
    "fasta_hash": "047e612c2da6fdf35671ad289a97867ec4f0323d",
    "genomes": ["tiny_ref"],
    "gtf_hash.gz": "4dba189e5199f0b0f63e95f08f689ffe9ab22591",
    "mem_gb": 3,
    "mkref_version": "cellranger-cellranger-6.1.0",
    "threads": 1,
    "version": "6.1.2"
}
```

> [!tip] 实测：旧版建的参考能在新版 Cell Ranger 里用
> 上例 `mkref_version` 是 **6.1.0**，而这个参考被 **10.1.0** 的 `testrun` 成功加载并跑通 → 官方"旧版 mkref 建的参考可用于新版管线，反之不保证"在本机得到验证。反过来把 10.1 建的参考拿到 CR 6 上用则会失败。

**为什么 10x 要预构建 STAR 索引**：人类 STAR 索引构建要 32 GB 内存、约 8 核时（整个流程里最重的一步）。预构建后开箱即用，代价就是体积 —— 2024-A 解压后共 **16 GB**，其中 `star/` 占 **13 GB**（`SA` 8.2 G、`Genome` 3.0 G、`SAindex` 1.5 G），而真正的序列文件 `fasta/genome.fa` 只有 3.0 G、注释只有 59 M。换句话说：**参考基因组的主体是索引，不是序列。**

---

## 4. 输入数据要求

### 4.1 FASTQ 命名（最容易踩的坑）

文件名必须符合下面之一：

```
[Sample Name]_S1_L00[Lane Number]_[Read Type]_001.fastq.gz
[Sample Name]_S1_[Read Type]_001.fastq.gz
```

`Read Type` ∈ `I1`（样本 index，可选）、`I2`（可选）、`R1`、`R2`。例如：

```
PBMC_S1_L001_R1_001.fastq.gz   PBMC_S1_L001_R2_001.fastq.gz
```

- `--fastqs` 给**文件夹路径**，`--sample` 给**文件名里的 `[Sample Name]` 前缀**，两者配合筛选
- Cell Ranger 会**递归扫描子目录**找 `*.fastq.gz`，但**子目录里不能有重复的序列文件**
- 多 flowcell：`--fastqs=/path/fc1,/path/fc2 --sample=SampleName`

### 4.2 不要预剪 R1

10x 的 R1 只有 26~28 bp（16 bp 条码 + 10~12 bp UMI）。用 `trim_galore`/`fastp` 按 bulk 那套逻辑去剪 R1 会把条码剪坏，`count` 会直接报条码相关错误或产生垃圾结果。接头修剪交给 Cell Ranger 内置流程，最多单独处理 poly-G。

### 4.3 真实 10x fastq 长什么样（实测）

用 Cell Ranger 自带的迷你数据集（`external/cellranger_tiny_fastq/`）实测到的结构，正好也是命名规范的正例：

| 文件 | 长度 | 内容 |
|---|---|---|
| `tinygex_S1_L001_I1_001.fastq.gz` | **8 bp** | 样本 index（i7），无则没有这个文件 |
| `tinygex_S1_L001_R1_001.fastq.gz` | **28 bp** | **16 bp 细胞条码 + 12 bp UMI**（这是 **v3/NextGEM** 化学；v2 是 16+10=26 bp） |
| `tinygex_S1_L001_R2_001.fastq.gz` | **91 bp** | cDNA（真正的转录本序列） |

两条 lane（L001 230,610 + L002 230,473）= **461,083 reads**，与 `metrics_summary.csv` 里的 `Number of Reads 461,083` 完全一致 —— 这也是判断"read 数是否被正确汇总"的一个对账办法。

---

## 5. `cellranger count`

### 5.1 最常用模板

```bash
cd ~/Developer/bioinfo/project/<项目名>
cellranger count \
  --id=Sample1 \
  --transcriptome=/var/home/smile/Developer/bioinfo/database/refdata-gex-GRCh38-2024-A \
  --fastqs=/path/to/fastq_dir \
  --sample=Sample1 \
  --create-bam=true \
  --localcores=8 --localmem=32
```

### 5.2 参数表（取自本机 10.1.0 的 `--help`）

| 参数 | 含义 | 默认/取值 | 必填 |
|---|---|---|---|
| `--id` | 运行 ID，同时是输出目录名 | `[a-zA-Z0-9_-]+` | ✅ |
| `--transcriptome` | 10x 兼容参考包目录 | — | ✅（官方示例必给） |
| `--fastqs` | FASTQ 所在文件夹（可逗号分隔多路径） | — | ✅ |
| `--sample` | 文件名前缀，用于筛选 FASTQ | — | 实测建议显式给 |
| **`--create-bam`** | 是否生成 BAM；`false` 更省时省空间 | **无默认值，必须给** | ✅ |
| `--expect-cells` | 期望细胞数，作为 cell calling 输入 | 不给则由算法估计 | — |
| `--force-cells` | 强制指定细胞数，绕过 cell calling | 最小 10 | — |
| `--include-introns` | 计数是否包含内含子 reads | **true** | — |
| `--nosecondary` | 关闭二级分析（聚类等） | — | — |
| `--r1-length` / `--r2-length` | 分析前硬截断 read 长度 | — | — |
| `--chemistry` | 化学版本；`auto` 自动识别 | `auto` | — |
| `--libraries` | 用 CSV 声明文库；给了它就别给 `--fastqs`/`--sample` | — | — |
| `--localcores` | 本地任务最大核数 | 默认全部核 | — |
| `--localmem` | 本地任务最大内存（GB） | 默认可用的 90% | 本机建议给 |
| `--jobmode` | `local` / `sge` / `lsf` / `slurm` / 模板路径 | `local` | — |
| `--output-dir` | 输出到指定目录 | 当前目录 | — |
| `--disable-ui` | 不启动 web UI | — | 服务器上建议给 |

其它：`--description`、`--project`、`--lanes`、`--feature-ref`、`--no-libraries`、`--check-library-compatibility`、`--min-crispr-umi`、`--dry`、`--overrides`、`--uiport`、`--noexit`、`--nopreflight`。

`--chemistry` 可选值：`auto`、`threeprime`、`fiveprime`、`SC3Pv1`~`SC3Pv4`、`SC3Pv3HT`、`SC5P-PE(-v3)`、`SC5P-R2(-v3)`、`SC-FB`；**分析 multiome 数据的 GEX 部分必须设为 `ARC-v1`**。

### 5.3 文档与二进制不一致的两处（务必注意）

| 项 | 官方文档写法 | 10.1.0 实际情况 |
|---|---|---|
| `--create-bam` | 参数表"未给默认值"，示例里给了 `=true` | usage 行强制出现：`--create-bam <true\|false>`，**不给就报错** |
| `--nocloupe` | 列为可选参数 | **不存在**（help 里 0 处匹配） |

网上大量教程是 CR 6/7 时代的，直接照抄会踩上面第一行。

---

## 6. 输出文件详解（`<id>/outs/`）

| 文件/目录 | 说明 |
|---|---|
| `web_summary.html` | **首先看这个**：运行摘要 + 图表 |
| `metrics_summary.csv` | 同样指标的 CSV，适合批量汇表 |
| `filtered_feature_bc_matrix/` | **只含判定为细胞的 barcode**，MEX 三件套（`barcodes.tsv.gz` / `features.tsv.gz` / `matrix.mtx.gz`） |
| `filtered_feature_bc_matrix.h5` | 同上，HDF5 格式，大矩阵读写更高效 |
| `raw_feature_bc_matrix/` `raw_...h5` | **固定白名单里所有有 reads 的 barcode**（含空滴背景）→ 清理 ambient RNA 时用 |
| `molecule_info.h5` | 每个分子的信息；**`cellranger aggr` 的必需输入** |
| `possorted_genome_bam.bam(.bai)` | 位置排序、带 barcode 注释的比对 BAM |
| `cloupe.cloupe` | Loupe Browser 可视化文件 |
| `analysis/` | 二级分析产物：`clustering/`、`diffexp/`、`pca/`、`tsne/`、`umap/` |

**filtered vs raw 的官方定义**：raw 是"白名单 barcode 中至少有一个 read 的全部"，filtered 是"只保留被判定为细胞相关的 barcode"。

**三种格式给谁用**：MEX 三件套给第三方包（scanpy/Seurat）；`.h5` 同内容但更高效；`.cloupe` 只给 Loupe Browser。

---

## 7. `web_summary.html` 指标判读

官方阈值主要来自技术说明 **CG000329**（Interpreting Cell Ranger Web Summary Files）。

| 指标 | 含义 | 官方参考范围 |
|---|---|---|
| Estimated Number of Cells | 至少关联一个细胞的 barcode 数 | 期望 500–10,000；不确定时官方建议**宁可高估** |
| Mean / Median Reads per Cell | 总 reads ÷ 细胞数 | ≥ 20,000 reads/cell |
| Median Genes per Cell | 每细胞检出基因数中位数（≥1 UMI 即算） | 随细胞类型与深度变化，无固定阈值 |
| Median UMI Counts per Cell | 每细胞 UMI 中位数 | 同上 |
| Total Genes Detected | 任一细胞中 ≥1 UMI 的基因数 | 同上 |
| Valid Barcodes | 条码纠错后匹配白名单的比例 | **> 75%** |
| Valid UMIs | UMI 无 N 且非同聚物的比例 | **> 75%** |
| Q30 Bases in Barcode / UMI | Q≥30 碱基比例 | 取决于测序平台；偏低提示上样浓度问题 |
| Q30 Bases in RNA Read | 同上（R2） | 理想 **> 65%** |
| Sequencing Saturation | 来自已观测 UMI 的 reads 比例 | **官方明确不给固定目标**，取决于文库复杂度与深度 |
| Fraction Reads in Cells | 有效条码 + 可信比对 + 细胞条码的 reads 比例 | **> 70%**；偏低说明 ambient RNA 大量进入 |
| Reads Mapped to Genome | 比对到基因组的比例 | 人/鼠宜 **> 85%** |
| Reads Mapped Confidently to Genome | 唯一比对比例 | 应接近上一项 |
| Reads Mapped Confidently to Transcriptome | 唯一比对到转录组且符合注释剪接位点（**UMI 计数用这个**） | 理想 **> 30%** |
| Reads Mapped Confidently to Intronic/Exonic | 内含子/外显子比例 | 低 RNA 样本（PBMC、单核）内含子偏高正常 |
| Reads Mapped Confidently to Intergenic | 基因间区比例 | 好样本应低 |
| Reads Mapped Antisense to Gene | 反义链比例 | 理想 **< 10%**；偏高提示参考或化学出错 |

**Barcode Rank Plot** 是判断细胞数是否合理的关键图：健康的"断崖+拐点"（cliff and knee）表示细胞与空滴分离良好；双峰形态提示样本异质。

> [!warning] 不要用 testrun 的数字判断质量
> 本机自检是极小测试数据，指标长这样（仅作"指标长什么样"的示例）：
> `Estimated Number of Cells 1,084`｜`Mean Reads per Cell 425`｜`Median Genes per Cell 12`｜`Valid Barcodes 94.8%`｜`Fraction Reads in Cells 93.9%`
> 这些数字远低于正常阈值**不代表安装有问题** —— 自检只看 `Pipestance completed successfully!`。

---

## 8. 其它子命令

| 子命令 | 用途 | 什么时候用 |
|---|---|---|
| `count` | 单样本 / 单 GEM well 的 GEX + Feature Barcode 计数 | 常规单样本 |
| `multi` | 多重样本、GEX+VDJ+Feature Barcode 联合分析（CSV 配置驱动） | Flex / BEAM / CellPlex / 组合多组学（`count` 不支持） |
| `multi-template` | 生成 multi 的配置 CSV 模板 | 配 multi 时 |
| `vdj` | 5′ V(D)J 组装，输出 `.vloupe` | 只有 V(D)J 库、无 GEX |
| `aggr` | 合并多个 count/multi/vdj 运行 | 多样本汇总成一个矩阵 |
| `reanalyze` | 只重做二级分析（PCA/聚类/UMAP），不重跑比对与计数 | 改聚类参数、换基因子集 |
| `annotate` | 自动细胞类型注释（10.1 新增，Pan-Human Azimuth 模型） | 想快速得到细胞类型 |
| `mkref` / `mkgtf` | 自建参考包 / 按 biotype 过滤 GTF | 用自己的注释版本（见 §3.3） |
| `mkvdjref` | 建 V(D)J 参考 | V(D)J 自建参考 |
| `testrun` | 安装自检 | 装完立刻跑一次 |
| `sitecheck` | 收集系统配置信息 | 报 bug 给 10x 支持时 |
| `mat2csv` | 矩阵转 CSV | 需要文本格式 |
| `upload` | 把调试包发给 10x 支持 | 出问题求助时 |
| `cloud` | 10x Cloud CLI | 用云端分析 |
| `telemetry` | 遥测开关（`cellranger telemetry disable`） | 介意隐私/离线环境 |

<!-- 说明：cellranger versions 子命令在 10.1.0 不存在（实测 error: unrecognized subcommand）。 -->

### 8.1 `multi` 的配置 CSV

分节（最多五节 + samples）：

```csv
[gene-expression]
reference,/path/refdata-gex-GRCh38-2024-A
create-bam,true

[feature]
reference,/path/feature_ref.csv

[vdj]
reference,/path/refdata-cellranger-vdj-GRCh38-alts-ensembl-7.1.0

[libraries]
fastq_id,fastqs,feature_types
Sample1_gex,/path/fastq_dir,Gene Expression
Sample1_ab,/path/fastq_dir,Antibody Capture
```

`[libraries]` 的 `feature_types` 取值：`Gene Expression`、`Antibody Capture`、`CRISPR Guide Capture`、`Multiplexing Capture`、`VDJ`、`VDJ-T`、`VDJ-T-GD`、`VDJ-B`、`Antigen Capture`、`Custom`。

> [!warning] TRG/TRD 链必须显式写 `VDJ-T-GD`
> 自动检测对 TRG/TRD 无效，写错会导致该库 **零 barcode**。

### 8.2 `aggr` 的输入 CSV

v6.0 起表头是 `sample_id,molecule_h5`（旧版为 `library_id`）：

```csv
sample_id,molecule_h5
LV123,/opt/runs/LV123/outs/molecule_info.h5
Sample1,/opt/runs/Run1/outs/per_sample_outs/Sample1/sample_molecule_info.h5
```

- `count` 输出 → `outs/molecule_info.h5`
- `multi` 输出 → `outs/per_sample_outs/<Sample>/sample_molecule_info.h5`
- `vdj` 输出 → `outs/vdj_contig_info.pb`（表头 `sample_id,vdj_contig_info,donor,origin`）
- **给的是单个文件，不是整个 `outs/` 目录**
- 额外列会自动成为 category 列；名为 `batch` 的列启用化学批次校正
- `--normalize` 默认 `mapped`（按测序深度归一化），可选 `none`

---

## 9. 排错与常见坑

### 9.1 失败分类

- **Alert 两级**：`WARNING` = 参数次优但数据可能仍可用；`ERROR` = 重大问题，输出多半不可用。**alert 不阻断流程**。
- **失败两类**：`Preflight`（输入/参数非法，通常无输出）与 `In-flight`（运行中外部因素，如内存或磁盘耗尽，报错因 stage 而异）。

### 9.2 本机约束（最重要）

```bash
# 本机 46 GB 内存 / 505 GB 空闲，必须主动限制，否则默认吃 90% 内存
--localcores=8 --localmem=32
```

并提前提高 `ulimit -n`（建议 16384），避免核数大时文件描述符耗尽。

### 9.3 常见报错与处理

| 现象 | 原因 | 处理 |
|---|---|---|
| 报错说 `--create-bam` 缺失 | 10.1.0 把它改成必填 | 显式加 `--create-bam=true` |
| 找不到 fastq / 细胞数极低 | 文件名不符合命名规范，或 `--sample` 前缀不匹配 | 按 §4.1 改名，`--sample` 与文件名前缀严格一致 |
| `TXRNGR10004 / 10009 / 10013` | read 长度不兼容、R1 长度混杂、fastq header 不同步 | 检查原始数据是否被错误修剪/拼接 |
| `TXRNGR10019 / 10020` | `aggr` 的输入用了**不同参考文件** | 同一项目统一参考 |
| `TXRNGR10014 / 10017` | `feature_type` 与 feature reference 不符 | 核对 antibody/CRISPR 参考 |
| `Reads Mapped to Genome` 异常低 | 参考选错、物种搞错、文库质量差 | 人样品不要用人+鼠混合参考 |
| OOM 被杀 | 未限制内存 | `--localmem` + `--localcores` |
| 磁盘写满 | 工作空间不足（BAM 很占空间） | `--create-bam=false` 或清理旧 pipestance |
| 饱和度低 | 深度不够或文库复杂度低 | 加测序量；官方无固定阈值 |
| 细胞数异常（多/少） | cell calling 判错、空滴/低 RNA 细胞 | 看 Barcode Rank Plot；低 RNA 细胞可 `--force-cells` 后人工过滤 |

### 9.4 调参建议

- 不确定细胞数：**宁可高估**（官方建议），事后在 Loupe Browser / scanpy 里过滤背景
- 想快速验证流程：`--nosecondary`（跳过聚类）+ `--create-bam=false`（不写 BAM）
- 服务器无图形界面：`--disable-ui`
- 只想重跑聚类：用 `reanalyze`，**不要重跑 count**

---

## 10. 下游衔接（scanpy / Seurat）

```python
# scanpy：直接读 outs/ 下的 MEX 三件套
import scanpy as sc
adata = sc.read_10x_mtx(
    "Sample1/outs/filtered_feature_bc_matrix",   # 目录
    var_names="gene_symbols",
    cache=True,
)
adata.var_names_make_unique()
```

```r
# Seurat
library(Seurat)
mat <- Read10X(data.dir = "Sample1/outs/filtered_feature_bc_matrix")
obj <- CreateSeuratObject(counts = mat, project = "Sample1")
```

> [!warning] 差异表达不要直接把所有细胞喂给 edgeR/DESeq2
> 上千个细胞不是独立生物学重复（pseudoreplication，p 值会严重虚高）。正确做法是 **pseudobulk**（按样本/细胞类型汇总成矩阵）后再用 bulk 差异分析工具，或改用 Wilcoxon / MAST。

---

## 11. 速查表

```bash
cellranger --version                       # 版本
cellranger sitecheck                       # 系统自检
cellranger testrun --id=check --localcores=8 --localmem=32   # 安装自检
cellranger count --id=S1 --transcriptome=REF --fastqs=DIR --sample=S1 \
                 --create-bam=true --localcores=8 --localmem=32
cellranger multi --id=M1 --csv=config.csv --localcores=8 --localmem=32
cellranger aggr  --id=A1 --csv=aggr.csv
cellranger reanalyze --id=R1 --matrix=S1/outs/filtered_feature_bc_matrix.h5
cellranger mkgtf in.gtf out.gtf --attribute=gene_biotype:protein_coding
cellranger mkref --genome=G --fasta=f.fa --genes=g.gtf --nthreads=16 --memgb=32
cellranger telemetry disable               # 关闭遥测
```

**产出检查清单**（每次跑完按顺序看）
1. 最后一行是否 `Pipestance completed successfully!`
2. `outs/web_summary.html`：Estimated Number of Cells / Median Genes / Fraction Reads in Cells
3. `outs/metrics_summary.csv`：Valid Barcodes > 75%？Mapped to Genome > 85%？（人/鼠）
4. `outs/filtered_feature_bc_matrix/` 三件套是否齐全

---

## 12. 来源

| 内容 | 链接 |
|---|---|
| 下载页（版本/md5/签名 curl） | <https://www.10xgenomics.com/support/software/cell-ranger/downloads> |
| 系统要求 | <https://www.10xgenomics.com/support/software/cell-ranger/downloads/cr-system-requirements> |
| 安装教程 | <https://www.10xgenomics.com/support/software/cell-ranger/latest/tutorials/cr-tutorial-in> |
| 参考包构建（含 PAR 说明） | <https://www.10xgenomics.com/support/software/cell-ranger/downloads/cr-ref-build-steps> |
| 参考版本 release notes | <https://www.10xgenomics.com/support/software/cell-ranger/latest/release-notes/cr-reference-release-notes> |
| count 管线 | <https://www.10xgenomics.com/support/software/cell-ranger/latest/analysis/running-pipelines/cr-gex-count> |
| 输出文件总览 | <https://www.10xgenomics.com/support/software/cell-ranger/latest/analysis/outputs/cr-outputs-gex-overview> |
| FASTQ 命名规范 | <https://www.10xgenomics.com/support/software/cell-ranger/latest/analysis/inputs/cr-specifying-fastqs> |
| 指标判读技术说明 CG000329 | <https://cdn.10xgenomics.com/image/upload/v1660261286/support-documents/CG000329_TechnicalNote_InterpretingCellRangerWebSummaryFiles_RevA.pdf> |
| 排错指南 | <https://www.10xgenomics.com/support/software/cell-ranger/latest/resources/cr-troubleshooting> |
| 错误码 | <https://www.10xgenomics.com/support/software/cell-ranger/latest/resources/cr-error-codes> |
| EULA | <https://www.10xgenomics.com/legal/end-user-software-license-agreement> |
| 源码仓库（仅信息用途） | <https://github.com/10XGenomics/cellranger> |
