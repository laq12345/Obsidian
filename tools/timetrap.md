---
tags:
  - cli
  - tool
  - time-tracking
  - productivity
created: 2026-07-15
---

# Timetrap — CLI 时间追踪

> GitHub：<https://github.com/samg/timetrap>
> 安装：`gem install timetrap`，命令缩写为 `t`

Ruby 写的命令行时间追踪器，按项目（timesheet）记录每天做了什么花了多久。

---

## 基本使用

```bash
# 创建/切换项目
t sheet coding          # 创建并切换到 coding 项目
t s coding              # 缩写

# 打卡上下班
t in "写 README"      # 开始计时
t out                   # 停止计时

# 查看
t display               # 查看当前项目明细
t d                     # 缩写
t now                   # 看当前正在计时的项目
t list                  # 列出所有项目
t today                 # 只看今天
t week                  # 只看本周
t month                 # 只看本月
```

---

## 快捷键/缩写

所有命令都可以缩写到最短唯一前缀：

| 全写 | 缩写 | 功能 |
|---|---|---|
| `sheet` | `s` | 切换项目 |
| `in` | `i` | 开始计时 |
| `out` | `o` | 停止计时 |
| `display` | `d` | 显示明细 |
| `edit` | `e` | 编辑条目 |
| `now` | `n` | 当前项目 |
| `list` | `l` | 项目列表 |
| `kill` | `k` | 删除 |
| `archive` | `a` | 归档 |
| `resume` | `r` | 恢复条目 |
| `configure` | `c` | 配置 |

---

## 补打/纠错

```bash
# 忘了开始计时——补打
t in --at "30 minutes ago"

# 编辑运行中的备注
t edit 写 README

# 编辑已结束的条目（先查 id）
t display --ids
t e -i43 --end "2026-07-15 14:00"
t e -i43 --start "10:30"
t e -i43 --append "补充说明"

# 自然语言时间
t out --at "in 30 minutes"
t edit --start "last monday at 10:30am"
t display --start "10am" --end "2pm"
```

---

## 输出格式

```bash
t d --format csv          # CSV 导入电子表格
t d --format json         # JSON
t d --format ical         # iCal 导入日历
t d --format ids          # 只输出条目 ID（用于脚本）
```

---

## 项目管理与归档

```bash
# 归档旧条目（移到 _ 前缀的隐藏项目）
t archive coding

# 删除
t kill coding                         # 删除整个项目
t kill --id 43                        # 删除单条

# 恢复已结束的条目
t resume --id 43                      # 重新开始某条
t r -i43 --at "5 minutes ago"         # 补开始时间
```

---

## 日常流程

```bash
# 早上开始工作
t s coding
t i "重构登录模块"

# 中午吃饭暂停
t out

# 下午继续
t i "继续重构"

# 结束时查看
t today
t week

# 导出报给老板
t d --format csv > timesheet.csv
```

---

## 配置

`t configure` 生成 `~/.timetrap.yml`，常用选项：

```yaml
round_in_seconds: 900          # 四舍五入到 15 分钟
database_file: ~/.timetrap.db  # SQLite 数据库路径
auto_checkout: true            # 自动签出
require_note: true             # 签入时强制写备注
default_formatter: text        # 默认输出格式
note_editor: vim               # 用 vim 编辑备注
week_start: monday             # 周起始日
```

---

## 安装说明

Fedora 需要先装 Ruby：

```bash
sudo dnf install ruby rubygems
gem install timetrap
```

命令别名 `t` 在安装后默认可用。
