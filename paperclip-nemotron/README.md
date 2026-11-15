# Paperclip Multi-Agent Team on Nemotron

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8bFcmnzaZcFNHTjlLhZ2VVlaA)

Launchable ID: env-3M8bFcmnzaZcFNHTjlLhZ2VVlaA

Run a team of AI agents on your own GPU. [Paperclip](https://github.com/paperclipai/paperclip) is an open-source agent orchestration app: you set up a company with an org chart, goals and tickets, and the agents work through them. Here every agent thinks with an NVIDIA Nemotron model that [vLLM](https://github.com/vllm-project/vllm) serves on the same instance, so no external model API key is needed.

## What it runs

| Component | Version | Image |
| --- | --- | --- |
| Paperclip (UI, API, embedded PostgreSQL) | v2026.1106.0 (pinned) | `ghcr.io/paperclipai/paperclip:2026.1106.0` |
| vLLM (OpenAI-compatible server) | v0.27.1 (pinned by digest) | `vllm/vllm-openai:v0.27.1` |

Current versions: Paperclip v2026.1106.0, vLLM v0.27.1, default model nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4.

Last smoke: 2026-11-15, fresh deploy on one NVIDIA L40S 48GB, including stop and start.

Paperclip serves its web UI on port 3100. Open it only through the open-paperclip Secure Link, which requires a Brev sign-in; do not open port 3100 in the instance firewall. The vLLM API has no API key and is bound to the instance itself (127.0.0.1:8000), so it is not reachable from outside the instance. Paperclip's agents reach it through the OpenCode adapter, where the model is always named `vllm-local/agent-model`.

## Pick a model

Set the `MODEL` launch parameter when you deploy:

- `nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4` (default)
- `nvidia/NVIDIA-Nemotron-3-Nano-30B-A3B-FP8`
- `Qwen/Qwen3-30B-A3B-Instruct-2507-FP8`

`MAX_MODEL_LEN` sets the context length (32768, 65536 or 131072 tokens; default 65536). Agents with long tickets benefit from more context; it uses more GPU memory.

The model is downloaded once on first start and loaded from the local cache after that. To change the model, deploy again with a different `MODEL`.

## Hugging Face token

`HF_TOKEN` is optional. The listed models are not gated; a token only raises Hugging Face download limits. On the deploy page you can bind a saved secret or paste a read token. Never put a token anywhere except this parameter.

## Minimum GPU

NVIDIA L40S 48GB for the default model, with 200 GiB of disk for the container images and the model cache. The other model choices are larger downloads; check each model card for the GPUs it supports.

## First run

1. Deploy and wait until the instance is Running. The first start downloads the model, so allow extra time.
2. Open the open-paperclip link and sign in or sign up on Paperclip's login page. See Paperclip's deployment modes guide (https://github.com/paperclipai/paperclip/blob/v2026.1106.0/docs/deploy/deployment-modes.md) for how authenticated mode handles the first user.
3. If Paperclip answers that the hostname is not allowed, add the link's host name (for example `name.example.com`, without `https://`) to the allow list and restart Paperclip:

   ```
   brev shell INSTANCE_NAME
   echo name.example.com | sudo tee -a ~/workspace/paperclip/allowed-hostnames.txt
   docker restart paperclip
   ```

4. Create a company and give it a goal.
5. Hire a CEO agent. Choose the OpenCode adapter and enter `vllm-local/agent-model` as its model; this is the model served on the instance.
6. Hire more agents the same way, for example an engineer and a researcher reporting to the CEO, and watch the agent team pick up tickets.

To call the OpenAI-compatible API from your own machine, forward the port with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 8000:8000
curl http://localhost:8000/v1/models
```

## Security

Paperclip runs in authenticated mode with private exposure: every user signs in to Paperclip, and requests for host names not on its allow list are refused. Its session and tool-signing secrets are generated on the instance at first boot and stored in `~/workspace/paperclip/.deploy-secrets.env`, readable only by its owner; they are never part of this repository. Agents run tools inside the Paperclip container with access to `~/workspace/paperclip`.

## How data persists

- Paperclip data (database, agent workspaces, uploads): `/home/ubuntu/workspace/paperclip`
- Models (Hugging Face cache): `/home/ubuntu/workspace/huggingface`

They survive a stop and start of the instance. They are removed when the instance is deleted.

## Stop or delete to control cost

- **Stop** the instance from the Brev console when you are not using it. Your company, agents and models are kept, and both containers are recreated on the next start (see Stop and start). Storage is still billed while the instance is stopped.
- **Delete** the instance when you are finished. This removes the instance and all of its data.

## Stop and start

Stopping the instance removes the Paperclip and vLLM containers; everything under ~/workspace is kept. Starting it again recreates the containers automatically, usually within a few minutes. If Paperclip is not back after 5 minutes, open a terminal on the instance and run:

```
cd /home/ubuntu/workspace && sudo docker compose up -d
```

## Licences

- Paperclip: MIT. The Paperclip image also installs third-party agent CLIs (OpenCode, Claude Code, Codex, Gemini CLI, Kimi Code), each under its own licence and terms.
- vLLM: Apache-2.0.
- NVIDIA Nemotron 3.5 Lightning 30B-A3B: OpenMDW License Agreement, version 1.1 (https://openmdw.ai/license/1-1/).
- NVIDIA Nemotron 3 Nano 30B-A3B: NVIDIA Nemotron Open Model License (https://www.nvidia.com/en-us/agreements/enterprise-software/nvidia-nemotron-open-model-license/). Licensed by NVIDIA Corporation under the NVIDIA Nemotron Model License.
- Qwen3-30B-A3B-Instruct-2507: Apache-2.0.

Each model is downloaded from Hugging Face under its own licence. Read the model card before use.

## Files

- `compose.yaml` - the stack, every image pinned.
- `LICENSE` - Apache-2.0 for the files in this folder, with upstream attributions.
