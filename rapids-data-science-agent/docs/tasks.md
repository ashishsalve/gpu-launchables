# Three tasks for the agent

Open a terminal in JupyterLab, run `agent`, and paste one task. Each task asks the agent to write a notebook into `notebooks/`, run it, and print a results table. The notebook measures its timings on your GPU when it runs.

## 1. Taxi trip analytics: pandas, cudf.pandas and Polars on CPU and GPU

```
Download the NYC TLC yellow taxi trip records for January, February and March 2025
(Parquet) and the taxi zone lookup CSV into data/. Write and run
notebooks/taxi_cpu_vs_gpu.ipynb that computes trips and fares by pickup zone and
hour of day four ways: pandas on CPU, cudf.pandas, Polars with the CPU engine, and
Polars with the GPU engine. Join the zone names, check that all four results match,
and print a timing table with one row per method.
```

If the download fails, ask the agent to generate a synthetic table of 20 million trips with the same columns instead.

## 2. Tip prediction: scikit-learn vs cuML, XGBoost CPU vs CUDA

```
Using the taxi data in data/, write and run notebooks/tip_prediction.ipynb that
predicts the tip amount from trip distance, fare, pickup hour, passenger count and
pickup zone. Train a RandomForestRegressor with scikit-learn on CPU and again with
cuml.accel enabled, then XGBoost with device="cpu" and device="cuda". Print a table
with fit time and R2 score for the four runs.
```

## 3. Zone-to-zone trip graph with cuGraph

```
Using the taxi data and the zone lookup in data/, write and run
notebooks/zone_graph.ipynb: load the trips with cuDF, build a directed graph with
one vertex per taxi zone and one edge per pickup-to-dropoff zone pair weighted by
trip count, and drop self-loops. Run cuGraph PageRank and print the top 15 zones
by name. Then run Louvain community detection on the undirected graph, print the
modularity and, for the five largest communities, the number of zones and the
three busiest zone names. Print a timing table for each step.
```

The `cugraph-analytics` skill shows the cuGraph calls the agent should use.

## Tips

- Ask the agent to "use the skill" by name (for example `polars-gpu-engine` or `cugraph-analytics`) to steer it.
- Keep the data in `data/` inside the workspace folder.
