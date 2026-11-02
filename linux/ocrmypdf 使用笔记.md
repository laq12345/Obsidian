# ocrmypdf 使用笔记

## 它是干什么的

给**扫描版 PDF**（一页一张图、文字选不中）叠加一层**隐形文本层**。

```
扫描件 = 一堆图片  →  人眼能看，机器读不到
ocrmypdf          →  Tesseract 识别图片里的字，在原图上叠一层看不见的文本
```

结果：**画面完全不变**，但文件变得——

- 文字可选中、可复制
- `Ctrl+F` 可全文搜索
- 可以喂给 `p2z`（pdf2zh）翻译

它本身不是 OCR 引擎，是 Tesseract 的流水线包装（含纠偏、去噪、旋转、PDF/A 输出）。

---

## 我这台机器的环境

**不在宿主机装**，跑在 toolbox 容器里（避免污染系统 PATH 和 Python）。

| 项 | 值 |
|---|---|
| 引擎 | **podman 镜像** `docker.io/jbarlow83/ocrmypdf:v17.13.0` |
| ocrmypdf | **17.13.0**（官方镜像）|
| tesseract | 5.5.0（镜像内置）|
| 中文模型 | 镜像自带 `chi_sim`（2.4 MB 标准版即可，实测 0 空格）|
| 宿主机 wrapper | `~/.local/bin/ocrpdf` |
| 默认参数 | `-l chi_sim+eng --deskew` |

> **2026-10-27 换引擎**：原先用 Fedora toolbox 里的 ocrmypdf 16.13，中文识别**词内空格多达 43 个/页**
> （「尽管 封面上只 有 我 一 个 人 的 名 字」）。换成官方镜像的 17.13 后**降到 0**。
> 与 tesseract 版本无关（镜像里的 tesseract 反而更旧 5.5.0），与语言模型也无关
> （镜像自带 2.4 MB 标准模型就够）—— 是 ocrmypdf 16→17 在图像预处理/hOCR 解析上的改进。

`ocrpdf` 里已封装好容器调用，**宿主机直接敲就行**，不用每次写 `toolbox run`。

---

## 快速开始

```bash
# 标准用法（中英混排）
ocrpdf 扫描书.pdf 可搜索书.pdf

# 只处理没有文本层的页（已有文本的页原样保留，最省时）
ocrpdf 书.pdf 输出.pdf --skip-text

# 只处理前 50 页试水
ocrpdf 书.pdf 输出.pdf --pages 1-50 --skip-text

# 英文书（跳过中文模型，更快更准）
OCRPDF_LANGS=eng ocrpdf 英文书.pdf 输出.pdf

# 快速模式：不纠偏 + 跳过 PDF/A（体积约减半、快 20%）
OCRPDF_FAST=1 ocrpdf 扫描书.pdf

# 看内置帮助
ocrpdf
```

---

## 第一步永远是：判断需不需要 OCR

```bash
pdftotext -f 1 -l 3 文件.pdf - | tr -d '[:space:]' | wc -c
```

| 输出 | 结论 |
|---|---|
| `< 200` | 纯图像，**需要 OCR** |
| 上千 | 已有文本层，**直接 p2z 翻译就行** |

另一个更直观的判断：**在阅读器里能不能选中文字**。选不中 = 需要 OCR。

> 期刊论文（AJP、PMID 系列）几乎都有文本层，不需要 OCR。
> 只有扫描书、影印版、复印件才需要。

---

## 常用参数

| 参数                          | 作用                     | 建议                                 |
| --------------------------- | ---------------------- | ---------------------------------- |
| `--skip-text`               | 已有文本层的页跳过              | **wrapper 已默认开启**（否则遇到自带文本的页会直接中止） |
| `--pages 1-50`              | 只 OCR 指定页，其余原样复制       | 试水、省时间                             |
| `--redo-ocr`                | 强制重做已有文本层（旧 OCR 质量差时用） | 少用                                 |
| `--deskew`                  | 自动纠正倾斜扫描               | 默认已开                               |
| `--rotate-pages`            | 自动把倒置/横放的页转正           | 扫描仪歪了时加                            |
| `--clean`                   | 去噪重编码                  | **清晰扫描件不需要**，会让文件变大、变慢             |
| `-O1/-O2/-O3`               | 图像优化级别（速度↔体积）          | 想文件小用 `-O2`                        |
| `--output-type pdfa`        | 转 PDF/A 归档格式           | 长期存档用，否则默认即可                       |
| `--output-type pdf`         | 普通 PDF                 | 想避免 PDF/A 转换警告用这个                  |
| `--tesseract-pagesegmode 6` | 分页模式：6=单栏正文            | 默认已设，中文断词更好                        |

### 语言怎么选（影响速度 3–5 倍）

| 书的类型 | 参数 |
|---|---|
| 英文书（含技术书）| `OCRPDF_LANGS=eng ocrpdf ...`（镜像自带 eng，无需额外装）|
| 中文书 | `OCRPDF_LANGS=chi_sim ocrpdf ...` |
| 中英混排 | 默认 `chi_sim+eng`（最慢）|

**英文书千万别用默认的 `chi_sim+eng`** —— 中文模型体积是英文的 5 倍，识别时还会尝试匹配汉字，纯属浪费。

> 2026-10-27 实测：1008 页英文技术书用 `chi_sim+eng` 跑了 **13 分钟**，输出 166 MB。

**词内空格问题的新旧对比（同一页中文《社会心理学》第 20 页）：**

| 引擎 | 词内空格 | 有效字符 |
|---|---|---|
| Fedora toolbox（ocrmypdf 16.13 + tesseract 5.5.3）| **43** | 4053 |
| podman 镜像（ocrmypdf 17.13 + tesseract 5.5.0）| **0** | 4044 |

> 参数调优（psm 3/6、oem 1、oversample 600）对 16.13 完全无效（43→42），所以差异在 ocrmypdf 版本本身。

**参数与体积的取舍（同 8 页中文样本，podman 17.13）：**

| 配置                                      | 耗时          | 体积         |
| --------------------------------------- | ----------- | ---------- |
| 默认（`--skip-text --deskew` + auto PDF/A） | 9456 ms     | 4.3 MB     |
| `--output-type pdf`                     | 9233 ms     | 4.3 MB     |
| **`--no-deskew`（= `OCRPDF_FAST=1`）**    | **7521 ms** | **2.2 MB** |
| `--no-deskew -O2`                       | 7876 ms     | 2.2 MB     |

→ **`--no-deskew` 是唯一有实质收益的优化**（体积减半、快 20%），前提是扫描件不歪。
→ `--output-type pdf` 单独只快 2.4%（PDF/A 尝试本来就秒失败）；`-O2` 无额外收益。
→ 但对 **PDF/A 能成功的大书**（如 1008 页那本走 Ghostscript 逐页），`--output-type pdf` 能省掉整段转换。


**容器版注意**：`jbig2` 可选依赖没装，部分图像优化做不了（只影响体积，不影响质量）。

---

## 实测数据（2026-10-27，本机）

测试对象：《社会心理学》扫描版，745 页，299 dpi 彩色 JPEG。

| 项目 | 结果 |
|---|---|
| 速度 | **3 页 / 8 秒** → 745 页约 **33 分钟** |
| 文件体积 | 约 1.5 倍（`--deskew` 触发重编码）|
| 中文正文 | ★★★☆ 可用，**但词内残留空格约 20%** |
| 英文/人名/机构 | ★★★★ 几乎全对 |
| 封面/插图/艺术字页 | ★ 基本乱码（正常，不必强求） |
| 代码块 / 公式 | ★ **会毁掉**，技术书别做 |

中文识别样例：

```
尽管 封面上只 有 我 一 个 人的 名 字 ,但 事实上, 这 本 书 是 很 多 心理 学 工作 者 集体 智慧 的 结晶。
```

**英文技术书的实测（1008 页《UNIX/Linux 系统管理技术手册》）**：

```
$ python dictionary
The ordinal array contains (1: 'first', 2: 'second', 3: 'third')
The ordinal of 1 is first
```

→ 英文/代码识别比预期好得多，命令行也能对上；中文「脚本 编程」带词内空格。
**结论：技术书 OCR 后用于「选中文字高亮 + Ctrl+F 搜索」完全够用**，只要不指望复制代码拿去跑。


对比同配置但用 brew 版（ocrmypdf 17.13 + tesseract 5.5.3）：

```
尽管封面上只有我一个人的名字 , 但事实上, 这本书是很多心理学工作者集体智慧的结晶。
```

差异来自容器里 tesseract 版本较旧，**换模型救不回来**。取舍：为这点质量去维护 1.1 GB 的 brew 依赖不值得。

**词内空格的实际影响**：`Ctrl+F` 搜两字词命中率约 70–80%（搜「尽管」能中，搜「一个人」可能不中）。**不影响阅读，只影响检索精度。**

---

## 什么书该做、什么不该做

| 类型 | 建议 |
|---|---|
| 纯中文小说 / 社科书 | ✅ 值得（换取全书可搜索）|
| 英文正文书 | ✅ 值得 |
| **技术书（代码、命令、公式）** | ❌ 别做，改用原生 EPUB/PDF 版本 |
| **EPUB** | ❌ 完全不需要（天生是文本，Foliate 直接读）|
| 期刊论文 | ❌ 通常已有文本层 |

> 技术书的正确解法是**找原生版本**，不是 OCR。
> z-lib、Anna's Archive 上同一本书常有多个版本。

---

## 典型工作流

```
纸质文献 / 扫描书
   ↓  手机扫描 App（微信「扫一扫 → 扫描件」/ Genius Scan / OpenScan）
图像型 PDF
   ↓  ocrpdf 扫描件.pdf 可搜索.pdf
带隐形文本层的 PDF（可选中、可搜索）
   ↓  p2z 可搜索.pdf
双语 PDF（原文页 / 译文页交替）→ 文档查看器打开
```

---

## 坑与注意

1. **竖排中文**需要额外的 `chi_sim_vert` 模型，**已于 2026-10-27 装入容器**（13 MB）。
   之前处理中文书时会刷一屏 `Failed loading language 'chi_sim_vert'` —— 那是 **16 个并发 worker 各自找不到竖排模型**的提示，不是真失败（Tesseract 会自动回退到横排 `chi_sim`，OCR 照常完成）。
2. **`PriorOcrFoundError: page N already has text!`** —— PDF 某页自带文本层（常见于扫描书附带的导航页/目录页），
   ocrmypdf 默认拒绝覆盖而中止。**wrapper 现在默认带 `--skip-text`，不会再遇到**；
   若确实要重做那几页，用 `--redo-ocr`；要强制覆盖全部用 `--force-ocr`。
3. **PDF/A 转换失败是正常的**：输入含未嵌入的 CID 字体（如 `STSong-Light-Acro`）时，ocrmypdf 会自动降级成普通 PDF，并打一条提示。不影响结果。
4. **`--deskew` 会让文件变大**（约 1.5×），因为它重编码图像。不需要纠偏就用 `--no-deskew`。
5. **`--clean` 别乱加**：它做去噪 + 重编码，对清晰扫描件纯属浪费时间和体积。
6. **容器冷启动慢**：第一次调用要 5–15 秒起容器，之后很快。
7. **一次性任务别留容器**：用完 `toolbox rm fedora-toolbox-44` 就干净了（但要先看下面的恢复步骤）。

---

## ⚠️ 环境重建 / 更新

镜像和 wrapper 都不在容器里，所以 **`toolbox rm` 不会影响 OCR 能力**。需要重建时：

```bash
# 1) 拉镜像（约 443 MB 压缩后；TUN 代理下可能要十几分钟）
podman pull docker.io/jbarlow83/ocrmypdf:v17.13.0

# 2) wrapper 若丢失，重建（见本笔记开头的脚本）
#    核心调用：
podman run --rm --userns=keep-id \
  -v "$in_dir:/in:Z" -v "$out_dir:/out:Z" \
  docker.io/jbarlow83/ocrmypdf:v17.13.0 \
  -l chi_sim+eng --deskew "/in/in.pdf" "/out/out.pdf"
```

**几个必须记住的坑：**

| 坑 | 说明 |
|---|---|
| **必须用完整镜像名** | `docker.io/jbarlow83/ocrmypdf:v17.13.0`。短名会触发 podman 的 TTY 交互确认，非交互环境直接报错 |
| **ENTRYPOINT 就是 ocrmypdf** | 调用时**不要**再写 `ocrmypdf`，直接给参数。要跑别的命令得 `--entrypoint tesseract` |
| **`--userns=keep-id` 必需** | 镜像默认用户是 `app`，不映射 uid 会导致 `OutputFileAccessError: not a writable file` |
| **挂载 `/tmp` 会撞 SELinux** | `:Z` 不允许 relabel `/tmp`。用 home 下的目录 |
| **镜像自带 chi_sim** | 不用挂载语言模型（标准 2.4 MB 版实测 0 空格）|

更新镜像（如出 18.x）：改 tag 后重新拉，wrapper 里 `OCRPDF_IMG` 环境变量可覆盖。

---

## 与替代方案对比

| 方案 | 排版 | 速度 | 中文质量 | 系统污染 |
|---|---|---|---|---|
| **ocrmypdf（podman 镜像 17.13）** | 保留原图 | 1 页/6 秒 | ★★★★★（0 词内空格）| 零 |
| ocrmypdf（brew，已弃用）| 同上 | 3 页/20 秒 | ★★★★ | 1.1 GB + PATH 污染 |
| ocrmypdf（Fedora 包 16.13）| 同上 | 3 页/8 秒 | ★★★（43 词内空格）| 层叠系统包 |
| 在线 OCR（百度/腾讯） | 不保留 | 快 | ★★★★ | 隐私风险 |
| 换原生 EPUB/PDF | — | 零 | — | 无需 OCR 最好 |

**结论**：容器方案是"零污染 + 够用质量"的最佳平衡点。除非有大量 OCR 需求，不要再装到宿主机。

---

## 相关笔记

- `p2z`（pdf2zh）：PDF 整篇翻译，生成双语 PDF
- 文档查看器（Papers）：GNOME 51 自带，`org.gnome.Papers`
- Zotero：文献管理 + 划词翻译（DeepSeek）
