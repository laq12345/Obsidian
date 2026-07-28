# ntfy 使用笔记

## 简介

ntfy（读作 "notify"）是一个 HTTP pub-sub 通知服务。通过 HTTP POST 发送消息，手机/电脑实时收到推送。

GitHub：https://github.com/binwiederhier/ntfy
31.7k stars，Go 编写，Apache 2.0 开源。

---

## 架构

```
curl / 脚本 ──POST──→ 服务器 ntfy ──推送──→ 手机 ntfy app
                      （自托管）
```

- **topic（主题）**：一个字符串标识符，订阅即收到该主题的消息
- 无需注册、无需账号，topic 名就是唯一凭证

---

## 服务器搭建

### 云服务器（推荐）

```bash
# 安装（CentOS/RHEL/Alibaba Cloud Linux）
curl -sL -o /tmp/ntfy.rpm https://github.com/binwiederhier/ntfy/releases/download/v2.26.0/ntfy_2.26.0_linux_amd64.rpm
rpm -ivh /tmp/ntfy.rpm
systemctl enable --now ntfy

# 放行端口（阿里云安全组或其他云防火墙需额外配置）
curl -s http://localhost:80/v1/health   # 验证
```

> 如果 systemd 报 `Failed to determine credentials for user 'ntfy'`：
> ```bash
> useradd --system --home-dir /var/lib/ntfy --shell /bin/false ntfy
> ```

### 安全组配置

云服务器需要在**安全组入方向**放行 **TCP 80** 端口。

---

## 手机订阅

1. 装 **ntfy** app（Google Play / F-Droid / App Store）
2. 点 ➕ → **Subscribe to topic**
3. 服务器地址填：`http://服务器公网IP:80`
4. 主题名填：任意标识符，如 `bio_alerts`
5. 点 Subscribe

---

## 发送消息

### 基础

```bash
# 最简单的
curl -d "消息内容" http://服务器IP:80/主题名

# 带标题
curl -H "Title: 标题" -d "消息内容" http://服务器IP:80/主题名

# 带优先级（urgent/high/low/min/default）
curl -H "Priority: high" -d "重要消息" http://服务器IP:80/主题名
```

### 带标签/表情

```bash
# 标签（内置 emoji 映射）
curl -H "Tags: warning" -d "磁盘空间不足" http://服务器IP:80/主题名

# 常见标签：tada 🎉、warning ⚠️、rotating_light 🚨、x ❌、white_check_mark ✅
# 完整列表：https://ntfy.sh/docs/emojis/

# 可叠加多个
curl -H "Tags: tada,white_check_mark" -H "Title: 完成" -d "分析已结束" http://服务器IP:80/主题名
```

### Markdown 格式

```bash
curl -H "Title: 分析报告" \
     -H "Tags: tada" \
     -d "**DEG 数量**: 254\n**上调**: 120\n**下调**: 134" \
     http://服务器IP:80/主题名
```

### 点击打开 URL

```bash
curl -H "Click: https://google.com" -d "点击打开网页" http://服务器IP:80/主题名
```

### 附件

```bash
curl -F "file=@/path/to/report.pdf" -F "message=报告已生成" http://服务器IP:80/主题名
```

---

## 管道用法（生信场景）

```bash
# 成功通知
snakemake all && curl -d "✅ Snakemake 完成" http://47.94.192.20:80/bio_alerts

# 失败通知
snakemake all && curl -d "✅ 成功" http://47.94.192.20:80/bio_alerts || curl -d "❌ 失败" http://47.94.192.20:80/bio_alerts

# 每步追踪
curl -d "⏳ 数据下载中..." http://47.94.192.20:80/bio_alerts
# ... 运行代码 ...
curl -d "📊 正在做差异分析..." http://47.94.192.20:80/bio_alerts
# ... 运行代码 ...
curl -d "✅ 全部完成，请查看结果" http://47.94.192.20:80/bio_alerts
```

---

## Web 端查看

浏览器打开 `http://服务器IP:80/主题名` 即可看到该主题的消息历史。

---

## 安全建议

| 风险 | 建议 |
|------|------|
| 任何人知道 topic 就能发消息 | topic 用随机字符串：`bio_$(openssl rand -hex 8)` |
| 端口 80 暴露公网 | 用 Tailscale 组网后只走内网 IP |
| 消息明文传输 | 配 HTTPS（nginx 反代 + Let's Encrypt） |

---

## 常用服务器命令

```bash
# 查看日志
journalctl -u ntfy -n 30 --no-pager

# 重启
systemctl restart ntfy

# 查看状态
systemctl status ntfy
```

---

## 排错

| 现象 | 原因 | 解决 |
|------|------|------|
| `curl: (52) Empty reply` | 端口未放通 | 检查云安全组 + 服务器防火墙 |
| `curl: (7) Failed to connect` | IP 错误或服务挂了 | 确认 IP 正确，`systemctl status ntfy` |
| 手机收不到 | 服务器地址填错 | 确认 `http://IP:80` 格式 |
| app 无法添加服务器 | 需要走 HTTP 不是 HTTPS | 用 `http://` 不是 `https://` |
