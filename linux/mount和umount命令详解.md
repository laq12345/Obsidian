---
date: 2026-08-24
lang: Linux
tags:
  - 编程
  - 工具
  - linux
  - mount
  - 磁盘
---

# mount 与 umount 命令详解

> 一句话理解：**Unix 下所有设备/文件系统都要「挂载」(mount) 到一个目录后才能访问**。`mount` 负责把存储设备接入目录树，`umount` 负责安全卸载。这是 Linux 用户与磁盘、U盘、ISO镜像、网络共享打交道的基础。

---

## 一、核心概念

| 概念 | 含义 | 类比 |
|------|------|------|
| **挂载点 (mount point)** | 设备被接入的那个空目录 | 墙上插座的插孔 |
| **文件系统** | 设备上的数据组织方式（ext4/btrfs/xfs） | 仓储系统 |
| **挂载** | 把文件系统和某个目录绑定 | 把设备插进插座 |
| **块设备** | 物理存储设备（/dev/sda1 /dev/nvme0n1p2） | 硬盘本体 |

**关键点**：Linux 没有 Windows 那种「D: 盘」。所有设备都要先被 `mount` 到一个目录，通过目录路径来访问。目录必须**存在**且通常**为空**（否则原内容会被遮盖）。

---

## 二、mount 基本用法

```bash
mount [选项] <设备> <挂载点>
mount -t <文件系统类型> <设备> <挂载点>
mount <挂载点>                # 也行，dev 可由 /etc/fstab 推断
```

### 最常见的日常场景

```bash
# 1. 查看当前已挂载的所有文件系统
mount
# 等价：findmnt、cat /proc/mounts

# 2. 挂载一个 U 盘 / 分区（自动识别类型）
sudo mount /dev/sdb1 /mnt/usb

# 3. 指定文件系统类型挂载
sudo mount -t ext4 /dev/sda2 /mnt/data

# 4. 挂载 ISO 镜像文件（不用烧盘）
sudo mount -o loop image.iso /mnt/iso

# 5. 挂载时指定读写选项
sudo mount -o rw,noatime /dev/sdb1 /mnt/usb
```

---

## 三、常用选项

### -t 指定文件系统类型
```bash
# 常见类型
mount -t ext4      # Linux 文件系统
mount -t vfat      # FAT32（U盘/老设备）
mount -t ntfs-3g   # Windows NTFS
mount -t iso9660   # 光盘 / ISO
mount -t cifs      # Windows 网络共享 (SMB)
mount -t nfs       # 网络文件系统
```

### -o 挂载选项（最常用）
用逗号分隔多个选项：

| 选项                     | 作用                         |
| ---------------------- | -------------------------- |
| `ro` / `rw`            | 只读 / 读写                    |
| `loop`                 | 把普通文件当块设备（挂 ISO）           |
| `noatime` / `relatime` | 关闭/减少访问时间更新（SSD 友好）        |
| `noexec`               | 禁止执行文件（安全加固）               |
| `nodev`                | 不解析设备文件                    |
| `nosuid`               | 忽略 suid 位                  |
| `user` / `users`       | 允许普通用户挂载                   |
| `defaults`             | 默认选项 ro+suid+dev+exec+auto |

```bash
# 举例
mount -o rw,noatime /dev/sdb1 /mnt
mount -o loop,ro image.iso /mnt/cdrom
mount -o uid=1000,gid=1000 /dev/sdb1 /mnt/usb   # 挂载时指定属主
```

---

## 四、umount 卸载

```bash
umount <挂载点或设备>
```

### 使用方法

```bash
# 按挂载点卸载（推荐，最直观）
sudo umount /mnt/usb

# 按设备卸载
sudo umount /dev/sdb1

# 卸载所有已挂载的可移动设备（谨慎）
sudo umount -a
```

### 卸载失败怎么办？（最关键）

**最常见的错误**：`device is busy` —— 有进程正在使用该挂载点（比如终端 cd 进去过、有个文件被占用）。

```bash
# 1. 先看谁在用（lsof / fuser）
lsof +D /mnt/usb          # 列出占用该挂载点下文件的进程
fuser -v /mnt/usb         # 同样查占用进程

# 2. 强制卸载（fuser 顺手杀掉占用进程）
sudo fuser -k /mnt/usb

# 3. 懒卸载 - 立即从目录树移除，等进程用完再真正卸载
sudo umount -l /mnt/usb

# 4. 强制卸载（慎用，可能丢数据）
sudo umount -f /mnt/usb
```

**黄金流程**：先 `lsof`/`fuser` 找原因，别一上来就 `-f`。安全顺序：`cd` 出去 → 关掉占用程序 → 正常 `umount` → 还不行才 `-l` → 最后才 `-f`。

---

## 五、fstab — 开机自动挂载

想每次开机自动挂载，编辑 `/etc/fstab`。

```bash
# 语法：<设备>  <挂载点>  <文件系统>  <选项>  <dump>  <fsck>
/dev/sdb1    /mnt/data    ext4    defaults    0    2
```

**发布前必须验证**（写错会导致开机失败！）：

```bash
sudo mount -a            # 按 fstab 全部挂载一次，确认无错
findmnt --verify         # 校验 fstab 语法
```

> 用 `UUID=` 比用 `/dev/sdXn` 更稳（设备名可能变化）：
> `UUID=xxxx-xxxx  /mnt/data  ext4  defaults  0  2`

---

## 六、查看挂载信息

```bash
mount                              # 原始输出（设备/类型/挂载点/选项）
findmnt                            # 更清晰的树状显示（推荐）
lsblk                              # 只看磁盘/分区结构
df -h                              # 各挂载点的空间使用
cat /proc/mounts                   # 内核当前真实挂载表
```

- `findmnt -t ext4`：只看某种类型
- `findmnt /mnt/data`：查某个挂载点
- `lsblk -f`：带文件系统类型和 UUID 的磁盘树

---

## 七、安全与注意事项

1. **卸载前先 `cd` 出挂载点**，否则会 busy。
2. **`umount -f` 极少用**，可能损坏数据，只在 NFS 之类卡死时用。
3. **挂载不需要 root**：如果 fstab 里加了 `user` 选项，或系统配置了 udisks（桌面环境自动挂载 U盘）。
4. **U 盘要「安全弹出」**：`umount` 就是 Linux 的安全弹出，强制断开可能与「Windows 未删除硬件」同理伤数据。
5. **别在系统关键分区上乱挂载**。

---

## 八、速查小抄

```bash
sudo mount /dev/sdb1 /mnt            # 挂载
sudo mount -t vfat /dev/sdb1 /mnt    # 指定 FAT32 挂载
sudo mount -o loop a.iso /mnt        # 挂载 ISO
sudo umount /mnt                      # 卸载
sudo umount /mnt                      # 失败( busy )时
lsof +D /mnt | 找占用 → umount        # 排查流程
sudo umount -l /mnt                   # 懒卸载
sudo mount -a                         # 挂载 fstab 全部
findmnt                              # 查看挂载
lsblk                                # 看磁盘
```

---

## 参考 & 扩展

- `findmnt`：更现代、更清晰的挂载查看工具（更推荐）
- `lsblk`：磁盘/分区/挂载点总览
- `udisksctl`：桌面下挂载外部磁盘
- `mount --bind`：把目录绑定到另一位置（高级）

_关键字：mount, umount, 挂载, 卸载, fstab, findmnt, lsblk, 磁盘, 文件系统_