# DuckDB 详细教程

> DuckDB 是一个现代化的、嵌入式的、列式存储的 OLAP 数据库。它是"数据分析界的 SQLite"。
> 本教程假设你有基本 SQL 知识（可先阅读《SQL 零基础教程》）。

---

## 目录

1. [DuckDB 是什么](#1-duckdb-是什么)
2. [为什么选择 DuckDB](#2-为什么选择-duckdb)
3. [核心概念与架构](#3-核心概念与架构)
4. [安装指南](#4-安装指南)
5. [CLI 命令行快速入门](#5-cli-命令行快速入门)
6. [创建数据库与表](#6-创建数据库与表)
7. [数据导入（CSV / Parquet / JSON / Excel）](#7-数据导入csv--parquet--json--excel)
8. [数据导出](#8-数据导出)
9. [直接查询外部文件](#9-直接查询外部文件)
10. [DuckDB 特有的 SQL 扩展（Friendly SQL）](#10-duckdb-特有的-sql-扩展friendly-sql)
11. [DuckDB 的数据类型](#11-duckdb-的数据类型)
12. [多数据库操作（ATTACH）](#12-多数据库操作attach)
13. [Python 集成](#13-python-集成)
14. [R 集成](#14-r-集成)
15. [Node.js / JavaScript 集成](#15-nodejs--javascript-集成)
16. [HTTP 与 S3 远程数据访问](#16-http-与-s3-远程数据访问)
17. [性能优化与最佳实践](#17-性能优化与最佳实践)
18. [DuckDB vs 其他工具对比](#18-duckdb-vs-其他工具对比)
19. [常见使用场景与案例](#19-常见使用场景与案例)
20. [进阶资源](#20-进阶资源)

---

## 1. DuckDB 是什么

### 1.1 一句话概括

**DuckDB 是一个嵌入式的、列式存储的 OLAP 数据库管理系统。**

拆解这句话：

| 词 | 含义 |
|----|------|
| **嵌入式** | 像 SQLite 一样内嵌在应用中，不需要单独的服务器进程 |
| **列式存储** | 数据按列存储（而非按行），分析查询极快 |
| **OLAP** | 面向在线分析处理（OnLine Analytical Processing），适合聚合、统计、报表 |
| **数据库管理系统** | 完整的 SQL 支持、ACID 事务、多客户端访问 |

### 1.2 DuckDB 的定位

```
                    OLTP（事务处理）          OLAP（分析处理）
                    ─────────────            ─────────────
服务器架构        PostgreSQL, MySQL       Snowflake, BigQuery, ClickHouse
嵌入式架构        SQLite                  DuckDB ← 我们在这里
```

DuckDB 填补了"嵌入式分析数据库"这一空白：它像 SQLite 一样零配置、无服务器，但像 ClickHouse 一样擅长分析查询。

### 1.3 核心理念

```
"数据应该在它产生的地方被分析"

你不需要：
  ✗ 启动数据库服务器
  ✗ 配置连接字符串
  ✗ 将数据导入到远程集群
  ✗ 等待 ETL 管道

你只需要：
  ✓ 安装 DuckDB
  ✓ 指向你的数据文件
  ✓ 写 SQL 查询
```

---

## 2. 为什么选择 DuckDB

### 2.1 DuckDB 的优势

```
🚀 极速分析
  - 列式存储 + 向量化执行引擎
  - 自动查询优化
  - 比 pandas/SQLite 快 10-100 倍

📦 零依赖、零配置
  - 单个可执行文件
  - 无需安装任何依赖
  - 无需启动服务器

📁 出色的文件支持
  - 直接查询 CSV、Parquet、JSON 文件
  - 无需先"导入"
  - 自动推断 schema

🐍 完美的数据分析伙伴
  - 与 Python/R 深度集成
  - 零拷贝与 pandas/polars 互操作
  - 替代 pandas 做复杂分析

🎯 友好的 SQL 方言
  - SELECT * EXCLUDE (...)
  - GROUP BY ALL
  - 友好的日期函数
  - 自动列别名
```

### 2.2 何时使用 DuckDB

```
✅ 适合：
  - 本地数据分析（替代 pandas 复杂操作）
  - CSV/Parquet/JSON 文件查询
  - 快速原型和探索性分析
  - 嵌入式应用中的分析功能
  - 数据管道中的中间处理
  - 测试和开发（替代完整数据库）
  - 教学和学习 SQL

❌ 不适合：
  - 高并发写入（选 PostgreSQL）
  - 海量用户同时查询（选 ClickHouse）
  - OLTP 事务处理（选 SQLite/PostgreSQL）
  - 需要复杂用户权限管理（选 PostgreSQL）
```

---

## 3. 核心概念与架构

### 3.1 架构概览

```
应用进程
    │
    ├── DuckDB Library (C++ 核心)
    │       ├── SQL Parser（SQL 解析器）
    │       ├── Optimizer（查询优化器）
    │       ├── Execution Engine（向量化执行引擎）
    │       └── Storage Engine（列式存储引擎）
    │
    └── 数据文件 (.db / .duckdb)
             ├── 列式数据段
             ├── 索引
             └── 元数据
```

### 3.2 列式存储 vs 行式存储

```
行式存储（SQLite, PostgreSQL）：
┌──────┬────────┬─────┬───────┐
│ id=1 │ 张三   │ 20  │ 85    │
├──────┼────────┼─────┼───────┤
│ id=2 │ 李四   │ 22  │ 92    │
├──────┼────────┼─────┼───────┤
│ id=3 │ 王五   │ 21  │ 78    │
└──────┴────────┴─────┴───────┘
→ 查询所有行的一行很快，但分析单列很慢

列式存储（DuckDB）：
[id]  [1, 2, 3, ...]          → 单独存储
[name] [张三, 李四, 王五]       → 单独存储
[age] [20, 22, 21]            → 单独存储
[grade] [85, 92, 78]          → 单独存储
→ 聚合查询极快：AVG(grade) 只扫描 grade 列！
```

### 3.3 向量化执行

传统数据库：一次处理一行 → "火山模型"
DuckDB：一次处理一批行（向量）→ "向量化执行"

```
传统方式：                  DuckDB：
row 1 → 处理               [row 1, row 2, ..., row 2048] → 批量处理
row 2 → 处理               CPU SIMD 指令并行
row 3 → 处理               缓存友好，分支预测友好
...
```

### 3.4 事务支持

DuckDB 支持 ACID 事务和 MVCC（多版本并发控制）：

```sql
-- 读写事务
BEGIN;
SELECT * FROM users WHERE id = 1;
UPDATE users SET name = '新名字' WHERE id = 1;
COMMIT;

-- 多个并发读（互不阻塞）
-- 多个写会序列化执行
```

---

## 4. 安装指南

### 4.1 命令行工具（CLI）

```bash
# macOS (Homebrew)
brew install duckdb

# Linux (直接下载)
wget https://github.com/duckdb/duckdb/releases/latest/download/duckdb_cli-linux-amd64.zip
unzip duckdb_cli-linux-amd64.zip
sudo mv duckdb /usr/local/bin/

# Windows (Chocolatey)
choco install duckdb

# 或者直接下载二进制文件
# 访问：https://duckdb.org/docs/installation/
```

### 4.2 Python

```bash
pip install duckdb

# 或使用 conda
conda install python-duckdb -c conda-forge
```

```python
import duckdb

# 基础用法
duckdb.sql("SELECT 'Hello, DuckDB!'").show()

# 连接数据库文件
con = duckdb.connect('mydb.duckdb')
con.sql("CREATE TABLE test (id INTEGER, name VARCHAR)")
con.sql("INSERT INTO test VALUES (1, 'hello')")
con.sql("SELECT * FROM test").show()
```

### 4.3 R

```r
install.packages("duckdb")

library(duckdb)
con <- dbConnect(duckdb(), dbdir = "mydb.duckdb")
dbWriteTable(con, "test", data.frame(id = 1:3, name = c("a", "b", "c")))
dbGetQuery(con, "SELECT * FROM test")
dbDisconnect(con)
```

### 4.4 Node.js

```bash
npm install duckdb
```

```javascript
const duckdb = require('duckdb');
const db = new duckdb.Database('mydb.duckdb');
const con = db.connect();

con.all('SELECT 42 AS answer', (err, res) => {
    console.log(res);  // [{answer: 42}]
});
```

### 4.5 其他语言

DuckDB 还支持 Java (JDBC), C/C++, Go, Rust, Julia, Swift 等。

---

## 5. CLI 命令行快速入门

### 5.1 启动与退出

```bash
# 打开内存数据库
duckdb

# 打开或创建持久化数据库
duckdb mydb.duckdb

# 退出
.exit
.quit
Ctrl+D
```

### 5.2 点命令（Dot Commands）

```sql
-- 查看帮助
.help

-- 列出所有表
.tables
SHOW TABLES;  -- SQL 方式

-- 查看表结构
DESCRIBE students;
.schema students

-- 切换输出模式
.mode line       -- 每行一列（适合宽表）
.mode csv        -- CSV 格式
.mode json       -- JSON 格式
.mode box        -- 表格框线
.mode markdown   -- Markdown 表格
.mode column     -- 列对齐

-- 输出到文件
.output result.txt
SELECT * FROM students;
.output          -- 恢复控制台输出

-- 导入/导出
.import file.csv tablename
.export file.csv

-- 读取并执行 SQL 文件
.read script.sql

-- 显示查询时间
.timer on
.timer off

-- 查看当前数据库文件路径
SELECT current_setting('database_path');
```

### 5.3 CLI 完整示例

```sql
-- 启动
$ duckdb school.duckdb

-- 创建表
CREATE TABLE students (
    id INTEGER PRIMARY KEY,
    name VARCHAR,
    age INTEGER,
    grade DOUBLE
);

-- 插入数据
INSERT INTO students VALUES
    (1, '张三', 20, 85.5),
    (2, '李四', 22, 92.0),
    (3, '王五', 21, 78.5),
    (4, '赵六', 23, 88.0),
    (5, '孙七', 20, 95.5);

-- 查询
SELECT name, grade FROM students WHERE grade > 80 ORDER BY grade DESC;

-- 聚合
SELECT AVG(grade) AS avg_grade, COUNT(*) AS total FROM students;

-- 格式化输出
.mode markdown
SELECT * FROM students LIMIT 3;

-- 退出
.exit
```

---

## 6. 创建数据库与表

### 6.1 数据库文件

```sql
-- 持久化数据库：数据保存到磁盘文件
ATTACH 'mydb.duckdb';              -- 附加已有数据库
-- 或启动时指定：duckdb mydb.duckdb

-- 内存数据库：数据仅存在于内存中（进程结束即丢失）
ATTACH ':memory:';
-- 或直接启动：duckdb
```

### 6.2 创建表

```sql
-- 基本建表
CREATE TABLE students (
    id INTEGER PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    age INTEGER,
    grade DOUBLE,
    enrolled DATE
);

-- IF NOT EXISTS（安全创建）
CREATE TABLE IF NOT EXISTS students (
    id INTEGER PRIMARY KEY,
    name VARCHAR
);

-- 临时表（会话结束自动删除）
CREATE TEMP TABLE temp_results AS
SELECT * FROM students WHERE grade > 80;

-- 从查询结果创建表（CTAS）
CREATE TABLE top_students AS
SELECT name, grade FROM students WHERE grade >= 90;

-- 复制表结构（不含数据）
CREATE TABLE students_backup AS
SELECT * FROM students WHERE 1 = 0;
```

### 6.3 修改表

```sql
-- 添加列
ALTER TABLE students ADD COLUMN phone VARCHAR(20);

-- 删除列
ALTER TABLE students DROP COLUMN phone;

-- 重命名列
ALTER TABLE students RENAME COLUMN grade TO score;

-- 修改列类型
ALTER TABLE students ALTER COLUMN score TYPE FLOAT;

-- 重命名表
ALTER TABLE students RENAME TO pupils;

-- 删除表
DROP TABLE IF EXISTS students;
```

### 6.4 查看表信息

```sql
-- 列出所有表
SHOW TABLES;
.tables

-- 查看表结构
DESCRIBE students;
SHOW students;
PRAGMA table_info('students');

-- 查看建表语句
SELECT sql FROM duckdb_tables() WHERE table_name = 'students';
```

---

## 7. 数据导入（CSV / Parquet / JSON / Excel）

DuckDB 的导入功能是其最大亮点之一。

### 7.1 从 CSV 导入

```sql
-- 自动推断 schema
CREATE TABLE users AS
SELECT * FROM read_csv('users.csv');

-- 简写：直接查询 CSV
SELECT * FROM 'users.csv';

-- 进阶选项
CREATE TABLE users AS
SELECT * FROM read_csv(
    'users.csv',
    header = true,                -- 第一行是列名
    delim = ',',                  -- 分隔符
    columns = {                   -- 手动指定列类型
        'id': 'INTEGER',
        'name': 'VARCHAR',
        'age': 'INTEGER',
        'email': 'VARCHAR',
        'salary': 'DOUBLE'
    },
    dateformat = '%Y-%m-%d',     -- 日期格式
    nullstr = 'NULL',            -- NULL 表示
    ignore_errors = true,        -- 忽略解析错误
    sample_size = 10000,         -- 推断 schema 的采样行数
    auto_detect = true           -- 自动检测参数
);

-- 读取 CSV 但不建表
SELECT COUNT(*), AVG(salary) FROM read_csv('users.csv');
```

### 7.2 从 Parquet 导入

Parquet 是列式存储格式，与 DuckDB 天然配合。

```sql
-- 直接查询 Parquet 文件
SELECT * FROM read_parquet('data.parquet');

-- 简写
SELECT * FROM 'data.parquet';

-- 读取目录下所有 Parquet 文件
SELECT * FROM read_parquet('data/*.parquet');

-- 读取时过滤（谓词下推，只读需要的行）
SELECT * FROM read_parquet('data.parquet')
WHERE date > '2025-01-01';

-- 只读取需要的列
SELECT name, age FROM read_parquet('data.parquet');
-- Parquet 列式存储，只读取指定列，极快！

-- 导入到表中
CREATE TABLE users AS
SELECT * FROM read_parquet('users.parquet');

-- Hive 分区支持
SELECT * FROM read_parquet('data/year=2025/month=06/*.parquet');
```

### 7.3 从 JSON 导入

```sql
-- 直接查询 JSON 文件
SELECT * FROM read_json('data.json');

-- 读取 NDJSON（每行一个 JSON 对象）
SELECT * FROM read_json('data.ndjson');

-- 读取压缩 JSON
SELECT * FROM read_json('data.json.gz');

-- 导入到表（自动展平嵌套结构）
CREATE TABLE events AS
SELECT * FROM read_json('events.json',
    format = 'auto',              -- auto / array / newline_delimited
    maximum_depth = 10            -- 最大嵌套深度
);

-- 处理嵌套 JSON
-- 原始 JSON: {"user": {"name": "张三", "age": 20}, "score": 95}
SELECT
    user->>'name' AS name,        -- 提取嵌套字段
    user->>'age' AS age,
    score
FROM read_json('data.json');
```

### 7.4 从 Excel 导入

```sql
-- 需要先安装扩展
INSTALL spatial;  -- excel 功能在 spatial 扩展中
LOAD spatial;

-- 读取 Excel
SELECT * FROM st_read('data.xlsx');

-- 读取特定工作表
SELECT * FROM st_read('data.xlsx', layer = 'Sheet2');
```

### 7.5 从其他数据库导入

```sql
-- PostgreSQL
INSTALL postgres_scanner;
LOAD postgres_scanner;
CALL postgres_attach('host=localhost dbname=mydb user=postgres');
-- 现在可以查询 PostgreSQL 中的表了！

-- SQLite
INSTALL sqlite_scanner;
LOAD sqlite_scanner;
CALL sqlite_attach('other.db');
-- 注意：也可以直接用 ATTACH 'other.db' (TYPE SQLITE)

-- MySQL
INSTALL mysql_scanner;
LOAD mysql_scanner;
ATTACH 'host=localhost database=mydb user=root' AS mysql_db (TYPE MYSQL);
```

### 7.6 从 pandas/Polars DataFrame 导入

```python
import duckdb
import pandas as pd

df = pd.DataFrame({'id': [1, 2, 3], 'name': ['张三', '李四', '王五']})

# 方式1：register 为虚拟表
duckdb.register('my_df', df)
duckdb.sql("SELECT * FROM my_df WHERE id > 1").show()

# 方式2：直接在 SQL 中引用
duckdb.sql("SELECT * FROM df").show()

# 方式3：导入到持久化表
con = duckdb.connect('mydb.duckdb')
con.execute("CREATE TABLE users AS SELECT * FROM df")
```

---

## 8. 数据导出

### 8.1 导出为 CSV

```sql
-- 从查询结果导出
COPY (SELECT * FROM students WHERE grade > 80)
TO 'output.csv' (HEADER, DELIMITER ',');

-- 从表导出
COPY students TO 'students.csv' (HEADER true);

-- COPY 选项
COPY students TO 'output.csv' (
    HEADER true,          -- 包含列名
    DELIMITER '|',        -- 分隔符
    NULL 'NULL',          -- NULL 表示
    QUOTE '"',            -- 引号字符
    FORCE_QUOTE (name)    -- 强制对 name 列使用引号
);
```

### 8.2 导出为 Parquet

```sql
-- 导出为 Parquet（推荐，保留类型信息且压缩高效）
COPY students TO 'students.parquet' (FORMAT PARQUET);

-- 按分区导出
COPY (
    SELECT *, year(date) AS yr
    FROM sales
) TO 'sales_output' (
    FORMAT PARQUET,
    PARTITION_BY (yr),
    OVERWRITE true
);
-- 生成：sales_output/yr=2024/, sales_output/yr=2025/, ...
```

### 8.3 导出为 JSON

```sql
-- 导出为 NDJSON
COPY students TO 'students.json' (FORMAT JSON);

-- 导出为 JSON 数组
COPY students TO 'students.json' (FORMAT JSON, ARRAY true);
```

### 8.4 导出为 Excel

```sql
INSTALL spatial; LOAD spatial;
COPY students TO 'students.xlsx' (FORMAT GDAL, DRIVER 'XLSX');
```

### 8.5 导出到 pandas/polars DataFrame

```python
# DuckDB → pandas
df = duckdb.sql("SELECT * FROM students").df()

# DuckDB → polars
df = duckdb.sql("SELECT * FROM students").pl()

# DuckDB → Arrow Table
table = duckdb.sql("SELECT * FROM students").arrow()

# .fetchdf() 也可以（老版本风格）
df = con.execute("SELECT * FROM students").fetchdf()
```

---

## 9. 直接查询外部文件

DuckDB 支持**无需导入、直接查询外部文件**，这是它的核心便利特性。

### 9.1 基本语法

```sql
-- 直接查询 CSV 文件
SELECT * FROM 'data.csv';
SELECT COUNT(*), AVG(grade) FROM 'students.csv' WHERE age > 20;

-- 直接查询 Parquet
SELECT * FROM 'data.parquet';
SELECT * FROM 'data/*.parquet';    -- 整个目录

-- 直接查询 JSON
SELECT * FROM 'data.json';

-- 自动从扩展名推断格式！
```

### 9.2 文件 Glob 模式

```sql
-- 读取目录下所有匹配的文件
SELECT * FROM 'data/*.csv';
SELECT * FROM 'data/**/*.csv';          -- 递归子目录
SELECT * FROM 'data/2025-*.parquet';    -- 通配符匹配
SELECT * FROM 'data/[abc]*.csv';        -- 字符集匹配
```

### 9.3 联合多文件

```sql
-- 读取多个文件，自动合并
SELECT * FROM read_csv(['file1.csv', 'file2.csv', 'file3.csv']);

-- 利用 glob 自动合并
SELECT * FROM read_csv('logs/2025/*.csv');

-- 添加文件名作为列（知道每行来自哪个文件）
SELECT *, filename FROM read_csv('data/*.csv', filename = true);
```

### 9.4 查询时直接过滤

```sql
-- 只取需要的列（对列式文件如 Parquet 极快）
SELECT name, grade FROM 'data.parquet';

-- 过滤（谓词下推）
SELECT * FROM 'data.parquet' WHERE date > '2025-01-01';

-- 聚合分析（无需导入全部数据）
SELECT
    class_id,
    COUNT(*) AS cnt,
    AVG(grade) AS avg_g
FROM 'students.csv'
GROUP BY class_id
ORDER BY avg_g DESC;

-- 连接外部文件和数据库表
SELECT s.name, c.name AS class
FROM 'students.csv' s
JOIN classes c ON s.class_id = c.id;
```

---

## 10. DuckDB 特有的 SQL 扩展（Friendly SQL）

DuckDB 实现了"友好的 SQL"，让编写查询更简单。

### 10.1 SELECT * EXCLUDE / REPLACE

```sql
-- EXCLUDE：排除某些列
SELECT * EXCLUDE (email, phone) FROM students;
-- 返回除 email 和 phone 之外的所有列

-- REPLACE：替换某些列的值
SELECT * REPLACE (grade * 1.1 AS grade) FROM students;
-- grade 列变成原值的 1.1 倍，其他列不变

-- 组合使用
SELECT * EXCLUDE (created_at)
REPLACE (UPPER(name) AS name)
FROM students;
```

### 10.2 GROUP BY ALL

```sql
-- 标准 SQL（要手动指定 GROUP BY 列）
SELECT class_id, AVG(grade), COUNT(*)
FROM students
GROUP BY class_id;

-- DuckDB Friendly SQL
SELECT class_id, AVG(grade), COUNT(*)
FROM students
GROUP BY ALL;
-- 自动按 SELECT 中的非聚合列分组！
```

### 10.3 COLUMNS() 表达式

```sql
-- COLUMNS() 表达式：动态选择列

-- 所有列名匹配某个正则
SELECT COLUMNS('grade|score') FROM students;   -- 返回 grade 和 score 列

-- 所有列转换
SELECT COLUMNS(c -> c * 2) FROM numbers_table;  -- 每列乘以 2

-- 对匹配列应用函数
SELECT COLUMNS('^price_') * 1.1 FROM products;  -- 所有 price_ 开头的列乘以 1.1

-- EXCEPT：排除某些列
SELECT COLUMNS('grade|score') FROM students;
-- 等同于 COLUMNS(c -> regexp_matches(c, 'grade|score'))
```

### 10.4 友好的别名

```sql
-- 自动生成列别名
SELECT AVG(grade) FROM students;
-- 列名自动为 avg(grade)，无需 AS

SELECT name, grade + 10 FROM students;
-- 第二列名为 (grade + 10)
```

### 10.5 表函数（Table Functions）

```sql
-- generate_series：生成序列
SELECT * FROM generate_series(1, 10);
SELECT * FROM generate_series('2025-01-01'::DATE, '2025-12-31'::DATE, INTERVAL '1 month');

-- unnest：展开数组
SELECT unnest([1, 2, 3, 4, 5]);

-- range
SELECT * FROM range(10);
SELECT * FROM range(0, 100, 5);

-- 生成随机数据
SELECT
    range AS id,
    random() AS value
FROM range(100);
```

### 10.6 FROM-first 语法

```sql
-- DuckDB 支持表名在 SELECT 之前的语法
FROM students SELECT *;
FROM students SELECT name, grade WHERE grade > 80;

-- 这在探索数据时特别方便（先写 FROM 确定数据源）
```

### 10.7 SAMPLE 子句

```sql
-- 随机采样行
SELECT * FROM students USING SAMPLE 10;       -- 10 行随机样本
SELECT * FROM students USING SAMPLE 10%;      -- 10% 的随机样本
SELECT * FROM students USING SAMPLE reservoir(10);  -- 蓄水池采样

-- 可重复采样（指定 seed）
SELECT * FROM students USING SAMPLE 10% (system, 42);
```

### 10.8 QUALIFY 子句

```sql
-- QUALIFY 直接过滤窗口函数结果（省去子查询）
-- 标准 SQL（需要子查询）
SELECT * FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY class_id ORDER BY grade DESC) AS rn
    FROM students
) WHERE rn = 1;

-- DuckDB Friendly SQL
SELECT *, ROW_NUMBER() OVER (PARTITION BY class_id ORDER BY grade DESC) AS rn
FROM students
QUALIFY rn = 1;
-- 每个班级取成绩最高的！
```

### 10.9 表达式索引

```sql
-- 简化列定义
CREATE TABLE example (
    i INTEGER PRIMARY KEY DEFAULT (nextval('seq')),
    j STRUCT(k VARCHAR, l INTEGER),
    k ALWAYS AS (j.k),      -- 计算列
    INDEX myindex (i, j)
);
```

### 10.10 隐式 JOIN

```sql
-- 从 SELECT 自动推断 JOIN
SELECT
    students.name,
    classes.name AS class_name
FROM students, classes
WHERE students.class_id = classes.id;
-- 等价于 INNER JOIN ... ON ...，但 DuckDB 能自动识别
```

---

## 11. DuckDB 的数据类型

### 11.1 基础类型

```sql
-- 数值类型
INTEGER / INT          -- 4 字节整数
BIGINT                 -- 8 字节整数
SMALLINT               -- 2 字节整数
TINYINT                -- 1 字节整数
UBIGINT                -- 无符号大整数
HUGEINT                -- 16 字节整数（专用）
FLOAT                  -- 4 字节浮点
DOUBLE                 -- 8 字节浮点
DECIMAL(prec, scale)   -- 定点小数

-- 字符串类型
VARCHAR / TEXT / STRING  -- 字符串
BLOB                    -- 二进制数据
ENUM                    -- 枚举（原生支持！）
UUID                    -- UUID

-- 日期时间
DATE                    -- 日期
TIME                    -- 时间
TIMESTAMP               -- 时间戳
TIMESTAMP WITH TIME ZONE -- 带时区的时间戳
INTERVAL                -- 时间间隔

-- 布尔
BOOLEAN / BOOL          -- true / false

-- 特殊
BIT                     -- 位串
JSON                    -- JSON（原生支持！）
```

### 11.2 嵌套/复合类型（DuckDB 特色）

```sql
-- STRUCT：结构体（类似 C 的 struct）
CREATE TABLE users (
    id INTEGER,
    info STRUCT(name VARCHAR, age INTEGER, address STRUCT(city VARCHAR, zip VARCHAR))
);

INSERT INTO users VALUES (1, {'name': '张三', 'age': 20, 'address': {'city': '北京', 'zip': '100000'}});

-- 访问嵌套字段
SELECT info.name, info.address.city FROM users;

-- LIST：数组
CREATE TABLE orders (
    id INTEGER,
    items VARCHAR[],     -- VARCHAR 数组
    quantities INTEGER[] -- INTEGER 数组
);

INSERT INTO orders VALUES (1, ['苹果', '香蕉', '橘子'], [3, 2, 5]);

-- 数组操作
SELECT
    items[1] AS first_item,       -- 索引从 1 开始
    len(items) AS item_count,
    items[2:3] AS sliced,         -- 切片
    array_concat(items, ['西瓜'])  -- 拼接
FROM orders;

-- MAP：字典/映射
CREATE TABLE config (
    id INTEGER,
    settings MAP(VARCHAR, VARCHAR)
);

INSERT INTO config VALUES (1, MAP {'theme': 'dark', 'lang': 'zh', 'timeout': '30'});

SELECT
    settings['theme'],
    settings['lang'],
    map_keys(settings) AS keys,
    map_values(settings) AS vals
FROM config;

-- UNION（tagged union）
CREATE TABLE shapes (
    id INTEGER,
    shape UNION(circle STRUCT(radius DOUBLE), rectangle STRUCT(width DOUBLE, height DOUBLE))
);
```

### 11.3 JSON 类型

```sql
-- 创建 JSON 列
CREATE TABLE logs (
    id INTEGER,
    data JSON
);

INSERT INTO logs VALUES
(1, '{"user": "张三", "action": "login", "ip": "1.2.3.4"}'),
(2, '{"user": "李四", "action": "purchase", "amount": 99.9}');

-- 提取 JSON 字段
SELECT
    data->>'user' AS username,
    data->>'action' AS action
FROM logs;

-- 条件过滤
SELECT * FROM logs WHERE data->>'action' = 'login';

-- JSON 与 STRUCT 互转
SELECT json('{"a": 1, "b": 2}')::STRUCT(a INTEGER, b INTEGER);
SELECT CAST({'a': 1, 'b': 2} AS JSON);
```

---

## 12. 多数据库操作（ATTACH）

DuckDB 可以同时操作多个数据库，甚至不同类型的数据源。

### 12.1 基本 ATTACH

```sql
-- 附加另一个 DuckDB 数据库
ATTACH 'other.duckdb' AS other_db;
-- 现在可以查询 other_db 中的表
SELECT * FROM other_db.students;

-- 查看所有附加的数据库
SELECT * FROM duckdb_databases();

-- 切换默认数据库
USE other_db;

-- 分离数据库
DETACH other_db;
```

### 12.2 跨数据库查询

```sql
-- 连接两个数据库中的表
ATTACH 'school.duckdb' AS school;
ATTACH 'library.duckdb' AS library;

SELECT
    s.name,
    b.title,
    b.borrowed_date
FROM school.students s
JOIN library.borrowed b ON s.id = b.student_id;
```

### 12.3 附加外部数据源（扩展能力）

```sql
-- SQLite
INSTALL sqlite_scanner;
LOAD sqlite_scanner;
ATTACH 'legacy.db' AS sqlite_db (TYPE SQLITE);

-- PostgreSQL（需要 postgres_scanner 扩展）
INSTALL postgres_scanner;
LOAD postgres_scener;
ATTACH 'host=prod.db.com dbname=warehouse' AS pg_db (TYPE POSTGRES);

-- MySQL
INSTALL mysql_scanner;
LOAD mysql_scanner;
ATTACH 'host=localhost database=app' AS mysql_db (TYPE MYSQL);
```

---

## 13. Python 集成

DuckDB 与 Python 的集成极为紧密，是 pandas 的强大替代。

### 13.1 基本用法

```python
import duckdb

# 方式1：默认内存数据库
duckdb.sql("SELECT 'Hello' AS greeting").show()

# 方式2：连接数据库文件
con = duckdb.connect('mydb.duckdb')

# 方式3：只读连接
con = duckdb.connect('mydb.duckdb', read_only=True)
```

### 13.2 与 pandas 无缝互操作

```python
import duckdb
import pandas as pd

# pandas DataFrame → DuckDB（零拷贝）
df = pd.DataFrame({
    'name': ['张三', '李四', '王五'],
    'age': [20, 22, 21],
    'grade': [85.5, 92.0, 78.5]
})

# 直接在 SQL 中引用 DataFrame！
result = duckdb.sql("""
    SELECT name, grade,
           CASE WHEN grade >= 90 THEN '优秀'
                WHEN grade >= 80 THEN '良好'
                ELSE '一般'
           END AS level
    FROM df
    ORDER BY grade DESC
""")
print(result)

# DuckDB → pandas DataFrame
df_result = result.df()
# 或 .fetchdf()
df_result = duckdb.sql("SELECT * FROM df WHERE age > 20").fetchdf()

# DuckDB → Polars
df_pl = duckdb.sql("SELECT * FROM df").pl()

# DuckDB → Arrow Table
table = duckdb.sql("SELECT * FROM df").arrow()

# pandas → DuckDB 表（持久化）
con = duckdb.connect('school.duckdb')
con.execute("CREATE TABLE students AS SELECT * FROM df")
# 或者用 register
con.register('students', df)
```

### 13.3 查询文件（无需 pandas）

```python
import duckdb

# 直接查询 CSV
result = duckdb.sql("""
    SELECT city, COUNT(*) AS cnt, AVG(price) AS avg_price
    FROM 'listings.csv'
    WHERE price > 0
    GROUP BY city
    ORDER BY cnt DESC
    LIMIT 10
""")
print(result.df())

# 查询 Parquet（性能更好）
result = duckdb.sql("""
    SELECT date_trunc('month', timestamp) AS month,
           SUM(amount) AS total_sales
    FROM 'sales/*.parquet'
    WHERE year(timestamp) = 2025
    GROUP BY month
    ORDER BY month
""")
print(result.df())

# 合并多个文件
result = duckdb.sql("""
    SELECT * FROM read_csv('data/2025-*.csv')
    WHERE amount > 100
""").df()
```

### 13.4 替换 pandas 复杂操作

```python
# ❌ pandas 方式（复杂、难读、可能慢）
import pandas as pd
df = pd.read_csv('sales.csv')
df['month'] = df['date'].dt.to_period('M')
df_filtered = df[df['amount'] > 0]
result = df_filtered.groupby(['region', 'month']).agg({
    'amount': ['sum', 'mean', 'count'],
    'customer_id': 'nunique'
}).reset_index()
result = result.sort_values(('amount', 'sum'), ascending=False).head(10)

# ✅ DuckDB 方式（清晰、快速）
result = duckdb.sql("""
    SELECT
        region,
        date_trunc('month', date) AS month,
        SUM(amount) AS total,
        AVG(amount) AS avg_amount,
        COUNT(*) AS transactions,
        COUNT(DISTINCT customer_id) AS unique_customers
    FROM 'sales.csv'
    WHERE amount > 0
    GROUP BY region, month
    ORDER BY total DESC
    LIMIT 10
""").df()
```

### 13.5 在 Jupyter Notebook 中

```python
# Jupyter notebook magic
%load_ext duckdb

# 单元格中执行 SQL
%%sql
SELECT name, grade FROM students WHERE grade > 80 ORDER BY grade DESC
```

---

## 14. R 集成

### 14.1 基本用法

```r
library(duckdb)
library(DBI)

# 创建连接
con <- dbConnect(duckdb(), dbdir = "mydb.duckdb")

# 执行 SQL
dbExecute(con, "CREATE TABLE students (id INTEGER, name VARCHAR, grade DOUBLE)")

dbExecute(con, "
    INSERT INTO students VALUES
    (1, '张三', 85.5),
    (2, '李四', 92.0),
    (3, '王五', 78.5)
")

# 查询
result <- dbGetQuery(con, "SELECT * FROM students WHERE grade > 80")
print(result)

# 从 data.frame / tibble 导入
df <- data.frame(
    name = c("赵六", "孙七"),
    grade = c(88.0, 95.5)
)
dbWriteTable(con, "students", df, append = TRUE)

# 直接查询 R 变量中的 data.frame
dbGetQuery(con, "SELECT name, grade FROM df ORDER BY grade DESC")

# 断开连接
dbDisconnect(con)
```

### 14.2 与 dplyr 配合

```r
library(duckdb)
library(dplyr)
library(dbplyr)

con <- dbConnect(duckdb(), dbdir = "mydb.duckdb")

# 使用 dplyr 语法查询 DuckDB
students_tbl <- tbl(con, "students")

result <- students_tbl %>%
    filter(grade > 80) %>%
    group_by(class_id) %>%
    summarise(
        avg_grade = mean(grade),
        count = n()
    ) %>%
    arrange(desc(avg_grade)) %>%
    collect()

# dplyr 代码会自动转换为 DuckDB SQL！
```

---

## 15. Node.js / JavaScript 集成

### 15.1 回调风格

```javascript
const duckdb = require('duckdb');
const db = new duckdb.Database('mydb.duckdb');
const con = db.connect();

// 执行 SQL
con.run('CREATE TABLE users (id INTEGER, name VARCHAR)');
con.run("INSERT INTO users VALUES (1, '张三'), (2, '李四')");

// 查询
con.all('SELECT * FROM users', (err, res) => {
    if (err) throw err;
    console.log(res);
    // [ { id: 1, name: '张三' }, { id: 2, name: '李四' } ]
});

// 逐行处理
con.each('SELECT * FROM users', (err, row) => {
    console.log(row);
});

// 清理
con.close();
db.close();
```

### 15.2 Promise 风格

```javascript
import { Database } from 'duckdb';
const db = new Database(':memory:');

function runQuery(sql, params = []) {
    return new Promise((resolve, reject) => {
        db.all(sql, ...params, (err, rows) => {
            if (err) reject(err);
            else resolve(rows);
        });
    });
}

async function main() {
    await runQuery('CREATE TABLE users (id INTEGER, name VARCHAR)');
    await runQuery("INSERT INTO users VALUES (1, '张三'), (2, '李四')");
    const users = await runQuery('SELECT * FROM users');
    console.log(users);
}
```

---

## 16. HTTP 与 S3 远程数据访问

DuckDB 可以直接查询网络上的数据文件！

### 16.1 HTTP/HTTPS 远程文件

```sql
-- 安装并加载 httpfs 扩展
INSTALL httpfs;
LOAD httpfs;

-- 直接查询远程 CSV
SELECT * FROM read_csv('https://example.com/datasets/sales.csv')
LIMIT 10;

-- 查询远程 Parquet
SELECT COUNT(*), AVG(amount)
FROM read_parquet('https://example.com/datasets/sales.parquet');

-- 直接执行分析
SELECT
    region,
    SUM(amount) AS total
FROM 'https://example.com/datasets/sales.parquet'
GROUP BY region
ORDER BY total DESC;
```

### 16.2 Amazon S3

```sql
INSTALL httpfs;
LOAD httpfs;

-- 设置 AWS 凭证
SET s3_region = 'us-east-1';
SET s3_access_key_id = 'YOUR_ACCESS_KEY';
SET s3_secret_access_key = 'YOUR_SECRET_KEY';
-- 或使用环境变量 AWS_ACCESS_KEY_ID 和 AWS_SECRET_ACCESS_KEY

-- 查询 S3 上的数据
SELECT COUNT(*) FROM read_parquet('s3://my-bucket/data/*.parquet');

-- 分析 S3 数据
SELECT
    date_trunc('month', timestamp) AS month,
    SUM(revenue) AS total_revenue
FROM 's3://my-bucket/sales/2025/*.parquet'
GROUP BY month
ORDER BY month;

-- 写入结果到 S3
COPY (SELECT * FROM summary)
TO 's3://my-bucket/output/summary.parquet' (FORMAT PARQUET);
```

### 16.3 Google Cloud Storage

```sql
INSTALL httpfs;
LOAD httpfs;

-- GCS 路径
SELECT * FROM read_parquet('gs://my-bucket/data.parquet');
```

### 16.4 Azure Blob Storage

```sql
INSTALL azure;
LOAD azure;

SET azure_connection_string = '...';
SELECT * FROM read_parquet('azure://my-container/data.parquet');
```

### 16.5 Hugging Face Datasets

```sql
INSTALL httpfs;
LOAD httpfs;

-- 直接查询 Hugging Face 上的数据集
SELECT * FROM read_parquet(
    'hf://datasets/username/dataset-name/data/*.parquet'
);
```

---

## 17. 性能优化与最佳实践

### 17.1 查询性能分析

```sql
-- EXPLAIN：查看执行计划
EXPLAIN SELECT * FROM students WHERE grade > 80;

-- EXPLAIN ANALYZE：查看实际执行时间和计划
EXPLAIN ANALYZE
SELECT class_id, AVG(grade)
FROM students
WHERE grade > 60
GROUP BY class_id;

-- 查看实际耗时
.timer on
SELECT ...;
```

### 17.2 使用 Parquet 格式

```sql
-- ❌ CSV 查询较慢（文本解析开销）
SELECT * FROM 'data.csv' WHERE date > '2025-01-01';

-- ✅ Parquet 查询极快（列式 + 谓词下推 + 压缩）
SELECT * FROM 'data.parquet' WHERE date > '2025-01-01';

-- 将 CSV 转为 Parquet 以提升后续查询速度
COPY (SELECT * FROM 'data.csv') TO 'data.parquet' (FORMAT PARQUET);
```

### 17.3 内存配置

```sql
-- 查看当前内存限制
SELECT current_setting('memory_limit');

-- 设置内存限制
SET memory_limit = '4GB';
SET memory_limit = '75%';  -- 使用系统内存的 75%

-- 设置临时目录（用于溢出到磁盘）
SET temp_directory = '/path/to/fast/ssd/tmp';
```

### 17.4 多线程配置

```sql
-- 查看/设置线程数
SELECT current_setting('threads');

SET threads = 4;  -- 使用 4 个线程

-- 通常设为 CPU 核心数即可
```

### 17.5 索引策略

```sql
-- DuckDB 使用 Min-Max 索引（Zone Maps）自动优化
-- 不需要手动创建 B-Tree 索引用于查询优化

-- 但可以创建约束索引
CREATE UNIQUE INDEX idx_email ON students(email);
```

### 17.6 查询优化建议

```
✅ 尽可能使用 Parquet 格式
✅ 只在需要时 SELECT 特定列（列式存储优势）
✅ 利用分区减少扫描数据量
✅ 合理设置 memory_limit 和 threads
✅ 对于大文件，先用 WHERE 过滤再聚合
✅ 使用 EXPLAIN ANALYZE 找出瓶颈
✅ 避免 SELECT * 除非真的需要所有列
✅ 对于重复使用的中间结果，创建物化表
```

### 17.7 大文件处理策略

```sql
-- 策略1：查询时直接过滤
SELECT region, SUM(amount)
FROM 'huge_file.parquet'
WHERE year(date) = 2025  -- 先过滤
GROUP BY region;

-- 策略2：创建视图简化后续查询
CREATE VIEW sales_2025 AS
SELECT * FROM 'huge_file.parquet' WHERE year(date) = 2025;

-- 策略3：物化中间结果
CREATE TABLE sales_2025_materialized AS
SELECT * FROM 'huge_file.parquet' WHERE year(date) = 2025;

-- 策略4：按分区写入和读取
COPY (SELECT * FROM 'huge_file.parquet')
TO 'partitioned/' (FORMAT PARQUET, PARTITION_BY year, OVERWRITE true);
```

---

## 18. DuckDB vs 其他工具对比

### 18.1 DuckDB vs SQLite

| 特性 | DuckDB | SQLite |
|------|--------|--------|
| 存储模型 | **列式** | 行式 |
| 优化目标 | **OLAP（分析）** | OLTP（事务） |
| 向量化执行 | ✅ | ❌ |
| 并行查询 | ✅ | ❌ |
| 直接查询文件 | ✅ (CSV/Parquet/JSON/S3) | ❌ |
| SQL 功能 | 完整 + 分析扩展 | 基础 |
| 客户端库 | C++/Python/R/JS/... | C/Python/... |
| 文件大小支持 | GB~TB | MB~GB |
| 并发写入 | 单写多读 | 单写多读 |
| 适合场景 | **数据分析、ETL** | 应用存储、事务 |

### 18.2 DuckDB vs pandas/polars

| 特性 | DuckDB | pandas | Polars |
|------|--------|--------|--------|
| SQL 支持 | ✅ 完整 | ❌ | ❌ |
| 内存外处理 | ✅ 自动溢出 | ❌ | ❌ |
| 大文件处理 | ✅ (>100GB) | ❌ (需 fit 内存) | ⚠️ 部分 |
| 类型系统 | ✅ 严格 | ⚠️ 隐式 | ✅ 严格 |
| 语法 | SQL | Python API | Python API |
| 持久化 | ✅ 数据库文件 | ❌ | ❌ |
| 适合 | **复杂分析 + SQL** | 交互式探索 | 高性能 ETL |

### 18.3 DuckDB vs ClickHouse

| 特性 | DuckDB | ClickHouse |
|------|--------|------------|
| 架构 | **嵌入式库** | 服务器进程 |
| 部署 | 零配置 | 需要服务器 |
| 并发查询 | 适中的并行 | 极高并发 |
| 数据量级 | GB ~ TB | TB ~ PB |
| 安装复杂度 | 一条命令 | 中等 |
| 适合 | **本地/嵌入式分析** | 生产级分析集群 |

### 18.4 DuckDB vs PostgreSQL

| 特性 | DuckDB | PostgreSQL |
|------|--------|------------|
| 架构 | 嵌入式 | 客户端/服务器 |
| 存储 | 列式 | 行式 |
| OLTP 事务 | ⚠️ 基础 | ✅ 成熟 |
| OLAP 分析 | ✅ 极快 | ⚠️ 较慢 |
| 权限管理 | ❌ 无 | ✅ 完善 |
| 复制/备份 | ❌ 基础 | ✅ 完善 |
| 生态 | 新兴 | 非常成熟 |
| 适合 | **分析任务** | **应用数据库** |

---

## 19. 常见使用场景与案例

### 19.1 场景一：CSV 文件分析（替代 Excel/pandas）

```sql
-- 你有 500MB 的 sales.csv，想分析销售趋势
-- 无需导入，直接查询！

-- 按月统计销售额
SELECT
    date_trunc('month', order_date) AS month,
    SUM(amount) AS total_sales,
    COUNT(*) AS order_count,
    AVG(amount) AS avg_order_value
FROM read_csv('sales.csv', auto_detect = true)
WHERE amount > 0
GROUP BY month
ORDER BY month;

-- 找出 Top 10 客户
SELECT customer_id, SUM(amount) AS total_spent
FROM 'sales.csv'
GROUP BY customer_id
ORDER BY total_spent DESC
LIMIT 10;
```

### 19.2 场景二：多文件合并分析

```sql
-- 每月一个 CSV 文件：sales_2025_01.csv, sales_2025_02.csv, ...
-- 一次查询全年数据
SELECT
    date_trunc('month', order_date) AS month,
    SUM(amount) AS total,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM 'sales_2025_*.csv'
GROUP BY month
ORDER BY month;

-- 输出为单个 Parquet 文件供后续使用
COPY (
    SELECT * FROM 'sales_2025_*.csv'
) TO 'sales_2025.parquet' (FORMAT PARQUET);
```

### 19.3 场景三：数据清洗

```sql
-- 清除重复数据
CREATE TABLE clean_users AS
SELECT * FROM (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY email ORDER BY created_at DESC) AS rn
    FROM 'users.csv'
) WHERE rn = 1;

-- 填充缺失值
SELECT
    COALESCE(name, '未知') AS name,
    COALESCE(age, (SELECT AVG(age) FROM 'users.csv')) AS age,
    COALESCE(email, 'no-email@example.com') AS email
FROM 'users.csv';

-- 验证数据质量
SELECT
    COUNT(*) AS total_rows,
    COUNT(name) AS name_filled,
    COUNT(email) AS email_filled,
    COUNT(CASE WHEN age IS NULL THEN 1 END) AS age_missing,
    COUNT(CASE WHEN age < 0 OR age > 120 THEN 1 END) AS age_invalid
FROM 'users.csv';
```

### 19.4 场景四：ETL 管道的一部分

```sql
-- 提取（Extract）：从多个源读取
ATTACH 'postgres://prod-db' AS pg (TYPE POSTGRES);
CREATE TEMP TABLE raw_orders AS
SELECT * FROM pg.orders WHERE order_date >= '2025-01-01';

-- 转换（Transform）：清洗和聚合
CREATE TABLE clean_orders AS
SELECT
    order_id,
    customer_id,
    order_date,
    COALESCE(amount, 0) AS amount,
    CASE
        WHEN amount >= 1000 THEN 'VIP'
        WHEN amount >= 500 THEN 'Gold'
        WHEN amount >= 100 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_tier
FROM raw_orders
WHERE amount IS NOT NULL AND amount >= 0;

-- 加载（Load）：导出为 Parquet
COPY clean_orders TO 's3://datalake/orders/' (FORMAT PARQUET, PARTITION_BY customer_tier);
```

### 19.5 场景五：机器学习数据准备

```python
import duckdb
import pandas as pd

con = duckdb.connect(':memory:')

# 特征工程：用 SQL 完成
features = con.sql("""
    SELECT
        u.user_id,
        u.age,
        u.registration_days,
        COUNT(DISTINCT o.order_id) AS order_count,
        COALESCE(SUM(o.amount), 0) AS total_spent,
        COALESCE(AVG(o.amount), 0) AS avg_order_value,
        MAX(o.order_date) AS last_order_date,
        CASE WHEN MAX(o.order_date) < CURRENT_DATE - 180 THEN 1 ELSE 0 END AS is_churned,
        CASE WHEN COUNT(DISTINCT o.order_id) > 10 THEN 1 ELSE 0 END AS is_power_user
    FROM users u
    LEFT JOIN orders o ON u.user_id = o.user_id
    GROUP BY u.user_id, u.age, u.registration_days
""").df()

# features DataFrame 可以直接用于 sklearn / pytorch 训练
```

### 19.6 场景六：API 数据导出

```python
from fastapi import FastAPI
import duckdb

app = FastAPI()
con = duckdb.connect('analytics.duckdb', read_only=True)

@app.get("/api/sales/summary")
def sales_summary():
    return con.sql("""
        SELECT region, SUM(amount) AS total
        FROM sales
        GROUP BY region
        ORDER BY total DESC
    """).df().to_dict(orient='records')

@app.get("/api/sales/by-date")
def sales_by_date(start: str, end: str):
    return con.sql(f"""
        SELECT date, SUM(amount) AS total
        FROM sales
        WHERE date BETWEEN '{start}' AND '{end}'
        GROUP BY date
        ORDER BY date
    """).df().to_dict(orient='records')
```

---

## 20. 进阶资源

### 20.1 官方资源

- **官方文档**：https://duckdb.org/docs/
- **SQL 参考**：https://duckdb.org/docs/sql/introduction
- **API 文档**：https://duckdb.org/docs/api/overview
- **GitHub**：https://github.com/duckdb/duckdb

### 20.2 安装常用扩展

```sql
-- 常用扩展一览
INSTALL httpfs;            -- HTTP/S3/GCS 文件访问
INSTALL postgres_scanner;  -- 连接 PostgreSQL
INSTALL sqlite_scanner;    -- 连接 SQLite
INSTALL mysql_scanner;     -- 连接 MySQL
INSTALL spatial;           -- 地理空间
INSTALL json;              -- JSON 增强
INSTALL excel;             -- Excel 支持
INSTALL parquet;           -- Parquet 读写
INSTALL full_text_search;  -- 全文搜索
INSTALL vss;               -- 向量相似搜索
INSTALL iceberg;           -- Apache Iceberg
INSTALL delta;             -- Delta Lake

-- 查看已安装扩展
SELECT * FROM duckdb_extensions();

-- 查看可用扩展
SELECT extension_name, installed, description
FROM duckdb_extensions();
```

### 20.3 学习路径

```
阶段 1：入门（1-3 天）
  ├─ 安装 DuckDB CLI 和 Python 库
  ├─ 运行基本 SQL（SELECT, WHERE, GROUP BY, JOIN）
  ├─ 尝试查询 CSV 文件
  └─ 用 Python + DuckDB 替代 pandas 简单操作

阶段 2：熟练（1 周）
  ├─ 掌握所有 DuckDB SQL 扩展（Friendly SQL）
  ├─ 数据导入导出（CSV ↔ Parquet ↔ JSON）
  ├─ 多文件查询和分区读写
  └─ Python 集成深入（register, df(), pl(), arrow()）

阶段 3：进阶（1 月）
  ├─ 远程数据访问（S3, HTTP, Hugging Face）
  ├─ 扩展使用（PostgreSQL scanner, spatial）
  ├─ 性能调优（EXPLAIN ANALYZE, memory, threads）
  ├─ 构建分析管道（ETL 脚本）
  └─ 窗口函数、递归 CTE 等高级 SQL

阶段 4：精通
  ├─ C++ API
  ├─ 自定义扩展开发
  ├─ 性能基准测试和优化
  └─ 贡献 DuckDB 开源项目
```

---

## 附录 A：快速参考卡片

### DuckDB CLI 常用命令

```
duckdb [dbname]              启动 CLI
.tables                      列出所有表
.schema table_name           查看表结构
.mode [csv|json|box|markdown|line|column]  输出模式
.output filename             输出到文件
.timer on|off                计时开关
.read script.sql             执行 SQL 文件
.explain on|off              自动显示执行计划
.import file.csv table_name  导入 CSV
SHOW/DESCRIBE table          查看表结构
.exit / .quit                退出
```

### Python 常用模式

```python
import duckdb

# 快速查询
duckdb.sql("SELECT * FROM 'file.parquet' LIMIT 5").show()

# 连接
con = duckdb.connect('mydb.duckdb')

# DataFrame → DuckDB
con.register('mytable', df)

# DuckDB → DataFrame
df = con.sql("SELECT * FROM mytable").df()
df = con.sql("SELECT * FROM mytable").fetchdf()

# 查询文件
df = duckdb.sql("SELECT * FROM 'data/*.parquet'").df()

# 注册并查询多个 DF
con.register('users', users_df)
con.register('orders', orders_df)
result = con.sql("""
    SELECT u.name, COUNT(o.id) AS order_count
    FROM users u
    LEFT JOIN orders o ON u.id = o.user_id
    GROUP BY u.name
""").df()
```

### SQL 速查

```sql
-- 查询文件
SELECT * FROM 'file.csv';
SELECT * FROM 'file.parquet';
SELECT * FROM '*.parquet';       -- glob
SELECT * FROM 's3://bucket/*.parquet';

-- 导入
CREATE TABLE t AS SELECT * FROM 'file.csv';
CREATE TABLE t AS SELECT * FROM read_csv('file.csv', auto_detect=true);

-- 导出
COPY t TO 'file.csv' (HEADER);
COPY t TO 'file.parquet' (FORMAT PARQUET);

-- 查看
SHOW TABLES;
DESCRIBE t;
SELECT * FROM duckdb_tables();

-- 配置
SET memory_limit = '4GB';
SET threads = 8;
```

---

> 📌 建议配合《SQL 零基础教程》一起阅读，先用 SQL 教程理解查询语法，再用本教程学习 DuckDB 的特性和实践。
>
> Happy Querying! 🦆
