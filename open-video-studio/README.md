# Wan 2.2 Video Studio (ComfyUI)

Generate video from text or an image with [Wan 2.2](https://github.com/Wan-Video/Wan2.2) on your own GPU. [ComfyUI](https://github.com/comfyanonymous/ComfyUI) comes ready with the Wan 2.2 TI2V-5B weights downloaded, the [ComfyUI-WanVideoWrapper](https://github.com/kijai/ComfyUI-WanVideoWrapper) node pack installed, and prebuilt SageAttention and FlashAttention wheels, so nothing is compiled on your instance.

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M7SG64BL2IkL3acLixc2Kx25wE)

Launchable ID: env-3M7SG64BL2IkL3acLixc2Kx25wE

Current versions: ComfyUI v0.45.0, ComfyUI-WanVideoWrapper a7439db (1.4.8), Wan 2.2 weights from Comfy-Org/Wan_2.2_ComfyUI_Repackaged ee6f4a4, SageAttention 2.2.0, FlashAttention 2.8.3.post2, pytorch/pytorch:2.7.1-cuda12.8-cudnn9-runtime

Last smoke: NOT YET SMOKED

## What you get

- Default instance: 1x NVIDIA L4 24GB, stoppable, 120 GiB disk. The deploy page shows the current hourly price.
- Minimum GPU: 24 GB VRAM for the default 5B model. The Wan 2.2 project documents TI2V-5B on a single 24 GB GPU.
- For the 14B model (`MODEL_SIZE=14B`), switch the instance to an NVIDIA L40S 48GB or larger before you deploy.
- One web UI behind a Brev Secure Link: **open-comfyui** (ComfyUI, port 8188).
- Host driver: the image uses CUDA 12.8; the instance needs a matching NVIDIA driver (570 or newer).
- Time to ready: about 25 minutes on first boot. The first boot installs ComfyUI and its Python packages, then downloads about 18 GB of 5B weights (about 38 GB for 14B). ComfyUI answers once the weights are on disk. Later starts take a minute or two.

## Launch parameters

| Name | Type | Default | Purpose |
|---|---|---|---|
| MODEL_SIZE | Choice | 5B | Wan 2.2 weights downloaded on first start. `5B`: TI2V-5B (text to video and image to video, fp16), runs on 24 GB GPUs. `14B`: T2V-A14B high-noise and low-noise experts (fp8) plus the 4-step LoRAs used by the ComfyUI template; needs a 48 GB GPU. |
| HF_TOKEN | Text | none | Optional Hugging Face read token. The default weights are public; a token raises Hugging Face download limits. Choose "Use a secret" to bind a saved Brev secret if that option is available to you, or paste the token. |

## Use it

1. Deploy and wait until the instance is Running. First boot takes about 25 minutes; follow it from a terminal on the instance with `docker logs -f open-video-studio-comfyui-1`. It is ready when the log shows `models-ready MODEL_SIZE=5B` and then ComfyUI's `To see the GUI go to` line.
2. Click **open-comfyui**.
3. Open the workflow template browser (Workflow menu, Browse Templates) and search "Wan2.2 5B" to open the Wan 2.2 TI2V-5B video template. The template's model files are already in place.
4. Type a prompt and press Run. Videos land in the output folder below.

A first run at the template's default 1280x704 and 121 frames takes a while on an L4. For a quick first result, lower the resolution (for example 832x480) and the frame count, then scale up.

With `MODEL_SIZE=14B`, use the Wan2.2 14B text-to-video template instead (search "Wan2.2 14B" in the template browser).

ComfyUI starts with SageAttention enabled (`--use-sage-attention`). FlashAttention is installed too and can be picked in the WanVideoWrapper sampler's attention setting.

### ComfyUI-WanVideoWrapper

The wrapper adds WanVideo nodes for features that are not yet in ComfyUI's built-in Wan support. Its example workflows (in `ComfyUI/custom_nodes/ComfyUI-WanVideoWrapper/example_workflows`) use extra node packs and model files that this Launchable does not install. Add those yourself if you need them, and check each one's licence first.

### Get the other model size

The download helper fetches either set into the right folders:

```
docker exec open-video-studio-comfyui-1 /root/workspace/venv/bin/python /root/workspace/bin/fetch-wan22.py 14B
```

The 14B set needs a 48 GB GPU to run.

### API access from your machine

ComfyUI also has an HTTP API. Reach it with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 8188:8188
curl http://localhost:8188/system_stats
```

## Where your data lives

Everything is on the instance under `$HOME/workspace/open-video-studio` (`/home/ubuntu/workspace/open-video-studio`), mounted at `/root/workspace` inside the container:

| Path | Contents |
|---|---|
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

## Stop vs delete

- **Stop** pauses GPU billing. Storage keeps billing while stopped. On start, ComfyUI comes back by itself (`restart: unless-stopped`) without reinstalling or re-downloading; no parameter needs re-entering.
- **Delete** ends all billing and destroys the instance and all data on it. It cannot be undone.

## Files

- `compose.yaml` - the stack. The image is pinned by tag and digest; every repository commit, prebuilt wheel and model revision is pinned, with the reason and date.
- `LICENSE` - Apache-2.0 for the files in this repository; third-party licences listed inside.

## Licences

| Component | Licence |
|---|---|
| [ComfyUI](https://github.com/comfyanonymous/ComfyUI) | GPL-3.0 |
| [ComfyUI-WanVideoWrapper](https://github.com/kijai/ComfyUI-WanVideoWrapper) | Apache-2.0 |
| [Wan 2.2](https://github.com/Wan-Video/Wan2.2) code and models | Apache-2.0 |
| [SageAttention](https://github.com/thu-ml/SageAttention) (prebuilt wheels from [deepbeepmeep/SageAttention](https://github.com/deepbeepmeep/SageAttention)) | Apache-2.0 |
| [FlashAttention](https://github.com/Dao-AILab/flash-attention) | BSD-3-Clause |
| [PyTorch](https://github.com/pytorch/pytorch) image | PyTorch BSD-style licence (see its LICENSE file); the image also contains NVIDIA CUDA and cuDNN libraries under NVIDIA's licence terms |

The weights download at first start from [Comfy-Org/Wan_2.2_ComfyUI_Repackaged](https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged) on Hugging Face under their own licence (Apache-2.0 on the model card); read it before use.

## Acknowledgements

- Wan 2.2 by the Wan team at Alibaba.
- ComfyUI by comfyanonymous and the Comfy-Org contributors; the Wan 2.2 templates and repackaged weights by Comfy-Org.
- ComfyUI-WanVideoWrapper by kijai.
- SageAttention by THU-ML; Linux wheels built by deepbeepmeep.
- FlashAttention by Tri Dao and contributors.
- The 4-step LoRAs in the 14B set by the LightX2V team.
