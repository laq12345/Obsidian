---
lang: Linux
date: 2026-04-21
tags:
  - 工具
  - 快照
  - fedora
---


Snapper 是 openSUSE/SUSE 官方开发并深度集成的快照管理工具，主要基于 Btrfs 文件系统（也支持精简配置 LVM 卷上的 XFS/Ext4），用于创建、管理和恢复文件系统快照，实现系统回滚和文件恢复。

一、基本概念与快照类型

Snapper 的快照分为三种类型 ：

- 单一快照 (single)：独立的快照，用于备份或回滚整个系统，时间线快照属于此类
- 前快照 (pre)：记录操作前的文件系统状态
- 后快照 (post)：记录操作后的文件系统状态，与前快照配对

自动创建的快照又分为三类：
- 时间线快照：每小时自动创建的单一快照
- 安装快照：使用 Zypper/YaST 安装软件包前后自动创建的快照对
- 管理快照：使用 YaST 管理系统配置前后自动创建的快照对

二、安装与初始配置

安装
在 openSUSE/SUSE 上通常已预装，其他发行版如 Debian 可手动安装：

```bash
sudo zypper install snapper        # openSUSE
sudo apt install snapper          # Debian/Ubuntu
```

创建配置文件
Snapper 通过配置文件管理不同分区/子卷。默认配置文件名为 `root`（管理根分区）：

```bash
# 为根目录创建配置
sudo snapper -c root create-config /

# 为 /home 目录创建独立配置
sudo snapper -c home create-config /home
```

配置文件位于 `/etc/snapper/configs/` 目录下 。

磁盘空间注意事项
- 根分区 `/` 大于 16GB 时，openSUSE 安装程序会自动启用 Snapper
- 小于 16GB 时，需手动创建配置，且默认禁用时间线快照 
- 快照与原始数据共享块，修改数据时旧块保留给快照，因此删除文件不一定释放空间 

三、核心命令用法

1. 查看快照

```bash
# 列出默认(root)配置的所有快照
sudo snapper list

# 列出所有配置的所有快照
sudo snapper list -a

# 列出特定类型的快照
sudo snapper list -t single          # 单一快照
sudo snapper list -t pre-post        # 快照对

# 查看特定配置的快照
sudo snapper -c home list
```

2. 创建快照

```bash
# 创建单一快照（默认类型）
sudo snapper create --description "手动备份"

# 创建标记为重要的时间线快照
sudo snapper create -t single \
  --description "系统快照" \
  --userdata "important=yes" \
  --cleanup-algorithm timeline

# 创建快照对（pre/post）
sudo snapper create -t pre --print-number --description "修改前"
# 假设输出快照编号为 30
sudo snapper create -t post --pre-number 30 --description "修改后"

# 自动在命令执行前后创建快照对
sudo snapper create --command "zypper update" --description "系统更新"
```

3. 比较与查看差异

```bash
# 查看两个快照间哪些文件发生了变化
sudo snapper status 30..31

# 查看当前系统与某快照的差异（0 表示当前系统）
sudo snapper status 161..0

# 查看具体文件的 diff
sudo snapper diff 30..31 /etc/fstab

# 查看所有文件的差异（不指定文件名）
sudo snapper diff 30..31
```

4. 撤销更改/恢复文件

```bash
# 撤销指定快照间的更改（恢复文件到之前状态）
sudo snapper undochange 30..31 /etc/ssh/sshd_config

# 从快照恢复文件到当前系统
sudo snapper undochange 161..0 /path/to/deleted/file

# 不指定文件名则恢复所有变更的文件（根分区慎用）
sudo snapper undochange 30..31
```

5. 删除快照

```bash
# 删除单个快照
sudo snapper delete 65

# 删除多个快照
sudo snapper delete 10-15

# 删除并立即释放空间（Btrfs 后台回收）
sudo snapper delete --sync 23

# 删除自定义配置的快照
sudo snapper -c home delete 89 90
```

注意：删除 `pre` 快照时，对应的 `post` 快照也会被删除 。

四、自动快照的启用与配置

时间线快照

```bash
# 启用
sudo snapper -c root set-config "TIMELINE_CREATE=yes"

# 禁用
sudo snapper -c root set-config "TIMELINE_CREATE=no"
```

安装快照（Zypper）

```bash
# 启用：安装插件
sudo zypper install snapper-zypp-plugin

# 禁用：卸载插件
sudo zypper remove snapper-zypp-plugin
```

管理快照（YaST）
编辑 `/etc/sysconfig/yast2`：

```bash
USE_SNAPPER=yes   # 启用
USE_SNAPPER=no    # 禁用
```

五、自动清理策略

Snapper 提供三种清理算法，通过 cron 定时执行 ：

算法	说明	配置参数	
number	保留指定数量的快照，超出后删除旧的	`NUMBER_LIMIT`, `NUMBER_LIMIT_IMPORTANT`	
timeline	按时间保留（每小时/天/月/年保留首个）	`TIMELINE_LIMIT_*` 系列参数	
empty-pre-post	删除前后无差异的快照对	`EMPTY_PRE_POST_CLEANUP`	

配置示例

```bash
# 设置保留最近10个普通和10个重要快照，不限年龄
sudo snapper -c root set-config "NUMBER_LIMIT=10"
sudo snapper -c root set-config "NUMBER_LIMIT_IMPORTANT=10"
sudo snapper -c root set-config "NUMBER_MIN_AGE=0"

# 启用配额支持（快照占用空间不超过分区50%）
sudo snapper -c root set-config "QGROUP=1/0"
```

重要：启用配额时，`NUMBER_LIMIT` 需设为范围值如 `2-10`；禁用时用固定值如 `10` 。

六、权限配置

默认仅 root 可管理快照，可授权给普通用户：

```bash
sudo snapper -c home set-config \
  "ALLOW_USERS=tux" \
  "ALLOW_GROUPS=users" \
  "SYNC_ACL=yes"
```

`SYNC_ACL=yes` 必须设置，否则普通用户无法访问快照目录 。

七、系统回滚

对于 Btrfs 根分区，可以从快照引导并执行系统回滚：

1. 在启动菜单选择 Start bootloader from a read-only snapshot
2. 选择合适的快照启动（只读模式）
3. 验证系统正常后，运行：
   
```bash
   sudo snapper rollback
   ```

4. 重启后系统即回滚到该快照状态 

警告：不建议直接从根快照 `undochange` 所有文件来回滚，可能导致启动配置不一致。

八、常用配置参考

```bash
# 查看所有配置
sudo snapper list-configs

# 修改快照元数据（描述、清理算法等）
sudo snapper modify --description "周备份" --cleanup-algorithm timeline 25

# 查看配置参数
sudo snapper -c root get-config

# 手动清理
sudo snapper cleanup timeline
```

Snapper 在 openSUSE/SUSE 中已深度集成，配合 Btrfs 可实现近乎即时的系统备份与回滚，是 Linux 下非常强大的系统保护工具。