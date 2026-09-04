---
date: 2026-05-23
tags:
  - 编程
  - 工具
  - linux
  - git
---
# Git 核心命令笔记

## 目录
1. [stash（临时储藏）](#1-stash)
2. [reflog（操作日志）](#2-reflog)
3. [rebase（变基）](#3-rebase)
4. [cherry-pick（挑拣提交）](#4-cherry-pick)
5. [amend（修改最后一次提交）](#5-amend)

---

## 1. stash

把未提交的修改暂存起来，干净地切换分支。

### 常用命令

| 命令 | 作用 |
|------|------|
| `git stash push -m "描述"` | 储藏当前修改（含暂存区和工作区） |
| `git stash` | 快捷方式（等效于 push） |
| `git stash list` | 查看储藏列表 |
| `git stash pop` | 恢复最近一次储藏并删除 |
| `git stash pop stash@{1}` | 恢复指定储藏 |
| `git stash apply` | 恢复但不删除储藏 |
| `git stash drop stash@{0}` | 删除指定储藏 |
| `git stash clear` | 清空所有储藏 |

### 典型场景

```bash
# 正在 feature 分支写代码，突然要去 main 修紧急 bug
git stash push -m "feature-x 半成品"
git switch main
# ... 修 bug ...
git switch feature-x
git stash pop    # 继续之前的开发
```

---

## 2. reflog

记录 HEAD 的所有变动历史，误操作后的救命稻草。

### 常用命令

| 命令                          | 作用         |
| --------------------------- | ---------- |
| `git reflog`                | 查看 HEAD 历史 |
| `git reflog show main`      | 查看特定分支历史   |
| `git reset --hard HEAD@{2}` | 恢复到某个历史状态  |

### 典型场景

```bash
# 误操作 hard reset，代码没了
git reset --hard HEAD~5      # 完蛋，5 个提交没了

git reflog                   # 找到 reset 前的 hash
git reset --hard HEAD@{1}    # 恢复！
```

### 找回被删除的分支

```bash
git reflog
# 找到分支删除前的 commit hash
git checkout <hash>              # 查看确认
git switch -c recovered-branch # 重建分支
```

---

## 3. rebase

把当前分支的提交接到另一个分支的最新提交上。

### 常用命令

| 命令                      | 作用                |
| ----------------------- | ----------------- |
| `git rebase main`       | 把当前分支变基到 main     |
| `git rebase -i HEAD~5`  | 交互式变基（整理最近 5 个提交） |
| `git rebase --continue` | 解决冲突后继续           |
| `git rebase --abort`    | 放弃变基              |

### 交互式变基命令

| 命令 | 缩写 | 作用 |
|------|------|------|
| pick | p | 保留提交 |
| reword | r | 修改提交消息 |
| squash | s | 合并到上一个提交 |
| fixup | f | 合并并丢弃提交消息 |
| drop | d | 删除提交 |
| edit | e | 暂停修改提交内容 |

### 典型场景

```bash
# 场景 1：同步主分支最新代码
git switch feature
git rebase main              # feature 的提交移到 main 最新之上

# 场景 2：整理提交历史（合并小提交）
git rebase -i HEAD~3
# 把 pick 改成 squash 合并
```

> **黄金法则**：不要对已经推送到远程的公共分支做 rebase。

---

## 4. cherry-pick

把指定提交复制到当前分支。

### 常用命令

| 命令 | 作用 |
|------|------|
| `git cherry-pick abc1234` | 挑拣单个提交 |
| `git cherry-pick abc1234 def5678` | 挑拣多个提交 |
| `git cherry-pick A..B` | 挑拣范围（不包括 A） |
| `git cherry-pick -x abc1234` | 挑拣并保留来源信息 |
| `git cherry-pick --continue` | 解决冲突后继续 |
| `git cherry-pick --abort` | 放弃挑拣 |

### 典型场景

```bash
# main 分支修了一个 bug，要应用到旧版本 release 分支
git switch release-v1
git cherry-pick -x <main 上的 bugfix 提交 hash>
```

---

## 5. amend

修正最近一次提交的内容或消息。

### 常用命令

| 命令 | 作用 |
|------|------|
| `git commit --amend -m "新消息"` | 修改提交消息 |
| `git commit --amend --no-edit` | 不改消息，只加文件 |
| `git commit --amend --author="..."` | 修改作者 |
| `git commit --amend --date="..."` | 修改时间戳 |

### 典型场景

```bash
# 刚提交完发现有个文件忘加了
git add forgotten.py
git commit --amend --no-edit   # 加到上一个提交，不改消息

# 提交消息写错了
git commit --amend -m "正确的消息"
```

> **注意**：amend 会改变 commit hash，如果已经 push 到远程，需要强制推送 `git push --force-with-lease`。

---

## 快速对比

| 命令 | 解决什么问题 | 是否改历史 |
|------|-----------|-----------|
| stash | 临时保存未提交修改 | 否 |
| reflog | 找回误删/误 reset 的内容 | 否（只查看） |
| rebase | 整理/移动提交序列 | 是 |
| cherry-pick | 复制单个提交到另一分支 | 否（新增提交） |
| amend | 修改最后一次提交 | 是 |

---

## 组合使用示例

```bash
# 场景：开发中临时去修 bug
git stash push -m "feature 开发中"
git switch main
git pull
# 修 bug...
git commit -m "fix: 紧急修复"
git switch feature
git rebase main              # 同步 main 的 bugfix
git stash pop                # 恢复开发状态

# 发现有个文件忘提交了
git add forgotten.py
git commit --amend --no-edit

# 又发现之前删了个分支上有用的代码
git reflog                   # 找回 hash
git cherry-pick abc1234      # 挑拣回来
```
