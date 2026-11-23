<p align="center">
  <strong>Nemotron Omni Multimodal Studio on NVIDIA Brev</strong><br>
  Ask NVIDIA Nemotron 3 Nano Omni about images, video and audio on one NVIDIA L40S, served by vLLM behind a Gradio studio.
</p>

# Nemotron Omni Multimodal Studio

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8a9cKCTehBUEgzwkv7tqk9gZK)

Launchable ID: env-3M8a9cKCTehBUEgzwkv7tqk9gZK

A multimodal studio for image, video and audio understanding on your own GPU. [vLLM](https://github.com/vllm-project/vllm) serves [NVIDIA Nemotron 3 Nano Omni](https://huggingface.co/nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-FP8), an omni vision language model that reads text, images, video and audio, and a small [Gradio](https://github.com/gradio-app/gradio) app gives you three tabs: Image Q&A, Video summary and Audio transcript. It runs on one NVIDIA L40S 48GB GPU, and uploads never leave the instance. First step: deploy, open the open-omni-studio link and upload a picture to the Image Q&A tab.

| Quick facts | |
| --- | --- |
| Runs | vLLM v0.33.0 (OpenAI-compatible server) with NVIDIA Nemotron 3 Nano Omni, plus a Gradio 6.32.0 studio app, two containers under Docker Compose |
| Default compute | 1x NVIDIA L40S 48GB on AWS (g6e.xlarge), stoppable; you can pick another GPU on the deploy page |
| Disk | 200 GiB |
| Ready in | about 22 minutes on a fresh deploy (2026-11-15) |
| Cost | about $2.23/hr on the default compute (console, 2026-11-15); storage is billed while stopped |
| Secrets | HF_TOKEN (optional Hugging Face read token) |
| Licences | vLLM Apache-2.0, Gradio Apache-2.0, Nemotron 3 Nano Omni NVIDIA Open Model Agreement, Qwen2.5-Omni-7B Apache-2.0 |
| Guide | https://www.9owls.com/launchables/nemotron-omni-studio/ |

Current versions: vLLM v0.33.0 (image pinned by digest), Gradio 6.32.0, Python 3.12.12, model nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-FP8

Last smoke: 2026-11-15, fresh deploy on one NVIDIA L40S 48GB, including stop and start.

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

| Component | Version | Image |
| --- | --- | --- |
| vLLM (OpenAI-compatible server) | v0.33.0 (pinned by digest) | `vllm/vllm-openai:v0.33.0` |
| vLLM audio decoding packages | `av` 19.0.2, `soundfile` 0.14.0, `soxr` 1.1.0, `scipy` 1.18.1 (pinned) | installed into the vLLM container on first start |
| Studio web app (Gradio) | Gradio 6.32.0 (pinned) | `python:3.12.12-slim-bookworm` |
| Model (default) | `nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-FP8` | downloaded from Hugging Face on first start, about 33 GB |
| Model (option) | `Qwen/Qwen2.5-Omni-7B` | downloaded from Hugging Face on first start |

The studio has three tabs:

- **Image Q&A** - upload a JPEG or PNG and ask about it.
- **Video summary** - upload an MP4 and get a summary plus a timestamped outline of key events.
- **Audio transcript** - upload a WAV or MP3 and get a transcript and a short summary.

## Deploy in three steps

1. Click Launch on Brev, keep the NVIDIA L40S 48GB or pick another GPU with at least 48 GB of memory, choose the `MODEL` setting (or keep the default), and deploy.
2. Wait until the instance shows Running and the open-omni-studio link answers. On a fresh deploy the studio page loaded after about 12 minutes and the model was ready after about 22 minutes, because the first start downloads the 33 GB model.
3. Open the **open-omni-studio** link, pick a tab, upload a file and press the button. The first request after a start takes longer while vLLM finishes loading.

## Try it first

- **Image Q&A:** upload any JPEG or PNG photo and leave the question empty. The studio then asks "Describe this image in detail." Ask a follow-up such as "What text is visible in this image?"
- **Video summary:** upload a short MP4 (the model card supports up to 2 minutes) and press **Summarize with timestamps**. With an empty question the studio asks for a short summary and a timestamped outline formatted mm:ss - event.
- **Audio transcript:** upload a WAV or MP3 clip and press **Transcribe and summarize**. With an empty question the studio asks for a transcript and up to five bullet points.

## How it works

- Two containers under Docker Compose: `vllm` serves the model, `studio` runs the Gradio app.
- The Studio app listens on port 7860 and is reached through the authenticated Brev Secure Link **open-omni-studio**.
- The vLLM API is bound to the instance itself on port 8000 and is not exposed publicly. Reach it with `brev port-forward`.
- The model runs on the instance GPU. Uploads are copied to `/home/ubuntu/workspace/media/uploads` and passed to vLLM as local `file:///media/...` URLs, so they never leave the instance.
- The vLLM image is built on CUDA 13.0, so the instance's NVIDIA driver must support CUDA 13.
- On first start vLLM adds its audio decoding packages (`av`, `soundfile`, `soxr`, `scipy`, pinned versions in `compose.yaml`), as the model card asks for `vllm[audio]`.

<details>
<summary>Advanced: input limits and vLLM settings</summary>

Input limits from the Nemotron 3 Nano Omni model card: video in MP4 up to 2 minutes, audio in WAV or MP3 up to 1 hour. This stack accepts one image, one video and one audio file per request, a limit set by `--limit-mm-per-prompt` in `compose.yaml`. It samples video at 2 frames per second, up to 128 frames, and caps the context at 65,536 tokens (32,768 for Qwen2.5-Omni-7B), so very long audio may need to be split.

For the Nemotron model, vLLM runs with `--reasoning-parser nemotron_v3`, so reasoning text goes to the reasoning field, not the answer content. The Studio app turns thinking off for its requests (`enable_thinking` false) and uses temperature 0.2.

</details>

## Settings

| Parameter | Required | Default | What it does |
| --- | --- | --- | --- |
| `MODEL` | No | `nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-FP8` | Model vLLM serves to the Studio. Choices: `nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-FP8` (about a 33 GB download; needs a 48 GB GPU) or `Qwen/Qwen2.5-Omni-7B` (open alternative under Apache-2.0; text, image, video and audio input). |
| `HF_TOKEN` | No | none | Hugging Face read token. Both models download without one; a token raises Hugging Face rate limits. On the deploy page you can bind a saved secret or paste a read token. |

The model is downloaded once on first start and loaded from the local cache after that. The Studio page opens before the download finishes; requests succeed once vLLM has loaded the model. To change the model, deploy again with a different `MODEL`. Never put a token anywhere except the `HF_TOKEN` parameter.

## Use it from your machine

To call the OpenAI-compatible API from your own machine, forward the port with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 8000:8000
curl http://localhost:8000/v1/models
```

The vLLM API then answers on http://localhost:8000/v1. It accepts `image_url`, `video_url` and `audio_url` content parts. Local files must sit under `/home/ubuntu/workspace/media` on the instance and are passed as `file:///media/NAME`.

## Data and persistence

Models and uploads live on the instance:

- Models (Hugging Face cache): `/home/ubuntu/workspace/huggingface`
- Uploaded files: `/home/ubuntu/workspace/media/uploads` (delete old uploads to reclaim disk space)

They survive a stop and start of the instance. They are removed when the instance is deleted.

## Stop, start and delete

- **Stop** the instance from the Brev console when you are not using it. Your models and uploads are kept, and both containers are recreated on the next start. Storage is still billed while the instance is stopped.
- **Start** it again: the containers are recreated automatically, usually within a few minutes, and the model loads from the local cache without a new download. If the studio is not back after 5 minutes, use the recovery command under Troubleshooting.
- **Delete** the instance when you are finished. This removes the instance and all of its data, including downloaded models and uploads.

## Troubleshooting

<details>
<summary>The studio is not back after a stop and start</summary>

Stopping the instance removes the studio's containers; everything under ~/workspace is kept. Starting it again recreates the containers automatically, usually within a few minutes. If the studio is not back after 5 minutes, open a terminal on the instance and run:

```
cd /home/ubuntu/workspace && sudo docker compose up -d
```

</details>

<details>
<summary>The studio says the model server is not ready yet</summary>

The Studio page opens before vLLM has finished loading the model. On the first start vLLM downloads the 33 GB model; on a fresh deploy the model was ready about 22 minutes after create. Wait a few minutes and press the button again.

</details>

<details>
<summary>A long audio or video file returns an error</summary>

This stack caps the context at 65,536 tokens (32,768 for Qwen2.5-Omni-7B) and samples video at 2 frames per second, up to 128 frames. Split very long audio into shorter clips, and keep videos within the model card limit of 2 minutes.

</details>

<details>
<summary>The disk is filling up</summary>

Every upload is copied to `/home/ubuntu/workspace/media/uploads`. Delete old uploads there to reclaim disk space.

</details>

## FAQ

### Which GPU do I need?

NVIDIA L40S 48GB, with 200 GiB of disk for the container images, the model cache and your uploads. The model card lists 1x L40S 48GB as the minimum GPU for the FP8 model and recommends 1x RTX PRO 6000 or 1x B200. The vLLM image needs an NVIDIA driver that supports CUDA 13.

### Does anything leave the instance?

Uploads never leave the instance: the studio copies them to `/home/ubuntu/workspace/media/uploads` and vLLM reads them from there. The instance downloads the container images, the pinned audio packages and the model from Hugging Face on first start.

### Do I need a Hugging Face token?

No. Both models download without one; a token raises Hugging Face rate limits. If you use one, enter it only in the `HF_TOKEN` setting.

### Can I run this on my own hardware?

Yes, the stack is the public [vLLM](https://github.com/vllm-project/vllm) image and a Python image, plus the `compose.yaml` in this folder, which holds the Studio app source inline. It needs an NVIDIA GPU with at least 48 GB of memory for the default model and a driver that supports CUDA 13.

### How do I update to a newer version?

This Launchable pins vLLM v0.33.0 by digest and Gradio 6.32.0 so every deploy is the same. To try a newer release on your own instance, change the pins in `compose.yaml` under `/home/ubuntu/workspace` and run `sudo docker compose up -d`; your models and uploads are kept.

## Guides and related Launchables

- Step-by-step guide: [Run the studio's Nemotron Omni model with vLLM](https://www.9owls.com/guides/run-nemotron-3-nano-omni-with-vllm/)
- [How to deploy a Launchable on NVIDIA Brev](https://www.9owls.com/guides/deploy-a-launchable-on-nvidia-brev/)
- [Serve NVIDIA Nemotron with vLLM](https://www.9owls.com/guides/serve-nvidia-nemotron-with-vllm/)
- [Serve an OpenAI-compatible API with vLLM](https://www.9owls.com/guides/serve-an-openai-compatible-api-with-vllm/)
- [How to stop and delete an NVIDIA Brev instance](https://www.9owls.com/guides/stop-start-and-delete-an-nvidia-brev-instance/)
- [Compare GPUs for LLM inference: NVIDIA L4 vs L40S](https://www.9owls.com/compare/nvidia-l4-vs-l40s-for-llm-inference/)
- [Parse documents with NVIDIA Nemotron Parse and Nemotron Omni](https://www.9owls.com/guides/parse-documents-with-nemotron-parse-and-omni/)
- [Run a browser agent in an OpenShell sandbox](https://www.9owls.com/guides/run-a-browser-agent-in-an-openshell-sandbox/)
- This Launchable on 9owls: https://www.9owls.com/launchables/nemotron-omni-studio/
- All Launchables by 9owls: https://www.9owls.com/launchables/
- Related: [Nemotron Chat with Open WebUI and vLLM](https://www.9owls.com/launchables/nemotron-chat/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aArulP2ZTX7HwqGLf4pwRT6z)); [Chatterbox + WhisperX Voice Lab](https://www.9owls.com/launchables/voice-lab/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M7TTV4QXYErJeINLDl77bsMVyb)); [Cosmos 3 Nano World Model Studio](https://www.9owls.com/launchables/cosmos3-video-studio/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aVI8A9ooLqzhwIEkWuuY27Pm))

## Keep your own stack running

NightKeeper packages your repository as an NVIDIA Brev Launchable, proves it on a fresh GPU and keeps it running. Your Brev API key stays in your repository's GitHub secrets. NightKeeper never sees it.

[Create your Launchable](https://www.9owls.com/nightkeeper/start/) or [read about NightKeeper](https://www.9owls.com/nightkeeper/).

## Credits and licences

- [vLLM](https://github.com/vllm-project/vllm): Apache-2.0.
- [Gradio](https://github.com/gradio-app/gradio): Apache-2.0.
- NVIDIA Nemotron 3 Nano Omni is licensed by NVIDIA Corporation under the [NVIDIA Open Model Agreement](https://www.nvidia.com/en-us/agreements/enterprise-software/nvidia-open-model-agreement/). By deploying with this model you accept its terms; read the [model card](https://huggingface.co/nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-FP8) before use.
- [Qwen2.5-Omni-7B](https://huggingface.co/Qwen/Qwen2.5-Omni-7B): Apache-2.0.

Files in this folder: `compose.yaml` (the stack, every image and package pinned; the Studio app source is inline) and [LICENSE](LICENSE) (Apache-2.0 for the files in this folder, with upstream attributions).

Published and maintained by [9owls, Inc.](https://www.9owls.com/). Questions: hello@9owls.com.
