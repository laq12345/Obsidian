---
date: 2026-04-24
tags:
  - snapper
  - fedora
  - 快照
  - btrfs
  - snapshot
  - 工具
  - linux
---

# Fedora 下 Snapper 快照工具详细教程

> 适用对象：使用 Fedora + Btrfs 文件系统的用户  
> 目标：学会 Snapper 的安装、配置、日常使用、回滚与故障排查

---

## 1. Snapper 是什么？它能解决什么问题？

Snapper 是一个基于文件系统快照的管理工具，最常见搭配是 **Btrfs**。

你可以把它理解为：

- 在系统关键操作（如升级、改配置）前后，给文件系统打“还原点”
- 之后可以比较差异、恢复单个文件，或者在必要时回滚整个系统状态

典型场景：

- `dnf upgrade` 后系统异常，想回退
- 改坏了 `/etc` 某个配置，想恢复旧版本
- 想保留按小时/按天的系统历史版本

---

## 2. 先确认你的 Fedora 是否适合用 Snapper

Snapper 主要依赖 Btrfs 快照能力。

### 2.1 检查根分区和 home 是否是 Btrfs

```bash
findmnt -T / -o TARGET,SOURCE,FSTYPE,OPTIONS
findmnt -T /home -o TARGET,SOURCE,FSTYPE,OPTIONS
```

如果 `FSTYPE` 是 `btrfs`，就可以使用 Snapper。

### 2.2 检查 Snapper 是否已安装

```bash
rpm -q snapper
```

未安装时：

```bash
sudo dnf install -y snapper
```

### 2.3 （可选）安装 DNF 自动快照插件

这个插件会在每次 DNF 事务前后自动创建 pre/post 快照：

```bash
sudo dnf install -y python3-dnf-plugin-snapper
```

---

## 3. Snapper 核心概念（先理解再上手）

### 3.1 Config（配置）

每个受管理的子卷（subvolume）对应一个 Snapper 配置。例如：

- `root` -> `/`
- `home` -> `/home`

查看已有配置：

```bash
snapper list-configs
```

### 3.2 Snapshot（快照）

快照有几类：

- `single`：单独快照
- `pre` / `post`：一对快照，通常用于某条命令执行前后
- `timeline`：定时快照（小时/天/周/月等）

### 3.3 Cleanup Algorithm（清理算法）

创建快照时可指定清理策略，常见有：

- `number`：按数量保留
- `timeline`：按时间层级保留
- `empty-pre-post`：清理空的 pre/post 对

---

## 4. Fedora 上初始化 Snapper（root/home）

> 如果你系统已存在 `root` 和 `home` 配置，可跳过本节。

### 4.1 创建 root 配置

```bash
sudo snapper -c root create-config /
```

### 4.2 创建 home 配置

```bash
sudo snapper -c home create-config /home
```

### 4.3 查看配置文件位置

Snapper 配置通常在：

- `/etc/snapper/configs/root`
- `/etc/snapper/configs/home`

模板文件通常在：

- `/usr/share/snapper/config-templates/default`

---

## 5. 启用定时快照与自动清理

Snapper 通过 systemd timer 定时执行。

启用并立即启动：

```bash
sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
```

查看状态：

```bash
systemctl list-timers --all 'snapper*'
```

可选：开机快照定时器（默认常见为关闭）：

```bash
sudo systemctl enable --now snapper-boot.timer
```

---

## 6. 日常最常用命令（高频）

下面以 `root` 配置为例（`-c root`）。

### 6.1 列出快照

```bash
sudo snapper -c root list
sudo snapper -c home list
```

### 6.2 手动创建快照

```bash
sudo snapper -c root create --description "before tuning sysctl" --cleanup-algorithm number
```

创建只读快照：

```bash
sudo snapper -c root create --read-only --description "readonly checkpoint"
```

### 6.3 一条命令自动生成 pre/post 快照对

```bash
sudo snapper -c root create --command "dnf upgrade --refresh -y" --description "dnf upgrade"
```

这会自动记录升级前后状态，后续可比较差异或回退部分文件。

### 6.4 查看两个快照之间哪些文件变了

```bash
sudo snapper -c root status 120..121
```

### 6.5 看具体文本差异

```bash
sudo snapper -c root diff 120..121 /etc
```

### 6.6 删除快照

```bash
sudo snapper -c root delete 120
```

---

## 7. 恢复：文件级恢复 vs 系统级回滚

这是 Snapper 最关键的价值。

### 7.1 文件级恢复（推荐优先使用）

只恢复受影响文件，风险最小。

示例：把 `/etc/ssh/sshd_config` 从快照差异中还原：

```bash
sudo snapper -c root undochange 120..121 /etc/ssh/sshd_config
```

恢复后建议重载服务，例如：

```bash
sudo systemctl reload sshd
```

如果涉及 SELinux 上下文变化，补一次：

```bash
sudo restorecon -Rv /etc/ssh/sshd_config
```

### 7.2 系统级回滚（高风险操作）

适用于升级后系统大面积异常。

```bash
sudo snapper -c root rollback
sudo reboot
```

也可指定回滚到某个快照：

```bash
sudo snapper -c root rollback 123
sudo reboot
```

注意：

- 回滚后通常需要重启才完全生效
- 回滚会影响大量系统状态，操作前尽量先做额外备份
- 如果 `/home` 在独立子卷，`root` 回滚不会自动回滚用户数据

---

## 8. DNF 升级前后的推荐工作流（实战）

### 方案 A：手动 pre/post

```bash
sudo snapper -c root create --type pre --description "pre dnf upgrade"
sudo dnf upgrade --refresh -y
sudo snapper -c root create --type post --pre-number <上一个pre编号> --description "post dnf upgrade"
```

### 方案 B：让 Snapper 自动包住命令（更省事）

```bash
sudo snapper -c root create --command "dnf upgrade --refresh -y" --description "dnf upgrade"
```

### 方案 C：使用 DNF 插件自动创建（最自动化）

安装插件后，普通 `dnf` 事务会自动触发快照：

```bash
sudo dnf install -y python3-dnf-plugin-snapper
sudo dnf upgrade --refresh -y
sudo snapper -c root list
```

---

## 9. 配置文件关键参数详解（`/etc/snapper/configs/*`）

下面是最常改的参数：

| 参数 | 作用 | 常见建议 |
| --- | --- | --- |
| `TIMELINE_CREATE` | 是否创建时间线快照 | `yes` |
| `TIMELINE_CLEANUP` | 是否清理时间线快照 | `yes` |
| `TIMELINE_LIMIT_HOURLY` | 保留小时快照数 | 8~24 |
| `TIMELINE_LIMIT_DAILY` | 保留天快照数 | 7~14 |
| `TIMELINE_LIMIT_MONTHLY` | 保留月快照数 | 3~12 |
| `NUMBER_CLEANUP` | 是否启用数量清理 | `yes` |
| `NUMBER_LIMIT` | 保留普通快照上限 | 30~100 |
| `NUMBER_LIMIT_IMPORTANT` | 保留重要快照上限 | 10~20 |
| `SPACE_LIMIT` | 快照最多占磁盘比例/大小 | 如 `0.3` 或 `20G` |
| `FREE_LIMIT` | 最低空闲空间要求 | 如 `0.2` 或 `10G` |
| `EMPTY_PRE_POST_CLEANUP` | 清理空 pre/post 对 | `yes` |

修改配置后，可手动触发清理验证：

```bash
sudo snapper -c root cleanup number
sudo snapper -c root cleanup timeline
```

---

## 10. 空间管理与配额（避免快照把盘占满）

### 10.1 查看 Btrfs 总体占用

```bash
sudo btrfs filesystem usage /
```

### 10.2 为空间感知清理启用 qgroup（推荐）

```bash
sudo snapper -c root setup-quota
sudo snapper -c home setup-quota
```

启用后，`SPACE_LIMIT` / `FREE_LIMIT` 会更有意义。

---

## 11. 常见故障排查

### 11.1 `No permissions`

多数 Snapper 操作需要 root 权限：

```bash
sudo snapper -c root list
```

### 11.2 看不到自动快照

检查 timer 是否启用：

```bash
systemctl status snapper-timeline.timer
systemctl status snapper-cleanup.timer
```

### 11.3 快照很多、磁盘被占满

- 调小 `NUMBER_LIMIT` / `TIMELINE_LIMIT_*`
- 执行 `snapper cleanup number` 和 `snapper cleanup timeline`
- 检查是否有长期不清理的 `important=yes` 快照

### 11.4 回滚后服务异常

- 执行 `sudo restorecon -Rv /`（耗时较长）修复 SELinux 上下文
- 重新生成 initramfs（必要时）
- 检查 `/etc/fstab`、引导项、内核包状态

---

## 12. Fedora 里的几个实践建议

1. **至少管理两个配置**：`root` 和 `home` 分开管理，系统与数据分离。  
2. **升级前打点**：大版本升级、内核/NVIDIA 驱动变更前手动建快照。  
3. **优先文件级恢复**：先用 `undochange`，再考虑 `rollback`。  
4. **定期审计快照策略**：每月看一次 `list` 和空间使用。  
5. **把 Snapper 当“快速回退”而不是异地备份**：它不替代 rsync/restic/borg 之类备份工具。  

---

## 13. 命令速查表

```bash
# 查看配置
snapper list-configs

# 查看快照
sudo snapper -c root list

# 创建快照
sudo snapper -c root create -d "before change"

# 命令前后快照
sudo snapper -c root create --command "dnf upgrade -y" -d "dnf upgrade"

# 比较变化
sudo snapper -c root status 100..101
sudo snapper -c root diff 100..101 /etc

# 恢复单文件
sudo snapper -c root undochange 100..101 /etc/fstab

# 删除快照
sudo snapper -c root delete 101

# 清理
sudo snapper -c root cleanup number
sudo snapper -c root cleanup timeline

# 系统回滚（谨慎）
sudo snapper -c root rollback
sudo reboot
```

---

## 14. 一句话总结

在 Fedora 上，Snapper 的最佳使用姿势是：

- `root/home` 分配置
- `timeline + cleanup` 常开
- 升级前后做 pre/post
- 出问题先 `undochange`，最后才 `rollback`

这样你可以在不改变日常使用习惯的前提下，大幅降低系统变更风险。
