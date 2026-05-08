---
date: 2026-04-25
lang: Linux
tags:
  - systemd
  - linux
  - 工具
  - fedora
---

# Fedora 上 systemd 系统化学习笔记（非常详细版）

> 适用系统：Fedora（含 Workstation / Server）  
> 目标读者：想从“会用 `systemctl`”进阶到“能设计、调优、排障、加固服务”的用户  
> 学习产出：你可以独立编写可靠的 `service/timer`、理解启动依赖、完成常见故障排查

---

## 目录

1. [学习目标与整体路线](#1-学习目标与整体路线)
2. [systemd 的定位与架构](#2-systemd-的定位与架构)
3. [Unit 基础模型与状态机](#3-unit-基础模型与状态机)
4. [Unit 文件路径、优先级与覆盖机制](#4-unit-文件路径优先级与覆盖机制)
5. [核心命令体系（systemctl / journalctl / systemd-analyze）](#5-核心命令体系systemctl--journalctl--systemd-analyze)
6. [service 单元深度解析](#6-service-单元深度解析)
7. [依赖与顺序：`Requires/Wants/After/Before` 彻底讲清](#7-依赖与顺序requireswantsafterbefore-彻底讲清)
8. [日志系统 journald 深入](#8-日志系统-journald-深入)
9. [timer 定时任务（替代 cron）](#9-timer-定时任务替代-cron)
10. [socket/path/mount/automount 等进阶 Unit](#10-socketpathmountautomount-等进阶-unit)
11. [用户级 systemd（`systemctl --user`）](#11-用户级-systemdsystemctl---user)
12. [资源控制（cgroup v2）与性能治理](#12-资源控制cgroup-v2与性能治理)
13. [systemd 安全加固实践](#13-systemd-安全加固实践)
14. [Fedora 结合 SELinux 的注意事项](#14-fedora-结合-selinux-的注意事项)
15. [启动流程、目标态与应急模式](#15-启动流程目标态与应急模式)
16. [故障排查方法论（生产可用）](#16-故障排查方法论生产可用)
17. [实战实验手册（按步骤练）](#17-实战实验手册按步骤练)
18. [生产环境最佳实践清单](#18-生产环境最佳实践清单)
19. [常见误区与反模式](#19-常见误区与反模式)
20. [速查附录（命令卡片 + 指令速览）](#20-速查附录命令卡片--指令速览)

---

## 1) 学习目标与整体路线

### 1.1 你需要掌握的能力

- 能独立编写并部署一个长期运行服务（`*.service`）
- 能把脚本任务迁移到 `*.timer`，并实现掉电补跑
- 能通过 `journalctl` 快速定位启动失败根因
- 能理解依赖图，避免“看起来启动了但业务不可用”
- 能对关键服务做资源限制和安全加固
- 能结合 Fedora + SELinux 处理权限与上下文问题

### 1.2 建议学习节奏（2~3 周）

- 第 1 周：命令与状态（`systemctl status`, `journalctl`）
- 第 2 周：写 unit（service + timer + override）
- 第 3 周：安全、资源、排障与启动性能分析

---

## 2) systemd 的定位与架构

### 2.1 它不只是“启动服务”

`systemd` 是 Linux 用户态的核心管理器（PID 1），负责：

- 系统引导后的用户空间初始化
- 服务生命周期管理（启动、停止、重启、重载、失败恢复）
- 依赖关系和并行启动编排
- 日志汇聚（`journald`）
- 会话与登录（`logind`）
- 资源分组与限制（cgroup）

### 2.2 systemd 生态中的主要组件

- `systemd`：主进程（PID 1），负责 unit 状态机与调度
- `systemctl`：管理入口（CLI）
- `systemd-journald`：结构化日志守护进程
- `systemd-logind`：登录会话与 seat 管理
- `systemd-udevd`：设备事件管理
- `systemd-tmpfiles`：临时文件与目录策略
- `systemd-resolved`：DNS 解析服务（Fedora 默认未必启用）
- `systemd-networkd`：网络管理（Fedora 常用 NetworkManager 替代）

### 2.3 与 SysV init 的核心差异

- 传统 SysV：脚本串行 + runlevel
- systemd：声明式 unit + 依赖图 + 并行 + cgroup + 统一日志

---

## 3) Unit 基础模型与状态机

### 3.1 Unit 是什么

Unit 是 systemd 管理对象，按后缀区分类型：

- `.service`：服务进程
- `.timer`：定时触发器
- `.socket`：套接字激活
- `.target`：目标态（类似运行阶段）
- `.mount` / `.automount`：挂载与按需挂载
- `.path`：文件路径变化触发
- `.slice` / `.scope`：资源分组

### 3.2 Unit 状态字段（看懂 `systemctl status`）

- `Loaded`：是否加载成功，配置从哪里加载
- `Active`：宏观状态（`active/inactive/failed`）
- `Sub`：细粒度子状态（如 `running/exited/dead`）

示例：

```bash
systemctl status sshd.service
```

你需要重点看：

- `Loaded` 是否指向预期路径
- `Active` 是否 `active (running)`
- `Main PID` 是否存在
- 末尾日志中的第一条错误信息

### 3.3 Unit 之间通过“依赖图”协作

systemd 并不是按固定顺序硬编码启动，而是通过 unit 之间声明关系进行拓扑调度。

---

## 4) Unit 文件路径、优先级与覆盖机制

### 4.1 系统级 unit 路径（Fedora）

- `/usr/lib/systemd/system`：rpm 包提供（不要手改）
- `/etc/systemd/system`：管理员自定义（优先级更高）
- `/run/systemd/system`：运行时动态配置

### 4.2 用户级 unit 路径

- `~/.config/systemd/user`
- `/etc/systemd/user`
- `/usr/lib/systemd/user`

### 4.3 覆盖优先级

`/etc` > `/run` > `/usr/lib`

### 4.4 正确修改方式：drop-in 覆盖

不要直接改 `/usr/lib/systemd/system/*.service`。使用：

```bash
sudo systemctl edit nginx.service
```

会生成：

- `/etc/systemd/system/nginx.service.d/override.conf`

查看合并后的最终配置：

```bash
systemctl cat nginx.service
```

查看覆盖差异：

```bash
systemd-delta
```

---

## 5) 核心命令体系（systemctl / journalctl / systemd-analyze）

### 5.1 `systemctl`：生命周期管理

```bash
# 启动 / 停止 / 重启 / 重载
sudo systemctl start NAME.service
sudo systemctl stop NAME.service
sudo systemctl restart NAME.service
sudo systemctl reload NAME.service

# 开机启用 / 禁用
sudo systemctl enable NAME.service
sudo systemctl disable NAME.service

# 同时开机启用并立即启动
sudo systemctl enable --now NAME.service

# 查看状态
systemctl status NAME.service

# 列出运行中的服务
systemctl list-units --type=service --state=running

# 列出已安装 unit 文件
systemctl list-unit-files --type=service
```

### 5.2 `mask` 与 `disable` 区别

- `disable`：取消开机自启，但允许手动/依赖启动
- `mask`：彻底屏蔽，链接到 `/dev/null`，任何方式都无法启动（除非 `unmask`）

### 5.3 `daemon-reload` 什么时候需要

当你修改了 unit 文件内容或 drop-in 文件后，必须：

```bash
sudo systemctl daemon-reload
```

### 5.4 `journalctl`：统一日志入口

```bash
# 查看某服务日志
journalctl -u NAME.service

# 跟随日志
journalctl -u NAME.service -f

# 仅本次启动日志
journalctl -u NAME.service -b

# 上一次开机日志
journalctl -b -1

# 某时间窗口
journalctl --since "2026-04-25 10:00" --until "2026-04-25 12:00"

# 仅 warning 以上
journalctl -p warning..emerg
```

### 5.5 `systemd-analyze`：启动与配置分析

```bash
systemd-analyze time
systemd-analyze blame
systemd-analyze critical-chain
sudo systemd-analyze verify /etc/systemd/system/myapp.service
systemd-analyze security myapp.service
```

---

## 6) service 单元深度解析

### 6.1 典型 service 文件结构

```ini
[Unit]
Description=My App Service
After=network-online.target
Wants=network-online.target

[Service]
Type=exec
User=myapp
Group=myapp
WorkingDirectory=/opt/myapp
Environment=APP_ENV=prod
EnvironmentFile=-/etc/myapp/myapp.env
ExecStart=/usr/bin/python3 /opt/myapp/app.py
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=3s
TimeoutStartSec=30s
TimeoutStopSec=20s
KillMode=control-group

[Install]
WantedBy=multi-user.target
```

### 6.2 `[Unit]` 常用字段

- `Description=`：描述
- `Documentation=`：文档链接或 man 页
- `After=/Before=`：顺序约束
- `Wants=/Requires=`：依赖强度
- `PartOf=`：联动停止/重启
- `ConditionPathExists=`：条件满足才启动

### 6.3 `[Service]` 常用字段（重点）

- `Type=`：进程模型（见下节）
- `ExecStart=`：启动命令（必须是绝对路径）
- `ExecStartPre=/ExecStartPost=`：前后钩子
- `ExecStop=`：停止命令
- `User=/Group=`：运行身份
- `WorkingDirectory=`：工作目录
- `Environment=` / `EnvironmentFile=`：环境变量
- `Restart=`：失败恢复策略
- `TimeoutStartSec=/TimeoutStopSec=`：超时控制
- `LimitNOFILE=`：文件句柄上限

### 6.4 `Type=` 如何选

- `simple`：默认，启动命令执行后即视为启动完成
- `exec`：更严格，等待 `execve` 成功
- `forking`：兼容老式守护进程（不推荐新项目使用）
- `oneshot`：一次性任务（可配 `RemainAfterExit=yes`）
- `notify`：服务主动上报就绪（生产常见，需程序支持）

推荐：

- 新服务优先 `Type=exec` 或 `Type=notify`
- 避免强行把前台程序写成 `forking`

### 6.5 `ExecStart` 的关键规则

- 不自动通过 shell 执行
- shell 特性（`|`, `>`, `&&`）默认不可直接用
- 若确实需要 shell，显式写：

```ini
ExecStart=/bin/bash -lc 'cmd1 && cmd2'
```

但通常建议改成脚本文件，便于可维护和审计。

### 6.6 自动恢复与限流

```ini
Restart=on-failure
RestartSec=2s
StartLimitIntervalSec=60
StartLimitBurst=5
```

含义：60 秒内最多失败重启 5 次，避免无限重启风暴。

---

## 7) 依赖与顺序：`Requires/Wants/After/Before` 彻底讲清

### 7.1 两个维度

- 依赖维度：要不要对方（`Requires/Wants`）
- 顺序维度：先后顺序（`After/Before`）

### 7.2 常见组合

```ini
Wants=network-online.target
After=network-online.target
```

解释：

- 想要网络在线（弱依赖）
- 并且本服务在其后启动

### 7.3 为什么只写 `After=network.target` 常出问题

- `network.target` 只是“网络栈启动了”
- 不代表地址、路由、DNS 一定可用
- 需要“可用网络”通常应使用 `network-online.target`

### 7.4 其他重要关系

- `BindsTo=`：更强绑定，被依赖消失会触发本 unit 停止
- `PartOf=`：从属联动（常用于 sidecar）
- `Conflicts=`：互斥关系

---

## 8) 日志系统 journald 深入

### 8.1 为什么 journald 好用

- 按 unit、boot、优先级、时间过滤
- 结构化字段（如 `_PID`, `_SYSTEMD_UNIT`）
- 与 systemd 生命周期天然关联

### 8.2 持久化日志（Fedora 常见需求）

默认可能是内存日志。启用持久化：

```bash
sudo mkdir -p /var/log/journal
sudo systemctl restart systemd-journald
```

### 8.3 常用排查命令

```bash
# 最近 200 行 + 本次启动
journalctl -u myapp.service -b -n 200

# 实时追踪
journalctl -u myapp.service -f

# 仅错误及以上
journalctl -u myapp.service -p err..emerg
```

### 8.4 容量治理

```bash
journalctl --disk-usage
sudo journalctl --vacuum-size=500M
sudo journalctl --vacuum-time=14d
```

---

## 9) timer 定时任务（替代 cron）

### 9.1 timer 的优势

- 与 unit 统一管理与日志
- 可表达依赖（比如网络就绪后执行）
- `Persistent=true` 支持错过任务补跑

### 9.2 组成关系

- `job.service`：任务本体
- `job.timer`：触发器

### 9.3 示例：每日备份

`/etc/systemd/system/backup.service`

```ini
[Unit]
Description=Backup job

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup.sh
```

`/etc/systemd/system/backup.timer`

```ini
[Unit]
Description=Daily backup timer

[Timer]
OnCalendar=*-*-* 03:30:00
Persistent=true
RandomizedDelaySec=10m

[Install]
WantedBy=timers.target
```

启用：

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now backup.timer
systemctl list-timers --all
```

### 9.4 常用时间表达式

- `OnCalendar=daily`
- `OnCalendar=Mon..Fri 09:00`
- `OnCalendar=*-*-01 00:00:00`（每月 1 号）
- `OnBootSec=5min`（开机 5 分钟后）
- `OnUnitActiveSec=1h`（每次执行后 1 小时）

---

## 10) socket/path/mount/automount 等进阶 Unit

### 10.1 socket 激活

适合低频服务：有连接请求时再拉起服务，节省资源。

- `myapi.socket` 监听端口或 unix socket
- `myapi.service` 处理请求

### 10.2 path 触发

监控文件变化触发服务，例如：目录出现新文件时自动处理。

- `Watcher.path` + `Watcher.service`

### 10.3 mount 与 automount

- `.mount`：声明挂载单元
- `.automount`：按需访问时再挂载，减少启动阻塞

### 10.4 slice 与 scope

- `slice`：服务资源分层（例如 `system.slice`, `user.slice`）
- `scope`：外部进程归组（常由桌面会话或 `systemd-run --scope` 生成）

---

## 11) 用户级 systemd（`systemctl --user`）

### 11.1 什么时候用

- 不需要 root 权限
- 个人开发服务、代理、同步程序

### 11.2 基本操作

```bash
systemctl --user daemon-reload
systemctl --user enable --now myuserapp.service
systemctl --user status myuserapp.service
journalctl --user -u myuserapp.service -f
```

### 11.3 退出登录后保持运行

```bash
sudo loginctl enable-linger <username>
```

### 11.4 用户级 unit 路径

- `~/.config/systemd/user/*.service`

---

## 12) 资源控制（cgroup v2）与性能治理

Fedora 默认 cgroup v2，可直接在 unit 中设置资源限制。

### 12.1 常用限制项

```ini
[Service]
CPUQuota=50%
MemoryMax=1G
TasksMax=512
IOWeight=200
```

### 12.2 查看资源树与实时占用

```bash
systemd-cgls
systemd-cgtop
```

### 12.3 设计建议

- 先观测后限制，避免“保护系统但压垮业务”
- 关键服务单独放在自定义 `.slice`，便于统一治理

---

## 13) systemd 安全加固实践

### 13.1 常见硬化指令（建议逐步启用）

```ini
[Service]
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/var/lib/myapp /var/log/myapp
PrivateDevices=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
RestrictSUIDSGID=yes
LockPersonality=yes
MemoryDenyWriteExecute=yes
SystemCallFilter=@system-service
```

### 13.2 能力裁剪

```ini
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
```

仅保留绑定低位端口所需能力，降低进程权限面。

### 13.3 快速评估安全评分

```bash
systemd-analyze security myapp.service
```

注意：评分用于指导，不是绝对标准，要结合业务实际。

---

## 14) Fedora 结合 SELinux 的注意事项

在 Fedora 上，很多“明明权限对了仍失败”的问题是 SELinux 拒绝导致。

### 14.1 先查 AVC 拒绝

```bash
sudo ausearch -m avc -ts recent
```

### 14.2 常见场景

- 可执行文件放在异常路径，上下文不对
- 服务写入目录未标注正确 type
- 非标准端口未授权给服务域

### 14.3 排查思路

- 先确认 systemd 错误日志
- 再看 SELinux 拒绝记录
- 必要时修复文件 context（而不是简单关闭 SELinux）

---

## 15) 启动流程、目标态与应急模式

### 15.1 目标态（target）可理解为“系统运行模式”

- `multi-user.target`：多用户文本模式
- `graphical.target`：图形模式
- `rescue.target`：救援模式
- `emergency.target`：极简应急模式
- `reboot.target` / `poweroff.target`

### 15.2 查看和修改默认目标

```bash
systemctl get-default
sudo systemctl set-default multi-user.target
```

### 15.3 引导性能定位

```bash
systemd-analyze time
systemd-analyze blame
systemd-analyze critical-chain
```

---

## 16) 故障排查方法论（生产可用）

### 16.1 八步流程

1. `systemctl status UNIT` 看第一现场
2. `journalctl -u UNIT -b -n 200` 看上下文
3. `systemctl cat UNIT` 确认生效配置
4. `systemd-analyze verify FILE` 做语法/依赖校验
5. 检查可执行路径、权限、解释器 shebang
6. 检查依赖服务/网络/挂载是否真的可用
7. Fedora 额外检查 SELinux AVC
8. 必要时临时放宽配置做二分定位，再收敛

### 16.2 快速定位“启动后秒退”

重点看：

- `Type` 是否与进程模型匹配
- 进程是否转后台导致 systemd 误判
- `WorkingDirectory` 和相对路径
- 环境变量是否缺失

### 16.3 快速定位“频繁重启”

检查：

- `Restart=` 是否过激
- `StartLimit*` 是否触发
- 应用是否因依赖未就绪启动失败

---

## 17) 实战实验手册（按步骤练）

> 建议在 Fedora 虚拟机或测试机进行。

### 实验 1：创建最小可运行服务

1. 创建程序：`/opt/hello/hello.sh`

```bash
sudo mkdir -p /opt/hello
sudo tee /opt/hello/hello.sh >/dev/null <<'EOF'
#!/usr/bin/env bash
while true; do
  date
  sleep 5
done
EOF
sudo chmod +x /opt/hello/hello.sh
```

2. 创建 unit：`/etc/systemd/system/hello.service`

```ini
[Unit]
Description=Hello loop service

[Service]
Type=exec
ExecStart=/opt/hello/hello.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

3. 启动并观察

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now hello.service
systemctl status hello.service
journalctl -u hello.service -f
```

### 实验 2：故意制造错误并排查

将 `ExecStart` 改成不存在路径，观察：

- `status` 的退出码
- `journalctl` 中 `No such file or directory`
- 修复后 `daemon-reload + restart`

### 实验 3：使用 drop-in 覆盖配置

```bash
sudo systemctl edit hello.service
```

添加：

```ini
[Service]
Environment=HELLO_MODE=prod
RestartSec=2s
```

验证：

```bash
systemctl cat hello.service
```

### 实验 4：把 cron 任务迁移到 timer

1. 写 `cleanup.service`（`Type=oneshot`）
2. 写 `cleanup.timer`（`OnCalendar=daily`, `Persistent=true`）
3. `enable --now cleanup.timer`
4. `systemctl list-timers --all`

### 实验 5：资源限制

给 `hello.service` 加：

```ini
[Service]
CPUQuota=20%
MemoryMax=100M
TasksMax=50
```

然后观察 `systemd-cgtop`。

### 实验 6：安全加固

逐个添加以下选项并验证功能是否正常：

- `NoNewPrivileges=yes`
- `PrivateTmp=yes`
- `ProtectSystem=full`
- `ProtectHome=yes`

每加一项就测试一次，最后运行：

```bash
systemd-analyze security hello.service
```

### 实验 7：用户级服务

在 `~/.config/systemd/user/` 写一个 `ticker.service`，通过 `systemctl --user` 管理。

### 实验 8：SELinux 场景排障

将服务日志写到一个非标准目录，触发拒绝后：

- 用 `ausearch` 查 AVC
- 修正 context 或目录策略
- 验证服务恢复

---

## 18) 生产环境最佳实践清单

### 18.1 配置管理

- 不改 `/usr/lib/systemd/system`
- 一律用 `/etc/systemd/system` 或 drop-in
- 所有 unit 纳入版本管理（Git）

### 18.2 可用性

- 合理使用 `Restart=on-failure`
- 配置 `StartLimit*` 防止重启风暴
- 关键依赖使用健康检查而不是盲目睡眠

### 18.3 可观测性

- 日志走 stdout/stderr，让 journald 收集
- 明确日志级别与关键事件
- 保持 `journalctl` 可检索性（包含上下文字段）

### 18.4 安全与隔离

- 非 root 运行（`User=`）
- 最小权限（capability 裁剪）
- 逐项硬化并回归测试

### 18.5 变更流程

- 修改 unit 后固定流程：`daemon-reload -> restart/reload -> status -> journalctl`
- 变更前后记录启动耗时、资源占用、错误率

---

## 19) 常见误区与反模式

- 误区 1：把 `After=` 当依赖用（它只是顺序）
- 误区 2：把 shell 一行命令直接塞进 `ExecStart=`
- 误区 3：每次都用 `Restart=always`，导致故障放大
- 误区 4：只看 `status` 不看 `journalctl`
- 误区 5：为了省事关闭 SELinux
- 误区 6：改了 unit 不执行 `daemon-reload`
- 误区 7：直接编辑包内 unit，升级后丢失

---

## 20) 速查附录（命令卡片 + 指令速览）

### 20.1 高频命令卡片

```bash
# 服务管理
systemctl status NAME.service
sudo systemctl enable --now NAME.service
sudo systemctl restart NAME.service
sudo systemctl reload NAME.service
sudo systemctl disable --now NAME.service
sudo systemctl mask NAME.service
sudo systemctl unmask NAME.service

# 配置检查
systemctl cat NAME.service
sudo systemctl edit NAME.service
sudo systemctl daemon-reload
systemd-delta
sudo systemd-analyze verify /etc/systemd/system/NAME.service

# 日志
journalctl -u NAME.service -b -n 200
journalctl -u NAME.service -f
journalctl -p warning..emerg -b
journalctl --disk-usage

# 启动性能
systemd-analyze time
systemd-analyze blame
systemd-analyze critical-chain

# timer
systemctl list-timers --all

# 用户服务
systemctl --user status
journalctl --user -u NAME.service -f
```

### 20.2 常见 unit 指令速览

| 分区 | 指令 | 用途 |
|---|---|---|
| `[Unit]` | `After=` | 启动顺序 |
| `[Unit]` | `Requires=` | 强依赖 |
| `[Unit]` | `Wants=` | 弱依赖 |
| `[Service]` | `Type=` | 进程模型 |
| `[Service]` | `ExecStart=` | 启动命令 |
| `[Service]` | `Restart=` | 异常恢复策略 |
| `[Service]` | `User=` | 运行用户 |
| `[Service]` | `WorkingDirectory=` | 工作目录 |
| `[Service]` | `Environment=` | 环境变量 |
| `[Service]` | `MemoryMax=` | 内存限制 |
| `[Install]` | `WantedBy=` | 启用挂载目标 |

### 20.3 推荐阅读 man 页面

```bash
man systemd
man systemd.unit
man systemd.service
man systemd.timer
man systemd.exec
man systemctl
man journalctl
```

---

## 结语

如果你把本笔记中的 8 个实验完整做完，并且每个实验都能解释“为什么这么配置”，你就已经具备了在 Fedora 上稳定管理绝大多数后台服务的能力。

下一步建议：

1. 选一个你常用应用（如 Flask/Go/Node）写成生产可用的 service
2. 为它加一个健康检查 timer
3. 做一轮“故意注入故障”的演练并写复盘
