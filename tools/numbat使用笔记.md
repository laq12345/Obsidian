---
tags:
  - cli
  - tool
  - calculator
  - units
  - language
  - numbat
created: 2026-10-17
---

# numbat — 带量纲类型的科学计算语言

> 官网：<https://numbat.dev/> ｜ 文档：<https://numbat.dev/docs/> ｜ 源码：<https://github.com/sharkdp/numbat>
> Web 版：<https://numbat.dev/> （可把整个计算过程存成 URL 分享）
> 本机：`numbat 1.24.0`（`~/.cargo/bin/numbat`，用 `numbat --version` 查）
> 许可证：MIT / Apache-2.0

一句话定位：**把"物理量纲"做进静态类型系统的计算器 + 小语言**。写 `2 m + 3 s` 会在运行前直接报错，而不是给你一个悄悄算错的结果。

---

## 目录

- [[#0. 定位与选型]]
- [[#1. 安装]]
- [[#2. 三种运行模式]]
- [[#3. CLI 选项]]
- [[#4. 交互式会话（REPL）]]
- [[#5. 语言基础]]
- [[#6. 单位与量纲]]
- [[#7. 类型系统]]
- [[#8. 自定义量纲与单位]]
- [[#9. 日期与时间]]
- [[#10. 测试与调试]]
- [[#11. 标准库（prelude）]]
- [[#12. 货币与汇率]]
- [[#13. 配置与定制]]
- [[#14. 编辑器集成]]
- [[#15. 示例配方（可直接抄）]]
- [[#16. 踩坑清单]]
- [[#17. 速查表]]
- [[#18. Unicode 输入速查]]

---

## 0. 定位与选型

它是"科学计算器"和"编程语言"的混合体：

- 计算器侧：单位换算、货币、日期时间、大数、进制
- 语言侧：静态类型 + 类型推断、自定义函数 / 单位 / 量纲、列表、struct、字符串、断言测试
- 函数式 / 声明式风格（**不是** 命令式，也没有可变变量）

官方对比表（`comparison.md`，原文自认不客观）：

| 能力 | numbat | Qalculate | Kalker | GNU Units | Frink | Wolfram Alpha |
|---|---|---|---|---|---|---|
| 开源许可 | MIT/Apache | GPL-2.0 | MIT | GPL-3.0 | ❌ | ❌ |
| 命令行 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Web 版 | ✓ | ❌ | ✓ | ❌ | ❌ | ✓ |
| 图形界面 | ❌ | ✓ | ❌ | ❌ | (✓) | ✓ |
| 单位库完备 | ✓ | ✓ | ❌ | ✓ | ✓ | ✓ |
| 自定义单位 | ✓ | ✓ | ❌ | ✓ | ✓ | ❌ |
| **物理量纲（类型级）** | ✓ | ❌ | ❌ | ❌ | ❌ | ❌ |
| 货币换算 | ✓ | ✓ | ❌ | ❌ | ✓ | ✓ |
| 日期时间计算 | ✓ | ✓ | ❌ | ❌ | ✓ | ✓ |
| 自定义函数 | ✓ | ✓ | ✓ | ❌ | ✓ | ❌ |
| 真正的编程语言 | ✓ | ❌ | ❌ | ❌ | ✓ | ? |
| 强类型 | ✓ | ❌ | ❌ | ❌ | ❌ | ❌ |
| 符号计算 | ❌ | (✓) | ❌ | ❌ | (✓) | ✓ |
| 十六/八/二进制 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 复数 | ❌ | ✓ | ✓ | ❌ | ✓ | ✓ |
| 向量/矩阵 | ❌ | ✓ | ✓ | ❌ | ✓ | ✓ |

其他说明：

- 类型系统灵感来自 **F#**（F# 在类型层放的是"单位"，numbat 放的是"量纲"，且两边都有完整类型推断）。
- 数值内部统一是 **64 位浮点**（约 15–16 位有效十进制数字），大整数精确性有限，官方计划换成任意精度（issue #4）。
- 没有符号计算、复数、矩阵；`plot` 模块只是生成图形字符串，要在 Web 版里看。

---

## 1. 安装

```bash
# Arch（官方 Extra 仓库）
sudo pacman -S numbat

# Debian/Ubuntu：从 release 页下 .deb
curl -LO https://github.com/sharkdp/numbat/releases/download/v1.24.0/numbat_1.24.0_amd64.deb
sudo dpkg -i numbat_1.24.0_amd64.deb
# 或 PPA（仅 amd64）：ppa:apandada1/numbat

# macOS
brew install numbat

# Windows
scoop install main/numbat

# Void / Chimera
sudo xbps-install -S numbat
doas apk add numbat

# NixOS
nix-env -iA nixpkgs.numbat

# 源码（cargo）
cargo install numbat-cli
# 或本地开发版
git clone https://github.com/sharkdp/numbat && cd numbat && cargo install -f --path numbat-cli
```

二进制发布包里的 `modules/` 目录**不是必需的**（prelude 已编译进二进制），但装上更好：能看标准库源码、错误信息里的路径更友好、也能当自己写模块的模板。打包者可用编译期环境变量 `NUMBAT_SYSTEM_MODULE_PATH` 指定系统模块目录。

---

## 2. 三种运行模式

| 模式 | 命令 |
|---|---|
| 交互式 REPL | `numbat` |
| 运行脚本 | `numbat script.nbt` |
| 直接求值单个/多个表达式 | `numbat -e '30 km/h -> mi/h'` |

```bash
numbat                                  # 进 REPL
numbat calc.nbt                         # 跑脚本
numbat -e '30 km/h -> mph'              # => 18.6411 mph（实测，不带 "= " 前缀）
numbat -e 'let x = 1 m' -e 'x -> cm'    # -e 可重复，按顺序求值
numbat script.nbt arg1 arg2             # 脚本参数 → 脚本里用 args() 取
numbat -i script.nbt                    # 跑完脚本后进入 REPL（保留状态）
```

> [!tip] `-e` 的输出
> `-e` 会把表达式的结果打印出来；脚本里则只有 `print(...)` 会输出，裸表达式不输出。想看中间量用 `inspect(...)`。

---

## 3. CLI 选项

`numbat --help` 实测（1.24.0）：

| 选项 | 含义 |
|---|---|
| `[FILE] [SCRIPT_ARGS]...` | 脚本文件 + 传给脚本的参数（用 `args()` 读） |
| `-e, --expression <CODE>` | 求值一个表达式，可重复多次，顺序执行 |
| `-i, --inspect-interactively` | 跑完脚本/表达式后进入交互式会话 |
| `--no-config` | 不读用户配置文件 |
| `-N, --no-prelude` | 不加载 prelude（隐含 `--no-init`），此时连 `m`/`kg` 都没有 |
| `--no-init` | 不加载 `init.nbt` |
| `--pretty-print <always\|never\|auto>` | 是否在结果前打印美化后的表达式 |
| `--color <always\|never\|auto>` | 彩色输出 |
| `--intro-banner <long\|short\|off>` | 启动横幅 |
| `--generate-config` | 生成默认配置文件 |
| `-h / -V` | 帮助 / 版本 |

---

## 4. 交互式会话（REPL）

### 特殊标识符

- `ans` 或 `_`：上一次计算的结果

```numbat
>>> 60 kW h / 150 kW
    = 0.4 h
>>> ans -> minutes
    = 24 min
```

### 特殊命令（仅交互模式）

| 命令                                                | 作用                                                                                        |
| ------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `help` / `?`                                      | 基本介绍                                                                                      |
| `help commands`                                   | 所有命令的简述                                                                                   |
| `info <标识符>`                                      | 查看函数 / 变量 / 单位 / 量纲的信息（**注意：`info` 是命令，不是函数**，`numbat -e 'info x'` 会报 unknown identifier） |
| `list`                                            | 列出当前所有已定义项                                                                                |
| `list functions`/`dimensions`/`variables`/`units` | 分类列出                                                                                      |
| `save` / `save <path>`                            | 把本次会话历史存成 `.nbt`（默认 `history.nbt`）                                                        |
| `clear`                                           | 清屏（Web 版另有 `reset`，重置解释器状态并清空 URL）                                                        |
| `quit` / `exit`                                   | 退出                                                                                        |

### 快捷键

| 按键                | 作用                                        |
| ----------------- | ----------------------------------------- |
| `Tab` / `Ctrl-I`  | 自动补全 + Unicode 输入（关键！）                    |
| `Ctrl-D`          | 退出                                        |
| `Ctrl-L`          | 清屏                                        |
| `↑` / `↓`         | 历史命令                                      |
| `Ctrl-R`          | 搜索历史                                      |
| `Ctrl-C`          | 清空当前行                                     |
| `Alt-Enter`       | 插入换行（`Shift-Enter` 在 Web 版）               |
| `Home` / `Ctrl-A` | 行首；`End` / `Ctrl-E` 行尾                    |
| `Ctrl-W`          | 删除光标前一个词                                  |
| Web 版另有           | `Ctrl-←/→` 按词移动、`Ctrl-K` 删右侧、`Ctrl-U` 删左侧 |

### 补全与 Unicode

输入 `\alpha` 再按 `Tab` → `α`；`\degree<Tab>` → `°`；`\^2<Tab>` → `²`。完整对照表见 [[#18. Unicode 输入速查]]。时区名字符串也支持 `Tab` 补全（`tz("Asia/Kath…")`）。

---

## 5. 语言基础

### 5.1 注释、语句分隔、导入

```numbat
# 行注释（可连续多行）

# 语句用换行或分号分隔
1
2
1;2

use prelude          # 不必写，启动时自动加载
use units::stoney    # 按需加载模块
```

### 5.2 数字表示

```numbat
12345          # 整数
12_345         # 可用下划线分隔
0.234  .234    # 浮点（可省前导 0）
1.234e15   1.234e+15   1e-9   1.0e-9   # 科学计数
0x2A  0o52  0b101010                   # 十六/八/二进制
NaN   inf                              # 非有限数
```

进制转换：

```numbat
0xffee -> bin        # 二进制字符串
42 -> oct
2^16 - 1 -> hex
273 |> base(3)       # 任意进制
144 |> base(12)
```

> [!warning] 精度
> 内部是 64 位浮点（≈15–16 位十进制有效数字）。两个极大整数相减求"精确整数差"可能出错。

### 5.3 运算符与优先级（高 → 低）

| 运算 | 语法 |
|---|---|
| 平方 / 立方 / … | `x²`, `x³`, `x⁻¹` |
| 阶乘 | `x!`, `x!!`, `x!!!` |
| 幂 | `x^y`, `x**y` |
| 乘法（隐式） | `x y`（空格） |
| 一元负号 | `-x` |
| 除法 | `x per y` |
| 除法 | `x / y`, `x ÷ y` |
| 乘法（显式） | `x * y`, `x · y`, `x × y` |
| 减法 | `x - y` |
| 加法 | `x + y` |
| 比较 | `x < y`, `x <= y`, `x ≤ y`, … `x == y`, `x != y` |
| 逻辑非 | `!x` |
| 逻辑与 / 或 | `x && y` ／ `x \|\| y` |
| 单位转换 | `x -> y`, `x → y`, `x ➞ y`, `x to y` |
| 条件表达式 | `if x then y else z` |
| 反向函数调用 | `x \|> f` |

> [!warning] 两个反直觉的优先级
> - **隐式乘法比除法优先**：`50 cm / 2 m` 会被解析成 `50 cm / (2 m)`
> - **`per` 比 `/` 优先**：`1 / meter per second` 解析成 `1 / (meter / second)`
>
> 不确定时打开 `pretty-print`（默认 auto），它会把你输入的第二行"还原"成规范形式：
> ```numbat
> >>> 1 / meter per second
>   1 / (meter / second)
>     = 1 s/m
> ```

`|>` 是反向调用，等价于 `f(arg)`，优先级最低，**特别适合在 REPL 里按上箭头补一个 `|> 函数`**。

### 5.4 变量（`let`）

```numbat
let pipe_radius = 1 cm
let Δp: Pressure = 0.1 bar        # 可选类型标注，会被类型检查器校验
let Q: FlowRate = π × pipe_radius^4 × Δp / (8 μ_water × pipe_length)
```

> [!info] 变量不可变
> 定义后不能改值，但可以**用同名重新定义**（后面的定义遮蔽前面的，类型也可以不同）：
> ```numbat
> let numbers = "1 2 3"
> let numbers = split(numbers, " ")   # 类型从 String 变成 List<String>
> ```

### 5.5 函数（`fn`）

```numbat
# 完整写法：参数类型 + 返回类型
fn max_distance(v: Velocity, θ: Angle) -> Length = v² · sin(2 θ) / g0

# 带局部变量（where ... and ...）
fn braking_distance(v) = v t_reaction + v² / 2 µ g0
  where t_reaction = 1 s
    and µ = 0.7

# 泛型 + 类型约束（Dim = 量纲类型）
fn max<D: Dim>(a: D, b: D) -> D = if a > b then a else b

# 泛型对任意类型（无约束）
fn second_element<A>(xs: List<A>) -> A = head(tail(xs))

# 幂运算泛型，两种等价写法
fn cube_root<T>(x: T^3) -> T = x^(1/3)
fn cube_root<T>(x: T) -> T^(1/3) = x^(1/3)

# 递归
fn fib(n) = if n ≤ 2 then 1 else fib(n - 2) + fib(n - 1)
```

**类型推断**：绝大多数标注可省。上面 `braking_distance` 进 REPL 后会被自动补全为：

```numbat
fn braking_distance(v: Velocity) -> Length = v × t_reaction + (v² / (2 µ × g0))
  where t_reaction: Time = 1 second
    and µ: Scalar = 0.7
```

推断原理：`+` 要求两侧量纲相同，于是得到约束方程
`type(v) × Time = type(v)² / (1 × Length / Time²)` → `type(v) = Length / Time`。

> [!tip] 省标注 ≠ 好习惯
> 完全不写标注时，推断可能给出**过于泛型**的函数。例如 `fn kinetic_energy(mass, speed) = 1/2 * mass * speed^2` 会被推断成
> `fn kinetic_energy<A: Dim, B: Dim>(mass: A, speed: B) -> A × B²`——能过类型检查，但用错也不会报错。建议至少标注参数类型。

### 5.6 条件表达式

`if <条件> then <表达式1> else <表达式2>`，**是表达式不是语句**，两分支类型必须一致，可跨行。

```numbat
fn step(x) = if x < 0 then 0 else 1

fn bump(x: Scalar) -> Scalar =
  if x >= 0 && x <= 1
    then 1
    else 0
```

### 5.7 列表

```numbat
[30 cm, 110 cm, 2 m]        # List<Length>
["a", "b", "c"]             # List<String>
[[1, 2], [3, 4]]            # List<List<Scalar>>

len([1, 2, 3])                      # 3
sum([30 cm, 130 cm, 2 m])           # 360 cm
mean([30 cm, 130 cm, 2 m])          # 120 cm
filter(is_finite, [20 cm, inf, 1 m])# [20 cm, 1 m]
map(sqr, [10 cm, 2 m])              # [100 cm², 4 m²]
range(1, 5)                         # [1, 2, 3, 4, 5]
linspace(0 m, 1 m, 5)               # [0 m, 0.25 m, 0.5 m, 0.75 m, 1 m]
```

### 5.8 结构体（struct）

```numbat
struct Element {
    name: String,
    atomic_number: Scalar,
    density: MassDensity,
}

let tungsten = Element {
    name: "Tungsten",
    atomic_number: 74,
    density: 19.25 g/cm³,
}

let side_length = cbrt(1 kg / tungsten.density) -> cm   # 点号取字段

# 泛型 struct
struct Tuple<A, B> { first: A, second: B }
let t = Tuple { first: "hello", second: 42 }

# 带量纲约束的泛型 struct
struct Vec<X: Dim> { x: X, y: X }
let position = Vec { x: 1 m, y: 2 m }
let velocity: Vec<Velocity> = Vec { x: 1 m/s, y: 2 m/s }
```

### 5.9 打印与字符串

```numbat
print(2 km/h)                    # 打印值
print(3 ft < 1 m)                # 打印布尔
print("hello world")             # 打印字符串

let radius: Length = sqrt(footballfield / 4 pi) -> meter
print("A football field would fit on a sphere of radius {radius}")

print("3² + 4² = {hypot2(3, 4)}²")
print("Speed: {speed} ({speed -> mph})")          # 插值里可以用任意表达式
print("value of π ≈ {π:.3}")                      # 格式说明符
print("After {falling_time}, speed is {falling_speed:.1}")
```

格式说明符沿用 **Rust 的 `std::fmt`**（如 `:.3` 有效数字、`:.1` 定点小数等）：<https://doc.rust-lang.org/std/fmt/#formatting-parameters>

---

## 6. 单位与量纲

### 6.1 单位记法

同一个单位通常有三种写法：长名、复数、短别名。

```numbat
2 min + 1 s              2 minutes + 1 second
150 cm                   150 centimeters
sin(30°)                 sin(30 degrees)
50 mph                   50 miles per hour
6 MiB                    6 mebibyte
25 °C                    25 degree_celsius
```

- **SI 单位支持公制前缀**：`mm`、`cm`、`km` / `millimeter`、`centimeter`、`kilometer`
- 合适的地方支持**二进制前缀**：`MiB`、`GiB` / `mebibyte`、`gibibyte`
- **长短前缀不能混用**：`km` ✓、`kilometer` ✓，但 `kmeter` ✗、`kilom` ✗
- 单位可用运算符自由组合：`kg * m/s^2`、`km/h`、`m²`、`meter per second`
- 完整单位表：<https://numbat.dev/docs/prelude/list-units.html>，或在 REPL 里 `list units`

### 6.2 基本单位转换

```numbat
120 km/h -> mph            # = 74.5645 mph    [Velocity]
1600 kcal / day -> W       # = 77.4815 W      [Power]
4 million ฿ -> €           # = 109066 €       [Money]
120 m^3 -> km * m^2        # = 0.12 km·m²     [Volume]
40 rods / hogshead -> mpg  # = 0.00198413 mpg [Length⁻²]
1 / (40 rods / hogshead) -> L / (100 km)
```

- 右侧也可以是复杂表达式
- 等价写法：`->`、`→`、`➞`、`to`
- 结果后面方括号里是**量纲名**（如 `[Velocity]`）——这本身就是一道自检

**转换到"另一个量的单位"**：

```numbat
let v1 = 50 km / h
let v2 = 3 m/s -> unit_of(v1)   # 10.8 km/h
```

### 6.3 高级转换：右侧带系数

当右侧表达式的数值不是 1 时，结果是"右侧量能装进左侧几次"：

```numbat
6 hours -> 45 min
  = 8 × 45 min
```

```numbat
# 协和号在 -60°C、17000 m 高空的马赫数
let concorde_speed = 2180 km/h
concorde_speed -> speed_of_sound(-60 °C)
  = 2.06885 × 292.701 m/s    [Velocity]
```

### 6.4 温度转换（重点坑）

只有 **开尔文 `K` 才是真正的 `Temperature` 单位**。`°C`/`°F` 只能用于"输入"和"作为转换目标"：

- `25 °C` 立即被转成 `298.15 K`
- `25 °C -> °F` 的结果是**纯数字** `77`（没有单位）
- 其他写法：`celsius` / `fahrenheit` / `degree_celsius` / `degree_fahrenheit`，或 `\degree<Tab>`

```numbat
25 °C                # = 298.15 K    [Temperature]
25 °C -> °F          # = 77
element("Fe").melting_point -> °C    # = 1538
```

> [!warning] 摄氏度加减要小心
> numbat 目前**不会**阻止 `10 °C + 1 °C`。因为两边先转成 K 再相加，结果是 `557.3 K`（≈ `284.15 °C`），**不是** `11 °C`。
> - 想加两个温度：其中一个应是**温差**，写成 `K`，如 `10 °C + 1 K`
> - **相减**永远安全：`20 °C - 10 °C` = `10 K`（偏移抵消）

### 6.5 转换函数总表（`x -> f`）

只要 `f` 是"接受同类型单参数"的函数，就能放在 `->` 右边：

```numbat
now() -> unixtime_s                    # 日期时间 → Unix 时间戳
now() -> tz("Asia/Kathmandu")          # 换时区（tz(...) 返回一个函数）
now() -> local                         # 换成本机时区
10 million seconds -> human            # "11 days + 13 hours + 46 minutes + 40 seconds"（实测）
48.7756° -> DMS                        # [48°, 46′, 32.16″]  （返回列表）
48.7756° -> DM                         # 48° 46.536′
1.75 m -> feet_and_inches
70 kg -> pounds_and_ounces
42 -> bin      42 -> oct      2^31-1 -> hex
0x2764 -> chr                          # 码点 → 字符
"❤" -> ord                             # 字符 → 码点
"numbat is awesome" -> uppercase
"vier bis elf weiße Querbänder" -> lowercase
```

---

## 7. 类型系统

### 7.1 量纲即类型

- `2 meter` 的类型是 `Length`，`3 inch` 也是 `Length`，所以 `2 meter + 3 inch` 合法
- `2 meter + 3 second` 非法
- **静态**：程序执行前就检查完；运行期仍可能有除以零等错误

### 7.2 类型的代数

任何类型都可写成基础量纲的乘积形式：$\prod_k D_k^{\alpha_k}$，$\alpha_k \in \mathbb{Q}$。
例如 `Energy` = `Mass¹ × Length² × Time⁻²`。

```numbat
dimension Time
dimension Current
dimension ElectricCharge = Current * Time      # 乘法
dimension Volume = Length^3                    # 幂
dimension Frequency = Time^(-1)
dimension Power = Energy / Time                # 除法 = A × B⁻¹
```

### 7.3 标注与推断

```numbat
let E_pot = 80 kg × 9.8 m/s² × 5 m             # 不写类型也能推断
let E_pot: Energy = 80 kg × 9.8 m/s² × 5 m     # 写了就会被校验，写错立刻报错

fn air_pressure(height: Length) -> Pressure =
  p0 · (1 - lapse_rate · height / t0)^5.255
```

### 7.4 泛型

```numbat
fn abs<D: Dim>(x: D) -> D                # 任意量纲
fn sqrt<D>(x: D^2) -> D                  # 或写成 fn sqrt<D>(x: D) -> D^(1/2)
```

`Dim` 约束保证不会拿 `Bool`、`String` 之类来调用。类型参数之间可以做乘除、开有理数次幂。

### 7.5 已知限制：指数必须是编译期常量

对于 `expr1 ^ expr2`，类型检查器要求：

1. `expr2` 的类型是 `Scalar`
2. 且满足下面之一：
   - `expr1` 也是 `Scalar`
   - `expr2` **能在编译期求值**并得到一个有理数

所以 `meter^(2 * (2 + 1) / 3)` = `Length^2` 没问题，但 `meter^f()` 会编译期报错（因为 `f()` 可能做任何事）。要完全支持就得引入依赖类型（dependent types）。

### 7.6 类型洞（typed holes）— 调试卷利器

在**任何表达式位置**写 `?`，类型检查器会告诉你那里需要什么类型，还会**推荐可用的同名常量**。

```numbat
let mass = 1 kg
let f: Force = mass * ?
```

```text
error: Found typed hole
  ┌─ <input:2>:2:23
2 │ let f: Force = mass * ?
  │                       ^ Acceleration
  = Found a hole of type 'Acceleration' …
```

```numbat
let q = electron_charge
let Q = 2 electron_charge
let r = 1 a0                        # 玻尔半径
q Q / (? r) -> eV
```

```text
  │        ^ ElectricPermittivity
  = Relevant matches for this hole include:
  =   eps0, ε0, electric_constant
```

不仅能推量纲，还能推任意类型、甚至函数类型：

```numbat
fn seq(n) = if n == 1 then [1] else cons_end(n, ?)     # 需要 List<Scalar>
fn transform(xs: List<Scalar>) -> List<String> = map(?, xs)  # 需要 Fn[(Scalar) -> String]
```

> 注意库仑定律里那个 $4\pi$ 是无量纲的，量纲分析推不出来，还得靠自己。

---

## 8. 自定义量纲与单位

### 8.1 新量纲 `dimension`

```numbat
dimension Length
dimension Time
dimension Mass

dimension Velocity = Length / Time
dimension Momentum = Mass * Velocity
dimension Force = Mass * Acceleration = Momentum / Time
dimension Energy = Momentum^2 / Mass = Mass * Velocity^2 = Force * Length
```

导出量纲可以写**多个等价定义**（可选），编译器会验证它们互相等价。

### 8.2 新单位 `unit`

```numbat
unit second: Time                                  # 基本单位（指定量纲）

unit minute: Time = 60 second                      # 导出单位（`: Time` 标注可选，用于自检）
unit farad: Capacitance = ampere^2 second^4 / (kilogram meter^2)
```

> [!tip] 单位定义的两种自检方式
> 1. 在定义末尾加 `-> 单位`（让量纲对齐）
> 2. 加类型标注 `: Energy`——更强，推荐

### 8.3 装饰器：前缀与别名

```numbat
@metric_prefixes
unit second: Time

@binary_prefixes
@metric_prefixes
unit byte = 8 bit            # 同时允许 mebibyte 和 megabyte

@metric_prefixes
@aliases(meters, metre, metres, m: short)
unit meter: Length
```

别名与前缀的交互用 `: long`（默认）/ `: short` / `: both` / `: none` 指定：

- 单位主名 + 所有 `long` 别名 → 接受**长前缀**（`milli`, `kilo`, `mega`…）
- `: short` 别名（如 `m`）→ 只接受**短前缀**（`m`, `k`, `M`…）
- 上面的定义因此允许：`millimeter` `kilometer` `millimeters` `millimetre` `millimetres` `mm` `km` …

### 8.4 临时/虚构单位（计数场景）

```numbat
unit book
@aliases(pages)
unit page
@aliases(words)
unit word

let words_per_book = 500 words/page × 300 pages/book   # 类型 Word / Book
```

`unit book` 是 `dimension Book; unit book: Book` 的语法糖——**会自动创建同名（首字母大写）的新量纲**，于是"书/页/词"互不混淆。

```numbat
@aliases(dots)
unit dot
unit dpi = dots / inch

fn inter_dot_spacing(resolution: Dot / Length) -> Length = 1 dot / resolution
inter_dot_spacing(72 dpi) -> µm          # 353 µm
```

### 8.5 教学例子：香蕉发电

```numbat
let halflife = 1.25 billion years
let occurrence = 0.0117%
let molar_mass = 40 g / mol

let decay_rate = ln(2) / halflife
let radioactivity = N_A * occurrence * decay_rate / molar_mass -> Bq / g   # ≈31 Bq/g

unit banana
let potassium_per_banana = 451 mg / banana
let radioactivity_banana = potassium_per_banana * radioactivity -> Bq / banana  # ≈14 Bq/banana

let energy_per_decay: Energy = 11% × 1.5 MeV + 89% × 1.3 MeV
let power_per_banana: Power / Banana = radioactivity_banana * energy_per_decay

fn household_power(annual_consumption: Energy) -> Power = annual_consumption / year
household_power(10000 kWh) / power_per_banana      # ≈ 4×10¹⁴ 根香蕉
```

> 原 what-if 文章算的是 3×10¹⁷，差 1000 倍，官方认为原文有误（`tutorial.md` 的 note）。

---

## 9. 日期与时间

基于 **proleptic Gregorian calendar**（把现行格里高利历外推到 1582 年之前）。

```numbat
today() - date("2000-01-01") -> days        # 本世纪过了多少天
now() -> tz("Asia/Kathmandu")               # 尼泊尔现在几点（时区名可 Tab 补全）
datetime("2024-11-01 12:30:00 Australia/Sydney") -> local
now() - 1 million seconds
calendar_add(now(), 40 days)                # 40 天后是哪天（按日历算）
date("2000-01-01") -> weekday               # "Saturday"（实测）
now() -> unixtime_s
from_unixtime_s(1707568901)
1 million seconds -> human
```

### 运算

| 左 | 运算符 | 右 | 结果 |
|---|---|---|---|
| `DateTime` | `-` | `DateTime` | 时间差（`Time`，默认单位秒） |
| `DateTime` | `+` / `-` | `Time` | 新 `DateTime` |
| `DateTime` | `->` | `tz("…")` / `local` | 时区转换 |

### 常用函数

`now()`、`today()`、`datetime(str)`、`date(str)`、`time(str)`、`format_datetime(fmt, dt)`、`tz(str)`、`local`、`get_local_timezone()`、`unixtime_s/ms/µs`、`from_unixtime_s/ms/µs`、`unix_s/ms/µs`（单位形式）、`calendar_add(dt, span)`、`calendar_sub(dt, span)`、`weekday(dt)`、`human(duration)`、`julian_date(dt)`、`from_julian_date(a)`

`format_datetime` 的格式符见 jiff 的 strtime 规范。

### 支持的输入格式

| 格式 | 例子 |
|---|---|
| RFC 3339 | `2024-02-10T12:30:00Z`、`2024-02-10T06:30:00-06:00` |
| RFC 2822 | `Sat, 10 Feb 2024 12:30:00 Z` |
| `%Y-%m-%d %H:%M:%S%.f` | `2024-02-10 12:30:00`、`… 06:30:00 -0600`、`… 07:30:00 US/Eastern`、`… 12:30:00.123456` |
| `%Y/%m/%d %H:%M:%S%.f` | 同上，用 `/` |
| `%Y-%m-%d %H:%M` | `2024-02-10 12:30` |
| `%Y-%m-%d %I:%M:%S%.f %p` | `2024-02-10 12:30:00 PM` |
| `%Y-%m-%d %I:%M %p` | `2024-02-10 12:30 PM` |

- RFC 3339 / 2822 **必须**带 UTC 偏移；其他格式的时区可省（省了用本机时区）
- `date()` 返回当天 0 点；`time()` 返回今天的那个时刻

> [!warning] 别直接给日期加 `days`/`months`/`years`
> - `day` 定义为 24 小时，但夏令时那天可能不是
> - `month` 定义为 1/12 年，但日历月长度不一
> - `year` 是回归年的平均值，但日历年有 365/366 天
>
> 想要日历语义请用 `calendar_add` / `calendar_sub`。

---

## 10. 测试与调试

```numbat
assert_eq(q1, q2)            # 精确相等
assert_eq(q1, q2, ε)         # |q1-q2| <= ε，比较前会先换算到 ε 的单位

assert_eq(2 + 3, 5)
assert_eq(1 ft × 77 in², 4 gal)
assert_eq(alpha, 1 / 137, 1e-4)
assert_eq(3.3 ft, 1 m, 1 cm)

assert(1 yard < 1 meter)
assert("foobar" |> str_contains("foo"))
```

断言失败抛运行时错误，成功则静默。

```numbat
>>> type(g0)
  Length / Time²
>>> type(2 < 3)
  Bool
>>> type(sqrt)
  forall A: Dim. Fn[(A²) -> A]

>>> inspect(36 km / 1.5 hours) * 1 day
  inspect: 24 km/h    [Velocity]
    = 576 km    [Length]

>>> range(1, 3) |> map(sqr) |> map(inspect) |> sum
  inspect: 1
  inspect: 4
  inspect: 9
    = 14
```

`inspect` 打印值+类型后**原样返回**，适合在长计算里插桩。

---

## 11. 标准库（prelude）

启动时自动加载模块 `prelude`（源码在仓库 `numbat/modules/`，也编译进二进制）。用 `--no-prelude` 可完全不加载。

### 11.1 prelude 默认包含

```
core::{scalar, quantities, dimensions, functions, lists, strings, error,
       debug, random, numbers, mixed_units}
math::{constants, transcendental, trigonometry, trigonometry_extra,
      statistics, number_theory, distributions, geometry,
      percentage_calculations, combinatorics}
units::{si, time, astronomical, imperial, us_customary, nautical, cgs,
        planck, fff, misc, humorous, partsperx, mixed, currency, bit, placeholder}
physics::{constants, temperature_conversion, speed_of_sound}
chemistry::elements
datetime::{functions, unixtime, human, julian_date}
plot::{line_plot, bar_chart}
```

### 11.2 常量

**数学**：`pi`/`π`、`τ`、`e`、`golden_ratio`/`φ`

**数量词**：`hundred`、`thousand`、`million`、`billion`、`trillion`、`quadrillion`、`quintillion`、`googol`、Unicode 分数（`½`、`⅓`、`⅔`、`¼`、`¾`…）、`quarter`、`half`、`semi`、`double`、`triple`、`dozen`

**物理常量**（含别名与量纲）：

| 含义 | 标识符 | 量纲 |
|---|---|---|
| 真空光速 | `speed_of_light`, `c` | `Velocity` |
| 牛顿引力常数 | `gravitational_constant`, `G` | `Force × Length² / Mass²` |
| 标准重力加速度 | `gravity`, `g0` | `Acceleration` |
| 普朗克常数 | `planck_constant`, `ℎ` | `Mass × Length² / Time` |
| 约化普朗克常数 | `h_bar`, `ℏ` | 同上 |
| 电子质量 | `electron_mass` | `Mass` |
| 元电荷 | `elementary_charge`, `electron_charge` | `ElectricCharge` |
| 真空磁导率 | `magnetic_constant`, `µ0`, `mu0` | `Force / Current²` |
| 真空介电常数 | `electric_constant`, `ε0`, `eps0` | `Capacitance / Length` |
| 玻尔磁子 | `bohr_magneton`, `µ_B` | `Energy / MagneticFluxDensity` |
| 精细结构常数 | `fine_structure_constant`, `alpha`, `α` | `Scalar` |
| 质子/中子质量 | `proton_mass`, `neutron_mass` | `Mass` |
| 阿伏伽德罗常数 | `avogadro_constant`, `N_A` | `1 / AmountOfSubstance` |
| 玻尔兹曼常数 | `boltzmann_constant`, `k_B` | `Energy / Temperature` |
| 斯特藩–玻尔兹曼常数 | `stefan_boltzmann_constant` | `Power / (Area × Temperature⁴)` |
| 理想气体常数 | `gas_constant`, `R` | `Energy / (AmountOfSubstance × Temperature)` |
| 普朗克长度/质量/时间/温度/能量 | `planck_length` 等 | 各自量纲 |
| 玻尔半径 | `bohr_radius`, `a0` | `Length` |
| 里德伯常数 | `rydberg_constant` | `Wavenumber` |

### 11.3 函数索引（按模块）

| 类别 | 代表函数 |
|---|---|
| 基础数学 | `id`, `abs`, `sqrt`, `cbrt`, `sqr`, `round(_in)`, `floor(_in)`, `ceil(_in)`, `trunc(_in)`, `fract`, `mod`, `parse`, `args` |
| 超越函数 | `exp`, `ln`, `log`, `log10`, `log2`, `gamma` |
| 三角 | `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `atan2`, `sinh`, `cosh`, `tanh`, `asinh`, `acosh`, `atanh` |
| 统计 | `maximum`, `minimum`, `mean`, `variance`, `stdev`, `median` |
| 组合数学 | `factorial`, `falling_factorial`, `binom`, `fibonacci`, `lucas`, `catalan` |
| 随机/分布 | `random`, `rand_uniform`, `rand_int`, `rand_bernoulli`, `rand_binom`, … |
| 列表 | `len`, `head`, `tail`, `cons`, `cons_end`, `is_empty`, `concat`, `take`, `drop`, `element_at`, `range`, `reverse`, `map`, `map2`, `filter`, `foldl`, `sort`, `sort_by_key`, `contains`, `unique`, `intersperse`, `sum`, `linspace`, `join`, `split` |
| 字符串 | `str_length`, `str_slice`, `chr`, `ord`, `lowercase`, `uppercase`, `str_append`, `str_prepend`, `str_find`, `str_contains`, `str_replace`, `str_repeat`, `base`, `bin`, `oct`, `dec`, `hex` |
| 浮点判定 | `is_nan`, `is_infinite`, `is_finite`, `is_zero`, `is_nonzero`, `is_integer` |
| 量（quantity） | `value_of`, `unit_of`, `base_unit_of`, `has_unit`, `is_dimensionless`, `unit_name`, `quantity_cast` |
| 化学 | `element("Fe")` → 可访问 `.melting_point`、`.density` 等 |
| 混合单位 | `unit_list`, `DMS`, `DM`, `feet_and_inches`, `pounds_and_ounces` |
| 温度 | `from_celsius`/`°C`、`from_fahrenheit`/`°F` |
| 声速 | `speed_of_sound(temperature)` |
| 颜色（`extra::color`） | `rgb`, `color`, `color_hex`, `color_rgb` + `black`/`white`/`red`… |
| 错误处理 | `error(...)`；调试 `inspect` |

### 11.4 单位总览（按量纲，节选）

| 量纲 | 常见单位 |
|---|---|
| `Length` | `m`/`meter`/`metre`, `in`, `ft`, `yd`, `mi`, `nautical_mile`/`NM`, `angstrom`/`Å`, `micron`, `mil`/`thou`, `furlong`, `fathom`, `rod`/`perch`, `league`, `au`/`AU`, `ly`, `pc`, `smoot`, `fermi`, `rackunit`, `footballfield` 相关面积单位 |
| `Time` | `s`, `min`, `h`/`hr`, `day`/`d`, `week`, `fortnight`, `month`, `year`/`yr`/`tropical_year`, `julian_year`, `gregorian_year`, `sidereal_day`, `decade`, `century`, `millennium` |
| `Mass` | `g`, `kg`（前缀）, `lb`/`pound`, `oz`, `stone`, `tonne`/`ton`, `grain`, `troy_ounce`/`ozt`, `pennyweight`, `firkin`, `hundredweight`/`cwt`, `dalton`/`Da`, `long_ton` |
| `Area` | `acre`, `are`, `barn`, `hectare`/`ha`, `footballfield` |
| `Volume` | `L`/`l`/`liter`, `gal`(US), `imperial_gallon`/`UK_gal`, `pint`, `cup`, `floz`, `tablespoon`/`tbsp`, `teaspoon`/`tsp`, `cc`, `barrel`, `hogshead` |
| `Velocity` | `mph`, `kph`, `kn`/`knot` |
| `Power` | `W`, `hp` |
| `Pressure` | `Pa`, `bar`, `atm`, `psi`, `torr`, `mmHg`, `inHg`, `ksi` |
| `Energy` | `J`, `cal`, `kcal`, `eV`, `Wh`, `BTU`, `erg`, `therm`, `thermie`, `Ry` |
| `Angle` | `rad`, `°`/`deg`, `′`, `″`, `gon`/`grad`, `turn`, `rev` |
| `Temperature` | `K`（唯一真单位）, `°C`, `°F` |
| `DigitalInformation` | `bit`/`bits`, `byte`/`B`/`octet`, `KB` |
| `DataRate` | `bps`；`Frame`/`frame`, `fps`, `Pixel`/`px`, `ppi`, `dpi`, `Dot`/`dot` |
| `Frequency` | `Hz`, `rpm` |
| 电磁 | `A`, `C`, `V`, `F`, `Ω`/`ohm`, `S`, `H`, `Wb`, `T`, `gauss`, `maxwell`, `Oe` |
| 辐射/光 | `Bq`, `Gy`, `Sv`, `kat`, `cd`, `lm`, `lux`, `nit` |
| 粘/流 | `poise`, `St`/`stokes`, `darcy`, `mpg` |
| `Money` | `€`/`EUR`、`$`/`USD`、`£`/`GBP`、`¥`/`JPY`、`元`/`CNY`、`฿`、`₩`、`₹`、`₺`、`₪`、`Rp`、`RM`、`zł`、`Kč`、`lei` … |
| 计数/人 | `person`/`people`/`capita`, `piece`, `beat`, `frame`, `LOC`/`SLOC` |
| 比例 | `%`/`percent`/`pct`, `‰`, `ppm`, `ppb`, `ppt`, `ppq` |

完整表：<https://numbat.dev/docs/prelude/list-units.html>

### 11.5 按需加载的模块（`all.nbt`）

```numbat
use all                                  # 一次性全加载

use units::currencies                    # 完整货币列表（prelude 里的 units::currency 只有欧元）
use units::stoney                        # Stoney 单位制
use units::hartree                       # Hartree 原子单位

use extra::algebra                       # quadratic_equation, cubic_equation
use extra::color                         # Color struct + rgb/hex
use extra::astronomy                     # 光秒、月/地/火/木/日质量半径、太阳光度、Jansky、foe…
use extra::celestial                     # sunrise_sunset, moon_phase, lunar_cycle
use extra::cooking                       # 食材密度倒数（water/butter/flour/sugar…），杯↔克换算
use extra::vector3                       # Vec<D>、add、multiply、dot_product、cross、length

use numerics::diff                       # diff(f, x, Δx)、dsolve_runge_kutta
use numerics::solve                      # root_bisect, root_newton
use numerics::fixed_point                # fixed_point(f, x0, ε)
```

**绘图**（`plot::line_plot` / `plot::bar_chart`，默认已加载）：

```numbat
line_plot(f, x_start, x_end) |> xlabel("t") |> ylabel("v") |> show
bar_chart([1, 2, 3]) |> xlabels(["a", "b", "c"]) |> show
```

`show(plot)` 返回字符串形式的图形，终端里主要是拿去做进一步处理；**要真正看图用 Web 版**。

---

## 12. 货币与汇率

- 量纲：`Money`，基准单位是 `euro`（`units/currency.nbt`）
- 其他货币由 `units/currencies.nbt` 通过 ECB 汇率定义：`unit dollar: Money = EUR / exchange_rate("USD")` 等
- **需要联网**取欧元参考汇率；离线时会报"未知标识符"
- 实测：`numbat -e '1 USD -> CNY'` → `6.68622 CNY`

配置项（`config.toml`）：

```toml
[exchange-rates]
# on-startup（默认，启动就后台拉）| on-first-use（用到了才拉）| never（禁用，用货币就报错）
fetching-policy = "on-startup"
```

---

## 13. 配置与定制

### 启动顺序

1. prelude（`<module-path>/prelude.nbt` 若存在，否则用内置版本）
2. 用户初始化文件 `<config-path>/init.nbt`（若存在）

### 配置目录

| 平台 | 路径 |
|---|---|
| Linux | `$HOME/.config/numbat` 或 `$XDG_CONFIG_HOME/numbat` |
| macOS | `$HOME/Library/Application Support/numbat` |
| Windows | `C:\Users\Alice\AppData\Roaming\numbat` |

### 模块搜索路径（靠前优先）

| 位置 | 说明 |
|---|---|
| `$NUMBAT_MODULES_PATH` | 单个目录，或 `:` 分隔的目录列表 |
| `<config-path>/modules` | 用户自定义模块 |
| `/usr/share/numbat/modules` | 系统模块（Linux/macOS） |
| `C:\Program Files\numbat\modules` | 系统模块（Windows） |
| `<builtin>` | 编译进二进制的内置模块 |

### config.toml

```bash
numbat --generate-config        # 生成默认配置
```

主要字段：

```toml
intro-banner = "long"       # long | short | off
prompt = ">>> "
pretty-print = "auto"       # always | never | auto（auto = 只在交互模式）
edit-mode = "emacs"         # emacs | vi
color = "auto"              # always | never | auto

[formatting]
digit-separator = "_"              # 也可 ",", " ", "'" 或 "" 关闭
digit-grouping-threshold = 6       # 达到几位才加分隔符
significant-digits = 6             # 浮点最多显示多少有效位
datetime = "%Y-%m-%d %H:%M:%S"     # strftime 风格，"%.f" 含小数秒

[exchange-rates]
fetching-policy = "on-startup"
```

### 自定义常量/函数/单位

写进 `~/.config/numbat/init.nbt`，每次启动生效。

### 自定义模块

放在 `<module-path>/custom/finance.nbt`，然后：

```numbat
use custom::finance
use custom::finance::functions      # 子目录
```

`custom` 只是惯例目录名，用来避开与标准库重名。也可以从 `init.nbt` 里 `use`，让它一直可用。

---

## 14. 编辑器集成

- Vim：`assets/numbat.vim`
- VS Code：仓库 `vscode-extension/`
- Sublime Text：`assets/numbat.sublime-syntax`
- Helix：tree-sitter 语法 <https://github.com/irevoire/tree-sitter-numbat>

---

## 15. 示例配方（可直接抄）

### 人口增长（指数模型）

```numbat
let initial_population = 50_000 people
let growth_rate = 2% per year

fn predict_population(t) =
    initial_population × e^(growth_rate·t) |> round_in(people)

print("Population in  20 years: {predict_population(20 years)}")
print("Population in 100 years: {predict_population(1 century)}")
```

### 药物剂量（自定义计数单位 `taking`）

```numbat
@aliases(takings)
unit taking

let body_weight = 75 kg
let dosage = (60 mg / kg) / day
let frequency = 3 takings / day

let total_daily_dose = dosage * body_weight -> mg / day
print("Total daily dose: {total_daily_dose}")

let single_dose = total_daily_dose / frequency
print("Single dose:      {single_dose}")
```

### 管道流量（Hagen–Poiseuille）

```numbat
let μ_water: DynamicViscosity = 1 mPa·s

fn flow_rate(radius: Length, length: Length, Δp: Pressure) -> FlowRate =
    π × radius^4 × Δp / (8 μ_water × length)

let Q = flow_rate(1 cm, 10 m, 0.1 bar)
print("Flow rate: {Q -> L/s}")
```

### 摩尔浓度

```numbat
let molar_mass_NaCl = 58.44 g / mol

fn molarity(mass: Mass, volume: Volume) -> Molarity =
    (mass / molar_mass_NaCl) / volume

print(molarity(9 g, 1 L) -> mmol / l)
```

### 菜谱缩放

```numbat
@aliases(servings)
unit serving

let original_recipe_servings = 2 servings
let desired_servings = 3 servings

fn scale(quantity) = quantity × desired_servings / original_recipe_servings

print("Milk:          {scale(500 ml)}")
print("Flour:         {scale(250 g)}")
print("Sugar:         {scale(2 cups)}")
print("Baking powder: {scale(4 tablespoons)}")
```

### 量纲分析（xkcd 687）

```numbat
let core_pressure = 3.5 million atmospheres
let prius_milage = 50 miles per gallon
let min_width_channel = 21 miles

let r: Scalar = planck_energy / core_pressure × prius_milage / min_width_channel
print("{r} ≈ π ?")
```

### 烧开一加仑水需要多少能量（华氏度/卡路里混算）

```numbat
let density_water = 1 kg / L
let mass_water = 1 gallon × density_water
let c_water = 1 cal / g K
let ΔT = 212 °F - 70 °F

let heat = mass_water × c_water × ΔT
print("  {heat -> kJ}\n  {heat -> BTU}\n  {heat -> kWh}")
```

### 自动微分型小工具（数值模块）

```numbat
use numerics::solve
use numerics::diff

root_bisect(f, 0 m, 10 m, 1e-6 m, 1e-6 m)
diff(f, 1 m, 0.001 m)
```

---

## 16. 踩坑清单

> [!warning] 标识符与单位名冲突
> `m`、`s`、`g`、`h`、`K`、`B`… 都是已有单位。写 `let m = 1 kg` 会报
> `error: identifier clash in definition … Module 'units::si', File <builtin>/modules/units/si.nbt`
> （本机实测）。**变量名用长一点的**：`mass`、`speed`、`tmp`、`m_obj`。

> [!warning] 隐式乘法 / `per` 的优先级
> `50 cm / 2 m` 是 `50 cm / (2 m)`；`1 / meter per second` 是 `1 / (meter/second)`。拿不准就开 `pretty-print` 看回显。

> [!warning] 摄氏度不能随便加减
> `10 °C + 1 °C` = `557.3 K`。见 [[#6.4 温度转换（重点坑）]]。

> [!warning] `°C`/`°F` 不是真单位
> 它们是"入口/出口"，转换结果是**无单位的数字**：`25 °C -> °F` = `77`。

> [!warning] 只有 64 位浮点
> `1e16 + 1 - 1e16` 之类不精确；官方计划改任意精度，现在别指望。

> [!warning] `day` / `month` / `year` 是固定时长
> 日期运算要日历语义请用 `calendar_add` / `calendar_sub`。

> [!hint] 货币必须联网
> 汇率从 ECB 拉；离线/禁用时用货币单位会报"未知标识符"。想彻底离线：`fetching-policy = "never"`。

> [!hint] `info` 是 REPL 命令
> `numbat -e 'info sqrt'` 会 `unknown identifier`；在交互式会话里敲 `info sqrt` 才对。

> [!hint] 想复用上一次结果
> `ans` 或 `_`。

> [!hint] 交互式调试技巧
> 输入到一半拉长表达式时，直接按 `↑` 调出上一行，接 `|> f` 或 `-> 单位` 再回车——这是官方推荐的交互范式。

---

## 17. 速查表

```numbat
# ── 基础
2 pi                       # 隐式乘法
2^32   2**32   2³          # 幂
17 mod 4  /  mod(17,4)
1920 / 16 * 9

# ── 单位
110 km / (1 day + 3 hours)         # = 4.07407 km/h  [Velocity]
50 mph                             # 短别名
50 miles per hour                  # 长名
6 MiB   6 mebibyte
25 °C    25 degree_celsius
120 km/h -> mph                    # 转换（-> / → / ➞ / to）
6 hours -> 45 min                  # = 8 × 45 min
3 m/s -> unit_of(v1)               # 对齐到别的量的单位
unit_of(1 m/s)                     # m/s

# ── 数值/进制
0xffee -> bin ; 42 -> oct ; 2^16-1 -> hex
273 |> base(3)

# ── 日期时间
now() ; today() ; date("2000-01-01") ; datetime("2024-02-10 12:30:00 Europe/Berlin")
now() -> tz("Asia/Kathmandu") ; datetime(...) -> local
now() - date("2000-01-01") -> days
calendar_add(now(), 40 days)
now() -> unixtime_s ; from_unixtime_s(1707568901)
1 million seconds -> human

# ── 字符串/输出
print("{v} ({v -> mph})") ; print("{π:.3}")
assert_eq(3.3 ft, 1 m, 1 cm) ; assert(1 yard < 1 meter)
type(g0) ; inspect(36 km / 1.5 hours)

# ── 量化/统计
len, sum, mean, median, variance, stdev, maximum, minimum
map, filter, foldl, range, linspace, sort, unique, take, drop

# ── 自定义
let x: Length = 1 m
fn f(a: Mass, b: Velocity) -> Energy = 1/2 a b^2
fn g<D: Dim>(a: D, b: D) -> D = if a > b then a else b
dimension Fame
@metric_prefixes @aliases(quorks) unit quork = 0.35 meter
struct S { a: Length, b: String }
```

---

## 18. Unicode 输入速查

输入 `\关键字` 后按 `Tab`。常用：

| 输入 | 结果 | | 输入 | 结果 |
|---|---|---|---|---|
| `\alpha` | α | | `\pi` | π |
| `\beta` | β | | `\rho` | ρ |
| `\gamma` | γ | | `\sigma` | σ |
| `\delta` | δ | | `\tau` | τ |
| `\mu` | μ | | `\phi` / `\varphi` | ϕ / φ |
| `\lambda` | λ | | `\omega` | ω |
| `\Delta` | Δ | | `\Omega` | Ω |
| `\times` | × | | `\cdot` | ⋅ |
| `\div` | ÷ | | `\pm` | ± |
| `\to` / `\rightarrow` | → | | `\degree` | ° |
| `\ge` / `\le` | ≥ / ≤ | | `\micro` | µ |
| `\^2` | ² | | `\_2` | ₂ |
| `\^0`…`\^9` | ⁰¹²³⁴⁵⁶⁷⁸⁹ | | `\_0`…`\_9` | ₀₁₂₃₄₅₆₇₈₉ |
| `\hbar` | ℏ | | `\planck` | ℎ |
| `\ohm` | Ω | | `\Angstrom` | Å |
| `\1/2` | ½ | | `\percent` | % |
| `\dollar` / `\euro` / `\sterling`/`\pound` | $ / € / £ | | `\yen` `\rupee` `\won` `\lira` `\peso` `\baht` `\shekel` | ¥ ₹ ₩ ₺ ₱ ฿ ₪ |
| `\dots`/`\ldots` | … | | `\arcmin` / `\arcsec` | ′ / ″ |

（灵感来自 Julia 的 Unicode 输入系统。）

---

## 19. 延伸阅读

- 主文档：<https://numbat.dev/docs/>（Tutorial / Basics / Advanced / CLI / Standard library / Examples）
- 语法总览（一页速览，官方自动生成）：<https://numbat.dev/docs/examples/example-numbat_syntax.html>
- 单位总表：<https://numbat.dev/docs/prelude/list-units.html>
- 标准库源码：<https://github.com/sharkdp/numbat/tree/main/numbat/modules>
- 示例程序：<https://github.com/sharkdp/numbat/tree/main/examples>（含 what_if_11.nbt 等）
- 与其他工具对比：<https://numbat.dev/docs/comparison.html>
- 本笔记基于 **main 分支的 book 源码 + 本机 numbat 1.24.0 实测**；若你升级到更高版本，个别细节（尤其是标准库内容）可能略有变化，可对照 `numbat --version` 与 `list units` 复核。
