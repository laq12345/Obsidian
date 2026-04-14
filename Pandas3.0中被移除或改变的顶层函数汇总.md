---
lang: Python
date: 2026-04-07
tags:
  - 数据分析
---
# ====== 已移除（只能用方法形式）======
pd.value_counts(x)        # → x.value_counts()           # 你的报错就是这个
pd.isnull(x)              # → x.isnull() 或 pd.isna(x)   # isna 还在，isnull 没了
pd.notnull(x)             # → x.notnull() 或 pd.notna(x)

# ====== 已移除的参数 ======
x.fillna(method='ffill')  # → x.ffill()
x.fillna(method='bfill')  # → x.bfill()

# ====== 还在的顶层函数（暂时没动）======
pd.Series()               # ✅ 还在
pd.DataFrame()            # ✅ 还在
pd.read_csv()             # ✅ 还在
pd.concat()               # ✅ 还在
pd.merge()                # ✅ 还在
pd.to_datetime()          # ✅ 还在
pd.cut()                  # ✅ 还在
pd.qcut()                 # ✅ 还在