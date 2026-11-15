# scikit-learn on the GPU with cuML (zero code change)

`cuml.accel` runs supported scikit-learn estimators on the GPU without code changes and falls back to the CPU for anything it does not accelerate.

## Run it

Paste into a notebook cell and run. It writes `bench_sklearn.py` into the `workspace` folder.

```python
%%writefile workspace/bench_sklearn.py
import time
import numpy as np
from sklearn.cluster import KMeans
from sklearn.decomposition import PCA

rng = np.random.default_rng(0)
X = rng.standard_normal((2_000_000, 64)).astype(np.float32)

t0 = time.perf_counter()
Xp = PCA(n_components=16).fit_transform(X)
labels = KMeans(n_clusters=20, n_init=1, random_state=0).fit_predict(Xp)
elapsed = time.perf_counter() - t0
print("clusters found:", len(np.unique(labels)))
print(f"PCA + KMeans on {X.shape[0]:,} x {X.shape[1]}: {elapsed:.2f} s")
```

CPU baseline, then the same script on the GPU:

```python
!python workspace/bench_sklearn.py
```

```python
!python -m cuml.accel workspace/bench_sklearn.py
```

Inside a notebook, load the extension before importing scikit-learn:

```python
%load_ext cuml.accel
from sklearn.cluster import KMeans
```

Reference: https://docs.nvidia.com/cuml/latest/cuml-accel/
