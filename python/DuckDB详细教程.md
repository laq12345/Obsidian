---
created: 2026-07-10
updated: 2026-09-17
tags:
  - sql
  - duckdb
  - database
  - cli
lang: SQL
---

# DuckDB 详细教程（SQL 基础 + CLI + Python API）

> **本机环境**：DuckDB CLI **v1.5.5**（`~/.local/bin/duckdb`）、Python 库 **1.5.5**（pixi 环境 `python3.14.7`，可用 pandas 3.0.5 / polars 1.44.2，**未装 pyarrow**）。
> 本文所有代码均在本机实测通过。

**相关笔记**：[[数据加载，存储与文件格式]] · [[Pandas基础]] · [[Pandas多级索引]]

---

## 0. 速查卡

```sql
SELECT 列, 聚合(列) FROM 表
  JOIN 另一表 ON 条件
  WHERE 行条件            -- 聚合前过滤
  GROUP BY 列
  HAVING 组条件            -- 聚合后过滤
  ORDER BY 列 DESC
  LIMIT 10;
```

```python
import duckdb
con = duckdb.connect("data.duckdb")        # 或留空 = 内存库
con.sql("SELECT * FROM 'a.parquet'").df()  # 一行搞定「读文件 → DataFrame」
```

---

## 1. SQL 基础

### 1.1 SQL 的四大类

| 类别     | 关键词                            | 干什么                |
| ------ | ------------------------------ | ------------------ |
| DDL 定义 | `CREATE` / `ALTER` / `DROP`    | 改表结构               |
| DML 操作 | `INSERT` / `UPDATE` / `DELETE` | 改数据                |
| DQL 查询 | `SELECT`                       | 读数据（**90% 的日常**）   |
| DCL 权限 | `GRANT` / `REVOKE`             | 授权（DuckDB 单机基本用不到） |

### 1.2 建表与类型

```sql
CREATE TABLE emp (
  id      INTEGER PRIMARY KEY,
  name    VARCHAR NOT NULL,
  dept    VARCHAR,
  salary  DOUBLE,
  hired   DATE
);

CREATE TABLE emp2 AS SELECT * FROM emp;         -- CTAS：复制结构+数据
CREATE TABLE x AS SELECT * FROM 'a.parquet';    -- 一步建表导入
CREATE OR REPLACE TABLE x AS SELECT ...;        -- 存在就覆盖
CREATE TEMP TABLE t AS SELECT ...;              -- 会话临时表
DROP TABLE IF EXISTS emp2;

ALTER TABLE emp ADD COLUMN email VARCHAR;
ALTER TABLE emp RENAME COLUMN name TO full_name;
ALTER TABLE emp DROP COLUMN email;

DESCRIBE emp;                                    -- 看列名和类型
```

**常用类型**

| 类别      | 类型                                                 |
| ------- | -------------------------------------------------- |
| 整数      | `TINYINT` `SMALLINT` `INTEGER` `BIGINT` `HUGEINT`  |
| 浮点 / 精确 | `FLOAT` `DOUBLE` `DECIMAL(10,2)`                   |
| 文本      | `VARCHAR`（等价 `TEXT` `STRING`）                      |
| 布尔      | `BOOLEAN`（字面量 `TRUE` / `FALSE`）                    |
| 时间      | `DATE` `TIME` `TIMESTAMP` `TIMESTAMPTZ` `INTERVAL` |
| 二进制     | `BLOB`                                             |
| 嵌套      | `LIST`（数组） `STRUCT`（结构体） `MAP`（字典） `UNION`         |
| 半结构化    | `JSON`                                             |

```sql
-- 嵌套类型
SELECT [1, 2, 3]              AS lst,
       {'a': 1, 'b': 'x'}     AS st,
       MAP {'k1': 1, 'k2': 2} AS mp,
       lst[1]                 AS 第一个,   -- 注意：索引从 1 开始
       st.a                   AS 取字段,
       unnest([1,2,3])        AS 炸开;
```

### 1.3 增删改 / UPSERT

```sql
-- 插入
INSERT INTO emp VALUES (1, '张三', '研发', 20000, '2024-03-01');
INSERT INTO emp (id, name, salary) VALUES (2, '李四', 18000);
INSERT INTO emp SELECT * FROM staging WHERE salary > 0;
INSERT INTO emp BY NAME SELECT 3 AS salary, '王五' AS name;   -- 按列名对齐

-- 更新
UPDATE emp SET salary = salary * 1.1 WHERE dept = '研发';

-- 删除
DELETE FROM emp WHERE hired < '2020-01-01';
DELETE FROM emp;                       -- 清空数据，保留表

-- UPSERT（主键冲突则更新）
INSERT INTO emp (id, name, salary) VALUES (1, '张三', 25000)
ON CONFLICT (id) DO UPDATE SET salary = EXCLUDED.salary;

-- 冲突则跳过
INSERT INTO emp (id, name) VALUES (9, 'x') ON CONFLICT DO NOTHING;
```

> ⚠️ **`UPDATE` / `DELETE` 忘了 `WHERE` 就是全表。**
> 安全习惯：先写成 `SELECT * FROM 表 WHERE 条件` 确认命中行数，再把 `SELECT *` 换成 `DELETE`。

### 1.4 SELECT：书写顺序 ≠ 执行顺序

```
书写： SELECT → FROM → JOIN → WHERE → GROUP BY → HAVING → ORDER BY → LIMIT
执行： FROM/JOIN → WHERE → GROUP BY → HAVING → SELECT → DISTINCT → ORDER BY → LIMIT
```

| 子句 | 能否用 SELECT 别名 | 能否用聚合函数 |
|---|---|---|
| `WHERE` | DuckDB **可以**（非标准扩展） | ❌ 报 `WHERE clause cannot contain aggregates!` |
| `GROUP BY` | DuckDB 可以 | — |
| `HAVING` | DuckDB 可以 | ✅ |
| `ORDER BY` | ✅ 标准就允许 | ✅ |

```sql
-- 实测 DuckDB 支持别名下推
SELECT pay*2 AS p2 FROM s WHERE p2 > 30;                 -- ✅
SELECT dept AS d FROM s GROUP BY d HAVING sum(pay) > 15; -- ✅
SELECT dept FROM s WHERE sum(pay) > 10 GROUP BY dept;    -- ❌ 聚合不能进 WHERE
```

> 别名用在 `WHERE` 是 DuckDB 的便利扩展，**MySQL / PostgreSQL / SQL Server 都不支持**。
> 写可移植 SQL 时别依赖它。

### 1.5 过滤与排序

```sql
SELECT * FROM emp
WHERE dept IN ('研发', '销售')
  AND salary BETWEEN 10000 AND 30000
  AND name LIKE '张%'              -- % 任意多字符，_ 单字符
  AND hired >= '2020-01-01'
  AND email IS NOT NULL
  AND NOT (dept = '行政');

WHERE regexp_matches(name, '^[张李王]');   -- 正则

ORDER BY dept ASC, salary DESC NULLS LAST
ORDER BY 列 COLLATE NOCASE                 -- 忽略大小写

SELECT DISTINCT dept FROM emp;
SELECT DISTINCT ON (dept) * FROM emp ORDER BY dept, salary DESC;  -- 每组一行
SELECT * FROM emp ORDER BY id LIMIT 10 OFFSET 20;
```

**⚠️ NULL 三大陷阱**

```sql
salary = NULL          -- ❌ 结果永远是 NULL / 不成立
salary IS NULL         -- ✅
salary <> 5            -- ❌ 当 salary 是 NULL 时，这行被排除！
coalesce(salary, 0)    -- ✅ 兜底
nullif(a, b)           -- a = b 时返回 NULL
```

任何与 NULL 的算术 / 比较结果都是 NULL，`WHERE` 里 NULL 视作「不通过」。
**统计非空值用 `count(列)`，统计总行数用 `count(*)`。**

### 1.6 聚合与分组

```sql
SELECT
  dept,
  count(*)                    AS 行数,      -- 含 NULL 行
  count(email)                AS 邮箱数,    -- 忽略 NULL
  count(DISTINCT center)      AS 中心数,    -- 去重计数
  sum(salary), avg(salary), min(salary), max(salary),
  median(salary),                           -- 中位数
  stddev_samp(salary),                      -- 样本标准差
  quantile_cont(salary, 0.5),               -- 分位数
  string_agg(name, ', ')      AS 名单,      -- 拼字符串（MySQL 是 GROUP_CONCAT）
  list(name)                  AS 名单数组,   -- DuckDB：拼成 LIST
  arg_max(name, salary)       AS 最高薪的人, -- 取另一列的对应值
  bool_or(flag), bool_and(flag)
FROM emp
GROUP BY dept
HAVING count(*) >= 3;
```

| 需求       | 函数                                    |
| -------- | ------------------------------------- |
| 行数 / 非空数 | `count(*)` / `count(列)`               |
| 求和 / 均值  | `sum` / `avg`                         |
| 中位数      | `median(x)` 或 `quantile_cont(x, 0.5)` |
| 标准差      | `stddev_samp`（样本） / `stddev_pop`（总体）  |
| 合并文本     | `string_agg(x, ',')`                  |
| 合并成数组    | `list(x)`                             |
| 最大值对应的名字 | `arg_max(名字, 值)`                      |
| 任意 / 第一个 | `any_value(x)` / `first(x)`           |

没有 `GROUP BY` 时，聚合函数把全表当一组：`SELECT count(*) FROM emp;`

### 1.7 JOIN

```sql
-- INNER JOIN：两边都匹配才保留
SELECT e.name, d.budget
FROM emp e JOIN dept d ON e.dept = d.dept_name;

-- LEFT JOIN：左表全保留，右表缺失补 NULL（最常用）
SELECT e.name, d.budget
FROM emp e LEFT JOIN dept d ON e.dept = d.dept_name;

-- RIGHT JOIN / FULL OUTER JOIN / CROSS JOIN（笛卡尔积）
-- 同名列可以直接 USING
SELECT * FROM emp JOIN dept USING (dept);

-- 自连接：找同部门同薪资的同事
SELECT a.name, b.name
FROM emp a JOIN emp b ON a.dept = b.dept AND a.id < b.id;
```

**⚠️ LEFT JOIN 头号坑**：在 `WHERE` 里写右表条件，等价于把 LEFT JOIN **降级成 INNER JOIN**。

```sql
-- ❌ 丢了所有没有匹配 dept 的员工
SELECT * FROM emp e LEFT JOIN dept d ON e.dept = d.dept
WHERE d.budget > 1000;

-- ✅ 条件写进 ON，才能保留左表
SELECT * FROM emp e LEFT JOIN dept d ON e.dept = d.dept AND d.budget > 1000;

-- ✅ 或显式允许 NULL
... WHERE (d.budget > 1000 OR d.budget IS NULL);
```

### 1.8 子查询 / CTE / 集合运算

```sql
-- 标量子查询
SELECT name FROM emp WHERE salary > (SELECT avg(salary) FROM emp);

-- 派生表
SELECT * FROM (
  SELECT dept, avg(salary) AS a FROM emp GROUP BY dept
) x WHERE x.a > 15000;

-- IN / EXISTS
SELECT * FROM dept WHERE dept_name IN (SELECT DISTINCT dept FROM emp);
SELECT * FROM dept d WHERE EXISTS (SELECT 1 FROM emp e WHERE e.dept = d.dept_name);

-- 相关子查询（引用外层列）
SELECT * FROM emp e
WHERE salary = (SELECT max(salary) FROM emp WHERE dept = e.dept);
```

**CTE（`WITH`）—— 把复杂查询拆成可读步骤，强烈推荐**

```sql
WITH 部门均值 AS (
  SELECT dept, avg(salary) AS a FROM emp GROUP BY dept
),
高薪 AS (
  SELECT e.name, e.salary, m.a
  FROM emp e JOIN 部门均值 m ON e.dept = m.dept
  WHERE e.salary > m.a
)
SELECT * FROM 高薪 ORDER BY salary DESC;
```

```sql
-- 集合运算
SELECT name FROM emp UNION      SELECT name FROM emp2;   -- 合并 + 去重
SELECT name FROM emp UNION ALL  SELECT name FROM emp2;   -- 合并，不去重（更快）
SELECT * FROM a UNION BY NAME SELECT * FROM b;           -- 按列名对齐（DuckDB）
SELECT name FROM emp INTERSECT SELECT name FROM emp2;    -- 交集
SELECT name FROM emp EXCEPT    SELECT name FROM emp2;    -- 差集
```

**跨表统计套路**（多张结构一致的 Excel 时）：

```sql
SELECT '结局表1' AS 来源, count(*) FROM '结局表1.xlsx'
UNION ALL
SELECT '结局表2', count(*) FROM '结局表2.xlsx';
```

### 1.9 窗口函数

**聚合**把多行压成一行；**窗口函数**保留每一行，额外附加一列计算结果。

```sql
函数名() OVER (
  PARTITION BY 分组列      -- 可选：组内计算
  ORDER BY 排序列          -- 可选：决定「累计 / 排名」的顺序
)
```

```sql
SELECT
  name, dept, salary,
  avg(salary)   OVER (PARTITION BY dept)                      AS 部门均值,
  salary - avg(salary) OVER (PARTITION BY dept)               AS 与均值差,
  rank()        OVER (PARTITION BY dept ORDER BY salary DESC) AS 名次,
  row_number()  OVER (ORDER BY salary DESC)                   AS 全局行号,
  sum(salary)   OVER (ORDER BY hired)                         AS 累计薪资,
  lag(salary)   OVER (ORDER BY hired)                         AS 上一位,
  lead(salary)  OVER (ORDER BY hired)                         AS 下一位,
  ntile(4)      OVER (ORDER BY salary)                        AS 四分位
FROM emp;
```

| 函数 | 说明 |
|---|---|
| `row_number()` | 1,2,3,4…（无并列） |
| `rank()` | 1,2,2,4…（并列跳号） |
| `dense_rank()` | 1,2,2,3…（并列不跳号） |
| `ntile(n)` | 分成 n 桶 |
| `lag(x)` / `lead(x)` | 上一行 / 下一行 |
| `first_value(x)` / `last_value(x)` | 组内首 / 末值 |
| `sum` `avg` `count` … | 普通聚合函数都能当窗口用 |

**取每组 Top-1 的标准写法**（窗口函数不能写在 `WHERE` 里，必须套一层）：

```sql
SELECT * FROM (
  SELECT *, row_number() OVER (PARTITION BY dept ORDER BY salary DESC) AS rk
  FROM emp
) t WHERE rk = 1;
```

或直接用 DuckDB 的 **`QUALIFY`** 免套一层：

```sql
SELECT dept, who, pay FROM emp_s
QUALIFY row_number() OVER (PARTITION BY dept ORDER BY pay DESC) = 1;
```

### 1.10 条件逻辑：`CASE`（最高频）

```sql
SELECT name,
  CASE WHEN salary >= 30000 THEN '高'
       WHEN salary >= 15000 THEN '中'
       ELSE '低' END                       AS 档位,
  if(salary > 20000, '高薪', '普通')        AS 简写
FROM emp;

-- 配合聚合做条件统计
SELECT dept,
       sum(CASE WHEN salary > 20000 THEN 1 ELSE 0 END) AS 高薪人数,
       count(*) FILTER (WHERE salary > 20000)          AS 高薪人数2  -- 更地道
FROM emp GROUP BY dept;
```

### 1.11 函数速查

**字符串**

| 目的 | 写法 |
|---|---|
| 大小写 | `upper(s)` `lower(s)` |
| 去空白 | `trim(s)` `ltrim` `rtrim` |
| 长度 | `length(s)` |
| 截取 | `substr(s, 2, 3)`（索引从 1 开始） |
| 替换 | `replace(s, 'a', 'b')` |
| 查找位置 | `position('a' IN s)` / `strpos(s, 'a')` |
| 切分 | `split_part(s, ',', 2)` / `string_split(s, ',')` |
| 拼接 | `s1 \|\| s2`、`concat(s1, s2)`、`concat_ws(',', ...)` |
| 填充 | `lpad(s, 5, '0')` `rpad(s, 5, ' ')` |
| 前后缀判断 | `starts_with(s, 'x')` `ends_with(s, 'x')` |
| 反转 | `reverse(s)` |
| 正则 | `regexp_matches(s, p)` `regexp_extract(s, p, 1)` `regexp_replace(s, p, r, 'g')` |

**数值**

`round(x, 2)` `floor` `ceil` `abs` `sqrt` `power(x, n)` `mod(a, b)` `greatest(...)` `least(...)`
类型转换：`CAST(x AS INTEGER)` / `x::INTEGER` / `try_cast(x AS INTEGER)`（失败给 NULL 而不报错）

**日期时间**（比 MySQL 干净很多）

```sql
SELECT
  date_trunc('month', hired)              AS 月初,
  date_trunc('week',  hired)              AS 周初,
  hired + INTERVAL 30 DAY                 AS 加30天,
  hired - INTERVAL '1' MONTH              AS 减1月,
  date_diff('day', hired, current_date)   AS 相差天数,
  current_date, now(), today(),
  strftime(hired, '%Y-%m')                AS 格式化,
  strptime('2024-03', '%Y-%m')            AS 解析,
  extract(year FROM hired)                AS 年,
  epoch_ms(hired)                         AS 毫秒时间戳,
  last_day(hired)                         AS 月末;
```

> ⚠️ DuckDB 用 `date_diff('day', a, b)`，MySQL 用 `DATEDIFF(b, a)`，SQL Server 用 `DATEDIFF(day, a, b)`
> —— **参数顺序和写法都不同**，跨库时注意。

**空值 / 类型**：`coalesce(a, b, c)` `nullif(a, b)` `ifnull(a, b)` `typeof(x)` `try_cast(x AS INT)`

**数组 / 嵌套**：`list_value(1,2,3)` `len(lst)` `lst[1]` `list_contains(lst, 2)` `unnest(lst)`（炸成多行）`list_transform(lst, x -> x * 2)`

### 1.12 常见 SQL 报错对照

| 报错 | 原因 | 解决 |
|---|---|---|
| `Binder Error: WHERE clause cannot contain aggregates` | 聚合函数写进 `WHERE` | 改用 `HAVING` 或子查询 |
| `Binder Error: Referenced column not found` | 列名拼错 / 缺引号 | `DESCRIBE` 看真实列名 |
| `Catalog Error: Table with name X does not exist` | 表名写错，或**每次 `-c` 是独立内存库** | 用 `duckdb file.db` 或同一次会话里建表 |
| `Conversion Error` | 类型转换失败 | `try_cast` 或 `all_varchar => true` |

---

## 2. DuckDB CLI 用法

### 2.1 启动方式

```bash
duckdb                              # 纯内存库，退出即消失
duckdb mydb.duckdb                  # 打开 / 创建持久化数据库
duckdb mydb.duckdb -c "SELECT 1;"   # 执行后退出（脚本 / 管道友好）
duckdb -readonly mydb.duckdb        # 只读打开
duckdb < script.sql                 # 从管道喂脚本
```

进入交互界面后提示符形如 `memory D`（库名 + `D`）。

### 2.2 点命令（dot commands）

**点命令不是 SQL，不加分号。**

| 命令 | 作用 |
|---|---|
| `.help` / `.help --all` / `.help shortcuts` | 帮助 |
| `.tables` | 列出所有表 |
| `.schema 表名` | 查看建表语句 |
| `.databases` | 列出已附加的数据库 |
| `.dump` | 把整个库导出成 SQL |
| **`.mode MODE`** | 设置输出格式 |
| `.maxrows 100` | duckbox 最多显示多少行（默认 40） |
| `.maxwidth 200` | 输出宽度，0 = 跟随终端 |
| `.headers on\|off` | 是否显示列头 |
| `.nullvalue NULL` | NULL 的显示文本 |
| `.timer on` | 显示每条查询耗时 |
| **`.excel`** | **下一个查询结果直接在电子表格里打开** |
| `.output 文件` | 后续输出重定向到文件 |
| `.once 文件` | 只把下一条命令的输出写文件 |
| `.read 文件.sql` | 执行 SQL 文件 |
| `.import FILE TABLE` | 导入数据 |
| `.edit` | 打开外部编辑器写查询 |
| `.cd 目录` | 切换工作目录 |
| `.shell 命令` / `.system 命令` | 执行 shell 命令 |
| `.open 另一个.db` | 关闭当前库并打开另一个 |
| `.quit` / `.exit` | 退出 |

**`.mode` 的合法值**（实测）：

```
ascii  box  column  csv  duckbox  html  insert  json  jsonlines
latex  line  list  markdown  quote  table  tabs  tcl  trash
```

常用：`duckbox`（默认，最好看）、`csv`、`json`、`markdown`、`latex`、`insert`（生成 INSERT 语句）。

```sql
.mode markdown
SELECT * FROM t;
-- → 直接粘进 Markdown 文档的表格
```

**启动配置**：`~/.duckdbrc` 里的内容会在启动时自动执行：

```
.mode duckbox
.maxrows 100
.timer on
.highlight on
```

### 2.3 直接查文件（DuckDB 最大卖点）

**⚠️ 路径必须加引号！** 这是最常见的新手报错：

```sql
SELECT * FROM 'data.csv';                  -- ✅
SELECT * FROM read_csv('data.csv');        -- ✅ 显式函数
SELECT * FROM "data.csv";                  -- ⚠️ 双引号是标识符，不推荐
SELECT * FROM data.csv;                    -- ❌ 被当成 schema.table
SELECT * FROM ./data.csv;                  -- ❌ Parser Error: syntax error at or near "."
```

> **报错原文**：
> `Parser Error: syntax error at or near "."` ← 不加引号时解析器把 `./...` 当标识符，遇到 `.` 就炸。
> **正确写法**：`SELECT * FROM './整理结果/结局表1-并发并发症.xlsx';`

**支持格式**

```sql
SELECT * FROM 'a.csv';
SELECT * FROM 'a.parquet';
SELECT * FROM 'a.json';
SELECT * FROM 'a.xlsx';                      -- 需 excel 扩展（v1.5.5 会自动装）
SELECT * FROM 'a.tsv';
SELECT * FROM read_csv_auto('a.txt');         -- 分隔符自动嗅探
SELECT * FROM 'logs/2024-*.parquet';          -- 通配符批量读
SELECT * FROM read_parquet(['a.parquet', 'b.parquet']);
SELECT * FROM read_parquet('logs/*.parquet', filename => true);  -- 多一列文件名
```

**`read_csv` 常用参数**

```sql
SELECT * FROM read_csv('a.csv',
    header        => true,          -- 第一行是表头
    delim         => '|',           -- 分隔符
    quote         => '"',
    nullstr       => ['', 'NA', '-'],   -- 哪些值算 NULL
    skip          => 2,             -- 跳过前 N 行
    columns       => {'id':'INTEGER', 'name':'VARCHAR'},   -- 手写 schema
    ignore_errors => true,
    all_varchar   => true,          -- 全部按字符串读（不猜类型）
    sample_size   => -1             -- 全文件采样（默认只采样部分行）
);
```

**`read_xlsx` 参数**（实测签名）

```
read_xlsx(col0, normalize_names, empty_as_varchar, stop_at_empty,
          sheet, range, ignore_errors, all_varchar, header)
```

```sql
-- 指定工作表（不指定则用第一个）
SELECT * FROM read_xlsx('a.xlsx', sheet => '并发并发症');

-- 指定单元格区域
SELECT * FROM read_xlsx('a.xlsx', range => 'A1:C4');

-- 中文表头 + 全字符串：推荐组合
SELECT * FROM read_xlsx('a.xlsx', all_varchar => true, header => true);

-- 不知道有哪些 sheet？故意写错名字，报错会列出来
SELECT * FROM read_xlsx('a.xlsx', sheet => 'NOPE');
-- Binder Error: Sheet "NOPE" not found in xlsx file "a.xlsx"
-- Did you mean: "并发并发症"
```

> ⚠️ **两个 xlsx 大坑**
> 1. `normalize_names => true` 会把中文表头毁成 `_`、`__1`、`__2`…… **中文表头千万别开**。
> 2. v1.5.5 **没有** `xlsx_sheet_names()` 函数（实测 `Catalog Error`），探 sheet 名只能用上面「故意写错」的技巧。

### 2.4 导出

```sql
COPY (SELECT * FROM t) TO 'out.csv'     (HEADER, DELIMITER ',');
COPY (SELECT * FROM t) TO 'out.parquet' (FORMAT PARQUET, COMPRESSION zstd);
COPY (SELECT * FROM t) TO 'out.json'    (FORMAT JSON, ARRAY true);

-- 按分区写多个文件
COPY t TO 'out/' (FORMAT PARQUET, PARTITION_BY (dept));
```

CLI 层也能导：

```sql
.mode csv
.once out.csv
SELECT * FROM t;
```

> DuckDB **不支持写 xlsx**（只能读）。要输出 Excel，导成 CSV 再用别的方式转，
> 或者用 `.excel` 点命令把结果直接丢进电子表格。

### 2.5 调试与元信息

```sql
DESCRIBE emp;                            -- 看表的列 / 类型
DESCRIBE SELECT 1 AS x;                  -- 看「查询结果」的列 / 类型（不执行）
SHOW TABLES;
SHOW ALL TABLES;                         -- 所有库的所有表
SUMMARIZE emp;                           -- ★ 每列类型 / 极值 / NULL 比例 / 唯一值数
EXPLAIN SELECT ...;                      -- 查询计划
EXPLAIN ANALYZE SELECT ...;              -- 计划 + 真实耗时
SELECT * FROM duckdb_functions() WHERE function_name ILIKE '%xlsx%';   -- 查函数签名
SELECT version();
```

**`SUMMARIZE` 是「拿到陌生表第一步」的最佳工具**，输出：

```
column_name | column_type | min | max | approx_unique | avg | std | q25 | q50 | q75 | count | null_percentage
```

一眼看出哪些列有 NULL、有无异常极值、类型对不对。**做数据核查先跑一遍 `SUMMARIZE`。**

---

## 3. DuckDB Python API

```bash
# 本机已装（pixi 环境）：duckdb 1.5.5
python3 -c "import duckdb; print(duckdb.__version__)"
```

### 3.1 连接

```python
import duckdb

con = duckdb.connect()                  # 内存库
con = duckdb.connect("data.duckdb")     # 持久化文件
con = duckdb.connect("data.duckdb", read_only=True)
con = duckdb.connect(config={"threads": 4, "memory_limit": "4GB"})

con.close()                             # 显式关闭
with duckdb.connect("data.duckdb") as con:   # 或上下文管理器（退出自动关）
    con.execute("CREATE TABLE z AS SELECT 1 AS a")

duckdb.default_connection()             # 模块级默认连接
duckdb.set_default_connection(con)      # 替换默认连接
```

### 3.2 两种执行风格

| 风格 | 返回 | 用途 |
|---|---|---|
| `con.execute(sql, params)` | `DuckDBPyConnection` | DDL / DML，配合 `fetch*` 取值 |
| `con.sql(sql, params=...)` | **`DuckDBPyRelation`**（惰性） | 查询，链式加工后取结果 |

```python
# 风格一：execute + fetch
con.execute("CREATE TABLE t AS SELECT * FROM (VALUES (1,'a'),(2,'b')) v(id,n)")
con.execute("SELECT * FROM t").fetchall()   # [(1,'a'), (2,'b')]
con.execute("SELECT * FROM t").fetchone()   # (1,'a')

# 风格二：sql() -> Relation（推荐，能力更强）
rel = con.sql("SELECT 42 AS answer, 'hi' AS s")   # 此时还没真正执行
rel.show()          # 打印成框线表
rel.df()            # → pandas DataFrame
rel.fetchall()      # → list of tuples
```

> ⚠️ 游标是一次性的：`fetchall()` 之后再 `fetchone()` 会返回 `None`。

**取结果的全部方法**（Relation 上同名可用）

| 方法 | 结果 |
|---|---|
| `.fetchall()` / `.fetchone()` / `.fetchmany(n)` | Python 元组 |
| `.df()` / `.to_df()` / `.fetchdf()` | pandas DataFrame |
| `.pl()` | polars DataFrame（**需装 pyarrow**） |
| `.arrow()` / `.to_arrow_table()` | pyarrow Table（**需装 pyarrow**） |
| `.fetchnumpy()` | 列名 → numpy 数组的字典 |
| `.show()` | 打印框线表（不返回数据） |
| `.explain()` | 查询计划字符串 |

> ⚠️ **本机未装 pyarrow**，所以 `.pl()` 和 `.arrow()` 会报 `ModuleNotFoundError: No module named 'pyarrow'`。
> 要转 polars，先 `pixi global install pyarrow` 或 `pixi add pyarrow`。

### 3.3 模块级便捷函数

```python
import duckdb

duckdb.sql("SELECT 1").fetchall()               # 默认连接上执行
duckdb.query("SELECT 1").fetchall()             # 同上（旧名，仍可用）
duckdb.execute("SELECT 1").fetchall()           # 同上
duckdb.sql("SELECT * FROM 'a.csv'").df()

duckdb.read_csv("a.csv")                        # 模块级读取
duckdb.read_parquet("a.parquet")
duckdb.read_json("a.json")
duckdb.from_df(df) / duckdb.from_arrow(tbl)
duckdb.register("name", df) / duckdb.unregister("name")
duckdb.install_extension("excel") / duckdb.load_extension("excel")
```

### 3.4 DataFrame / Arrow 互操作（核心）

```python
import pandas as pd, duckdb

con = duckdb.connect()
df = pd.DataFrame({"x": [1, 2, 3], "g": ["p", "p", "q"]})

# ① 自动替换扫描：直接 SELECT 变量名！零拷贝
con.sql("SELECT g, sum(x) AS s FROM df GROUP BY g").df()

# ② 显式注册（推荐，避免依赖变量名）
con.register("myvar", df)
con.sql("SELECT count(*) FROM myvar").fetchone()

# ③ 从 DataFrame 构造 Relation
con.from_df(df).aggregate("g, sum(x) AS s").df()

# ④ 引用已存在的表（而非变量）
con.table("t").df()

# ⑤ 结果写回 DataFrame
result = con.sql("SELECT * FROM t").df()
```

> ① 是 DuckDB 的杀手锏：**不用把 DataFrame 传进 SQL 字符串，直接写变量名**。
> 但要注意：变量名变了 SQL 就失效，正式代码里推荐用 ② `register()`。

### 3.5 Relation 的链式 API

不下 SQL 也能加工数据（等价于 SQL 子句）：

```python
rel = con.table("t")

rel.project("n, pay")                     # SELECT 列
rel.filter("pay > 15")                    # WHERE
rel.order("pay DESC")                     # ORDER BY
rel.limit(2)                              # LIMIT
rel.distinct()                            # DISTINCT
rel.aggregate("n, count(*) AS c, sum(pay) AS s")   # GROUP BY
rel.join(other, "a = id", "left")         # JOIN
rel.union(other) / rel.intersect(other) / rel.except_(other)
rel.project("n, sum(pay) OVER (PARTITION BY n) AS s")  # 窗口也能写

# 全部可链式串联
con.table("t").filter("pay > 15").project("n, pay").order("pay DESC").df()
```

**导出 / 落地**

```python
rel.write_csv("out.csv")
rel.write_parquet("out.parquet")
rel.to_table("tbl_z")      # 物化成表
rel.to_view("v_w")         # 物化成视图
rel.insert_into("base")    # 插入已有表
```

其他常用：`rel.columns` / `rel.types` / `rel.dtypes` / `rel.shape` / `rel.describe()` / `rel.value_counts("g")`
以及一大批聚合并发糖：`sum/avg/mean/median/min/max/count/std/var/quantile/string_agg/list/first/last/…`

> 完整方法列表：`[m for m in dir(rel) if not m.startswith('_')]`，v1.5.5 共 **111 个**。

### 3.6 读写文件

```python
# 连接级
con.read_csv("a.csv")
con.read_parquet("a.parquet")
con.read_json("a.json")

# SQL 里照旧用路径字符串（记得加引号）
con.sql("SELECT * FROM 'a.parquet'").df()
con.sql("SELECT * FROM read_csv('a.csv', header => true)").df()

# Excel（先加载扩展）
con.execute("INSTALL excel; LOAD excel")
con.sql("SELECT * FROM './整理结果/结局表1-并发并发症.xlsx' LIMIT 5").df()

# 读取通配符
con.sql("SELECT * FROM 'logs/*.parquet'").df()
```

### 3.7 建表 / 视图 / 插入 / 事务

```python
con.execute("CREATE TABLE base(a INT, b VARCHAR)")

# Relation 直接插入
con.sql("SELECT * FROM (VALUES (1,'x'),(2,'y')) v(a,b)").insert_into("base")

# 也可以先注册 DataFrame 再 INSERT
con.register("df2", pd.DataFrame({"a": [9], "b": ["z"]}))
con.execute("INSERT INTO base SELECT * FROM df2")

con.execute("CREATE OR REPLACE VIEW v1 AS SELECT a, count(*) AS c FROM base GROUP BY a")
con.sql("SELECT * FROM v1 ORDER BY a").df()

# 事务
con.execute("BEGIN")
con.execute("INSERT INTO base VALUES (100, 'x')")
con.execute("ROLLBACK")     # 或 COMMIT
```

### 3.8 参数化查询（防注入 / 复用）

```python
# execute：位置参数 ?
con.execute("SELECT * FROM t WHERE pay > ?", [25]).fetchall()
con.execute("SELECT * FROM t WHERE pay > ? AND n = ?", [25, "a"]).fetchall()

# sql()：位置参数
con.sql("SELECT * FROM t WHERE pay > ?", params=[25]).fetchall()

# sql()：命名参数 $
con.sql("SELECT $v AS v", params={"v": 5}).fetchall()

# executemany：批量插入
con.execute("CREATE TABLE m(a INT, b VARCHAR)")
con.executemany("INSERT INTO m VALUES (?, ?)", [(1, "x"), (2, "y")])
```

也可用 `duckdb.value()` 构造标量、`duckdb.values()` 构造常量关系。

### 3.9 Python UDF（自定义函数）

```python
con.create_function(
    "add1",
    lambda x: None if x is None else x + 1,
    ["INTEGER"],      # 入参类型
    "INTEGER",        # 返回类型
)
con.sql("SELECT pay, add1(pay) AS p1 FROM t").df()
```

移除：`con.remove_function("add1")`。也支持向量化 UDF（`type="arrow"`，需 pyarrow）。

---

## 4. DuckDB 独有特性 / 语法糖

> 这些都是 DuckDB 扩展，**不可移植到 MySQL / PostgreSQL**，自己写代码时很爽，交接时注意。

```sql
-- 1. GROUP BY ALL：自动按所有非聚合列分组
SELECT dept, count(*) FROM emp GROUP BY ALL;

-- 2. ORDER BY ALL
SELECT * FROM emp ORDER BY ALL;

-- 3. QUALIFY：窗口函数过滤，免套子查询
SELECT * FROM emp QUALIFY rank() OVER (PARTITION BY dept ORDER BY salary DESC) = 1;

-- 4. SELECT * EXCLUDE / REPLACE / RENAME
SELECT * EXCLUDE (salary) FROM emp;
SELECT * REPLACE (salary / 1000 AS salary) FROM emp;
SELECT * RENAME (name AS 姓名) FROM emp;

-- 5. COLUMNS 通配表达式（对一批列批量套函数）
SELECT min(COLUMNS(*)) FROM emp;
SELECT COLUMNS('^salary') FROM emp;          -- 正则选列
SELECT max(COLUMNS(*)) FROM 'a.csv';

-- 6. FROM 可以放最前面（SELECT * 可省）
FROM emp SELECT name;

-- 7. PIVOT / UNPIVOT（Excel 数据透视表等价物）
PIVOT emp ON dept USING sum(salary);
UNPIVOT t ON A, B INTO NAME k VALUE v;

-- 8. 直接构造表
SELECT * FROM (VALUES (1, 'a'), (2, 'b')) AS v(id, n);

-- 9. 序列 / 日期生成
SELECT * FROM range(10);                       -- 0..9
SELECT unnest(generate_series(1, 5)) AS n;
SELECT * FROM generate_series(DATE '2024-01-01', DATE '2024-12-01', INTERVAL 1 MONTH);
```

---

## 5. 实战配方

### 5.1 用 CLI 分析一组 Excel 表格

```bash
# ① 打开持久库（重要：不然每次 -c 都是空库）
duckdb 分析.duckdb
```

```sql
-- ② 装 / 加载 excel 扩展（v1.5.5 通常自动，保险起见写一次）
INSTALL excel; LOAD excel;

-- ③ 全部按字符串导入，避免类型乱猜
CREATE OR REPLACE TABLE 结局表1 AS
SELECT * FROM read_xlsx('./整理结果/结局表1-并发并发症.xlsx', all_varchar => true);

CREATE OR REPLACE TABLE 结局表2 AS
SELECT * FROM read_xlsx('./整理结果/结局表2-研究结局.xlsx', all_varchar => true);

-- ④ 先摸底
-- 注意：表名若含连字符 - 必须写 "结局表1-并发并发症"，否则报 Parser Error: syntax error at or near "-"
SHOW TABLES;
SUMMARIZE 结局表1;

-- ⑤ 中文列名带全角括号也能直接用；含空格 / 特殊符号时加双引号
SELECT "并发并发症（如有则记如下）_纵膈气肿" AS 纵膈气肿, count(*) AS n
FROM 结局表1 GROUP BY 1 ORDER BY n DESC;

-- ⑥ 交叉核查
SELECT 中心编号,
       count(*) AS 总数,
       count(*) FILTER (WHERE "并发症是否与机械通气相关_气胸" = '是') AS 相关气胸
FROM 结局表1
GROUP BY 中心编号 ORDER BY 总数 DESC;

-- ⑦ 导出
COPY (SELECT * FROM 结局表1) TO '结局表1_clean.csv' (HEADER);
```

### 5.2 同样的事用 Python 做

```python
import duckdb, pandas as pd

con = duckdb.connect("分析.duckdb")
con.execute("INSTALL excel; LOAD excel")

SRC = "./整理结果"
# 一次导入所有 xlsx（通配符 + 按文件名建表更省事时用循环）
for name in ["结局表1-并发并发症", "结局表2-研究结局"]:
    con.execute(f"""
        CREATE OR REPLACE TABLE "{name}" AS
        SELECT * FROM read_xlsx('{SRC}/{name}.xlsx', all_varchar => true)
    """)

print(con.sql("SHOW TABLES").df())
# ⚠️ 表名含连字符 - 时必须加双引号，否则连字符被当成减号：
#    Parser Error: syntax error at or near "-"
print(con.sql('SUMMARIZE "结局表1-并发并发症"').df())

# 直接拿到 DataFrame 继续用 pandas / polars
df = con.sql("""
    SELECT 中心编号, count(*) AS 总数
    FROM "结局表1-并发并发症"
    GROUP BY 中心编号
    ORDER BY 总数 DESC
""").df()
```

### 5.3 「Excel 清洗」常用片段

```sql
-- 全字符串读入 → 显式转型（最稳）
CREATE OR REPLACE TABLE t AS
SELECT
  id::INTEGER                        AS id,          -- 显式转整数
  try_cast(pay AS DECIMAL(10,2))     AS pay,         -- 转不动就给 NULL
  trim(name)                         AS name,        -- 去空白
  nullif(trim(dept), '')             AS dept,        -- 空串视作 NULL
  strptime(hired, '%Y-%m-%d')::DATE  AS hired        -- 字符串转日期
FROM read_xlsx('a.xlsx', all_varchar => true);

-- 查脏数据
SELECT * FROM t WHERE id IS NULL OR pay IS NULL;
```

### 5.4 用 `CASE` 把「是 / 否」转成 0/1 便于统计

```sql
SELECT dept,
       count(*) AS n,
       sum(CASE WHEN 气胸 = '是' THEN 1 ELSE 0 END) AS 气胸数,
       round(100.0 * sum(CASE WHEN 气胸 = '是' THEN 1 ELSE 0 END) / count(*), 1) AS 气胸率
FROM t GROUP BY dept;
```

---

## 6. 陷阱清单

### SQL 通用

1. **`UPDATE` / `DELETE` 忘 `WHERE`** → 全表。先用 `SELECT` 验证命中行数。
2. **`= NULL` 永远不成立** → 必须 `IS NULL`；`<>` 也会静默排除 NULL 行。
3. **`LEFT JOIN` 后在 `WHERE` 写右表条件** → 降级成 INNER JOIN，条件挪进 `ON`。
4. **聚合函数写进 `WHERE`** → 报错，该用 `HAVING`。
5. **窗口函数写进 `WHERE`** → 报错，套一层子查询或用 `QUALIFY`。
6. **`count(列)` vs `count(*)`** → 前者忽略 NULL。
7. **`SELECT DISTINCT` 写在多列上** → 是对「整行组合」去重，不是单列。
8. **`UNION` 会自动去重（慢）** → 确定无重复时用 `UNION ALL`。

### DuckDB 专有

9. **文件路径不加引号** → `syntax error at or near "."`。
10. **`-c "..."` 每次是独立内存库** → 建的表下次就没了，要用 `duckdb file.db`。
11. **xlsx 开了 `normalize_names`** → 中文表头被毁成 `_` `__1`。
12. **编号列变成 `1.0` / `2.0`** → DuckDB 猜成了 double，用 `all_varchar => true` 或显式 `::INTEGER`。
13. **`pl()` / `arrow()` 报 `No module named 'pyarrow'`** → 装 pyarrow。
14. **`fetchall()` 之后再 `fetchone()`** → 返回 `None`，游标只能消费一次。
15. **DuckDB 不能写 xlsx** → 只能读，输出走 CSV / Parquet 或 `.excel` 点命令。
16. **中文表名 / 列名含 `-`、空格、全角括号时的引号规则**：
    - 纯中文（含全角括号）**不加引号也能用**：`SELECT 中心编号 FROM t`、`SELECT 并发并发症（如有则记如下）_纵膈气肿 FROM t` 都实测通过。
    - 含**半角连字符 `-`** 必须加双引号：`SUMMARIZE "结局表1-并发并发症"`。不加会 `Parser Error: syntax error at or near "-"`（连字符被当成减号）。
    - 含**空格**、**半角括号**等也一律加双引号。
    - **保险做法**：不确定就加 `"` 包起来，永远不出错。

---

## 7. 结语：需要背下来的最小集合

```sql
SELECT DISTINCT 列, 聚合(列) FROM 表
  JOIN 另一表 ON 条件
  WHERE 行条件
  GROUP BY 列
  HAVING 组条件
  ORDER BY 列 DESC
  LIMIT 10;
```

加上 `WITH ... AS (...)` 拆步骤、`OVER (PARTITION BY ...)` 做组内计算、`CASE WHEN` 做分支、`COALESCE` 防 NULL
—— 日常 95% 的分析需求就覆盖了。

```python
con.sql("...").df()      # 读数据
con.register("df", df)   # 喂 DataFrame
rel.write_parquet(...)   # 落地
```
