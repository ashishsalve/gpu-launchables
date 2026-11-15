# Pipecat Voice Agent with Nemotron Speech

Talk to a real-time voice agent in your browser, running entirely on one GPU. This environment deploys the [NVIDIA Nemotron Voice Agent blueprint](https://github.com/NVIDIA-AI-Blueprints/nemotron-voice-agent) with its single-GPU profile: Nemotron streaming speech recognition (ASR), the Nemotron 3.5 Lightning language model on [vLLM](https://github.com/vllm-project/vllm), and Magpie text to speech (TTS), connected by a [Pipecat](https://github.com/pipecat-ai/pipecat) speech to speech pipeline with a WebRTC browser app. It needs only a Hugging Face token; no NGC key is required.

Current versions: blueprint v2.3.1 (commit 1f5bd71), vLLM v0.31.0, NeMo-Speech.cpp 0.2.0, coturn 4.5.2 (by digest), uv 0.13.8

Last smoke: not yet run

## What it runs

| Component | Version | Source |
| --- | --- | --- |
| Nemotron Voice Agent app (Pipecat, WebRTC UI) | v2.3.1 | built on the instance from the tagged blueprint source |
| vLLM serving Nemotron 3.5 Lightning 30B-A3B (NVFP4) | v0.31.0 | `vllm/vllm-openai:v0.31.0` |
| NeMo-Speech.cpp (ASR and TTS) | 0.2.0 | `nvcr.io/nvidia/nemo-speech.cpp:0.2.0` |
| coturn TURN relay | 4.5.2 | `instrumentisto/coturn:4.5.2@sha256:6c25f154177c9e9fccc3ba6f28455ad3b0a869f00be0562853a327b5f7b6069a` |

The setup script clones the blueprint at tag v2.3.1, checks the commit, runs the blueprint's `scripts/download-nemo-speech-models.sh` to fetch the speech models into `~/workspace/nemotron-voice-agent/models/nemo-speech`, and starts the blueprint's own Docker Compose stack. Image versions are the ones the blueprint pins at that tag, except coturn, which a small Compose override pins to version 4.5.2 by digest. The model download script uses [uv](https://github.com/astral-sh/uv) 0.13.8, installed from its release archive with a checksum check into `~/workspace/tools`.

## Models

| Role | Model | Licence |
| --- | --- | --- |
| Language model | [nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4](https://huggingface.co/nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4) | OpenMDW-1.1 |
| Speech recognition, English (default) | [nvidia/nemotron-speech-streaming-en-0.6b](https://huggingface.co/nvidia/nemotron-speech-streaming-en-0.6b) | NVIDIA Open Model License |
| Speech recognition, multilingual | [nvidia/nemotron-3.5-asr-streaming-0.6b](https://huggingface.co/nvidia/nemotron-3.5-asr-streaming-0.6b) | OpenMDW-1.1 |
| Text to speech | [nvidia/magpie_tts_multilingual_357m](https://huggingface.co/nvidia/magpie_tts_multilingual_357m) | NVIDIA Open Model License |
| Audio codec for text to speech | [nvidia/nemo-nano-codec-22khz-1.89kbps-21.5fps](https://huggingface.co/nvidia/nemo-nano-codec-22khz-1.89kbps-21.5fps) | NVIDIA Open Model License |
| Speaker diarization (downloaded by the blueprint script) | [nvidia/Nemotron-3-Diarization](https://huggingface.co/nvidia/Nemotron-3-Diarization) | OpenMDW-1.1 |
| Voice activity detection | [Silero VAD v6.2.0, via ggml-org/whisper-vad](https://huggingface.co/ggml-org/whisper-vad) | MIT |

Models are downloaded from Hugging Face on first start by the blueprint's download script, which fetches all of the models above whichever profile you choose. By deploying you accept each model's licence:

- [NVIDIA Open Model License](https://www.nvidia.com/en-us/agreements/enterprise-software/nvidia-open-model-license/). Licensed by NVIDIA Corporation under the NVIDIA Open Model License.
- [OpenMDW License Agreement, version 1.1](https://openmdw.ai/license/1-1/).
- MIT License (Silero VAD).

## Launch parameters

- `HF_TOKEN` (required): a Hugging Face read token, used to download the models. On the deploy page you can bind a saved secret or paste a token. Never put a token anywhere except this parameter.
- `VOICE_PROFILE`: `generic-assistant/single-gpu` (default, English speech recognition) or `multilingual-assistant/single-gpu` (multilingual speech recognition). Both use the same language model and Magpie voice. These are the blueprint's own single-GPU Docker Compose profiles; the setup script runs `docker compose --profile VOICE_PROFILE --profile turn up -d` as described in the blueprint's [Getting Started guide](https://github.com/NVIDIA-AI-Blueprints/nemotron-voice-agent/blob/v2.3.1/docs/01-getting-started.md).

## GPU and disk

This Launchable defaults to one NVIDIA L40S 48GB with 200 GiB of disk. No smoke has been recorded on this configuration yet. The blueprint states that Nemotron 3.5 Lightning needs at least 28 GiB of usable GPU memory, and requires NVIDIA driver 580 or newer and Docker Compose 2.20 or newer; the setup script checks both and stops with a message if either is missing.

## Use it

1. Deploy and wait until the instance is Running. The first start builds the app and downloads the models; the blueprint notes that this can take 30-60 minutes.
2. Open the talk-to-voice-agent link and allow microphone access in your browser.
3. Start a conversation and speak. The first replies are slower while the GPU warms up.

Browser audio travels over WebRTC through the bundled TURN relay, which uses UDP port 3478 and UDP ports 49160-49200 on the instance. The relay needs these UDP ports reachable from the network your browser is on. If you connect from a network that blocks UDP, audio may not connect.

To check the language model directly, forward its port with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 18000:18000
curl http://localhost:18000/v1/models
```

## How data persists

Everything lives under `~/workspace` on the instance:

- Blueprint checkout, settings and speech models: `~/workspace/nemotron-voice-agent`
- Hugging Face model cache: `~/workspace/huggingface`

The `.env` file in the blueprint checkout holds your Hugging Face token and a TURN password generated on the instance; it is readable only by its owner. Data survives a stop and start of the instance and is removed when the instance is deleted.

## Stop or delete to control cost

- **Stop** the instance from the Brev console when you are not using it. Models and settings are kept. On the next start a system service brings the stack back and updates the TURN address, because the public IP can change; no parameter needs to be entered again. Storage is still billed while the instance is stopped.
- **Delete** the instance when you are finished. This removes the instance and all of its data, including downloaded models.

## Files

- `setup.sh` - clones the pinned blueprint, writes its configuration and starts it.
- `LICENSE` - Apache-2.0 for the files in this folder, with upstream and model licence notices.
