# LlamaFactory (LlamaBoard)

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=LAUNCHABLE_ID_PENDING)

No-code fine-tuning of open LLMs in the browser. [LlamaFactory](https://github.com/hiyouga/LLaMA-Factory)'s LlamaBoard web UI runs LoRA, QLoRA and full fine-tuning of 100+ open models, from dataset to exported model. Pick a base model at launch; your datasets, checkpoints and exports persist across a stop and start.

## What it runs

| Component | Version | Image |
| --- | --- | --- |
| LlamaFactory with LlamaBoard | v0.9.5 (pinned) | `hiyouga/llamafactory:0.9.5` |

The official public image runs unmodified as a single container; nothing is built. For a reproducible pull, the tag's digest is:

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

You can still pick any other Hugging Face model inside LlamaBoard. LlamaBoard opens before the base model download finishes; large models take several minutes.

## Hugging Face token

`HF_TOKEN` is optional. It is needed only for gated models such as Llama-3.1-8B-Instruct, from a Hugging Face account that has been granted access, and it also raises download rate limits. On the deploy page you can bind a saved secret or paste the value. The token is read from the environment by the Hugging Face client and is never printed or passed on a command line.

## Minimum GPU

NVIDIA A100 80GB, with 100 GiB of disk. LlamaFactory documents about 16 GB of GPU memory for LoRA and about 60 GB for full bf16 fine-tuning of a 7B model, and less with QLoRA. On a smaller GPU, use LoRA or QLoRA.

## How the container starts

The container runs this start command:

```
/bin/bash -c 'set -euo pipefail; W=/root/workspace/llamafactory; mkdir -p "$W/models" "$W/logs" "$W/hf"; cd "$W"; test -d data || cp -r /app/data ./data; export HF_HOME="$W/hf"; test -n "${HF_TOKEN:-}" || unset HF_TOKEN; M="${BASE_MODEL:-Qwen/Qwen3-8B}"; case "$M" in Qwen/Qwen3-8B) R=b968826d9c46dd6066d109eabc6255188de91218 ;; Qwen/Qwen3-4B-Instruct-2507) R=cdbee75f17c01a7cc42f958dc650907174af0554 ;; meta-llama/Llama-3.1-8B-Instruct) R=0e9e39f249a16976918f6564b8830bc894c89659 ;; none) R= ;; *) echo "unknown BASE_MODEL $M" >&2; exit 1 ;; esac; if test -n "$R"; then (python -c "import sys; from huggingface_hub import snapshot_download; snapshot_download(sys.argv[1], revision=sys.argv[2], local_dir=sys.argv[3])" "$M" "$R" "$W/models/${M#*/}" && echo "fetch-model: $M $R complete") >>"$W/logs/model-fetch.log" 2>&1 & fi; exec llamafactory-cli webui'
```

On every start it:

1. Works from `/root/workspace/llamafactory`, so LlamaBoard's `data/`, `saves/`, `llamaboard_cache/` and `llamaboard_config/` live in the workspace.
2. Copies LlamaFactory's bundled example datasets (`/app/data`) into the workspace once.
3. Points the Hugging Face cache at `/root/workspace/llamafactory/hf`.
4. Downloads the chosen base model in the background into `/root/workspace/llamafactory/models/<model name>`. Files already present are not downloaded again. Progress goes to `/root/workspace/llamafactory/logs/model-fetch.log`.
5. Starts LlamaBoard on port 7860.

To run the same container on your own machine with Docker and the NVIDIA Container Toolkit:

```
docker run -d --name llamaboard --gpus all --ipc=host --restart unless-stopped \
  -p 7860:7860 \
  -e BASE_MODEL=Qwen/Qwen3-8B -e HF_TOKEN \
  -v "$HOME/llamaboard-workspace:/root/workspace" \
  hiyouga/llamafactory:0.9.5@sha256:c5e769e047a19f9322800c9881a6270557ef0e6682f0145b50b322f8724de6b6 \
  /bin/bash -c '<the start command above, between the single quotes>'
```

`--ipc=host` follows the LlamaFactory documentation and gives the data loaders enough shared memory.

## Use it

1. Deploy and wait until the instance is Running.
2. Open the LlamaBoard link.
3. Check `/root/workspace/llamafactory/logs/model-fetch.log` for a `fetch-model: ... complete` line, then set **Model path** to the downloaded model, for example `/root/workspace/llamafactory/models/Qwen3-8B`, and pick the matching model name.
4. Choose a fine-tuning method (LoRA is a good start), pick a dataset (bundled examples such as `identity` work out of the box, or add your own to `data/` and register it in `data/dataset_info.json`), and press **Start**.
5. Chat with the result in the **Chat** tab, then merge and save it in the **Export** tab.

To reach LlamaBoard from your own machine, forward the port with the Brev CLI and open `http://localhost:7860`:

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

## Demo

Demo recording coming soon.

## Acknowledgements

- [LlamaFactory](https://github.com/hiyouga/LLaMA-Factory) by hiyouga and contributors, Apache-2.0. LlamaBoard is its web UI. If you use it in research, cite LlamaFactory as its README asks.
- Model weights keep their own licences; read them on Hugging Face before use.
- `LICENSE` - Apache-2.0 for the files in this folder, with the third-party notices.
