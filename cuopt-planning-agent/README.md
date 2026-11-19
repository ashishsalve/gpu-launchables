# cuOpt Planning Agent on Nemotron

Plan delivery routes and job schedules in plain English with NVIDIA cuOpt and a local NVIDIA Nemotron 3.5 Lightning model, served by vLLM, on one GPU. The planner gives the model a small set of solver tools, builds the cuOpt routing or scheduling request from the model's tool call, and shows the result on a map and a Gantt chart. The planner is configured to call the vLLM server on this instance; no hosted model API is configured.

Inspired by NVIDIA's cuOpt agent example (NVIDIA/cuopt-examples).

- Default compute: 1x NVIDIA L40S 48GB. The compose file gives vLLM 55 percent of GPU memory (`--gpu-memory-utilization 0.55`) and runs cuOpt on the same GPU.
- Default disk: 200 GiB.

## What you get

- **Planner page** on port 3000, configured as the Secure Link `open-planner`: a chat box, a map, a Gantt chart and a status strip that reports the health of the local model and of cuOpt.
- **NVIDIA cuOpt server** (HTTP API on port 5000 inside the compose network). The compose file attaches it only to the `solver` network, declared `internal: true`, which it shares with the planner. The compose file starts it after vLLM reports healthy.
- **NVIDIA Nemotron 3.5 Lightning** served by vLLM as `nemotron-planner` on localhost:8000 (OpenAI-compatible API).
- **Sample data**: a depot, 25 delivery stops, 3 vans of 40 crates and 12 jobs for 3 machines. All sample data is synthetic.

## Try these three tasks

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

Routing uses straight-line distances between stops at an average speed of 30 km/h; the map has no street basemap. `read_skill` reads five cuOpt skill files from NVIDIA/skills (pinned commit), fetched on first start as one source tarball and used only if its sha256 matches the pinned value.

The compose file publishes port 3000 for the Secure Link, binds vLLM to `127.0.0.1:8000` and publishes no port for cuOpt.

## Settings

| Parameter | Type | Required | Default | Meaning |
| --- | --- | --- | --- | --- |
| MODEL | Choice | no | nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4 | Model vLLM serves. |
| HF_TOKEN | Text | no | none | Optional Hugging Face read token. The model is public; a token only lifts anonymous download limits. Choose "Use a secret" and pick a saved Hugging Face secret (the option may be off for your account), or paste a read token. |

## Use the model API from your machine

```
brev port-forward <instance-name> --port 8000:8000
curl http://localhost:8000/v1/models
```

The planner sends `"max_tokens": 4096` with every request because vLLM serves the model with a reasoning parser; give your own requests a similar limit.

## Data and persistence

Everything lives under `/home/ubuntu/workspace/cuopt-planner` on the instance:

- `huggingface/` model download cache
- `samples/` the CSV files the planner uses (edit them to plan your own stops, vans or jobs)
- `plans/` every solved plan as JSON
- `vendor/` and `skills/` files fetched on first start

Brev keeps the instance disk when you Stop the instance and removes it when you Delete the instance.

## Stop and delete

- **Stop** pauses the instance. All three services are set to `restart: unless-stopped`; after Start, check the status strip and see [docs/troubleshooting.md](docs/troubleshooting.md) if a service is not `ok`.
- **Delete** removes the instance and everything on it.

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md). The deploy log is at `sudo cat /var/log/brev-workspace.log`.

## Acceptable use and safety

Plans are suggestions from a solver working on the data you give it. Check routes, times and loads before you act on them. The planner offers the model only the four tools listed above.

## Versions

Current versions: vLLM v0.27.1, Nemotron 3.5 Lightning 30B-A3B NVFP4, cuOpt 26.10.1, MapLibre GL JS 6.19.0, NVIDIA/skills e8f43c17.

Last smoke: not yet run

- vllm/vllm-openai v0.27.1 (pinned by digest)
- nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4 at revision bee7596271d1495f6992ae224aefde4410e816b8
- nvidia/cuopt 26.10.1-cuda12.9-py3.14 (pinned by digest)
- python 3.12.16-slim-bookworm (pinned by digest)
- maplibre-gl 6.19.0 (sha512 integrity checked)
- NVIDIA/skills at commit e8f43c17b6ed0e8888ad21a447f63b0617849f71 (source tarball sha256 2ea0fff7f84973fc0c5831942b1ba76e5402042d786695b37162183ddd932a2e)

## Credits and licences

- This repository: Apache-2.0 (see LICENSE).
- NVIDIA cuOpt: Apache-2.0.
- vLLM: Apache-2.0.
- NVIDIA Nemotron 3.5 Lightning: OpenMDW-1.1 (see the model card on Hugging Face).
- MapLibre GL JS: BSD-3-Clause.
- NVIDIA/skills: see that repository's licence.
- Inspired by NVIDIA's cuOpt agent example (NVIDIA/cuopt-examples).
