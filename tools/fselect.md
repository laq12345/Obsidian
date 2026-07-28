---
tags:
  - cli
  - tool
  - file-search
created: 2026-07-13
---

# fselect — 用 SQL 查文件

> 官网：<https://fselect.rocks/> | GitHub：<https://github.com/jhspetersson/fselect>
> 安装：`cargo install fselect` 或直接下二进制

替代 `find`，用 SQL 语法搜文件。

## 基本语法

```
fselect [列, ...] [from 路径] [where 条件] [order by 列] [limit N]
```

不写 `from` 默认当前目录。

---

## 常用示例

### 基础

```bash
fselect name, size from ~ where name = '*.jpg'
fselect fsize, path from /tmp where size gt 2g
fselect name from /tmp where size between 5mb and 6mb
```

### 日期过滤

```bash
fselect path from ~ where modified = today
fselect path from ~ where modified = 'last fri'
```

### 文件类型快捷

```bash
fselect path from ~ where is_image
fselect path from ~ where is_video
fselect path from ~ where is_source
fselect path from ~ where is_archive
```

### 聚合统计

```bash
fselect 'MIN(size), MAX(size), AVG(size), SUM(size), COUNT(*)' from ~/Downloads
fselect 'ext, count(*), sum(size) from ~/Downloads group by ext order by sum(size) desc limit 20'
```

### 正则 / 模式

```bash
fselect name from ~ where path = '*rust*'
fselect name from ~ where path =~ '.*Rust.*'
fselect path from ~ where name like 'report-2024-%'
```

### 多目录 / 深度 / 符号链接 / 压缩包

```bash
fselect path from ~/old, ~/new where name = '*.jpg'
fselect path from ~ depth 3 symlinks archives
```

### Git 状态

```bash
fselect path, git_status from ~/projects where git_status = 'modified'
fselect 'name, git_last_commit_date, git_last_commit_author from src order by git_last_commit_date desc'
fselect path, git_branch from ~/projects depth 2 where is_git_repo
```

### 子查询

```bash
fselect 'name from /test1 where size in (select size from /test2)'
fselect 'name from /production where name not in (select name from /backup)'
```

### 内容搜索

```bash
fselect path from ~/src where contains('TODO') and name = '*.rs'
```

### 输出格式

```bash
fselect size, path from ~ limit 5 into json
fselect size, path from ~ limit 5 into csv
```

### 交互模式

```bash
fselect -i
fselect> name, size from . where is_image
fselect> exit
```

---

## 运算符

| 运算符 | 别名 | 说明 |
|---|---|---|
| `=` | `==`, `eq` | 等于（glob） |
| `!=` | `<>`, `ne` | 不等于 |
| `=~` | `regexp`, `rx` | 正则匹配 |
| `>` / `>=` | `gt` / `gte` | 大于 |
| `<` / `<=` | `lt` / `lte` | 小于 |
| `like` | | SQL LIKE |
| `between` | | 范围 |

## 常用列

`name`, `filename`, `ext`, `path`, `abspath`, `dir`, `absdir`, `size`, `fsize`, `modified`, `created`, `accessed`, `mime`

## 文件类型布尔

`is_dir`, `is_file`, `is_hidden`, `is_empty`, `is_image`, `is_video`, `is_audio`, `is_doc`, `is_source`, `is_archive`

## 单位

`k`/`kib`=1024, `kb`=1000, `m`/`mib`, `mb`, `g`/`gib`, `gb`, `t`/`tib`, `tb`
