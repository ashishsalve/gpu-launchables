# Open Notebook on Nemotron

A private research assistant on your own GPU. [Open Notebook](https://github.com/lfnovo/open-notebook) is an open-source alternative to NotebookLM: add PDFs, web pages and notes to a notebook, chat with your documents, search them, and turn them into a two-voice podcast. In this environment every model runs on the instance itself: NVIDIA Nemotron on [vLLM](https://github.com/vllm-project/vllm) writes the answers and podcast scripts, NVIDIA Nemotron 3.5 Embed powers search, and [Speaches](https://github.com/speaches-ai/speaches) speaks and transcribes with Kokoro and faster-whisper. No cloud API key is needed.

Current versions: Open Notebook 1.15.1, vLLM 0.33.0, Speaches 0.8.3, SurrealDB 2.7.0

Last smoke: not yet run

## What it runs

| Component | Version | Image |
| --- | --- | --- |
| Open Notebook (web app and API) | 1.15.1 (pinned) | `lfnovo/open_notebook:1.15.1` |
| SurrealDB (Open Notebook's database) | 2.7.0 (pinned) | `surrealdb/surrealdb:v2.7.0` |
| BusyBox (start helper for SurrealDB; copies itself once, then idles) | 1.37.0 (pinned) | `busybox:1.37.0-musl` |
| vLLM, chat model | 0.33.0 (pinned) | `vllm/vllm-openai:v0.33.0` |
| vLLM, embedding model | 0.33.0 (pinned) | `vllm/vllm-openai:v0.33.0` |
| Speaches (text-to-speech, speech-to-text) | 0.8.3 (pinned) | `ghcr.io/speaches-ai/speaches:0.8.3-cuda-12.6.3` |
| Setup helpers (run once) | 3.13.9 (pinned) | `python:3.13.9-slim` |

Open Notebook listens on port 8502. Its API, the database, the embedding server and Speaches publish no port. The chat model API is bound to the instance itself (127.0.0.1:8000).

The database password is generated at random on first start and stored in `db-secrets/surreal-password` (readable by root only). No default password is used, and the password is never printed.

On first start a setup helper downloads the speech models and registers every local model in Open Notebook, sets them as the defaults, and adds a podcast profile with two voices. You can start working as soon as the chat model has loaded.

## Models

| Role | Model | Licence |
| --- | --- | --- |
| Chat, notes, podcast scripts (default) | `nvidia/NVIDIA-Nemotron-3-Nano-30B-A3B-FP8` | NVIDIA Nemotron Open Model License |
| Chat (option) | `Qwen/Qwen3-8B` | Apache-2.0 |
| Embeddings for search | `nvidia/Nemotron-3.5-Embed-1B-BF16` | OpenMDW-1.1 |
| Podcast voices | `speaches-ai/Kokoro-82M-v1.0-ONNX` (from `hexgrad/Kokoro-82M`) | Apache-2.0 (original model) |
| Speech to text | `Systran/faster-whisper-small` | MIT |

Pick the chat model with the `MODEL` launch parameter. The default downloads about 33 GB, Qwen3-8B about 16 GB. Models download once on first start and load from the local cache after that. The chat model runs with reasoning output switched off so answers and podcast scripts come back directly. To change the model, deploy again with a different `MODEL`.

## Hugging Face token

`HF_TOKEN` is optional. None of the models above is gated; a token only raises Hugging Face download rate limits. On the deploy page you can bind a saved secret or paste a read token. Never put a token anywhere except this parameter.

## Password and access

`OPEN_NOTEBOOK_PASSWORD` is optional. Set it on the deploy page to require a password for the Open Notebook web app and API; leave it empty to keep Open Notebook's own password off. On the deploy page you can bind a saved secret or paste a value.

Keep the Secure Link private; do not share it.

## Default GPU

One NVIDIA L40S 48GB, with 200 GiB of disk for the container images and the model cache. The chat model, the embedding model and the speech models share the one GPU.

## Use it

1. Deploy and wait until the instance is Running.
2. Open the open-notebook link.
3. Create a notebook and add sources: upload a PDF, paste a web page link or write a note.
4. Chat with your documents, or open the podcast panel and generate an episode with the "Local podcast (Nemotron)" profile.

The first chat answer can take a few minutes after the instance starts while the chat model loads.

To call the OpenAI-compatible chat API from your own machine, forward the port with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 8000:8000
curl http://localhost:8000/v1/models
```

## How data persists

Everything lives under `/home/ubuntu/workspace/open-notebook` on the instance:

- Notebooks, sources, notes and podcasts: `notebook_data` and `surreal_data`
- Downloaded chat and embedding models: `huggingface`
- Speech models: `speaches`
- Database password and Open Notebook encryption key: `db-secrets` and `notebook_data/secrets` (keep them with the data)
- BusyBox start helper for the database: `tools`

They survive a stop and start of the instance. They are removed when the instance is deleted.

## Stop or delete to control cost

- **Stop** the instance from the Brev console when you are not using it. Your notebooks and models are kept, and the containers are recreated on the next start (see Stop and start). Storage is still billed while the instance is stopped.
- **Delete** the instance when you are finished. This removes the instance and all of its data, including notebooks, podcasts and downloaded models.

## Stop and start

Stopping the instance removes the Open Notebook containers; everything under ~/workspace is kept. Starting it again recreates the containers automatically, usually within a few minutes. If Open Notebook is not back after 5 minutes, open a terminal on the instance and run:

```
cd /home/ubuntu/workspace && sudo docker compose up -d
```

## Licences and notices

The files in this repository are licensed under Apache-2.0 (see `LICENSE`). The software and models above are downloaded at deploy time under their own licences. Read each model card before use.

- Licensed by NVIDIA Corporation under the NVIDIA Nemotron Model License. https://www.nvidia.com/en-us/agreements/enterprise-software/nvidia-nemotron-open-model-license/
- NVIDIA Nemotron 3.5 Embed is provided under the OpenMDW License Agreement, version 1.1: https://openmdw.ai/license/1-1/
- Open Notebook is MIT licensed. Speaches is MIT licensed. vLLM is Apache-2.0 licensed. BusyBox is GPL-2.0 licensed.
- SurrealDB is licensed under the Business Source License 1.1 (see `LICENSE` for its Additional Use Grant).

NotebookLM is a product of Google. This project is not affiliated with or endorsed by Google.

## Files

- `compose.yaml` - the stack, every image pinned.
- `LICENSE` - Apache-2.0 for the files in this folder, with upstream attributions.
