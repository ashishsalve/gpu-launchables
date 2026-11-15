# Nemotron Chat with Open WebUI and vLLM

A private chat assistant on your own GPU, powered by NVIDIA Nemotron. [vLLM](https://github.com/vllm-project/vllm) serves [NVIDIA Nemotron 3.5 Lightning](https://huggingface.co/nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4) through an OpenAI-compatible API, and [Open WebUI](https://github.com/open-webui/open-webui) gives you the browser chat interface, started together with Docker Compose. Prompts are answered by the model on your instance; no third-party model API is called.

Current versions: vllm/vllm-openai:v0.27.1, ghcr.io/open-webui/open-webui:v0.13.3, default model nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4

Last smoke: not yet run

## What it runs

| Component | Version | Image |
| --- | --- | --- |
| vLLM (OpenAI-compatible server) | v0.27.1 (pinned by digest) | `vllm/vllm-openai:v0.27.1` |
| Open WebUI | v0.13.3 (pinned) | `ghcr.io/open-webui/open-webui:v0.13.3` |

Open WebUI listens on port 8080. The vLLM API is bound to the instance itself (127.0.0.1:8000) and is not exposed publicly.

## Pick a model

Set the `MODEL` launch parameter when you deploy:

- `nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4` (default) - NVIDIA Nemotron 3.5 Lightning, a 30B-parameter hybrid Mamba-Transformer mixture-of-experts model with 3B active parameters, quantized to NVFP4. About a 25 GB download.
- `Qwen/Qwen3-8B` - an open alternative from the Qwen team. About a 16 GB download.

Both models are open on Hugging Face and need no access request. The model is downloaded once on first start and loaded from the local cache after that. The chat page opens before the download finishes; the model appears in the model picker once vLLM has loaded it. To change the model, deploy again with a different `MODEL`.

## Reasoning on or off

Each model has a reasoning mode that its chat template switches with `enable_thinking`; Nemotron 3.5 Lightning reasons by default. vLLM runs with the matching reasoning parser, so the reasoning trace comes back separately from the answer. For faster, shorter answers, turn reasoning off per request through the API with `"chat_template_kwargs": {"enable_thinking": false}` (see the example below). With reasoning on, the trace counts toward `max_tokens`, so allow a generous output budget (for example 2048 or more) or the answer can be cut off before it starts. The Nemotron 3.5 Lightning model card recommends temperature 1.0 and top_p 0.95, which this environment sets as the Open WebUI default.

## Hugging Face token

`HF_TOKEN` is optional: every model offered here is ungated. A token avoids anonymous download rate limits. On the deploy page you can bind a saved secret or paste a read token. Never put a token anywhere except this parameter.

## Default GPU and disk

Default instance: 1x NVIDIA L40S 48GB, with 200 GiB of disk for the container images and the model cache. The default model uses about 40 GB of GPU memory, so if you change the instance type, pick a GPU with 48 GB or more.

## Use it

1. Deploy and wait until the instance is Running.
2. Open the **chat-with-nemotron** link. The first account you create becomes the Open WebUI admin, so create it right away.
3. Wait for the model to appear in the model picker, then chat.

To call the OpenAI-compatible API from your own machine, forward the port with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 8000:8000
curl http://localhost:8000/v1/models
curl http://localhost:8000/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4","messages":[{"role":"user","content":"Say hello"}],"chat_template_kwargs":{"enable_thinking":false}}'
```

Use the `MODEL` value you deployed as the `model` field.

## How data persists

Models and chats live on the instance:

- Models (Hugging Face cache): `/home/ubuntu/workspace/huggingface`
- Chats, users and settings: `/home/ubuntu/workspace/open-webui`

They survive a stop and start of the instance. They are removed when the instance is deleted.

## Stop or delete to control cost

- **Stop** the instance from the Brev console when you are not using it. Your models and chats are kept, and both containers start again on the next start (`restart: unless-stopped`). Storage is still billed while the instance is stopped.
- **Delete** the instance when you are finished. This removes the instance and all of its data, including downloaded models and chat history.

## Licences and attribution

- NVIDIA Nemotron 3.5 Lightning is made available by NVIDIA Corporation under the [OpenMDW License Agreement, version 1.1](https://openmdw.ai/license/1-1/).
- Qwen3-8B is licensed under Apache 2.0.
- vLLM is licensed under Apache 2.0. Open WebUI is distributed under the Open WebUI License; this environment keeps its branding unchanged.

The model weights are downloaded directly from Hugging Face; this environment does not redistribute them. Read each model card before use.

## Files

- `compose.yaml` - the stack, every image pinned.
- `LICENSE` - Apache-2.0 for the files in this folder, with upstream attributions.
