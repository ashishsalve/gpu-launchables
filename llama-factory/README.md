# LlamaFactory (LlamaBoard)

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M7QbAu67oVXAOLqhezAb8g5EVD)

No-code fine-tuning of open LLMs in the browser. [LlamaFactory](https://github.com/hiyouga/LLaMA-Factory)'s LlamaBoard web UI runs LoRA, QLoRA and full fine-tuning of 100+ open models, from dataset to exported model. Pick a base model at launch; your datasets, checkpoints and exports persist across a stop and start.

Last smoke: 2026-11-15, fresh deploy on one NVIDIA L40S 48GB. LlamaBoard answered on port 7860 about 10 minutes after launch; the default Qwen3-8B download (16 GB) completed in the background.

## What it runs

| Component | Version | Image |
| --- | --- | --- |
| LlamaFactory with LlamaBoard | v0.9.5 (pinned) | `hiyouga/llamafactory:0.9.5` |

The official public image runs unmodified as one Docker Compose service ([compose.yaml](compose.yaml)); nothing is built. For a reproducible pull, the tag's digest is:

```
hiyouga/llamafactory:0.9.5@sha256:c5e769e047a19f9322800c9881a6270557ef0e6682f0145b50b322f8724de6b6
```

LlamaBoard listens on port 7860.

## Pick a base model

Set the `BASE_MODEL` launch parameter when you deploy. It is downloaded on first start at a fixed Hugging Face commit:

| Model | Size | Licence | Commit |
| --- | --- | --- | --- |
| `Qwen/Qwen3-8B` (default) | 8.2B | Apache-2.0 | `b968826d9c46dd6066d109eabc6255188de91218` |
| `Qwen/Qwen3-4B-Instruct-2507` | 4.0B | Apache-2.0 | `cdbee75f17c01a7cc42f958dc650907174af0554` |
| `meta-llama/Llama-3.1-8B-Instruct` | 8.0B | Llama 3.1 Community License (gated) | `0e9e39f249a16976918f6564b8830bc894c89659` |
| `none` | - | - | download nothing |

You can still pick any other Hugging Face model inside LlamaBoard. LlamaBoard opens before the base model download finishes; the default model takes several minutes.

## Hugging Face token

`HF_TOKEN` is optional. It is needed only for gated models such as Llama-3.1-8B-Instruct, from a Hugging Face account that has been granted access, and it also raises download rate limits. On the deploy page you can bind a saved secret or paste the value. The token is read from the environment by the Hugging Face client and is never printed or passed on a command line.

## GPU and disk

The default deploy is one NVIDIA L40S 48GB with 256 GiB of disk. LoRA and QLoRA on the default 8B model fit comfortably. LlamaFactory documents about 16 GB of GPU memory for LoRA and about 60 GB for full bf16 fine-tuning of a 7B model, so choose an 80 GB GPU if you plan full fine-tuning.

## How it starts

The `llamaboard` service in [compose.yaml](compose.yaml) runs a short start script on every start:

1. Works from `/root/workspace/llamafactory`, so LlamaBoard's `data/`, `saves/`, `llamaboard_cache/` and `llamaboard_config/` live in the workspace.
2. Copies LlamaFactory's bundled example datasets (`/app/data`) into the workspace once.
3. Points the Hugging Face cache at `/root/workspace/llamafactory/hf`.
4. Downloads the chosen base model in the background with `hf download` into `/root/workspace/llamafactory/models/<model name>`. Files already present are not downloaded again. Progress goes to `/root/workspace/llamafactory/logs/model-fetch.log`.
5. Starts LlamaBoard on port 7860.

The service runs with `ipc: host`, as the LlamaFactory documentation recommends, so the data loaders have enough shared memory.

To run the same stack on your own machine with Docker Compose and the NVIDIA Container Toolkit, download [compose.yaml](compose.yaml) and run:

```
BASE_MODEL=Qwen/Qwen3-8B docker compose up -d
```

## Use it

1. Deploy and wait until the instance is Running.
2. Open the LlamaBoard link.
3. Check `/root/workspace/llamafactory/logs/model-fetch.log` for a `fetch-model: ... complete` line, then set **Model path** to the downloaded model, for example `/root/workspace/llamafactory/models/Qwen3-8B`, and pick the matching model name.
4. Choose a fine-tuning method (LoRA is a good start), pick a dataset (bundled examples such as `identity` work out of the box, or add your own to `data/` and register it in `data/dataset_info.json`), and press **Start**.
5. Chat with the result in the **Chat** tab, then merge and save it in the **Export** tab.

To reach LlamaBoard from your own machine without the browser link, forward the port with the Brev CLI and open `http://localhost:7860`:

```
brev port-forward INSTANCE_NAME --port 7860:7860
```

## How data persists

Everything lives under `/root/workspace/llamafactory` inside the container:

- Datasets and `dataset_info.json`: `/root/workspace/llamafactory/data`
- Checkpoints, LoRA adapters and training logs: `/root/workspace/llamafactory/saves`
- Downloaded base models: `/root/workspace/llamafactory/models`
- Hugging Face cache: `/root/workspace/llamafactory/hf`
- LlamaBoard settings: `/root/workspace/llamafactory/llamaboard_config`

It survives a stop and start of the instance. It is removed when the instance is deleted.

## Stop or delete to control cost

- **Stop** the instance from the Brev console when you are not training. Your files are kept and nothing needs re-entering after the next start. A training run that was in progress does not resume by itself; restart it from its last checkpoint in LlamaBoard. Storage is still billed while the instance is stopped.
- **Delete** the instance when you are finished. This removes the instance and every file on it, including datasets, checkpoints and exported models. Download or push your models first.

## Acknowledgements

- [LlamaFactory](https://github.com/hiyouga/LLaMA-Factory) by hiyouga and contributors, Apache-2.0. LlamaBoard is its web UI. If you use it in research, cite LlamaFactory as its README asks.
- Model weights keep their own licences; read them on Hugging Face before use.
- `LICENSE` - Apache-2.0 for the files in this folder, with the third-party notices.
