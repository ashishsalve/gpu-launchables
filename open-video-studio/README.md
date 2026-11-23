<p align="center">
  <strong>Wan 2.2 on NVIDIA Brev</strong><br>
  Text and image to video with Wan 2.2 in ComfyUI on one NVIDIA L4, with ComfyUI-WanVideoWrapper and prebuilt SageAttention and FlashAttention.
</p>

# Wan 2.2 Video Studio (ComfyUI)

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M7SG64BL2IkL3acLixc2Kx25wE)

Launchable ID: env-3M7SG64BL2IkL3acLixc2Kx25wE

Generate video from text or an image with [Wan 2.2](https://github.com/Wan-Video/Wan2.2) on your own NVIDIA L4 24GB GPU. [ComfyUI](https://github.com/comfyanonymous/ComfyUI) comes ready with the Wan 2.2 TI2V-5B weights downloaded, the [ComfyUI-WanVideoWrapper](https://github.com/kijai/ComfyUI-WanVideoWrapper) node pack installed, and prebuilt SageAttention and FlashAttention wheels, so nothing is compiled on your instance. First step: deploy, click open-comfyui, open the Wan 2.2 5B video template and press Run.

| Quick facts | |
| --- | --- |
| Runs | ComfyUI v0.45.0 with ComfyUI-WanVideoWrapper, Wan 2.2 TI2V-5B (or T2V-A14B), SageAttention 2.2.0 and FlashAttention 2.8.3.post2, one container under Docker Compose |
| Default compute | 1x NVIDIA L4 24GB on GCP (g2-standard-8), stoppable; you can pick another GPU on the deploy page |
| Disk | 150 GiB |
| Ready in | about 16 minutes on a fresh deploy (2026-11-15); allow up to about 25 minutes on first boot |
| Cost | about $1.02/hr on the default compute (console, 2026-11-15); storage is billed while stopped |
| Secrets | HF_TOKEN, optional; the default weights are public |
| Licences | ComfyUI GPL-3.0, ComfyUI-WanVideoWrapper Apache-2.0, Wan 2.2 Apache-2.0, SageAttention Apache-2.0, FlashAttention BSD-3-Clause |
| Guide | https://www.9owls.com/launchables/open-video-studio/ |

Current versions: ComfyUI v0.45.0, ComfyUI-WanVideoWrapper a7439db (1.4.8), Wan 2.2 weights from Comfy-Org/Wan_2.2_ComfyUI_Repackaged ee6f4a4, SageAttention 2.2.0, FlashAttention 2.8.3.post2, pytorch/pytorch:2.7.1-cuda12.8-cudnn9-runtime

Last smoke: 2026-11-15, fresh deploy on one NVIDIA L4 24GB with the 5B model. ComfyUI answered about 16 minutes after launch with the WanVideo nodes loaded.

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
| PyTorch base image (CUDA 12.8, cuDNN 9) | 2.7.1 (pinned by tag and digest) | `pytorch/pytorch:2.7.1-cuda12.8-cudnn9-runtime` |
| ComfyUI | v0.45.0 (commit 989d93d) | git, installed into the workspace on first boot |
| ComfyUI-WanVideoWrapper | a7439db (1.4.8) | git, installed into `ComfyUI/custom_nodes/` |
| Wan 2.2 weights | Comfy-Org/Wan_2.2_ComfyUI_Repackaged ee6f4a4 | Hugging Face, downloaded on first boot |
| SageAttention | 2.2.0 (prebuilt Linux wheel, cu128, torch 2.7.1) | pip wheel |
| FlashAttention | 2.8.3.post2 (prebuilt wheel, cu12, torch 2.7) | pip wheel |
| Download helper | fetches either model set | `bin/fetch-wan22.py` in the workspace |

- Default instance: 1x NVIDIA L4 24GB, stoppable, 150 GiB disk.
- Minimum GPU: 24 GB VRAM for the default 5B model. The Wan 2.2 project documents TI2V-5B on a single 24 GB GPU.
- For the 14B model (`MODEL_SIZE=14B`), switch the instance to an NVIDIA L40S 48GB or larger before you deploy.
- One web UI behind a Brev Secure Link: **open-comfyui** (ComfyUI, port 8188).
- Host driver: the image uses CUDA 12.8; the instance needs a matching NVIDIA driver (570 or newer).

## Deploy in three steps

1. Click Launch on Brev, keep the NVIDIA L4 (or pick an L40S 48GB or larger for 14B), choose `MODEL_SIZE`, and deploy.
2. Wait until the instance is Running and the **open-comfyui** link loads ComfyUI. On the 2026-11-15 fresh deploy ComfyUI answered about 16 minutes after launch; allow up to about 25 minutes. The first boot installs ComfyUI and its Python packages, then downloads about 18 GB of 5B weights (about 38 GB for 14B). ComfyUI answers once the weights are on disk. Later starts take a minute or two.
3. Click **open-comfyui**, open the workflow template browser (Workflow menu, Browse Templates) and search "Wan2.2 5B".

To follow the first boot from a terminal on the instance:

```
docker logs -f open-video-studio-comfyui-1
```

It is ready when the log shows `models-ready MODEL_SIZE=5B` and then ComfyUI's `To see the GUI go to` line.

## Try it first

1. Text to video: open the Wan 2.2 TI2V-5B video template ("Wan2.2 5B" in the template browser). The template's model files are already in place. Type a prompt and press Run. Videos land in the `output/` folder of the workspace.
2. A quick first result: a first run at the template's default 1280x704 and 121 frames takes a while on an L4. Lower the resolution (for example 832x480) and the frame count, then scale up.
3. Save your workflow from the Workflow menu once you like the settings. Saved workflows are kept in the `user/` folder, and images you upload are kept in the `input/` folder.

With `MODEL_SIZE=14B`, use the Wan2.2 14B text-to-video template instead (search "Wan2.2 14B" in the template browser).

## How it works

- One container, started with Docker Compose from the pinned PyTorch 2.7.1 CUDA 12.8 image.
- ComfyUI listens on port 8188 and is reached through the authenticated Brev Secure Link **open-comfyui**.
- On first boot the container clones ComfyUI and ComfyUI-WanVideoWrapper at pinned commits, builds a Python environment in the workspace, installs the prebuilt attention wheels and downloads the Wan 2.2 weights chosen by `MODEL_SIZE`. Later starts skip the install and find the weights on disk.
- ComfyUI starts with SageAttention enabled (`--use-sage-attention`). FlashAttention is installed too and can be picked in the WanVideoWrapper sampler's attention setting.
- The model runs on the instance GPU. Prompts, images and videos stay on the instance.

<details>
<summary>Advanced: ComfyUI-WanVideoWrapper</summary>

The wrapper adds WanVideo nodes for features that are not yet in ComfyUI's built-in Wan support. Its example workflows (in `ComfyUI/custom_nodes/ComfyUI-WanVideoWrapper/example_workflows`) use extra node packs and model files that this Launchable does not install. Add those yourself if you need them, and check each one's licence first.

</details>

<details>
<summary>Advanced: get the other model size</summary>

The download helper fetches either set into the right folders:

```
docker exec open-video-studio-comfyui-1 /root/workspace/venv/bin/python /root/workspace/bin/fetch-wan22.py 14B
```

The 14B set needs a 48 GB GPU to run.

</details>

## Settings

| Parameter | Required | Default | What it does |
| --- | --- | --- | --- |
| MODEL_SIZE | yes (Choice) | 5B | Wan 2.2 weights downloaded on first start. `5B`: TI2V-5B (text to video and image to video, fp16), runs on 24 GB GPUs. `14B`: T2V-A14B high-noise and low-noise experts (fp8) plus the 4-step LoRAs used by the ComfyUI template; needs a 48 GB GPU. |
| HF_TOKEN | no (Text) | none | Optional Hugging Face read token. The default weights are public; a token raises Hugging Face download limits. Choose "Use a secret" to bind a saved Brev secret if that option is available to you, or paste the token. |

Both values are kept in the container configuration, so Stop and Start need no re-entry.

## Use it from your machine

ComfyUI also has an HTTP API. Reach it with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 8188:8188
curl http://localhost:8188/system_stats
```

ComfyUI and its API then answer on http://localhost:8188 on your machine.

## Data and persistence

Everything is on the instance under `$HOME/workspace/open-video-studio` (`/home/ubuntu/workspace/open-video-studio`), mounted at `/root/workspace` inside the container:

| Path | Contents |
| --- | --- |
| `output/` | Generated videos |
| `input/` | Uploaded images |
| `user/` | Your saved workflows and ComfyUI settings |
| `ComfyUI/models/` | Model weights |
| `ComfyUI/custom_nodes/` | ComfyUI-WanVideoWrapper |
| `venv/` | Python environment |
| `cache/huggingface/` | Hugging Face cache |

All of it survives **Stop** and is destroyed by **Delete**. Download your videos before you delete the instance, for example with `scp` over the SSH config the Brev CLI sets up:

```
scp -r INSTANCE_NAME:~/workspace/open-video-studio/output ./wan-videos
```

## Stop, start and delete

- **Stop** pauses GPU billing. Your workspace is kept, including weights, workflows and videos. Storage keeps billing while stopped.
- **Start** it again: ComfyUI comes back by itself (`restart: unless-stopped`) without reinstalling or re-downloading; no parameter needs re-entering. Later starts take a minute or two.
- **Delete** ends all billing and destroys the instance and all data on it. It cannot be undone.

## Troubleshooting

<details>
<summary>The open-comfyui link does not load right after deploy</summary>

The first boot installs ComfyUI and its Python packages, then downloads about 18 GB of 5B weights (about 38 GB for 14B). ComfyUI answers only once the weights are on disk. Follow progress with `docker logs -f open-video-studio-comfyui-1` and wait for `models-ready MODEL_SIZE=5B` and then `To see the GUI go to`.

</details>

<details>
<summary>The 14B template does not run on the L4</summary>

The 14B set needs a 48 GB GPU. Deploy on an NVIDIA L40S 48GB or larger with `MODEL_SIZE=14B`, or stay on the 5B template on the L4.

</details>

<details>
<summary>A first video takes a long time</summary>

The template default of 1280x704 and 121 frames takes a while on an L4. Lower the resolution (for example 832x480) and the frame count for a first result, then scale up.

</details>

<details>
<summary>A WanVideoWrapper example workflow shows missing nodes</summary>

The wrapper's example workflows use extra node packs and model files that this Launchable does not install. Use the built-in Wan 2.2 templates, or add the missing packs yourself after checking each one's licence.

</details>

## FAQ

### Which GPU do I need for Wan 2.2?

24 GB VRAM for the default 5B model; the default is one NVIDIA L4 24GB with 150 GiB of disk. For the 14B model, pick an NVIDIA L40S 48GB or larger. The image uses CUDA 12.8, so the host needs NVIDIA driver 570 or newer.

### Where do my videos go?

Into `output/` under `/home/ubuntu/workspace/open-video-studio`. They survive Stop and are destroyed by Delete, so download them first with `scp`.

### Do I need a Hugging Face token?

No. The default weights are public. `HF_TOKEN` only raises Hugging Face download limits.

### Does anything leave the instance?

Generation runs on the instance GPU; prompts, images and videos stay on it. On first boot the container downloads ComfyUI and the wrapper from GitHub, Python packages and the attention wheels, and the Wan 2.2 weights from Hugging Face.

### Can I run this on my own hardware?

Yes. The stack is the public `pytorch/pytorch` image plus the `compose.yaml` in this folder; the host needs an NVIDIA GPU with 24 GB VRAM and the NVIDIA Container Toolkit. See [ComfyUI](https://github.com/comfyanonymous/ComfyUI) and [Wan 2.2](https://github.com/Wan-Video/Wan2.2) for their own install options.

### How do I update to a newer version?

This Launchable pins the image, ComfyUI, the wrapper, the wheels and the weight revision so every deploy is the same. To try newer versions, change the pins in `compose.yaml` on your own copy; your workspace data is kept.

## Guides and related Launchables

- Step-by-step guide: [How to generate video with Wan 2.2 in ComfyUI](https://www.9owls.com/guides/generate-video-with-wan-2-2-in-comfyui/)
- [Run ComfyUI on a cloud GPU](https://www.9owls.com/guides/run-comfyui-on-a-cloud-gpu/)
- [How to deploy a Launchable on NVIDIA Brev](https://www.9owls.com/guides/deploy-a-launchable-on-nvidia-brev/)
- [Stop, start and delete an NVIDIA Brev instance](https://www.9owls.com/guides/stop-start-and-delete-an-nvidia-brev-instance/)
- [What is a Brev Launchable?](https://www.9owls.com/guides/what-is-a-brev-launchable/)
- [Compare GPU memory: NVIDIA L4 vs L40S](https://www.9owls.com/compare/nvidia-l4-vs-l40s-for-llm-inference/)
- [Brev Launchables FAQ](https://www.9owls.com/faq/brev-launchable-basics/): billing, persistence and choosing a GPU
- [Image and video Launchables](https://www.9owls.com/topics/image-and-video/)
- This Launchable on 9owls: https://www.9owls.com/launchables/open-video-studio/
- All Launchables by 9owls: https://www.9owls.com/launchables/
- Related: [ComfyUI Pro](https://www.9owls.com/launchables/comfyui-pro/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M7UQ4Vwk9PM9fd7gTp51ExxPCK)); [Cosmos 3 Nano World Model Studio](https://www.9owls.com/launchables/cosmos3-video-studio/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aVI8A9ooLqzhwIEkWuuY27Pm)); [LoRA Training (ai-toolkit + kohya_ss)](https://www.9owls.com/launchables/lora-training/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M77hJCDpHkAGNvOR4xmmgsC1KA))

## Keep your own stack running

NightKeeper packages your repository as an NVIDIA Brev Launchable, proves it on a fresh GPU and keeps it running. Your Brev API key stays in your repository's GitHub secrets. NightKeeper never sees it.

[Create your Launchable](https://www.9owls.com/nightkeeper/start/) or [read about NightKeeper](https://www.9owls.com/nightkeeper/).

## Credits and licences

| Component | Licence |
| --- | --- |
| [ComfyUI](https://github.com/comfyanonymous/ComfyUI) | GPL-3.0 |
| [ComfyUI-WanVideoWrapper](https://github.com/kijai/ComfyUI-WanVideoWrapper) | Apache-2.0 |
| [Wan 2.2](https://github.com/Wan-Video/Wan2.2) code and models | Apache-2.0 |
| [SageAttention](https://github.com/thu-ml/SageAttention) (prebuilt wheels from [deepbeepmeep/SageAttention](https://github.com/deepbeepmeep/SageAttention)) | Apache-2.0 |
| [FlashAttention](https://github.com/Dao-AILab/flash-attention) | BSD-3-Clause |
| [PyTorch](https://github.com/pytorch/pytorch) image | PyTorch BSD-style licence (see its LICENSE file); the image also contains NVIDIA CUDA and cuDNN libraries under NVIDIA's licence terms |

The weights download at first start from [Comfy-Org/Wan_2.2_ComfyUI_Repackaged](https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged) on Hugging Face under their own licence (Apache-2.0 on the model card); read it before use.

- Wan 2.2 by the Wan team at Alibaba.
- ComfyUI by comfyanonymous and the Comfy-Org contributors; the Wan 2.2 templates and repackaged weights by Comfy-Org.
- ComfyUI-WanVideoWrapper by kijai.
- SageAttention by THU-ML; Linux wheels built by deepbeepmeep.
- FlashAttention by Tri Dao and contributors.
- The 4-step LoRAs in the 14B set by the LightX2V team.

Files in this folder: `compose.yaml` (the stack; the image is pinned by tag and digest, and every repository commit, prebuilt wheel and model revision is pinned, with the reason and date) and [LICENSE](LICENSE) (Apache-2.0 for the files in this folder; third-party licences listed inside).

Published and maintained by [9owls, Inc.](https://www.9owls.com/). Questions: hello@9owls.com.
