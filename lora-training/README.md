# LoRA training (ai-toolkit + kohya_ss)

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=LAUNCHABLE_ID_PENDING)

Train LoRAs for FLUX, Wan 2.2 and Qwen-Image on your own GPU. [AI Toolkit](https://github.com/ostris/ai-toolkit) by Ostris and [Kohya's GUI](https://github.com/bmaltais/kohya_ss) run side by side with Docker Compose, sharing one model cache and one GPU.

## What it runs

| Component | Version | Image |
| --- | --- | --- |
| AI Toolkit | 0.13.42 (pinned) | `ostris/aitoolkit:0.13.42` |
| Kohya's GUI (kohya_ss) | v26.0.0 (pinned) | `ghcr.io/bmaltais/kohya-ss-gui:v26.0.0` |

Two web UIs, each behind its own Brev link:

- **AI Toolkit** (port 8675): datasets, job queue and sample previews.
- **Kohya's GUI** (port 7860): sd-scripts training with full control of every flag.

The AI Toolkit image is built on CUDA 13.0 and needs NVIDIA driver 580 or newer.

## Pick a base model

Set the `BASE_MODEL` launch parameter when you deploy. It is downloaded into the shared cache on first start:

- `black-forest-labs/FLUX.1-dev` (default, gated, needs `HF_TOKEN`)
- `ai-toolkit/Wan2.2-T2V-A14B-Diffusers-bf16`
- `Qwen/Qwen-Image`
- `none` (download nothing)

The download runs in the background, and both UIs open before it finishes. Follow it from a terminal on the instance:

```
docker logs -f lora-training-ai-toolkit-1
```

It ends with `BASE_MODEL ready: <model>`. Start training after that line, or AI Toolkit downloads the model again inside the job.

## Hugging Face token

`HF_TOKEN` is a Hugging Face read token. It is required for gated models such as FLUX.1-dev: accept the model licence on huggingface.co first. On the deploy page you can bind a saved secret or paste the token.

## Minimum GPU

NVIDIA A100 80GB, with 250 GiB of disk. AI Toolkit also ships example configs for 24 GB cards that use quantization and its low-VRAM mode; if you choose a smaller GPU, keep at least 24 GB.

## Use it

1. Deploy and wait until the instance is Running.
2. Open the AI Toolkit link. Create a dataset, upload images with captions, then create a job. The base model IDs above match AI Toolkit's own example configs.
3. Or open the Kohya's GUI link. Put model files in `/app/models` and datasets in `/dataset`. The base model chosen at launch is visible read-only under `/hf-cache/hub/`.
4. Run one training job at a time: both UIs share the GPU.

To use a UI from your own machine, forward its port with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 8675:8675
```

## How data persists

All data is on the instance under `~/workspace/lora-training`:

| Path | Contents |
| --- | --- |
| `~/workspace/lora-training/hf-cache` | Hugging Face download cache (base models) |
| `~/workspace/lora-training/ai-toolkit/datasets` | AI Toolkit datasets |
| `~/workspace/lora-training/ai-toolkit/output` | AI Toolkit trained LoRAs and samples |
| `~/workspace/lora-training/ai-toolkit/config` | AI Toolkit job configs |
| `~/workspace/lora-training/kohya/` | Kohya models, dataset, outputs, config, cache |

These folders survive a stop and start of the instance. They are removed when the instance is deleted. AI Toolkit keeps its job list in a database inside its container: it survives a stop and start but is reset if the container is recreated.

Download your LoRAs before you delete the instance, for example with `scp` over the SSH config the Brev CLI sets up:

```
scp -r INSTANCE_NAME:~/workspace/lora-training/ai-toolkit/output ./lora-output
```

## Stop or delete to control cost

- **Stop** the instance from the Brev console between training jobs. Your data is kept, and both UIs start again on the next start (`restart: unless-stopped`). Storage is still billed while the instance is stopped.
- **Delete** the instance when you are finished. This removes the instance and all of its data, including datasets and trained LoRAs.

## Demo

Demo recording coming soon.

## Files

- `compose.yaml` - the stack, every image pinned.
- `LICENSE` - Apache-2.0 for the files in this folder, with upstream attributions.

## Acknowledgements

- AI Toolkit by Ostris - MIT License.
- Kohya's GUI by bmaltais, built on kohya-ss/sd-scripts - Apache-2.0.
- Base models carry their own licences; read each model card before use. FLUX.1-dev is under a non-commercial licence.
