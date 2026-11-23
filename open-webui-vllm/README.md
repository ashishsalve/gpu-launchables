<p align="center">
  <strong>Open WebUI + vLLM on NVIDIA Brev</strong><br>
  A private chat assistant on one NVIDIA L40S: vLLM serves an open-weight model through an OpenAI-compatible API and Open WebUI gives you the chat in your browser.
</p>

# Open WebUI + vLLM

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M6reXdi0sY0m18g80JNRJN0WtE)

Launchable ID: env-3M6reXdi0sY0m18g80JNRJN0WtE

A private chat assistant on your own GPU. [vLLM](https://github.com/vllm-project/vllm) serves an open-weight model through an OpenAI-compatible API, and [Open WebUI](https://github.com/open-webui/open-webui) gives you the browser chat interface, started together with Docker Compose on one NVIDIA L40S 48GB. Nothing you type leaves the instance. First step: deploy, open the chat-in-open-webui link, create your admin account and chat with Qwen3-8B or the model you picked.

| Quick facts | |
| --- | --- |
| Runs | vLLM v0.33.0 (OpenAI-compatible server) and Open WebUI v0.13.3, two containers under Docker Compose |
| Default compute | 1x NVIDIA L40S 48GB on Crusoe (l40s-48gb.1x), stoppable; you can pick another GPU on the deploy page |
| Disk | 128 GiB |
| Ready in | about 17 minutes to the first chat answer on a fresh deploy (2026-11-14) |
| Cost | about $1.74/hr on the default compute (console, 2026-11-15); storage is billed while stopped |
| Secrets | `HF_TOKEN`, optional, only for gated models |
| Licences | vLLM Apache-2.0, Open WebUI License; each model carries its own licence |
| Guide | https://www.9owls.com/launchables/open-webui-vllm/ |

Current versions: vLLM v0.33.0 (vllm/vllm-openai:v0.33.0), Open WebUI v0.13.3 (ghcr.io/open-webui/open-webui:v0.13.3)

Last smoke: 2026-11-14, fresh deploy on one NVIDIA L40S 48GB with Qwen/Qwen3-8B. The first chat answer arrived about 17 minutes after launch.

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
| vLLM (OpenAI-compatible server) | v0.33.0 (pinned) | `vllm/vllm-openai:v0.33.0` |
| Open WebUI | v0.13.3 (pinned) | `ghcr.io/open-webui/open-webui:v0.13.3` |
| Model | your `MODEL` choice, default `Qwen/Qwen3-8B` | downloaded from Hugging Face on first start |

The vLLM image is built on CUDA 13.0, so the instance's NVIDIA driver must support CUDA 13.

## Deploy in three steps

1. Click Launch on Brev, keep the NVIDIA L40S or pick another GPU, choose a `MODEL` (or keep `Qwen/Qwen3-8B`), and deploy. Add `HF_TOKEN` only for a gated model.
2. Wait until the instance shows Running and the **chat-in-open-webui** link loads. The chat page opens before the model download finishes; on the 2026-11-14 fresh deploy the first chat answer arrived about 17 minutes after launch.
3. Open **chat-in-open-webui** and create an account right away: the first account you create becomes the Open WebUI admin. Wait for the model to appear in the model picker, then chat.

## Try it first

- Ask a question in the chat, for example: `Explain in three sentences what an OpenAI-compatible API is.`
- Paste a block of your own text and ask: `Summarize this in five bullet points.` The text is processed on your instance only.
- Call the model through the API from your own machine (see [Use it from your machine](#use-it-from-your-machine)):

```
curl http://localhost:8000/v1/chat/completions -H 'Content-Type: application/json' -d '{"model":"Qwen/Qwen3-8B","messages":[{"role":"user","content":"Reply OK"}],"max_tokens":32}'
```

Replace `Qwen/Qwen3-8B` with your `MODEL` if you picked another one.

## How it works

- Two containers start together with Docker Compose: `vllm` and `open-webui`.
- vLLM serves the `MODEL` you chose on port 8000 with an OpenAI-compatible API (`--max-model-len 16384`, `--gpu-memory-utilization 0.90`). The API is bound to the instance itself (localhost only) and is not exposed publicly.
- Open WebUI listens on port 8080 and is reached through the authenticated Brev Secure Link **chat-in-open-webui**. It talks to vLLM inside the instance.
- The model runs on the instance GPU. Nothing you type leaves the instance.
- Both containers use `restart: unless-stopped`, so they come back by themselves after a stop and start.

<details>
<summary>Advanced: model sizes and GPU memory</summary>

The weights of `Qwen/Qwen3-32B-FP8` are 32.0 GiB, so that choice needs a 48 GB GPU. `--max-model-len 16384` bounds the KV cache. The other three choices are smaller downloads (about 14 to 16 GB). The full configuration is in `compose.yaml` in this folder.

</details>

## Settings

| Parameter | Required | Default | What it does |
| --- | --- | --- | --- |
| `MODEL` | no | `Qwen/Qwen3-8B` | The Hugging Face model vLLM serves and Open WebUI uses by default. Choices below. |
| `HF_TOKEN` | no | none | Hugging Face read token, needed only for gated models such as `meta-llama/Llama-3.1-8B-Instruct`. |

`MODEL` choices:

- `Qwen/Qwen3-8B` (default, about a 16 GB download)
- `Qwen/Qwen3-32B-FP8` (about a 34 GB download; needs a 48 GB GPU)
- `openai/gpt-oss-20b` (about a 14 GB download)
- `meta-llama/Llama-3.1-8B-Instruct` (gated, needs `HF_TOKEN`)

The model is downloaded once on first start and loaded from the local cache after that. To change the model, deploy again with a different `MODEL`.

`HF_TOKEN` is optional. Accept the model's licence on its Hugging Face page with the same account first. On the deploy page you can bind a saved secret or paste a read token. Never put a token anywhere except this parameter.

## Use it from your machine

To call the OpenAI-compatible API from your own machine, forward the port with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 8000:8000
curl http://localhost:8000/v1/models
```

The vLLM API then answers on http://localhost:8000/v1 on your machine, and `/v1/models` lists the model you deployed.

## Data and persistence

Models and chats live on the instance:

- Models (Hugging Face cache): `/home/ubuntu/workspace/huggingface` (`~/workspace/huggingface`)
- Chats, users and settings: `/home/ubuntu/workspace/open-webui` (`~/workspace/open-webui`)

They survive a stop and start of the instance. They are removed when the instance is deleted.

## Stop, start and delete

- **Stop** the instance from the Brev console when you are not using it. Your models and chats are kept. Storage is still billed while the instance is stopped.
- **Start** it again: both containers start again by themselves (`restart: unless-stopped`) with the same settings, and the model loads from the local cache without a new download.
- **Delete** the instance when you are finished. This removes the instance and all of its data, including downloaded models and chat history.

## Troubleshooting

<details>
<summary>The model does not appear in the model picker</summary>

The chat page opens before vLLM has downloaded and loaded the model. On a fresh deploy the first answer arrived about 17 minutes after launch; a larger `MODEL` takes longer. Wait, then reload the page. To follow progress, open a terminal on the instance with `brev shell INSTANCE_NAME` and run:

```
sudo docker ps
sudo docker logs --tail 50 openwebui-vllm-vllm-1
```

</details>

<details>
<summary>The gated Llama model does not load</summary>

`meta-llama/Llama-3.1-8B-Instruct` needs `HF_TOKEN`. Accept the model's licence on its Hugging Face page with the same account as the token, then deploy again with `HF_TOKEN` set.

</details>

<details>
<summary>vLLM does not start on another GPU</summary>

The vLLM image is built on CUDA 13.0, so the instance's NVIDIA driver must support CUDA 13. Run `nvidia-smi` on the instance to see the driver's CUDA version. `Qwen/Qwen3-32B-FP8` also needs a 48 GB GPU; pick a smaller `MODEL` on a smaller GPU.

</details>

<details>
<summary>Who is the admin?</summary>

The first account created in Open WebUI becomes the admin. Create it right after the chat-in-open-webui link loads.

</details>

## FAQ

### Which GPU do I need?

The default is one NVIDIA L40S 48GB with 128 GiB of disk for the container images and the model cache. `Qwen/Qwen3-32B-FP8` needs a 48 GB GPU. The driver must support CUDA 13.

### Does anything leave the instance?

Nothing you type leaves the instance: the model runs on the instance GPU and the vLLM API is bound to the instance itself. The model weights are downloaded from Hugging Face on first start.

### Can I use it with OpenAI client libraries?

Yes. vLLM serves an OpenAI-compatible API. Forward port 8000 with `brev port-forward` and point your client at http://localhost:8000/v1 with your `MODEL` as the model name.

### How do I change the model?

Deploy again with a different `MODEL`. The four choices are listed under [Settings](#settings).

### Can I run this on my own hardware?

Yes, the stack is the public [vLLM](https://github.com/vllm-project/vllm) and [Open WebUI](https://github.com/open-webui/open-webui) images plus the `compose.yaml` in this folder. You need an NVIDIA GPU, a driver that supports CUDA 13 and the NVIDIA Container Toolkit.

### How do I update to a newer version?

This Launchable pins vLLM v0.33.0 and Open WebUI v0.13.3 so every deploy is the same. To try newer releases, change the image tags in your own copy of `compose.yaml` and run it on your own instance or hardware.

## Guides and related Launchables

- Step-by-step guide: [Run Open WebUI with vLLM on a cloud GPU](https://www.9owls.com/guides/run-open-webui-with-vllm-on-a-cloud-gpu/)
- [Serve an OpenAI-compatible API with vLLM](https://www.9owls.com/guides/serve-an-openai-compatible-api-with-vllm/)
- [Ollama vs vLLM](https://www.9owls.com/compare/ollama-vs-vllm/)
- [GPU comparison for LLM inference](https://www.9owls.com/compare/nvidia-l4-vs-l40s-for-llm-inference/)
- [How to deploy a Launchable on NVIDIA Brev](https://www.9owls.com/guides/deploy-a-launchable-on-nvidia-brev/)
- [How to stop and delete an NVIDIA Brev instance](https://www.9owls.com/guides/stop-start-and-delete-an-nvidia-brev-instance/)
- This Launchable on 9owls: https://www.9owls.com/launchables/open-webui-vllm/
- All Launchables by 9owls: https://www.9owls.com/launchables/
- Related: [Ollama + Open WebUI starter](https://www.9owls.com/launchables/ollama-open-webui/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M6T0t4dhogSr5ruwzfHUvkBAVN)); [Nemotron Chat with Open WebUI and vLLM](https://www.9owls.com/launchables/nemotron-chat/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aArulP2ZTX7HwqGLf4pwRT6z)); [RAGFlow on your own GPU](https://www.9owls.com/launchables/ragflow/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M7Rp4TmPPfR0piWdfBqcHweyVl))

## Keep your own stack running

NightKeeper packages your repository as an NVIDIA Brev Launchable, proves it on a fresh GPU and keeps it running. Your Brev API key stays in your repository's GitHub secrets. NightKeeper never sees it.

[Create your Launchable](https://www.9owls.com/nightkeeper/start/) or [read about NightKeeper](https://www.9owls.com/nightkeeper/).

## Credits and licences

- [vLLM](https://github.com/vllm-project/vllm): Apache-2.0.
- [Open WebUI](https://github.com/open-webui/open-webui): Open WebUI License.
- Models are downloaded from Hugging Face under their own licences: Qwen3-8B, Qwen3-32B-FP8 and gpt-oss-20b under Apache-2.0, Llama 3.1 8B Instruct under the Llama 3.1 Community License.

Files in this folder: `compose.yaml` (the stack, every image pinned) and [LICENSE](LICENSE) (Apache License 2.0 for the files in this folder, with upstream attributions).

Published and maintained by [9owls, Inc.](https://www.9owls.com/). Questions: hello@9owls.com.
