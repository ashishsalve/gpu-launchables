<p align="center">
  <strong>AI Toolkit and Kohya's GUI on NVIDIA Brev</strong><br>
  LoRA training for FLUX, Wan 2.2 and Qwen-Image on one NVIDIA L40S 48GB, with AI Toolkit by Ostris and Kohya's GUI (kohya_ss) side by side.
</p>

# LoRA Training (ai-toolkit + kohya_ss)

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M77hJCDpHkAGNvOR4xmmgsC1KA)

Launchable ID: env-3M77hJCDpHkAGNvOR4xmmgsC1KA

Train LoRAs for FLUX, Wan 2.2 and Qwen-Image on your own GPU. [AI Toolkit](https://github.com/ostris/ai-toolkit) by Ostris and [Kohya's GUI](https://github.com/bmaltais/kohya_ss) run side by side with Docker Compose on one NVIDIA L40S 48GB, sharing one model cache and one GPU. First step: deploy with a Hugging Face token, open AI Toolkit from the open-ai-toolkit link, create a dataset from your captioned images and queue a training job.

| Quick facts | |
| --- | --- |
| Runs | AI Toolkit 0.13.42 (port 8675) and Kohya's GUI v26.0.0 (port 7860), two containers under Docker Compose |
| Default compute | 1x NVIDIA L40S 48GB on AWS (g6e.2xlarge, 8 vCPU), stoppable; you can pick another GPU on the deploy page, keep at least 24 GB |
| Disk | 256 GiB |
| Ready in | about 15 minutes on a fresh deploy for both UIs (2026-11-14); the base model download continues in the background |
| Cost | about $2.69/hr on the default compute (console, 2026-11-15); storage is billed while stopped |
| Secrets | `HF_TOKEN` (Hugging Face read token), needed for gated models such as FLUX.1-dev |
| Licences | AI Toolkit MIT, Kohya's GUI Apache-2.0, sd-scripts Apache-2.0; base models carry their own licences |
| Guide | https://www.9owls.com/launchables/lora-training/ |

Current versions: AI Toolkit 0.13.42 (ostris/aitoolkit:0.13.42), Kohya's GUI v26.0.0 (ghcr.io/bmaltais/kohya-ss-gui:v26.0.0)

Last smoke: 2026-11-14, fresh deploy on one NVIDIA L4 24GB. AI Toolkit (port 8675) and Kohya's GUI (port 7860) both answered about 15 minutes after launch.

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
| AI Toolkit | 0.13.42 (pinned) | `ostris/aitoolkit:0.13.42` |
| Kohya's GUI (kohya_ss) | v26.0.0 (pinned) | `ghcr.io/bmaltais/kohya-ss-gui:v26.0.0` |
| The stack | every image pinned | `compose.yaml` in this folder |

Two web UIs, each behind its own Brev link:

- **AI Toolkit** (port 8675, link **open-ai-toolkit**): datasets, job queue and sample previews.
- **Kohya's GUI** (port 7860, link **open-kohya-gui**): sd-scripts training with full control of every flag.

The AI Toolkit image is built on CUDA 13.0 and needs NVIDIA driver 580 or newer.

## Deploy in three steps

1. Click Launch on Brev, keep the NVIDIA L40S or pick another GPU with at least 24 GB, choose a `BASE_MODEL` and supply `HF_TOKEN`, then deploy.
2. Wait until the instance shows Running and the open-ai-toolkit link loads. Both UIs answered about 15 minutes after launch on a fresh deploy; the base model keeps downloading in the background after that.
3. Open the **open-ai-toolkit** link, or the **open-kohya-gui** link if you prefer sd-scripts with every flag exposed.

## Try it first

1. Watch the base model download. Open a terminal on the instance and run `docker logs -f lora-training-ai-toolkit-1`. It ends with `BASE_MODEL ready: <model>`. Start training after that line, or AI Toolkit downloads the model again inside the job.
2. Train a first LoRA in AI Toolkit. Open the AI Toolkit link, create a dataset, upload images with captions, then create a job. The base model IDs offered at launch match AI Toolkit's own example configs, which also cover Wan 2.2 and Qwen-Image by their Hugging Face repo IDs.
3. Or train with Kohya's GUI. Open the Kohya's GUI link, put model files in `/app/models` and datasets in `/dataset`. The base model chosen at launch is visible read-only under `/hf-cache/hub/`.

Run one training job at a time: both UIs share the GPU.

## How it works

- Two containers, started with Docker Compose from the pinned images in `compose.yaml`, both restarting automatically (`restart: unless-stopped`).
- AI Toolkit listens on port 8675 behind the Brev Secure Link **open-ai-toolkit**; Kohya's GUI listens on port 7860 behind **open-kohya-gui**.
- On first start, the AI Toolkit container creates the workspace folders and downloads `BASE_MODEL` into the shared Hugging Face cache in the background. Both UIs open before the download finishes.
- Kohya's GUI sees the same cache read-only, so a base model is downloaded once.
- Both containers reserve the same GPU. Training runs on the instance; datasets and trained LoRAs stay on its disk until you download them.

<details>
<summary>Advanced: the low-VRAM example configs</summary>

AI Toolkit ships example configs for 24 GB cards that use quantization and its low-VRAM mode, for FLUX, Wan 2.2 and Qwen-Image. They are the starting point if you pick a 24 GB GPU instead of the default L40S 48GB.

</details>

## Settings

| Parameter | Required | Default | What it does |
| --- | --- | --- | --- |
| `BASE_MODEL` | yes | `black-forest-labs/FLUX.1-dev` | Hugging Face base model downloaded into the shared cache on first start. Choices: `black-forest-labs/FLUX.1-dev` (gated, needs `HF_TOKEN`) or `none` (download nothing). |
| `HF_TOKEN` | no | none | Hugging Face read token, required for gated models such as FLUX.1-dev: accept the model licence on huggingface.co first. On the deploy page you can bind a saved secret or paste the token. |

## Use it from your machine

To use a UI from your own machine, forward its port with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 8675:8675
```

Then open http://localhost:8675 locally for AI Toolkit. For Kohya's GUI, forward port 7860 the same way.

## Data and persistence

All data is on the instance under `/home/ubuntu/workspace/lora-training` (`~/workspace/lora-training`):

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

## Stop, start and delete

- **Stop** the instance from the Brev console between training jobs. Your data is kept. Storage is still billed while the instance is stopped.
- **Start** it again: both UIs start again on their own (`restart: unless-stopped`), with no settings to re-enter.
- **Delete** the instance when you are finished. This removes the instance and all of its data, including datasets and trained LoRAs.

## Troubleshooting

<details>
<summary>A training job downloads the base model again</summary>

The first-start download was still running. Follow it with `docker logs -f lora-training-ai-toolkit-1` and start training after the line `BASE_MODEL ready: <model>`.

</details>

<details>
<summary>The log shows BASE_MODEL prefetch failed</summary>

The download of a gated model such as FLUX.1-dev needs `HF_TOKEN`, from a Hugging Face account that has accepted the model licence on huggingface.co. The UIs still run; deploy again with a valid token, or set the model in an AI Toolkit job config with the token available.

</details>

<details>
<summary>AI Toolkit does not see the GPU</summary>

The AI Toolkit image is built on CUDA 13.0 and needs NVIDIA driver 580 or newer on the instance. Check the driver version with `nvidia-smi` in a terminal on the instance.

</details>

<details>
<summary>A job runs out of GPU memory</summary>

Both UIs share one GPU. Run one training job at a time. On a 24 GB GPU, start from AI Toolkit's 24 GB example configs, which use quantization and low-VRAM mode.

</details>

<details>
<summary>The AI Toolkit job list is empty</summary>

The job list lives in a database inside the AI Toolkit container and is reset if the container is recreated. Your datasets, configs and trained LoRAs are on the host under `~/workspace/lora-training` and are kept.

</details>

## FAQ

### Which GPU do I need?

The default is one NVIDIA L40S 48GB (AWS g6e.2xlarge, 8 vCPU) with 256 GiB of disk. AI Toolkit also ships example configs for 24 GB cards that use quantization and its low-VRAM mode; if you choose a smaller GPU, keep at least 24 GB.

### Why do I need a Hugging Face token?

The default base model, FLUX.1-dev, is gated on Hugging Face. Accept its licence on huggingface.co, then supply a read token as `HF_TOKEN`. With `BASE_MODEL` set to `none`, nothing is downloaded at start.

### Does anything leave the instance?

The instance downloads the pinned images and the base model you choose from Hugging Face. Your datasets and trained LoRAs stay on the instance disk until you download them.

### Can I train Wan 2.2 or Qwen-Image LoRAs?

Yes. AI Toolkit's example configs cover Wan 2.2 and Qwen-Image; set the model by its Hugging Face repo ID in the job config. It is downloaded into the same cache.

### Can I run this on my own hardware?

Yes, the stack is the `compose.yaml` in this folder with the public [AI Toolkit](https://github.com/ostris/ai-toolkit) and [Kohya's GUI](https://github.com/bmaltais/kohya_ss) images. The AI Toolkit image needs NVIDIA driver 580 or newer.

### How do I update to a newer version?

This Launchable pins AI Toolkit 0.13.42 and Kohya's GUI v26.0.0 so every deploy is the same. To try a newer release, change the image tag in your own copy of `compose.yaml`; your data under `~/workspace/lora-training` lives outside the containers.

## Guides and related Launchables

- Step-by-step guide: [Train a FLUX LoRA on a cloud GPU](https://www.9owls.com/guides/train-a-flux-lora-on-a-cloud-gpu/)
- [How to deploy a Launchable on NVIDIA Brev](https://www.9owls.com/guides/deploy-a-launchable-on-nvidia-brev/)
- [How to stop and delete an NVIDIA Brev instance](https://www.9owls.com/guides/stop-start-and-delete-an-nvidia-brev-instance/)
- [Run ComfyUI on a cloud GPU](https://www.9owls.com/guides/run-comfyui-on-a-cloud-gpu/)
- [NVIDIA L4 vs L40S: which GPU does each Launchable default to?](https://www.9owls.com/compare/nvidia-l4-vs-l40s-for-llm-inference/)
- [Brev Launchables FAQ](https://www.9owls.com/faq/brev-launchable-basics/): billing, stop and delete, what persists and how to choose a GPU
- This Launchable on 9owls: https://www.9owls.com/launchables/lora-training/
- All Launchables by 9owls: https://www.9owls.com/launchables/
- Related: [LlamaFactory (LlamaBoard)](https://www.9owls.com/launchables/llama-factory/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M7QbAu67oVXAOLqhezAb8g5EVD)); [ComfyUI Pro](https://www.9owls.com/launchables/comfyui-pro/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M7UQ4Vwk9PM9fd7gTp51ExxPCK)); [Wan 2.2 Video Studio (ComfyUI)](https://www.9owls.com/launchables/open-video-studio/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M7SG64BL2IkL3acLixc2Kx25wE))

## Keep your own stack running

NightKeeper packages your repository as an NVIDIA Brev Launchable, proves it on a fresh GPU and keeps it running. Your Brev API key stays in your repository's GitHub secrets. NightKeeper never sees it.

[Create your Launchable](https://www.9owls.com/nightkeeper/start/) or [read about NightKeeper](https://www.9owls.com/nightkeeper/).

## Credits and licences

- [AI Toolkit](https://github.com/ostris/ai-toolkit) by Ostris: MIT License.
- [Kohya's GUI](https://github.com/bmaltais/kohya_ss) by bmaltais, built on [kohya-ss/sd-scripts](https://github.com/kohya-ss/sd-scripts): Apache-2.0.
- Base models carry their own licences; read each model card before use. FLUX.1-dev is under a non-commercial licence.

Files in this folder: `compose.yaml` (the stack, every image pinned) and [LICENSE](LICENSE) (Apache-2.0 for the files in this folder, with upstream attributions).

Published and maintained by [9owls, Inc.](https://www.9owls.com/). Questions: hello@9owls.com.
