<p align="center">
  <strong>Paperclip on NVIDIA Brev</strong><br>
  Run a Paperclip multi-agent team on an NVIDIA Nemotron model served by vLLM on one NVIDIA L40S GPU, with no external model API key.
</p>

# Paperclip Multi-Agent Team on Nemotron

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8bFcmnzaZcFNHTjlLhZ2VVlaA)

Launchable ID: env-3M8bFcmnzaZcFNHTjlLhZ2VVlaA

Run a team of AI agents on your own GPU. [Paperclip](https://github.com/paperclipai/paperclip) is an open-source agent orchestration app: you set up a company with an org chart, goals and tickets, and the agents work through them. This NVIDIA Brev Launchable runs it next to an NVIDIA Nemotron model that [vLLM](https://github.com/vllm-project/vllm) serves on the same NVIDIA L40S instance, so no external model API key is needed. Click Launch on Brev, wait for the `open-paperclip` link, sign in, create a company and hire a CEO agent.

| Quick facts | |
| --- | --- |
| Runs | Paperclip (UI, API, embedded PostgreSQL) + vLLM OpenAI-compatible server + NVIDIA Nemotron 3.5 Lightning 30B-A3B NVFP4 (local model) |
| Default compute | 1x NVIDIA L40S 48GB on AWS; you can pick another GPU on the deploy page |
| Disk | 200 GiB |
| Ready in | 24 minutes or less on a fresh deploy (2026-11-15) |
| Cost | about $2.23/hr on the default compute (console, 2026-11-15); storage is billed while stopped |
| Secrets | `HF_TOKEN` (optional Hugging Face read token) |
| Licences | Paperclip: MIT; vLLM: Apache-2.0; Nemotron 3.5 Lightning: OpenMDW 1.1 |
| Guide | https://www.9owls.com/launchables/paperclip-nemotron/ |

Current versions: Paperclip v2026.1106.0, vLLM v0.27.1, default model nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4.

Last smoke: 2026-11-15, fresh deploy on one NVIDIA L40S 48GB, including stop and start.

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

| Component | Version | Image |
| --- | --- | --- |
| Paperclip (UI, API, embedded PostgreSQL) | v2026.1106.0 (pinned) | `ghcr.io/paperclipai/paperclip:2026.1106.0` |
| vLLM (OpenAI-compatible server) | v0.27.1 (pinned by digest) | `vllm/vllm-openai:v0.27.1` |
| NVIDIA Nemotron 3.5 Lightning 30B-A3B NVFP4 | default model | `nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4` from Hugging Face |

## Deploy in three steps

1. Click **Launch on Brev**, keep the NVIDIA L40S 48GB or pick another GPU, choose a `MODEL` if you want a different one, and deploy.
2. Wait until the instance shows Running and the `open-paperclip` link answers. The first start downloads the model, so allow extra time; a fresh deploy was ready in 24 minutes or less.
3. Click `open-paperclip` and sign in or sign up on Paperclip's login page. See Paperclip's [deployment modes guide](https://github.com/paperclipai/paperclip/blob/v2026.1106.0/docs/deploy/deployment-modes.md) for how authenticated mode handles the first user.

## Try it first

1. If Paperclip answers that the hostname is not allowed, add the link's host name (for example `name.example.com`, without `https://`) to the allow list and restart Paperclip:

   ```
   brev shell INSTANCE_NAME
   echo name.example.com | sudo tee -a ~/workspace/paperclip/allowed-hostnames.txt
   docker restart paperclip
   ```

2. Create a company and give it a goal.
3. Hire a CEO agent. Choose the OpenCode adapter and enter `vllm-local/agent-model` as its model; this is the model served on the instance.
4. Hire more agents the same way, for example an engineer and a researcher reporting to the CEO, and watch the agent team pick up tickets.

## How it works

- The Launchable defines one Brev Secure Link, `open-paperclip`, for port 3100, the Paperclip web UI. Open it only through the `open-paperclip` Secure Link, which requires a Brev sign-in; do not open port 3100 in the instance firewall.
- The vLLM API has no API key and is bound to the instance loopback only (`localhost:8000`), so it is not reachable from outside the instance.
- Paperclip's agents reach vLLM through the OpenCode adapter, where the model is always named `vllm-local/agent-model`, whatever `MODEL` you picked.
- Paperclip runs in authenticated mode with private exposure: every user signs in to Paperclip, and requests for host names not on its allow list are refused.
- Both services run under Docker Compose with the `unless-stopped` restart policy.

<details>
<summary>Advanced: Paperclip secrets and agent tools</summary>

Paperclip's session and tool-signing secrets are generated on the instance at first boot and stored in `~/workspace/paperclip/.deploy-secrets.env`, readable only by its owner; they are never part of this repository. Agents run tools inside the Paperclip container with access to `~/workspace/paperclip`.

</details>

## Settings

| Parameter | Required | Default | What it does |
| --- | --- | --- | --- |
| `MODEL` | no | `nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4` | The model vLLM serves for the agents. Choices: `nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4` (default), `nvidia/NVIDIA-Nemotron-3-Nano-30B-A3B-FP8`, `Qwen/Qwen3-30B-A3B-Instruct-2507-FP8`. |
| `MAX_MODEL_LEN` | no | `65536` | Context length in tokens: 32768, 65536 or 131072. Agents with long tickets benefit from more context; it uses more GPU memory. |
| `HF_TOKEN` | no | none | Optional Hugging Face read token. The listed models are not gated; a token only raises Hugging Face download limits. On the deploy page you can bind a saved secret or paste a read token. Never put a token anywhere except this parameter. |

The model is downloaded once on first start and loaded from the local cache after that. To change the model, deploy again with a different `MODEL`.

## Use it from your machine

```
brev port-forward INSTANCE_NAME --port 8000:8000
curl http://localhost:8000/v1/models
```

The vLLM OpenAI-compatible API then answers on `http://localhost:8000/v1` with the model name `agent-model`.

## Data and persistence

- Paperclip data (database, agent workspaces, uploads): `/home/ubuntu/workspace/paperclip`
- Models (Hugging Face cache): `/home/ubuntu/workspace/huggingface`

They survive a stop and start of the instance. They are removed when the instance is deleted.

## Stop, start and delete

- **Stop** the instance from the Brev console when you are not using it. Your company, agents and models are kept. Storage is still billed while the instance is stopped.
- **Start** it again from the Brev console. Stopping the instance removes the Paperclip and vLLM containers; everything under ~/workspace is kept. Starting it again recreates the containers automatically, usually within a few minutes. If Paperclip is not back after 5 minutes, open a terminal on the instance and run `cd /home/ubuntu/workspace && sudo docker compose up -d`.
- **Delete** the instance when you are finished. This removes the instance and all of its data.

## Troubleshooting

<details>
<summary>Paperclip says the hostname is not allowed</summary>

Add the Secure Link host name, without `https://`, to `~/workspace/paperclip/allowed-hostnames.txt` and run `docker restart paperclip`, as shown in [Try it first](#try-it-first).

</details>

<details>
<summary>Paperclip is not back after a start</summary>

Wait 5 minutes, then run `cd /home/ubuntu/workspace && sudo docker compose up -d`.

</details>

<details>
<summary>Agents do not answer yet</summary>

Agents can run once vLLM has loaded the model. On the first start the model is downloaded first. Check with `curl http://localhost:8000/v1/models` on the instance; it lists `agent-model` when the model is ready.

</details>

<details>
<summary>Where are the logs?</summary>

- Setup log: `sudo cat /var/log/brev-workspace.log`
- Service logs: `cd /home/ubuntu/workspace && sudo docker compose logs --no-color vllm paperclip`

</details>

## FAQ

### Which GPU do I need for Paperclip on Nemotron?

NVIDIA L40S 48GB for the default model, with 200 GiB of disk for the container images and the model cache. The other model choices are larger downloads; check each model card for the GPUs it supports.

### Does anything leave the instance?

The model runs on the instance: vLLM serves it on the same GPU and Paperclip's agents call it there, so no external model API key is set. The model is downloaded from Hugging Face on first start, and agents run tools inside the Paperclip container, which can reach the network when a task needs it.

### Can I run this on my own hardware?

Yes. Paperclip, vLLM and the model files are open; see the [Paperclip repository](https://github.com/paperclipai/paperclip) and the `compose.yaml` in this folder.

### How do I update to a newer version?

The images are pinned to the versions in "Current versions" above. To move to a newer release, deploy a new instance after this Launchable is updated, or edit the pins in `compose.yaml` on your own copy and test the result before relying on it.

## Acceptable use and safety

Paperclip's agents run tools inside the Paperclip container with access to `~/workspace/paperclip`. Review what they do, keep your Paperclip sign-in private, and do not give the agents credentials you would not hand to a new colleague. Use each model within the terms of its licence.

## Guides and related Launchables

- Step-by-step guide: [Run a Paperclip multi-agent team on Nemotron](https://www.9owls.com/guides/run-a-paperclip-multi-agent-team-on-nemotron/)
- Model server: [Serve NVIDIA Nemotron with vLLM](https://www.9owls.com/guides/serve-nvidia-nemotron-with-vllm/) and [Serve an OpenAI-compatible API with vLLM](https://www.9owls.com/guides/serve-an-openai-compatible-api-with-vllm/)
- New to Launchables: [Deploy a Launchable on NVIDIA Brev](https://www.9owls.com/guides/deploy-a-launchable-on-nvidia-brev/) and the [Brev Launchables FAQ](https://www.9owls.com/faq/brev-launchable-basics/)
- Instance lifecycle: [Stop, start and delete an NVIDIA Brev instance](https://www.9owls.com/guides/stop-start-and-delete-an-nvidia-brev-instance/)
- This Launchable on 9owls: https://www.9owls.com/launchables/paperclip-nemotron/
- All Launchables by 9owls: https://www.9owls.com/launchables/
- Related: [OpenHands on Nemotron](https://www.9owls.com/launchables/openhands-nemotron/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8b2pM4xEhrOmr5yEObCVI7kyS)); [Nemotron Chat](https://www.9owls.com/launchables/nemotron-chat/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aArulP2ZTX7HwqGLf4pwRT6z)); [Open Notebook on Nemotron](https://www.9owls.com/launchables/open-notebook-nemotron/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8a9DRg8X8LZyGjEtqCwWcjaYS))

## Keep your own stack running

NightKeeper packages your repository as an NVIDIA Brev Launchable, proves it on a fresh GPU and keeps it running. Your Brev API key stays in your repository's GitHub secrets. NightKeeper never sees it.

[Create your Launchable](https://www.9owls.com/nightkeeper/start/) or [read about NightKeeper](https://www.9owls.com/nightkeeper/).

## Credits and licences

- Paperclip: MIT. The Paperclip image also installs third-party agent CLIs (OpenCode, Claude Code, Codex, Gemini CLI, Kimi Code), each under its own licence and terms.
- vLLM: Apache-2.0.
- NVIDIA Nemotron 3.5 Lightning 30B-A3B: OpenMDW License Agreement, version 1.1 (https://openmdw.ai/license/1-1/).
- NVIDIA Nemotron 3 Nano 30B-A3B: NVIDIA Nemotron Open Model License (https://www.nvidia.com/en-us/agreements/enterprise-software/nvidia-nemotron-open-model-license/). Licensed by NVIDIA Corporation under the NVIDIA Nemotron Model License.
- Qwen3-30B-A3B-Instruct-2507: Apache-2.0.
- The files in this folder: Apache License 2.0; see [LICENSE](LICENSE).

Each model is downloaded from Hugging Face under its own licence. Read the model card before use.

Published and maintained by [9owls, Inc.](https://www.9owls.com/). Questions: hello@9owls.com.
