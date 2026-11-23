<p align="center">
  <strong>Pipecat Voice Agent on NVIDIA Brev</strong><br>
  Talk to a real-time voice agent in your browser: Nemotron speech recognition, Nemotron 3.5 Lightning on vLLM and Magpie text to speech, joined by Pipecat on one NVIDIA L40S GPU.
</p>

# Pipecat Voice Agent with Nemotron Speech

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8b9S3MTLbdyBbCVcA9ZrJhGAJ)

Launchable ID: env-3M8b9S3MTLbdyBbCVcA9ZrJhGAJ

Talk to a real-time voice agent in your browser, running entirely on one GPU. This NVIDIA Brev Launchable deploys the [NVIDIA Nemotron Voice Agent blueprint](https://github.com/NVIDIA-AI-Blueprints/nemotron-voice-agent) with its single-GPU profile: Nemotron streaming speech recognition (ASR), the Nemotron 3.5 Lightning language model on [vLLM](https://github.com/vllm-project/vllm), and Magpie text to speech (TTS), connected by a [Pipecat](https://github.com/pipecat-ai/pipecat) speech to speech pipeline with a WebRTC browser app. It needs only a Hugging Face token; no NGC key is required. Paste the token, click Launch on Brev, and about 22 minutes later open the `talk-to-voice-agent` link, allow the microphone and start speaking.

| Quick facts | |
| --- | --- |
| Runs | Pipecat voice agent app (WebRTC UI) + vLLM serving Nemotron 3.5 Lightning + NeMo-Speech.cpp for ASR and TTS + coturn TURN relay |
| Default compute | 1x NVIDIA L40S 48GB on AWS; you can pick another GPU with at least 28 GiB of usable GPU memory on the deploy page |
| Disk | 200 GiB |
| Ready in | about 22 minutes on a fresh deploy (2026-11-15) |
| Cost | about $2.23/hr on the default compute (console, 2026-11-15); storage is billed while stopped |
| Secrets | `HF_TOKEN` (Hugging Face read token, set at launch) |
| Licences | Blueprint code: Apache 2.0; Pipecat: BSD 2-Clause; vLLM and NeMo-Speech.cpp: Apache 2.0; models: OpenMDW 1.1 and NVIDIA Open Model License |
| Guide | https://www.9owls.com/launchables/pipecat-voice-agent-nemotron/ |

Current versions: blueprint v2.3.1 (commit 1f5bd71), vLLM v0.31.0, NeMo-Speech.cpp 0.2.0, coturn 4.5.2 (by digest), uv 0.13.8

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

| Component | Version | Image or source |
| --- | --- | --- |
| Nemotron Voice Agent app (Pipecat, WebRTC UI) | v2.3.1 | built on the instance from the tagged blueprint source |
| vLLM serving Nemotron 3.5 Lightning 30B-A3B (NVFP4) | v0.31.0 | `vllm/vllm-openai:v0.31.0` |
| NeMo-Speech.cpp (ASR and TTS) | 0.2.0 | `nvcr.io/nvidia/nemo-speech.cpp:0.2.0` |
| coturn TURN relay | 4.5.2 | `instrumentisto/coturn:4.5.2@sha256:6c25f154177c9e9fccc3ba6f28455ad3b0a869f00be0562853a327b5f7b6069a` |

Models:

| Role | Model | Licence |
| --- | --- | --- |
| Language model | [nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4](https://huggingface.co/nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4) | OpenMDW-1.1 |
| Speech recognition, English (default) | [nvidia/nemotron-speech-streaming-en-0.6b](https://huggingface.co/nvidia/nemotron-speech-streaming-en-0.6b) | NVIDIA Open Model License |
| Speech recognition, multilingual | [nvidia/nemotron-3.5-asr-streaming-0.6b](https://huggingface.co/nvidia/nemotron-3.5-asr-streaming-0.6b) | OpenMDW-1.1 |
| Text to speech | [nvidia/magpie_tts_multilingual_357m](https://huggingface.co/nvidia/magpie_tts_multilingual_357m) | NVIDIA Open Model License |
| Audio codec for text to speech | [nvidia/nemo-nano-codec-22khz-1.89kbps-21.5fps](https://huggingface.co/nvidia/nemo-nano-codec-22khz-1.89kbps-21.5fps) | NVIDIA Open Model License |
| Speaker diarization (downloaded by the blueprint script) | [nvidia/Nemotron-3-Diarization](https://huggingface.co/nvidia/Nemotron-3-Diarization) | OpenMDW-1.1 |
| Voice activity detection | [Silero VAD v6.2.0, via ggml-org/whisper-vad](https://huggingface.co/ggml-org/whisper-vad) | MIT |

## Deploy in three steps

1. Click **Launch on Brev**, keep the NVIDIA L40S 48GB or pick another GPU with at least 28 GiB of usable GPU memory, set `HF_TOKEN` (choose "Use a secret" and pick your saved Hugging Face secret, or paste a read token), and deploy.
2. Wait until the instance shows Running and the `talk-to-voice-agent` link answers. On the last fresh deploy the app answered after about 16 minutes and the language model was ready after about 22 minutes; the blueprint notes that a first start can take 30-60 minutes.
3. Click `talk-to-voice-agent`, allow microphone access in your browser, and speak.

## Try it first

1. Talk: open `talk-to-voice-agent`, allow the microphone and say "What can you help me with?". The agent transcribes your speech, answers with Nemotron 3.5 Lightning and speaks the reply with Magpie. The first replies are slower while the GPU warms up.
2. Check the app: in a terminal on the instance, run `curl http://localhost:7860/health`. A ready app answers `{"status":"ok"}`.
3. Check the language model: run `curl http://localhost:18000/v1/models` on the instance. The served model id is `nvidia/nemotron-3.5-lightning-30b-a3b`.

## How it works

- The Launchable defines one Brev Secure Link, `talk-to-voice-agent`, for port 7860, the Pipecat WebRTC voice app.
- Browser audio travels over WebRTC through the bundled coturn TURN relay, which uses UDP port 3478 and UDP ports 49160-49200 on the instance. These ports are allowed only from your IP address. The relay needs these UDP ports reachable from the network your browser is on; if you connect from a network that blocks UDP, audio may not connect.
- vLLM serves Nemotron 3.5 Lightning on port 18000 of the instance. NeMo-Speech.cpp runs speech recognition and text to speech on the same GPU. On the last smoke, about 43.5 GB of GPU memory was in use.
- All models run on the instance. The Hugging Face token is used only to download the models.
- A system service, `nemotron-voice-agent.service`, starts the stack on every boot and updates the TURN address, because the public IP can change after a start.

<details>
<summary>Advanced: what the setup script does</summary>

The setup script clones the blueprint at tag v2.3.1, checks the commit, runs the blueprint's `scripts/download-nemo-speech-models.sh` to fetch the speech models into `/home/ubuntu/workspace/nemotron-voice-agent/models/nemo-speech`, and starts the blueprint's own Docker Compose stack. Image versions are the ones the blueprint pins at that tag, except coturn, which a small Compose override pins to version 4.5.2 by digest. The model download script uses [uv](https://github.com/astral-sh/uv) 0.13.8, installed from its release archive with a checksum check into `/home/ubuntu/workspace/tools`.

The blueprint states that Nemotron 3.5 Lightning needs at least 28 GiB of usable GPU memory, and requires NVIDIA driver 580 or newer and Docker Compose 2.20 or newer; the setup script checks both and stops with a message if either is missing.

The blueprint's download script fetches all of the models listed in [What you get](#what-you-get), whichever profile you choose.

</details>

## Settings

| Parameter | Required | Default | What it does |
| --- | --- | --- | --- |
| `HF_TOKEN` | yes | none | A Hugging Face read token, used to download the models. On the deploy page you can bind a saved secret ("Use a secret") or paste a token. Never put a token anywhere except this parameter. |
| `VOICE_PROFILE` | no | `generic-assistant/single-gpu` | `generic-assistant/single-gpu` uses English speech recognition. `multilingual-assistant/single-gpu` uses multilingual speech recognition. Both use the same language model and Magpie voice. |

<details>
<summary>About the voice profiles</summary>

These are the blueprint's own single-GPU Docker Compose profiles; the setup script runs `docker compose --profile VOICE_PROFILE --profile turn up -d` as described in the blueprint's [Getting Started guide](https://github.com/NVIDIA-AI-Blueprints/nemotron-voice-agent/blob/v2.3.1/docs/01-getting-started.md). The last smoke ran the default `generic-assistant/single-gpu` profile.

</details>

## Use it from your machine

```
brev port-forward INSTANCE_NAME --port 18000:18000
curl http://localhost:18000/v1/models
```

The vLLM OpenAI-compatible API then answers on `http://localhost:18000/v1` with the model id `nvidia/nemotron-3.5-lightning-30b-a3b`, so an OpenAI-compatible client on your machine can use the Nemotron language model directly.

## Data and persistence

Everything lives under the Brev workspace directory on the instance:

- Blueprint checkout, settings and speech models: `/home/ubuntu/workspace/nemotron-voice-agent`
- Hugging Face model cache: `/home/ubuntu/workspace/huggingface`
- uv and the download tools: `/home/ubuntu/workspace/tools`

The `.env` file in the blueprint checkout holds your Hugging Face token and a TURN password generated on the instance; it is readable only by its owner. Data survives a stop and start of the instance and is removed when the instance is deleted.

## Stop, start and delete

- **Stop** the instance from the Brev console when you are not using it. Models and settings are kept. Storage is still billed while the instance is stopped.
- **Start** it again from the Brev console. A system service brings the stack back and updates the TURN address; no parameter needs to be entered again and nothing is downloaded again. In the last smoke, the app answered within a minute of the start and the language model about 5.5 minutes after it. If the app does not answer, run `sudo systemctl restart nemotron-voice-agent.service`.
- **Delete** the instance when you are finished. This removes the instance and all of its data, including downloaded models.

## Troubleshooting

<details>
<summary>Where are the logs?</summary>

- Setup log: `sudo cat /var/log/brev-workspace.log`
- Stack start-up: `sudo systemctl status nemotron-voice-agent.service`
- Containers: `sudo docker ps`, then `sudo docker logs CONTAINER_NAME`

</details>

<details>
<summary>The link opens but the agent does not answer</summary>

The language model is still loading. Run `curl http://localhost:18000/v1/models` on the instance; the agent answers once it lists `nvidia/nemotron-3.5-lightning-30b-a3b`. A first start can take 30-60 minutes.

</details>

<details>
<summary>The page loads but there is no audio</summary>

Check that your browser has microphone access for the page. Audio uses UDP port 3478 and UDP ports 49160-49200, allowed only from your IP address. If you connect from a network that blocks UDP, audio may not connect.

</details>

<details>
<summary>The app does not answer after a start</summary>

Run `sudo systemctl restart nemotron-voice-agent.service`, then check `curl http://localhost:7860/health`.

</details>

<details>
<summary>The setup log says the driver or Docker Compose is too old</summary>

The blueprint needs NVIDIA driver 580 or newer and Docker Compose 2.20 or newer, and the setup script stops if either is missing. Deploy again on the default compute.

</details>

## FAQ

### Which GPU do I need for the Pipecat voice agent with Nemotron?

One NVIDIA L40S 48GB, the default compute and the GPU used in the last smoke. The blueprint states that Nemotron 3.5 Lightning needs at least 28 GiB of usable GPU memory, so a 24 GB GPU is too small.

### Does anything leave the instance?

Speech recognition, the language model and text to speech all run on the instance. The Hugging Face token is used to download the models on first start, and browser audio travels between your browser and the instance over WebRTC.

### Do I need an NGC API key?

No. The images used are public and the models download from Hugging Face, so only `HF_TOKEN` is needed.

### Can I run this on my own hardware?

Yes. The blueprint documents its single-GPU profiles for your own GPU; see the [NVIDIA Nemotron Voice Agent blueprint](https://github.com/NVIDIA-AI-Blueprints/nemotron-voice-agent) and the `setup.sh` in this folder.

### How do I update to a newer version?

The blueprint, images and tools are pinned to the versions in "Current versions" above. To move to a newer release, deploy a new instance after this Launchable is updated, or change the pins in `setup.sh` on your own copy and test the result before relying on it.

## Guides and related Launchables

- Step-by-step guide: [Build a Pipecat voice agent with Nemotron Speech](https://www.9owls.com/guides/build-a-pipecat-voice-agent-with-nemotron-speech/)
- New to Launchables: [Deploy a Launchable on NVIDIA Brev](https://www.9owls.com/guides/deploy-a-launchable-on-nvidia-brev/)
- Another voice agent: [NeMo Voice Agent on Nemotron](https://www.9owls.com/launchables/nemo-voice-agent-nemotron/) and its guide [Build a NeMo voice agent on Nemotron](https://www.9owls.com/guides/build-a-nemo-voice-agent-on-nemotron/)
- Language model only: [Serve NVIDIA Nemotron with vLLM](https://www.9owls.com/guides/serve-nvidia-nemotron-with-vllm/)
- Instance lifecycle: [Stop, start and delete an NVIDIA Brev instance](https://www.9owls.com/guides/stop-start-and-delete-an-nvidia-brev-instance/)
- This Launchable on 9owls: https://www.9owls.com/launchables/pipecat-voice-agent-nemotron/
- All Launchables by 9owls: https://www.9owls.com/launchables/
- Related: [Chatterbox + WhisperX Voice Lab](https://www.9owls.com/launchables/voice-lab/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M7TTV4QXYErJeINLDl77bsMVyb)); [Nemotron Chat](https://www.9owls.com/launchables/nemotron-chat/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aArulP2ZTX7HwqGLf4pwRT6z)); [Nemotron Omni Multimodal Studio](https://www.9owls.com/launchables/nemotron-omni-studio/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8a9cKCTehBUEgzwkv7tqk9gZK))

## Keep your own stack running

NightKeeper packages your repository as an NVIDIA Brev Launchable, proves it on a fresh GPU and keeps it running. Your Brev API key stays in your repository's GitHub secrets. NightKeeper never sees it.

[Create your Launchable](https://www.9owls.com/nightkeeper/start/) or [read about NightKeeper](https://www.9owls.com/nightkeeper/).

## Credits and licences

- NVIDIA Nemotron Voice Agent blueprint: source code under the Apache License 2.0; documentation and assets under CC-BY-4.0.
- Pipecat: BSD 2-Clause License.
- vLLM: Apache License 2.0.
- NeMo-Speech.cpp: Apache License 2.0.
- coturn: BSD 3-Clause License.
- uv: Apache License 2.0 or MIT License.
- Models: [NVIDIA Open Model License](https://www.nvidia.com/en-us/agreements/enterprise-software/nvidia-open-model-license/) (licensed by NVIDIA Corporation under the NVIDIA Open Model License), [OpenMDW License Agreement, version 1.1](https://openmdw.ai/license/1-1/), and MIT License (Silero VAD). Models are downloaded from Hugging Face on first start; by deploying you accept each model's licence.
- The files in this folder: Apache License 2.0; see [LICENSE](LICENSE).

Published and maintained by [9owls, Inc.](https://www.9owls.com/). Questions: hello@9owls.com.
