---
tags:
  - cli
  - tool
  - screenshot
  - code
created: 2026-07-13
---

# Silicon — 代码截图生成器

> GitHub：<https://github.com/Aloxaf/silicon>
> 安装：`cargo install silicon` | Fedora 依赖：`sudo dnf install cmake expat-devel fontconfig-devel libxcb-devel freetype-devel libxml2-devel harfbuzz-devel`

Rust 写的代码截图工具，本地渲染，无网络依赖，毫秒级。

---

## 基本用法

```bash
silicon main.rs -o main.png
echo 'println!("hello")' | silicon -l rs -o out.png
silicon --from-clipboard -l rs --to-clipboard
```

## 常用选项

| 选项 | 说明 |
|---|---|
| `-o <file>` | 输出路径 |
| `-l <lang>` | 语言（rs, py, bash...） |
| `--background '#fff'` | 背景色 |
| `--shadow-color '#555'` | 阴影色 |
| `--shadow-blur-radius 30` | 阴影模糊 |
| `--no-window-controls` | 隐藏窗口按钮 |
| `--highlight-lines '1;3-4'` | 高亮行 |
| `--window-title "title"` | 窗口标题 |
| `-f 'Hack; SimSun=31'` | 字体列表 |

## 透明背景

`silicon test.rs -o test.png --background '#fff0'`

## 配置

写入 `~/.config/silicon/config`，每行一个参数：

```
--shadow-color '#555'
--background '#fff'
--no-window-controls
```

## 自定义语法/主题

与 bat 共用缓存，`silicon --build-cache` 重建。
