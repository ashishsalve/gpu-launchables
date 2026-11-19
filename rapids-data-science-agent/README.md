# RAPIDS Data Science Agent with Hermes

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3MK00FdEhqj8HhqutQYrm896chK)

Launchable ID: env-3MK00FdEhqj8HhqutQYrm896chK

1x L40S 48GB, >= 48 GB VRAM | 200 GiB disk | ~$2.26/hr (console 2026-11-19) | ~30 min to ready | Stop to pause, Delete when done

Ask a data question in plain English and Hermes Agent writes and runs a GPU notebook for you with NVIDIA RAPIDS (cuDF, cuML and cuGraph), guided by NVIDIA Agent Skills. Hermes Agent is an open-source agent by Nous Research. The NVIDIA Nemotron 3.5 Lightning model runs on the same GPU with vLLM; no hosted model key is used.

Default GPU: one NVIDIA L40S 48GB. The model server and RAPIDS share that GPU.

## What you get

- JupyterLab on the RAPIDS image (cuDF, cudf.pandas, cuDF-Polars, cuML, cuGraph, XGBoost with CUDA).
- Hermes Agent in the JupyterLab terminal (command `agent`) and its web dashboard.
- NVIDIA Agent Skills for cuDF and cuML plus the NVIDIA skill finder, and two bundled skills: Polars GPU engine and cuGraph analytics.
- A local model server (vLLM) with the model name `nemotron`, published on the instance loopback address only.

## Try these three tasks

1. Open the `open-jupyterlab` link. JupyterLab asks for its login key; read it in the Brev terminal with `sudo cat /home/ubuntu/workspace/rapids-data-science-agent/.jupyter-token`.
2. Open `START-HERE.md` in the `workspace` folder, then open a terminal (File > New > Terminal) and run `agent`.
3. Paste one of the tasks in [docs/tasks.md](docs/tasks.md): taxi trip analytics (pandas vs cudf.pandas vs Polars CPU and GPU), tip prediction (scikit-learn vs cuML, XGBoost CPU vs CUDA), or a zone-to-zone trip graph with cuGraph (PageRank and Louvain communities).

Each task asks the agent to write a notebook into `workspace/notebooks/`, run it and print a results table.

## How it works

- `jupyter` serves JupyterLab on port 8888 for the Brev Secure Link `open-jupyterlab`.
- `agent` serves the Hermes dashboard on port 9119 for the Brev Secure Link `hermes`, behind a login (user `hermes`; read the generated password with `sudo cat /home/ubuntu/workspace/rapids-data-science-agent/hermes/dashboard-password`).
- `vllm` serves the model on the instance loopback only (localhost port 8001). Hermes reaches it at `http://vllm:8000/v1`.

On first start the `agent` service installs Hermes Agent from a pinned source archive, with its Python dependencies taken from the project's lock file and checked by hash, then installs the listed skills. Hermes runs on its own Python 3.14, installed under the workspace; notebooks and the code the agent runs use the RAPIDS Python 3.12 environment, so `python` in the agent's commands imports cuDF. Its log ends with `agent-init: ready`.

The agent can reach the internet, for example to download data.

## Settings

| Parameter | Default | Meaning |
| --- | --- | --- |
| MAX_MODEL_LEN | 65536 | Model context window in tokens. Hermes Agent needs at least 64000. |
| VLLM_GPU_MEMORY_UTILIZATION | 0.55 | Share of GPU memory for the model; the rest is for RAPIDS. |
| HF_TOKEN | none | Optional Hugging Face read token. Pick "Use a secret" to bind a saved Brev secret, or paste one. |

## Use the model API from your machine

```
brev port-forward INSTANCE_NAME --port 8001:8001
curl http://localhost:8001/v1/models
```

## Data and persistence

Notebooks, data, the Hermes install, its configuration and skills live in `/home/ubuntu/workspace/rapids-data-science-agent` (the `workspace` folder in JupyterLab). The model cache lives in `/home/ubuntu/workspace/huggingface`. Brev keeps the workspace when you Stop the instance and removes it when you Delete it.

## Stop and delete

Stop pauses the instance. Delete removes the instance and all data. After a Start, if a service is not running, start it again with `cd /home/ubuntu/workspace && sudo docker compose up -d`.

## Upgrade

After you change `compose.yaml` (for example to pick up a newer version of this Launchable), recreate the containers so every change takes effect; a change to an embedded configuration file alone does not recreate a container:

```
cd /home/ubuntu/workspace && sudo docker compose up -d --force-recreate
```

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md). Setup log: `sudo cat /var/log/brev-workspace.log`.

## Acceptable use and safety

The agent runs the code it writes inside the `agent` and `jupyter` containers, with access to the workspace folder and the internet. Review notebooks before you share results, and do not paste credentials into prompts.

## Skills

See [docs/skills.md](docs/skills.md) for the installed skills and how to add your own.

Current versions: vLLM v0.27.1; NVIDIA Nemotron 3.5 Lightning 30B-A3B NVFP4 (revision bee7596271d1495f6992ae224aefde4410e816b8); RAPIDS 26.10 (rapidsai/notebooks:26.10-cuda12-py3.12); XGBoost 3.4.2 CUDA; Hermes Agent v0.23.2 (ae2a81ccc00e9b7c06301523e5bb09608397149c) installed with uv 0.13.5; NVIDIA Agent Skills at commit e8f43c17b6ed0e8888ad21a447f63b0617849f71.

Last smoke: 2026-11-19 (fresh deploy on 1x L40S; stop and start checked).

## Credits and licences

- NVIDIA RAPIDS: Apache-2.0.
- NVIDIA Nemotron 3.5 Lightning: OpenMDW-1.1.
- NVIDIA Agent Skills: Apache-2.0 and CC-BY-4.0.
- Hermes Agent by Nous Research: MIT.
- vLLM: Apache-2.0.
- This repository: Apache-2.0 (see LICENSE).
