<p align="center">
  <strong>NVIDIA RAPIDS on NVIDIA Brev</strong><br>
  GPU data science in JupyterLab on one NVIDIA L4: pandas on cuDF, scikit-learn on cuML, Polars on its GPU engine and XGBoost on CUDA.
</p>

# RAPIDS Data Science with cuDF and cuML

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aZ3FqwckUgj9tV7qQc9B3vVG)

Launchable ID: env-3M8aZ3FqwckUgj9tV7qQc9B3vVG

GPU data science in JupyterLab with [NVIDIA RAPIDS](https://github.com/rapidsai) on one NVIDIA L4 24GB GPU. Run your pandas code on the GPU with cuDF and your scikit-learn code with cuML with no code changes, run Polars queries on its GPU engine with engine="gpu", train [XGBoost](https://github.com/dmlc/xgboost) on the GPU with device="cuda", and compare each against the CPU on the same instance. First step: deploy, open JupyterLab from the open-jupyterlab link, and paste one of the five ready examples into a notebook.

| Quick facts | |
| --- | --- |
| Runs | JupyterLab 4 with RAPIDS 26.10 (cuDF, cuDF-Polars, cuML, cuGraph, Dask-CUDA) and XGBoost 3.4.2 (CUDA build), one container under Docker Compose |
| Default compute | 1x NVIDIA L4 24GB on GCP (g2-standard-8, 8 vCPU, 32 GiB RAM), stoppable; you can pick another GPU on the deploy page |
| Disk | 64 GiB |
| Ready in | about 11 minutes on a fresh deploy (2026-11-15) |
| Cost | about $1.02/hr on the default compute (console, 2026-11-15); storage is billed while stopped |
| Secrets | none; there are no launch parameters |
| Licences | RAPIDS Apache-2.0, XGBoost Apache-2.0, JupyterLab BSD-3-Clause |
| Guide | https://www.9owls.com/launchables/rapids-datascience/ |

Current versions: RAPIDS 26.10 (`rapidsai/notebooks:26.10-cuda12-py3.12`, CUDA 12, Python 3.12)

Last smoke: 2026-11-15, fresh deploy on one NVIDIA L4 24GB, including stop and start.

## Contents

- [What you get](#what-you-get)
- [Deploy in three steps](#deploy-in-three-steps)
- [Try it first](#try-it-first)
- [How it works](#how-it-works)
- [Settings](#settings)
- [Use it from your machine](#use-it-from-your-machine)
- [Data and persistence](#data-and-persistence)
- [Stop, start and delete](#stop-start-and-delete)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [Guides and related Launchables](#guides-and-related-launchables)
- [Keep your own stack running](#keep-your-own-stack-running)
- [Credits and licences](#credits-and-licences)

## What you get

| Component | Version | Image or file |
| --- | --- | --- |
| RAPIDS (cuDF, cuDF-Polars, cuML, cuGraph, Dask-CUDA) | 26.10 (pinned by tag and digest) | `rapidsai/notebooks:26.10-cuda12-py3.12` |
| XGBoost (CUDA build) | 3.4.2 (`xgboost=3.4.2=cuda129_pyh5c66634_0`) | conda, installed at container start |
| JupyterLab 4 with Dask and GPU dashboards | as shipped in the RAPIDS 26.10 image | same image |
| Runnable examples | five notebooks-as-Markdown | [docs/](docs/cudf-pandas.md) in this folder |

## Deploy in three steps

1. Click Launch on Brev, keep the NVIDIA L4 or pick another GPU, and deploy. There are no settings to fill.
2. Wait until the instance shows Running and the open-jupyterlab link loads the JupyterLab login page. This takes about 11 minutes on a fresh deploy, because the first start installs the CUDA build of XGBoost before JupyterLab starts.
3. Read your JupyterLab token with the Brev CLI, then click **open-jupyterlab** and paste it into the login page:

```
brev shell INSTANCE_NAME
sudo cat /home/ubuntu/workspace/rapids/.jupyter-token
```

On the login page you can also set a password for later logins. JupyterLab opens in the top-level notebooks folder.

## Try it first

Open a new notebook in the top-level folder and paste the cells from one of these examples. Each example generates its own data, so nothing is downloaded and no account is needed.

| Example | What it shows |
| --- | --- |
| [docs/cudf-pandas.md](docs/cudf-pandas.md) | pandas on the GPU with `cudf.pandas`, timed against plain pandas |
| [docs/cuml-accel.md](docs/cuml-accel.md) | scikit-learn on the GPU with `python -m cuml.accel` |
| [docs/polars-gpu.md](docs/polars-gpu.md) | Polars lazy queries with the GPU engine |
| [docs/xgboost-gpu.md](docs/xgboost-gpu.md) | XGBoost training with `device="cuda"` vs CPU |
| [docs/time-series-finance.md](docs/time-series-finance.md) | time series features on synthetic price data, then XGBoost on the GPU (educational, not investment advice) |

A good first run: start with the cuDF pandas example to see the same pandas code on CPU and GPU, then the XGBoost example. The image's own RAPIDS example notebooks are in the folders beside `workspace`. Save notebooks you want to keep into the `workspace` folder.

## How it works

- One container, started with Docker Compose from the pinned RAPIDS 26.10 notebooks image.
- JupyterLab listens on port 8888 and is reached through the authenticated Brev Secure Link **open-jupyterlab**.
- JupyterLab also asks for its own token, which is generated randomly on the first start of your instance and stays the same after stop and start.
- The Dask dashboard is on port 8787 behind the **dask-dashboard** link.
- There are no launch parameters and no secrets. The examples use synthetic data generated on the instance.
- Each time the container starts, it downloads and installs the CUDA build of XGBoost (about 150 MB) from conda, so the instance needs internet access and JupyterLab is ready only after that install finishes.

<details>
<summary>Advanced: Dask cluster and dashboard</summary>

If you start a Dask cluster in a notebook (for example `LocalCUDACluster` from `dask_cuda`), its dashboard is on port 8787 and opens from the **dask-dashboard** link. The JupyterLab sidebar also has Dask and GPU dashboard panels.

</details>

## Settings

This Launchable has no launch parameters. Pick the GPU on the deploy page; everything else is preset in `compose.yaml`.

## Use it from your machine

To reach JupyterLab without the browser link, forward the port with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 8888:8888
```

Then open http://localhost:8888 locally and log in with the same token.

## Data and persistence

Save your notebooks and data in the `workspace` folder in JupyterLab. It is stored on the instance at `/home/ubuntu/workspace/rapids`. It survives a stop and start of the instance and is removed when the instance is deleted. Files outside `workspace` live inside the container and are lost if the container is recreated.

## Stop, start and delete

- **Stop** the instance from the Brev console when you are not using it. Your `workspace` folder is kept, including your notebooks and your JupyterLab token. Storage is still billed while the instance is stopped.
- **Start** it again: the JupyterLab container is recreated automatically, usually within a few minutes. If it is not back after 5 minutes, use the recovery command under Troubleshooting.
- **Delete** the instance when you are finished. This removes the instance and all of its data.

## Troubleshooting

<details>
<summary>JupyterLab is not back after a stop and start</summary>

Stopping the instance removes the JupyterLab container; everything under ~/workspace is kept, including your notebooks and your JupyterLab token. Starting it again recreates the container automatically, usually within a few minutes. If JupyterLab is not back after 5 minutes, open a terminal on the instance and run:

```
cd /home/ubuntu/workspace && sudo docker compose up -d
```

</details>

<details>
<summary>The open-jupyterlab link does not load right after deploy</summary>

Each container start installs the CUDA build of XGBoost (about 150 MB) from conda before JupyterLab starts. On a fresh deploy the whole stack was ready in about 11 minutes. Wait, then reload the link. The instance needs internet access for this install.

</details>

<details>
<summary>JupyterLab asks for a token or password</summary>

This is expected: JupyterLab has its own token in addition to the Brev link. Read it with `brev shell INSTANCE_NAME`, then `sudo cat /home/ubuntu/workspace/rapids/.jupyter-token`. You can set a password on the login page for later logins.

</details>

<details>
<summary>An example runs out of GPU memory</summary>

The examples are sized for the 24 GB NVIDIA L4. On a GPU with less memory, reduce the row counts in the example.

</details>

## FAQ

### Which GPU do I need for RAPIDS?

One NVIDIA GPU with compute capability 7.0 or newer (Volta or later), as RAPIDS requires. The default is one NVIDIA L4 24GB with 64 GiB of disk. The examples are sized for the L4; on a GPU with less memory, reduce the row counts.

### What does it cost to leave it running?

A running instance bills by the hour for the GPU you chose; the deploy page shows the current price before you deploy (the default L4 was about $1.02/hr on 2026-11-15). A stopped instance bills only its storage. Delete the instance when you are finished to stop all charges for it.

### Where does my data live?

In the `workspace` folder in JupyterLab, stored on the instance at `/home/ubuntu/workspace/rapids`. It survives Stop and is removed by Delete.

### Can I use my own data?

Yes. Upload files into the `workspace` folder from the JupyterLab file browser and read them with pandas, cuDF or Polars as usual.

### Does anything leave the instance?

The examples generate their data on the instance and make no outside calls. The container downloads the pinned XGBoost package from conda at each start.

### Can I run this on my own hardware?

Yes, the stack is the public [RAPIDS notebooks image](https://github.com/rapidsai/docker) plus the `compose.yaml` in this folder. See the [RAPIDS](https://github.com/rapidsai) project for supported GPUs and drivers.

### How do I update to a newer RAPIDS version?

This Launchable pins RAPIDS 26.10 by tag and digest so every deploy is the same. To try a newer release on your own instance, change the image tag in `compose.yaml` under `/home/ubuntu/workspace` and run `sudo docker compose up -d`; your `workspace` folder is kept.

## Guides and related Launchables

- Step-by-step guide: [How to run RAPIDS cuDF and cuML in JupyterLab](https://www.9owls.com/guides/run-rapids-cudf-and-cuml-in-jupyterlab/)
- [How to deploy a Launchable on NVIDIA Brev](https://www.9owls.com/guides/deploy-a-launchable-on-nvidia-brev/)
- [How to stop and delete an NVIDIA Brev instance](https://www.9owls.com/guides/stop-start-and-delete-an-nvidia-brev-instance/)
- [What is a Brev Launchable?](https://www.9owls.com/guides/what-is-a-brev-launchable/)
- [Brev Launchables FAQ](https://www.9owls.com/faq/brev-launchable-basics/): billing, persistence and choosing a GPU
- [Run a GPU data science agent with Hermes and RAPIDS](https://www.9owls.com/guides/run-a-gpu-data-science-agent-with-hermes-and-rapids/)
- This Launchable on 9owls: https://www.9owls.com/launchables/rapids-datascience/
- All Launchables by 9owls: https://www.9owls.com/launchables/
- Related: [RAPIDS Data Science Agent with Hermes](https://www.9owls.com/launchables/rapids-data-science-agent/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3MK00FdEhqj8HhqutQYrm896chK)); [Isaac Lab + Newton Robot Learning](https://www.9owls.com/launchables/isaac-lab-newton/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8arIbDn5RySQJP1XtedUwZdFa)); [RAGFlow on your own GPU](https://www.9owls.com/launchables/ragflow/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M7Rp4TmPPfR0piWdfBqcHweyVl))
## Keep your own stack running

NightKeeper packages your repository as an NVIDIA Brev Launchable, proves it on a fresh GPU and keeps it running. Your Brev API key stays in your repository's GitHub secrets. NightKeeper never sees it.

[Create your Launchable](https://www.9owls.com/nightkeeper/start/) or [read about NightKeeper](https://www.9owls.com/nightkeeper/).

## Credits and licences

- [RAPIDS](https://github.com/rapidsai) (cuDF, cuDF-Polars, cuML, cuGraph, Dask-CUDA), from the official [RAPIDS container images](https://github.com/rapidsai/docker): Apache-2.0.
- [XGBoost](https://github.com/dmlc/xgboost), CUDA build: Apache-2.0.
- JupyterLab: BSD-3-Clause.

Files in this folder: `compose.yaml` (the stack, image pinned by tag and digest), `docs/` (the runnable examples) and [LICENSE](LICENSE) (Apache License 2.0 for the files in this folder, with upstream attributions).

Published and maintained by [9owls, Inc.](https://www.9owls.com/). Questions: hello@9owls.com.
