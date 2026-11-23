<p align="center">
  <strong>NVIDIA Cosmos 3 Nano on NVIDIA Brev</strong><br>
  Text-to-video and image-to-video with the Cosmos3-Nano world model on one NVIDIA L40S, served by vLLM-Omni with a Gradio studio and the Cosmos safety guardrails on.
</p>

# Cosmos 3 Nano World Model Studio

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aVI8A9ooLqzhwIEkWuuY27Pm)

Launchable ID: env-3M8aVI8A9ooLqzhwIEkWuuY27Pm

Generate videos with [NVIDIA Cosmos3-Nano](https://huggingface.co/nvidia/Cosmos3-Nano), the open Cosmos 3 world model for physical AI, on your own GPU. [vLLM-Omni](https://github.com/vllm-project/vllm-omni) serves the model on one NVIDIA L40S 48GB, and a small Gradio studio gives you text-to-video and image-to-video in the browser. Use it to prototype scenes and synthetic data clips for robotics and autonomous systems. First step: accept the guardrail model's access conditions on Hugging Face, deploy with your Hugging Face token, and open the open-cosmos-studio link.

Built on NVIDIA Cosmos.

| Quick facts | |
| --- | --- |
| Runs | vLLM-Omni serving nvidia/Cosmos3-Nano with Cosmos guardrails, plus a Gradio 6.32.0 studio, two containers under Docker Compose |
| Default compute | 1x NVIDIA L40S 48GB on AWS (g6e.xlarge, 4 vCPU, 32 GiB RAM), stoppable; you can pick another GPU on the deploy page |
| Disk | 200 GiB |
| Ready in | about 17 minutes on a fresh deploy (2026-11-15) |
| Cost | about $2.23/hr on the default compute (console, 2026-11-15); storage is billed while stopped |
| Secrets | `HF_TOKEN` (Hugging Face read token, required) |
| Licences | Cosmos3-Nano OpenMDW License 1.1, Cosmos-1.0-Guardrail NVIDIA Open Model License, vLLM-Omni Apache-2.0, Gradio Apache-2.0 |
| Guide | https://www.9owls.com/launchables/cosmos3-video-studio/ |

Current versions: vLLM-Omni `vllm/vllm-omni:cosmos3` (pinned by digest, 2026-10-19 build), nvidia/Cosmos3-Nano revision `45666784803b3a7ad577e0def405f9afcc3bddb2`, Gradio 6.32.0, Python 3.12.16.

Last smoke: 2026-11-15, fresh deploy on one NVIDIA L40S 48GB, including stop and start.

## Contents

- [What you get](#what-you-get)
- [Before you deploy](#before-you-deploy)
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
| vLLM-Omni serving nvidia/Cosmos3-Nano | `cosmos3` build, pinned by digest | `vllm/vllm-omni:cosmos3@sha256:86fb713b...` (full digest in `compose.yaml`) |
| nvidia/Cosmos3-Nano model | revision `45666784803b3a7ad577e0def405f9afcc3bddb2` | downloaded from Hugging Face on first start |
| Cosmos safety guardrails | nvidia/Cosmos-1.0-Guardrail and the models it uses | downloaded by the guardrail code in the vLLM-Omni image on first start |
| Cosmos 3 Nano Video Studio (Gradio 6.32.0) | defined in `compose.yaml` | `python:3.12.16-slim-bookworm` (pinned by digest) |

## Before you deploy

Cosmos guardrails are on by default. They use the gated [nvidia/Cosmos-1.0-Guardrail](https://huggingface.co/nvidia/Cosmos-1.0-Guardrail) model.

1. Before you deploy, sign in to Hugging Face, open https://huggingface.co/nvidia/Cosmos-1.0-Guardrail and accept its access conditions. Access is granted immediately.
2. Then create a read token for the same account and enter it as `HF_TOKEN`. On the deploy page you can choose "Use a secret" to bind a saved secret, or paste the token.

The token is needed only for this guardrail model; Cosmos3-Nano itself is not gated.

Never put a token anywhere except this parameter. The server runs with Cosmos guardrails enabled, and the studio never turns them off; keep them on in your own API requests.

## Deploy in three steps

1. Click Launch on Brev, keep the NVIDIA L40S or pick another GPU, enter your `HF_TOKEN`, and deploy.
2. Wait until the instance shows Running and the open-cosmos-studio link loads the studio. On a fresh deploy the stack was healthy about 17 minutes after create (2026-11-15). The first start downloads the model and the guardrail models, a large download (tens of GB).
3. Open the **open-cosmos-studio** link. The status line reads "ready" when Cosmos3-Nano is loaded; press "Refresh status" to check.

## Try it first

- **Text to video**: on the Text to video tab, keep the sample prompt "A robot arm picks up a red cube from a wooden table and places it in a blue bin, steady camera, daylight." and press Generate. At the defaults (1280x720, 45 frames, 30 steps) the smoke test returned a clip in 84 seconds on the L40S.
- **Your own scene**: write a prompt such as "A forklift moves a pallet across a warehouse floor", pick resolution, frames, steps and seed, and press Generate. Keep the seed to reproduce a clip; change it for a variation.
- **Image to video**: on the Image to video tab, upload a first frame (JPG, PNG or WebP), describe the motion, and press Generate.

Each clip is an MP4 with audio generated by the model, saved to the outputs folder. Generation runs one request at a time.

## How it works

- Two containers, started with Docker Compose: `cosmos` (vLLM-Omni serving nvidia/Cosmos3-Nano) and `studio` (the Gradio app).
- The studio listens on port 7860 and is reached through the authenticated Brev Secure Link **open-cosmos-studio**.
- The vLLM-Omni API listens on port 8000, bound to the instance itself, and is not exposed publicly. Reach it with `brev port-forward`.
- The model runs on the GPU of your instance; prompts, input images and generated videos stay on the instance.
- `HF_TOKEN` reaches only the `cosmos` container, through its environment, and is never printed.
- Both containers restart automatically (`restart: unless-stopped`).

<details>
<summary>Advanced: generation settings and GPU memory</summary>

The studio defaults to 1280x720, 45 frames (about 2 seconds at 24 fps), 30 steps, guidance scale 6.0 and seed 123. In the 2026-11-15 smoke these defaults peaked at 44,771 of 46,068 MiB of GPU memory on the L40S 48GB, with the guardrail on. Raise frames and steps only with GPU memory to spare. The upstream vLLM recipe lists one H200, H100 or A100 as the single-GPU profile. For longer or larger clips, deploy on an A100 80GB.

</details>

## Settings

| Parameter | Required | Default | What it does |
| --- | --- | --- | --- |
| `HF_TOKEN` | Yes | none | Hugging Face read token, needed to download the gated nvidia/Cosmos-1.0-Guardrail model. Request access to that model with the same account first. Choose "Use a secret" to bind a saved secret, or paste a read token. |

Everything else is preset in `compose.yaml`.

## Use it from your machine

To call the API from your own machine, forward the port with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 8000:8000
curl -X POST http://localhost:8000/v1/videos/sync -H "Accept: video/mp4" \
  -F "prompt=A forklift moves a pallet across a warehouse floor" \
  -F "size=1280x720" -F "num_frames=45" -F "fps=24" \
  -F "num_inference_steps=30" -F "seed=123" --output out.mp4
```

Add `-F "input_reference=@frame.png"` for image-to-video. The vLLM-Omni API answers on http://localhost:8000 while the port forward runs; `GET /health` returns 200 when the model is loaded.

## Data and persistence

Everything lives under `/home/ubuntu/workspace/cosmos3-studio` on the instance:

- Model cache (Hugging Face): `/home/ubuntu/workspace/cosmos3-studio/huggingface`
- Generated videos: `/home/ubuntu/workspace/cosmos3-studio/outputs`
- Studio Python environment: `/home/ubuntu/workspace/cosmos3-studio/envs`

They survive a stop and start of the instance. They are removed when the instance is deleted, so download the videos you want to keep.

## Stop, start and delete

- **Stop** the instance from the Brev console when you are not using it. The model cache and your videos are kept, and both containers are recreated on the next start. Storage is still billed while the instance is stopped.
- **Start** it again: the containers are recreated automatically and the model loads from the cache, without a new download. In the 2026-11-15 smoke the stack was healthy again about 7 minutes after the start. If the studio is not back after that, use the recovery command under Troubleshooting.
- **Delete** the instance when you are finished. This removes the instance and all of its data, including downloaded models and generated videos.

## Troubleshooting

<details>
<summary>The studio is not back after a stop and start</summary>

Stopping the instance removes the studio's containers; everything under ~/workspace is kept. Starting it again recreates the containers automatically, usually within a few minutes. If the studio is not back after 5 minutes, open a terminal on the instance and run:

```
cd /home/ubuntu/workspace && sudo docker compose up -d
```

</details>

<details>
<summary>The status line says loading</summary>

The first start downloads the model and the guardrail models, a large download (tens of GB). On a fresh deploy the stack was healthy about 17 minutes after create. Wait, then press "Refresh status". The instance needs internet access for this download.

</details>

<details>
<summary>The model does not load because the guardrail download is refused</summary>

The guardrail model is gated. Check that the Hugging Face account behind your `HF_TOKEN` has accepted the access conditions at https://huggingface.co/nvidia/Cosmos-1.0-Guardrail and that the token has read access.

</details>

<details>
<summary>A generation fails with an out-of-memory error</summary>

The defaults are sized for the 48 GB L40S, where they use most of the GPU memory. Lower frames or steps, or deploy on an A100 80GB for longer or larger clips.

</details>

## FAQ

### Which GPU do I need for Cosmos3-Nano?

The default is one NVIDIA L40S 48GB with 200 GiB of disk; at the studio defaults it peaked at 44,771 of 46,068 MiB of GPU memory in the 2026-11-15 smoke. The upstream vLLM recipe lists one H200, H100 or A100 as the single-GPU profile. For longer or larger clips, deploy on an A100 80GB.

### Why do I need a Hugging Face token?

The Cosmos guardrails use the gated nvidia/Cosmos-1.0-Guardrail model, so the download needs a token from an account that has accepted its access conditions. Cosmos3-Nano itself is not gated.

### Can I turn the guardrails off?

No. The server runs with Cosmos guardrails enabled and this Launchable has no option to disable them. The NVIDIA Open Model License for nvidia/Cosmos-1.0-Guardrail requires the guardrail to stay in place.

### Does anything leave the instance?

The first start downloads the model and guardrail models from Hugging Face and the pinned Gradio package from PyPI. Hugging Face telemetry and Gradio analytics are turned off in `compose.yaml`. Prompts, input images and generated videos stay on the instance.

### Can I run this on my own hardware?

Yes, the stack is the public [vLLM-Omni](https://github.com/vllm-project/vllm-omni) image plus the `compose.yaml` in this folder. Read the [Cosmos3-Nano model card](https://huggingface.co/nvidia/Cosmos3-Nano) for supported GPUs and settings.

### How do I update to a newer version?

This Launchable pins the vLLM-Omni image by digest and the model by revision so every deploy is the same. To try a newer release on your own instance, change the image or the `--revision` in `compose.yaml` under `/home/ubuntu/workspace` and run `sudo docker compose up -d`; the workspace folder is kept.

## Guides and related Launchables

- Step-by-step guide: [How to run the Cosmos 3 Nano world model](https://www.9owls.com/guides/run-the-cosmos-3-nano-world-model/)
- [How to deploy a Launchable on NVIDIA Brev](https://www.9owls.com/guides/deploy-a-launchable-on-nvidia-brev/)
- [How to stop and delete an NVIDIA Brev instance](https://www.9owls.com/guides/stop-start-and-delete-an-nvidia-brev-instance/)
- [What is a Brev Launchable?](https://www.9owls.com/guides/what-is-a-brev-launchable/)
- [Which GPU does each Launchable default to?](https://www.9owls.com/compare/nvidia-l4-vs-l40s-for-llm-inference/)
- [Brev Launchables FAQ](https://www.9owls.com/faq/brev-launchable-basics/): billing, persistence and choosing a GPU
- This Launchable on 9owls: https://www.9owls.com/launchables/cosmos3-video-studio/
- All Launchables by 9owls: https://www.9owls.com/launchables/
- Related: [Wan 2.2 Video Studio (ComfyUI)](https://www.9owls.com/launchables/open-video-studio/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M7SG64BL2IkL3acLixc2Kx25wE)); [ComfyUI Pro](https://www.9owls.com/launchables/comfyui-pro/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M7UQ4Vwk9PM9fd7gTp51ExxPCK)); [Isaac Lab + Newton Robot Learning](https://www.9owls.com/launchables/isaac-lab-newton/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8arIbDn5RySQJP1XtedUwZdFa))

## Keep your own stack running

NightKeeper packages your repository as an NVIDIA Brev Launchable, proves it on a fresh GPU and keeps it running. Your Brev API key stays in your repository's GitHub secrets. NightKeeper never sees it.

[Create your Launchable](https://www.9owls.com/nightkeeper/start/) or [read about NightKeeper](https://www.9owls.com/nightkeeper/).

## Credits and licences

- [NVIDIA Cosmos3-Nano](https://huggingface.co/nvidia/Cosmos3-Nano): OpenMDW License 1.1 (https://openmdw.ai/license/1-1/).
- Cosmos safety guardrails: nvidia/Cosmos-1.0-Guardrail weights under the NVIDIA Open Model License (https://www.nvidia.com/en-us/agreements/enterprise-software/nvidia-open-model-license); text and video safety models downloaded by the cosmos-guardrail package, each under its own licence; cosmos-guardrail package (Apache-2.0).
- [vLLM-Omni](https://github.com/vllm-project/vllm-omni): Apache-2.0.
- Gradio: Apache-2.0.
- nvidia/Cosmos3-Nano is released by NVIDIA; keep the licence and origin notices when you share the model or derivatives. nvidia/Cosmos-1.0-Guardrail is "Licensed by NVIDIA Corporation under the NVIDIA Open Model License", which requires the guardrail to stay in place; do not bypass or disable it.
- Read each model card before use.

Files in this folder: `compose.yaml` (the stack and the studio, every image, model revision and package pinned) and [LICENSE](LICENSE) (Apache License 2.0 for the files in this folder, with upstream attributions).

Published and maintained by [9owls, Inc.](https://www.9owls.com/). Questions: hello@9owls.com.
