---
tags:
  - python
  - statistics
  - 医学统计
  - scipy
  - pingouin
created: 2026-07-14
---

# scipy.stats + pingouin 医学统计速查教程

> 面向医学生的常用统计检验教程：t 检验、方差分析、卡方检验、相关分析、非参数检验。
> 所有示例代码均已在本机环境（python 3.14 + scipy 1.18 + pingouin 0.6.1）真实运行验证，输出为实际结果。
> 配套环境：`pixi global install pingouin --environment python`

## 目录

1. [环境准备与依赖](#环境准备与依赖)
2. [核心：选检验的决策树](#核心选检验的决策树)
3. [数据准备（模拟医学数据）](#数据准备模拟医学数据)
4. [正态性检验（决策分水岭）](#正态性检验决策分水岭)
5. [t 检验三兄弟](#t-检验三兄弟)
6. [方差分析 ANOVA + 事后检验](#方差分析-anova--事后检验)
7. [卡方检验（分类变量）](#卡方检验分类变量)
8. [相关性分析](#相关性分析)
9. [非参数检验三件套](#非参数检验三件套)
10. [进阶：重复测量 ANOVA / 双因素 ANOVA](#进阶重复测量-anova--双因素-anova)
11. [常见坑与论文写法](#常见坑与论文写法)

---

## 环境准备与依赖

```bash
pixi global install pingouin --environment python
```

本教程用到三个库：

```python
import numpy as np
import pandas as pd
import scipy.stats as st      # 基础统计函数
import pingouin as pg         # 医学统计友好封装
```

**scipy vs pingouin 怎么选？**（个人建议）

| 场景 | 用哪个 |
|---|---|
| 快速算一个 p 值，不关心额外指标 | `scipy.stats` |
| 写论文 / 系统分析，想要效应量、置信区间、统计功效、贝叶斯因子 | `pingouin` |

**核心区别：** scipy 只给你检验统计量和 p 值；pingouin 一行输出完整表格（效应量 + 置信区间 + power），这些正是医学论文审稿人要的东西。**两者输出可以互相印证**（下面的例子你会看到数字完全一致）。

---

## 核心：选检验的决策树

**先看数据类型，再沿树往下走**（这是整个统计入门最重要的一张图）：

```
数据是什么类型？
│
├── 连续变量（血压、血糖、年龄）
│   ├── 数据正态吗？ → Shapiro-Wilk 检验
│   │   ├── 正态 → 参数检验
│   │   │   ├── 一组 vs 已知值      → 单样本 t 检验
│   │   │   ├── 两组独立样本        → 独立样本 t 检验
│   │   │   ├── 两组配对（前后测）  → 配对 t 检验
│   │   │   ├── 三组及以上          → ANOVA + Tukey 事后检验
│   │   │   └── 两个连续变量关系    → Pearson 相关
│   │   └── 非正态 → 非参数检验
│   │       ├── 两组独立            → Mann-Whitney U
│   │       ├── 两组配对            → Wilcoxon 符号秩
│   │       ├── 三组及以上          → Kruskal-Wallis
│   │       └── 两个变量关系        → Spearman 相关
│   └── 方差不齐（Levene 检验显著）→ Welch t 检验 / Welch ANOVA
│
└── 分类变量（性别、是否患病、疗效等级）
    └── 列联表（行×列交叉） → 卡方检验
```

**学习方法：** 每学一个检验，先定位它在树上的位置，再问三个问题——① 什么时候用 ② 代码怎么写 ③ 结果怎么解读。

---

## 数据准备（模拟医学数据）

教程用模拟的临床试验数据：两组患者的收缩压（mmHg），A 组安慰剂、B 组治疗。

```python
import numpy as np
import pandas as pd
import scipy.stats as st
import pingouin as pg

np.random.seed(42)

# 两组独立样本：收缩压
group_A = np.random.normal(128, 12, 30)   # 安慰剂组
group_B = np.random.normal(135, 13, 30)   # 治疗组

# 长格式 DataFrame（统计分析的推荐格式：一行一个观测）
df = pd.DataFrame({
    "group": ["A"] * 30 + ["B"] * 30,
    "sbp": np.concatenate([group_A, group_B])
})

# 配对数据：治疗前后（同一批患者）
before = np.random.normal(140, 12, 25)
after = before - np.random.normal(8, 5, 25)

# 三组数据（ANOVA 用）
g1 = np.random.normal(120, 10, 25)   # 低剂量
g2 = np.random.normal(128, 11, 25)   # 中剂量
g3 = np.random.normal(135, 12, 25)   # 高剂量
df3 = pd.DataFrame({
    "group": ["低剂量"]*25 + ["中剂量"]*25 + ["高剂量"]*25,
    "sbp": np.concatenate([g1, g2, g3])
})
```

**先做描述性统计**（pandas 就够，这是分析的第一步）：

```python
df.groupby("group")["sbp"].agg(["count", "mean", "std", "median", "min", "max"]).round(2)
```

```
       count    mean   std  median     min     max
group
A         30  125.74  10.8  125.19  105.04  146.95
B         30  133.42  12.1  134.16  109.52  159.08
```

---

## 正态性检验（决策分水岭）

**作用：** 决定你走参数检验（t/ANOVA/Pearson）还是非参数检验（Mann-Whitney/Kruskal/Spearman）。

```python
# scipy 版本（对每组分别检验）
for g in ["A", "B"]:
    w, p = st.shapiro(df.loc[df.group == g, "sbp"])
    print(f"组{g}: W={w:.4f}, p={p:.4f}")

# pingouin 版本（长格式 DataFrame，一次性全组）
pg.normality(df, dv="sbp", group="group")
```

```
            W    pval  normal
group
A      0.9751  0.6868    True
B      0.9837  0.9130    True
```

**结果解读：** 原假设是「数据来自正态分布」。`p > 0.05` → 不能拒绝原假设 → 认为正态，走参数检验。本例两组都正态。

**注意：**
- 参数是 `shapiro`（默认），样本量建议 < 5000；大样本可用 `method="normaltest"`（D'Agostino 检验）
- **正态性看的是每组分别**，不是合并
- 医学数据（住院天数、费用、生存时间）经常是**右偏态**，非正态是常态，别硬套 t 检验

---

## t 检验三兄弟

### ① 独立样本 t 检验（两组独立数据，如：安慰剂 vs 治疗）

```python
# scipy（注意 scipy 用两个数组，equal_var=True 为经典 t 检验）
t, p = st.ttest_ind(group_A, group_B, equal_var=True)
print(f"t={t:.4f}, p={p:.4f}")

# pingouin（直接传两个数组）
pg.ttest(group_A, group_B, correction=False)
```

scipy 输出：`t=-2.5940, p=0.0120`

pingouin 输出（**这就是论文需要的完整信息**）：

```
            T  dof alternative  p_val             CI95  cohen_d   power   BF10
T_test -2.594   58   two-sided  0.012  [-13.61, -1.75]   0.6698  0.7227  4.082
```

**字段解读：** `T`=t值，`dof`=自由度，`p_val`=p值，`CI95`=均值差的95%置信区间，`cohen_d`=效应量（0.2小/0.5中/0.8大），`power`=统计功效，`BF10`=贝叶斯因子。

**论文写法：** 独立样本 t 检验显示，治疗组收缩压显著高于安慰剂组（t = −2.59，p = 0.012，Cohen's d = 0.67）。

> **方差不齐怎么办？** 先用 `st.levene(group_A, group_B)` 检验方差齐性；若 p < 0.05，改用 Welch 修正：scipy 用 `equal_var=False`，pingouin 用默认 `correction="auto"`（自动判断）。

### ② 配对 t 检验（同一批人的前后对比，医学实验最常用）

```python
# scipy
t, p = st.ttest_rel(before, after)

# pingouin
pg.ttest(before, after, paired=True)
```

```
              T  dof alternative  p_val          CI95  cohen_d   power       BF10
T_test  10.7258   24   two-sided    0.0  [6.26, 9.24]   0.6021  0.8234  8.019e+07
```

**注意 `p_val = 0.0` 的陷阱：** pingouin 显示 0.0 是因为 p 值极小被四舍五入，**论文里绝不能写 p=0**！正确写法是 `p < 0.001`。想显示完整数值，可以：

```python
res = pg.ttest(before, after, paired=True)
print(res["p_val"].iloc[0])   # 用科学计数法看真实值，如 1.2e-09
```

**论文写法：** 配对 t 检验显示，治疗后收缩压显著降低（t = 10.73，p < 0.001）。

### ③ 单样本 t 检验（一组数据 vs 已知值，如：与正常值 130 比较）

```python
# scipy
t, p = st.ttest_1samp(before, popmean=130)

# pingouin（y 传数字即可）
pg.ttest(before, 130)
```

```
             T  dof alternative   p_val             CI95  cohen_d   power    BF10
T_test  3.8791   24   two-sided  0.0007  [134.6, 145.07]   0.7758  0.9608  46.651
```

---

## 方差分析 ANOVA + 事后检验

**场景：** 三组及以上比较（低/中/高剂量）。注意：**ANOVA 只告诉你「组间有差异」，不告诉你「哪两组有差异」**，所以显著后必须做事后检验（Tukey HSD）。

```python
# scipy（只给 F 和 p）
F, p = st.f_oneway(g1, g2, g3)
print(f"F={F:.4f}, p={p:.4f}")

# pingouin（长格式）
pg.anova(data=df3, dv="sbp", between="group")
```

```
  Source  ddof1  ddof2        F  p_unc     np2
0  group      2     72  16.8991    0.0  0.3195
```

`np2` = 偏 eta 平方（效应量：0.01小/0.06中/0.14大）。本例 0.32 是大效应。

**ANOVA 显著后，做 Tukey 事后检验：**

```python
pg.pairwise_tukey(data=df3, dv="sbp", between="group")
```

```
     A    B    mean_A    mean_B     diff       se      T  p_tukey  hedges
0  中剂量  低剂量  128.4290  119.6351   8.7939  3.1212  2.8174   0.0170  0.8089
1  中剂量  高剂量  128.4290  137.7780  -9.3490  3.1212 -2.9953   0.0104 -0.8379
2  低剂量  高剂量  119.6351  137.7780 -18.1429  3.1212 -5.8127   0.0000 -1.5649
```

**解读：** `p_tukey` 是三组两两比较的校正后 p 值。本例三组两两之间均显著（p 均 < 0.05）。

**论文写法：** 单因素方差分析显示三组收缩压差异显著（F(2,72) = 16.90，p < 0.001，η²p = 0.32）；Tukey 事后检验显示高剂量组显著高于低剂量组（p < 0.001）和中剂量组（p = 0.010）。

> **方差不齐的多组比较：** 用 `pg.welch_anova(data=df3, dv="sbp", between="group")`（Welch ANOVA），事后用 `pg.pairwise_gameshowell()`。

---

## 卡方检验（分类变量）

**场景：** 两个分类变量的关系（如：治疗组 vs 对照组 的有效率差异）。数据是**列联表**（计数）。

```python
import numpy as np

# 列联表：行=组，列=[有效, 无效]
table = np.array([[45, 15],   # 治疗组：45 有效，15 无效
                  [30, 30]])  # 对照组：30 有效，30 无效

# scipy（correction=False 为皮尔逊卡方，不进行 Yates 连续性校正）
chi2, p, dof, expected = st.chi2_contingency(table, correction=False)
print(f"chi2={chi2:.4f}, p={p:.4f}, dof={dof}")

# pingouin 需要长格式：先转换
rows = []
for gi, g in enumerate(["治疗组", "对照组"]):
    for oi, out in enumerate(["有效", "无效"]):
        rows.extend([[g, out]] * int(table[gi, oi]))
df_chi = pd.DataFrame(rows, columns=["group", "outcome"])

# pingouin（x, y 是长格式 DataFrame 的两列）
# 返回三个对象：(expected, observed, stats)，stats 是检验结果表
res = pg.chi2_independence(df_chi, x="group", y="outcome", correction=False)
res[2][["test", "chi2", "dof", "pval", "cramer"]]
```

scipy 输出：`chi2=8.0000, p=0.0047, dof=1`（期望频数矩阵见 `expected` 变量）

pingouin 输出（它同时给出 6 种卡方变体，通常看第一行 `pearson`）：

```
                 test    chi2  dof    pval  cramer
0             pearson  8.0000  1.0  0.0047  0.2582
1        cressie-read  8.0257  1.0  0.0046  0.2586
2      log-likelihood  8.1173  1.0  0.0044  0.2601
3       freeman-tukey  8.2228  1.0  0.0041  0.2618
4  mod-log-likelihood  8.3619  1.0  0.0038  0.2640
5              neyman  8.7500  1.0  0.0031  0.2700
```

**解读：** 两组有效率差异显著（p = 0.005）。`cramer` = Cramér's V（分类变量的效应量：0.1小/0.3中/0.5大）。

**论文写法：** 卡方检验显示治疗组有效率显著高于对照组（χ² = 8.00，p = 0.005，V = 0.26）。

**重要前提：** 卡方检验要求**期望频数 ≥ 5**（scipy 会返回 `expected` 矩阵，检查它）。若期望频数 < 5，用 Fisher 精确检验 `st.fisher_exact(table)`（2×2 表）或 `pg.fisher`。

---

## 相关性分析

**场景：** 两个连续变量的线性关系（如：BMI 与血压）。

```python
x = np.random.normal(5, 1, 40)
y = 2.5 * x + np.random.normal(0, 1.5, 40)

# scipy
r, p = st.pearsonr(x, y)          # 皮尔逊（要求双变量正态）
rs, ps = st.spearmanr(x, y)       # 斯皮尔曼（秩相关，不要求正态）

# pingouin（method 可选 pearson / spearman / kendall）
pg.corr(x, y, method="pearson")
pg.corr(x, y, method="spearman")
```

```
# pearson
          n       r          CI95  p_val       BF10  power
pearson  40  0.8789  [0.78, 0.93]    0.0  8.038e+10    1.0

# spearman
           n       r          CI95  p_val  power
spearman  40  0.8417  [0.72, 0.91]    0.0    1.0
```

**解读：** r = 0.88 为强正相关（|r|<0.3 弱 / 0.3-0.7 中 / >0.7 强），p < 0.001 显著。`CI95` 是相关系数的置信区间。

**Pearson vs Spearman 怎么选：**
- 两个变量**都近似正态**、且关系是线性的 → Pearson
- 数据**偏态**、有**等级数据**（疼痛评分、疗效等级）、或关系非单调 → Spearman
- 医学量表中很常见：主观评分（Likert 量表）用 Spearman

**论文写法：** BMI 与收缩压呈显著正相关（r = 0.88，p < 0.001，95% CI [0.78, 0.93]）。

---

## 非参数检验三件套

**什么时候用：** 正态性检验不通过（p < 0.05），或数据是等级/顺序数据。它们是 t 检验和 ANOVA 的「非正态替代版」。

### ① Mann-Whitney U（独立两组，替代独立 t 检验）

```python
skew_a = np.random.exponential(2, 30)   # 偏态数据
skew_b = np.random.exponential(3, 30)

U, p = st.mannwhitneyu(skew_a, skew_b)  # scipy
pg.mwu(skew_a, skew_b)                  # pingouin
```

```
     U_val alternative   p_val     RBC    CLES
MWU  284.0   two-sided  0.0144 -0.3689  0.3156
```

`RBC` = 秩二列相关（效应量），`CLES` = 共同语言效应量（概率解释：随机取一个 A 组值大于 B 组值的概率）。

### ② Wilcoxon 符号秩（配对两组，替代配对 t 检验）

```python
w, p = st.wilcoxon(skew_a[:25], skew_b[:25])  # scipy
pg.wilcoxon(skew_a[:25], skew_b[:25])         # pingouin
```

```
          W_val alternative   p_val     RBC    CLES
Wilcoxon  110.0   two-sided  0.1645 -0.3231  0.3728
```

### ③ Kruskal-Wallis（三组及以上，替代单因素 ANOVA）

```python
H, p = st.kruskal(skew_a[:20], skew_b[:20], np.random.exponential(4, 20))
```

**论文写法：** 因数据呈非正态分布，采用 Mann-Whitney U 检验，两组差异显著（U = 284，p = 0.014，RBC = −0.37）。

---

## 进阶：重复测量 ANOVA / 双因素 ANOVA

### 重复测量 ANOVA（同一批人在多个时间点测量）

```python
rng = np.random.default_rng(7)
n = 20
base = rng.normal(130, 8, n)
t0 = base
t1 = base - rng.normal(6, 1.5, n)
t2 = base - rng.normal(14, 2.5, n)

data = pd.DataFrame({
    "subject": np.tile(np.arange(n), 3),          # 注意：tile！一行一个观测
    "time": np.repeat(["t0", "t1", "t2"], n),     # 注意：repeat！
    "sbp": np.concatenate([t0, t1, t2])
})

pg.rm_anova(data=data, dv="sbp", within="time", subject="subject")
```

```
  Source  ddof1  ddof2        F  p_unc  p_GG_corr     ng2     eps  sphericity  W_spher  p_spher
0   time      2     38  444.127    0.0        0.0  0.4617  0.6808       False   0.5311   0.0034
```

**注意（新手最易错）：** 长格式组装时，`subject` 用 `tile`（1,2,3,...重复）、`time` 用 `repeat`（t0 全部、t1 全部），与拼接的 `sbp` 顺序对应——两者写反会导致配对错乱！

**球形检验：** `sphericity=False` 且 `p_spher = 0.003 < 0.05` 说明违反球形假设，此时看 **`p_GG_corr`**（Greenhouse-Geisser 校正后的 p 值）而非 `p_unc`。

显著后的事后两两比较：`pg.pairwise_ttests(data=data, dv="sbp", within="time", subject="subject")`。

### 双因素 ANOVA（两个分组变量，如：组别 × 性别）

```python
pg.anova(data=df, dv="sbp", between="group", detailed=False)
```

```
  Source  ddof1  ddof2       F  p_unc    np2
0  group      1     58  6.7287  0.012  0.104
```

`detailed=True` 可查看 `SS`、`MS`（平方和/均方）等细节；双因素时两个 `between` 变量用 `between=["组别", "性别"]`，并关注交互项。

---

## 常见坑与论文写法

### 六个高频坑

1. **p = 0.0 的陷阱**：pingouin 输出 `p_val = 0.0` 是四舍五入，论文写 `p < 0.001`，绝不写 `p = 0`
2. **长格式是王道**：pingouin 的 `anova`/`normality` 等函数接受长格式 DataFrame（一行一个观测），别拿宽格式硬塞
3. **先看正态性再选检验**：非正态数据用 t 检验会被审稿人打回
4. **卡方检验前检查期望频数**：`expected` 矩阵有 < 5 的值就用 Fisher 精确检验
5. **ANOVA 显著 ≠ 知道哪两组有差异**：必须跟事后检验（Tukey）
6. **重复测量数据注意球形假设**：违反时读 `p_GG_corr`

### 论文统计结果的标准写法模板

| 检验 | 论文写法 |
|---|---|
| 独立 t 检验 | 两组差异显著（t(58) = −2.59，p = 0.012，Cohen's d = 0.67） |
| 配对 t 检验 | 治疗后显著降低（t(24) = 10.73，p < 0.001） |
| 单因素 ANOVA | 三组差异显著（F(2,72) = 16.90，p < 0.001，η²p = 0.32） |
| 卡方检验 | 有效率差异显著（χ² = 8.00，p = 0.005，V = 0.26） |
| Pearson 相关 | 显著正相关（r = 0.88，p < 0.001，95% CI [0.78, 0.93]） |
| Mann-Whitney U | 差异显著（U = 284，p = 0.014） |

### 一个完整的分析流程模板（复制即用）

```python
import numpy as np, pandas as pd
import scipy.stats as st, pingouin as pg

# 1. 描述性统计
desc = df.groupby("group")["sbp"].agg(["count", "mean", "std", "median"])

# 2. 正态性
norm = pg.normality(df, dv="sbp", group="group")

# 3. 按决策树选检验
if norm["normal"].all():          # 全部正态
    res = pg.anova(data=df, dv="sbp", between="group")   # ≥3组
    # res = pg.ttest(x, y)                               # 2组
else:
    res = pg.kruskal(data=df, dv="sbp", between="group") # ≥3组
    # res = pg.mwu(x, y)                                 # 2组

# 4. ANOVA 显著 → 事后检验
if res["p_unc"].iloc[0] < 0.05:
    posthoc = pg.pairwise_tukey(data=df, dv="sbp", between="group")

# 5. 输出论文语句
f"差异显著（F({int(res['ddof1'].iloc[0])},{int(res['ddof2'].iloc[0])}) = {res['F'].iloc[0]:.2f}, p < 0.05)"
```

---

## 参考

- scipy.stats 官方文档：<https://docs.scipy.org/doc/scipy/reference/stats.html>
- pingouin 官方文档：<https://pingouin-stats.org/stable/>
- pingouin API 速查：<https://pingouin-stats.org/stable/api.html>
- 本教程输出环境：python 3.14 / scipy 1.18.0 / pingouin 0.6.1

*相关笔记：[[DuckDB详细教程]] · [[FastAPI_详细教程]] · [[loguru笔记]]*
