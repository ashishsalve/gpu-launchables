# Polars on the GPU

Polars runs a lazy query on the GPU when you collect it with the GPU engine, powered by cuDF. `raise_on_fail=True` makes the query fail loudly instead of silently running on the CPU.

## Run it

Paste into a notebook cell and run:

```python
import time
import numpy as np
import polars as pl
from polars.testing import assert_frame_equal

n = 50_000_000
rng = np.random.default_rng(0)
df = pl.DataFrame({
    "key": rng.integers(0, 10_000, n),
    "x": rng.random(n),
    "y": rng.random(n),
})

q = (
    df.lazy()
    .filter(pl.col("x") > 0.1)
    .group_by("key")
    .agg(pl.col("y").mean().alias("y_mean"), pl.col("x").sum().alias("x_sum"), pl.len().alias("rows"))
    .sort("key")
)

t0 = time.perf_counter()
cpu = q.collect()
t_cpu = time.perf_counter() - t0

t0 = time.perf_counter()
gpu = q.collect(engine=pl.GPUEngine(raise_on_fail=True))
t_gpu = time.perf_counter() - t0

assert_frame_equal(cpu, gpu, check_exact=False)
print(f"CPU {t_cpu:.2f} s, GPU {t_gpu:.2f} s, results match")
```

Run the cell twice: the first GPU collect includes a one-time warm-up.

Reference: https://docs.pola.rs/user-guide/gpu-support/
