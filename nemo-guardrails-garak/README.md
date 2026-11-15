# NeMo Guardrails + garak LLM Security Lab

Red team a chat model and see what guardrails change, on one GPU. [garak](https://github.com/NVIDIA/garak), the LLM vulnerability scanner, sends jailbreak and prompt-injection probes to the model twice: once directly, and once through [NeMo Guardrails](https://github.com/NVIDIA-NeMo/Guardrails) with content safety rails powered by [Nemotron 3.5 Content Safety](https://huggingface.co/nvidia/Nemotron-3.5-Content-Safety). [Open WebUI](https://github.com/open-webui/open-webui) shows the raw and the guarded model side by side, so you can try your own prompts against both.

Current versions: NeMo Guardrails 0.24.1, garak 0.17.1, vLLM v0.20.2, Open WebUI v0.13.3

Last smoke: not yet run

## What it runs

| Component | Version | Source |
| --- | --- | --- |
| vLLM (chat model and safety model, two processes) | v0.20.2 (pinned by digest) | `vllm/vllm-openai:v0.20.2` |
| NeMo Guardrails server | 0.24.1 (pinned) | `pip install nemoguardrails[server]==0.24.1` on `python:3.12.16-slim-bookworm` |
| garak | 0.17.1 (pinned) | `pip install garak==0.17.1` on `python:3.12.16-slim-bookworm` |
| Open WebUI | v0.13.3 (pinned) | `ghcr.io/open-webui/open-webui:v0.13.3` |

Models:

- Chat model, set by the `CHAT_MODEL` launch parameter:
  - `nvidia/NVIDIA-Nemotron-Nano-9B-v2` (default)
  - `Qwen/Qwen3-8B`
- Safety model: `nvidia/Nemotron-3.5-Content-Safety`, used by NeMo Guardrails for the input rail (checks each user prompt) and the output rail (checks each model answer).

All models are downloaded from Hugging Face on first start and none of them is gated, so no token is needed. `HF_TOKEN` is optional and only raises Hugging Face download rate limits. On the deploy page you can bind a saved secret or paste a read token. Never put a token anywhere except this parameter.

## Default GPU

The Launchable deploys on one NVIDIA L40S 48GB, with 200 GiB of disk for the container images, the Python environments and the model cache. Both models share the one GPU: the chat model gets 55 percent of GPU memory and the safety model 30 percent.

## Use it

1. Deploy and wait until the instance is Running. The first start downloads the images, both models and the Python packages, which takes a while.
2. Open the **compare-raw-vs-guarded** link (Open WebUI). The first account you create becomes the Open WebUI admin, so create it right away.
3. Open WebUI lists the chat model twice: once from the direct vLLM connection and once from the NeMo Guardrails connection (`compose.yaml` gives them the prefixes `raw` and `guarded`). Open a second chat with the other one and send the same prompt to both. When a rail blocks a prompt or an answer, the guarded model replies with a refusal instead.
4. Open the **garak-reports** link. When both models are ready, garak scans each one once with a fixed probe set (DAN-style jailbreak prompts, jailbreak prompts collected in the wild, and prompt-injection hijacks). Each scan's reports use the prefix `raw-model` or `guarded` and appear in this list when that scan finishes.

### Run the scan again

The scan runs once per instance. To run it again, for example after changing the guardrails configuration, open a terminal on the instance and run the commands below. The scan marker is owned by root inside the container, so it is removed through the container rather than from the host:

```
GARAK=$(docker ps -q --filter label=com.docker.compose.project=guardrails-garak --filter label=com.docker.compose.service=garak)
docker exec $GARAK rm /workspace/garak/.scanned
docker restart $GARAK
```

Reports from earlier runs stay in the list.

### Call the APIs from your own machine

Both APIs are OpenAI-compatible and bound to the instance itself. Forward them with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 8000:8000
brev port-forward INSTANCE_NAME --port 8001:8001
curl http://localhost:8000/v1/models
```

- `http://localhost:8000/v1` - guarded model (NeMo Guardrails)
- `http://localhost:8001/v1` - raw model (vLLM)

## How the guardrails are configured

The NeMo Guardrails configuration is written by the guardrails service command in `compose.yaml` (it creates `config.yml` and `prompts.yml` at start). It follows the NeMo Guardrails `nemotron-3.5-content-safety` example: the safety model's own chat template supplies the safety policy, and the input and output rails parse its `User Safety` and `Response Safety` verdicts. Edit that command and redeploy to add or change rails.

## How data persists

Everything lives on the instance under `/home/ubuntu/workspace`:

- Models (Hugging Face cache): `/home/ubuntu/workspace/huggingface`
- garak, its reports and scan state: `/home/ubuntu/workspace/garak`
- NeMo Guardrails Python environment: `/home/ubuntu/workspace/guardrails`
- Chats, users and settings: `/home/ubuntu/workspace/open-webui`

They survive a stop and start of the instance. They are removed when the instance is deleted.

## Stop or delete to control cost

- **Stop** the instance from the Brev console when you are not using it. Models, reports and chats are kept, and every service starts again on the next start (`restart: unless-stopped`). Storage is still billed while the instance is stopped.
- **Delete** the instance when you are finished. This removes the instance and all of its data, including downloaded models, reports and chat history.

## Responsible use

garak sends adversarial prompts on purpose. Scan only models and endpoints you own or are allowed to test. Reports can contain harmful text produced by the model under test.

## Files

- `compose.yaml` - the stack, every image and package pinned, with the NeMo Guardrails configuration inline.
- `LICENSE` - Apache-2.0 for the files in this folder, with upstream attributions and model licence notices.
