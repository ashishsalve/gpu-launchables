# RAPIDS Data Science with cuDF and cuML

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aZ3FqwckUgj9tV7qQc9B3vVG)

Launchable ID: env-3M8aZ3FqwckUgj9tV7qQc9B3vVG

GPU data science in JupyterLab with [NVIDIA RAPIDS](https://github.com/rapidsai). Run your pandas code on the GPU with cuDF and your scikit-learn code with cuML with no code changes, run Polars queries on its GPU engine with engine="gpu", train XGBoost on the GPU with device="cuda", and compare each against the CPU on the same instance.

Current versions: RAPIDS 26.10 (`rapidsai/notebooks:26.10-cuda12-py3.12`, CUDA 12, Python 3.12)

Last smoke: 2026-11-15, fresh deploy on one NVIDIA L4 24GB, including stop and start.

## What it runs

| Component | Version | Source |
| --- | --- | --- |
| RAPIDS (cuDF, cuDF-Polars, cuML, cuGraph, Dask-CUDA) | 26.10 (pinned by tag and digest) | `rapidsai/notebooks:26.10-cuda12-py3.12` |
| XGBoost (CUDA build) | 3.4.2 (`xgboost=3.4.2=cuda129_pyh5c66634_0`) | conda, installed at container start |
| JupyterLab 4 with Dask and GPU dashboards | as shipped in the RAPIDS 26.10 image | same image |

One container, started with Docker Compose. JupyterLab listens on port 8888 and is reached through the authenticated Brev link. JupyterLab also asks for its own token, which is generated randomly on the first start of your instance and stays the same after stop and start. There are no launch parameters.

Each time the container starts, it downloads and installs the CUDA build of XGBoost (about 150 MB) from conda, so the instance needs internet access and JupyterLab is ready only after that install finishes.

## Minimum GPU

One NVIDIA GPU with compute capability 7.0 or newer (Volta or later), as RAPIDS requires. The default is one NVIDIA L4 24GB with 64 GiB of disk. The examples are sized for the L4; on a GPU with less memory, reduce the row counts.

## Use it

1. Deploy and wait until the instance is Running and the open-jupyterlab link loads the JupyterLab login page (the first start installs XGBoost first, so this takes a few minutes).
2. Read your JupyterLab token from the instance with the Brev CLI:

   ```
   brev shell INSTANCE_NAME
   sudo cat /home/ubuntu/workspace/rapids/.jupyter-token
   ```

3. Click **open-jupyterlab** and paste the token into the JupyterLab login page. On that page you can also set a password for later logins. JupyterLab opens in the top-level notebooks folder.
4. Open a new notebook in that top-level folder and follow one of the examples below. The image's own RAPIDS example notebooks are in the folders beside `workspace`. Save notebooks you want to keep into the workspace folder.

| Example | What it shows |
| --- | --- |
| [docs/cudf-pandas.md](docs/cudf-pandas.md) | pandas on the GPU with `cudf.pandas`, timed against plain pandas |
| [docs/cuml-accel.md](docs/cuml-accel.md) | scikit-learn on the GPU with `python -m cuml.accel` |
| [docs/polars-gpu.md](docs/polars-gpu.md) | Polars lazy queries with the GPU engine |
| [docs/xgboost-gpu.md](docs/xgboost-gpu.md) | XGBoost training with `device="cuda"` vs CPU |
| [docs/time-series-finance.md](docs/time-series-finance.md) | time series features on synthetic price data, then XGBoost on the GPU (educational, not investment advice) |

Each example generates its own data, so nothing is downloaded and no account is needed.

### Dask dashboard

If you start a Dask cluster in a notebook (for example `LocalCUDACluster` from `dask_cuda`), its dashboard is on port 8787 and opens from the **dask-dashboard** link. The JupyterLab sidebar also has Dask and GPU dashboard panels.

### From your own machine

To reach JupyterLab without the browser link, forward the port with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 8888:8888
```

Then open http://localhost:8888 locally and log in with the same token.

## How data persists

Save your notebooks and data in the `workspace` folder in JupyterLab. It is stored on the instance at `/home/ubuntu/workspace/rapids`. It survives a stop and start of the instance and is removed when the instance is deleted. Files outside `workspace` live inside the container and are lost if the container is recreated.

## Stop or delete to control cost

- **Stop** the instance from the Brev console when you are not using it. Your `workspace` folder is kept, and the JupyterLab container is recreated on the next start (see Stop and start). Storage is still billed while the instance is stopped.
- **Delete** the instance when you are finished. This removes the instance and all of its data.

## Stop and start

Stopping the instance removes the JupyterLab container; everything under ~/workspace is kept, including your notebooks and your JupyterLab token. Starting it again recreates the container automatically, usually within a few minutes. If JupyterLab is not back after 5 minutes, open a terminal on the instance and run:

```
cd /home/ubuntu/workspace && sudo docker compose up -d
```

## Files

- `compose.yaml` - the stack, image pinned by tag and digest.
- `docs/` - the runnable examples.
- `LICENSE` - Apache-2.0 for the files in this folder, with upstream attributions.
