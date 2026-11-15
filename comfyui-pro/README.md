# ComfyUI Pro

ComfyUI with ComfyUI-Manager and a pinned, audited set of 12 custom-node packs, in one prebuilt container image on a single NVIDIA GPU. Pick FLUX.1 or Qwen-Image at launch; your models, workflows and outputs persist across Stop.

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M7UQ4Vwk9PM9fd7gTp51ExxPCK)

Launchable ID: env-3M7UQ4Vwk9PM9fd7gTp51ExxPCK

Current versions: ComfyUI v0.45.0 (989d93d0d968e704c589ce0146bb18c77f6b50cc), comfyui_manager 4.2.2, PyTorch 2.8.0 with CUDA 12.8, 12 node packs at the commits in docs/nodes.md, image ghcr.io/ashishsalve/comfyui-pro:0.45.0@sha256:3883a324527680f5028983b99581afd32fff8fa8bfdcf1dbea27b0b5480dfeef

Last smoke: 2026-11-15, fresh deploy on one NVIDIA L40S 48GB. ComfyUI answered about 8 minutes after launch with all 12 custom node packs imported.

## Why "audited"

Custom nodes are Python code that runs with full access to your instance. Malicious nodes have been published to the Comfy Registry before (ComfyUI issue #11791, an information stealer hidden in "Upscaler_4K" nodes). ComfyUI Pro installs nothing from a registry at deploy time: the image carries exactly the packs listed in [docs/nodes.md](docs/nodes.md), each from its author's repository at one full git commit, with the checks we ran and the packs we left out and why. ComfyUI-Manager starts at its strictest security level.

## What you get

- One Docker Compose service, `comfyui`, from a prebuilt image: nothing is compiled or pip-installed on your GPU clock.
- 1x NVIDIA L40S 48 GB on a stoppable instance, 100 GiB disk. The deploy page shows the current hourly price for the instance you pick; the lowest stoppable 1x L40S list price was about $1.74/hr on 2026-11-11.
- Minimum GPU: 24 GB VRAM (estimate, not yet measured). The FLUX.1 fp8 checkpoints are 17.2 GB; the Qwen-Image fp8 set is 30.1 GB and runs with partial offload below 48 GB. If you swap the instance, keep at least 24 GB of VRAM.
- The host NVIDIA driver must support CUDA 12.8.
- Time to ready: about 20 minutes on first boot (estimate): the image pull plus the model download. The UI opens before the model download finishes; models appear in the loaders when their files land. Later starts are faster (estimate: a few minutes) because the image and models are already on disk.

## The container image

```
docker pull ghcr.io/ashishsalve/comfyui-pro:0.45.0@sha256:3883a324527680f5028983b99581afd32fff8fa8bfdcf1dbea27b0b5480dfeef
```

- Tags `0.45.0` and `0.45.0-319a5a6` point to digest `sha256:3883a324527680f5028983b99581afd32fff8fa8bfdcf1dbea27b0b5480dfeef`. `compose.yaml` pins the digest, so a moved tag never changes what you run.
- Built by GitHub Actions from the project's Dockerfile on 2026-11-14. Base image `pytorch/pytorch:2.8.0-cuda12.8-cudnn9-runtime`, pinned by digest. ComfyUI is checked out at the v0.45.0 commit; each node pack at the commit in docs/nodes.md; no pack installer script is ever run.
- The image contains no model weights and no credentials. Models are downloaded on first start into your workspace, each file pinned to a Hugging Face commit and checked against its expected size.
- Inside the image, `/opt/comfyui-pro/pip-freeze.txt` lists every resolved Python package.

## Launch parameters

| Name | Type | Required | Default | What it does |
|---|---|---|---|---|
| MODEL_SET | Choice | no | flux1-schnell-fp8 | Models downloaded on first start: `flux1-schnell-fp8` (FLUX.1 [schnell] fp8, 17.2 GB, Apache-2.0), `flux1-dev-fp8` (FLUX.1 [dev] fp8, 17.2 GB, FLUX.1 [dev] Non-Commercial License), `qwen-image-fp8` (Qwen-Image fp8 diffusion model, text encoder and VAE, 30.1 GB, Apache-2.0), `none` (download nothing) |
| HF_TOKEN | Text | no | none | Your Hugging Face token, for gated models you add later and higher download rate limits. The default model sets do not need it. On the deploy page choose "Use a secret" to bind a saved Brev secret (this option may not be enabled for your account), or paste the value. |

Both values are read once, when the container is first created, and the container keeps them across restarts and Stop/Start.

## Use it

1. Deploy and wait until the instance is Running.
2. Click **Open-ComfyUI**.
3. Load a template from the Workflow menu (FLUX.1 or Qwen-Image) and press Run. Progress of the first-start model download is in `/home/ubuntu/workspace/comfyui-pro/logs/model-fetch.log`; it ends with `fetch-models: MODEL_SET <set> complete`.

To call the ComfyUI HTTP API from your own machine, forward the port with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 8188:8188
curl http://localhost:8188/system_stats
```

To add another model set later without redeploying, run on the instance:

```
docker exec comfyui-pro python /opt/comfyui-pro/fetch-models.py qwen-image-fp8 /root/workspace/models
```

## Where your data lives

Everything you create is stored on the instance under `/home/ubuntu/workspace/comfyui-pro/`, bind-mounted into the container:

| On the instance | In the container | Holds |
|---|---|---|
| `/home/ubuntu/workspace/comfyui-pro/models` | `/root/workspace/models` | checkpoints, diffusion_models, text_encoders, vae, loras, ... |
| `/home/ubuntu/workspace/comfyui-pro/output` | `/root/workspace/output` | generated images and videos |
| `/home/ubuntu/workspace/comfyui-pro/input` | `/root/workspace/input` | uploaded inputs |
| `/home/ubuntu/workspace/comfyui-pro/user` | `/root/workspace/user` | workflows, settings, ComfyUI-Manager config |
| `/home/ubuntu/workspace/comfyui-pro/cache/huggingface` | `/root/workspace/cache/huggingface` | Hugging Face cache |
| `/home/ubuntu/workspace/comfyui-pro/logs` | `/root/workspace/logs` | model download log |

It survives **Stop** and is destroyed by **Delete**. The container runs as root, so these files are owned by root on the instance: use `sudo` to change or remove them from a shell. Nodes you add through ComfyUI-Manager, and weights that some nodes fetch on first use, live inside the container: they survive Stop and restarts, but not a re-created container.

## Stop vs delete

- **Stop** pauses GPU billing. Storage keeps billing while stopped. On start, the container restarts by itself (`restart: unless-stopped`) with the same parameters; nothing needs re-entering. A stopped instance is tied to its provider and region, and GPU capacity there may not be free when you start it again.
- **Delete** ends all billing and destroys the instance and every file on it, including models and outputs. It cannot be undone. Download your outputs first.

## Run it on your own GPU machine

Any Linux host with an NVIDIA GPU (24 GB or more), a driver that supports CUDA 12.8, Docker and the NVIDIA Container Toolkit:

```
MODEL_SET=flux1-schnell-fp8 docker compose -f compose.yaml up -d
```

Set `HF_TOKEN` in the same way if you need it. The compose file stores data under `/home/ubuntu/workspace/comfyui-pro/`; edit the volume paths for your machine. ComfyUI has no login of its own: do not expose port 8188 to the internet.

## Licences

- Files in this repository (README.md, LICENSE, compose.yaml, docs/): Apache-2.0, see `LICENSE`.
- ComfyUI: GPL-3.0. ComfyUI-Manager: GPL-3.0. The image ships both unmodified at the versions above, and their full source is at the pinned commits upstream. Because the image bundles GPL-3.0 software, it is labelled GPL-3.0-only.
- Custom-node packs: each keeps its own licence (GPL-3.0, MIT or Apache-2.0), listed per pack in [docs/nodes.md](docs/nodes.md).
- PyTorch, CUDA libraries and the Python packages in the image keep their own licences.
- Model weights are not part of this repository or the image and keep their own licences: FLUX.1 [schnell] and Qwen-Image are Apache-2.0; FLUX.1 [dev] is under the FLUX.1 [dev] Non-Commercial License, which restricts commercial use. Read each licence on Hugging Face before you use the weights or their outputs commercially.

## Files

- `compose.yaml` - the Docker Compose file Brev runs.
- `docs/nodes.md` - the audited node set: pack, author repository, commit, licence, and the packs left out.
- `LICENSE` - Apache-2.0 for the files in this repository, with the third-party licences listed.

## Acknowledgements

- ComfyUI by comfyanonymous and contributors, and Comfy-Org for ComfyUI, the model repacks used here, and ComfyUI-Manager (originally by Dr.Lt.Data).
- The node-pack authors: kijai, rgthree, pythongosssss, Kosinkadink, Fannovel16, city96, ssitu, yolain, chrisgoringe and crystian.
- Black Forest Labs for FLUX.1, and the Qwen team for Qwen-Image.
- The PyTorch team for the base image, and NVIDIA Brev for the GPU instances.
