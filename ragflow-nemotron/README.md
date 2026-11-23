<p align="center">
  <strong>RAGFlow with NVIDIA Nemotron on NVIDIA Brev</strong><br>
  Chat with your documents on one NVIDIA L40S: RAGFlow and the Infinity engine, with Nemotron chat and embedding models served by vLLM.
</p>

# RAGFlow RAG with NVIDIA Nemotron

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8amkBXTPnhVDHsznOXkc6jOf9)

Launchable ID: env-3M8amkBXTPnhVDHsznOXkc6jOf9

Chat with your documents on your own GPU. [RAGFlow](https://github.com/infiniflow/ragflow) 1.0 runs with NVIDIA Nemotron models served by [vLLM](https://github.com/vllm-project/vllm): the [Nemotron 3.5 Bolt E4B](https://huggingface.co/nvidia/NVIDIA-Nemotron-3.5-Bolt-E4B-BF16) chat model and the [Nemotron 3.5 Embed 1B](https://huggingface.co/nvidia/Nemotron-3.5-Embed-1B-BF16) embedding model, with the [Infinity](https://github.com/infiniflow/infinity) vector engine, on one NVIDIA L40S 48GB GPU. Your documents and the RAG pipeline stay on the instance. First step: deploy, open RAGFlow from the open-ragflow link, connect the two local models once, then upload a document and ask it a question.

| Quick facts | |
| --- | --- |
| Runs | RAGFlow 1.0 web UI and API, Infinity vector engine, two vLLM servers (chat and embeddings), MySQL, Silo object store, Apache Kvrocks and NATS; eight services under Docker Compose |
| Default compute | 1x NVIDIA L40S 48GB on AWS (g6e.xlarge), stoppable; you can pick another GPU on the deploy page |
| Disk | 200 GiB |
| Ready in | about 28 minutes on a fresh deploy (2026-11-15) |
| Cost | about $2.23/hr on the default compute (console, 2026-11-15); storage is billed while stopped |
| Secrets | optional HF_TOKEN (Hugging Face read token); no value is stored in this folder |
| Licences | RAGFlow, Infinity and vLLM Apache-2.0; NVIDIA Nemotron models OpenMDW-1.1; see Credits and licences |
| Guide | https://www.9owls.com/launchables/ragflow-nemotron/ |

Current versions: infiniflow/ragflow:v1.0.0, vllm/vllm-openai:v0.33.0, infiniflow/infinity:v0.7.5-x64-v3, mysql:8.0.40, pgsty/silo:RELEASE.2026-08-06T00-00-00Z, apache/kvrocks:2.16.0, nats:2.14.2; models nvidia/NVIDIA-Nemotron-3.5-Bolt-E4B-BF16, nvidia/Nemotron-3.5-Embed-1B-BF16

Last smoke: 2026-11-15, fresh deploy on one NVIDIA L40S 48GB, including stop and start.

## Contents

- [What you get](#what-you-get)
- [Deploy in three steps](#deploy-in-three-steps)
- [Connect the local models](#connect-the-local-models)
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
| RAGFlow (web UI and HTTP API) | 1.0.0 (pinned by tag and digest) | `infiniflow/ragflow:v1.0.0` |
| Infinity vector and full-text engine | 0.7.5 | `infiniflow/infinity:v0.7.5-x64-v3` |
| vLLM chat server, OpenAI-compatible | 0.33.0 | `vllm/vllm-openai:v0.33.0` |
| vLLM embedding server, OpenAI-compatible | 0.33.0 | `vllm/vllm-openai:v0.33.0` |
| Chat model (default) | pinned revision | `nvidia/NVIDIA-Nemotron-3.5-Bolt-E4B-BF16` |
| Embedding model (default) | pinned revision | `nvidia/Nemotron-3.5-Embed-1B-BF16` |
| MySQL Community Server | 8.0.40 | `mysql:8.0.40` |
| Silo object store | RELEASE.2026-08-06T00-00-00Z | `pgsty/silo:RELEASE.2026-08-06T00-00-00Z` |
| Apache Kvrocks cache | 2.16.0 | `apache/kvrocks:2.16.0` |
| NATS task queue | 2.14.2 | `nats:2.14.2` |
| The stack | every image pinned by version tag and digest, every model by revision | [compose.yaml](compose.yaml) in this folder |

The default configuration is sized for one 48 GB GPU: the chat model gets 72 percent of GPU memory and the embedding model 15 percent.

## Deploy in three steps

1. Click Launch on Brev, keep the NVIDIA L40S or pick another GPU, keep or change the model settings, and deploy.
2. Wait until the instance shows Running and the open-ragflow link answers. The first deploy pulls the vLLM image and downloads both models before the chat endpoint answers; on a fresh deploy the whole stack was ready in about 28 minutes. To follow the chat model loading, open a terminal on the instance and run the command below. The chat model is ready when the log shows the server listening on port 8000.
3. Click **open-ragflow** and register an account on the sign-in page. The first account you register is yours; the page is reachable only through your Brev login.

```
docker logs -f ragflow-vllm-chat-1
```

## Connect the local models

RAGFlow keeps model settings per account, so connect the two local models once after you register:

1. Click your avatar in the upper-right corner and select **Model providers**.
2. Find **VLLM** and add a provider instance with base URL `http://vllm-chat:8000/v1`. Leave **API Key** empty. Add the chat model with the exact `MODEL` value, for example `nvidia/NVIDIA-Nemotron-3.5-Bolt-E4B-BF16`, as a **Chat** model. Verify and save.
3. Add another **VLLM** provider instance with base URL `http://vllm-embed:8000/v1`. Add the exact `EMBED_MODEL` value, for example `nvidia/Nemotron-3.5-Embed-1B-BF16`, as an **Embedding** model. Verify and save.
4. Open **Set default models** and select both models.

## Try it first

- **Ask questions about your own files.** Create a Dataset with the embedding model you added, upload a few documents (for example a PDF manual or a report), parse them, then start a Chat on that Dataset and ask a question whose answer is in one of the documents.
- **Check both model endpoints from a terminal on the instance.** Each command lists the model it serves:

```
curl http://localhost:8000/v1/models
curl http://localhost:8001/v1/models
```

- **Call the chat model directly** with the OpenAI-compatible API, using the exact `MODEL` value as the model name:

```
curl http://localhost:8000/v1/chat/completions -H "Content-Type: application/json" -d '{"model": "nvidia/NVIDIA-Nemotron-3.5-Bolt-E4B-BF16", "messages": [{"role": "user", "content": "Say ready."}]}'
```

## How it works

- Eight services run under Docker Compose: RAGFlow, Infinity, MySQL, the Silo object store, Kvrocks, NATS, and two vLLM servers.
- One web UI sits behind the Brev Secure Link **open-ragflow** (port 8080). Port 8080 serves the RAGFlow web UI and its HTTP API under `/api/v1`.
- Two OpenAI-compatible endpoints run on the instance, not exposed to the internet: chat at `http://localhost:8000/v1` (model name = the `MODEL` value) and embeddings at `http://localhost:8001/v1` (model name = the `EMBED_MODEL` value).
- The GPU serves the two models. Document parsing (layout analysis and OCR) runs on the CPU.
- Your documents, the vector index and the chats stay on the instance. The database, object store and cache are not reachable from outside the instance.

<details>
<summary>Advanced: internal passwords and the admin console</summary>

No default password is used. On first start the stack generates random internal passwords for its database, object store and cache and keeps them in `$HOME/workspace/ragflow/secrets`, readable only by root. Do not delete that folder while the data folders exist.

RAGFlow also creates an administrator account, `admin@ragflow.io`, for its separate admin console. Its random password is written once to `$HOME/workspace/ragflow/logs/admin_bootstrap_password.txt`; read it with `sudo cat` if you need the admin console.

</details>

## Settings

| Parameter | Required | Default | What it does |
| --- | --- | --- | --- |
| MODEL | no (Choice) | nvidia/NVIDIA-Nemotron-3.5-Bolt-E4B-BF16 | Chat model served by vLLM. Choices: nvidia/NVIDIA-Nemotron-3.5-Bolt-E4B-BF16, Qwen/Qwen3-8B. |
| EMBED_MODEL | no (Choice) | nvidia/Nemotron-3.5-Embed-1B-BF16 | Embedding model served by vLLM. Choices: nvidia/Nemotron-3.5-Embed-1B-BF16, Qwen/Qwen3-Embedding-0.6B. Datasets are indexed with this model; changing it later means re-parsing your documents. |
| HF_TOKEN | no (Text) | none | Optional Hugging Face read token. All offered models are public; a token only raises download rate limits. Choose "Use a secret" to bind a saved Brev secret if that option is available to you, or paste the token. |

## Use it from your machine

To call the APIs from your own machine, forward the ports with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 8080:8080
brev port-forward INSTANCE_NAME --port 8000:8000
```

Port 8080 then answers on localhost with the RAGFlow web UI and its HTTP API under `/api/v1`. Port 8000 is the vLLM chat endpoint at `http://localhost:8000/v1`.

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

- **Stop** the instance from the Brev console when you are not using it. Stop pauses GPU billing; storage keeps billing while stopped. Everything under `/home/ubuntu/workspace/ragflow` is kept.
- **Start** it again: every service is recreated automatically with the same models, and no parameter needs re-entering. The models reload from the local cache; in the 2026-11-15 smoke RAGFlow and the chat model were back about 7 minutes after start. If RAGFlow is not back after 5 minutes, use the recovery command under Troubleshooting.
- **Delete** the instance when you are finished. This removes the instance and all of its data, and it cannot be undone. Export anything you need first, for example:

```
scp -r INSTANCE_NAME:~/workspace/ragflow/minio ./ragflow-documents
```

## Troubleshooting

<details>
<summary>RAGFlow is not back after a stop and start</summary>

Stopping the instance removes the RAGFlow containers; everything under ~/workspace is kept. Starting it again recreates the containers automatically, usually within a few minutes. If RAGFlow is not back after 5 minutes, open a terminal on the instance and run:

```
cd /home/ubuntu/workspace && sudo docker compose up -d
```

</details>

<details>
<summary>The open-ragflow link or the chat model is not ready right after deploy</summary>

The first deploy pulls the vLLM image and downloads both models before the chat endpoint answers. On a fresh deploy the whole stack was ready in about 28 minutes. Follow the chat model with `docker logs -f ragflow-vllm-chat-1`; it is ready when the log shows the server listening on port 8000.

</details>

<details>
<summary>RAGFlow cannot verify a model</summary>

Check the base URL and the model name. The chat provider uses `http://vllm-chat:8000/v1` and the embedding provider `http://vllm-embed:8000/v1`, with the API Key left empty. The model name must be the exact `MODEL` or `EMBED_MODEL` value you deployed with. Confirm the model is loaded with `curl http://localhost:8000/v1/models` or `curl http://localhost:8001/v1/models` on the instance.

</details>

<details>
<summary>Answers changed after switching the embedding model</summary>

Datasets are indexed with the embedding model they were created with. After changing `EMBED_MODEL`, re-parse your documents.

</details>

## FAQ

### Which GPU do I need?

The default is one NVIDIA L40S 48GB with 200 GiB of disk. The configuration is sized for one 48 GB GPU: the chat model gets 72 percent of GPU memory and the embedding model 15 percent. In the 2026-11-15 smoke the two default models used 31772 of 46068 MiB.

### Does anything leave the instance?

Your documents, the RAG index and your chats stay on the instance, and the chat and embedding models run on its GPU. On first start the instance downloads the container images and the models from Hugging Face.

### Can I use Qwen models instead of Nemotron?

Yes. Pick Qwen/Qwen3-8B for `MODEL` and Qwen/Qwen3-Embedding-0.6B for `EMBED_MODEL` on the deploy page, then add those exact names in RAGFlow.

### Is a reranker included?

No. The GPU memory is shared by the chat and embedding models, and no reranking service is part of this stack.

### Can I run this on my own hardware?

Yes, the stack is the `compose.yaml` in this folder with the public [RAGFlow](https://github.com/infiniflow/ragflow) and [vLLM](https://github.com/vllm-project/vllm) images. See those projects for supported GPUs and drivers.

### How do I update to a newer version?

This Launchable pins every image by tag and digest and every model by revision, so every deploy is the same. To try a newer release on your own instance, change the image tag in `compose.yaml` under `/home/ubuntu/workspace` and run `sudo docker compose up -d`; your data under `/home/ubuntu/workspace/ragflow` is kept.

## Guides and related Launchables

- Step-by-step guide: [Self-host RAGFlow with local models](https://www.9owls.com/guides/self-host-ragflow-with-local-models/)
- [Serve NVIDIA Nemotron with vLLM](https://www.9owls.com/guides/serve-nvidia-nemotron-with-vllm/)
- [Serve an OpenAI-compatible API with vLLM](https://www.9owls.com/guides/serve-an-openai-compatible-api-with-vllm/)
- [How to deploy a Launchable on NVIDIA Brev](https://www.9owls.com/guides/deploy-a-launchable-on-nvidia-brev/)
- [How to stop and delete an NVIDIA Brev instance](https://www.9owls.com/guides/stop-start-and-delete-an-nvidia-brev-instance/)
- This Launchable on 9owls: https://www.9owls.com/launchables/ragflow-nemotron/
- All Launchables by 9owls: https://www.9owls.com/launchables/
- Related: [RAGFlow on your own GPU](https://www.9owls.com/launchables/ragflow/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M7Rp4TmPPfR0piWdfBqcHweyVl)); [Open Notebook on Nemotron](https://www.9owls.com/launchables/open-notebook-nemotron/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8a9DRg8X8LZyGjEtqCwWcjaYS)); [Nemotron Chat with Open WebUI and vLLM](https://www.9owls.com/launchables/nemotron-chat/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aArulP2ZTX7HwqGLf4pwRT6z))

## Keep your own stack running

NightKeeper packages your repository as an NVIDIA Brev Launchable, proves it on a fresh GPU and keeps it running. Your Brev API key stays in your repository's GitHub secrets. NightKeeper never sees it.

[Create your Launchable](https://www.9owls.com/nightkeeper/start/) or [read about NightKeeper](https://www.9owls.com/nightkeeper/).

## Credits and licences

- [RAGFlow](https://github.com/infiniflow/ragflow) by InfiniFlow: Apache-2.0.
- [Infinity](https://github.com/infiniflow/infinity) by InfiniFlow: Apache-2.0.
- [vLLM](https://github.com/vllm-project/vllm): Apache-2.0.
- NVIDIA Nemotron 3.5 Bolt E4B and Nemotron 3.5 Embed 1B by NVIDIA: OpenMDW-1.1; base models (Google Gemma 4; Mistral Ministral 3) under Apache-2.0 per each model card.
- Qwen3-8B and Qwen3-Embedding-0.6B by the Qwen team: Apache-2.0.
- Silo object store by PGSTY, a MinIO fork: AGPL-3.0-or-later.
- Apache Kvrocks: Apache-2.0.
- NATS: Apache-2.0.
- MySQL Community Server: GPL-2.0.

The NVIDIA Nemotron models are downloaded from Hugging Face at launch and are governed by the [OpenMDW License Agreement, version 1.1](https://openmdw.ai/license/1-1/) (OpenMDW-1.1):

- nvidia/NVIDIA-Nemotron-3.5-Bolt-E4B-BF16: OpenMDW-1.1. The model card states that it was post-trained on Google Gemma 4 and that use of the Google Gemma 4 model is governed by the Apache License, Version 2.0.
- nvidia/Nemotron-3.5-Embed-1B-BF16: OpenMDW-1.1. The model card states that its Ministral-3-3B-Instruct-2512-BF16 and Ministral-3-8B-Instruct-2512-BF16 base models are governed by the Apache License, Version 2.0.

By launching with these models you accept their licence terms. Read each model card before use.

Files in this folder: [compose.yaml](compose.yaml) (the stack, every image pinned by version tag and digest and every model by revision, with the reason and date) and [LICENSE](LICENSE) (Apache-2.0 for the files in this folder; upstream attributions and model licence notices inside).

Published and maintained by [9owls, Inc.](https://www.9owls.com/). Questions: hello@9owls.com.
