# Open WebUI + vLLM

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M6reXdi0sY0m18g80JNRJN0WtE)

A private chat assistant on your own GPU. [vLLM](https://github.com/vllm-project/vllm) serves an open-weight model through an OpenAI-compatible API, and [Open WebUI](https://github.com/open-webui/open-webui) gives you the browser chat interface, started together with Docker Compose. Nothing you type leaves the instance.

## What it runs

| Component | Version | Image |
| --- | --- | --- |
| vLLM (OpenAI-compatible server) | v0.33.0 (pinned) | `vllm/vllm-openai:v0.33.0` |
| Open WebUI | v0.13.3 (pinned) | `ghcr.io/open-webui/open-webui:v0.13.3` |

Open WebUI listens on port 8080. The vLLM API is bound to the instance itself (127.0.0.1:8000) and is not exposed publicly. The vLLM image is built on CUDA 13.0, so the instance's NVIDIA driver must support CUDA 13.

## Pick a model

Set the `MODEL` launch parameter when you deploy:

- `Qwen/Qwen3-8B` (default, about a 16 GB download)
- `Qwen/Qwen3-32B-FP8` (about a 34 GB download; needs a 48 GB GPU)
- `openai/gpt-oss-20b` (about a 14 GB download)
- `meta-llama/Llama-3.1-8B-Instruct` (gated, needs `HF_TOKEN`)

The model is downloaded once on first start and loaded from the local cache after that. The chat page opens before the download finishes; the model appears in the model picker once vLLM has loaded it. To change the model, deploy again with a different `MODEL`.

## Hugging Face token

`HF_TOKEN` is optional and is needed only for gated models such as `meta-llama/Llama-3.1-8B-Instruct`. Accept the model's licence on its Hugging Face page with the same account first. On the deploy page you can bind a saved secret or paste a read token. Never put a token anywhere except this parameter.

## Minimum GPU

NVIDIA L40S 48GB, with 128 GiB of disk for the container images and the model cache.

## Use it

1. Deploy and wait until the instance is Running.
2. Open the Open WebUI link. The first account you create becomes the Open WebUI admin, so create it right away.
3. Wait for the model to appear in the model picker, then chat.

To call the OpenAI-compatible API from your own machine, forward the port with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 8000:8000
curl http://localhost:8000/v1/models
```

## How data persists

Models and chats live on the instance:

- Models (Hugging Face cache): `~/workspace/huggingface`
- Chats, users and settings: `~/workspace/open-webui`

They survive a stop and start of the instance. They are removed when the instance is deleted.

## Stop or delete to control cost

- **Stop** the instance from the Brev console when you are not using it. Your models and chats are kept, and both containers start again on the next start (`restart: unless-stopped`). Storage is still billed while the instance is stopped.
- **Delete** the instance when you are finished. This removes the instance and all of its data, including downloaded models and chat history.

## Demo

Demo recording coming soon.

## Files

- `compose.yaml` - the stack, every image pinned.
- `LICENSE` - Apache-2.0 for the files in this folder, with upstream attributions.
