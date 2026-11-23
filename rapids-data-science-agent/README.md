<p align="center">
  <strong>RAPIDS Data Science Agent on NVIDIA Brev</strong><br>
  Ask a data question in plain English and Hermes Agent writes and runs a GPU notebook with NVIDIA RAPIDS cuDF, cuML and cuGraph, with a local NVIDIA Nemotron model on one NVIDIA L40S GPU.
</p>

# RAPIDS Data Science Agent with Hermes

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3MK00FdEhqj8HhqutQYrm896chK)

Launchable ID: env-3MK00FdEhqj8HhqutQYrm896chK

1x L40S 48GB, >= 48 GB VRAM | 200 GiB disk | ~$2.26/hr (console 2026-11-19) | ~30 min to ready | Stop to pause, Delete when done

Ask a data question in plain English and [Hermes Agent](https://github.com/NousResearch/hermes-agent), an open-source agent by Nous Research, writes and runs a GPU notebook for you with [NVIDIA RAPIDS](https://github.com/rapidsai) (cuDF, cuML and cuGraph), guided by [NVIDIA Agent Skills](https://github.com/NVIDIA/skills). The NVIDIA Nemotron 3.5 Lightning model runs on the same NVIDIA L40S GPU with [vLLM](https://github.com/vllm-project/vllm), so no hosted model key is used. Click Launch on Brev, wait about 30 minutes, open JupyterLab, run `agent` in a terminal and paste your first task.

| Quick facts | |
| --- | --- |
| Runs | JupyterLab on the RAPIDS image + Hermes Agent (terminal and web dashboard) + vLLM serving NVIDIA Nemotron 3.5 Lightning (local model) |
| Default compute | 1x NVIDIA L40S 48GB on AWS; you can pick another GPU on the deploy page |
| Disk | 200 GiB |
| Ready in | about 30 minutes on a fresh deploy (2026-11-19) |
| Cost | about $2.26/hr on the default compute (console, 2026-11-19); storage is billed while stopped |
| Secrets | `HF_TOKEN` (optional Hugging Face read token, set at launch) |
| Licences | RAPIDS: Apache-2.0; Nemotron 3.5 Lightning: OpenMDW-1.1; NVIDIA Agent Skills: Apache-2.0 and CC-BY-4.0; Hermes Agent: MIT; vLLM: Apache-2.0 |
| Guide | https://www.9owls.com/launchables/rapids-data-science-agent/ |

Current versions: vLLM v0.27.1; NVIDIA Nemotron 3.5 Lightning 30B-A3B NVFP4 (revision bee7596271d1495f6992ae224aefde4410e816b8); RAPIDS 26.10 (rapidsai/notebooks:26.10-cuda12-py3.12); XGBoost 3.4.2 CUDA; Hermes Agent v0.23.2 (ae2a81ccc00e9b7c06301523e5bb09608397149c) installed with uv 0.13.5; NVIDIA Agent Skills at commit e8f43c17b6ed0e8888ad21a447f63b0617849f71.

Last smoke: 2026-11-19 (fresh deploy on 1x L40S; stop and start checked).

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
- [Acceptable use and safety](#acceptable-use-and-safety)
- [Guides and related Launchables](#guides-and-related-launchables)
- [Keep your own stack running](#keep-your-own-stack-running)
- [Credits and licences](#credits-and-licences)

## What you get

| Component | Version | Image or file |
| --- | --- | --- |
| JupyterLab with NVIDIA RAPIDS (cuDF, cudf.pandas, cuDF-Polars, cuML, cuGraph) | RAPIDS 26.10 | `rapidsai/notebooks:26.10-cuda12-py3.12` |
| XGBoost with CUDA | 3.4.2 | installed into the RAPIDS image on first start |
| Hermes Agent (Nous Research), terminal command `agent` and web dashboard | v0.23.2 (ae2a81ccc00e9b7c06301523e5bb09608397149c), installed with uv 0.13.5 | pinned source archive |
| NVIDIA Agent Skills: cuDF, cuML and the NVIDIA skill finder | commit e8f43c17b6ed0e8888ad21a447f63b0617849f71 | pinned archive |
| Bundled skills: Polars GPU engine and cuGraph analytics | included in this folder | `compose.yaml` |
| vLLM model server, model name `nemotron` | v0.27.1 | `vllm/vllm-openai:v0.27.1` |
| NVIDIA Nemotron 3.5 Lightning 30B-A3B NVFP4 | revision bee7596271d1495f6992ae224aefde4410e816b8 | Hugging Face model |

## Deploy in three steps

1. Click **Launch on Brev**, keep the NVIDIA L40S or pick another GPU, keep the default settings (`HF_TOKEN` is optional), and deploy.
2. Wait until the instance shows Running and the `hermes` and `open-jupyterlab` links answer. A fresh deploy took about 30 minutes, most of it pulling images and downloading the model (about 18 GB).
3. Open the `open-jupyterlab` link. JupyterLab asks for its login key; read it in the Brev terminal with `sudo cat /home/ubuntu/workspace/rapids-data-science-agent/.jupyter-token`. Then open `START-HERE.md` in the `workspace` folder.

## Try it first

Open a terminal in JupyterLab (File > New > Terminal), run `agent`, and paste one of the tasks in [docs/tasks.md](docs/tasks.md):

1. Taxi trip analytics: pandas vs cudf.pandas vs Polars on CPU and GPU.
2. Tip prediction: scikit-learn vs cuML, XGBoost CPU vs CUDA.
3. A zone-to-zone trip graph with cuGraph (PageRank and Louvain communities).

Each task asks the agent to write a notebook into `workspace/notebooks/`, run it and print a results table. Review each notebook before you rely on its results.

## How it works

- `jupyter` serves JupyterLab on port 8888 for the Brev Secure Link `open-jupyterlab`.
- `agent` serves the Hermes dashboard on port 9119 for the Brev Secure Link `hermes`, behind a login (user `hermes`; read the generated password with `sudo cat /home/ubuntu/workspace/rapids-data-science-agent/hermes/dashboard-password`).
- `vllm` serves the model on the instance loopback only (localhost port 8001). Hermes reaches it at `http://vllm:8000/v1`.
- The model server and RAPIDS share the one GPU; `VLLM_GPU_MEMORY_UTILIZATION` sets the model's share.
- The agent can reach the internet, for example to download data.

<details>
<summary>Advanced: how the agent is installed</summary>

On first start the `agent` service installs Hermes Agent from a pinned source archive, with its Python dependencies taken from the project's lock file and checked by hash, then installs the listed skills. Hermes runs on its own Python 3.14, installed under the workspace; notebooks and the code the agent runs use the RAPIDS Python 3.12 environment, so `python` in the agent's commands imports cuDF. Its log ends with `agent-init: ready`.

</details>

<details>
<summary>Advanced: skills</summary>

The agent uses the NVIDIA Agent Skills for cuDF and cuML, the NVIDIA skill finder, and two bundled skills: `polars-gpu-engine` and `cugraph-analytics`. See [docs/skills.md](docs/skills.md) for the installed skills and how to add your own.

</details>

## Settings

| Parameter | Default | Required | What it does |
| --- | --- | --- | --- |
| MAX_MODEL_LEN | 65536 | no | Model context window in tokens. Hermes Agent needs at least 64000. |
| VLLM_GPU_MEMORY_UTILIZATION | 0.55 | no | Share of GPU memory for the model (`0.55` or `0.65`); the rest is for RAPIDS. |
| HF_TOKEN | none | no | Optional Hugging Face read token. Pick "Use a secret" to bind a saved Brev secret, or paste one. |

## Use it from your machine

```
brev port-forward INSTANCE_NAME --port 8001:8001
curl http://localhost:8001/v1/models
```

The vLLM OpenAI-compatible API then answers on `http://localhost:8001/v1` with the model name `nemotron`.

## Data and persistence

- Notebooks, data, the Hermes install, its configuration and skills: `/home/ubuntu/workspace/rapids-data-science-agent` (the `workspace` folder in JupyterLab).
- Model cache: `/home/ubuntu/workspace/huggingface`.

Brev keeps the workspace when you Stop the instance and removes it when you Delete it.

## Stop, start and delete

- **Stop** pauses the instance. Notebooks, data, the model cache and the agent install stay in the workspace folders above. Storage is still billed while the instance is stopped.
- **Start** it again from the Brev console. After a Start, if a service is not running, start it again with `cd /home/ubuntu/workspace && sudo docker compose up -d`.
- **Delete** removes the instance and all data.

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md) for the full list. Setup log: `sudo cat /var/log/brev-workspace.log`.

<details>
<summary>The links do not open yet</summary>

First start downloads two images, the model (about 18 GB) and the agent with its locked dependencies. Check progress with `cd /home/ubuntu/workspace && sudo docker compose ps`. `vllm` is ready when `curl -s http://localhost:8001/v1/models` lists `nemotron`. `agent` is ready when its log ends with `agent-init: ready`.

</details>

<details>
<summary>Services are not running after Start</summary>

Run `cd /home/ubuntu/workspace && sudo docker compose up -d`.

</details>

<details>
<summary>The agent command is not found</summary>

The agent service installs Hermes on first start. Wait for `agent-init: ready` in `sudo docker compose logs agent`, then open a new terminal.

</details>

<details>
<summary>GPU out of memory in a notebook</summary>

The model server and RAPIDS share the GPU. Read fewer columns, or process the data in chunks.

</details>

## FAQ

### Which GPU do I need?

One NVIDIA L40S 48GB, the default compute and the GPU used in the last smoke. The model server and the RAPIDS notebooks share that GPU.

### Does anything leave the instance?

The model runs on the instance, so no hosted model key is used and the model API listens on the instance only. The agent can reach the internet when a task asks it to, for example to download data.

### Can I run this on my own hardware?

The parts are open source: see [Hermes Agent](https://github.com/NousResearch/hermes-agent), [NVIDIA RAPIDS](https://github.com/rapidsai), [vLLM](https://github.com/vllm-project/vllm) and the `compose.yaml` in this folder.

### How do I update to a newer version?

The images, model and agent are pinned to the versions in "Current versions" above. After you change `compose.yaml` (for example to pick up a newer version of this Launchable), recreate the containers with `cd /home/ubuntu/workspace && sudo docker compose up -d --force-recreate`; a change to an embedded configuration file alone does not recreate a container.

## Acceptable use and safety

The agent runs the code it writes inside the `agent` and `jupyter` containers, with access to the workspace folder and the internet. Review notebooks before you share results, and do not paste credentials into prompts.

## Guides and related Launchables

- Step-by-step guide: [Run a GPU data science agent with Hermes and RAPIDS](https://www.9owls.com/guides/run-a-gpu-data-science-agent-with-hermes-and-rapids/)
- New to Launchables: [Deploy a Launchable on NVIDIA Brev](https://www.9owls.com/guides/deploy-a-launchable-on-nvidia-brev/)
- Model server: [Serve NVIDIA Nemotron with vLLM](https://www.9owls.com/guides/serve-nvidia-nemotron-with-vllm/)
- Other agents: [NVIDIA Brev agent Launchables](https://www.9owls.com/guides/nvidia-brev-agent-launchables/)
- Instance lifecycle: [Stop, start and delete an NVIDIA Brev instance](https://www.9owls.com/guides/stop-start-and-delete-an-nvidia-brev-instance/)
- This Launchable on 9owls: https://www.9owls.com/launchables/rapids-data-science-agent/
- All Launchables by 9owls: https://www.9owls.com/launchables/
- Related: [RAPIDS Data Science with cuDF and cuML](https://www.9owls.com/launchables/rapids-datascience/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aZ3FqwckUgj9tV7qQc9B3vVG)); [Nemotron Chat with Open WebUI and vLLM](https://www.9owls.com/launchables/nemotron-chat/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aArulP2ZTX7HwqGLf4pwRT6z)); [Open Notebook on Nemotron](https://www.9owls.com/launchables/open-notebook-nemotron/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8a9DRg8X8LZyGjEtqCwWcjaYS))

## Keep your own stack running

NightKeeper packages your repository as an NVIDIA Brev Launchable, proves it on a fresh GPU and keeps it running. Your Brev API key stays in your repository's GitHub secrets. NightKeeper never sees it.

[Create your Launchable](https://www.9owls.com/nightkeeper/start/) or [read about NightKeeper](https://www.9owls.com/nightkeeper/).

## Credits and licences

- NVIDIA RAPIDS: Apache-2.0.
- NVIDIA Nemotron 3.5 Lightning: OpenMDW-1.1.
- NVIDIA Agent Skills: Apache-2.0 and CC-BY-4.0.
- Hermes Agent by Nous Research: MIT.
- vLLM: Apache-2.0.
- The files in this folder: Apache License 2.0; see [LICENSE](LICENSE).

Published and maintained by [9owls, Inc.](https://www.9owls.com/). Questions: hello@9owls.com.
