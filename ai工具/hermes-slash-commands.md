---
time: 2026-06-12T21:58:00
lang: Linux
tags:
  - 工具
  - hermes
  - ai
---

# Hermes Slash Commands 完全参考

> Hermes v0.16.0 | 适用场景：CLI + QQ/Telegram 等消息平台

---

## 对话控制

| 命令 | 说明 |
|------|------|
| `/new` | 开始全新会话，清空上下文 |
| `/reset` | 同 /new |
| `/stop` | 立即中断当前操作 |
| `/retry` | 重试上一轮（AI 重新生成回复） |
| `/undo` | 撤销上一轮交换，回到之前的状态 |
| `/title [名称]` | 给当前会话命名（方便后面恢复） |
| `/resume [名称]` | 恢复到之前命名的会话 |
| `/approve` | 批准一个待处理的危险命令 |
| `/deny` | 拒绝一个待处理的危险命令 |
| `/sethome` | 将当前聊天设为主频道（定时任务结果往这推） |
| `/background <任务>` | 在后台单独执行一个任务，不中断当前对话 |
| `/rollback [编号]` | 查看或恢复文件系统检查点 |

## 模型与推理

| 命令 | 说明 |
|------|------|
| `/model` | 查看和切换已配置的模型 |
| `/model deepseek:deepseek-v4-flash` | 切换到指定模型 |
| `/model anthropic:claude-sonnet-4` | 切换到 Claude |
| `/reasoning [level]` | 调整推理深度：low / medium / high |
| `/reasoning show` | 显示推理过程 |
| `/reasoning hide` | 隐藏推理过程 |

## 用量与诊断

| 命令 | 说明 |
|------|------|
| `/usage` | 当前会话 token 使用量 + 花费 |
| `/insights [天数]` | 指定天数内的用量统计（如 `/insights 7`） |
| `/compress` | 手动压缩对话上下文，释放 token |
| `/status` | 显示当前会话信息 |
| `/whoami` | 显示你在本平台的管理权限级别 |
| `/gquota` | Google Gemini 配额（DeepSeek 用户无视） |

## 技能系统

| 命令 | 说明 |
|------|------|
| `/skills` | 列出所有可用技能 |
| `/skills pending` | 列出待审批的技能写入 |
| `/skills approve <id>` | 批准技能修改 |
| `/skills reject <id>` | 拒绝技能修改 |
| `/skills approval on/off` | 开关技能审批 |
| `/<skill-name>` | 调用特定技能（如 `/arxiv`、`/plan`） |

## 定时任务 (Cron)

| 命令 | 说明 |
|------|------|
| `/cron list` | 列出所有定时任务 |
| `/cron show <id>` | 查看任务详情 |
| `/cron run <id>` | 立即运行一次 |
| `/cron pause <id>` | 暂停 |
| `/cron resume <id>` | 恢复 |
| `/cron delete <id>` | 删除 |

## 记忆管理

| 命令 | 说明 |
|------|------|
| `/memory pending` | 列出待审批的记忆写入 |
| `/memory approve <id>` | 批准记忆写入 |
| `/memory reject <id>` | 拒绝记忆写入 |
| `/memory approval on/off` | 开关记忆审批 |

## 平台管理

| 命令 | 说明 |
|------|------|
| `/platform list` | 查看所有消息平台适配器状态 |
| `/platform pause <名称>` | 暂停某平台 |
| `/platform resume <名称>` | 恢复某平台 |

## 插件与 MCP

| 命令 | 说明 |
|------|------|
| `/reload-mcp` | 重新加载 MCP 服务器配置 |
| `/bundles` | 列出所有 skill 组合包 |

## 人格与语音

| 命令 | 说明 |
|------|------|
| `/personality [名称]` | 切换人格 |
| `/voice on/off` | 开关语音模式 |
| `/voice tts` | 文本转语音设置 |

## 系统

| 命令 | 说明 |
|------|------|
| `/update` | 更新 Hermes 到最新版 |
| `/help` | 显示所有可用命令 |

---

## 最常用的 10 个

```
/model                    ← 换模型
/new                      ← 开新对话
/usage                    ← 看花了多少钱
/compress                 ← 省 token
/background "任务"         ← 后台跑任务
/cron list                ← 看定时任务
/skills                   ← 看有什么技能
/arxiv "关键词"            ← 搜论文（需 skill）
/plan "需求"              ← 先列计划不动手
/stop                     ← 它发疯时打断
```

---

> 注意：`/model` 只能切**已配置**的 provider。新增 provider 必须退出对话后运行 `hermes model`。
