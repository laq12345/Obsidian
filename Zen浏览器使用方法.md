---
date: 2026-05-05
tags:
  - 浏览器
  - zen
  - 工具
---
# Zen Browser 使用指南

## 目录
- [书签 (Bookmarks)](#书签-bookmarks)
- [紧凑模式 (Compact Mode)](#紧凑模式-compact-mode)
- [扩展 (Extensions)](#扩展-extensions)
- [Glance 预览](#glance-预览)
- [画中画 (Picture-in-Picture)](#画中画-picture-in-picture)
- [键盘快捷键 (Keyboard Shortcuts)](#键盘快捷键-keyboard-shortcuts)
- [分屏视图 (Split View)](#分屏视图-split-view)
- [翻译 (Translations)](#翻译-translations)
- [地址栏与搜索 (URL Bar & Search)](#地址栏与搜索-url-bar--search)
- [窗口同步与恢复 (Window Sync & Recovery)](#窗口同步与恢复-window-sync--recovery)
- [工作空间 (Workspaces)](#工作空间-workspaces)

---

## 书签 (Bookmarks)

Zen 基于 Firefox，继承其书签系统并进行了增强。

### 布局模式
- **单工具栏布局**：紧凑地址栏集成到垂直标签栏中，需先点击展开地址栏才能看到书签图标
- **多工具栏布局**：传统完整地址栏位于独立的水平工具栏

### 添加书签
- 点击地址栏的书签图标
- 快捷键：`Ctrl+D`
- 右键标签页 → `Bookmark Tab...`（支持添加标签和关键词）
- 多选标签页后右键 → `Bookmark Tabs...`（批量保存为书签文件夹）

### 管理书签
| 位置 | 说明 |
|------|------|
| **书签工具栏** | 位于浏览器顶部，单工具栏模式下悬停顶部边缘可显示 |
| **书签菜单** | 通过书签侧边栏或书签库访问 |
| **其他书签** | 杂项未分类书签，可右键隐藏 |

### 访问方式
- **最近书签**：点击工具栏 `...` → `Bookmarks`
- **书签侧边栏**：`Ctrl+B`
- **书签库**：`Ctrl+Shift+O` 或菜单 → `Bookmarks` → `Manage bookmarks`（支持导入和备份）

### 高级设置（about:config）
- `browser.toolbars.bookmarks.visibility = 'never'`：完全隐藏书签工具栏
- `zen.view.experimental-no-window-controls = 'true'`：禁用悬停窗口控件

---

## 紧凑模式 (Compact Mode)

隐藏所有浏览器工具栏，获得更宽阔的网页浏览视野。

### 启用方式
- 右键工具栏空白区域 → `Compact Mode` → `Enable compact mode`
- 快捷键：`Ctrl+S`

### 隐藏选项（多工具栏/折叠工具栏模式）
- **Hide sidebar**：隐藏标签侧边栏（悬停边缘可恢复）
- **Hide toolbar**：隐藏顶部工具栏（悬停顶部边缘可恢复）
- **Hide both**：同时隐藏两者

### 快捷键
| 操作 | 快捷键 |
|------|--------|
| 切换浮动侧边栏 | `Alt+Ctrl+S` |
| 切换浮动工具栏 | `Alt+Ctrl+W` |

---

## 扩展 (Extensions)

Zen 基于 Firefox，可从 [addons.mozilla.org](https://addons.mozilla.org) 安装扩展。

> **注意**：Zen 不支持 Firefox 主题。扩展影响网页内容，而 Zen Mods（CSS）仅影响浏览器 UI。

### 管理扩展
- **设置中心**：点击地址栏设置图标，可固定到工具栏、管理、移除扩展
- **附加组件管理器**：`Ctrl+Shift+A` 或菜单 → `Add-ons and themes`
  - 查看详情、管理偏好、分配快捷键、启用/禁用扩展
  - 可设置是否在隐私窗口或受限站点运行

### 扩展快捷键
附加组件管理器 → 齿轮菜单 → `Manage Extension Shortcuts`

---

## Glance 预览

在当前标签页上方快速预览网页，无需完全切换。

### 使用方法
- 按住 `Alt` 点击链接打开预览
- 在 Essentials 和固定标签页中，点击外部链接会自动创建 Glance

### 操作按钮
| 按钮 | 功能 |
|------|------|
| 关闭 | 关闭预览（或点击预览区域外） |
| 展开 | 在新标签页中打开 |
| 分屏 | 添加为分屏标签 |

### 设置
`Settings` → `Look and Feel` → `Glance`：可禁用或修改触发方式（`Ctrl+Click` / `Shift+Click`）

---

## 画中画 (Picture-in-Picture)

将视频弹出为始终置顶的浮动窗口。

### 启用方式
1. **视频悬浮按钮**：悬停视频时出现 Zen PiP 切换按钮
2. **地址栏图标**：单视频页面地址栏显示 PiP 图标
3. **右键菜单**：右键视频选择 PiP（YouTube 等使用自定义菜单时，用 `Shift+右键` 或双击右键）
4. **自动迷你播放器**：切换标签时视频自动进入右下角浮动播放器（需在 `about:config` 中开启 `media.videocontrols.picture-in-picture.enable-when-switching-tabs.enabled`）

### 快捷键
| 操作 | 快捷键 |
|------|--------|
| 开启/关闭 PiP | `Ctrl+Shift+]` |
| 静音/取消静音 | `Ctrl+↓` / `Ctrl+↑` |
| 音量调节 | `↑` / `↓` |
| 快退/快进 5 秒 | `←` / `→` |
| 快退/快进 10% | `Ctrl+←` / `Ctrl+→` |
| 跳到开始/结尾 | `Home` / `End` |
| 暂停/播放 | `Space` |
| 全屏切换 | 双击 或 `F` |
| 关闭 PiP 窗口 | `Ctrl+W` |

### 字幕支持
在开启 PiP 前打开字幕即可。支持 YouTube、Netflix、Disney+、Amazon Prime Video 等及所有使用 WebVTT 的网站。

### 媒体播放器
后台标签播放音频时，侧边栏底部会出现媒体控制器。

---

## 键盘快捷键 (Keyboard Shortcuts)

所有快捷键可在 `Settings` → `Keyboard Shortcuts` 中自定义。

### 常用快捷键
| 操作 | 快捷键 |
|------|--------|
| 新窗口 | `Ctrl+N` |
| 新标签页 | `Ctrl+T` |
| 关闭标签页 | `Ctrl+W` |
| 恢复关闭的标签 | `Shift+Ctrl+T` |
| 切换标签页 | `Ctrl+Tab` / `Ctrl+Shift+Tab` |
| 选择标签 #1-#8 | `Alt+1` ~ `Alt+8` |
| 选择最后一个标签 | `Alt+9` |
| 聚焦搜索/地址栏 | `Ctrl+K` / `Ctrl+J` / `Ctrl+L` / `Alt+D` |
| 页面内查找 | `Ctrl+F` |
| 书签当前页 | `Ctrl+D` |
| 截图 | `Shift+Ctrl+S` |
| 切换阅读模式 | `Alt+Ctrl+R` |
| 复制当前 URL | `Shift+Ctrl+C` |
| 复制 URL 为 Markdown | `Alt+Shift+Ctrl+C` |
| 切换侧边栏宽度 | `Alt+B` |
| 开发者工具 | `Shift+Ctrl+I` |
| 隐私浏览窗口 | `Shift+Ctrl+P` |

### 切换设置
在快捷键设置页中，点击输入框按下新组合，绿色边框表示保存成功，红色边框表示冲突。

---

## 分屏视图 (Split View)

最多支持 4 个标签页并排显示。

### 创建分屏
- 拖拽侧边栏标签页到另一标签页的左/右侧，出现分屏指示器后松开
- 右键链接 → `Split link in new tab`

### 使用分屏
- **拖动手柄**（`:::`）：调整分屏位置（左、右、上、下）
- **取消分屏**（`‒`）：移除单个标签的分屏
- **全部分屏**：`Alt+Ctrl+U`

### 布局快捷键
| 操作 | 快捷键 |
|------|--------|
| 水平分屏 | `Alt+Ctrl+H` |
| 垂直分屏 | `Alt+Ctrl+V` |
| 网格分屏 | `Alt+Ctrl+G` |

---

## 翻译 (Translations)

基于 Firefox 的本地翻译功能，不依赖云服务。

### 翻译整页
- 访问外语页面时自动弹出翻译面板
- 手动：菜单 → `Translate page` 或地址栏翻译按钮
- 可选择检测语言和目标语言
- 首次使用需下载语言包（约 20-60 秒）

### 翻译选中文字
- 选中文字 → 右键 → `Translate Selection to...`
- 支持复制链接文字翻译：右键超链接 → `Translate Link Text to...`

### 翻译设置
- **翻译面板齿轮按钮**：
  - `Always offer to translate`：自动提示翻译
  - `Always translate...` / `Never translate...`：按语言设置
  - `Never translate this site`：排除特定站点
- **Settings** → `General` → `Language & Appearance`：
  - 管理首选语言顺序
  - 下载离线语言包（总大小约 1.3 GB，单个语言 17-116 MB）
  - 管理始终翻译/从不翻译的语言列表和站点列表

### 支持语言
阿拉伯语、中文（简体）、法语、德语、日语、韩语、俄语、西班牙语等 33 种语言，持续增加中。

---

## 地址栏与搜索 (URL Bar & Search)

Zen 使用浮动地址栏替代传统新标签页。

### 地址栏行为
点击新标签页按钮时，地址栏浮动在页面中央，直接输入搜索词或 URL 即可。输入内容即使关闭地址栏也会被保留。

### 浮动模式设置（`Settings` → `Look and Feel` → `Zen URL Bar`）
| 模式 | 说明 |
|------|------|
| **Floating only when typing**（默认） | 通过快捷键或新标签页按钮时浮动，点击时固定 |
| **Always floating** | 始终浮动在中央 |
| **Normal** | 始终固定在顶部 |

### 搜索引擎
- 默认提供 Google、DuckDuckGo、Wikipedia
- 可在 `Settings` → `Search` 中管理：
  - 设置常规/隐私窗口默认搜索引擎
  - 开关搜索建议、最近搜索
  - 选择建议来源（历史、书签、剪贴板、打开的标签页）

### 添加自定义搜索引擎
- 访问支持 OpenSearch 的站点 → 右键地址栏 → `Add "网站名"`
- 手动添加：`Settings` → `Search` → `Search Shortcuts` → `Add`
  - 可设置名称、搜索 URL（`%s` 代替搜索词）、自定义关键词
- 使用关键词：新标签页按钮 → 输入关键词 → `Space` → 输入搜索内容

### 恢复传统新标签页
`about:config` → `zen.urlbar.replace-newtab` 设为 `false`

---

## 窗口同步与恢复 (Window Sync & Recovery)

Zen 在同一设备上同步所有窗口的状态。

### 窗口同步
- 新窗口自动镜像现有标签页状态
- 选择同一标签页时，非活动窗口显示页面缩略预览
- 使用 `Ctrl+Q` 或菜单 `Quit` 退出可保存所有窗口状态，重启后恢复

### 空白窗口
- 菜单 → `New blank window` 或 `Ctrl+Shift+N`
- 标签页临时存在，重启后不恢复
- 可通过 `Move to...` 将标签页移回已有 Space

### 恢复丢失的会话
**Zen v1.18+**：
1. 关闭 Zen
2. 打开配置文件目录（`about:support` → `Profile Directory` → `Open Directory`）
3. 进入 `zen-sessions-backup` 文件夹
4. 复制最新的 `zen-sessions-<日期>.jsonlz4`，重命名为 `zen-sessions.jsonlz4`
5. 复制到配置文件根目录，重启 Zen

### 跨设备同步
当前仅支持同设备同步。跨设备可使用 Firefox 账号的 **Send to Device** 功能发送标签页。

---

## 工作空间 (Workspaces)

按任务、项目或主题组织标签页。

### 创建工作空间
- 点击侧边栏的 `Default` → 点击 `+` 图标
- 可自定义图标和名称
- 工作空间图标显示在侧边栏底部

### 容器标签页 (Container Tabs)
提供独立的 Cookie 会话，可在同一网站登录多个账号。

| 默认容器 | 颜色标识 |
|----------|----------|
| Personal | 蓝色 |
| Work | 橙色 |
| Banking | 绿色 |
| Shopping | 粉色 |

### 使用容器标签页
- 右键 `New Tab` 按钮 → 选择容器
- 右键已有标签页 → `Open in New Container Tab`
- 右键链接 → `Open Link in New Container Tab`

### 容器与工作空间联动
- 可为每个工作空间分配默认容器
- 开启 `Switch to workspace where container is set as default when opening container tabs`（`Settings` → `Tab Management` → `Workspaces`）可在打开容器标签页时自动切换到对应工作空间

### 管理容器
`Settings` → `General` → `Container Tabs`：9 种颜色、13 种图标可自定义创建

> **限制**：容器标签页仅隔离 Cookie/浏览会话，不隔离浏览历史和扩展。

