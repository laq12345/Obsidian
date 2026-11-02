# pdf2zh 使用笔记（命令行 + Zotero 插件）

## 概览

两个入口，**同一个引擎**：

```
┌─ 命令行 ─────────────────────────────────────────┐
│  p2z 论文.pdf                                    │
└──────────────────┬───────────────────────────────┘
                   ↓
        ~/.venvs/pdf2zh-next/bin/pdf2zh_next
                   ↑        （pdf2zh-next 2.9.0 / BabelDOC 0.6.x 内核）
                   ↓
┌─ Zotero 内 ──────┴───────────────────────────────┐
│  右键 → PDF2zh → 翻译                             │
│    ↓                                             │
│  p2zserver（Flask，端口 8890）                    │
└──────────────────────────────────────────────────┘
```

**关键：只有一份引擎环境** `~/.venvs/pdf2zh-next`，两边共用，没有重复安装。

> 2026-10-28 从旧版 `pdf2zh 1.9.11` 全量迁移到 `pdf2zh-next 2.9.0`。旧版已卸载。

---

## 一、命令行：`p2z`

### 基本用法

```bash
p2z 论文.pdf                  # 默认输出到 <源文件目录>/translated/
p2z 论文.pdf  --pages 1-10    # 只翻前 10 页
p2z *.pdf -o ~/Documents/翻译  # 批量 + 指定输出目录
p2z                          # 看帮助
```

### 输出 3 个文件

| 文件 | 内容 |
|---|---|
| `xxx.zh.dual.pdf` | **段落级双语对照**（英文段落下方直接接中文，不是页级交替）|
| `xxx.zh.mono.pdf` | 纯中文 |
| `xxx.zh.glossary.csv` | **自动术语表**（如 `Piezo channels → Piezo通道`）|

### 参数速查

| 参数 | 作用 |
|---|---|
| `-o <dir>` | 输出目录（默认 `<源文件目录>/translated/`）|
| `--pages 1-10` | 只翻指定页 |
| `--pool-max-workers N` | 并发数（旧版的 `-t`）|
| `--ignore-cache` | 忽略缓存强制重翻 |
| `--no-dual` / `--no-mono` | 不生成双语版 / 纯中文版 |
| `--translate-table-text` | 连表格文字一起翻（更慢）|
| `--ocr-workaround` | 扫描件兼容模式 |

**旧参数会自动映射**：`-t N` → `--pool-max-workers N`，`--babeldoc` 被忽略（已是默认内核），`-s xxx` 被忽略（引擎固定 deepseek）。

### 清理产物：`p2z clean`

翻译产物会一直堆积（一篇论文动辄几十 MB），用这个清：

```bash
p2z clean                 # 清当前目录的 translated/
p2z clean ~/Downloads     # 清指定目录的 translated/
p2z clean --server        # 清 Zotero 插件服务的译文残留
p2z clean --all           # 当前目录 + Zotero server 一起清
p2z clean -n              # dry-run：只看会删什么
p2z clean -y              # 跳过确认（脚本里用）
```

行为约定：

- 只删 `translated/` **里面的文件**，目录本身保留
- **不碰源 PDF**，也不碰 `-o` 指定的自定义输出目录之外的东西
- 默认先列清单（文件数 + 体积）并要 `y/N` 确认

实际输出长这样：

```
将要清理（目录保留，只删里面的文件）:
  ~/.local/share/zotero-pdf2zh/translated   12 个文件  121M
确认删除这 12 个文件？[y/N]
```

### 实测数据（2026-10-28，本机）

| 项 | pdf2zh 1.9.11（旧，已卸）| **pdf2zh-next 2.9.0（现用）** |
|---|---|---|
| 速度 | 25 秒/页 | **54 秒/页（慢 2.2 倍）** |
| 首次运行额外开销 | — | **+95 秒**（模型加载）|
| 页脚/下载信息 | ❌ 保留英文 | ✅ **翻译**（"首次发表于2024年8月27日"）|
| 术语一致性 | 无 | ✅ **glossary.csv** |
| 双语形式 | 页级交替 | **段落级对照** |
| 水印 | 无 | 默认有，已用 `--watermark-output-mode no_watermark` 关掉 |

一篇 10 页论文约 **9 分钟**（旧版 4 分钟）。换来的是脚注翻译 + 术语表 + 段落对照，读医学文献值得。

---

## 二、Zotero 插件

### 启动 / 停止 server

**日常用前台版**（彩色日志直达终端，和官方文档演示一样）：

```bash
p2zserver          # 前台运行，Ctrl+C 停止
```

**需要它自己待在后台**（不占终端、可无人值守）时用 systemd：

```bash
systemctl --user start p2z
systemctl --user stop p2z
systemctl --user status p2z
```

两者不冲突：`p2zserver` 检测到后台服务在跑会先自动 `stop` 再前台启动。

`p2z.service` 位于 `~/.config/systemd/user/p2z.service`，关键配置：

```ini
[Service]
WorkingDirectory=%h/.local/share/zotero-pdf2zh
Environment="PATH=%h/.venvs/pdf2zh-next/bin:%h/.local/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=%h/.local/share/zotero-pdf2zh/.venv/bin/python server.py \
    --enable_venv false --port 8890 --check_update false
Restart=on-failure
StandardOutput=append:%h/.cache/p2zserver.log

[Install]
WantedBy=default.target
```

- **`--enable_venv false`** 是关键：不新建环境，直接用 `~/.venvs/pdf2zh-next`
- **`--check_update false`**：不联网问 gitee 有没有新版本（否则网络差时启动会卡 30 秒以上）
- **`[Install]` 段存在但没有 `enable`** → `systemctl --user is-enabled p2z` 返回 `disabled`，开机不自启
- `Restart=on-failure` 只管进程崩溃，与开机自启无关
- 日志在 `~/.cache/p2zserver.log`（不放 `/tmp`，重启不会被清）

也可以直接用 systemctl：

```bash
systemctl --user start p2z
systemctl --user stop p2z
systemctl --user status p2z
```

> 如果哪天想改成开机自启：`systemctl --user enable p2z`。改回：`systemctl --user disable p2z`。

### 插件配置（3 项）

Zotero → **编辑 → 设置 → PDF2zh**：

| 项 | 填什么 |
|---|---|
| 端口 / 服务地址 | `8890`（**不是 47700**）|
| 翻译引擎 | **`pdf2zh_next`** |
| 翻译服务 | `deepseek` |

填完点「测试连接」。API Key 不用在插件里填 —— 已在 server 的 `config.toml` 里配好。

### 使用

```
Zotero 里右键文献条目（或 PDF 附件）→ PDF2zh → 翻译
   ↓ server 终端显示进度条
   ↓ 约 54 秒/页
   ↓ 双语 PDF 自动挂成该条目的子附件
```

浏览器打开 `http://127.0.0.1:8890` 可以看翻译进度和历史记录。

### 停止

前台运行时按 `Ctrl+C`；后台服务用 `systemctl --user stop p2z`。

**server 没起时，插件点翻译会报 `NetworkError when attempting to fetch resource`** —— 看到这个错就直接 `p2zserver`。

> 系统重启后 server 不会自动回来（systemd 那边是 `disabled`），需要重新 `p2zserver`。

---

## 三、配置文件

### Server 的配置：`~/.local/share/zotero-pdf2zh/config/config.toml`

权限必须 600（含明文 key）。关键字段：

```toml
deepseek = true                      # 翻译引擎
term_deepseek = true                 # 术语提取引擎

lang_out = "zh-CN"
watermark_output_mode = "no_watermark"   # 模板默认已关

[deepseek_detail]
translate_engine_type = "DeepSeek"
deepseek_model = "deepseek-flash"        # 模板默认 "deepseek-v4-flash"，不是 API 接受的 ID！
deepseek_api_key = "sk-..."

[term_deepseek_detail]
translate_engine_type = "DeepSeek"
term_deepseek_model = "deepseek-flash"   # 同样要改
term_deepseek_api_key = "sk-..."         # 默认是字符串 "null"，必须替换
```

> ⚠️ **两处 key 都要填**。只填翻译引擎的 key，术语提取引擎会报 `ValueError: DeepSeek API key is required`。

### `p2z` 的配置

| 位置 | 用途 |
|---|---|
| `~/.config/PDFMathTranslate/prompt-medical.txt` | 医学提示词，`p2z` 读它传给 `--custom-system-prompt` |
| `~/.config/pdf2zh/default/2.9.0.toml` | pdf2zh-next 自己的配置（命令行时用）|

> `p2z` 里的 key/model 写成默认值，可用 `DEEPSEEK_API_KEY` / `DEEPSEEK_MODEL` 环境变量覆盖。

---

## 四、坑与常见错误

### ① `cannot import name 'BitStream' from 'bitstring'`

```
File ".../babeldoc/document_il/backend/pdf_creater.py", line 9
    from bitstring import BitStream
ImportError: cannot import name 'BitStream'
```

`bitstring 5.x` 移除了 `BitStream`，而 BabelDOC 还在用。修复：

```bash
uv pip install --python ~/.venvs/pdf2zh-next/bin/python "bitstring<4.2"
```

> 每次 `uv pip install -U pdf2zh-next` 升级后都要重跑这条。旧 pdf2zh 也踩过同一个坑。

### ② `ValueError: DeepSeek API key is required`

服务端 traceback 里出现这行 → **术语提取引擎的 key 没配**（见上面 config.toml）。
注意 `term_deepseek_api_key` 的默认值是字符串 `"null"`，不是空串 `""`，正则替换时容易漏。

### ③ 插件弹窗只显示 `CalledProcessError ... exit status 1`

那只是最外层包装。**真正原因在 server 终端的 Python traceback 最后几行**（`ValueError: ...`），不是弹窗里那串命令。

### ④ 水印

BabelDOC 会在每页顶部加一行"本文档由 funstory.ai 的开源 PDF 翻译库 BabelDOC … 翻译"。
- 命令行：`--watermark-output-mode no_watermark`（`p2z` 已默认加）
- 可选值：`watermarked` / `no_watermark` / `both`
- server 的 config.toml 模板默认已是 `no_watermark`

### ⑤ 命令名冲突

`pdf2zh-next` 的 entry_points 同时提供 `pdf2zh`、`pdf2zh2`、`pdf2zh_next` 三个命令。
如果和旧版 `pdf2zh` 一起装，**会互相覆盖** `~/.local/bin/pdf2zh`。

### ⑥ 端口

Server 默认 **8890**（不是 47700）。插件和 `p2zserver` 要对齐。

### ⑦ 插件里进度永远显示 `0/1`、卡在 `Parse PDF...`

**现象**：Zotero 插件面板只有一行不动的「正在处理 0/1 个文件」，看不出翻了没。

**根因**：server 用正则 `(\d+)/(\d+)` 从 pdf2zh_next 的进度条里取数字，但

```
Translate Paragraphs  ━━╸━━  70/…  0:16…
                              ↑ 分母被截断
```

PTY 只有 80 列，rich 画不下就把 `70/1175` 挤成 `70/…` → 正则匹配失败 → `progress` 恒为 0。

而无 TTY 时（systemd 里跑）`os.get_terminal_size()` 抛 `OSError`，静默回退到 80 列 —— 前台跑反而不一定出问题，**是 systemd 后台跑才稳定复现**。

**已打 patch**（`~/.local/share/zotero-pdf2zh/utils/execute.py:114`）：

```python
# 改前
def _detect_terminal_size(default_cols=80, default_rows=24):
# 改后
def _detect_terminal_size(default_cols=200, default_rows=50):
```

**效果**（实测）：`progress` 从 `0%` 变成实时跳动的 `79%` / `88%`，`message` 变成 `translate 88/100`。

> ⚠️ **升级 server 后这个 patch 会丢，需重打**。备份在 `utils/execute.py.bak-20261028`。
>
> 重打命令：
> ```bash
> sed -i 's/def _detect_terminal_size(default_cols=80, default_rows=24):/def _detect_terminal_size(default_cols=200, default_rows=50):/' \
>   ~/.local/share/zotero-pdf2zh/utils/execute.py
> systemctl --user restart p2z
> ```

### ⑧ 日志爆炸（systemd 的场景）

`StandardOutput=append:` 会把进度条**每一帧**都写文件 —— 实测 **27 KB/秒**，翻一本 100 页的书能写上百 MB（已清掉一个 24 MB 的）。

已改为 `StandardOutput=journal`，查日志：

```bash
journalctl --user -u p2z -f        # 实时
journalctl --user -u p2z -n 50     # 最近 50 行
```

### ⑨ 附件名 `deepseek-dual` 改成 `dual-<文献标题>`

插件默认附件名是 `service + "-" + type`（如 `deepseek-dual`、`deepseek-mono`），跟源文献无关，翻完根本分不清哪篇是哪篇。

**注意**：这个名字是**插件**起的，不是磁盘文件名。磁盘上其实是完整的：

```
1-s2.0-S0944711326001893-main.no_watermark.zh-CN.LR_dual.pdf
```

**已 patch** `content/scripts/pdf2zh.js`（xpi 安装包内，`addAttachment` 函数）：

```javascript
// 改前
let newTitle = service + "-" + type;
const shortTitle = targetItem.getField("shortTitle");
if (shortTitle && shortTitle.length > 0) {
  newTitle = shortTitle + "-" + service + "-" + type;
}

// 改后
const shortTitle = targetItem.getField("shortTitle");
const itemTitle = (targetItem.getField("title") || "").trim();
const baseName = (shortTitle && shortTitle.trim().length > 0)
  ? shortTitle.trim()
  : (itemTitle.length > 0 ? itemTitle : leafName);
let newTitle = type + "-" + baseName;
```

效果：`deepseek-dual` → `dual-Cell senescence emerges as a hallmark....pdf`

重打步骤（升级插件后）：

```bash
cd /tmp && rm -rf xpiprobe && mkdir xpiprobe && cd xpiprobe
cp ~/.zotero/zotero/o8nz5vw6.default/extensions/pdf2zh@guaguastandup.com.xpi .
unzip -oq pdf2zh@guaguastandup.com.xpi
# → 改 content/scripts/pdf2zh.js 的 addAttachment 函数（见上）
zip -r -X -q /tmp/pdf2zh-new.xpi . -x "*.xpi"
cp /tmp/pdf2zh-new.xpi ~/.zotero/zotero/o8nz5vw6.default/extensions/pdf2zh@guaguastandup.com.xpi
# 重启 Zotero 生效
```

检查新包里确实有改动：

```bash
unzip -p 新xpi content/scripts/pdf2zh.js | grep -c "本地改动"   # 应返回 1
```

> ⚠️ 这个 xpi 是**未签名**的（无 META-INF），Zotero 可以直接加载重打包版本。
> 原版备份：`~/.zotero/zotero/o8nz5vw6.default/pdf2zh-xpi.bak-20261028`
>
> 插件里的 `rename` 开关必须为**开**（默认开），否则走 `leafName` 不用 `newTitle`。
> 已存在的旧附件不会改名，只影响以后新翻译的。

---

## 五、目录与体积

| 路径 | 内容 | 体积 |
|---|---|---|
| `~/.venvs/pdf2zh-next/` | 引擎（含 BabelDOC 0.6.x）| ~1 GB |
| `~/.local/share/zotero-pdf2zh/` | server + Flask venv | ~250 MB |
| `~/.local/share/zotero-pdf2zh/translated/` | server 的翻译产物 | 随使用增长 |
| `~/.config/PDFMathTranslate/prompt-medical.txt` | 医学提示词 | 1 KB |

旧的 `pdf2zh 1.9.11`（uv tool，~200 MB）已于 2026-10-28 卸载，配套的 `fix-pdf2zh`、`~/.cache/pdf2zh/`、`~/.config/PDFMathTranslate/config.json` 一并清理。

---

## 六、与 ocrmypdf 的配合

扫描件必须先 OCR 再翻译：

```
纸质/扫描 PDF
  ↓  OCRPDF_FAST=1 ocrpdf 扫描书.pdf     （podman 镜像 ocrmypdf 17.13）
带文本层的 PDF
  ↓  p2z 扫描书-ocr.pdf
双语 PDF
```

顺序不能反 —— pdf2zh 需要文本层才能翻译。详见 `ocrmypdf 使用笔记.md`。

---

## 相关笔记

- `ocrmypdf 使用笔记.md` —— 扫描件加文本层（podman 镜像方案）
- `mise 使用笔记.md` —— 引擎环境的管理方式
- Zotero 里的划词翻译用的是 **Translate for Zotero** 插件（DeepSeek，秒级），与本笔记的整篇翻译是两套东西
