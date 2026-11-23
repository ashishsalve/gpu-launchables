<p align="center">
  <strong>Nemotron Chat on NVIDIA Brev</strong><br>
  A private chat assistant on one NVIDIA L40S: vLLM serves NVIDIA Nemotron 3.5 Lightning and Open WebUI is the browser chat interface.
</p>

# Nemotron Chat with Open WebUI and vLLM

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aArulP2ZTX7HwqGLf4pwRT6z)

Launchable ID: env-3M8aArulP2ZTX7HwqGLf4pwRT6z

A private chat assistant on your own GPU, powered by NVIDIA Nemotron. [vLLM](https://github.com/vllm-project/vllm) serves [NVIDIA Nemotron 3.5 Lightning](https://huggingface.co/nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4) through an OpenAI-compatible API, and [Open WebUI](https://github.com/open-webui/open-webui) gives you the browser chat interface, started together with Docker Compose on one NVIDIA L40S 48GB GPU. Prompts are answered by the model on your instance; no third-party model API is called. First step: deploy, open the chat-with-nemotron link, create your admin account and start chatting once the model appears in the model picker.

| Quick facts | |
| --- | --- |
| Runs | vLLM v0.27.1 (OpenAI-compatible server) and Open WebUI v0.13.3, two containers under Docker Compose |
| Default compute | 1x NVIDIA L40S 48GB on AWS (g6e.xlarge), stoppable; you can pick another GPU with 48 GB or more on the deploy page |
| Disk | 200 GiB |
| Ready in | about 18 minutes on a fresh deploy (2026-11-15) |
| Cost | about $2.23/hr on the default compute (console, 2026-11-15); storage is billed while stopped |
| Secrets | `HF_TOKEN` (optional Hugging Face read token) |
| Licences | NVIDIA Nemotron 3.5 Lightning OpenMDW-1.1, Qwen3-8B Apache-2.0, vLLM Apache-2.0, Open WebUI License |
| Guide | https://www.9owls.com/launchables/nemotron-chat/ |

Current versions: vllm/vllm-openai:v0.27.1, ghcr.io/open-webui/open-webui:v0.13.3, default model nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4

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
- [Guides and related Launchables](#guides-and-related-launchables)
- [Keep your own stack running](#keep-your-own-stack-running)
- [Credits and licences](#credits-and-licences)

## What you get

| Component | Version | Image or file |
| --- | --- | --- |
| vLLM (OpenAI-compatible server) | v0.27.1 (pinned by digest) | `vllm/vllm-openai:v0.27.1` |
| Open WebUI | v0.13.3 (pinned) | `ghcr.io/open-webui/open-webui:v0.13.3` |
| NVIDIA Nemotron 3.5 Lightning (default model) | NVFP4 checkpoint, about a 25 GB download | `nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4` from Hugging Face |
| Qwen3-8B (launch option) | about a 16 GB download | `Qwen/Qwen3-8B` from Hugging Face |
| The stack | every image pinned | [compose.yaml](compose.yaml) in this folder |

## Deploy in three steps

1. Click Launch on Brev, keep the NVIDIA L40S or pick another GPU with 48 GB or more, choose a `MODEL` (or keep the default), optionally set `HF_TOKEN`, and deploy.
2. Wait until the instance shows Running and the **chat-with-nemotron** link answers. On a fresh deploy the whole stack was ready in about 18 minutes.
3. Open the **chat-with-nemotron** link. The first account you create becomes the Open WebUI admin, so create it right away. Wait for the model to appear in the model picker, then chat.

## Try it first

Paste one of these into a new chat once the model shows in the picker:

- A quick arithmetic check with reasoning: `What is 17 x 23? Show your reasoning.` Nemotron 3.5 Lightning reasons by default, so you see a reasoning trace before the answer.
- A longer task that uses the 65,536-token context of the default model: paste a long document and ask `Summarize this in five bullet points.`
- A call from your own machine to the OpenAI-compatible API with reasoning turned off: see [Use it from your machine](#use-it-from-your-machine).

## How it works

- Two containers, started with Docker Compose from the pinned images: `vllm` serves the model, `open-webui` is the chat interface.
- Open WebUI listens on port 8080 and is reached through the authenticated Brev Secure Link **chat-with-nemotron**.
- The vLLM API is bound to the instance itself on port 8000 and is not exposed publicly. Reach it with `brev port-forward`.
- The model is downloaded from Hugging Face once on first start and loaded from the local cache after that. The chat page opens before the download finishes; the model appears in the model picker once vLLM has loaded it.
- Prompts are answered by the model on your instance; no third-party model API is called.

<details>
<summary>Advanced: reasoning on or off</summary>

Each model has a reasoning mode that its chat template switches with `enable_thinking`; Nemotron 3.5 Lightning reasons by default. vLLM runs with the matching reasoning parser, so the reasoning trace comes back separately from the answer. For faster, shorter answers, turn reasoning off per request through the API with `"chat_template_kwargs": {"enable_thinking": false}` (see the example under Use it from your machine). With reasoning on, the trace counts toward `max_tokens`, so allow a generous output budget (for example 2048 or more) or the answer can be cut off before it starts.

The Nemotron 3.5 Lightning model card recommends temperature 1.0 and top_p 0.95, which this environment sets as the Open WebUI default.

</details>

<details>
<summary>Advanced: serving flags per model</summary>

The start script in `compose.yaml` picks the vLLM flags for the chosen `MODEL`, following each model card. Nemotron 3.5 Lightning NVFP4 uses the card's non-Blackwell recipe (humming MoE and linear backends, `modelopt_fp4`), reasoning parser `nemotron_v3` and tool parser `qwen3_coder`, with `--max-model-len 65536`. Qwen3-8B uses reasoning parser `qwen3` and tool parser `hermes`, with `--max-model-len 32768`. Every model runs with `--max-num-seqs 16` and `--gpu-memory-utilization 0.90`.

</details>

## Settings

| Parameter | Required | Default | What it does |
| --- | --- | --- | --- |
| `MODEL` | no | `nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4` | The Hugging Face model vLLM serves. Choices: the default NVIDIA Nemotron 3.5 Lightning, or `Qwen/Qwen3-8B`. |
| `HF_TOKEN` | no | none | Hugging Face read token. Every model offered here is ungated; a token only avoids anonymous download rate limits. |

Models you can pick with `MODEL`:

- `nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4` (default) - NVIDIA Nemotron 3.5 Lightning, a 30B-parameter hybrid Mamba-Transformer mixture-of-experts model with 3B active parameters, quantized to NVFP4. About a 25 GB download.
- `Qwen/Qwen3-8B` - an open alternative from the Qwen team. About a 16 GB download.

Both models are open on Hugging Face and need no access request. To change the model, deploy again with a different `MODEL`.

For `HF_TOKEN`, on the deploy page you can bind a saved secret or paste a read token. Never put a token anywhere except this parameter.

## Use it from your machine

To call the OpenAI-compatible API from your own machine, forward the port with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 8000:8000
curl http://localhost:8000/v1/models
curl http://localhost:8000/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4","messages":[{"role":"user","content":"Say hello"}],"chat_template_kwargs":{"enable_thinking":false}}'
```

The vLLM API then answers on http://localhost:8000/v1 locally. Use the `MODEL` value you deployed as the `model` field.

## Data and persistence

Models and chats live on the instance:

- Models (Hugging Face cache): `/home/ubuntu/workspace/huggingface`
- Chats, users and settings: `/home/ubuntu/workspace/open-webui`

They survive a stop and start of the instance. They are removed when the instance is deleted.

## Stop, start and delete

- **Stop** the instance from the Brev console when you are not using it. Your models and chats are kept. Storage is still billed while the instance is stopped.
- **Start** it again: both containers are recreated automatically, usually within a few minutes, and the model loads from the local cache. If Open WebUI is not back after 5 minutes, use the recovery command under Troubleshooting.
- **Delete** the instance when you are finished. This removes the instance and all of its data, including downloaded models and chat history.

## Troubleshooting

<details>
<summary>Open WebUI is not back after a stop and start</summary>

Stopping the instance removes the Open WebUI and vLLM containers; everything under ~/workspace is kept. Starting it again recreates the containers automatically, usually within a few minutes. If Open WebUI is not back after 5 minutes, open a terminal on the instance and run:

```
cd /home/ubuntu/workspace && sudo docker compose up -d
```

</details>

<details>
<summary>The chat page opens but no model is in the picker</summary>

The chat page opens before the model download finishes. The default model is about a 25 GB download on first start. Wait, then reload the page; the model appears once vLLM has loaded it. On a fresh deploy the whole stack was ready in about 18 minutes.

</details>

<details>
<summary>The answer is cut off or empty</summary>

With reasoning on, the reasoning trace counts toward `max_tokens`. Allow a generous output budget (for example 2048 or more), or turn reasoning off for the request with `"chat_template_kwargs": {"enable_thinking": false}`.

</details>

<details>
<summary>vLLM runs out of GPU memory on another GPU</summary>

The default model uses about 40 GB of GPU memory. If you change the instance type, pick a GPU with 48 GB or more.

</details>

## FAQ

### Which GPU do I need?

The default is one NVIDIA L40S 48GB with 200 GiB of disk for the container images and the model cache. The default model uses about 40 GB of GPU memory, so if you change the instance type, pick a GPU with 48 GB or more.

### Does anything leave the instance?

Prompts are answered by the model on your instance; no third-party model API is called. The instance downloads the container images and the model weights from Hugging Face on first start.

### Can I run this on my own hardware?

Yes, the stack is the public [vLLM](https://github.com/vllm-project/vllm) and [Open WebUI](https://github.com/open-webui/open-webui) images plus the `compose.yaml` in this folder. Read the [Nemotron 3.5 Lightning model card](https://huggingface.co/nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4) for its supported GPUs and vLLM settings.

### How do I update to a newer version?

This Launchable pins vLLM v0.27.1 by digest and Open WebUI v0.13.3 so every deploy is the same. To try newer releases on your own instance, change the image tags in `compose.yaml` under `/home/ubuntu/workspace` and run `sudo docker compose up -d`; your models and chats are kept.

## Guides and related Launchables

- Step-by-step guide: [Serve NVIDIA Nemotron with vLLM](https://www.9owls.com/guides/serve-nvidia-nemotron-with-vllm/)
- [Run Open WebUI with vLLM on a cloud GPU](https://www.9owls.com/guides/run-open-webui-with-vllm-on-a-cloud-gpu/)
- [Serve an OpenAI-compatible API with vLLM](https://www.9owls.com/guides/serve-an-openai-compatible-api-with-vllm/)
- [GPU memory and model fit for LLM inference](https://www.9owls.com/compare/nvidia-l4-vs-l40s-for-llm-inference/)
- [Ollama vs vLLM](https://www.9owls.com/compare/ollama-vs-vllm/)
- [How to deploy a Launchable on NVIDIA Brev](https://www.9owls.com/guides/deploy-a-launchable-on-nvidia-brev/)
- [How to stop and delete an NVIDIA Brev instance](https://www.9owls.com/guides/stop-start-and-delete-an-nvidia-brev-instance/)
- [Brev Launchables FAQ](https://www.9owls.com/faq/brev-launchable-basics/): billing, persistence and choosing a GPU
- This Launchable on 9owls: https://www.9owls.com/launchables/nemotron-chat/
- All Launchables by 9owls: https://www.9owls.com/launchables/
- Related: [Open WebUI + vLLM](https://www.9owls.com/launchables/open-webui-vllm/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M6reXdi0sY0m18g80JNRJN0WtE)); [Ollama + Open WebUI starter](https://www.9owls.com/launchables/ollama-open-webui/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M6T0t4dhogSr5ruwzfHUvkBAVN)); [OpenHands Coding Agent on Nemotron](https://www.9owls.com/launchables/openhands-nemotron/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8b2pM4xEhrOmr5yEObCVI7kyS))

## Keep your own stack running

NightKeeper packages your repository as an NVIDIA Brev Launchable, proves it on a fresh GPU and keeps it running. Your Brev API key stays in your repository's GitHub secrets. NightKeeper never sees it.

[Create your Launchable](https://www.9owls.com/nightkeeper/start/) or [read about NightKeeper](https://www.9owls.com/nightkeeper/).

## Credits and licences

- NVIDIA Nemotron 3.5 Lightning is made available by NVIDIA Corporation under the [OpenMDW License Agreement, version 1.1](https://openmdw.ai/license/1-1/).
- Qwen3-8B is licensed under Apache 2.0.
- [vLLM](https://github.com/vllm-project/vllm) is licensed under Apache 2.0.
- [Open WebUI](https://github.com/open-webui/open-webui) is distributed under the Open WebUI License; this environment keeps its branding unchanged.

The model weights are downloaded directly from Hugging Face; this environment does not redistribute them. Read each model card before use.

Files in this folder: `compose.yaml` (the stack, every image pinned) and [LICENSE](LICENSE) (Apache License 2.0 for the files in this folder, with upstream attributions).

Published and maintained by [9owls, Inc.](https://www.9owls.com/). Questions: hello@9owls.com.
