# XGBoost on the GPU

XGBoost trains on the GPU with `device="cuda"`. This example trains the same model on the CPU and on the GPU and compares time and accuracy.

## Run it

Paste into a notebook cell and run:

```python
import time
import numpy as np
import xgboost as xgb

rng = np.random.default_rng(0)
n, f = 2_000_000, 50
X = rng.standard_normal((n, f)).astype(np.float32)
y = ((X[:, 0] + 0.5 * X[:, 1] * X[:, 2] + 0.1 * rng.standard_normal(n)) > 0).astype(np.int32)
split = int(n * 0.8)

for device in ["cpu", "cuda"]:
    clf = xgb.XGBClassifier(tree_method="hist", device=device, n_estimators=300, max_depth=8)
    t0 = time.perf_counter()
    clf.fit(X[:split], y[:split])
    elapsed = time.perf_counter() - t0
    acc = (clf.predict(X[split:]) == y[split:]).mean()
    print(f"{device}: {elapsed:.1f} s, accuracy {acc:.4f}")
```

To keep the whole pipeline on the GPU, pass cuDF or CuPy data to `fit` instead of NumPy arrays.

Reference: https://xgboost.readthedocs.io/en/stable/gpu/index.html
