<p align="center">
  <strong>ComfyUI Pro on NVIDIA Brev</strong><br>
  ComfyUI with ComfyUI-Manager and 12 pinned, audited custom-node packs in one prebuilt image on one NVIDIA L40S 48GB, with FLUX.1 or Qwen-Image picked at launch.
</p>

# ComfyUI Pro

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M7UQ4Vwk9PM9fd7gTp51ExxPCK)

Launchable ID: env-3M7UQ4Vwk9PM9fd7gTp51ExxPCK

ComfyUI Pro runs [ComfyUI](https://github.com/comfyanonymous/ComfyUI) with [ComfyUI-Manager](https://github.com/Comfy-Org/ComfyUI-Manager) and a pinned, audited set of 12 custom-node packs, in one prebuilt container image on a single NVIDIA L40S 48GB GPU. Pick FLUX.1 or Qwen-Image at launch; your models, workflows and outputs persist across Stop. First step: deploy, click open-comfyui, load a FLUX.1 template from the Workflow menu and press Run.

| Quick facts | |
| --- | --- |
| Runs | ComfyUI v0.45.0, ComfyUI-Manager 4.2.2, 12 custom-node packs and PyTorch 2.8.0 with CUDA 12.8, one container under Docker Compose |
| Default compute | 1x NVIDIA L40S 48GB on AWS (g6e.xlarge), stoppable; you can pick another GPU on the deploy page |
| Disk | 150 GiB |
| Ready in | about 8 minutes on a fresh deploy (2026-11-15); the first model download continues after the UI opens |
| Cost | about $2.23/hr on the default compute (console, 2026-11-15); storage is billed while stopped |
| Secrets | optional HF_TOKEN; the default model sets do not need it |
| Licences | ComfyUI GPL-3.0, ComfyUI-Manager GPL-3.0, node packs GPL-3.0, MIT or Apache-2.0, files in this folder Apache-2.0; model weights keep their own licences |
| Guide | https://www.9owls.com/launchables/comfyui-pro/ |

Current versions: ComfyUI v0.45.0 (989d93d0d968e704c589ce0146bb18c77f6b50cc), comfyui_manager 4.2.2, PyTorch 2.8.0 with CUDA 12.8, 12 node packs at the commits in docs/nodes.md, image ghcr.io/ashishsalve/comfyui-pro:0.45.0@sha256:3883a324527680f5028983b99581afd32fff8fa8bfdcf1dbea27b0b5480dfeef

Last smoke: 2026-11-15, fresh deploy on one NVIDIA L40S 48GB. ComfyUI answered about 8 minutes after launch with all 12 custom node packs imported.

## Contents

- [What you get](#what-you-get)
- [Why audited](#why-audited)
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
| ComfyUI | v0.45.0 (commit 989d93d0d968e704c589ce0146bb18c77f6b50cc) | `ghcr.io/ashishsalve/comfyui-pro:0.45.0`, pinned by digest |
| ComfyUI-Manager | comfyui_manager 4.2.2, started at its strictest security level | same image |
| PyTorch with CUDA | 2.8.0 with CUDA 12.8 (base `pytorch/pytorch:2.8.0-cuda12.8-cudnn9-runtime`, pinned by digest) | same image |
| Custom-node packs | 12 packs, each at one full git commit | listed in [docs/nodes.md](docs/nodes.md) |
| Models | FLUX.1 [schnell] fp8, FLUX.1 [dev] fp8 or Qwen-Image fp8, each file pinned to a Hugging Face commit | downloaded on first start into your workspace |
| Stack definition | one Docker Compose service, `comfyui` | `compose.yaml` in this folder |

Nothing is compiled or pip-installed on your GPU clock: the image is prebuilt, and only the model files are downloaded at first start.

## Why audited

Custom nodes are Python code that runs with full access to your instance. Malicious nodes have been published to the Comfy Registry before (ComfyUI issue #11791, an information stealer hidden in "Upscaler_4K" nodes). ComfyUI Pro installs nothing from a registry at deploy time: the image carries exactly the packs listed in [docs/nodes.md](docs/nodes.md), each from its author's repository at one full git commit, with the checks we ran and the packs we left out and why. ComfyUI-Manager starts at its strictest security level.

## Deploy in three steps

1. Click Launch on Brev, keep the NVIDIA L40S or pick another GPU, choose a MODEL_SET (default `flux1-schnell-fp8`), and deploy.
2. Wait until the instance shows Running and the open-comfyui link answers. On the 2026-11-15 fresh deploy, ComfyUI answered about 8 minutes after launch; the model download continues after that.
3. Click **open-comfyui**, load a template from the Workflow menu (FLUX.1 or Qwen-Image) and press Run.

Progress of the first-start model download is in `/home/ubuntu/workspace/comfyui-pro/logs/model-fetch.log`; it ends with `fetch-models: MODEL_SET <set> complete`. Models appear in the loaders when their files land.

## Try it first

- Generate your first image: with the default `flux1-schnell-fp8` set, open the Workflow menu, load the FLUX.1 template and press Run. The output is saved under `/home/ubuntu/workspace/comfyui-pro/output`.
- Check the API from your machine: forward port 8188 (see [Use it from your machine](#use-it-from-your-machine)) and run `curl http://localhost:8188/system_stats`.
- Watch the GPU: the ComfyUI-Crystools pack in the audited set shows a GPU and VRAM monitor in the UI.

## How it works

- One container, `comfyui-pro`, started by Docker Compose from the prebuilt image pinned by digest, with `restart: unless-stopped`.
- ComfyUI serves its web UI and HTTP API on port 8188, reached through the authenticated Brev Secure Link **open-comfyui**. ComfyUI has no login of its own.
- The GPU is reserved for the container through the NVIDIA runtime; the container gets 8 GB of shared memory, as PyTorch's Docker guidance asks.
- A health check calls `http://localhost:8188/system_stats` every 30 seconds.
- The image contains no model weights and no credentials. Models are downloaded on first start into your workspace, each file pinned to a Hugging Face commit and checked against its expected size.

<details>
<summary>Advanced: the container image</summary>

```
docker pull ghcr.io/ashishsalve/comfyui-pro:0.45.0@sha256:3883a324527680f5028983b99581afd32fff8fa8bfdcf1dbea27b0b5480dfeef
```

- Tags `0.45.0` and `0.45.0-319a5a6` point to digest `sha256:3883a324527680f5028983b99581afd32fff8fa8bfdcf1dbea27b0b5480dfeef`. `compose.yaml` pins the digest, so a moved tag never changes what you run.
- Built by GitHub Actions from the project's Dockerfile on 2026-11-14. Base image `pytorch/pytorch:2.8.0-cuda12.8-cudnn9-runtime`, pinned by digest. ComfyUI is checked out at the v0.45.0 commit; each node pack at the commit in docs/nodes.md; no pack installer script is ever run.
- Inside the image, `/opt/comfyui-pro/pip-freeze.txt` lists every resolved Python package.
- The host NVIDIA driver must support CUDA 12.8.

</details>

## Settings

| Parameter | Required | Default | What it does |
| --- | --- | --- | --- |
| MODEL_SET | yes (Choice) | `flux1-schnell-fp8` | Models downloaded on first start: `flux1-schnell-fp8` (FLUX.1 [schnell] fp8, 17.2 GB, Apache-2.0), `flux1-dev-fp8` (FLUX.1 [dev] fp8, 17.2 GB, FLUX.1 [dev] Non-Commercial License), `qwen-image-fp8` (Qwen-Image fp8 diffusion model, text encoder and VAE, 30.1 GB, Apache-2.0), `none` (download nothing) |
| HF_TOKEN | no (Text) | none | Your Hugging Face token, for gated models you add later and higher download rate limits. The default model sets do not need it. On the deploy page choose "Use a secret" to bind a saved Brev secret (this option may not be enabled for your account), or paste the value. |

Both values are read once, when the container is first created, and the container keeps them across restarts and Stop/Start.

The FLUX.1 fp8 checkpoints are 17.2 GB; the Qwen-Image fp8 set is 30.1 GB and runs with partial offload below 48 GB.

## Use it from your machine

To call the ComfyUI HTTP API from your own machine, forward the port with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 8188:8188
curl http://localhost:8188/system_stats
```

ComfyUI's web UI and HTTP API then answer on http://localhost:8188 on your machine.

To add another model set later without redeploying, run on the instance:

```
docker exec comfyui-pro python /opt/comfyui-pro/fetch-models.py qwen-image-fp8 /root/workspace/models
```

If `docker` answers "permission denied", prefix the command with `sudo`.

## Data and persistence

Everything you create is stored on the instance under `/home/ubuntu/workspace/comfyui-pro/`, bind-mounted into the container:

| On the instance | In the container | Holds |
| --- | --- | --- |
| `/home/ubuntu/workspace/comfyui-pro/models` | `/root/workspace/models` | checkpoints, diffusion_models, text_encoders, vae, loras, ... |
| `/home/ubuntu/workspace/comfyui-pro/output` | `/root/workspace/output` | generated images and videos |
| `/home/ubuntu/workspace/comfyui-pro/input` | `/root/workspace/input` | uploaded inputs |
| `/home/ubuntu/workspace/comfyui-pro/user` | `/root/workspace/user` | workflows, settings, ComfyUI-Manager config |
| `/home/ubuntu/workspace/comfyui-pro/cache/huggingface` | `/root/workspace/cache/huggingface` | Hugging Face cache |
| `/home/ubuntu/workspace/comfyui-pro/logs` | `/root/workspace/logs` | model download log |

It survives **Stop** and is destroyed by **Delete**. The container runs as root, so these files are owned by root on the instance: use `sudo` to change or remove them from a shell. Nodes you add through ComfyUI-Manager, and weights that some nodes fetch on first use, live inside the container: they survive Stop and restarts, but not a re-created container.

## Stop, start and delete

- **Stop** the instance from the Brev console when you are not using it. Stop pauses GPU billing; storage keeps billing while stopped. Your models, workflows and outputs are kept.
- **Start** it again: the container restarts by itself (`restart: unless-stopped`) with the same parameters; nothing needs re-entering. A stopped instance is tied to its provider and region, and GPU capacity there may not be available when you start it again.
- **Delete** the instance when you are finished. This ends all billing and removes the instance and all of its data, including models and outputs. It cannot be undone. Download your outputs first.

## Troubleshooting

<details>
<summary>The UI is open but the model loaders are empty</summary>

The first-start model download is still running; the UI opens before it finishes. Check its progress on the instance:

```
sudo tail -n 5 /home/ubuntu/workspace/comfyui-pro/logs/model-fetch.log
```

The download is done when the log ends with `fetch-models: MODEL_SET <set> complete`. Then refresh the loader in ComfyUI. If you chose `none`, no models are downloaded; add a set with the `fetch-models.py` command under [Use it from your machine](#use-it-from-your-machine).

</details>

<details>
<summary>ComfyUI is not back after a stop and start</summary>

The container restarts by itself and keeps its parameters. If the open-comfyui link does not answer after a few minutes, check the container on the instance and start it if it is stopped:

```
sudo docker ps -a --filter name=comfyui-pro
sudo docker start comfyui-pro
```

Use `docker start` rather than re-running `docker compose up` without the variables: re-creating the container without MODEL_SET and HF_TOKEN set would use the defaults.

</details>

<details>
<summary>Qwen-Image runs slowly or runs out of GPU memory</summary>

The Qwen-Image fp8 set is 30.1 GB and runs with partial offload below 48 GB. Keep the default NVIDIA L40S 48GB for this set, or use a FLUX.1 set (17.2 GB) on a smaller GPU.

</details>

## FAQ

### Which GPU do I need?

The default is one NVIDIA L40S 48GB with 150 GiB of disk, so that every MODEL_SET choice fits. On your own machine, the stack needs an NVIDIA GPU with 24 GB or more and a driver that supports CUDA 12.8.

### Does anything leave the instance?

Your workflows, inputs and outputs stay in `/home/ubuntu/workspace/comfyui-pro/` on the instance. The container downloads the chosen model files from Hugging Face on first start, and two packs (comfyui_controlnet_aux and ComfyUI-Florence2) download their weights from Hugging Face on first use, as listed in [docs/nodes.md](docs/nodes.md).

### Can I use FLUX.1 [dev] commercially?

FLUX.1 [dev] is under the FLUX.1 [dev] Non-Commercial License, which restricts commercial use. FLUX.1 [schnell] and Qwen-Image are Apache-2.0. Read each licence on Hugging Face before you use the weights or their outputs commercially.

### Can I add my own custom nodes?

Yes, through ComfyUI-Manager, which starts at its strictest security level. Nodes you add live inside the container and are not part of the audited set; see [docs/nodes.md](docs/nodes.md) before you add one.

### Can I run this on my own hardware?

Yes. Any Linux host with an NVIDIA GPU (24 GB or more), a driver that supports CUDA 12.8, Docker and the NVIDIA Container Toolkit:

```
MODEL_SET=flux1-schnell-fp8 docker compose -f compose.yaml up -d
```

Set `HF_TOKEN` in the same way if you need it. The compose file stores data under `/home/ubuntu/workspace/comfyui-pro/`; edit the volume paths for your machine. ComfyUI has no login of its own: do not expose port 8188 to the internet. See the [ComfyUI](https://github.com/comfyanonymous/ComfyUI) project for supported GPUs.

### How do I update to a newer version?

This Launchable pins ComfyUI v0.45.0, every node pack by commit and the image by digest, so every deploy runs the same software. To try a newer ComfyUI on your own machine, change the `image:` line in `compose.yaml` and run `docker compose up -d`; your workspace folders are kept.

## Guides and related Launchables

- Step-by-step guide: [Run ComfyUI on a cloud GPU](https://www.9owls.com/guides/run-comfyui-on-a-cloud-gpu/)
- [How to deploy a Launchable on NVIDIA Brev](https://www.9owls.com/guides/deploy-a-launchable-on-nvidia-brev/)
- [How to stop and delete an NVIDIA Brev instance](https://www.9owls.com/guides/stop-start-and-delete-an-nvidia-brev-instance/)
- [Train a FLUX LoRA on a cloud GPU](https://www.9owls.com/guides/train-a-flux-lora-on-a-cloud-gpu/)
- [Which GPU does each Launchable default to?](https://www.9owls.com/compare/nvidia-l4-vs-l40s-for-llm-inference/)
- [Brev Launchables FAQ](https://www.9owls.com/faq/brev-launchable-basics/): billing, persistence and choosing a GPU
- This Launchable on 9owls: https://www.9owls.com/launchables/comfyui-pro/
- All Launchables by 9owls: https://www.9owls.com/launchables/
- Related: [Wan 2.2 Video Studio (ComfyUI)](https://www.9owls.com/launchables/open-video-studio/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M7SG64BL2IkL3acLixc2Kx25wE)); [LoRA Training (ai-toolkit + kohya_ss)](https://www.9owls.com/launchables/lora-training/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M77hJCDpHkAGNvOR4xmmgsC1KA)); [Cosmos 3 Nano World Model Studio](https://www.9owls.com/launchables/cosmos3-video-studio/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aVI8A9ooLqzhwIEkWuuY27Pm))

## Keep your own stack running

NightKeeper packages your repository as an NVIDIA Brev Launchable, proves it on a fresh GPU and keeps it running. Your Brev API key stays in your repository's GitHub secrets. NightKeeper never sees it.

[Create your Launchable](https://www.9owls.com/nightkeeper/start/) or [read about NightKeeper](https://www.9owls.com/nightkeeper/).

## Credits and licences

- [ComfyUI](https://github.com/comfyanonymous/ComfyUI) by comfyanonymous and contributors: GPL-3.0. [ComfyUI-Manager](https://github.com/Comfy-Org/ComfyUI-Manager) by Comfy-Org (originally by Dr.Lt.Data): GPL-3.0. The image ships both unmodified at the versions above, and their full source is at the pinned commits upstream. Because the image bundles GPL-3.0 software, it is labelled GPL-3.0-only.
- Custom-node packs: each keeps its own licence (GPL-3.0, MIT or Apache-2.0), listed per pack in [docs/nodes.md](docs/nodes.md). Thanks to the node-pack authors: kijai, rgthree, pythongosssss, Kosinkadink, Fannovel16, city96, ssitu, yolain, chrisgoringe and crystian.
- PyTorch, CUDA libraries and the Python packages in the image keep their own licences. Thanks to the PyTorch team for the base image.
- Model weights are not part of this folder or the image and keep their own licences: FLUX.1 [schnell] by Black Forest Labs and Qwen-Image by the Qwen team are Apache-2.0; FLUX.1 [dev] is under the FLUX.1 [dev] Non-Commercial License, which restricts commercial use. Comfy-Org publishes the model repacks used here.

Files in this folder: `compose.yaml` (the Docker Compose file Brev runs, image pinned by digest), `docs/nodes.md` (the audited node set: pack, author repository, commit, licence, and the packs left out) and [LICENSE](LICENSE) (Apache License 2.0 for the files in this folder, with the third-party licences listed).

Published and maintained by [9owls, Inc.](https://www.9owls.com/). Questions: hello@9owls.com.
