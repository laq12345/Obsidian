# SQL 零基础教程

> 适合完全新手的 SQL 学习指南，从最基本的概念讲起，逐步深入。

---

## 目录

1. [什么是 SQL](#1-什么是-sql)
2. [数据库基础概念](#2-数据库基础概念)
3. [SQL 语句分类](#3-sql-语句分类)
4. [数据类型](#4-数据类型)
5. [DDL - 数据定义语言](#5-ddl---数据定义语言)
6. [DML - 数据操作语言](#6-dml---数据操作语言)
7. [DQL - 数据查询语言（基础）](#7-dql---数据查询语言基础)
8. [WHERE 子句与过滤](#8-where-子句与过滤)
9. [ORDER BY 排序与 LIMIT 限制](#9-order-by-排序与-limit-限制)
10. [常用函数](#10-常用函数)
11. [聚合查询与 GROUP BY](#11-聚合查询与-group-by)
12. [JOIN 连接查询（重点）](#12-join-连接查询重点)
13. [子查询（Subquery）](#13-子查询subquery)
14. [集合运算（UNION / INTERSECT / EXCEPT）](#14-集合运算union--intersect--except)
15. [CASE 表达式](#15-case-表达式)
16. [窗口函数（Window Functions）](#16-窗口函数window-functions)
17. [CTE（公用表表达式）](#17-cte公用表表达式)
18. [约束（Constraints）](#18-约束constraints)
19. [索引（Index）](#19-索引index)
20. [视图（View）](#20-视图view)
21. [事务（Transaction）](#21-事务transaction)
22. [最佳实践与常见错误](#22-最佳实践与常见错误)

---

## 1. 什么是 SQL

**SQL**（Structured Query Language，结构化查询语言）是与关系型数据库交互的标准语言。简单来说，SQL 就是"和数据库对话的语言"。

### 1.1 SQL 能做什么？

- **查询数据**：从数据库中找出你需要的信息
- **插入数据**：向数据库中添加新记录
- **更新数据**：修改已有的数据
- **删除数据**：移除不需要的记录
- **创建表结构**：定义数据的组织方式
- **控制权限**：管理谁能访问什么数据

### 1.2 主流数据库

| 数据库 | 类型 | 典型场景 |
|--------|------|----------|
| SQLite | 嵌入式 | 移动应用、本地存储 |
| DuckDB | 嵌入式 OLAP | 数据分析、数据处理 |
| PostgreSQL | 客户端/服务器 | Web 应用、企业系统 |
| MySQL/MariaDB | 客户端/服务器 | Web 应用、中小型系统 |
| SQL Server | 客户端/服务器 | 企业级 Windows 应用 |
| Oracle | 客户端/服务器 | 大型企业系统 |

---

## 2. 数据库基础概念

### 2.1 核心概念类比

把数据库想象成一个 **Excel 工作簿**：

| 数据库概念 | Excel 类比 |
|-----------|-----------|
| **数据库（Database）** | 整个 Excel 文件 (.xlsx) |
| **表（Table）** | 一个工作表（Sheet） |
| **行（Row）** | 一行数据（一条记录） |
| **列（Column）** | 一列数据（一个字段/属性） |
| **主键（Primary Key）** | 每行的唯一标识（如学号） |

### 2.2 一个示例表：students

```
 students 表
┌────┬──────────┬─────┬─────────────┬──────────┐
│ id │  name    │ age │    email    │  grade   │
├────┼──────────┼─────┼─────────────┼──────────┤
│ 1  │ 张三    │  20 │ zs@test.com │    85    │
│ 2  │ 李四    │  22 │ ls@test.com │    92    │
│ 3  │ 王五    │  21 │ ww@test.com │    78    │
│ 4  │ 赵六    │  23 │ zl@test.com │    88    │
│ 5  │ 孙七    │  20 │ sq@test.com │    95    │
└────┴──────────┴─────┴─────────────┴──────────┘
```

- **id 列**：主键，唯一标识每个学生
- **name 列**：字符串类型
- **age 列**：整数类型
- **email 列**：字符串类型
- **grade 列**：整数类型

### 2.3 Schema（模式）

Schema 是数据库中的逻辑分组。一个数据库可以有多个 Schema，每个 Schema 下可以有多张表。

```sql
-- 格式：database.schema.table
SELECT * FROM mydb.public.students;
```

---

## 3. SQL 语句分类

SQL 语句按功能分为四大类：

```
                   SQL
                    │
      ┌─────────────┼─────────────┐
      │             │             │
     DDL           DML           DCL
  (数据定义)    (数据操作)    (数据控制)
      │             │             │
  CREATE        SELECT         GRANT
  ALTER         INSERT         REVOKE
  DROP          UPDATE
  TRUNCATE      DELETE
                MERGE

      TCL (事务控制)
      COMMIT
      ROLLBACK
      SAVEPOINT

      DQL (数据查询) — 有时从 DML 中分离
      SELECT（查询部分）
```

| 类别 | 全称 | 作用 | 关键字 |
|------|------|------|--------|
| DDL | Data Definition Language | 定义数据库结构 | CREATE, ALTER, DROP, TRUNCATE |
| DML | Data Manipulation Language | 操作数据 | INSERT, UPDATE, DELETE, MERGE |
| DQL | Data Query Language | 查询数据 | SELECT |
| DCL | Data Control Language | 控制权限 | GRANT, REVOKE |
| TCL | Transaction Control Language | 事务控制 | COMMIT, ROLLBACK, SAVEPOINT |

---

## 4. 数据类型

### 4.1 常见数据类型总览

```
                    数据类型
                       │
        ┌──────────────┼──────────────┐
        │              │              │
      数值            字符串        日期/时间
        │              │              │
   INTEGER          CHAR           DATE
   BIGINT           VARCHAR        TIME
   SMALLINT         TEXT           TIMESTAMP
   TINYINT          CLOB           INTERVAL
   DECIMAL/NUMERIC  BLOB
   FLOAT/REAL
   DOUBLE
```

### 4.2 数值类型

```sql
-- 整数类型
INTEGER        -- 4 字节，范围：-2,147,483,648 到 2,147,483,647
BIGINT         -- 8 字节，更大范围
SMALLINT       -- 2 字节，范围：-32,768 到 32,767
TINYINT        -- 1 字节，范围：0 到 255

-- 浮点数类型
FLOAT          -- 4 字节单精度
DOUBLE         -- 8 字节双精度
REAL           -- 同 FLOAT

-- 定点数（精确小数）
DECIMAL(10, 2) -- 总共 10 位数字，其中 2 位小数
NUMERIC(10, 2) -- 同 DECIMAL
```

### 4.3 字符串类型

```sql
CHAR(10)       -- 固定长度 10 个字符（不足用空格填充）
VARCHAR(255)   -- 可变长度，最多 255 个字符
TEXT           -- 不限长度的长文本
```

> **CHAR vs VARCHAR**：CHAR 适合存储固定长度的数据（如身份证号），VARCHAR 适合长度可变的数据（如姓名、邮箱）。

### 4.4 日期/时间类型

```sql
DATE           -- 日期：'2025-06-09'
TIME           -- 时间：'14:30:00'
TIMESTAMP      -- 日期+时间：'2025-06-09 14:30:00'
INTERVAL       -- 时间间隔：'3 days', '2 hours'
```

### 4.5 布尔类型

```sql
BOOLEAN        -- true / false
BOOL           -- 同 BOOLEAN
```

### 4.6 其他类型

```sql
BLOB           -- 二进制大对象（图片、文件等）
UUID           -- 通用唯一标识符
JSON           -- JSON 数据（PostgreSQL、DuckDB 等支持）
ENUM           -- 枚举类型（部分数据库支持）
```

---

## 5. DDL - 数据定义语言

### 5.1 CREATE TABLE - 创建表

```sql
-- 基本语法
CREATE TABLE 表名 (
    列名1 数据类型 [约束],
    列名2 数据类型 [约束],
    ...
    [表级约束]
);

-- 示例：创建学生表
CREATE TABLE students (
    id      INTEGER PRIMARY KEY,          -- 主键
    name    VARCHAR(100) NOT NULL,         -- 非空
    age     INTEGER DEFAULT 18,            -- 默认值 18
    email   VARCHAR(200) UNIQUE,           -- 唯一约束
    grade   INTEGER CHECK (grade >= 0 AND grade <= 100),  -- 检查约束
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 5.2 ALTER TABLE - 修改表结构

```sql
-- 添加列
ALTER TABLE students ADD COLUMN phone VARCHAR(20);

-- 删除列（部分数据库支持）
ALTER TABLE students DROP COLUMN phone;

-- 修改列的数据类型
ALTER TABLE students ALTER COLUMN age TYPE BIGINT;

-- 重命名列
ALTER TABLE students RENAME COLUMN grade TO score;

-- 重命名表
ALTER TABLE students RENAME TO pupils;
```

### 5.3 DROP TABLE - 删除表

```sql
-- 删除表（不可逆！）
DROP TABLE students;

-- 安全删除（如果表存在才删除，避免报错）
DROP TABLE IF EXISTS students;
```

### 5.4 TRUNCATE TABLE - 清空表数据

```sql
-- 清空表中所有数据（保留表结构）
TRUNCATE TABLE students;
```

> **TRUNCATE vs DELETE**：TRUNCATE 更快，但不能回滚；DELETE 可以回滚（在事务中），可以有 WHERE 条件。

---

## 6. DML - 数据操作语言

### 6.1 INSERT - 插入数据

```sql
-- 插入完整的一行
INSERT INTO students (id, name, age, email, grade)
VALUES (1, '张三', 20, 'zhangsan@test.com', 85);

-- 省略列名（必须按表中列的顺序提供所有值）
INSERT INTO students
VALUES (2, '李四', 22, 'lisi@test.com', 92);

-- 只插入部分列（其余使用默认值或 NULL）
INSERT INTO students (name, email, grade)
VALUES ('王五', 'wangwu@test.com', 78);

-- 批量插入多行
INSERT INTO students (name, age, email, grade) VALUES
    ('赵六', 23, 'zhaoliu@test.com', 88),
    ('孙七', 20, 'sunqi@test.com', 95),
    ('周八', 21, 'zhouba@test.com', 73);

-- 从查询结果插入（INSERT ... SELECT）
INSERT INTO top_students (id, name, grade)
SELECT id, name, grade FROM students WHERE grade >= 90;
```

### 6.2 UPDATE - 更新数据

```sql
-- 更新所有行（危险！）
UPDATE students SET grade = 100;

-- 更新特定行（务必加 WHERE）
UPDATE students
SET grade = 90, age = 21
WHERE id = 1;

-- 基于子查询更新
UPDATE students
SET grade = grade + 5
WHERE grade < 60;

-- 多表更新（PostgreSQL / DuckDB 语法）
UPDATE students
SET grade = s.grade + bonus.points
FROM bonus
WHERE students.id = bonus.student_id;
```

### 6.3 DELETE - 删除数据

```sql
-- 删除所有行（危险！保留表结构）
DELETE FROM students;

-- 删除特定行（务必加 WHERE）
DELETE FROM students
WHERE grade < 60;

-- 基于子查询删除
DELETE FROM students
WHERE id IN (
    SELECT student_id
    FROM attendance
    WHERE absent_days > 30
);
```

### 6.4 MERGE / UPSERT - 合并操作

```sql
-- DuckDB / PostgreSQL 语法：冲突时更新
INSERT INTO students (id, name, grade)
VALUES (1, '张三', 95)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    grade = EXCLUDED.grade;

-- MySQL 语法：REPLACE INTO 或 ON DUPLICATE KEY UPDATE
```

---

## 7. DQL - 数据查询语言（基础）

### 7.1 SELECT 基本结构

```sql
SELECT [DISTINCT] 列名1, 列名2, ...
FROM 表名
[WHERE 条件]
[GROUP BY 分组列]
[HAVING 分组条件]
[ORDER BY 排序列 [ASC|DESC]]
[LIMIT 行数];
```

> **书写顺序**：SELECT → FROM → WHERE → GROUP BY → HAVING → ORDER BY → LIMIT
>
> **执行顺序**：FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
>
> 理解执行顺序比记忆书写顺序更重要！

### 7.2 基本 SELECT 示例

```sql
-- 查询所有列（* 表示全部）
SELECT * FROM students;

-- 查询特定列
SELECT name, grade FROM students;

-- 使用别名（AS 可以省略）
SELECT name AS 姓名, grade AS 成绩 FROM students;
-- 等同于
SELECT name 姓名, grade 成绩 FROM students;

-- 去重查询
SELECT DISTINCT age FROM students;         -- 所有不同年龄
SELECT DISTINCT age, grade FROM students;  -- 去重组合

-- 计算列
SELECT name, grade, grade * 1.2 AS bonus_grade FROM students;

-- 常数列
SELECT name, '中国' AS country FROM students;
```

### 7.3 查询执行过程详解

```sql
-- 考虑这条查询：
SELECT name, grade + 10 AS adjusted
FROM students
WHERE grade > 60
ORDER BY adjusted DESC
LIMIT 3;

-- 执行步骤：
-- Step 1 (FROM)：定位 students 表
-- Step 2 (WHERE)：过滤 grade > 60 的行
-- Step 3 (SELECT)：计算每行的 name 和 grade + 10
-- Step 4 (ORDER BY)：按 adjusted 降序排列
-- Step 5 (LIMIT)：取前 3 行
```

---

## 8. WHERE 子句与过滤

### 8.1 比较运算符

```sql
=           -- 等于
<> 或 !=    -- 不等于
>           -- 大于
<           -- 小于
>=          -- 大于等于
<=          -- 小于等于
```

```sql
-- 示例
SELECT * FROM students WHERE grade = 85;       -- 成绩等于 85
SELECT * FROM students WHERE grade <> 60;      -- 成绩不等于 60
SELECT * FROM students WHERE age > 20;         -- 年龄大于 20
SELECT * FROM students WHERE age BETWEEN 18 AND 22;  -- 在范围内
```

### 8.2 逻辑运算符

```sql
AND     -- 与（两个条件都满足）
OR      -- 或（任一条件满足）
NOT     -- 非（取反）
```

```sql
-- 成绩在 80 到 90 之间
SELECT * FROM students
WHERE grade >= 80 AND grade <= 90;

-- 年龄小于 20 或成绩大于 90
SELECT * FROM students
WHERE age < 20 OR grade > 90;

-- 邮箱不为空
SELECT * FROM students
WHERE email IS NOT NULL;
```

### 8.3 IN 和 NOT IN

```sql
-- 查询年龄为 18、19 或 20 的学生
SELECT * FROM students WHERE age IN (18, 19, 20);

-- 等价于
SELECT * FROM students WHERE age = 18 OR age = 19 OR age = 20;

-- 不在某个集合中
SELECT * FROM students WHERE grade NOT IN (0, 100);
```

### 8.4 BETWEEN

```sql
-- 查询成绩在 60 到 80 之间的学生（包含边界）
SELECT * FROM students WHERE grade BETWEEN 60 AND 80;

-- 等价于
SELECT * FROM students WHERE grade >= 60 AND grade <= 80;

-- 日期范围
SELECT * FROM students
WHERE created_at BETWEEN '2025-01-01' AND '2025-12-31';
```

### 8.5 LIKE - 模糊匹配

```sql
-- % 匹配零个或多个字符
-- _ 匹配恰好一个字符

SELECT * FROM students WHERE name LIKE '张%';     -- 姓张的所有人
SELECT * FROM students WHERE name LIKE '%三%';    -- 名字中包含"三"
SELECT * FROM students WHERE name LIKE '张_';     -- 姓张，且名字只有两个字
SELECT * FROM students WHERE email LIKE '%@test.com';  -- 特定邮箱域名

-- 转义特殊字符（如需要匹配 % 或 _ 本身）
SELECT * FROM products WHERE name LIKE '%100\%' ESCAPE '\';
```

### 8.6 IS NULL / IS NOT NULL

```sql
-- 查询邮箱为空的学生
SELECT * FROM students WHERE email IS NULL;

-- 查询邮箱不为空的学生
SELECT * FROM students WHERE email IS NOT NULL;

-- 注意：不能用 = NULL（结果是 NULL，不是 true/false）
```

### 8.7 运算符优先级

```
优先级从高到低：
1. () 括号
2. 算术运算符：* / + -
3. 比较运算符：= <> > < >= <=
4. NOT
5. AND
6. OR
```

```sql
-- 不好的写法（有歧义）
SELECT * FROM students WHERE age > 18 OR grade > 80 AND name LIKE '张%';

-- 推荐的写法（用括号明确意图）
SELECT * FROM students WHERE (age > 18 OR grade > 80) AND name LIKE '张%';
```

---

## 9. ORDER BY 排序与 LIMIT 限制

### 9.1 ORDER BY

```sql
-- 单列排序
SELECT * FROM students ORDER BY grade;         -- 默认升序（ASC）
SELECT * FROM students ORDER BY grade ASC;     -- 显式升序
SELECT * FROM students ORDER BY grade DESC;    -- 降序

-- 多列排序
SELECT * FROM students ORDER BY age ASC, grade DESC;
-- 先按年龄升序，年龄相同的按成绩降序

-- 按别名排序
SELECT name, grade * 1.2 AS bonus FROM students
ORDER BY bonus DESC;

-- 按列位置排序（不推荐，可读性差）
SELECT name, age, grade FROM students ORDER BY 3 DESC;
-- 按第 3 列（grade）降序
```

### 9.2 LIMIT 和 OFFSET

```sql
-- 返回前 5 行
SELECT * FROM students ORDER BY grade DESC LIMIT 5;

-- 跳过前 3 行，返回接下来的 5 行（分页查询）
SELECT * FROM students ORDER BY id LIMIT 5 OFFSET 3;
-- 等同于（部分数据库支持）
SELECT * FROM students ORDER BY id LIMIT 3, 5;

-- 分页公式：
-- 第 n 页，每页 m 条
-- OFFSET = (n - 1) * m
-- LIMIT = m
```

### 9.3 FETCH（SQL 标准语法）

```sql
-- 某些数据库的标准写法
SELECT * FROM students ORDER BY grade DESC
FETCH FIRST 5 ROWS ONLY;

-- 带偏移
SELECT * FROM students ORDER BY grade DESC
OFFSET 3 ROWS FETCH NEXT 5 ROWS ONLY;

-- 带百分比（部分数据库支持）
SELECT * FROM students ORDER BY grade DESC
FETCH FIRST 10 PERCENT ROWS ONLY;
```

---

## 10. 常用函数

### 10.1 字符串函数

```sql
-- 大小写转换
SELECT UPPER('hello');              -- 'HELLO'
SELECT LOWER('WORLD');              -- 'world'

-- 字符串长度
SELECT LENGTH('hello');             -- 5
SELECT CHAR_LENGTH('你好');          -- 2（字符数）

-- 拼接
SELECT CONCAT('Hello', ' ', 'World');  -- 'Hello World'
SELECT 'Hello' || ' ' || 'World';      -- 'Hello World'（|| 拼接）

-- 截取
SELECT SUBSTRING('Hello World', 1, 5);  -- 'Hello'（从第1位开始，取5个字符）
SELECT LEFT('Hello World', 5);          -- 'Hello'
SELECT RIGHT('Hello World', 5);         -- 'World'

-- 替换
SELECT REPLACE('Hello World', 'World', 'SQL');  -- 'Hello SQL'

-- 去除空格
SELECT TRIM('  hello  ');            -- 'hello'
SELECT LTRIM('  hello  ');           -- 'hello  '
SELECT RTRIM('  hello  ');           -- '  hello'

-- 查找位置
SELECT POSITION('World' IN 'Hello World');  -- 7

-- 正则匹配（DuckDB / PostgreSQL 支持）
SELECT name FROM students WHERE name ~ '^张';
```

### 10.2 数值函数

```sql
-- 基本运算
SELECT 10 + 5;    -- 15
SELECT 10 - 5;    -- 5
SELECT 10 * 5;    -- 50
SELECT 10 / 3;    -- 3（整数除法）
SELECT 10.0 / 3;  -- 3.3333（浮点除法）
SELECT 10 % 3;    -- 1（取余）

-- 取整
SELECT ROUND(3.14159, 2);   -- 3.14
SELECT CEIL(3.1);           -- 4（向上取整）
SELECT FLOOR(3.9);          -- 3（向下取整）

-- 绝对值
SELECT ABS(-10);            -- 10

-- 幂与开方
SELECT POWER(2, 3);         -- 8（2³）
SELECT SQRT(16);            -- 4

-- 最大/最小值
SELECT GREATEST(10, 5, 8, 12);  -- 12
SELECT LEAST(10, 5, 8, 12);     -- 5

-- 随机数
SELECT RANDOM();            -- 0 到 1 之间的随机数
```

### 10.3 日期/时间函数

```sql
-- 获取当前时间
SELECT CURRENT_DATE;        -- '2025-06-09'
SELECT CURRENT_TIME;        -- '14:30:00'
SELECT CURRENT_TIMESTAMP;   -- '2025-06-09 14:30:00.123456'
SELECT NOW();               -- 同 CURRENT_TIMESTAMP

-- 提取日期部分
SELECT EXTRACT(YEAR FROM CURRENT_DATE);     -- 2025
SELECT EXTRACT(MONTH FROM CURRENT_DATE);    -- 6
SELECT EXTRACT(DAY FROM CURRENT_DATE);      -- 9
SELECT EXTRACT(DOW FROM CURRENT_DATE);      -- 星期几（0=周日, 1=周一...）

-- 日期运算
SELECT CURRENT_DATE + INTERVAL '7 days';     -- 7 天后
SELECT CURRENT_DATE - INTERVAL '1 month';    -- 1 个月前
SELECT AGE(TIMESTAMP '2025-06-09', TIMESTAMP '2020-01-01');
-- 返回 '5 years 5 months 8 days'

-- 日期差值
SELECT DATEDIFF('day', '2025-01-01', '2025-06-09');  -- 159 天
SELECT DATEDIFF('month', '2025-01-01', '2025-06-09');  -- 5 个月

-- 日期格式化
SELECT STRFTIME(CURRENT_DATE, '%Y年%m月%d日');  -- '2025年06月09日'
```

### 10.4 类型转换函数

```sql
-- CAST 标准语法
SELECT CAST('123' AS INTEGER);          -- 123
SELECT CAST(123 AS VARCHAR);            -- '123'
SELECT CAST('2025-06-09' AS DATE);      -- 2025-06-09

-- 简写（部分数据库）
SELECT '123'::INTEGER;                  -- PostgreSQL / DuckDB 风格
SELECT CONVERT(INT, '123');             -- SQL Server 风格
```

### 10.5 NULL 处理函数

```sql
-- COALESCE：返回第一个非 NULL 的值
SELECT COALESCE(NULL, NULL, 'default');  -- 'default'
SELECT name, COALESCE(email, '无邮箱') FROM students;

-- NULLIF：如果两个值相等则返回 NULL
SELECT NULLIF(10, 10);   -- NULL
SELECT NULLIF(10, 5);    -- 10

-- IFNULL（部分数据库替代）
SELECT IFNULL(email, '无邮箱') FROM students;
```

---

## 11. 聚合查询与 GROUP BY

### 11.1 聚合函数

```sql
-- 计数
SELECT COUNT(*) FROM students;              -- 总行数（包括 NULL）
SELECT COUNT(email) FROM students;          -- email 非 NULL 的行数
SELECT COUNT(DISTINCT age) FROM students;   -- 不同年龄的个数

-- 求和
SELECT SUM(grade) FROM students;            -- 所有成绩之和

-- 平均值
SELECT AVG(grade) FROM students;            -- 平均成绩

-- 最大/最小值
SELECT MAX(grade) FROM students;            -- 最高分
SELECT MIN(grade) FROM students;            -- 最低分

-- 标准差和方差
SELECT STDDEV(grade) FROM students;         -- 标准差
SELECT VARIANCE(grade) FROM students;       -- 方差
```

### 11.2 GROUP BY - 分组聚合

```sql
-- 按班级统计平均分
SELECT class_id, AVG(grade) AS avg_grade
FROM students
GROUP BY class_id;

-- 按年龄和班级统计人数
SELECT age, class_id, COUNT(*) AS count
FROM students
GROUP BY age, class_id;

-- 多聚合函数同时使用
SELECT
    class_id,
    COUNT(*) AS student_count,
    AVG(grade) AS avg_grade,
    MAX(grade) AS max_grade,
    MIN(grade) AS min_grade
FROM students
GROUP BY class_id;
```

### 11.3 HAVING - 过滤分组结果

```sql
-- WHERE 过滤行，HAVING 过滤分组
-- 执行顺序：WHERE → GROUP BY → HAVING

-- 找出平均分大于 80 的班级
SELECT
    class_id,
    AVG(grade) AS avg_grade
FROM students
GROUP BY class_id
HAVING AVG(grade) > 80;

-- WHERE 和 HAVING 同时使用
SELECT
    class_id,
    AVG(grade) AS avg_grade
FROM students
WHERE grade > 60       -- 先过滤无效成绩
GROUP BY class_id
HAVING AVG(grade) > 80 -- 再过滤分组结果
ORDER BY avg_grade DESC;
```

### 11.4 GROUP BY 的扩展（DuckDB / PostgreSQL）

```sql
-- ROLLUP：小计汇总
SELECT
    COALESCE(city, '所有城市') AS city,
    COALESCE(class_id, 0) AS class_id,
    COUNT(*) AS count
FROM students
GROUP BY ROLLUP(city, class_id);

-- CUBE：所有维度组合
SELECT city, class_id, COUNT(*)
FROM students
GROUP BY CUBE(city, class_id);

-- GROUPING SETS：指定具体维度组合
SELECT city, class_id, COUNT(*)
FROM students
GROUP BY GROUPING SETS (
    (city, class_id),
    (city),
    ()
);
```

---

## 12. JOIN 连接查询（重点）

连接查询是 SQL 最强大的功能之一，也是面试必考内容。

### 12.1 连接的类型

```
     JOIN 类型
        │
    ┌───┴───┐
  內连接   外连接
(INNER)  (OUTER)
           │
   ┌───────┼───────┐
  LEFT   RIGHT   FULL
 JOIN   JOIN    JOIN
```

### 12.2 示例数据

```sql
-- 班级表
CREATE TABLE classes (
    id INT PRIMARY KEY,
    name VARCHAR(50)
);
-- classes: (1, '一班'), (2, '二班'), (3, '三班')

-- 学生表（class_id 是外键）
CREATE TABLE students (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    class_id INT
);
-- students: (1,'张三',1), (2,'李四',1), (3,'王五',2), (4,'赵六',NULL)
-- 注：赵六没有班级
```

### 12.3 INNER JOIN（内连接）

返回两个表中**匹配**的行。

```sql
-- 显式写法（推荐）
SELECT s.name AS student, c.name AS class
FROM students s
INNER JOIN classes c ON s.class_id = c.id;

-- 结果：
-- 张三 | 一班
-- 李四 | 一班
-- 王五 | 二班
-- （赵六没有匹配班级，不出现在结果中）
-- （三班没有学生，不出现）

-- 隐式写法（不推荐，可读性差）
SELECT s.name, c.name
FROM students s, classes c
WHERE s.class_id = c.id;
```

```
        classes                    students
    ┌─────┬────────┐         ┌─────┬────────┬──────────┐
    │ id  │  name  │         │ id  │  name  │ class_id │
    ├─────┼────────┤         ├─────┼────────┼──────────┤
    │  1  │  一班  │◄────────│  1  │  张三  │    1     │
    │     │        │◄────────│  2  │  李四  │    1     │
    │  2  │  二班  │◄────────│  3  │  王五  │    2     │
    │  3  │  三班  │         │  4  │  赵六  │  NULL    │
    └─────┴────────┘         └─────┴────────┴──────────┘

    INNER JOIN 结果：
    ┌────────┬────────┐
    │ 张三   │ 一班   │
    │ 李四   │ 一班   │
    │ 王五   │ 二班   │
    └────────┴────────┘
```

### 12.4 LEFT JOIN（左外连接）

返回**左表全部行** + 右表匹配的行（无匹配则填 NULL）。

```sql
SELECT s.name AS student, c.name AS class
FROM students s
LEFT JOIN classes c ON s.class_id = c.id;

-- 结果：
-- 张三 | 一班
-- 李四 | 一班
-- 王五 | 二班
-- 赵六 | NULL     ← 保留了左表（students）所有行
```

### 12.5 RIGHT JOIN（右外连接）

返回**右表全部行** + 左表匹配的行（无匹配则填 NULL）。

```sql
SELECT s.name AS student, c.name AS class
FROM students s
RIGHT JOIN classes c ON s.class_id = c.id;

-- 结果：
-- 张三 | 一班
-- 李四 | 一班
-- 王五 | 二班
-- NULL | 三班     ← 保留了右表（classes）所有行
```

### 12.6 FULL OUTER JOIN（全外连接）

返回两表**所有行**（左有右没有的填 NULL，右有左没有的也填 NULL）。

```sql
SELECT s.name AS student, c.name AS class
FROM students s
FULL OUTER JOIN classes c ON s.class_id = c.id;

-- 结果：
-- 张三 | 一班
-- 李四 | 一班
-- 王五 | 二班
-- 赵六 | NULL     ← 左有右没有
-- NULL | 三班     ← 右有左没有
```

### 12.7 CROSS JOIN（交叉连接）

返回两表的**笛卡尔积**（左表每一行 × 右表每一行）。

```sql
SELECT s.name, c.name
FROM students s
CROSS JOIN classes c;

-- 4 个学生 × 3 个班级 = 12 行结果
-- 通常不直接用，而是配合条件过滤
```

### 12.8 SELF JOIN（自连接）

表与自身连接，常用于层级数据。

```sql
-- 员工表（包含上级 ID）
CREATE TABLE employees (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    manager_id INT
);

-- 查询每个员工及其上级的名字
SELECT
    e.name AS employee,
    m.name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.id;
```

### 12.9 JOIN 执行过程理解

```sql
-- 三表连接
SELECT
    s.name,
    c.name AS class,
    t.name AS teacher
FROM students s
INNER JOIN classes c ON s.class_id = c.id
LEFT JOIN teachers t ON c.teacher_id = t.id;
```

```
执行流程（概念上）：
1. students INNER JOIN classes ON class_id → 临时结果 R1
2. R1 LEFT JOIN teachers ON teacher_id → 最终结果

实际上数据库优化器会重排 JOIN 顺序以达到最优性能。
```

### 12.10 JOIN 常见陷阱

```sql
-- ❌ 错误：LEFT JOIN 后在 WHERE 中过滤右表列，退化为 INNER JOIN
SELECT s.name, c.name
FROM students s
LEFT JOIN classes c ON s.class_id = c.id
WHERE c.name = '一班';  -- 会排除 c.name 为 NULL 的行！

-- ✅ 正确：应该把条件放在 ON 中
SELECT s.name, c.name
FROM students s
LEFT JOIN classes c ON s.class_id = c.id AND c.name = '一班';
```

---

## 13. 子查询（Subquery）

子查询是嵌套在另一个查询中的查询。SQL 的灵魂之一。

### 13.1 标量子查询（返回单个值）

```sql
-- 查询成绩超过平均分的学生
SELECT name, grade
FROM students
WHERE grade > (SELECT AVG(grade) FROM students);

-- 查询与张三同班的学生
SELECT name
FROM students
WHERE class_id = (
    SELECT class_id FROM students WHERE name = '张三'
);
```

### 13.2 行子查询（返回单行多列）

```sql
-- 查询与张三同班同岁的学生
SELECT name
FROM students
WHERE (class_id, age) = (
    SELECT class_id, age FROM students WHERE name = '张三'
);
```

### 13.3 列子查询（返回单列多行）

配合 IN, ANY/SOME, ALL 使用：

```sql
-- IN：值在子查询结果中
SELECT name FROM students
WHERE class_id IN (
    SELECT id FROM classes WHERE grade_level = '高一'
);

-- ANY/SOME：满足子查询结果中的任意一个条件
SELECT name, grade FROM students
WHERE grade > ANY (
    SELECT grade FROM students WHERE class_id = 1
);
-- grade 大于班级 1 中任意一个学生的成绩

-- ALL：满足子查询结果中的所有条件
SELECT name, grade FROM students
WHERE grade > ALL (
    SELECT grade FROM students WHERE class_id = 1
);
-- grade 大于班级 1 中所有学生的成绩（即大于最高分）

-- EXISTS：子查询结果存在
SELECT c.name
FROM classes c
WHERE EXISTS (
    SELECT 1 FROM students s WHERE s.class_id = c.id
);
-- 查询有学生的班级

-- NOT EXISTS：子查询结果不存在
SELECT c.name
FROM classes c
WHERE NOT EXISTS (
    SELECT 1 FROM students s WHERE s.class_id = c.id
);
-- 查询没有学生的班级
```

### 13.4 派生表（FROM 子句中的子查询）

```sql
-- 将子查询结果作为临时表使用
SELECT class_avg.class_id, class_avg.avg_grade
FROM (
    SELECT class_id, AVG(grade) AS avg_grade
    FROM students
    GROUP BY class_id
) AS class_avg
WHERE class_avg.avg_grade > 80;
```

### 13.5 关联子查询（Correlated Subquery）

内部查询引用外部查询的列。

```sql
-- 查询每个班级中成绩最高的学生
SELECT name, class_id, grade
FROM students s1
WHERE grade = (
    SELECT MAX(grade)
    FROM students s2
    WHERE s2.class_id = s1.class_id  -- 引用外部 s1.class_id
);

-- 查询比同班平均分高的学生
SELECT name, class_id, grade
FROM students s1
WHERE grade > (
    SELECT AVG(grade)
    FROM students s2
    WHERE s2.class_id = s1.class_id
);
```

> ⚠️ 关联子查询每处理外部一行就要执行一次内部查询，性能可能较差。窗口函数（见第 16 章）通常是更好的选择。

### 13.6 子查询位置总结

```sql
-- 1. SELECT 中（必须是标量子查询）
SELECT name, grade, (SELECT AVG(grade) FROM students) AS overall_avg
FROM students;

-- 2. FROM 中（派生表，必须有别名）
SELECT * FROM (SELECT * FROM students WHERE grade > 80) AS good_students;

-- 3. WHERE 中
SELECT * FROM students WHERE grade > (SELECT AVG(grade) FROM students);

-- 4. HAVING 中
SELECT class_id, AVG(grade)
FROM students
GROUP BY class_id
HAVING AVG(grade) > (SELECT AVG(grade) FROM students);

-- 5. JOIN 中
SELECT s.name, a.avg_grade
FROM students s
JOIN (SELECT class_id, AVG(grade) AS avg_grade FROM students GROUP BY class_id) a
ON s.class_id = a.class_id;
```

---

## 14. 集合运算（UNION / INTERSECT / EXCEPT）

集合运算用于组合多个 SELECT 的结果。

```sql
-- 两个查询必须有相同的列数和兼容的数据类型
SELECT name, grade FROM students_2024
UNION
SELECT name, grade FROM students_2025;
```

### 14.1 UNION（并集）

```sql
-- UNION：合并结果，自动去重
SELECT name FROM students_in_class1
UNION
SELECT name FROM students_in_class2;

-- UNION ALL：合并结果，不去重（更快）
SELECT name FROM students_in_class1
UNION ALL
SELECT name FROM students_in_class2;
```

### 14.2 INTERSECT（交集）

```sql
-- 找出同时存在于两个集合中的行
SELECT name FROM students_in_class1
INTERSECT
SELECT name FROM students_in_class2;
```

### 14.3 EXCEPT（差集）

```sql
-- 找出在第一个查询有但第二个查询没有的行
SELECT name FROM students_in_class1
EXCEPT
SELECT name FROM students_in_class2;
```

### 14.4 集合运算与排序

```sql
-- ORDER BY 只能出现在最后一个查询之后
(
    SELECT name, '一班' AS class FROM class1_students
    UNION ALL
    SELECT name, '二班' AS class FROM class2_students
)
ORDER BY name;

-- 各子查询内部不能用 ORDER BY（除非配合 LIMIT）
```

---

## 15. CASE 表达式

CASE 表达式是 SQL 中的"if-else"，可以在 SELECT、WHERE、ORDER BY 等位置使用。

### 15.1 简单 CASE

```sql
SELECT name, grade,
    CASE grade
        WHEN 90 THEN 'A+'
        WHEN 80 THEN 'A'
        WHEN 70 THEN 'B'
        WHEN 60 THEN 'C'
        ELSE 'F'
    END AS letter_grade
FROM students;
```

### 15.2 搜索 CASE（更常用）

```sql
SELECT name, grade,
    CASE
        WHEN grade >= 90 THEN '优秀'
        WHEN grade >= 80 THEN '良好'
        WHEN grade >= 70 THEN '中等'
        WHEN grade >= 60 THEN '及格'
        ELSE '不及格'
    END AS grade_level
FROM students;
```

### 15.3 CASE 的各种用法

```sql
-- 在 WHERE 中使用（配合复杂条件）
SELECT * FROM students
WHERE CASE
    WHEN class_id = 1 THEN grade > 80
    WHEN class_id = 2 THEN grade > 70
    ELSE grade > 60
END;

-- 在 ORDER BY 中使用（自定义排序）
SELECT name, grade
FROM students
ORDER BY CASE
    WHEN grade >= 90 THEN 1
    WHEN grade >= 80 THEN 2
    WHEN grade >= 70 THEN 3
    ELSE 4
END;

-- 在 GROUP BY 中使用
SELECT
    CASE
        WHEN grade >= 90 THEN '优秀'
        WHEN grade >= 60 THEN '及格'
        ELSE '不及格'
    END AS level,
    COUNT(*) AS count
FROM students
GROUP BY 1;

-- 在聚合函数中使用
SELECT
    AVG(CASE WHEN gender = '男' THEN grade END) AS male_avg,
    AVG(CASE WHEN gender = '女' THEN grade END) AS female_avg
FROM students;
```

---

## 16. 窗口函数（Window Functions）

窗口函数是 SQL 中最重要的高级特性之一。它允许在"窗口"（一组相关的行）上执行计算，**不会减少行数**（与 GROUP BY 不同）。

### 16.1 窗口函数基本语法

```sql
函数名(参数) OVER (
    [PARTITION BY 列名]    -- 分组定义
    [ORDER BY 列名]        -- 排序定义
    [ROWS/RANGE 子句]      -- 窗口大小
)
```

### 16.2 排名函数

```sql
-- ROW_NUMBER()：连续编号（即使值相同也不并列）
SELECT name, grade,
    ROW_NUMBER() OVER (ORDER BY grade DESC) AS row_num
FROM students;

-- RANK()：有并列，跳号（1, 2, 2, 4...）
SELECT name, grade,
    RANK() OVER (ORDER BY grade DESC) AS rank
FROM students;

-- DENSE_RANK()：有并列，不跳号（1, 2, 2, 3...）
SELECT name, grade,
    DENSE_RANK() OVER (ORDER BY grade DESC) AS dense_rank
FROM students;

-- NTILE(n)：将行分成 n 组，返回组号
SELECT name, grade,
    NTILE(4) OVER (ORDER BY grade DESC) AS quartile
FROM students;
```

```
原始数据（按 grade DESC）：张三(95), 李四(95), 王五(88), 赵六(85), 孙七(85)

ROW_NUMBER(): 1, 2, 3, 4, 5    ← 连续编号
RANK():       1, 1, 3, 4, 4    ← 并列跳号
DENSE_RANK(): 1, 1, 2, 3, 3    ← 并列不跳号
NTILE(3):     1, 1, 2, 2, 3    ← 尽量均分
```

### 16.3 偏移函数

```sql
-- LAG(列, 偏移量, 默认值)：取前一行
SELECT name, grade,
    LAG(grade, 1) OVER (ORDER BY grade) AS prev_grade,
    LAG(grade, 2) OVER (ORDER BY grade) AS prev2_grade
FROM students;

-- LEAD(列, 偏移量, 默认值)：取后一行
SELECT name, grade,
    LEAD(grade, 1) OVER (ORDER BY grade) AS next_grade
FROM students;

-- FIRST_VALUE / LAST_VALUE：窗口的第一个/最后一个值
SELECT name, grade,
    FIRST_VALUE(grade) OVER (ORDER BY grade) AS min_grade,
    LAST_VALUE(grade) OVER (
        ORDER BY grade
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS max_grade
FROM students;

-- NTH_VALUE：窗口中的第 n 个值
SELECT name, grade,
    NTH_VALUE(grade, 2) OVER (ORDER BY grade) AS second_lowest
FROM students;
```

### 16.4 聚合窗口函数

```sql
-- 在窗口上使用聚合函数
SELECT
    name,
    class_id,
    grade,
    AVG(grade) OVER (PARTITION BY class_id) AS class_avg,
    grade - AVG(grade) OVER (PARTITION BY class_id) AS diff_from_avg,
    SUM(grade) OVER (PARTITION BY class_id ORDER BY grade) AS running_total
FROM students;
```

### 16.5 PARTITION BY 详解

```sql
-- PARTITION BY 将数据分成多个窗口
-- 没有 PARTITION BY：整个结果集是一个窗口
SELECT name, grade,
    AVG(grade) OVER () AS overall_avg
FROM students;

-- 有 PARTITION BY：按类分组窗口
SELECT name, class_id, grade,
    AVG(grade) OVER (PARTITION BY class_id) AS class_avg,
    RANK() OVER (PARTITION BY class_id ORDER BY grade DESC) AS class_rank
FROM students;
```

### 16.6 窗口大小控制（FRAME 子句）

```sql
-- ROWS BETWEEN：按物理行定义窗口
SELECT name, grade,
    SUM(grade) OVER (
        ORDER BY grade
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_sum
FROM students;

-- 常用模式：
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW      -- 累积（从开头到当前）
ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING                -- 滚动（前1+当前+后1）
ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING -- 全窗口
ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING        -- 从当前到尾

-- RANGE BETWEEN：按逻辑值定义窗口（ORDER BY 值相同的行视为一组）
SELECT name, grade,
    AVG(grade) OVER (
        ORDER BY grade
        RANGE BETWEEN 5 PRECEDING AND 5 FOLLOWING
    ) AS nearby_avg
FROM students;
```

### 16.7 常见业务场景

```sql
-- 每个班级成绩 Top 3
SELECT * FROM (
    SELECT name, class_id, grade,
        RANK() OVER (PARTITION BY class_id ORDER BY grade DESC) AS rn
    FROM students
) WHERE rn <= 3;

-- 计算环比（与上期对比）
SELECT month, revenue,
    LAG(revenue) OVER (ORDER BY month) AS prev_month,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY month)) * 100.0 /
        LAG(revenue) OVER (ORDER BY month), 2) AS growth_pct
FROM monthly_revenue;

-- 去除重复数据（保留每组最新的一条）
DELETE FROM students
WHERE id NOT IN (
    SELECT id FROM (
        SELECT id,
            ROW_NUMBER() OVER (PARTITION BY name, class_id ORDER BY created_at DESC) AS rn
        FROM students
    ) WHERE rn = 1
);
```

---

## 17. CTE（公用表表达式）

CTE（Common Table Expression）让复杂查询更容易理解和维护。

### 17.1 基本 CTE 语法

```sql
-- 基本语法
WITH cte_name AS (
    SELECT ...  -- CTE 查询
)
SELECT ... FROM cte_name ...;  -- 主查询
```

### 17.2 单个 CTE

```sql
-- 将子查询提取为 CTE，提高可读性
WITH class_avg AS (
    SELECT class_id, AVG(grade) AS avg_grade
    FROM students
    GROUP BY class_id
)
SELECT s.name, s.grade, a.avg_grade
FROM students s
JOIN class_avg a ON s.class_id = a.class_id
WHERE s.grade > a.avg_grade;
```

### 17.3 多个 CTE

```sql
-- 链式使用多个 CTE
WITH
class_stats AS (
    -- 第一步：班级统计
    SELECT class_id,
           COUNT(*) AS student_count,
           AVG(grade) AS avg_grade
    FROM students
    GROUP BY class_id
),
top_classes AS (
    -- 第二步：筛选优秀班级
    SELECT * FROM class_stats
    WHERE avg_grade > 80
)
-- 第三步：最终查询
SELECT s.name, s.grade, t.avg_grade
FROM students s
JOIN top_classes t ON s.class_id = t.class_id
WHERE s.grade > t.avg_grade;
```

### 17.4 递归 CTE

递归 CTE 用于处理树状结构或生成序列：

```sql
-- 生成 1 到 100 的序列
WITH RECURSIVE numbers(n) AS (
    SELECT 1                           -- 初始行
    UNION ALL
    SELECT n + 1 FROM numbers WHERE n < 100  -- 递归部分
)
SELECT * FROM numbers;

-- 查询组织层级（员工 → 上级 → 上级的上级...）
WITH RECURSIVE org_hierarchy AS (
    -- 基础：顶层管理者（没有上级的人）
    SELECT id, name, manager_id, 1 AS level
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- 递归：下级员工
    SELECT e.id, e.name, e.manager_id, h.level + 1
    FROM employees e
    JOIN org_hierarchy h ON e.manager_id = h.id
)
SELECT * FROM org_hierarchy ORDER BY level, id;
```

### 17.5 CTE vs 子查询 vs 临时表

| 特性 | 子查询 | CTE | 临时表 |
|------|--------|-----|--------|
| 可读性 | 嵌套越多越差 | 好 | 好 |
| 复用性 | 不能复用 | 可在主查询多次引用 | 可多次引用 |
| 执行计划 | 可能合并优化 | 可能合并优化 | 物化到磁盘 |
| 递归 | 不支持 | 支持 | 不支持 |

---

## 18. 约束（Constraints）

约束是数据完整性的保障，确保数据的准确性和可靠性。

### 18.1 约束类型总览

```sql
CREATE TABLE students (
    id INT PRIMARY KEY,                               -- 主键约束
    name VARCHAR(100) NOT NULL,                        -- 非空约束
    email VARCHAR(200) UNIQUE,                         -- 唯一约束
    age INT DEFAULT 18,                                -- 默认值
    grade INT CHECK (grade >= 0 AND grade <= 100),     -- 检查约束
    class_id INT REFERENCES classes(id)                -- 外键约束
);
```

### 18.2 PRIMARY KEY（主键）

```sql
-- 单列主键
CREATE TABLE students (
    id INT PRIMARY KEY,
    name VARCHAR(100)
);

-- 复合主键（多列组合唯一）
CREATE TABLE enrollments (
    student_id INT,
    course_id INT,
    enrolled_at DATE,
    PRIMARY KEY (student_id, course_id)  -- 一个学生不能重复选同一门课
);

-- 自增主键
-- DuckDB: INTEGER PRIMARY KEY 默认自增
-- PostgreSQL: SERIAL 或 GENERATED ALWAYS AS IDENTITY
-- MySQL: AUTO_INCREMENT
```

### 18.3 FOREIGN KEY（外键）

外键确保引用完整性：子表的某个值必须在父表中存在。

```sql
CREATE TABLE orders (
    id INT PRIMARY KEY,
    customer_id INT,
    amount DECIMAL(10,2),
    FOREIGN KEY (customer_id) REFERENCES customers(id)
    ON DELETE CASCADE      -- 客户被删除时，其订单也被级联删除
    ON UPDATE CASCADE      -- 客户 ID 更新时，订单的 customer_id 同步更新
);

-- 外键行为选项：
-- CASCADE：级联操作
-- SET NULL：设置为 NULL
-- SET DEFAULT：设置为默认值
-- RESTRICT：禁止操作（默认）
-- NO ACTION：同 RESTRICT
```

### 18.4 CHECK（检查约束）

```sql
-- 列级 CHECK
CREATE TABLE products (
    id INT PRIMARY KEY,
    price DECIMAL(10,2) CHECK (price > 0),
    stock INT CHECK (stock >= 0)
);

-- 表级 CHECK（涉及多列）
CREATE TABLE employees (
    id INT PRIMARY KEY,
    start_date DATE,
    end_date DATE,
    CHECK (end_date IS NULL OR end_date > start_date)
);
```

### 18.5 UNIQUE（唯一约束）

```sql
-- 单列唯一
CREATE TABLE users (
    id INT PRIMARY KEY,
    email VARCHAR(200) UNIQUE,
    phone VARCHAR(20) UNIQUE
);

-- 组合唯一（两个列的组合不能重复）
CREATE TABLE enrollments (
    student_id INT,
    course_id INT,
    UNIQUE (student_id, course_id)
);
```

> **UNIQUE vs PRIMARY KEY**：
> - PRIMARY KEY 不能为 NULL，一张表只能有一个
> - UNIQUE 允许 NULL，一张表可以有多个
> - 两者都会自动创建索引

### 18.6 NOT NULL 和 DEFAULT

```sql
CREATE TABLE articles (
    id INT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,                     -- 必须有标题
    content TEXT NOT NULL DEFAULT '',                 -- 默认空字符串
    author VARCHAR(100) DEFAULT '匿名',
    published_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- 默认当前时间
    views INT DEFAULT 0
);
```

### 18.7 修改约束

```sql
-- 添加约束
ALTER TABLE students ADD CONSTRAINT unique_email UNIQUE (email);
ALTER TABLE students ADD CONSTRAINT check_grade CHECK (grade BETWEEN 0 AND 100);
ALTER TABLE students ADD CONSTRAINT fk_class FOREIGN KEY (class_id) REFERENCES classes(id);

-- 删除约束
ALTER TABLE students DROP CONSTRAINT unique_email;
```

---

## 19. 索引（Index）

索引就像书的目录，帮助你快速定位数据，而不需要"翻完整本书"。

### 19.1 基本概念

```
没有索引（全表扫描）：
[行1] [行2] [行3] ... [行1000000] → 依次检查每一行 → 慢！

有索引（B-Tree 结构）：
        [50]
       /    \
    [25]    [75]
   /    \  /    \
 [12] [37] [62] [87]  → 二分查找 → O(log n) → 快！
```

### 19.2 创建索引

```sql
-- 单列索引
CREATE INDEX idx_students_name ON students(name);

-- 复合索引（多列索引）
CREATE INDEX idx_students_class_grade ON students(class_id, grade);

-- 唯一索引（确保列值唯一）
CREATE UNIQUE INDEX idx_students_email ON students(email);

-- 在创建表时定义索引
CREATE TABLE students (
    id INT PRIMARY KEY,            -- 主键自动创建索引
    name VARCHAR(100),
    email VARCHAR(200),
    INDEX idx_name (name)          -- 创建时指定（部分数据库）
);
```

### 19.3 索引使用原则

```
✅ 适合创建索引的列：
  - WHERE 子句经常使用的列
  - JOIN 连接条件中的列
  - ORDER BY / GROUP BY 列
  - 外键列
  - 区分度高的列（值很分散，如邮箱）

❌ 不适合创建索引的列：
  - 很少被查询的列
  - 经常被更新的列（维护索引有成本）
  - 区分度低的列（如性别、布尔值）
  - 小表（全表扫描可能更快）
```

### 19.4 复合索引的最左前缀原则

```sql
-- 创建复合索引
CREATE INDEX idx_a_b_c ON table_name(a, b, c);

-- 能用到索引的查询（从最左列开始匹配）
WHERE a = 1                    ✅ 用到 a
WHERE a = 1 AND b = 2          ✅ 用到 a, b
WHERE a = 1 AND b = 2 AND c = 3 ✅ 用到 a, b, c
WHERE a = 1 AND c = 3          ✅ 用到 a（但 c 没用上）
WHERE b = 2                    ❌ 没用上（跳过了最左列 a）
WHERE c = 3                    ❌ 没用上
```

### 19.5 索引操作

```sql
-- 查看索引（DuckDB）
SELECT * FROM duckdb_indexes();

-- 查看查询是否使用索引
EXPLAIN SELECT * FROM students WHERE name = '张三';

-- 删除索引
DROP INDEX idx_students_name;
```

---

## 20. 视图（View）

视图是"虚拟表"，存储的是查询定义，不是数据本身。

### 20.1 创建和使用视图

```sql
-- 创建视图
CREATE VIEW top_students AS
SELECT name, grade, class_id
FROM students
WHERE grade >= 90;

-- 使用视图（像普通表一样）
SELECT * FROM top_students;
SELECT class_id, COUNT(*) FROM top_students GROUP BY class_id;

-- 视图可以基于其他视图
CREATE VIEW top_classes AS
SELECT class_id, COUNT(*) AS top_count
FROM top_students
GROUP BY class_id
HAVING COUNT(*) > 5;

-- 创建或替换视图
CREATE OR REPLACE VIEW top_students AS
SELECT name, grade, class_id, age
FROM students
WHERE grade >= 85;
```

### 20.2 删除视图

```sql
DROP VIEW top_students;
DROP VIEW IF EXISTS top_students;
```

### 20.3 视图的用途

```
- 简化复杂查询：将复杂的 JOIN 查询封装成视图
- 安全控制：隐藏敏感列（不暴露密码、薪资等）
- 向后兼容：底层表结构改变，视图保持接口不变
- 数据聚合：预定义统计查询
```

### 20.4 物化视图（Materialized View）

与普通视图不同，物化视图将结果**物理存储**，适合复杂且不频繁更新的查询。

```sql
-- 创建物化视图（DuckDB 不直接支持，但可用其他方式）
-- PostgreSQL 语法：
CREATE MATERIALIZED VIEW class_summary AS
SELECT class_id, COUNT(*) AS cnt, AVG(grade) AS avg_g
FROM students
GROUP BY class_id;

-- 刷新数据
REFRESH MATERIALIZED VIEW class_summary;
```

> DuckDB 暂不支持 CREATE MATERIALIZED VIEW，但可以通过 CREATE TABLE AS 实现类似效果。

---

## 21. 事务（Transaction）

事务是一组要么全部成功、要么全部失败的操作（原子性）。

### 21.1 ACID 特性

| 特性 | 说明 |
|------|------|
| **A**tomicity（原子性） | 事务是一个不可分割的整体 |
| **C**onsistency（一致性） | 事务前后数据处于一致状态 |
| **I**solation（隔离性） | 并发事务互不干扰 |
| **D**urability（持久性） | 提交后数据永久保存 |

### 21.2 基本事务操作

```sql
-- 开始事务
BEGIN;
-- 或
START TRANSACTION;

-- 执行操作
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;

-- 提交（确认所有操作）
COMMIT;

-- 回滚（撤销所有操作）
ROLLBACK;

-- 保存点（部分回滚）
SAVEPOINT my_savepoint;
UPDATE accounts SET balance = balance - 50 WHERE id = 1;
ROLLBACK TO my_savepoint;  -- 撤销到保存点
COMMIT;
```

### 21.3 事务示例：银行转账

```sql
-- 张三给李四转账 500 元
BEGIN;

-- 检查张三余额
SELECT balance FROM accounts WHERE id = 1;
-- 假设余额 1000

-- 扣款
UPDATE accounts SET balance = balance - 500 WHERE id = 1;

-- 模拟错误（此时如果系统崩溃...）
-- 李四还没收到钱！

-- 入账
UPDATE accounts SET balance = balance + 500 WHERE id = 2;

-- 确认
COMMIT;
-- 事务保证了：要么两步都成功，要么两步都回滚
```

### 21.4 隔离级别

```sql
-- 查看当前隔离级别
SHOW TRANSACTION_ISOLATION;

-- 设置隔离级别
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- 常见隔离级别（从低到高）：
-- READ UNCOMMITTED：脏读   - 读到未提交的数据
-- READ COMMITTED：  不可重复读 - 同一事务两次读取结果不同（默认）
-- REPEATABLE READ： 幻读     - 同一查询返回不同行数
-- SERIALIZABLE：   最高隔离  - 事务完全串行执行
```

> DuckDB 支持 READ COMMITTED 和 REPEATABLE READ 隔离级别。

---

## 22. 最佳实践与常见错误

### 22.1 SQL 书写规范

```sql
-- ✅ 推荐：关键字大写，缩进清晰
SELECT
    s.name,
    s.grade,
    c.name AS class_name
FROM students s
INNER JOIN classes c ON s.class_id = c.id
WHERE s.grade >= 60
    AND s.created_at >= '2025-01-01'
ORDER BY s.grade DESC
LIMIT 10;

-- ❌ 不推荐：全小写，无缩进，一行到底
select s.name,s.grade,c.name from students s join classes c on s.class_id=c.id where s.grade>=60 and s.created_at>='2025-01-01' order by s.grade desc limit 10;
```

### 22.2 常见错误

```sql
-- 1. 忘记 WHERE 导致的灾难性更新/删除
-- ❌ UPDATE students SET grade = 0;   -- 所有成绩变 0！
-- ✅ UPDATE students SET grade = 0 WHERE id = 1;

-- 2. 在 WHERE 中对列使用函数（破坏索引使用）
-- ❌ SELECT * FROM students WHERE UPPER(name) = '张三';
-- ✅ SELECT * FROM students WHERE name = '张三';

-- 3. 隐式类型转换
-- ❌ SELECT * FROM students WHERE id = '1';  -- id 是 INT
-- ✅ SELECT * FROM students WHERE id = 1;

-- 4. NULL 比较陷阱
-- ❌ SELECT * FROM students WHERE email = NULL;     -- 永远返回空！
-- ✅ SELECT * FROM students WHERE email IS NULL;

-- 5. SELECT * 的滥用
-- ❌ SELECT * FROM students;  -- 生产环境可能返回很多不必要的数据
-- ✅ SELECT name, grade FROM students;

-- 6. 在 LEFT JOIN 的 WHERE 中过滤右表
-- ❌ 见第 12.10 节

-- 7. GROUP BY 和 SELECT 不匹配
-- ❌ SELECT name, AVG(grade) FROM students GROUP BY class_id;
-- 上面语句在多数数据库中会报错，因为 name 没在 GROUP BY 中
```

### 22.3 性能优化建议

```
1. 只查询需要的列，避免 SELECT *
2. 用 EXISTS 替代 IN（对于大表子查询）
3. 合理创建索引，但不要过度索引
4. 避免在 WHERE 中对列使用函数
5. 用小结果集驱动大结果集（EXPLAIN 分析执行计划）
6. 能一次查询完成的事不要分多次
7. 批处理代替逐行处理
```

### 22.4 学习路线建议

```
Phase 1: 基础查询
  └─ SELECT, WHERE, ORDER BY, LIMIT

Phase 2: 数据操作
  └─ INSERT, UPDATE, DELETE
  └─ CREATE TABLE, ALTER TABLE

Phase 3: 高级查询
  └─ JOIN（重点掌握 INNER 和 LEFT JOIN）
  └─ GROUP BY + 聚合函数
  └─ 子查询

Phase 4: 进阶特性
  └─ 窗口函数
  └─ CTE
  └─ 索引

Phase 5: 实战
  └─ 用 DuckDB 做数据分析项目
  └─ 读开源项目的 SQL 代码
  └─ 在 LeetCode / HackerRank 上练习 SQL 题
```

---

## 附录 A：快速参考卡片

### 查询模板

```
SELECT [DISTINCT] 列1, 列2, ...
FROM 表1
[JOIN 表2 ON 条件]
[WHERE 条件]
[GROUP BY 列]
[HAVING 条件]
[ORDER BY 列 [ASC|DESC]]
[LIMIT n OFFSET m];
```

### 常用聚合函数

```
COUNT(*)    计数
SUM(列)     求和
AVG(列)     平均值
MAX(列)     最大值
MIN(列)     最小值
STDDEV(列)  标准差
```

### 连接类型

```
INNER JOIN   两表都匹配才返回
LEFT JOIN    左表全返回，右表无匹配填 NULL
RIGHT JOIN   右表全返回，左表无匹配填 NULL
FULL JOIN    两表全返回，无匹配填 NULL
CROSS JOIN   笛卡尔积
```

---

> 📌 **下一步**：有了 SQL 基础之后，推荐阅读《DuckDB 详细教程》了解这个现代化的嵌入式分析数据库，然后用它来实践本教程中的所有 SQL 示例。
