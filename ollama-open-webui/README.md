<p align="center">
  <strong>Ollama + Open WebUI on NVIDIA Brev</strong><br>
  A private chat assistant on one NVIDIA L4: Ollama serves open-weight models and Open WebUI is the browser chat interface.
</p>

# Ollama + Open WebUI starter

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M6T0t4dhogSr5ruwzfHUvkBAVN)

Launchable ID: env-3M6T0t4dhogSr5ruwzfHUvkBAVN

A private, self-hosted chat assistant on your own GPU. [Ollama](https://github.com/ollama/ollama) serves open-weight language models and [Open WebUI](https://github.com/open-webui/open-webui) is the browser chat interface, started together with Docker Compose on one NVIDIA L4 24GB GPU. On first start it downloads the model you choose (gpt-oss:20b by default), so the chat is ready as soon as the download finishes. First step: deploy, open the chat-in-open-webui link, create your account and ask a question.

| Quick facts | |
| --- | --- |
| Runs | Ollama 0.40.16 and Open WebUI v0.13.3, two containers under Docker Compose, plus a one-time model download |
| Default compute | 1x NVIDIA L4 24GB on GCP (g2-standard-4), stoppable; you can pick another GPU on the deploy page |
| Disk | 64 GiB |
| Ready in | about 14 minutes on a fresh deploy (2026-11-15) |
| Cost | about $0.85/hr on the default compute (console, 2026-11-15); storage is billed while stopped |
| Secrets | none; the only launch parameter is MODEL |
| Licences | Ollama MIT License, Open WebUI License; each model under its own licence |
| Guide | https://www.9owls.com/launchables/ollama-open-webui/ |

Current versions: Ollama 0.40.16 (ollama/ollama:0.40.16), Open WebUI v0.13.3 (ghcr.io/open-webui/open-webui:v0.13.3)

Last smoke: 2026-11-15, fresh deploy on one NVIDIA L4 24GB with gpt-oss:20b. Open WebUI was ready about 14 minutes after launch.

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

| Component | Version | Image |
| --- | --- | --- |
| Ollama | 0.40.16 (pinned) | `ollama/ollama:0.40.16` |
| Open WebUI | v0.13.3 (pinned) | `ghcr.io/open-webui/open-webui:v0.13.3` |
| Model download | the MODEL you pick, pulled once on first start | `ollama/ollama:0.40.16` (one-shot `ollama-pull` service) |
| Stack definition | Docker Compose | [compose.yaml](compose.yaml) in this folder |

## Deploy in three steps

1. Click Launch on Brev, keep the NVIDIA L4 or pick another GPU, choose a MODEL (or keep gpt-oss:20b), and deploy.
2. Wait until the instance shows Running and the **chat-in-open-webui** link loads Open WebUI. On a fresh deploy this took about 14 minutes, most of it the model download.
3. Click **chat-in-open-webui**, create your account on the Open WebUI sign-up page, and start a chat with the model you picked.

## Try it first

- Ask a short question to warm up the model, for example: `Explain in three sentences what a GPU does that a CPU does not.` The first answer can take a couple of minutes while the model loads into GPU memory; later answers are fast.
- Paste a page of your own text and ask: `Summarize this in five bullet points.` The text is processed by Ollama on your instance.
- Pull a second model from the Open WebUI model settings (for example `qwen3:14b` or `gemma3:12b`) and switch between models in the model picker at the top of the chat.

## How it works

- Two long-running containers, started with Docker Compose from pinned images: `ollama` (serves the model on the GPU) and `open-webui` (the chat interface).
- A one-shot `ollama-pull` container downloads the MODEL you chose once, after Ollama is healthy. Open WebUI uses that model as its default.
- Open WebUI listens on port 8080 and is reached through the authenticated Brev Secure Link **chat-in-open-webui**.
- The Ollama API listens on port 11434 bound to the instance itself (localhost only) and is not exposed publicly.
- Both long-running containers use `restart: unless-stopped`, so they come back after a stop and start without re-entering the launch parameter.

<details>
<summary>Advanced: model memory and tool calling</summary>

GPU memory measured at Ollama's default context length: gpt-oss:20b about 16.3 GiB and gemma3:12b about 18.3 GiB, both within the 24 GB of an NVIDIA L4. A longer context or several chats at once raises memory use.

Open WebUI is preset to prompt-based tool calling (`DEFAULT_MODEL_PARAMS` with `"function_calling":"legacy"`) so every model in the list answers, including models without native tool calling. You can change this per model in the Open WebUI settings.

</details>

## Settings

| Parameter | Required | Default | What it does |
| --- | --- | --- | --- |
| MODEL | No | `gpt-oss:20b` | Ollama model pulled on first start and set as the Open WebUI default. Choices: `gpt-oss:20b` (14GB download), `qwen3:14b` (9.3GB), `gemma3:12b` (8.2GB). |

The model is pulled once on first start. You can pull more models later from the Open WebUI model settings.

## Use it from your machine

To reach Open WebUI or the Ollama API without the browser link, forward the ports with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 8080:8080
brev port-forward INSTANCE_NAME --port 11434:11434
```

Then open http://localhost:8080 for Open WebUI, or call the Ollama API at http://localhost:11434 (for example `curl http://localhost:11434/api/tags` lists the downloaded models).

## Data and persistence

Models and chats live on the instance, under `~/workspace/ollama` and `~/workspace/open-webui` (on disk: `/home/ubuntu/workspace/ollama` and `/home/ubuntu/workspace/open-webui`). They survive a stop and start of the instance, and the model is not downloaded again. They are removed when the instance is deleted.

## Stop, start and delete

- **Stop** the instance from the Brev console when you are not using it. Your models and chats are kept, and the containers start again on the next start. Storage is still billed while the instance is stopped.
- **Start** it again: Ollama and Open WebUI come back by themselves, with the same models, accounts and chats. If they are not back after 5 minutes, use the recovery command under Troubleshooting.
- **Delete** the instance when you are finished. This removes the instance and all of its data, including downloaded models and chat history.

## Troubleshooting

<details>
<summary>The chat-in-open-webui link does not load right after deploy</summary>

Open WebUI starts after Ollama is healthy, and the first start also downloads the model (about 14 GB for gpt-oss:20b). On a fresh deploy the whole stack was ready in about 14 minutes. Wait, then reload the link.

</details>

<details>
<summary>The first answer takes a long time</summary>

The first request loads the model into GPU memory, which took about two minutes for gpt-oss:20b on an NVIDIA L4. Later answers start quickly while the model stays loaded.

</details>

<details>
<summary>The model is missing from the model picker</summary>

The download may still be running. Check it from a terminal on the instance (`brev shell INSTANCE_NAME`):

```
cd /home/ubuntu/workspace && sudo docker compose logs ollama-pull
```

You can also pull the model again from the Open WebUI model settings.

</details>

<details>
<summary>Open WebUI is not back after a stop and start</summary>

Your models and chats under `/home/ubuntu/workspace` are kept. If Open WebUI is not back after 5 minutes, open a terminal on the instance and run:

```
cd /home/ubuntu/workspace && sudo docker compose up -d
```

</details>

## FAQ

### Which GPU do I need?

The default is one NVIDIA L4 24GB with 64 GiB of disk. The default model gpt-oss:20b uses about 16 GiB of GPU memory at Ollama's default context length, so a GPU with 24 GB fits each of the offered models comfortably.

### Which model should I pick?

gpt-oss:20b is the default and the model this Launchable was tested with. qwen3:14b and gemma3:12b are smaller downloads. You can add any of them later from the Open WebUI model settings without redeploying.

### Does anything leave the instance?

Ollama runs the model on your instance's GPU, so prompts and answers are processed there, and chats are stored under `/home/ubuntu/workspace/open-webui`. The instance downloads the container images and the model at first start.

### Can I run this on my own hardware?

Yes. The stack is the public [Ollama](https://github.com/ollama/ollama) and [Open WebUI](https://github.com/open-webui/open-webui) images plus the [compose.yaml](compose.yaml) in this folder. Change the `/home/ubuntu/workspace` paths in it to folders on your machine, and make sure the NVIDIA Container Toolkit is installed.

### How do I update to a newer version?

This Launchable pins Ollama 0.40.16 and Open WebUI v0.13.3 so every deploy is the same. To try newer releases on your own instance, change the image tags in the compose file under `/home/ubuntu/workspace` and run `sudo docker compose up -d`; your models and chats are kept.

## Guides and related Launchables

- Step-by-step guide: [How to run Ollama and Open WebUI on a cloud GPU](https://www.9owls.com/guides/run-ollama-and-open-webui-on-a-cloud-gpu/)
- [How to deploy a Launchable on NVIDIA Brev](https://www.9owls.com/guides/deploy-a-launchable-on-nvidia-brev/)
- [Ollama vs vLLM](https://www.9owls.com/compare/ollama-vs-vllm/): when Ollama suits one user and when vLLM suits many concurrent users
- [Run Open WebUI with vLLM on a cloud GPU](https://www.9owls.com/guides/run-open-webui-with-vllm-on-a-cloud-gpu/)
- [GPU memory for LLM inference compared](https://www.9owls.com/compare/nvidia-l4-vs-l40s-for-llm-inference/): how large a model fits on the NVIDIA L4
- [How to stop and delete an NVIDIA Brev instance](https://www.9owls.com/guides/stop-start-and-delete-an-nvidia-brev-instance/)
- [Brev Launchables FAQ](https://www.9owls.com/faq/brev-launchable-basics/): billing, persistence and choosing a GPU
- This Launchable on 9owls: https://www.9owls.com/launchables/ollama-open-webui/
- All Launchables by 9owls: https://www.9owls.com/launchables/
- Related: [Open WebUI + vLLM](https://www.9owls.com/launchables/open-webui-vllm/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M6reXdi0sY0m18g80JNRJN0WtE)); [Nemotron Chat with Open WebUI and vLLM](https://www.9owls.com/launchables/nemotron-chat/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aArulP2ZTX7HwqGLf4pwRT6z)); [Open Notebook on Nemotron](https://www.9owls.com/launchables/open-notebook-nemotron/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8a9DRg8X8LZyGjEtqCwWcjaYS))

## Keep your own stack running

NightKeeper packages your repository as an NVIDIA Brev Launchable, proves it on a fresh GPU and keeps it running. Your Brev API key stays in your repository's GitHub secrets. NightKeeper never sees it.

[Create your Launchable](https://www.9owls.com/nightkeeper/start/) or [read about NightKeeper](https://www.9owls.com/nightkeeper/).

## Credits and licences

- [Ollama](https://github.com/ollama/ollama): MIT License.
- [Open WebUI](https://github.com/open-webui/open-webui): Open WebUI License, see its [LICENSE](https://github.com/open-webui/open-webui/blob/main/LICENSE) for the terms, including its branding requirements.
- Models downloaded by Ollama are subject to the licence of each model.

Files in this folder: `compose.yaml` (the stack, images pinned by tag) and [LICENSE](LICENSE) (Apache License 2.0 for the files in this folder, with upstream attributions).

Published and maintained by [9owls, Inc.](https://www.9owls.com/). Questions: hello@9owls.com.
