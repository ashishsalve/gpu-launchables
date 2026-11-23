<p align="center">
  <strong>NeMo Guardrails and garak on NVIDIA Brev</strong><br>
  Red team a chat model and see what guardrails change, on one NVIDIA L40S: garak probes, NeMo Guardrails with Nemotron 3.5 Content Safety, vLLM and Open WebUI.
</p>

# NeMo Guardrails + garak LLM Security Lab

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8bOSWcMAZsaOnuaytHUvAEC0v)

Launchable ID: env-3M8bOSWcMAZsaOnuaytHUvAEC0v

Red team a chat model and see what guardrails change, on one NVIDIA L40S 48GB GPU. [garak](https://github.com/NVIDIA/garak), the LLM vulnerability scanner, sends jailbreak and prompt-injection probes to the model twice: once directly, and once through [NeMo Guardrails](https://github.com/NVIDIA-NeMo/Guardrails) with content safety rails powered by [Nemotron 3.5 Content Safety](https://huggingface.co/nvidia/Nemotron-3.5-Content-Safety). [Open WebUI](https://github.com/open-webui/open-webui) shows the raw and the guarded model side by side, so you can try your own prompts against both. First step: deploy, open the compare-raw-vs-guarded link, and send the same prompt to the raw and the guarded model.

| Quick facts | |
| --- | --- |
| Runs | vLLM (chat model and safety model), NeMo Guardrails server, garak and Open WebUI, five services under Docker Compose |
| Default compute | 1x NVIDIA L40S 48GB on AWS (g6e.xlarge, 4 vCPU, 32 GiB RAM), stoppable; you can pick another GPU on the deploy page |
| Disk | 200 GiB |
| Ready in | about 20 minutes to chat on a fresh deploy (2026-11-15); the garak reports appear later, after both scans finish |
| Cost | about $2.23/hr on the default compute (console, 2026-11-15); storage is billed while stopped |
| Secrets | `HF_TOKEN`, optional; all models are ungated |
| Licences | NeMo Guardrails Apache-2.0, garak Apache-2.0, vLLM Apache-2.0, Open WebUI License; model licence notices in [LICENSE](LICENSE) |
| Guide | https://www.9owls.com/launchables/nemo-guardrails-garak/ |

Current versions: NeMo Guardrails 0.24.1, garak 0.17.1, vLLM v0.20.2, Open WebUI v0.13.3

Last smoke: 2026-11-15, fresh deploy on one NVIDIA L40S 48GB, including stop and start.

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
- [Responsible use](#responsible-use)
- [FAQ](#faq)
- [Guides and related Launchables](#guides-and-related-launchables)
- [Keep your own stack running](#keep-your-own-stack-running)
- [Credits and licences](#credits-and-licences)

## What you get

| Component | Version | Image or file |
| --- | --- | --- |
| vLLM (chat model and safety model, two processes) | v0.20.2 (pinned by digest) | `vllm/vllm-openai:v0.20.2` |
| NeMo Guardrails server | 0.24.1 (pinned) | `pip install nemoguardrails[server]==0.24.1` on `python:3.12.16-slim-bookworm` |
| garak | 0.17.1 (pinned) | `pip install garak==0.17.1` on `python:3.12.16-slim-bookworm` |
| Open WebUI | v0.13.3 (pinned) | `ghcr.io/open-webui/open-webui:v0.13.3` |

Models:

- Chat model, set by the `CHAT_MODEL` launch parameter: `nvidia/NVIDIA-Nemotron-Nano-9B-v2` (default) or `Qwen/Qwen3-8B`.
- Safety model: `nvidia/Nemotron-3.5-Content-Safety`, used by NeMo Guardrails for the input rail (checks each user prompt) and the output rail (checks each model answer).

All models are downloaded from Hugging Face on first start and none of them is gated, so no token is needed.

## Deploy in three steps

1. Click Launch on Brev, keep the NVIDIA L40S, pick the chat model (or keep the default), and deploy. `HF_TOKEN` can stay empty.
2. Wait until the instance shows Running and the **compare-raw-vs-guarded** link loads Open WebUI. The first start downloads the images, both models and the Python packages; on the 2026-11-15 fresh deploy chat was ready in about 20 minutes.
3. Open **compare-raw-vs-guarded** and create your account right away: the first account you create becomes the Open WebUI admin.

## Try it first

1. Compare raw and guarded replies. Open WebUI lists the chat model twice: once from the direct vLLM connection and once from the NeMo Guardrails connection (`compose.yaml` gives them the prefixes `raw` and `guarded`). Open one chat with each and send the same prompt to both. When a rail blocks a prompt or an answer, the guarded model replies with a refusal instead.
2. Send a prompt injection. In the 2026-11-15 smoke, a prompt-injection request through the guarded API was refused with "I'm sorry, I can't respond to that.", while a benign question was answered normally.
3. Read the garak reports. Open the **garak-reports** link. When both models are ready, garak scans each one once with a fixed probe set (DAN-style jailbreak prompts, jailbreak prompts collected in the wild, and prompt-injection hijacks). Each scan's reports use the prefix `raw-model` or `guarded` and appear in this list when that scan finishes.

## How it works

- Five services, started with Docker Compose from pinned images and packages: `vllm-safety`, `vllm-chat`, `guardrails`, `open-webui` and `garak`.
- Both models share the one GPU: the chat model gets 55 percent of GPU memory and the safety model 30 percent.
- Open WebUI listens on port 8080 behind the authenticated Brev Secure Link **compare-raw-vs-guarded**.
- garak serves its reports on port 8888 behind the **garak-reports** link. That page starts only after the first scan has finished; until then the link does not load.
- Two OpenAI-compatible APIs are bound to the instance itself: the guarded model (NeMo Guardrails) on port 8000 and the raw model (vLLM) on port 8001. Neither is exposed to the internet.
- Models run on the instance. garak sends its probes only to the two endpoints on the instance.

<details>
<summary>Advanced: how the guardrails are configured</summary>

The NeMo Guardrails configuration is written by the guardrails service command in `compose.yaml` (it creates `config.yml` and `prompts.yml` at start). It follows the NeMo Guardrails `nemotron-3.5-content-safety` example: the safety model's own chat template supplies the safety policy, and the input and output rails parse its `User Safety` and `Response Safety` verdicts. Edit that command and redeploy to add or change rails.

</details>

<details>
<summary>Advanced: run the garak scan again</summary>

The scan runs once per instance. To run it again, for example after changing the guardrails configuration, open a terminal on the instance and run the commands below. The scan marker is owned by root inside the container, so it is removed through the container rather than from the host:

```
GARAK=$(docker ps -q --filter label=com.docker.compose.project=guardrails-garak --filter label=com.docker.compose.service=garak)
docker exec $GARAK rm /workspace/garak/.scanned
docker restart $GARAK
```

Reports from earlier runs stay in the list.

</details>

## Settings

| Parameter | Required | Default | What it does |
| --- | --- | --- | --- |
| `CHAT_MODEL` | no | `nvidia/NVIDIA-Nemotron-Nano-9B-v2` | Chat model that vLLM serves and NeMo Guardrails protects: `nvidia/NVIDIA-Nemotron-Nano-9B-v2` (about an 18 GB download) or `Qwen/Qwen3-8B` (about a 16 GB download). Both are ungated. |
| `HF_TOKEN` | no | none | Optional Hugging Face read token. It only raises Hugging Face download rate limits. On the deploy page you can bind a saved secret or paste a read token. Never put a token anywhere except this parameter. |

## Use it from your machine

Both APIs are OpenAI-compatible and bound to the instance itself. Forward them with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 8000:8000
brev port-forward INSTANCE_NAME --port 8001:8001
curl http://localhost:8000/v1/models
```

- `http://localhost:8000/v1` - guarded model (NeMo Guardrails)
- `http://localhost:8001/v1` - raw model (vLLM)

## Data and persistence

Everything lives on the instance under `/home/ubuntu/workspace`:

- Models (Hugging Face cache): `/home/ubuntu/workspace/huggingface`
- garak, its reports and scan state: `/home/ubuntu/workspace/garak`
- NeMo Guardrails Python environment: `/home/ubuntu/workspace/guardrails`
- Chats, users and settings: `/home/ubuntu/workspace/open-webui`

They survive a stop and start of the instance. They are removed when the instance is deleted.

## Stop, start and delete

- **Stop** the instance from the Brev console when you are not using it. Models, reports and chats are kept. Storage is still billed while the instance is stopped.
- **Start** it again: stopping removes the lab's containers, and starting recreates them automatically, usually within a few minutes. If the lab is not back after 5 minutes, use the recovery command under Troubleshooting.
- **Delete** the instance when you are finished. This removes the instance and all of its data, including downloaded models, reports and chat history.

## Troubleshooting

<details>
<summary>The lab is not back after a stop and start</summary>

Stopping the instance removes the lab's containers; everything under ~/workspace is kept. Starting it again recreates the containers automatically, usually within a few minutes. If the lab is not back after 5 minutes, open a terminal on the instance and run:

```
cd /home/ubuntu/workspace && sudo docker compose up -d
```

</details>

<details>
<summary>The garak-reports link does not load</summary>

This is expected until the first scan has finished. garak scans the raw and the guarded endpoint first and only then starts its report page on port 8888. Keep using Open WebUI and reload the link later.

</details>

<details>
<summary>Chat replies include the model's reasoning text</summary>

With the default `nvidia/NVIDIA-Nemotron-Nano-9B-v2`, no reasoning parser is set in vLLM, so the reply content can include the model's reasoning before the answer. The model card switches reasoning with `/think` and `/no_think` in the system prompt.

</details>

## Responsible use

garak sends adversarial prompts on purpose. Scan only models and endpoints you own or are allowed to test. Reports can contain harmful text produced by the model under test.

## FAQ

### Which GPU do I need?

The default is one NVIDIA L40S 48GB with 200 GiB of disk. Both models run on that one GPU, sharing its memory 55 and 30 percent; in the 2026-11-15 smoke they used 38770 of 46068 MiB.

### Does anything leave the instance?

The models, the guardrails and garak all run on the instance, and the two APIs are bound to the instance itself. On first start the instance downloads the container images, the Python packages and the models from Hugging Face.

### Can I run this on my own hardware?

Yes, the stack is the `compose.yaml` in this folder with public images and packages. See [NeMo Guardrails](https://github.com/NVIDIA-NeMo/Guardrails), [garak](https://github.com/NVIDIA/garak) and [vLLM](https://github.com/vllm-project/vllm) for supported GPUs and drivers.

### How do I update to a newer version?

This Launchable pins every image and package so every deploy is the same. To try a newer release on your own instance, change the version in `compose.yaml` under `/home/ubuntu/workspace` and run `sudo docker compose up -d`; your data under `/home/ubuntu/workspace` is kept.

## Guides and related Launchables

- Step-by-step guide: [How to run a garak LLM vulnerability scan with NeMo Guardrails](https://www.9owls.com/guides/run-a-garak-llm-vulnerability-scan-with-nemo-guardrails/)
- [Red team an AI agent with garak and NeMo Guardrails](https://www.9owls.com/guides/red-team-an-ai-agent-with-garak-and-nemo-guardrails/)
- [How to deploy a Launchable on NVIDIA Brev](https://www.9owls.com/guides/deploy-a-launchable-on-nvidia-brev/)
- [Serve an OpenAI-compatible API with vLLM](https://www.9owls.com/guides/serve-an-openai-compatible-api-with-vllm/)
- [Run Open WebUI with vLLM on a cloud GPU](https://www.9owls.com/guides/run-open-webui-with-vllm-on-a-cloud-gpu/)
- [How to stop and delete an NVIDIA Brev instance](https://www.9owls.com/guides/stop-start-and-delete-an-nvidia-brev-instance/)
- [NVIDIA L4 vs L40S for LLM inference](https://www.9owls.com/compare/nvidia-l4-vs-l40s-for-llm-inference/)
- To red team a tool-using agent instead of a chat model: [OpenShell + garak Agent Safety Lab](https://www.9owls.com/launchables/openshell-garak-agent-safety-lab/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3MK1o9MUGMtZElFZvoYphMsZUmB))
- This Launchable on 9owls: https://www.9owls.com/launchables/nemo-guardrails-garak/
- All Launchables by 9owls: https://www.9owls.com/launchables/
- Related: [Nemotron Chat with Open WebUI and vLLM](https://www.9owls.com/launchables/nemotron-chat/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aArulP2ZTX7HwqGLf4pwRT6z)); [Open WebUI + vLLM](https://www.9owls.com/launchables/open-webui-vllm/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M6reXdi0sY0m18g80JNRJN0WtE)); [OpenHands Coding Agent on Nemotron](https://www.9owls.com/launchables/openhands-nemotron/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8b2pM4xEhrOmr5yEObCVI7kyS))

## Keep your own stack running

NightKeeper packages your repository as an NVIDIA Brev Launchable, proves it on a fresh GPU and keeps it running. Your Brev API key stays in your repository's GitHub secrets. NightKeeper never sees it.

[Create your Launchable](https://www.9owls.com/nightkeeper/start/) or [read about NightKeeper](https://www.9owls.com/nightkeeper/).

## Credits and licences

- [NeMo Guardrails](https://github.com/NVIDIA-NeMo/Guardrails): Apache-2.0.
- [garak](https://github.com/NVIDIA/garak): Apache-2.0.
- [vLLM](https://github.com/vllm-project/vllm): Apache-2.0.
- [Open WebUI](https://github.com/open-webui/open-webui): Open WebUI License.
- `nvidia/NVIDIA-Nemotron-Nano-9B-v2`: NVIDIA Open Model License. `nvidia/Nemotron-3.5-Content-Safety`: OpenMDW-1.1, built on Gemma 3 and subject to the Gemma Terms of Use and the Gemma Prohibited Use Policy. `Qwen/Qwen3-8B`: Apache-2.0. Notices are in [LICENSE](LICENSE).

Files in this folder: `compose.yaml` (the stack, every image and package pinned, with the NeMo Guardrails configuration inline) and [LICENSE](LICENSE) (Apache License 2.0 for the files in this folder, with upstream attributions and model licence notices).

Published and maintained by [9owls, Inc.](https://www.9owls.com/). Questions: hello@9owls.com.
