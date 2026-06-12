---
time: 2026-06-12T21:59:00
lang: Linux
tags:
  - 工具
  - ai
  - opencode
---

# OpenCode (Sisyphus) Slash Commands 参考

> 适用于本环境 OpenCode / Sisyphus Agent

---

## 内建命令

| 命令 | 说明 | 典型用法 |
|------|------|----------|
| `/playwright` | 浏览器自动化（截图、测试、爬取） | `/playwright "打开 xxx 页面并截图"` |
| `/frontend-ui-ux` | 前端 UI/UX 设计与实现 | 改样式、调布局、做动画 |
| `/git-master` | Git 操作专家（提交、回滚、追溯） | 原子化 commit、交互式 rebase |
| `/review-work` | 实现后的全面审查（启动 5 个并行审查代理） | `/review-work` 审查刚完成的代码 |
| `/remove-ai-slops` | 清除 AI 生成代码中的坏味道 | `/remove-ai-slops` 清理当前改动 |
| `/init-deep` | 初始化 AGENTS.md 知识库 | 新项目接入时用 |
| `/debugging` | 系统化调试（假设→验证→修复） | `/debugging "为什么 API 返回 500"` |
| `/security-research` | 安全审计（3 漏洞猎手 + 2 PoC 工程师并行） | `/security-research` 审计代码库 |
| `/security-review` | 同上，别名 | |
| `/visual-qa` | UI 视觉回归测试 | 改完 UI 后验证视觉正确性 |
| `/refactor` | 智能重构（LSP + AST + 架构分析） | `/refactor "重构 user 模块"` |
| `/start-work` | 从 Prometheus 计划启动工作 | 加载计划文件后执行 |
| `/handoff` | 生成上下文摘要，用于新会话延续 | 任务没做完但需新对话框时 |
| `/hyperplan` | 对抗式多 Agent 规划 | 5 个对立角色交叉审查，1 个领袖合成方案 |
| `/ralph-loop` | 持续自引用开发循环 | |
| `/ulw-loop` | 持续 ultrawork 循环 | |
| `/cancel-ralph` | 取消活跃的 Ralph 循环 | |
| `/stop-continuation` | 停止所有续接机制 | |

---

## 可用 Skill（通过 skill tool 加载）

### 开发流程

| skill | 说明 |
|-------|------|
| `brainstorming` | 创意工作前的头脑风暴（需求探索） |
| `test-driven-development` | TDD：先写测试再写实现 |
| `requesting-code-review` | 完成工作后的代码审查请求 |
| `receiving-code-review` | 收到 code review 反馈后的处理 |
| `verification-before-completion` | 声称完成前的验证流程 |
| `systematic-debugging` | 系统化调试方法论 |

### 项目管理

| skill | 说明 |
|-------|------|
| `writing-plans` | 多步骤任务的实施计划编写 |
| `executing-plans` | 在独立 session 中执行实施计划 |
| `finishing-a-development-branch` | 分支完成后的合并/PR 决策 |
| `dispatching-parallel-agents` | 并行派遣多个子 Agent |
| `subagent-driven-development` | 子 Agent 驱动的开发 |

### Git 与工具

| skill | 说明 |
|-------|------|
| `using-git-worktrees` | Git worktree 隔离开发 |
| `using-superpowers` | Superpowers 技能系统使用指南 |
| `customize-opencode` | 自定义 OpenCode 配置（opencode.json 等） |
| `writing-skills` | 创建/编辑 skill 文件 |

### 安全

| skill | 说明 |
|-------|------|
| `security-research` | 安全研究（漏洞猎手 + PoC） |
| `security-review` | 安全审查（别名） |

---

## Agent 类型（通过 task() 委派）

### 探索类

| agent | 类型 | 说明 |
|-------|------|------|
| `explore` | 子代理 | 代码库内搜索（free） |
| `librarian` | 子代理 | 外部参考搜索（文档/开源/GitHub） |

### 咨询类

| agent | 类型 | 说明 |
|-------|------|------|
| `oracle` | 只读 | 高智商推理（架构/调试） |
| `metis` | 只读 | 预规划分析（发现歧义和陷阱） |
| `momus` | 只读 | 计划评审（验证清晰度和完整性） |

### 执行类

| category | 说明 |
|----------|------|
| `visual-engineering` | 前端/UI/UX/设计 |
| `ultrabrain` | 高难度逻辑和架构 |
| `deep` | 目标驱动的自主研究和实现 |
| `quick` | 单文件小改动 |
| `writing` | 文档/技术写作 |
| `artistry` | 创造性/非传统问题 |

---

## 最常用的 10 个

```
/refactor              ← 重构代码
/debugging             ← 系统化调试
/review-work           ← 改完代码后的全面审查
/security-research     ← 安全审计
/remove-ai-slops       ← 清理 AI 代码坏味道
/visual-qa             ← 验证 UI 视觉
/playwright            ← 浏览器自动化
/git-master            ← 精巧的 git 操作
/handoff               ← 工作交接
/hyperplan             ← 复杂任务的多 Agent 规划
```
