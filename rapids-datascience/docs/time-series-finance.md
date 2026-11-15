# Time series features for finance on the GPU

An educational example: build per-ticker time series features with pandas code accelerated by cuDF, then train an XGBoost model on the GPU. The prices are synthetic random walks generated in the notebook, so no data download or API key is needed.

This is a teaching example about GPU data processing. It is not investment advice, and a model trained on random-walk prices has no predictive value.

## Run it

Open a new notebook. Load `cudf.pandas` in the first cell, before importing pandas:

```python
%load_ext cudf.pandas
import time
import numpy as np
import pandas as pd
import xgboost as xgb
```

Generate 2,000 synthetic tickers with 2,500 trading days each (5 million rows):

```python
tickers, days = 2_000, 2_500
rng = np.random.default_rng(0)
log_ret = rng.normal(0.0002, 0.02, size=(tickers, days))
close = 100 * np.exp(np.cumsum(log_ret, axis=1))
df = pd.DataFrame({
    "ticker": np.repeat(np.arange(tickers), days),
    "day": np.tile(np.arange(days), tickers),
    "close": close.ravel(),
})
```

Compute returns, rolling volatility and moving averages per ticker:

```python
t0 = time.perf_counter()
g = df.groupby("ticker")["close"]
df["ret_1d"] = g.pct_change()
df["ret_5d"] = g.pct_change(5)
df["ma_20"] = g.rolling(20).mean().reset_index(level=0, drop=True)
df["ma_50"] = g.rolling(50).mean().reset_index(level=0, drop=True)
df["vol_20"] = df.groupby("ticker")["ret_1d"].rolling(20).std().reset_index(level=0, drop=True)
df["ma_gap"] = df["ma_20"] / df["ma_50"] - 1
df["target"] = (df.groupby("ticker")["ret_1d"].shift(-1) > 0).astype("int32")
df = df.dropna()
print(f"features for {len(df):,} rows in {time.perf_counter() - t0:.2f} s")
```

Train on the first 80 percent of days and test on the rest (a time-based split, never a random one, for time series):

```python
features = ["ret_1d", "ret_5d", "vol_20", "ma_gap"]
cut = int(days * 0.8)
train, test = df[df["day"] < cut], df[df["day"] >= cut]
clf = xgb.XGBClassifier(tree_method="hist", device="cuda", n_estimators=200, max_depth=6)
clf.fit(train[features], train["target"])
acc = (clf.predict(test[features]) == test["target"].to_numpy()).mean()
print(f"test accuracy {acc:.3f} (about 0.5 is expected on random-walk data)")
```

To see the speedup, restart the kernel, skip the `%load_ext cudf.pandas` line, and run the feature cell again on the CPU.

Reference: https://docs.nvidia.com/cudf/latest/cudf_pandas/
