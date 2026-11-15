# pandas on the GPU with cuDF (zero code change)

`cudf.pandas` runs your existing pandas code on the GPU. Operations cuDF supports run on the GPU; anything else falls back to pandas on the CPU automatically. You do not change your code.

This example times the same pandas script twice on the same instance: once with plain pandas on the CPU, once under `cudf.pandas` on the GPU.

## Run it

1. In JupyterLab, open a new notebook (Python 3 kernel).
2. Paste the cell below and run it. It writes `bench_pandas.py` into the `workspace` folder.

```python
%%writefile workspace/bench_pandas.py
import time
import numpy as np
import pandas as pd

n = 50_000_000
rng = np.random.default_rng(0)
df = pd.DataFrame({
    "key": rng.integers(0, 10_000, n),
    "a": rng.random(n),
    "b": rng.random(n),
})

t0 = time.perf_counter()
out = (
    df[df["a"] > 0.1]
    .assign(c=lambda d: d["a"] * d["b"])
    .groupby("key")
    .agg(a_mean=("a", "mean"), c_sum=("c", "sum"), rows=("b", "size"))
    .sort_values("c_sum", ascending=False)
)
elapsed = time.perf_counter() - t0
print(out.head(3))
print(f"filter + groupby + sort on {n:,} rows: {elapsed:.2f} s")
```

3. Run the CPU baseline and then the GPU run in the next cells:

```python
!python workspace/bench_pandas.py
```

```python
!python -m cudf.pandas workspace/bench_pandas.py
```

The printed results are the same; compare the two timings. The first GPU run includes a short warm-up.

## In a notebook

To accelerate pandas inside a notebook, load the extension in the first cell, before `import pandas`:

```python
%load_ext cudf.pandas
import pandas as pd
```

Reference: https://docs.nvidia.com/cudf/latest/cudf_pandas/
