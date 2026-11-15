# RAGFlow on your own GPU

Chat with your documents on your own GPU. [RAGFlow](https://github.com/infiniflow/ragflow) 1.0 runs with local models served by [vLLM](https://github.com/vllm-project/vllm): a Qwen3 chat model and the Qwen3 embedding model, with the [Infinity](https://github.com/infiniflow/infinity) vector engine. Nothing leaves the instance.

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M7Rp4TmPPfR0piWdfBqcHweyVl)

Launchable ID: env-3M7Rp4TmPPfR0piWdfBqcHweyVl

Current versions: infiniflow/ragflow:v1.0.0, vllm/vllm-openai:v0.33.0, infiniflow/infinity:v0.7.5-x64-v3, mysql:8.0.40, pgsty/silo:RELEASE.2026-08-06T00-00-00Z, apache/kvrocks:2.16.0, nats:2.14.2

Last smoke: 2026-11-15, fresh deploy on one NVIDIA L40S 48GB. All eight services were up about 22 minutes after launch (most of it pulling the vLLM image); health, chat and embeddings all answered.

## What you get

- Default instance: 1x NVIDIA L40S 48GB, stoppable, 100 GiB disk. The deploy page shows the current hourly price.
- Minimum GPU: 40 GB VRAM for the default chat model (Qwen/Qwen3-8B). On a 24 GB GPU such as L4, launch with `MODEL=Qwen/Qwen3-4B-Instruct-2507`. Plan for at least 32 GB of system memory.
- Ready in about 20 minutes on first deploy: most of that is the vLLM image pull and the chat model download.
- One web UI behind a Brev Secure Link: **open-ragflow** (port 8080) - RAGFlow.
- Two OpenAI-compatible endpoints on the instance, not exposed to the internet:
  - chat: `http://localhost:8000/v1` (model name = the `MODEL` value)
  - embeddings: `http://localhost:8001/v1` (model name `Qwen/Qwen3-Embedding-0.6B`)

## Launch parameters

| Name | Type | Default | Purpose |
|---|---|---|---|
| MODEL | Choice | Qwen/Qwen3-8B | Chat model served by vLLM. Choices: Qwen/Qwen3-8B (48 GB GPU), Qwen/Qwen3-4B-Instruct-2507 (24 GB GPU). |
| HF_TOKEN | Text | none | Optional Hugging Face read token. The models are public; a token only raises download rate limits. Choose "Use a secret" to bind a saved Brev secret if that option is available to you, or paste the token. |

## Use it

1. Deploy and wait until the instance is Running. The models load in the background; follow progress from a terminal on the instance:

   ```
   docker logs -f ragflow-vllm-chat-1
   ```

   The chat model is ready when the log shows the server listening on port 8000.
2. Click **open-ragflow** and register an account on the sign-in page. The first account you register is yours; the page is reachable only through your Brev login.
3. Connect the local models once (RAGFlow keeps model settings per account):
   1. Click your avatar in the upper-right corner and select **Model providers**.
   2. Find **VLLM** and add a provider instance with base URL `http://vllm-chat:8000/v1`. Leave **API Key** empty. Add the chat model with the exact `MODEL` value, for example `Qwen/Qwen3-8B`, as a **Chat** model. Verify and save.
   3. Add another **VLLM** provider instance with base URL `http://vllm-embed:8000/v1`. Add `Qwen/Qwen3-Embedding-0.6B` as an **Embedding** model. Verify and save.
   4. Open **Set default models** and select both models.
4. Create a Dataset with `Qwen/Qwen3-Embedding-0.6B` as its embedding model, upload documents, parse them, then start a Chat on that Dataset.

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

- **Stop** pauses GPU billing. Storage keeps billing while stopped. On start, every service comes back by itself (`restart: unless-stopped`) with the same model; no parameter needs re-entering. The models reload from the local cache, which takes a few minutes.
- **Delete** ends all billing and destroys the instance and all data on it. It cannot be undone. Export anything you need first, for example:

```
scp -r INSTANCE_NAME:~/workspace/ragflow/minio ./ragflow-documents
```

## Files

- `compose.yaml` - the stack, every image pinned by version tag and digest with the reason and date.
- `LICENSE` - Apache-2.0 for the files in this folder; upstream credits inside.

## Credits

- RAGFlow by InfiniFlow - Apache-2.0.
- Infinity by InfiniFlow - Apache-2.0.
- vLLM - Apache-2.0.
- Silo object store by PGSTY, a MinIO fork - AGPL-3.0-or-later.
- Apache Kvrocks - Apache-2.0.
- NATS - Apache-2.0.
- MySQL Community Server - GPL-2.0.
- Qwen3-8B, Qwen3-4B-Instruct-2507 and Qwen3-Embedding-0.6B by the Qwen team - Apache-2.0; read each model card before use.
