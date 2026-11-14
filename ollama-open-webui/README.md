# Ollama + Open WebUI starter

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=LAUNCHABLE_ID_PENDING)

A private, self-hosted chat assistant on your own GPU. This environment runs [Ollama](https://github.com/ollama/ollama) to serve open-weight language models and [Open WebUI](https://github.com/open-webui/open-webui) as the browser chat interface, started together with Docker Compose. On first start it downloads the model you choose, so the chat is ready to use as soon as the download finishes.

## What it runs

| Component | Version | Image |
| --- | --- | --- |
| Ollama | 0.40.16 (pinned) | `ollama/ollama:0.40.16` |
| Open WebUI | v0.13.3 (pinned) | `ghcr.io/open-webui/open-webui:v0.13.3` |

Open WebUI listens on port 8080. The Ollama API is bound to the instance itself (127.0.0.1:11434) and is not exposed publicly.

## Pick a model

Set the `MODEL` launch parameter when you deploy:

- `gpt-oss:20b` (default)
- `qwen3:14b`
- `gemma3:12b`

The model is pulled once on first start. You can pull more models later from the Open WebUI model settings.

## Minimum GPU

NVIDIA L4 24GB. The default model `gpt-oss:20b` uses about 16 GiB of GPU memory at Ollama's default context length.

## How data persists

Models and chats live on the instance, under `~/workspace/ollama` and `~/workspace/open-webui`. They survive a stop and start of the instance. They are removed when the instance is deleted.

## Stop or delete to control cost

- **Stop** the instance from the Brev console when you are not using it. Your models and chats are kept, and the containers start again on the next start.
- **Delete** the instance when you are finished. This removes the instance and all of its data, including downloaded models and chat history.

## Demo

Demo recording coming soon.
