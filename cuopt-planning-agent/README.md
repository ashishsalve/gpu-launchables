<p align="center">
  <strong>cuOpt Planning Agent on NVIDIA Brev</strong><br>
  Plan delivery routes and job schedules in plain English with NVIDIA cuOpt and a local NVIDIA Nemotron 3.5 Lightning model, served by vLLM on one NVIDIA L40S GPU.
</p>

# cuOpt Planning Agent on Nemotron

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3MJZSZtBvP7HOHkxRYmvvjUoeUQ)

Launchable ID: env-3MJZSZtBvP7HOHkxRYmvvjUoeUQ

Plan delivery routes and job schedules in plain English with [NVIDIA cuOpt](https://github.com/NVIDIA/cuopt) and a local [NVIDIA Nemotron 3.5 Lightning](https://huggingface.co/nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4) model, served by [vLLM](https://github.com/vllm-project/vllm), on one GPU. The planner gives the model a small set of solver tools, builds the cuOpt routing or scheduling request from the model's tool call, and shows the routes and the job schedule as a table and a Gantt chart. The planner is configured to call the vLLM server on this instance; no hosted model API is configured. Click Launch on Brev, wait about 23 minutes, open the `open-planner` link and plan tomorrow's deliveries from the sample data.

| Quick facts | |
| --- | --- |
| Runs | NVIDIA cuOpt server + vLLM serving NVIDIA Nemotron 3.5 Lightning 30B-A3B NVFP4 (local model) + planner page with map and Gantt chart |
| Default compute | 1x NVIDIA L40S 48GB on AWS; you can pick another GPU on the deploy page |
| Disk | 256 GiB |
| Ready in | about 23 minutes on a fresh deploy (2026-11-19) |
| Cost | about $2.27/hr on the default compute including 256 GiB storage (console, 2026-11-19); storage is billed while stopped |
| Secrets | `HF_TOKEN` (optional Hugging Face read token) |
| Licences | NVIDIA cuOpt: Apache-2.0; vLLM: Apache-2.0; Nemotron 3.5 Lightning: OpenMDW-1.1; MapLibre GL JS: BSD-3-Clause |
| Guide | https://www.9owls.com/launchables/cuopt-planning-agent/ |

Default disk: 256 GiB; you can change the disk size on the deploy page.

Current versions: vLLM v0.27.1, Nemotron 3.5 Lightning 30B-A3B NVFP4, cuOpt 26.10.1, MapLibre GL JS 6.19.0, NVIDIA/skills e8f43c17.

Last smoke: 2026-11-19, fresh deploy on AWS g6e.xlarge (1x L40S): ready in about 23 minutes; services came back on their own after Stop and Start

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
| vLLM OpenAI-compatible server | v0.27.1 (pinned by digest) | `vllm/vllm-openai:v0.27.1` |
| NVIDIA Nemotron 3.5 Lightning 30B-A3B NVFP4 | revision `bee7596271d1495f6992ae224aefde4410e816b8` | `nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4` |
| NVIDIA cuOpt server | 26.10.1 (pinned by digest) | `nvidia/cuopt:26.10.1-cuda12.9-py3.14` |
| Planner base image | 3.12.16 (pinned by digest) | `python:3.12.16-slim-bookworm` |
| MapLibre GL JS | 6.19.0 (sha512 integrity checked) | `maplibre-gl` from registry.npmjs.org |
| NVIDIA/skills | commit `e8f43c17b6ed0e8888ad21a447f63b0617849f71` (source tarball sha256 `2ea0fff7f84973fc0c5831942b1ba76e5402042d786695b37162183ddd932a2e`) | five cuOpt `SKILL.md` files |

- **Planner page** on port 3000, configured as the Secure Link `open-planner`: a chat box, a map, a Gantt chart and a status strip that reports the health of the local model and of cuOpt. The map view needs a browser with WebGL2 support; the chat, the solves and the Gantt chart do not.
- **NVIDIA cuOpt server** (HTTP API on port 5000 inside the compose network). The compose file attaches it only to the `solver` network, declared `internal: true`, which it shares with the planner, so the cuOpt container has no internet access. The compose file starts it after vLLM reports healthy.
- **NVIDIA Nemotron 3.5 Lightning** served by vLLM as `nemotron-planner` on localhost:8000 (OpenAI-compatible API).
- **Sample data**: a depot, 25 delivery stops, 3 vans of 40 crates and 12 jobs for 3 machines. All sample data is synthetic.

## Deploy in three steps

1. Click **Launch on Brev**, keep the NVIDIA L40S or pick another GPU, optionally set `HF_TOKEN`, and deploy.
2. Wait until the instance shows Running and the `open-planner` link answers. A fresh deploy took about 23 minutes, most of it image pulls and the model download.
3. Click `open-planner`, wait until Model and cuOpt both show `ok` in the status strip, then click the Task 1 button.

## Try it first

Open the Secure Link `open-planner`, wait until Model and cuOpt both show `ok`, then click a task button or type:

1. `Plan tomorrow's deliveries from the sample CSV: 3 vans of 40 crates, depot opens 07:00 and closes 19:00, stop 12 only after 14:00.`
2. `Van 2 broke down at the depot. Re-plan with the other two vans.` The two remaining vans hold 80 crates and the stops need 100 crates in total.
3. `Schedule 12 jobs on 3 machines from the sample jobs table, minimize makespan, job 4 must finish before job 7 starts.`

Bonus: `What if demand grows 15 percent at every stop?`

**Solve without the agent**: the Routes, Van 2 down and Schedule buttons build the cuOpt requests directly from the sample CSV files, without calling the model. Use them to check the solver on its own.

## How it works

1. You type a request. The planner sends it to the local model with four tools: `solve_routing`, `solve_milp`, `get_sample_data` and `read_skill`.
2. When the model answers with a tool call, the planner checks every parameter (types and ranges) and builds the cuOpt request itself. The model is offered no tool for solver JSON, shell commands or code.
3. The planner posts the request to cuOpt (`/cuopt/request`), polls `/cuopt/solution/<id>`, draws the result and returns a summary to the model for its reply.

- The Launchable defines one Brev Secure Link, `open-planner`, for port 3000, the planner page.
- The compose file publishes port 3000 for the Secure Link, binds vLLM port 8000 to the instance loopback interface only and publishes no port for cuOpt.
- vLLM gets 55 percent of GPU memory (`--gpu-memory-utilization 0.55`) and cuOpt runs on the same GPU.
- All three services run under Docker Compose with `restart: unless-stopped`.

<details>
<summary>Advanced: distances, the map and the skill files</summary>

Routing uses straight-line distances between stops at an average speed of 30 km/h; the map has no street basemap. `read_skill` reads five cuOpt skill files from NVIDIA/skills (pinned commit), fetched on first start as one source tarball and used only if its sha256 matches the pinned value. MapLibre GL JS is downloaded from registry.npmjs.org on first start and used only if its sha512 matches the pinned value.

</details>

## Settings

| Parameter | Type | Required | Default | What it does |
| --- | --- | --- | --- | --- |
| `MODEL` | Choice | no | `nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4` | Model vLLM serves. |
| `HF_TOKEN` | Text | no | none | Optional Hugging Face read token. The model is public; a token only lifts anonymous download limits. Choose "Use a secret" and pick a saved Hugging Face secret (the option may be off for your account), or paste a read token. |

## Use it from your machine

```
brev port-forward INSTANCE_NAME --port 8000:8000
curl http://localhost:8000/v1/models
```

The vLLM OpenAI-compatible API then answers on `http://localhost:8000/v1` with the model name `nemotron-planner`. The planner sends `"max_tokens": 4096` with every request because vLLM serves the model with a reasoning parser; give your own requests a similar limit.

## Data and persistence

Everything lives under `/home/ubuntu/workspace/cuopt-planner` on the instance:

- `huggingface/` model download cache
- `samples/` the CSV files the planner uses (edit them to plan your own stops, vans or jobs)
- `plans/` every solved plan as JSON
- `vendor/` and `skills/` files fetched on first start

This folder survives Stop and Start: in the last smoke the saved plans, the skill files and the model cache were still there after Start, and the model was not downloaded again. Delete removes the instance and this folder.

## Stop, start and delete

- **Stop** the instance from the Brev console when you are not using it. The folder `/home/ubuntu/workspace/cuopt-planner` is kept. Storage is still billed while the instance is stopped.
- **Start** it again from the Brev console. All three services are set to `restart: unless-stopped`. In the last smoke all three services came back on their own after Start, about 7 minutes later, with no manual step. If a service is not `ok` in the status strip, see [docs/troubleshooting.md](docs/troubleshooting.md).
- **Delete** the instance when you are finished. This removes the instance and all of its data.

## Troubleshooting

The full guide, with the exact commands, is in [docs/troubleshooting.md](docs/troubleshooting.md).

<details>
<summary>Where are the logs?</summary>

- Deploy log: `sudo cat /var/log/brev-workspace.log`
- Service logs, in the folder Brev used for the compose project: `docker compose logs --no-color planner` (or `vllm`, `cuopt`)

</details>

<details>
<summary>The status strip says Model: loading</summary>

The first start downloads the model and loads it into vLLM. Follow it with `docker compose logs -f vllm`. vLLM is ready when `curl -s http://localhost:8000/v1/models` lists `nemotron-planner`.

</details>

<details>
<summary>The status strip says cuOpt: loading</summary>

The compose file starts cuOpt only after vLLM reports healthy. Check `docker compose logs --tail 100 cuopt` and `docker compose ps`. For an out-of-memory error, restart vLLM before cuOpt as described in [docs/troubleshooting.md](docs/troubleshooting.md).

</details>

<details>
<summary>The map stays empty</summary>

The map view draws with WebGL2. Without it the map stays empty while the chat, the solves and the Gantt chart keep working. Open the Secure Link in a browser with WebGL2 enabled.

</details>

<details>
<summary>The summary lists unserved stops</summary>

Compare the total demand with the van capacity. Add a van, raise the capacity or lower demand.

</details>

## FAQ

### Which GPU do I need for the cuOpt Planning Agent?

The default compute is one NVIDIA L40S 48GB, the GPU used in the last smoke. vLLM takes 55 percent of its memory and cuOpt runs on the same GPU.

### Does anything leave the instance?

The planner is configured to call the vLLM server on this instance; no hosted model API is configured. The cuOpt container sits on an internal network with no internet access. On first start the instance downloads the model from Hugging Face, MapLibre GL JS from registry.npmjs.org and the skill files from GitHub.

### Can I plan my own stops, vans or jobs?

Yes. Edit the CSV files in `/home/ubuntu/workspace/cuopt-planner/samples`. To restore the sample files, follow "Start over" in [docs/troubleshooting.md](docs/troubleshooting.md).

### Are the plans optimal?

Plans are suggestions from a solver working on the data you give it. A schedule solve stops after 20 seconds; when cuOpt has not proven the result optimal, the summary says it is the best found within that limit.

### Can I run this on my own hardware?

Yes. NVIDIA cuOpt, vLLM and the Nemotron 3.5 Lightning model are open; see the [cuOpt repository](https://github.com/NVIDIA/cuopt) and the `compose.yaml` in this folder.

### How do I update to a newer version?

The images, the model revision and the downloads are pinned to the versions in "Current versions" above. To move to a newer release, deploy a new instance after this Launchable is updated, or edit the pins in `compose.yaml` on your own copy and test the result before relying on it.

## Acceptable use and safety

Plans are suggestions from a solver working on the data you give it. Check routes, times and loads before you act on them. The planner offers the model only the four tools listed above. Use the model within the terms of its licence.

## Guides and related Launchables

- Step-by-step guide: [Plan routes and schedules with cuOpt and Nemotron](https://www.9owls.com/guides/plan-routes-and-schedules-with-cuopt-and-nemotron/)
- New to Launchables: [Deploy a Launchable on NVIDIA Brev](https://www.9owls.com/guides/deploy-a-launchable-on-nvidia-brev/)
- Other agents: [NVIDIA Brev agent Launchables](https://www.9owls.com/guides/nvidia-brev-agent-launchables/)
- Instance lifecycle: [Stop, start and delete an NVIDIA Brev instance](https://www.9owls.com/guides/stop-start-and-delete-an-nvidia-brev-instance/)
- This Launchable on 9owls: https://www.9owls.com/launchables/cuopt-planning-agent/
- All Launchables by 9owls: https://www.9owls.com/launchables/
- Related: [Nemotron Chat with Open WebUI and vLLM](https://www.9owls.com/launchables/nemotron-chat/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aArulP2ZTX7HwqGLf4pwRT6z)); [RAPIDS Data Science with cuDF and cuML](https://www.9owls.com/launchables/rapids-datascience/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aZ3FqwckUgj9tV7qQc9B3vVG)); [RAPIDS Data Science Agent with Hermes](https://www.9owls.com/launchables/rapids-data-science-agent/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3MK00FdEhqj8HhqutQYrm896chK))

## Keep your own stack running

NightKeeper packages your repository as an NVIDIA Brev Launchable, proves it on a fresh GPU and keeps it running. Your Brev API key stays in your repository's GitHub secrets. NightKeeper never sees it.

[Create your Launchable](https://www.9owls.com/nightkeeper/start/) or [read about NightKeeper](https://www.9owls.com/nightkeeper/).

## Credits and licences

- NVIDIA cuOpt: Apache-2.0.
- vLLM: Apache-2.0.
- NVIDIA Nemotron 3.5 Lightning: OpenMDW-1.1 (see the model card on Hugging Face). By deploying with this model you accept its terms.
- MapLibre GL JS: BSD-3-Clause.
- [NVIDIA/skills](https://github.com/NVIDIA/skills): see that repository's licence.
- Inspired by NVIDIA's cuOpt agent example ([NVIDIA/cuopt-examples](https://github.com/NVIDIA/cuopt-examples)).
- The files in this folder: Apache License 2.0; see [LICENSE](LICENSE).

Published and maintained by [9owls, Inc.](https://www.9owls.com/). Questions: hello@9owls.com.
