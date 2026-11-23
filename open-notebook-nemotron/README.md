<p align="center">
  <strong>Open Notebook on NVIDIA Brev</strong><br>
  A private research assistant on one NVIDIA L40S: chat with your PDFs and notes and turn them into a two-voice podcast, with NVIDIA Nemotron on vLLM and local speech by Speaches.
</p>

# Open Notebook on Nemotron

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8a9DRg8X8LZyGjEtqCwWcjaYS)

Launchable ID: env-3M8a9DRg8X8LZyGjEtqCwWcjaYS

A private research assistant on your own GPU. [Open Notebook](https://github.com/lfnovo/open-notebook) is an open-source alternative to NotebookLM: add PDFs, web pages and notes to a notebook, chat with your documents, search them, and turn them into a two-voice podcast. In this environment every model runs on one NVIDIA L40S 48GB on the instance itself: NVIDIA Nemotron on [vLLM](https://github.com/vllm-project/vllm) writes the answers and podcast scripts, NVIDIA Nemotron 3.5 Embed powers search, and [Speaches](https://github.com/speaches-ai/speaches) speaks and transcribes with Kokoro and faster-whisper. No cloud API key is needed. First step: deploy, open the open-notebook link, create a notebook and upload a PDF.

| Quick facts | |
| --- | --- |
| Runs | Open Notebook 1.15.1 with SurrealDB 2.7.0, vLLM 0.33.0 (chat and embeddings) and Speaches 0.8.3 (speech), eight services under Docker Compose |
| Default compute | 1x NVIDIA L40S 48GB on AWS (g6e.xlarge, 4 vCPU, 32 GiB RAM), stoppable; you can pick another GPU on the deploy page |
| Disk | 200 GiB |
| Ready in | about 28 minutes on a fresh deploy until the chat model answers; the web app loads after about 16 minutes (2026-11-15) |
| Cost | about $2.23/hr on the default compute (console, 2026-11-15); storage is billed while stopped |
| Secrets | optional `HF_TOKEN` and `OPEN_NOTEBOOK_PASSWORD` launch parameters; none is required |
| Licences | Open Notebook MIT, vLLM Apache-2.0, Speaches MIT, SurrealDB BSL 1.1, NVIDIA Nemotron Open Model License, OpenMDW-1.1 |
| Guide | https://www.9owls.com/launchables/open-notebook-nemotron/ |

Current versions: Open Notebook 1.15.1, vLLM 0.33.0, Speaches 0.8.3, SurrealDB 2.7.0

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

| Component | Version | Image |
| --- | --- | --- |
| Open Notebook (web app and API) | 1.15.1 (pinned) | `lfnovo/open_notebook:1.15.1` |
| SurrealDB (Open Notebook's database) | 2.7.0 (pinned) | `surrealdb/surrealdb:v2.7.0` |
| BusyBox (start helper for SurrealDB; copies itself once, then idles) | 1.37.0 (pinned) | `busybox:1.37.0-musl` |
| vLLM, chat model | 0.33.0 (pinned) | `vllm/vllm-openai:v0.33.0` |
| vLLM, embedding model | 0.33.0 (pinned) | `vllm/vllm-openai:v0.33.0` |
| Speaches (text-to-speech, speech-to-text) | 0.8.3 (pinned) | `ghcr.io/speaches-ai/speaches:0.8.3-cuda-12.6.3` |
| Setup helpers (run once) | 3.13.9 (pinned) | `python:3.13.9-slim` |

| Role | Model | Licence |
| --- | --- | --- |
| Chat, notes, podcast scripts (default) | `nvidia/NVIDIA-Nemotron-3-Nano-30B-A3B-FP8` | NVIDIA Nemotron Open Model License |
| Chat (option) | `Qwen/Qwen3-8B` | Apache-2.0 |
| Embeddings for search | `nvidia/Nemotron-3.5-Embed-1B-BF16` | OpenMDW-1.1 |
| Podcast voices | `speaches-ai/Kokoro-82M-v1.0-ONNX` (from `hexgrad/Kokoro-82M`) | Apache-2.0 (original model) |
| Speech to text | `Systran/faster-whisper-small` | MIT |

## Deploy in three steps

1. Click Launch on Brev, keep the NVIDIA L40S 48GB, optionally fill the settings, and deploy. None of the settings is required.
2. Wait until the instance shows Running and the open-notebook link loads Open Notebook. On a fresh deploy the web app loaded after about 16 minutes and the chat model answered after about 28 minutes, because the models download on first start.
3. Click **open-notebook**, create a notebook and add a source: upload a PDF, paste a web page link or write a note.

## Try it first

Every model is already registered and set as the default, so you can start as soon as the chat model has loaded.

1. Create a notebook, upload a PDF you know well, then ask in the chat: "Summarize the three main points of this source and quote the passage behind each one."
2. Add a web page link as a second source and ask: "Where do these two sources agree, and where do they differ?"
3. Open the podcast panel and generate an episode with the "Local podcast (Nemotron)" profile. Its two voices, Adam and Bella, are spoken by Kokoro on the same GPU.

## How it works

- Eight services run under Docker Compose: Open Notebook, SurrealDB, two vLLM servers, Speaches, and three helpers (init, tools, seed).
- Open Notebook listens on port 8502 and is reached through the Brev Secure Link **open-notebook**. Its API, the database, the embedding server and Speaches publish no port. The chat model API is bound to the instance itself on port 8000 (localhost only).
- The chat model, the embedding model and the speech models share the one GPU. Your documents, chats and podcasts are processed on the instance; no cloud model API is called.
- The database password is generated at random on first start and stored in `db-secrets/surreal-password` (readable by root only). No default password is used, and the password is never printed.
- On first start a setup helper downloads the speech models and registers every local model in Open Notebook, sets them as the defaults, and adds a podcast profile with two voices.

<details>
<summary>Advanced: the chat model settings</summary>

The chat model runs with reasoning output switched off so answers and podcast scripts come back directly. vLLM serves it with a 32768-token context and up to 16 parallel requests, and the embedding server starts first so the two vLLM processes do not measure GPU memory at the same time. Models download once on first start and load from the local cache after that.

</details>

## Settings

| Parameter | Required | Default | What it does |
| --- | --- | --- | --- |
| `MODEL` | no | `nvidia/NVIDIA-Nemotron-3-Nano-30B-A3B-FP8` | Chat model vLLM serves for notes, chat and podcast scripts. The default downloads about 33 GB; the option `Qwen/Qwen3-8B` about 16 GB. To change the model, deploy again with a different `MODEL`. |
| `HF_TOKEN` | no | none | Optional Hugging Face read token. None of the models is gated; a token only raises Hugging Face download rate limits. Bind a saved secret on the deploy page or paste a read token. Never put a token anywhere except this parameter. |
| `OPEN_NOTEBOOK_PASSWORD` | no | none | Optional password for the Open Notebook web app and API. Leave it empty to keep Open Notebook's own password off. Bind a saved secret on the deploy page or paste a value. |

Keep the Secure Link private; do not share it.

## Use it from your machine

To call the OpenAI-compatible chat API from your own machine, forward the port with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 8000:8000
curl http://localhost:8000/v1/models
```

The vLLM chat server then answers on http://localhost:8000/v1 with the model you chose in `MODEL`.

## Data and persistence

Everything lives under `/home/ubuntu/workspace/open-notebook` on the instance:

- Notebooks, sources, notes and podcasts: `notebook_data` and `surreal_data`
- Downloaded chat and embedding models: `huggingface`
- Speech models: `speaches`
- Database password and Open Notebook encryption key: `db-secrets` and `notebook_data/secrets` (keep them with the data)
- BusyBox start helper for the database: `tools`

They survive a stop and start of the instance. They are removed when the instance is deleted.

## Stop, start and delete

- **Stop** the instance from the Brev console when you are not using it. Your notebooks and models are kept, and the containers are recreated on the next start. Stopping can take up to 10 minutes. Storage is still billed while the instance is stopped.
- **Start** it again: the containers are recreated automatically, usually within a few minutes, and the settings you chose at deploy are kept. After a start the chat model answered again in about 9 minutes (2026-11-15). If Open Notebook is not back after 5 minutes, use the recovery command under Troubleshooting.
- **Delete** the instance when you are finished. This removes the instance and all of its data, including notebooks, podcasts and downloaded models.

## Troubleshooting

<details>
<summary>Open Notebook is not back after a stop and start</summary>

Stopping the instance removes the Open Notebook containers; everything under ~/workspace is kept. Starting it again recreates the containers automatically, usually within a few minutes. If Open Notebook is not back after 5 minutes, open a terminal on the instance and run:

```
cd /home/ubuntu/workspace && sudo docker compose up -d
```

</details>

<details>
<summary>The first chat answer takes a long time</summary>

The first chat answer can take a few minutes after the instance starts while the chat model loads. On a fresh deploy the chat model is downloaded first (about 33 GB for the default), so the web app can load before chat answers. Wait, then ask again.

</details>

<details>
<summary>Open Notebook asks for a password</summary>

This happens when `OPEN_NOTEBOOK_PASSWORD` was set on the deploy page. Enter that value. Leave the parameter empty on a new deploy to keep Open Notebook's own password off.

</details>

## FAQ

### Which GPU do I need?

The default is one NVIDIA L40S 48GB with 200 GiB of disk; the chat model, the embedding model and the speech models share that one GPU. The default Nemotron chat model needs a 48 GB GPU. The `Qwen/Qwen3-8B` option is a smaller download (about 16 GB).

### Do I need a Hugging Face token or a cloud API key?

No. None of the models is gated, so `HF_TOKEN` only raises Hugging Face download rate limits. Every model runs on the instance, so no cloud API key is needed.

### Does anything leave the instance?

Chat, search, podcast scripts, voices and transcription all run on models served on the instance. The instance downloads the container images and models on first start, and Open Notebook fetches a web page when you add its link as a source.

### Where does my data live?

Under `/home/ubuntu/workspace/open-notebook` on the instance. It survives Stop and is removed by Delete.

### Can I run this on my own hardware?

Yes. The stack is the public [Open Notebook](https://github.com/lfnovo/open-notebook) image plus the `compose.yaml` in this folder, which uses host paths under `/home/ubuntu/workspace/open-notebook` and one NVIDIA GPU. See the Open Notebook project for its own install options.

### How do I update to a newer version?

This Launchable pins every image so every deploy is the same. To try a newer release on your own instance, change the image tag in `compose.yaml` under `/home/ubuntu/workspace` and run `sudo docker compose up -d`; your data under `/home/ubuntu/workspace/open-notebook` is kept.

## Guides and related Launchables

- Step-by-step guide: [How to run Open Notebook, a self-hosted NotebookLM alternative](https://www.9owls.com/guides/run-open-notebook-a-self-hosted-notebooklm-alternative/)
- [How to deploy a Launchable on NVIDIA Brev](https://www.9owls.com/guides/deploy-a-launchable-on-nvidia-brev/)
- [Serve NVIDIA Nemotron with vLLM](https://www.9owls.com/guides/serve-nvidia-nemotron-with-vllm/)
- [Self-host RAGFlow with local models](https://www.9owls.com/guides/self-host-ragflow-with-local-models/)
- [How to stop and delete an NVIDIA Brev instance](https://www.9owls.com/guides/stop-start-and-delete-an-nvidia-brev-instance/)
- [Brev Launchables FAQ](https://www.9owls.com/faq/brev-launchable-basics/): billing, persistence and choosing a GPU
- This Launchable on 9owls: https://www.9owls.com/launchables/open-notebook-nemotron/
- All Launchables by 9owls: https://www.9owls.com/launchables/
- Related: [RAGFlow on your own GPU](https://www.9owls.com/launchables/ragflow/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M7Rp4TmPPfR0piWdfBqcHweyVl)); [RAGFlow RAG with NVIDIA Nemotron](https://www.9owls.com/launchables/ragflow-nemotron/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8amkBXTPnhVDHsznOXkc6jOf9)); [Nemotron Chat with Open WebUI and vLLM](https://www.9owls.com/launchables/nemotron-chat/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aArulP2ZTX7HwqGLf4pwRT6z))

## Keep your own stack running

NightKeeper packages your repository as an NVIDIA Brev Launchable, proves it on a fresh GPU and keeps it running. Your Brev API key stays in your repository's GitHub secrets. NightKeeper never sees it.

[Create your Launchable](https://www.9owls.com/nightkeeper/start/) or [read about NightKeeper](https://www.9owls.com/nightkeeper/).

## Credits and licences

The software and models above are downloaded at deploy time under their own licences. Read each model card before use.

- Licensed by NVIDIA Corporation under the NVIDIA Nemotron Model License. https://www.nvidia.com/en-us/agreements/enterprise-software/nvidia-nemotron-open-model-license/
- NVIDIA Nemotron 3.5 Embed is provided under the OpenMDW License Agreement, version 1.1: https://openmdw.ai/license/1-1/
- [Open Notebook](https://github.com/lfnovo/open-notebook) is MIT licensed. [Speaches](https://github.com/speaches-ai/speaches) is MIT licensed. [vLLM](https://github.com/vllm-project/vllm) is Apache-2.0 licensed. BusyBox is GPL-2.0 licensed.
- SurrealDB is licensed under the Business Source License 1.1 (see [LICENSE](LICENSE) for its Additional Use Grant).

NotebookLM is a product of Google. This project is not affiliated with or endorsed by Google.

Files in this folder: `compose.yaml` (the stack, every image pinned) and [LICENSE](LICENSE) (Apache License 2.0 for the files in this folder, with upstream attributions).

Published and maintained by [9owls, Inc.](https://www.9owls.com/). Questions: hello@9owls.com.
