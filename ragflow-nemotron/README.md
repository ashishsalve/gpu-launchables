# RAGFlow RAG with NVIDIA Nemotron

Chat with your documents on your own GPU. [RAGFlow](https://github.com/infiniflow/ragflow) 1.0 runs with NVIDIA Nemotron models served by [vLLM](https://github.com/vllm-project/vllm): the [Nemotron 3.5 Bolt E4B](https://huggingface.co/nvidia/NVIDIA-Nemotron-3.5-Bolt-E4B-BF16) chat model and the [Nemotron 3.5 Embed 1B](https://huggingface.co/nvidia/Nemotron-3.5-Embed-1B-BF16) embedding model, with the [Infinity](https://github.com/infiniflow/infinity) vector engine. Your documents and the RAG pipeline stay on the instance.

Current versions: infiniflow/ragflow:v1.0.0, vllm/vllm-openai:v0.33.0, infiniflow/infinity:v0.7.5-x64-v3, mysql:8.0.40, pgsty/silo:RELEASE.2026-08-06T00-00-00Z, apache/kvrocks:2.16.0, nats:2.14.2; models nvidia/NVIDIA-Nemotron-3.5-Bolt-E4B-BF16, nvidia/Nemotron-3.5-Embed-1B-BF16

Last smoke: not yet run.

## What you get

- Default instance: 1x NVIDIA L40S 48GB, stoppable, 200 GiB disk. The deploy page shows the current hourly price.
- The default configuration is sized for one 48 GB GPU: the chat model gets 72 percent of GPU memory and the embedding model 15 percent.
- First deploy pulls the vLLM image and downloads both models before the chat endpoint answers.
- One web UI behind a Brev Secure Link: **open-ragflow** (port 8080) - RAGFlow.
- Two OpenAI-compatible endpoints on the instance, not exposed to the internet:
  - chat: `http://localhost:8000/v1` (model name = the `MODEL` value)
  - embeddings: `http://localhost:8001/v1` (model name = the `EMBED_MODEL` value)

## Launch parameters

| Name | Type | Default | Purpose |
|---|---|---|---|
| MODEL | Choice | nvidia/NVIDIA-Nemotron-3.5-Bolt-E4B-BF16 | Chat model served by vLLM. Choices: nvidia/NVIDIA-Nemotron-3.5-Bolt-E4B-BF16, Qwen/Qwen3-8B. |
| EMBED_MODEL | Choice | nvidia/Nemotron-3.5-Embed-1B-BF16 | Embedding model served by vLLM. Choices: nvidia/Nemotron-3.5-Embed-1B-BF16, Qwen/Qwen3-Embedding-0.6B. Datasets are indexed with this model; changing it later means re-parsing your documents. |
| HF_TOKEN | Text | none | Optional Hugging Face read token. All offered models are public; a token only raises download rate limits. Choose "Use a secret" to bind a saved Brev secret if that option is available to you, or paste the token. |

## Use it

1. Deploy and wait until the instance is Running. The models load in the background; follow progress from a terminal on the instance:

   ```
   docker logs -f ragflow-vllm-chat-1
   ```

   The chat model is ready when the log shows the server listening on port 8000.
2. Click **open-ragflow** and register an account on the sign-in page. The first account you register is yours; the page is reachable only through your Brev login.
3. Connect the local models once (RAGFlow keeps model settings per account):
   1. Click your avatar in the upper-right corner and select **Model providers**.
   2. Find **VLLM** and add a provider instance with base URL `http://vllm-chat:8000/v1`. Leave **API Key** empty. Add the chat model with the exact `MODEL` value, for example `nvidia/NVIDIA-Nemotron-3.5-Bolt-E4B-BF16`, as a **Chat** model. Verify and save.
   3. Add another **VLLM** provider instance with base URL `http://vllm-embed:8000/v1`. Add the exact `EMBED_MODEL` value, for example `nvidia/Nemotron-3.5-Embed-1B-BF16`, as an **Embedding** model. Verify and save.
   4. Open **Set default models** and select both models.
4. Create a Dataset with the embedding model you added, upload documents, parse them, then start a Chat on that Dataset.

Document parsing (layout analysis and OCR) runs on the CPU; the GPU serves the two models.

To call the APIs from your own machine, forward the ports with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 8080:8080
brev port-forward INSTANCE_NAME --port 8000:8000
```

Port 8080 serves the RAGFlow web UI and its HTTP API under `/api/v1`. Port 8000 is the vLLM chat endpoint.

## Where your data lives

All data is on the instance under `/home/ubuntu/workspace/ragflow` (`$HOME/workspace/ragflow`):

| Path | Contents |
|---|---|
| `$HOME/workspace/ragflow/minio` | uploaded documents |
| `$HOME/workspace/ragflow/mysql` | accounts, datasets, chats, settings |
| `$HOME/workspace/ragflow/infinity` | vectors and full-text index |
| `$HOME/workspace/ragflow/hf-cache` | downloaded models |
| `$HOME/workspace/ragflow/kvrocks`, `nats` | cache and task queue |
| `$HOME/workspace/ragflow/logs` | RAGFlow logs |
| `$HOME/workspace/ragflow/secrets` | internal passwords generated on first start |

These folders survive **Stop** and are destroyed by **Delete**.

No default password is used. On first start the stack generates random internal passwords for its database, object store and cache and keeps them in `secrets/`, readable only by root. Do not delete that folder while the data folders exist. None of those services is reachable from outside the instance.

RAGFlow also creates an administrator account, `admin@ragflow.io`, for its separate admin console. Its random password is written once to `$HOME/workspace/ragflow/logs/admin_bootstrap_password.txt`; read it with `sudo cat` if you need the admin console.

## Stop vs delete

- **Stop** pauses GPU billing. Storage keeps billing while stopped. On start, every service comes back by itself (`restart: unless-stopped`) with the same models; no parameter needs re-entering. The models reload from the local cache, which takes a few minutes.
- **Delete** ends all billing and destroys the instance and all data on it. It cannot be undone. Export anything you need first, for example:

```
scp -r INSTANCE_NAME:~/workspace/ragflow/minio ./ragflow-documents
```

## Files

- `compose.yaml` - the stack, every image pinned by version tag and digest and every model by revision, with the reason and date.
- `LICENSE` - Apache-2.0 for the files in this folder; upstream credits and model licence notices inside.

## Model licences

The NVIDIA Nemotron models are downloaded from Hugging Face at launch and are governed by the [OpenMDW License Agreement, version 1.1](https://openmdw.ai/license/1-1/) (OpenMDW-1.1):

- nvidia/NVIDIA-Nemotron-3.5-Bolt-E4B-BF16 - OpenMDW-1.1. The model card states that it was post-trained on Google Gemma 4 and that use of the Google Gemma 4 model is governed by the Apache License, Version 2.0.
- nvidia/Nemotron-3.5-Embed-1B-BF16 - OpenMDW-1.1. The model card states that its Ministral-3-3B-Instruct-2512-BF16 and Ministral-3-8B-Instruct-2512-BF16 base models are governed by the Apache License, Version 2.0.

By launching with these models you accept their licence terms. Read each model card before use.

## Credits

- RAGFlow by InfiniFlow - Apache-2.0.
- Infinity by InfiniFlow - Apache-2.0.
- vLLM - Apache-2.0.
- NVIDIA Nemotron 3.5 Bolt E4B and Nemotron 3.5 Embed 1B by NVIDIA - OpenMDW-1.1; base models (Google Gemma 4; Mistral Ministral 3) under Apache-2.0 per each model card.
- Qwen3-8B and Qwen3-Embedding-0.6B by the Qwen team - Apache-2.0.
- Silo object store by PGSTY, a MinIO fork - AGPL-3.0-or-later.
- Apache Kvrocks - Apache-2.0.
- NATS - Apache-2.0.
- MySQL Community Server - GPL-2.0.
