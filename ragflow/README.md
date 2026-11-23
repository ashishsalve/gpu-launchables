<p align="center">
  <strong>RAGFlow on NVIDIA Brev</strong><br>
  Chat with your documents on one NVIDIA L40S: RAGFlow 1.0 with local Qwen3 chat and embedding models served by vLLM and the Infinity engine.
</p>

# RAGFlow on your own GPU

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M7Rp4TmPPfR0piWdfBqcHweyVl)

Launchable ID: env-3M7Rp4TmPPfR0piWdfBqcHweyVl

Chat with your documents on your own GPU. [RAGFlow](https://github.com/infiniflow/ragflow) 1.0 runs with local models served by [vLLM](https://github.com/vllm-project/vllm): a Qwen3 chat model and the Qwen3 embedding model, with the [Infinity](https://github.com/infiniflow/infinity) vector engine, on one NVIDIA L40S 48GB GPU. Your documents, vectors and chats stay on the instance. First step: deploy, open RAGFlow from the open-ragflow link, connect the two local models once, then upload a document and ask it a question.

| Quick facts | |
| --- | --- |
| Runs | RAGFlow 1.0 web UI and API, two vLLM servers (chat and embeddings), Infinity, MySQL, Silo object store, Apache Kvrocks and NATS: eight services under Docker Compose |
| Default compute | 1x NVIDIA L40S 48GB on AWS (g6e.xlarge), stoppable; you can pick another GPU on the deploy page |
| Disk | 256 GiB |
| Ready in | about 22 minutes on a fresh deploy (2026-11-15) |
| Cost | about $2.23/hr on the default compute (console, 2026-11-15); storage is billed while stopped |
| Secrets | HF_TOKEN (optional); no default passwords |
| Licences | RAGFlow, Infinity, vLLM, Kvrocks and NATS Apache-2.0; Silo AGPL-3.0-or-later; MySQL GPL-2.0; Qwen3 models Apache-2.0 |
| Guide | https://www.9owls.com/launchables/ragflow/ |

Current versions: infiniflow/ragflow:v1.0.0, vllm/vllm-openai:v0.33.0, infiniflow/infinity:v0.7.5-x64-v3, mysql:8.0.40, pgsty/silo:RELEASE.2026-08-06T00-00-00Z, apache/kvrocks:2.16.0, nats:2.14.2

Last smoke: 2026-11-15, fresh deploy on one NVIDIA L40S 48GB. All eight services were up about 22 minutes after launch (most of it pulling the vLLM image); health, chat and embeddings all answered.

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
| RAGFlow web UI and API | 1.0.0 | `infiniflow/ragflow:v1.0.0` |
| vLLM chat server | 0.33.0 (CUDA 13.0 build) | `vllm/vllm-openai:v0.33.0` |
| vLLM embedding server | 0.33.0, same image | `vllm/vllm-openai:v0.33.0` |
| Infinity vector and full-text engine | 0.7.5 | `infiniflow/infinity:v0.7.5-x64-v3` |
| MySQL Community Server (metadata) | 8.0.40 | `mysql:8.0.40` |
| Silo object store (uploaded documents) | RELEASE.2026-08-06T00-00-00Z | `pgsty/silo:RELEASE.2026-08-06T00-00-00Z` |
| Apache Kvrocks (cache) | 2.16.0 | `apache/kvrocks:2.16.0` |
| NATS (task queue) | 2.14.2 | `nats:2.14.2` |
| Chat model (default) | Qwen/Qwen3-8B, revision b968826d9c46dd6066d109eabc6255188de91218 | Hugging Face |
| Chat model (24 GB GPUs) | Qwen/Qwen3-4B-Instruct-2507, revision cdbee75f17c01a7cc42f958dc650907174af0554 | Hugging Face |
| Embedding model | Qwen/Qwen3-Embedding-0.6B, revision 97b0c614be4d77ee51c0cef4e5f07c00f9eb65b3 | Hugging Face |
| Stack definition | every image pinned by version tag and digest | `compose.yaml` in this folder |

- Default instance: 1x NVIDIA L40S 48GB, stoppable. The deploy page shows the current hourly price.
- Minimum GPU: 40 GB VRAM for the default chat model (Qwen/Qwen3-8B). On a 24 GB GPU such as L4, launch with `MODEL=Qwen/Qwen3-4B-Instruct-2507`. Plan for at least 32 GB of system memory.
- One web UI behind a Brev Secure Link: **open-ragflow** (port 8080) - RAGFlow.
- Two OpenAI-compatible endpoints on the instance, not exposed to the internet: chat at `http://localhost:8000/v1` (model name = the `MODEL` value) and embeddings at `http://localhost:8001/v1` (model name `Qwen/Qwen3-Embedding-0.6B`).

## Deploy in three steps

1. Click Launch on Brev, keep the NVIDIA L40S or pick another GPU, keep `MODEL=Qwen/Qwen3-8B` (or choose `Qwen/Qwen3-4B-Instruct-2507` for a 24 GB GPU), optionally add HF_TOKEN, and deploy.
2. Wait until the instance shows Running and the open-ragflow link loads the RAGFlow sign-in page. A fresh deploy took about 22 minutes, most of it pulling the vLLM image and downloading the chat model. The models keep loading in the background; follow progress from a terminal on the instance with `docker logs -f ragflow-vllm-chat-1`. The chat model is ready when the log shows the server listening on port 8000.
3. Click **open-ragflow**, register an account on the sign-in page, and connect the local models as shown in Try it first. The first account you register is yours; the page is reachable only through your Brev login.

## Try it first

Connect the local models once (RAGFlow keeps model settings per account):

1. Click your avatar in the upper-right corner and select **Model providers**.
2. Find **VLLM** and add a provider instance with base URL `http://vllm-chat:8000/v1`. Leave **API Key** empty. Add the chat model with the exact `MODEL` value, for example `Qwen/Qwen3-8B`, as a **Chat** model. Verify and save.
3. Add another **VLLM** provider instance with base URL `http://vllm-embed:8000/v1`. Add `Qwen/Qwen3-Embedding-0.6B` as an **Embedding** model. Verify and save.
4. Open **Set default models** and select both models.

Then try these:

- Chat with a document: create a Dataset with `Qwen/Qwen3-Embedding-0.6B` as its embedding model, upload a PDF or text file you own, parse it, then start a Chat on that Dataset and ask a question whose answer is in the file.
- Call the chat model directly: in a terminal on the instance, run the request below. The reply arrives in `choices[0].message.content`.

```
curl -fsS http://localhost:8000/v1/chat/completions -H 'Content-Type: application/json' -d '{"model":"Qwen/Qwen3-8B","messages":[{"role":"user","content":"Reply with the word ready."}],"max_tokens":64}'
```

- Check both model servers: `curl -fsS http://localhost:8000/v1/models` lists the chat model and `curl -fsS http://localhost:8001/v1/models` lists `Qwen/Qwen3-Embedding-0.6B`.

## How it works

- Eight services start under Docker Compose from `compose.yaml`, every image pinned by version tag and digest.
- RAGFlow serves its web UI and HTTP API on port 8080, reached through the authenticated Brev Secure Link **open-ragflow**.
- vLLM serves the chat model on port 8000 and the embedding model on port 8001, both bound to the instance loopback only. Inside the stack, RAGFlow reaches them as `vllm-chat:8000` and `vllm-embed:8000`.
- Document parsing (layout analysis and OCR) runs on the CPU; the GPU serves the two models.
- MySQL, the object store, Kvrocks, NATS and Infinity have no published ports and are not reachable from outside the instance.
- Every service has `restart: unless-stopped`, so the stack comes back by itself after a stop and start.

<details>
<summary>Advanced: internal passwords and the admin console</summary>

No default password is used. On first start the stack generates random internal passwords for its database, object store and cache and keeps them in `/home/ubuntu/workspace/ragflow/secrets`, readable only by root. Do not delete that folder while the data folders exist.

RAGFlow also creates an administrator account, `admin@ragflow.io`, for its separate admin console. Its random password is written once to `$HOME/workspace/ragflow/logs/admin_bootstrap_password.txt`; read it with `sudo cat` if you need the admin console.

</details>

## Settings

| Parameter | Required | Default | What it does |
| --- | --- | --- | --- |
| MODEL | yes (Choice) | Qwen/Qwen3-8B | Chat model served by vLLM. Choices: Qwen/Qwen3-8B (48 GB GPU), Qwen/Qwen3-4B-Instruct-2507 (24 GB GPU). Enter the same name in RAGFlow when you add the model. |
| HF_TOKEN | no (Text) | none | Optional Hugging Face read token. The models are public; a token only raises download rate limits. Choose "Use a secret" to bind a saved Brev secret if that option is available to you, or paste the token. |

## Use it from your machine

To call the APIs from your own machine, forward the ports with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 8080:8080
brev port-forward INSTANCE_NAME --port 8000:8000
```

Port 8080 serves the RAGFlow web UI and its HTTP API under `/api/v1`. Port 8000 is the vLLM chat endpoint.

## Data and persistence

All data is on the instance under `/home/ubuntu/workspace/ragflow` (`$HOME/workspace/ragflow`):

| Path | Contents |
| --- | --- |
| `$HOME/workspace/ragflow/minio` | uploaded documents |
| `$HOME/workspace/ragflow/mysql` | accounts, datasets, chats, settings |
| `$HOME/workspace/ragflow/infinity` | vectors and full-text index |
| `$HOME/workspace/ragflow/hf-cache` | downloaded models |
| `$HOME/workspace/ragflow/kvrocks`, `nats` | cache and task queue |
| `$HOME/workspace/ragflow/logs` | RAGFlow logs |
| `$HOME/workspace/ragflow/secrets` | internal passwords generated on first start |

These folders survive **Stop** and are destroyed by **Delete**.

## Stop, start and delete

- **Stop** pauses GPU billing. Storage keeps billing while stopped. Your data folders, models and settings are kept.
- **Start** it again: every service comes back by itself (`restart: unless-stopped`) with the same model; no parameter needs re-entering. The models reload from the local cache, which takes a few minutes.
- **Delete** ends all billing and destroys the instance and all data on it. It cannot be undone. Export anything you need first, for example:

```
scp -r INSTANCE_NAME:~/workspace/ragflow/minio ./ragflow-documents
```

## Troubleshooting

<details>
<summary>The open-ragflow link does not load right after deploy</summary>

A fresh deploy took about 22 minutes, most of it pulling the vLLM image and downloading the chat model. RAGFlow starts only after its database, object store, cache, queue and Infinity accept connections. Wait, then reload the link. Follow the chat model with `docker logs -f ragflow-vllm-chat-1`.

</details>

<details>
<summary>Verify fails when adding a VLLM model provider</summary>

Use the service names, not localhost: `http://vllm-chat:8000/v1` for the chat model and `http://vllm-embed:8000/v1` for the embedding model, with **API Key** empty. The chat model name must match the `MODEL` value exactly, for example `Qwen/Qwen3-8B`. If the chat model is still loading, wait until `docker logs -f ragflow-vllm-chat-1` shows the server listening on port 8000.

</details>

<details>
<summary>The chat server stops on a 24 GB GPU</summary>

Qwen/Qwen3-8B needs a GPU with at least 40 GB of VRAM. On a 24 GB GPU such as L4, deploy again with `MODEL=Qwen/Qwen3-4B-Instruct-2507`.

</details>

<details>
<summary>I need the RAGFlow admin console password</summary>

Run `sudo cat $HOME/workspace/ragflow/logs/admin_bootstrap_password.txt` on the instance. The account is `admin@ragflow.io`.

</details>

## FAQ

### Which GPU do I need for RAGFlow with local models?

At least 40 GB of VRAM for the default chat model, Qwen/Qwen3-8B; the default is one NVIDIA L40S 48GB. On a 24 GB GPU such as L4, choose `MODEL=Qwen/Qwen3-4B-Instruct-2507`. Plan for at least 32 GB of system memory.

### Does anything leave the instance?

Your documents, vectors, chats and accounts stay on the instance, and the models run on its GPU. On first start the instance downloads the container images and the Hugging Face models; after that the models load from the local cache.

### Where does my data live?

Under `/home/ubuntu/workspace/ragflow` on the instance. It survives Stop and is destroyed by Delete.

### Can I run this on my own hardware?

Yes, the stack is the `compose.yaml` in this folder: a Linux host with an NVIDIA GPU, Docker Compose and the NVIDIA Container Toolkit. Its data paths are under `/home/ubuntu/workspace/ragflow`. See the [RAGFlow](https://github.com/infiniflow/ragflow) project for its own deployment options.

### How do I update to a newer version?

This Launchable pins every image by tag and digest and every model by revision, so each deploy is the same. The embedding model is pinned so stored vectors stay valid: a different embedding model needs every dataset re-indexed. For newer RAGFlow releases, follow the [RAGFlow](https://github.com/infiniflow/ragflow) project.

## Guides and related Launchables

- Step-by-step guide: [Self-host RAGFlow with local models](https://www.9owls.com/guides/self-host-ragflow-with-local-models/)
- [Serve an OpenAI-compatible API with vLLM](https://www.9owls.com/guides/serve-an-openai-compatible-api-with-vllm/)
- [How to deploy a Launchable on NVIDIA Brev](https://www.9owls.com/guides/deploy-a-launchable-on-nvidia-brev/)
- [GPU memory for LLM inference compared](https://www.9owls.com/compare/nvidia-l4-vs-l40s-for-llm-inference/)
- [How to stop and delete an NVIDIA Brev instance](https://www.9owls.com/guides/stop-start-and-delete-an-nvidia-brev-instance/)
- This Launchable on 9owls: https://www.9owls.com/launchables/ragflow/
- All Launchables by 9owls: https://www.9owls.com/launchables/
- Related: [RAGFlow RAG with NVIDIA Nemotron](https://www.9owls.com/launchables/ragflow-nemotron/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8amkBXTPnhVDHsznOXkc6jOf9)); [Open Notebook on Nemotron](https://www.9owls.com/launchables/open-notebook-nemotron/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8a9DRg8X8LZyGjEtqCwWcjaYS)); [Open WebUI + vLLM](https://www.9owls.com/launchables/open-webui-vllm/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M6reXdi0sY0m18g80JNRJN0WtE))

## Keep your own stack running

NightKeeper packages your repository as an NVIDIA Brev Launchable, proves it on a fresh GPU and keeps it running. Your Brev API key stays in your repository's GitHub secrets. NightKeeper never sees it.

[Create your Launchable](https://www.9owls.com/nightkeeper/start/) or [read about NightKeeper](https://www.9owls.com/nightkeeper/).

## Credits and licences

- [RAGFlow](https://github.com/infiniflow/ragflow) by InfiniFlow - Apache-2.0.
- [Infinity](https://github.com/infiniflow/infinity) by InfiniFlow - Apache-2.0.
- [vLLM](https://github.com/vllm-project/vllm) - Apache-2.0.
- Silo object store by PGSTY, a MinIO fork - AGPL-3.0-or-later.
- Apache Kvrocks - Apache-2.0.
- NATS - Apache-2.0.
- MySQL Community Server - GPL-2.0.
- Qwen3-8B, Qwen3-4B-Instruct-2507 and Qwen3-Embedding-0.6B by the Qwen team - Apache-2.0; read each model card before use.

Files in this folder: `compose.yaml` (the stack, every image pinned by version tag and digest with the reason and date) and [LICENSE](LICENSE) (Apache-2.0 for the files in this folder; upstream attributions inside).

Published and maintained by [9owls, Inc.](https://www.9owls.com/). Questions: hello@9owls.com.
