---
date: 2026-08-24
lang: Linux
tags:
  - 工具
  - 邮箱
  - linux
  - CLI
  - himalaya
---

# himalaya 终端邮箱使用指南

> 一句话理解：**himalaya 是一个用 Rust 写的、纯命令行的邮件客户端**。不走 GUI、没有事件循环——你像用 fd/eza/bat 一样，在终端里用**命令**收信、读信、发信、搜索、移动邮件。可脚本化、快、专注。
>
> **与 aerc/mutt/alpine 的区别**：aerc/mutt 是 **TUI**（锁住终端进事件循环，用按键交互）；himalaya 是 **CLI**（无状态命令，和 shell 深度结合）。官方也在开发同库的 TUI（himalaya-tui）。

---

## 本机环境（实测于 2026-08-24）

```bash
$ himalaya --version
himalaya v2.1.0 +imap +rustls-ring +gmail +maildir +smtp +msgraph +jmap
build: linux gnu x86_64
git: heads/master, rev 6bca26b86ea13a91c65347b5353696345de652e1
```

**已启用特性模块**：
| 模块 | 作用 |
|------|------|
| `+imap` / `+smtp` | 标准 IMAP 收信 / SMTP 发信 |
| `+gmail` / `+msgraph` | Gmail REST API / Microsoft Graph |
| `+jmap` | 现代邮件协议 JMAP（Fastmail 等） |
| `+maildir` | 本地 Maildir 邮件目录 |
| `+rustls-ring` | rustls + ring 加密（TLS） |

---

## ⚠️ 当前状态：还没配置账号

```bash
$ himalaya account list
Error: No configuration found. Run bare `himalaya` to launch the wizard and generate one.
```

**这是正常的**。首次运行需先跑向导生成 `~/.config/himalaya/config.toml`。

---

## 一、初始化（配置向导）

```bash
# 直接运行 himalaya，不带命令，启动交互式向导
himalaya
```

向导做的事：
1. 输入**账号名**和**邮箱地址**
2. **并行探测**多种发现机制（并在结果里选最安全的端点）：
   - **PACC**（draft-ietf-mailmaint-pacc）
   - **Thunderbird Autoconfiguration**
   - **RFC 6186 SRV**（`_imap._tcp`、`_imaps._tcp`、`_submission._tcp`）
   - **RFC 8620 JMAP**（`/.well-known/jmap`）
3. 自动填好 IMAP/SMTP（或 JMAP）的默认值
4. 把结果写到一个 `[accounts.<name>]` 块，**打印到 stdout**（提示输出到 stderr）

> **重要**：向导把 TOML 打印出来，可以用 `himalaya > 配置文件` 直接重定向进去！重新跑可再生成账号并追加。
> 想重跑：`himalaya configure`（别名 `wizard`）。

配置文件加载顺序（第一个找到的）：
```
$XDG_CONFIG_HOME/himalaya/config.toml
$HOME/.config/himalaya/config.toml     # ← 最常见
$HOME/.himalayarc
```

---

## 二、账号管理

```bash
himalaya account list          # 列出所有账号 [别名 ls]
himalaya account check         # 校验账号配置（能否连上服务器）★ 排查第一步 ★
```

多账号切换（`-a` 名字必须和 TOML 根级表格 key 一致）：
```bash
himalaya -a work envelope list
```

---

## 三、共享 API（后端无关命令）

这些命令走账号的**第一个配置的后端**，或用 `-b/--backend` 指定。设置了 `[mailbox.alias]` 的 `inbox` 后，`-m` 默认指向它。

```bash
himalaya mailbox list                                  # 列出邮件夹
himalaya envelope list --page 2                        # 翻页
himalaya envelope search from alice and after 2026-01-01 order by date desc   # 搜索
himalaya flag add --flag seen 1:3,5                    # 设置已读标记
himalaya message read 42                               # 读第42封
himalaya message copy --from INBOX --to Archives 42    # 复制到另一夹
himalaya attachment download 42                        # 下载附件
```

**`envelope list` 常用参数**：
```bash
himalaya envelope list -m sent            # 指定邮件夹（用别名）
himalaya envelope list -p 2               # 第2页（最新在首页）
himalaya envelope list -s 50              # 每页50封（默认25）
himalaya envelope list -r                 # 显示收件人而非发件人（发件箱）
himalaya envelope list --has-attachment   # 显示附件列
himalaya envelope list --max-width 120    # 控制表格宽度
```

### 搜索 DSL（`envelope search` / `sr`）

用自带查询语言，跨后端解析。语法结构：**条件树 + 排序**。
```bash
himalaya envelope search from alice and after 2026-01-01 order by date desc
```
涵盖 header、date、body 子句。完整语法看 `himalaya envelope search --help`。

---

## 四、协议专属 API

每个后端暴露自有接口，`-b` 在此处被忽略（固定用自己的后端）：

```bash
himalaya imap raw 'a1 SEARCH FROM "alice@example.com"'         # IMAP 原生查询
himalaya jmap mailbox query --role drafts                       # JMAP 找草稿箱 id
himalaya gmail messages list -q "from:alice is:unread"          # Gmail 语法
himalaya msgraph mail-folder list                                # Microsoft Graph
himalaya smtp send -f me@example.com -t you@example.com < message.eml  # 直接发
```

---

## 五、写邮件（compose / reply / forward）

简单场景用参数。复杂 MIME（签名、加密、MML 指令、编辑器流程）链上 **mml** 组合器：

```bash
himalaya message compose --to you@example.org --subject Hello --body Hi --send
mml compose >(himalaya message send)                 # 链 mml 做富文本
himalaya message add -m drafts --flag draft < message.eml    # 存草稿
```

---

## 六、配置文件详解（官方 config.sample.toml）

> ⚠️ **字段名以官方为准**。配置是**扁平键**，不是旧版 `backend.type` 那种写法。

### 全局配置
```toml
# 全局（账号没写时生效）
#display-name = "Alice"                # From 里的显示名
#signature = "Regards,\nAlice"         # 签名
#signature-delim = "-- \n"
#downloads-dir = "~/downloads"         # 附件目录
#envelope.list.page-size = 50          # 默认每页数
#table.preset = "││──╞═╪╡┆    ┬┴┌┐└┘"  # 表格样式
```

### 单个账号 + IMAP/SMTP（最通用）
```toml
[accounts.gmail]
default = true                        # 不写 -a 时用这个
display-name = "你的名字"
email = "you@gmail.com"

# --- IMAP 收信 ---
imap.server = "imaps://imap.gmail.com:993"     # 或 imap://...:143（STARTTLS）
#imap.tls.provider = "rustls"
#imap.tls.rustls.crypto = "ring"
#imap.starttls = false                          # 仅 imap:// 时用
#imap.sasl-ir = false                           # 126/163(Coremail) 可能要 false

# SASL 认证：plain/login/oauthbearer/xoauth2/scram-sha-256/anonymous 选一
imap.sasl.plain.username = "you@gmail.com"
# 密码两种写法：raw 明文（仅测试）或 command（推荐，从密码管理器读取）
imap.sasl.plain.password.raw = "***"
#imap.sasl.plain.password.command = "pass show gmail"

# --- SMTP 发信 ---
smtp.server = "smtps://smtp.gmail.com:465"
smtp.sasl.plain.username = "you@gmail.com"
smtp.sasl.plain.password.raw = "***"

# --- 邮件夹别名（-m 用友好名） ---
[mailbox.alias]
inbox = "INBOX"
sent = "[Gmail]/Sent Mail"
drafts = "[Gmail]/Drafts"
trash = "[Gmail]/Trash"
archive = "[Gmail]/All Mail"
```

### 各邮箱服务官方模板

**Gmail**（拒绝普通密码，需**应用专用密码**，16位，开启两步验证后生成）：
```toml
[accounts.gmail]
imap.server = "imaps://imap.gmail.com:993"
imap.sasl.plain.username = "example@gmail.com"
imap.sasl.plain.password.command = "pass show gmail"
smtp.server = "smtps://smtp.gmail.com:465"
smtp.sasl.plain.username = "example@gmail.com"
smtp.sasl.plain.password.command = "pass show gmail"
[mailbox.alias]
inbox = "INBOX"
sent = "[Gmail]/Sent Mail"
drafts = "[Gmail]/Drafts"
trash = "[Gmail]/Trash"
archive = "[Gmail]/All Mail"
```
> Gmail 的 label 都会变成顶层 IMAP 邮件夹；`[Gmail]/` 前缀下的特殊夹要用别名或引号包住（`-m "[Gmail]/Drafts"`）。「全部邮件」别名 `archive` 可一招搜全部。

**Outlook / Microsoft 365**（微软停用基本认证，只用 OAuth2）：
```toml
[accounts.outlook]
imap.server = "imaps://outlook.office365.com:993"
imap.sasl.xoauth2.username = "example@outlook.com"
imap.sasl.xoauth2.token.command = ["ortie","token","show","-a","outlook"]
smtp.server = "smtp://smtp-mail.outlook.com:587"
smtp.starttls = true
smtp.sasl.xoauth2.username = "example@outlook.com"
smtp.sasl.xoauth2.token.command = ["ortie","token","show","-a","outlook"]
```

**Fastmail**（IMAP/SMTP 用 app password，或 JMAP 用 API token）：
```toml
[accounts.fastmail]
imap.server = "imaps://imap.fastmail.com"
imap.sasl.plain.username = "example@fastmail.com"
imap.sasl.plain.password.command = "pass show fastmail"
smtp.server = "smtps://smtp.fastmail.com"
smtp.sasl.plain.username = "example@fastmail.com"
smtp.sasl.plain.password.command = "pass show fastmail"
```
用 JMAP 替代 IMAP/SMTP（只留一个 jmap 块）：
```toml
[accounts.fastmail]
jmap.server = "https://api.fastmail.com/jmap/session"
jmap.auth.bearer.token.command = "pass show fastmail"
```

**Proton**（无原生 IMAP/SMTP，需 **Proton Bridge** 走本地端点）：
```toml
[accounts.proton]
imap.server = "imap://127.0.0.1:1143"
imap.sasl.plain.username = "example@proton.me"
imap.sasl.plain.password.command = "pass show proton-bridge"
smtp.server = "smtp://127.0.0.1:1025"
smtp.sasl.plain.username = "example@proton.me"
smtp.sasl.plain.password.command = "pass show proton-bridge"
# 本地链路也开启 TLS（导出 Bridge 证书）：
#imap.starttls = true; imap.tls.cert = "/path/to/cert.pem"
```

**Posteo**（普通密码即可，无需 app password）：
```toml
[accounts.posteo]
imap.server = "imaps://posteo.de"
imap.sasl.plain.username = "example@posteo.net"
smtp.server = "smtps://posteo.de"
smtp.sasl.plain.username = "example@posteo.net"
```

**iCloud**（IMAP 登录用地址名，SMTP 登录用完整地址，需 app-specific 密码）：
```toml
[accounts.icloud]
imap.server = "imaps://imap.mail.me.com:993"
imap.sasl.plain.username = "johnappleseed"        # 注意：不是完整邮箱
smtp.server = "smtp://smtp.mail.me.com:587"
smtp.starttls = true
smtp.sasl.plain.username = "johnappleseed@icloud.com" # SMTP 用完整地址
[mailbox.alias]
sent = "Sent Messages"
```

---

## 七、认证与密码（易错点）

- **每个密码/令牌字段**（`*.password` / `*.passwd` / `*.token`）支持：
  - `raw`：明文（仅测试用，别进生产）
  - `command`：无参数命令 / 数组命令，从密码管理器读 `pass show example` / `["ortie","token","show","-a","gmail"]`
- **v2 移除了原生 keyring 支持** → 用 `pass` / `secret-tool` / `gopass` 等第三方 CLI 作为 `command`。
- **OAuth2**：v2 **不内置 OAuth flow**。用 [ortie](https://github.com/pimalaya/ortie)（或任意 token broker）拿 access token，接成 `command`。
- **SASL 机制**（IMAP/SMTP 通用）：`anonymous` / `login` / `plain` / `oauthbearer` / `xoauth2` / `scram-sha-256`，选一个；整表省略则跳过认证。

---

## 八、调试 & 常见操作

```bash
# 详细日志（写 stderr，可重定向）
himalaya --log trace mailbox list
himalaya --log trace --log-file /tmp/himalaya.log mailbox list

# 环境变量 RUST_LOG 也生效；RUST_BACKTRACE=1 看完整回溯
RUST_LOG=debug himalaya envelope list

# 关闭彩色输出
NO_COLOR=1 himalaya envelope list

# 代理（SOCKS5/HTTP）
ALL_PROXY=socks5://... himalaya envelope list
```

---

## 九、常用全局选项

| 选项 | 作用 |
|------|------|
| `-c, --config <PATH>` | 指定配置（可多路径用 `:` 分隔，首个为基础，其余深合并） |
| `-a, --account <NAME>` | 切换账号 |
| `-b, --backend <BACKEND>` | 强制后端：`auto/imap/jmap/gmail/msgraph/maildir/m2dir/pimdir/smtp` |
| `--json` | JSON 输出（脚本化） |
| `--log <level>` / `--log-file` | 日志（off/error/warn/info/debug/trace） |

```bash
himalaya -a work -b imap --json envelope list    # 换账号+强制IMAP+JSON
```

---

## 十、安装（回顾：你已装好）

Himalaya 官方安装方式（你已用其中一种装好 v2.1.0）：
```bash
# 预编译脚本
curl -sSL https://raw.githubusercontent.com/pimalaya/himalaya/master/install.sh | PREFIX=~/.local sh
# Cargo（装最新/定制特性）
cargo install --locked --git https://github.com/pimalaya/himalaya.git
# Fedora / RHEL（COPR）——Silverblue 上一般用 distrobox 跑
dnf copr enable atim/himalaya && dnf install himalaya
```

---

## 十一、速查小抄

```bash
himalaya                            # 首次：启动配置向导
himalaya account list               # 列账号
himalaya account check              # 校验连接 ★
himalaya mailbox list               # 列邮件夹
himalaya envelope list              # 看收件箱
himalaya envelope list -m sent      # 看已发送
himalaya envelope search from alice and after 2026-01-01 order by date desc  # 搜索
himalaya message read 42            # 读邮件
himalaya message compose --to a@b --subject Hi --body Hey --send   # 写并发送
himalaya flag add --flag seen 1:3,5 # 标记
himalaya attachment download 42     # 下载附件
himalaya -a work --json envelope list   # 多账号+JSON
```

---

## 十二、扩展（同库生态）

| 工具 | 用途 |
|------|------|
| **himalaya-tui** | 官方 TUI（开发中，更像 aerc/mutt） |
| **himalaya-vim** | Vim 插件 |
| **mml** | MML 富文本组合器（签名/加密） |
| **ortie** | OAuth2 token 管理（v2 的 OAuth 搭档） |
| **neverest** | 邮箱同步/备份（跨后端） |
| **sirup** | 预认证 IMAP/SMTP session 复用（省握手） |

---

## 参考

- 官网：https://pimalaya.org/
- README：https://github.com/pimalaya/himalaya
- 配置模板：`config.sample.toml`（仓库根目录，逐项注释）
- 配置位置：`~/.config/himalaya/config.toml`

_关键字：himalaya, 邮件, email, IMAP, SMTP, JMAP, Gmail, Outlook, CLI, 命令行, 终端_
