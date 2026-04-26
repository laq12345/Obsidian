---
date: 2026-04-26
tags:
  - EFI
  - linux
  - 重装系统
---
## 以管理员身份运行 CMD 或 PowerShell，依次执行：
diskpart
list disk          ← 确认磁盘0是你的Linux盘（465GB）
select disk 0      ← 选择磁盘0
clean              ← ⚠️ 这会清空整个磁盘0，包括EFI分区