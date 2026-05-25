---
date: 2026-05-25
tags:
  - 工具
  - linux
  - yazi
  - zellij
  - 设置
---

# Yazi + Zellij 图片/PDF 预览解决方案

## 问题

Zellij 作为终端复用器，不转发 Kitty 图形协议，导致 Yazi 在 Zellij 内无法预览图片和 PDF。

## 解决方案

双配置方案：Zellij 内外使用不同配置，Zellij 内用 noop preloader 阻止图片渲染，改用元数据文本预览。

## 修改清单

### 新增文件

| 文件                                        | 用途                              |
| ----------------------------------------- | ------------------------------- |
| `~/.config/yazi/scripts/preview-image.sh` | 图片元数据预览脚本                       |
| `~/.config/yazi/scripts/preview-pdf.sh`   | PDF 元数据预览脚本                     |
| `~/.config/yazi-zellij/yazi.toml`         | Zellij 专用配置                     |
| `~/.config/yazi-zellij/init.lua`          | 从主配置复制                          |
| `~/.config/yazi-zellij/keymap.toml`       | 从主配置复制                          |
| `~/.config/yazi-zellij/theme.toml`        | 从主配置复制                          |
| `~/.config/yazi-zellij/package.toml`      | 从主配置复制（插件声明，必须存在）               |
| `~/.config/yazi-zellij/plugins/`          | 软链接 → `~/.config/yazi/plugins/` |
| `~/.config/yazi-zellij/scripts/`          | 软链接 → `~/.config/yazi/scripts/` |
| `~/.config/yazi-zellij/flavors/`          | 软链接 → `~/.config/yazi/flavors/` |

### 修改文件

| 文件 | 改动 |
|------|------|
| `~/.zshrc` | `y()` 函数增加 `ZELLIJ_SESSION_NAME` 检测，自动切换 `YAZI_CONFIG_HOME` |

`.zshrc` 中 `y()` 函数的完整内容：

```zsh
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	if [ -n "$ZELLIJ_SESSION_NAME" ]; then
		YAZI_CONFIG_HOME="$HOME/.config/yazi-zellij" command yazi "$@" --cwd-file="$tmp"
	else
		command yazi "$@" --cwd-file="$tmp"
	fi
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}
```

### 未修改

`~/.config/yazi/yazi.toml` 保持原样，不含元数据预览器，确保 Zellij 外正常使用原生 Kitty 图形协议预览。

---

## 工作原理

```
y()
  ├─ Zellij 外  →  加载 ~/.config/yazi/       →  原生预览
  └─ Zellij 内  →  加载 ~/.config/yazi-zellij/ →  noop preloader 阻止图片渲染
                                                 →  piper 显示元数据
```

Zellij 配置关键差异：

```toml
# ~/.config/yazi-zellij/yazi.toml 比主配置多出的内容

[[plugin.prepend_preloaders]]
mime = "image/*"
run  = "noop"                # 阻止 Yazi 尝试渲染图片

[[plugin.prepend_preloaders]]
mime = "application/pdf"
run  = "noop"                # 阻止 Yazi 尝试渲染 PDF

[[plugin.prepend_previewers]]
url = "*.{jpg,jpeg,png,gif,webp,bmp,svg,ico,tiff,tif,avif,heic,heif,jxl}"
run = 'piper -- /var/home/smile/.config/yazi/scripts/preview-image.sh "$1"'

[[plugin.prepend_previewers]]
url = "*.pdf"
run = 'piper -- /var/home/smile/.config/yazi/scripts/preview-pdf.sh "$1"'
```

---

## 维护注意

将来如果修改主配置的 `init.lua` / `keymap.toml` / `package.toml` / `theme.toml` 等文件，需要同步复制到 `~/.config/yazi-zellij/`（`yazi.toml` 除外）。

也可以改用软链接替代复制：

```bash
ln -sf ~/.config/yazi/init.lua ~/.config/yazi-zellij/init.lua
ln -sf ~/.config/yazi/keymap.toml ~/.config/yazi-zellij/keymap.toml
ln -sf ~/.config/yazi/theme.toml ~/.config/yazi-zellij/theme.toml
ln -sf ~/.config/yazi/package.toml ~/.config/yazi-zellij/package.toml
```

---

## 依赖

| 工具 | 用途 | 安装方式 |
|------|------|----------|
| `piper` | Yazi 插件，桥接 shell 命令到预览 | `ya pkg add yazi-rs/plugins:piper` |
| `file` | 检测文件类型 | 系统自带 |
| `identify` | ImageMagick，图片详细信息 | `dnf install ImageMagick` |
| `ffprobe` | 媒体文件元数据 | `dnf install ffmpeg` |
| `pdfinfo` | PDF 元数据 | `dnf install poppler-utils` |
| `pdftotext` | PDF 文本提取 | `dnf install poppler-utils` |
| `stat` | 文件时间戳和大小 | 系统自带 |
