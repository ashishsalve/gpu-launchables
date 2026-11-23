<p align="center">
  <strong>OpenHands on NVIDIA Brev</strong><br>
  Run the OpenHands coding agent on NVIDIA Nemotron 3.5 Lightning, served by vLLM on one NVIDIA L40S GPU, with no hosted model API.
</p>

# OpenHands Coding Agent on Nemotron

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8b2pM4xEhrOmr5yEObCVI7kyS)

Launchable ID: env-3M8b2pM4xEhrOmr5yEObCVI7kyS

A private AI software engineer on your own GPU. [OpenHands](https://github.com/OpenHands/OpenHands) is an open-source coding agent that writes, runs and fixes code. This NVIDIA Brev Launchable runs it next to [NVIDIA Nemotron 3.5 Lightning](https://huggingface.co/nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4), served on the same NVIDIA L40S instance by [vLLM](https://github.com/vllm-project/vllm) through an OpenAI-compatible API, so prompts are not sent to a hosted model API. Click Launch on Brev, and about 24 minutes later open the `open-openhands` link, point OpenHands at the local model and give it its first coding task.

| Quick facts | |
| --- | --- |
| Runs | OpenHands (Agent Canvas) + vLLM OpenAI-compatible server + NVIDIA Nemotron 3.5 Lightning 30B-A3B NVFP4 (local model) |
| Default compute | 1x NVIDIA L40S 48GB on AWS (g6e.xlarge); you can pick another GPU on the deploy page |
| Disk | 200 GiB |
| Ready in | about 24 minutes on a fresh deploy (2026-11-15) |
| Cost | about $2.23/hr on the default compute (console, 2026-11-15); storage is billed while stopped |
| Secrets | `HF_TOKEN` (optional Hugging Face read token, set at launch) |
| Licences | OpenHands: MIT; vLLM: Apache 2.0; Nemotron 3.5 Lightning: OpenMDW 1.1; Qwen3-Coder (option): Apache 2.0 |
| Guide | https://www.9owls.com/launchables/openhands-nemotron/ |

Current versions: OpenHands 1.40.0, vLLM v0.27.1, NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4 (default model)

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

| Component | Version | Image or file |
| --- | --- | --- |
| OpenHands (Agent Canvas) | 1.40.0 (pinned) | `ghcr.io/openhands/agent-canvas:1.40.0` |
| vLLM (OpenAI-compatible server) | v0.27.1 (pinned by digest) | `vllm/vllm-openai:v0.27.1` |
| NVIDIA Nemotron 3.5 Lightning 30B-A3B NVFP4 (default model) | downloaded from Hugging Face on first start | `nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4` |
| Qwen3-Coder 30B-A3B Instruct FP8 (option) | downloaded from Hugging Face on first start | `Qwen/Qwen3-Coder-30B-A3B-Instruct-FP8` |

## Deploy in three steps

1. Click **Launch on Brev**, keep the NVIDIA L40S or pick another GPU, keep or change `MODEL` and `MAX_MODEL_LEN`, optionally set `HF_TOKEN`, and deploy.
2. Wait until the instance shows Running and the `open-openhands` link answers. A fresh deploy took about 24 minutes, including the image pulls and the model download.
3. Open `open-openhands` (go to `/canvas` if the start page does not open it), enter the OpenHands API key, and set the model once in Settings, as described below.

Reading the API key and setting the model:

1. OpenHands asks for its API key. The key is generated on first start; read it on the instance (for example after `brev shell INSTANCE_NAME`) and paste it into the UI:

   ```
   docker exec $(docker ps --quiet --filter label=com.docker.compose.service=openhands) sh -c 'cat "$STATE_DIR/api-key.txt"'
   ```

   Keep this key private: anyone who has it and can reach the OpenHands link can run code on the instance.
2. Open Settings > LLM, switch to Advanced, and enter:
   - Custom model: `openai/coder`
   - Base URL: `http://vllm:8000/v1`
   - API key: any non-empty text, for example `local` (vLLM here does not check it)
3. Start a conversation. The first answer arrives once vLLM has finished loading the model; until then requests fail and can be retried.

The LLM setting is saved in `/home/ubuntu/workspace/openhands`, so you enter it once per instance.

## Try it first

Put the code you want the agent to work on in `/home/ubuntu/workspace/projects` on the instance; OpenHands sees it as `/projects`. Then start a conversation and paste one of these tasks:

1. "Create a folder /projects/hello with a Python function add(a, b), a pytest test for it, and run the test."
2. "Clone a small public Python project of your choice into /projects at a release tag, install it in a virtual environment and run its tests. Report which tests pass."

Review the commands OpenHands runs and the files it changes before you rely on them.

## How it works

- The Launchable defines one Brev Secure Link, `open-openhands`, for port 8000, the OpenHands UI. Port 8000 is published on all interfaces of the instance; access to OpenHands requires its API key.
- vLLM serves the model you pick under the fixed name `coder`. OpenHands reaches it inside the stack as `http://vllm:8000/v1`.
- The vLLM API is bound to the instance loopback interface only, on port 8001, and is not exposed publicly.
- The agent runs commands inside the OpenHands container, as the OpenHands user (uid 10001); it is not given the Docker socket and does not run in privileged mode.
- The model is downloaded once from Hugging Face on first start and loaded from the local cache after that.
- Both long-running services, `vllm` and `openhands`, run under Docker Compose with the `unless-stopped` restart policy. A one-shot `workspace-init` service prepares the OpenHands folders on first start.

<details>
<summary>Advanced: serving flags</summary>

Nemotron 3.5 Lightning is served with the model card's W4A16 serving flags and the `nemotron_v3` reasoning parser; Qwen3-Coder uses plain serving. Both use the `qwen3_coder` tool-call parser with automatic tool choice. Every model is served with `--max-num-seqs 16` and `--gpu-memory-utilization 0.90`. The full command is in `compose.yaml` in this folder.

</details>

## Settings

| Parameter | Required | Default | What it does |
| --- | --- | --- | --- |
| `MODEL` | no | `nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4` | Model vLLM serves to OpenHands as `coder`. The default is NVIDIA Nemotron 3.5 Lightning, 30B total and 3B active parameters, NVFP4 weights. The open alternative is `Qwen/Qwen3-Coder-30B-A3B-Instruct-FP8`, about a 31 GB download. |
| `MAX_MODEL_LEN` | no | `65536` | Context window in tokens: 65536, 32768 or 131072. OpenHands needs at least 22000 tokens; 32768 or more is recommended. A larger window uses more GPU memory. |
| `HF_TOKEN` | no | none | Optional Hugging Face read token. Both models are public; a token only avoids anonymous download limits. Choose "Use a secret" and pick a saved secret, or paste a read token. Never put a token anywhere except this parameter. |

To change the model, deploy again with a different `MODEL`.

## Use it from your machine

```
brev port-forward INSTANCE_NAME --port 8001:8001
curl http://localhost:8001/v1/models
```

The vLLM OpenAI-compatible API then answers on `http://localhost:8001/v1` with the model name `coder`, so any OpenAI-compatible client on your machine can use the local model.

## Data and persistence

- Models (Hugging Face cache): `/home/ubuntu/workspace/huggingface`
- OpenHands settings and conversations: `/home/ubuntu/workspace/openhands`
- Your projects: `/home/ubuntu/workspace/projects`

They survive a stop and start of the instance. They are removed when the instance is deleted.

Projects in `/home/ubuntu/workspace/projects` are owned by the OpenHands user (uid 10001); use sudo to edit them from the instance shell.

## Stop, start and delete

- **Stop** the instance from the Brev console when you are not using it. Your models, settings and projects are kept. Stopping the instance removes the OpenHands containers; everything under ~/workspace is kept. Storage is still billed while the instance is stopped.
- **Start** it again from the Brev console. Starting it recreates the containers automatically, without re-entering parameters or downloading the model again. In the last smoke, OpenHands and the model answered again about 18 minutes after Start. If OpenHands is not back after that, run `cd /home/ubuntu/workspace && sudo docker compose up -d`.
- **Delete** the instance when you are finished. This removes the instance and all of its data, including downloaded models and your projects. Push any work you want to keep to your own git remote first.

## Troubleshooting

<details>
<summary>Where are the logs?</summary>

- Setup log: `sudo cat /var/log/brev-workspace.log`
- Service logs: `cd /home/ubuntu/workspace && sudo docker compose logs --no-color vllm openhands`

</details>

<details>
<summary>OpenHands does not answer after a start</summary>

Open a terminal on the instance and run:

```
cd /home/ubuntu/workspace && sudo docker compose up -d
```

</details>

<details>
<summary>The agent does not answer yet</summary>

The first answer arrives once vLLM has finished loading the model; until then requests fail and can be retried. On a fresh deploy the model is downloaded first. When `curl http://localhost:8001/v1/models` on the instance lists `coder`, the model is ready.

</details>

<details>
<summary>OpenHands asks for an API key</summary>

This is expected. Read the key with the `docker exec` command in [Deploy in three steps](#deploy-in-three-steps) and paste it into the UI.

</details>

<details>
<summary>I cannot edit files in the projects folder from the shell</summary>

Projects are owned by the OpenHands user (uid 10001); use sudo to edit them from the instance shell.

</details>

## FAQ

### Which GPU do I need for OpenHands with Nemotron?

One NVIDIA L40S 48GB runs the default Nemotron 3.5 Lightning model with a 65536-token context; that is the default compute and the GPU used in the last smoke. A larger context window uses more GPU memory.

### Is the model local, or does OpenHands call a hosted API?

The model is local. vLLM serves it on the same GPU instance, OpenHands talks to it inside the stack, and prompts are not sent to a hosted model API. The model is downloaded from Hugging Face on first start, and the agent itself has network access inside its container.

### What can the agent do?

OpenHands writes, runs and fixes code. It executes the commands the model proposes inside its own container and works on the code in `/projects`. Start with the tasks in [Try it first](#try-it-first).

### What does it cost to leave it running?

The deploy page shows the hourly price of the GPU you pick. A running instance is billed by the hour; Stop it when you are not using it, and Delete it when you are finished, because storage is still billed while it is stopped.

### Where does my data live?

Under `/home/ubuntu/workspace` on the instance: the model cache, OpenHands settings and conversations, and your projects. It survives Stop and is removed by Delete.

### Can I run this on my own hardware?

Yes. OpenHands, vLLM and the model weights are open; see the [OpenHands repository](https://github.com/OpenHands/OpenHands) and the `compose.yaml` in this folder.

### How do I update to a newer version?

The images are pinned to the versions in "Current versions" above. To move to a newer release, deploy a new instance after this Launchable is updated, or edit the pins in `compose.yaml` on your own copy and test the result before relying on it.

## Acceptable use and safety

OpenHands executes the commands the model proposes inside its container, with network access. Review what it does, keep the OpenHands API key private, and do not give it credentials you would not hand to a new colleague. Use each model within the terms of its licence.

## Guides and related Launchables

- Step-by-step guide: [Run OpenHands with a local Nemotron model](https://www.9owls.com/guides/run-openhands-with-a-local-nemotron-model/)
- New to Launchables: [Deploy a Launchable on NVIDIA Brev](https://www.9owls.com/guides/deploy-a-launchable-on-nvidia-brev/)
- The model server: [Serve NVIDIA Nemotron with vLLM](https://www.9owls.com/guides/serve-nvidia-nemotron-with-vllm/) and [Serve an OpenAI-compatible API with vLLM](https://www.9owls.com/guides/serve-an-openai-compatible-api-with-vllm/)
- GPU choice: [NVIDIA L4 vs L40S for LLM inference](https://www.9owls.com/compare/nvidia-l4-vs-l40s-for-llm-inference/)
- Instance lifecycle: [Stop, start and delete an NVIDIA Brev instance](https://www.9owls.com/guides/stop-start-and-delete-an-nvidia-brev-instance/)
- This Launchable on 9owls: https://www.9owls.com/launchables/openhands-nemotron/
- All Launchables by 9owls: https://www.9owls.com/launchables/
- Related: [Paperclip Multi-Agent Team on Nemotron](https://www.9owls.com/launchables/paperclip-nemotron/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8bFcmnzaZcFNHTjlLhZ2VVlaA)); [Nemotron Chat with Open WebUI and vLLM](https://www.9owls.com/launchables/nemotron-chat/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aArulP2ZTX7HwqGLf4pwRT6z)); [Open WebUI + vLLM](https://www.9owls.com/launchables/open-webui-vllm/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M6reXdi0sY0m18g80JNRJN0WtE))

## Keep your own stack running

NightKeeper packages your repository as an NVIDIA Brev Launchable, proves it on a fresh GPU and keeps it running. Your Brev API key stays in your repository's GitHub secrets. NightKeeper never sees it.

[Create your Launchable](https://www.9owls.com/nightkeeper/start/) or [read about NightKeeper](https://www.9owls.com/nightkeeper/).

## Credits and licences

- OpenHands: MIT License.
- vLLM: Apache License 2.0.
- NVIDIA Nemotron 3.5 Lightning: governed by the OpenMDW License Agreement, version 1.1 (see the model card). By deploying with this model you accept its terms.
- Qwen3-Coder-30B-A3B-Instruct-FP8: Apache License 2.0.
- The files in this folder: `compose.yaml` (the stack, every image pinned) and `LICENSE` (Apache License 2.0 for the files in this folder, with upstream attributions); see [LICENSE](LICENSE).

Published and maintained by [9owls, Inc.](https://www.9owls.com/). Questions: hello@9owls.com.
