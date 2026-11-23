<p align="center">
  <strong>LlamaFactory on NVIDIA Brev</strong><br>
  No-code LoRA and QLoRA fine-tuning of open LLMs in the browser with the LlamaBoard web UI, on one NVIDIA L40S 48GB GPU.
</p>

# LlamaFactory (LlamaBoard)

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M7QbAu67oVXAOLqhezAb8g5EVD)

Launchable ID: env-3M7QbAu67oVXAOLqhezAb8g5EVD

No-code fine-tuning of open LLMs in the browser. [LlamaFactory](https://github.com/hiyouga/LLaMA-Factory)'s LlamaBoard web UI runs LoRA, QLoRA and full fine-tuning of 100+ open models, from dataset to exported model, here on one NVIDIA L40S 48GB GPU. Pick a base model at launch; your datasets, checkpoints and exports persist across a stop and start. First step: deploy, open LlamaBoard from the open-llamaboard link, and run a LoRA fine-tune on the bundled `identity` dataset.

| Quick facts | |
| --- | --- |
| Runs | LlamaFactory v0.9.5 with the LlamaBoard web UI, one container under Docker Compose |
| Default compute | 1x NVIDIA L40S 48GB on AWS (g6e.xlarge), stoppable; you can pick another GPU on the deploy page |
| Disk | 256 GiB |
| Ready in | about 10 minutes on a fresh deploy (2026-11-15); the base model download continues in the background |
| Cost | about $2.23/hr on the default compute (console, 2026-11-15); storage is billed while stopped |
| Secrets | `HF_TOKEN`, optional, only for gated models such as Llama-3.1-8B-Instruct |
| Licences | LlamaFactory Apache-2.0; model weights keep their own licences |
| Guide | https://www.9owls.com/launchables/llama-factory/ |

Current versions: LlamaFactory v0.9.5, image hiyouga/llamafactory:0.9.5@sha256:c5e769e047a19f9322800c9881a6270557ef0e6682f0145b50b322f8724de6b6

Last smoke: 2026-11-15, fresh deploy on one NVIDIA L40S 48GB. LlamaBoard answered on port 7860 about 10 minutes after launch; the default Qwen3-8B download (16 GB) completed in the background.

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
| LlamaFactory with LlamaBoard | v0.9.5 (pinned by tag and digest) | `hiyouga/llamafactory:0.9.5` |
| Base model (your choice at launch) | pinned to a fixed Hugging Face commit | downloaded on first start, see [Settings](#settings) |
| Bundled example datasets | as shipped in the v0.9.5 image | copied into the workspace once |

The official public image runs unmodified as one Docker Compose service ([compose.yaml](compose.yaml)); nothing is built. For a reproducible pull, the tag's digest is:

```
hiyouga/llamafactory:0.9.5@sha256:c5e769e047a19f9322800c9881a6270557ef0e6682f0145b50b322f8724de6b6
```

## Deploy in three steps

1. Click Launch on Brev, keep the NVIDIA L40S or pick another GPU, choose a `BASE_MODEL` (default `Qwen/Qwen3-8B`), add `HF_TOKEN` only for a gated model, and deploy.
2. Wait until the instance shows Running and the **open-llamaboard** link loads LlamaBoard. On a fresh deploy this took about 10 minutes. LlamaBoard opens before the base model download finishes; the default model takes several minutes more.
3. Click **open-llamaboard**. When the model download log shows a `fetch-model: ... complete` line (see [Troubleshooting](#troubleshooting)), set **Model path** to the downloaded model, for example `/root/workspace/llamafactory/models/Qwen3-8B`, and pick the matching model name.

## Try it first

1. A first LoRA run: choose LoRA as the fine-tuning method, pick the bundled `identity` dataset, and press **Start**. Checkpoints and training logs are written under `/root/workspace/llamafactory/saves`.
2. Chat with the result in the **Chat** tab, then merge and save it in the **Export** tab.
3. Your own data: add a dataset file to `data/` and register it in `data/dataset_info.json` under `/root/workspace/llamafactory`, then pick it in LlamaBoard.

## How it works

- One container, started with Docker Compose from the pinned official LlamaFactory v0.9.5 image.
- LlamaBoard listens on port 7860 and is reached through the authenticated Brev Secure Link **open-llamaboard**. No other ports are opened, and the LlamaFactory API server is not started.
- The model is trained and served on your instance's GPU. Model and dataset downloads come from Hugging Face.
- The service runs with `ipc: host`, as the LlamaFactory documentation recommends, so the data loaders have enough shared memory.
- The service has `restart: unless-stopped`, so LlamaBoard starts again with the instance.

<details>
<summary>Advanced: what the start script does</summary>

The `llamaboard` service in [compose.yaml](compose.yaml) runs a short start script on every start:

1. Works from `/root/workspace/llamafactory`, so LlamaBoard's `data/`, `saves/`, `llamaboard_cache/` and `llamaboard_config/` live in the workspace.
2. Copies LlamaFactory's bundled example datasets (`/app/data`) into the workspace once.
3. Points the Hugging Face cache at `/root/workspace/llamafactory/hf`.
4. Downloads the chosen base model in the background with `hf download` into `/root/workspace/llamafactory/models/<model name>`. Files already present are not downloaded again. Progress goes to `/root/workspace/llamafactory/logs/model-fetch.log`.
5. Starts LlamaBoard on port 7860.

</details>

## Settings

| Parameter | Required | Default | What it does |
| --- | --- | --- | --- |
| `BASE_MODEL` | yes (has a default) | `Qwen/Qwen3-8B` | Base model downloaded on first start at a fixed Hugging Face commit; `none` downloads nothing |
| `HF_TOKEN` | no | none | Hugging Face token, needed only for gated models such as Llama-3.1-8B-Instruct; also raises download rate limits |

`BASE_MODEL` choices:

| Model | Size | Licence | Commit |
| --- | --- | --- | --- |
| `Qwen/Qwen3-8B` (default) | 8.2B | Apache-2.0 | `b968826d9c46dd6066d109eabc6255188de91218` |
| `Qwen/Qwen3-4B-Instruct-2507` | 4.0B | Apache-2.0 | `cdbee75f17c01a7cc42f958dc650907174af0554` |
| `meta-llama/Llama-3.1-8B-Instruct` | 8.0B | Llama 3.1 Community License (gated) | `0e9e39f249a16976918f6564b8830bc894c89659` |
| `none` | - | - | download nothing |

You can still pick any other Hugging Face model inside LlamaBoard.

`HF_TOKEN` must come from a Hugging Face account that has been granted access to the gated model. On the deploy page you can bind a saved secret or paste the value. The token is read from the environment by the Hugging Face client and is never printed or passed on a command line.

## Use it from your machine

To reach LlamaBoard without the browser link, forward the port with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 7860:7860
```

Then open `http://localhost:7860` locally.

## Data and persistence

Everything lives under `/root/workspace/llamafactory` inside the container:

- Datasets and `dataset_info.json`: `/root/workspace/llamafactory/data`
- Checkpoints, LoRA adapters and training logs: `/root/workspace/llamafactory/saves`
- Downloaded base models: `/root/workspace/llamafactory/models`
- Hugging Face cache: `/root/workspace/llamafactory/hf`
- LlamaBoard settings: `/root/workspace/llamafactory/llamaboard_config`

It survives a stop and start of the instance. It is removed when the instance is deleted.

## Stop, start and delete

- **Stop** the instance from the Brev console when you are not training. Your files are kept and nothing needs re-entering after the next start. Storage is still billed while the instance is stopped.
- **Start** it again: LlamaBoard comes back with your files. A training run that was in progress does not resume by itself; restart it from its last checkpoint in LlamaBoard.
- **Delete** the instance when you are finished. This removes the instance and every file on it, including datasets, checkpoints and exported models. Download or push your models first.

## Troubleshooting

<details>
<summary>The base model does not appear yet</summary>

LlamaBoard opens before the base model download finishes. Open a shell with `brev shell INSTANCE_NAME`, find the container with `sudo docker ps`, then run `sudo docker exec CONTAINER tail -n 5 /root/workspace/llamafactory/logs/model-fetch.log`. When it shows a `fetch-model: ... complete` line, set **Model path** to the folder under `/root/workspace/llamafactory/models`.

</details>

<details>
<summary>The open-llamaboard link does not load right after deploy</summary>

On a fresh deploy LlamaBoard answered about 10 minutes after launch, because the instance first pulls the LlamaFactory image. Wait, then reload the link.

</details>

<details>
<summary>The Llama-3.1-8B-Instruct download fails</summary>

This model is gated. Deploy with `HF_TOKEN` set to a token from a Hugging Face account that has been granted access to the model, or pick one of the Qwen choices.

</details>

<details>
<summary>Training runs out of GPU memory</summary>

The launch choices (4B to 8B models) are sized for LoRA and QLoRA on the 48 GB L40S. Full bf16 fine-tuning of a 7B model needs about 60 GB of GPU memory per the LlamaFactory documentation, so use LoRA or QLoRA here, or deploy on an 80 GB GPU.

</details>

## FAQ

### Which GPU do I need for LlamaFactory?

The default is one NVIDIA L40S 48GB with 256 GiB of disk, and the 4B to 8B launch choices are sized for LoRA and QLoRA on it. LlamaFactory documents about 16 GB of GPU memory for LoRA and about 60 GB for full bf16 fine-tuning of a 7B model, so choose an 80 GB GPU if you plan full fine-tuning.

### What does it cost to leave it running?

A running instance bills by the hour for the GPU you chose; the deploy page shows the current price before you deploy. A stopped instance bills only its storage. Delete the instance when you are finished to stop all charges for it.

### Where do my datasets and checkpoints live?

Under `/root/workspace/llamafactory` inside the container: datasets in `data`, checkpoints and LoRA adapters in `saves`, base models in `models`. They survive Stop and are removed by Delete.

### Does anything leave the instance?

Training and chat run on your instance's GPU. The instance downloads the base model and any datasets or models you pick from Hugging Face; when `HF_TOKEN` is set, the Hugging Face client sends it to Hugging Face for those downloads.

### Can I run this on my own hardware?

Yes. With Docker Compose and the NVIDIA Container Toolkit, download [compose.yaml](compose.yaml) and run `BASE_MODEL=Qwen/Qwen3-8B docker compose up -d`. See [LlamaFactory](https://github.com/hiyouga/LLaMA-Factory) for supported models and hardware.

### How do I update to a newer LlamaFactory version?

This Launchable pins LlamaFactory v0.9.5 by tag and digest so every deploy is the same. To try a newer release on your own machine, change the image tag in [compose.yaml](compose.yaml) and start it again; keep a copy of your `saves` folder first.

## Guides and related Launchables

- Step-by-step guide: [How to fine-tune an LLM with LlamaFactory](https://www.9owls.com/guides/fine-tune-an-llm-with-llamafactory/)
- [How to deploy a Launchable on NVIDIA Brev](https://www.9owls.com/guides/deploy-a-launchable-on-nvidia-brev/)
- [Stop, start and delete an NVIDIA Brev instance](https://www.9owls.com/guides/stop-start-and-delete-an-nvidia-brev-instance/)
- [Brev Launchables FAQ](https://www.9owls.com/faq/brev-launchable-basics/): billing, persistence and choosing a GPU
- [GPU memory and model fit](https://www.9owls.com/compare/nvidia-l4-vs-l40s-for-llm-inference/): how much model fits on the NVIDIA L40S
- [Serve an OpenAI-compatible API with vLLM](https://www.9owls.com/guides/serve-an-openai-compatible-api-with-vllm/)
- [Train a FLUX LoRA on a cloud GPU](https://www.9owls.com/guides/train-a-flux-lora-on-a-cloud-gpu/)
- [Fine-tuning Launchables](https://www.9owls.com/topics/fine-tuning/): other fine-tuning stacks on NVIDIA Brev
- This Launchable on 9owls: https://www.9owls.com/launchables/llama-factory/
- All Launchables by 9owls: https://www.9owls.com/launchables/
- Related: [LoRA Training (ai-toolkit + kohya_ss)](https://www.9owls.com/launchables/lora-training/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M77hJCDpHkAGNvOR4xmmgsC1KA)); [Nemotron Chat with Open WebUI and vLLM](https://www.9owls.com/launchables/nemotron-chat/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aArulP2ZTX7HwqGLf4pwRT6z)); [Open WebUI + vLLM](https://www.9owls.com/launchables/open-webui-vllm/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M6reXdi0sY0m18g80JNRJN0WtE))

## Keep your own stack running

NightKeeper packages your repository as an NVIDIA Brev Launchable, proves it on a fresh GPU and keeps it running. Your Brev API key stays in your repository's GitHub secrets. NightKeeper never sees it.

[Create your Launchable](https://www.9owls.com/nightkeeper/start/) or [read about NightKeeper](https://www.9owls.com/nightkeeper/).

## Credits and licences

- [LlamaFactory](https://github.com/hiyouga/LLaMA-Factory) by hiyouga and contributors, Apache-2.0. LlamaBoard is its web UI. If you use it in research, cite LlamaFactory as its README asks.
- Model weights keep their own licences; read them on Hugging Face before use.

Files in this folder: [compose.yaml](compose.yaml) (the stack, image pinned by tag and digest) and [LICENSE](LICENSE) (Apache License 2.0 for the files in this folder, with the third-party notices).

Published and maintained by [9owls, Inc.](https://www.9owls.com/). Questions: hello@9owls.com.
