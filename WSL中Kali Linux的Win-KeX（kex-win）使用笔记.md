---
date: 2026-04-20
tags:
  - wsl
  - kali
  - win-kex
  - kex
  - vnc
---

# WSL 中 Kali Linux 的 Win-KeX（kex-win）使用笔记

> 主题：重点讲解 `kex --win`（Window Mode）
> 参考文档：
> - https://www.kali.org/docs/wsl/win-kex/
> - https://www.kali.org/docs/wsl/win-kex-win/
> - https://www.kali.org/docs/wsl/win-kex-sl/
> - https://www.kali.org/docs/wsl/win-kex-esm/
> 整理时间：2026-04-20

---

## 1. Win-KeX 是什么

Win-KeX 是 Kali 在 WSL 2 中提供的图形桌面方案，让你在 Windows 上运行 Kali GUI。

它主要有 3 种模式：

1. **Window Mode（`--win`）**：Kali 桌面在独立窗口中运行（本文重点）
2. **Seamless Mode（`--sl`）**：Kali 应用与 Windows 桌面融合显示
3. **Enhanced Session Mode（`--esm`）**：基于 RDP，ARM 设备上尤为常用

Win-KeX 的优势：

- WSL 里直接获得 Kali 图形环境
- 支持剪贴板共享
- 支持声音（PulseAudio）
- 支持 root / 非 root 会话并行
- 支持多会话管理

---

## 2. kex --win 的定位与原理

`kex --win` 是 Win-KeX 的 Window Mode。

- **表现形态**：启动一个独立的 Kali 图形桌面窗口
- **底层技术**：Win-KeX Window Mode 使用 **TigerVNC** 客户端/服务端
- **默认模式**：在多数 x86/x64 Windows 设备上，`kex` 默认就是 window mode
  - 所以 `kex` 与 `kex --win` 通常等价

适合场景：

- 想让 Windows 与 Kali 视觉上分离，避免混在一起
- 希望操作逻辑接近“单独一台 Kali 桌面”
- 不想使用 RDP 的 ESM 路径

---

## 3. 前置条件

建议最少满足：

1. Windows 已启用 WSL 2
2. 已安装 Kali Linux（Microsoft Store 版或导入版）
3. 可正常进入 Kali 终端
4. 网络正常，能安装 apt 包

可选但推荐：

- Windows Terminal（便于配置一键启动）

---

## 4. 安装与初始化

在 Kali WSL 内执行：

```bash
sudo apt update
sudo apt install -y kali-win-kex
```

首次启动（普通用户）：

```bash
kex --win
# 或简写
kex
```

第一次启动会要求你设置 VNC 密码（Window Mode 使用）。

---

## 5. 高频命令速查（kex-win）

### 5.1 启动会话

```bash
# 普通用户启动 Window Mode
kex --win

# 默认模式通常就是 --win
kex

# 启用声音
kex --win --sound
# 等价
kex --win -s
```

也可在 Windows 侧直接调用（不先进入 Kali shell）：

```powershell
wsl -d kali-linux kex --win -s
```

### 5.2 root 会话

```bash
sudo kex --win
```

注意：root 会话连接时，客户端通常会要求输入 VNC 密码。

### 5.3 修改密码

```bash
# 修改当前用户的 kex(VNC) 密码
kex --passwd

# 修改 root 的 kex(VNC) 密码
sudo kex --passwd
```

### 5.4 断开与重连

- 在图形窗口中按 `F8` 打开 TigerVNC 菜单
- 选择 `Exit viewer`：只关闭客户端窗口，会话可能仍在后台

后台会话重连：

```bash
kex --win --start-client
```

### 5.5 停止会话

```bash
kex --win --stop
```

这会关闭/停止 Window Mode 相关服务端会话。

---

## 6. 声音与防火墙

启用声音示例：

```bash
kex --win --sound
```

首次开启声音时，Windows Defender 防火墙可能弹窗询问放行。

建议：

- 至少允许当前网络类型（常见为 Public networks）
- 如果误点拒绝，后续可去防火墙中重新放行相关组件

---

## 7. 多屏与显示行为

Win-KeX Window Mode 支持多显示器。

调整思路（TigerVNC 客户端内）：

1. `F8` 打开菜单
2. 进入 `Options -> Screen`
3. 取消 `Enable full-screen mode over all monitors`
4. 临时退出全屏，将窗口拖到目标显示器
5. 再开启全屏

如果出现 DPI/缩放不理想：

- 优先尝试 Windows 显示缩放调整
- 或改用 `--esm`（RDP 路径在某些 HiDPI 设备上显示更“锐”）

---

## 8. 会话管理最佳实践

### 8.1 普通用户与 root 分离

建议把日常操作放在普通用户会话里，只有确需时再进 root 图形会话：

- 安全性更高
- 降低误操作风险

### 8.2 关闭方式建议

- 临时离开：直接 `Exit viewer`，后续 `--start-client` 重连
- 下班收工：执行 `kex --win --stop`，避免后台残留

### 8.3 命令别名（可选）

可在 shell 中加别名：

```bash
alias kx='kex --win'
alias kxs='kex --win -s'
alias kxstop='kex --win --stop'
```

---

## 9. Windows Terminal 一键启动（实用）

在 Windows Terminal profile 中可配置：

```json
{
  "name": "Win-KeX",
  "commandline": "wsl -d kali-linux kex --wtstart -s"
}
```

说明：

- `--wtstart` 用于 Win-KeX 与 Windows Terminal 的启动协作
- 可结合 `startingDirectory` 指向 `//wsl$/kali-linux/home/<kali-user>`

---

## 10. 常见问题排查

### 10.1 `kex: command not found`

原因：未安装或安装异常。

处理：

```bash
sudo apt update
sudo apt install -y kali-win-kex
```

### 10.2 能启动但黑屏/闪退

可按以下顺序排查：

1. 更新系统后重试

```bash
sudo apt update && sudo apt full-upgrade -y
```

2. 停掉旧会话再重启

```bash
kex --win --stop
kex --win
```

3. 在 Windows 侧执行 `wsl --shutdown` 后重进 Kali

4. 查看是否有防火墙拦截弹窗被拒绝

### 10.3 密码错误或忘记

重置：

```bash
kex --passwd
# 或 root
sudo kex --passwd
```

### 10.4 声音不可用

- 确认用 `-s/--sound` 启动
- 检查防火墙是否放行
- 先 `--stop` 再带 `--sound` 重启

---

## 11. 与其他模式的选择建议

1. 优先 `--win`：
   - 追求“完整 Kali 桌面窗口”
   - 希望与 Windows 桌面隔离

2. 选 `--sl`：
   - 希望 Kali 应用与 Windows 应用并排混用
   - 追求跨系统工作流融合

3. 选 `--esm`：
   - 在 ARM 上是官方重点支持路径
   - 对 HiDPI 清晰度体验有更高要求

---

## 12. 建议的日常命令流

```bash
# 1) 启动（带声音）
kex --win -s

# 2) 临时关闭客户端窗口后，重连
kex --win --start-client

# 3) 完全结束
kex --win --stop
```

---

## 13. 补充说明

- `kex --help` 可以查看当前版本支持的全部参数
- `man kex` 可查看手册页
- 官方文档更新较快，遇到行为差异时，以 Kali 官方页面为准

```bash
kex --help
man kex
```

---

## 14. 一句话总结

`kex --win` 是 WSL 中 Kali 图形化最稳妥、最直观的入口：用它快速开桌面、用 `--sound` 补齐多媒体、用 `--start-client` 重连、用 `--stop` 收尾，就能形成高效且可控的日常工作流。
