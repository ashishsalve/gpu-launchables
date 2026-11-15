# Nemotron Omni Multimodal Studio

A multimodal studio for image, video and audio understanding on your own GPU. [vLLM](https://github.com/vllm-project/vllm) serves [NVIDIA Nemotron 3 Nano Omni](https://huggingface.co/nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-FP8), an omni vision language model that reads text, images, video and audio, and a small [Gradio](https://github.com/gradio-app/gradio) app gives you three tabs:

- **Image Q&A** - upload a JPEG or PNG and ask about it.
- **Video summary** - upload an MP4 and get a summary plus a timestamped outline of key events.
- **Audio transcript** - upload a WAV or MP3 and get a transcript and a short summary.

Uploads never leave the instance.

Current versions: vLLM v0.33.0 (image pinned by digest), Gradio 6.32.0, Python 3.12.12, model nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-FP8

Last smoke: not yet run

## What it runs

| Component | Version | Image |
| --- | --- | --- |
| vLLM (OpenAI-compatible server) | v0.33.0 (pinned by digest) | `vllm/vllm-openai:v0.33.0` |
| Studio web app (Gradio) | Gradio 6.32.0 (pinned) | `python:3.12.12-slim-bookworm` |

The Studio app listens on port 7860. The vLLM API is bound to the instance itself (127.0.0.1:8000) and is not exposed publicly. The vLLM image is built on CUDA 13.0, so the instance's NVIDIA driver must support CUDA 13. On first start vLLM adds its audio decoding packages (`av`, `soundfile`, `soxr`, `scipy`, pinned versions in `compose.yaml`), as the model card asks for `vllm[audio]`.

## Pick a model

Set the `MODEL` launch parameter when you deploy:

- `nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-FP8` (default, about a 33 GB download; needs a 48 GB GPU)
- `Qwen/Qwen2.5-Omni-7B` (open alternative under Apache-2.0; text, image, video and audio input)

The model is downloaded once on first start and loaded from the local cache after that. The Studio page opens before the download finishes; requests succeed once vLLM has loaded the model. To change the model, deploy again with a different `MODEL`.

Input limits from the Nemotron 3 Nano Omni model card: video in MP4 up to 2 minutes, audio in WAV or MP3 up to 1 hour. This stack accepts one image, one video and one audio file per request, a limit set by `--limit-mm-per-prompt` in `compose.yaml`. It samples video at 2 frames per second, up to 128 frames, and caps the context at 65,536 tokens (32,768 for Qwen2.5-Omni-7B), so very long audio may need to be split.

## Hugging Face token

`HF_TOKEN` is optional. Both models download without one; a token raises Hugging Face rate limits. On the deploy page you can bind a saved secret or paste a read token. Never put a token anywhere except this parameter.

## Minimum GPU

NVIDIA L40S 48GB, with 200 GiB of disk for the container images, the model cache and your uploads. The model card lists 1x L40S 48GB as the minimum GPU for the FP8 model and recommends 1x RTX PRO 6000 or 1x B200.

## Use it

1. Deploy and wait until the instance is Running.
2. Open the open-omni-studio link.
3. Pick a tab, upload a file and press the button. The first request after a start takes longer while vLLM finishes loading.

To call the OpenAI-compatible API from your own machine, forward the port with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 8000:8000
curl http://localhost:8000/v1/models
```

The API accepts `image_url`, `video_url` and `audio_url` content parts. Local files must sit under `/home/ubuntu/workspace/media` on the instance and are passed as `file:///media/NAME`.

## How data persists

Models and uploads live on the instance:

- Models (Hugging Face cache): `/home/ubuntu/workspace/huggingface`
- Uploaded files: `/home/ubuntu/workspace/media/uploads` (delete old uploads to free disk)

They survive a stop and start of the instance. They are removed when the instance is deleted.

## Stop or delete to control cost

- **Stop** the instance from the Brev console when you are not using it. Your models and uploads are kept, and both containers are recreated on the next start (see Stop and start). Storage is still billed while the instance is stopped.
- **Delete** the instance when you are finished. This removes the instance and all of its data, including downloaded models and uploads.

## Stop and start

Stopping the instance removes the studio's containers; everything under ~/workspace is kept. Starting it again recreates the containers automatically, usually within a few minutes. If the studio is not back after 5 minutes, open a terminal on the instance and run:

```
cd /home/ubuntu/workspace && sudo docker compose up -d
```

## Model licence

NVIDIA Nemotron 3 Nano Omni is licensed by NVIDIA Corporation under the [NVIDIA Open Model Agreement](https://www.nvidia.com/en-us/agreements/enterprise-software/nvidia-open-model-agreement/). By deploying with this model you accept its terms; read the [model card](https://huggingface.co/nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-FP8) before use. [Qwen2.5-Omni-7B](https://huggingface.co/Qwen/Qwen2.5-Omni-7B) is licensed under Apache-2.0.

## Files

- `compose.yaml` - the stack, every image and package pinned; the Studio app source is inline.
- `LICENSE` - Apache-2.0 for the files in this folder, with upstream attributions.
