<p align="center">
  <strong>Chatterbox and WhisperX on NVIDIA Brev</strong><br>
  Text-to-speech and speech-to-text on one NVIDIA L4, behind OpenAI-compatible audio endpoints, with permissively licensed open-source engines and models.
</p>

# Chatterbox + WhisperX Voice Lab

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M7TTV4QXYErJeINLDl77bsMVyb)

Launchable ID: env-3M7TTV4QXYErJeINLDl77bsMVyb

Text-to-speech with [Chatterbox](https://github.com/resemble-ai/chatterbox) by Resemble AI and speech-to-text with [WhisperX](https://github.com/m-bain/whisperX) on your own GPU, behind OpenAI-compatible `/v1/audio/speech` and `/v1/audio/transcriptions` endpoints. The default compute is one NVIDIA L4 24GB, and the speech engines and every model they download are under permissive licences (MIT, BSD or CC-BY-4.0). First step: deploy, click the open-voice-lab link, type a sentence and click Speak, then transcribe the result.

| Quick facts | |
| --- | --- |
| Runs | Chatterbox (text-to-speech) and WhisperX (speech-to-text with English word timings and optional speaker labels), two containers under Docker Compose |
| Default compute | 1x NVIDIA L4 24GB on GCP (g2-standard-8), stoppable; you can pick another GPU on the deploy page |
| Disk | 150 GiB |
| Ready in | about 14 minutes on a fresh deploy (2026-11-15) |
| Cost | about $1.02/hr on the default compute (console, 2026-11-15); storage is billed while stopped |
| Secrets | HF_TOKEN, optional, only for speaker labels |
| Licences | Chatterbox MIT, WhisperX BSD-2-Clause, faster-whisper MIT, pyannote.audio MIT, speaker-diarization-community-1 CC-BY-4.0 |
| Guide | https://www.9owls.com/launchables/voice-lab/ |

Current versions: chatterbox-tts 0.1.7 (torch 2.6.0), whisperx 3.8.6 (torch 2.8.0, faster-whisper 1.2.1, ctranslate2 4.8.5, pyannote-audio 4.0.7), python:3.11.18-slim-bookworm

Last smoke: 2026-11-15, fresh deploy on one NVIDIA L4 24GB. /health was ready about 14 minutes after launch; a speech request round-tripped through transcription word for word.

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
| Base image (both services) | Python 3.11.18 on Debian bookworm, pinned by digest | `python:3.11.18-slim-bookworm@sha256:a83ba18aef0f865b1a4a611c2cf460fe446f2795673bbb9fe43be570439e3b39` |
| Chatterbox (original English model) | chatterbox-tts 0.1.7, torch 2.6.0, torchaudio 2.6.0 | pip, installed once into the workspace |
| WhisperX | whisperx 3.8.6, torch 2.8.0, torchaudio 2.8.0, torchvision 0.23.0, torchcodec 0.7.0, faster-whisper 1.2.1, ctranslate2 4.8.5, pyannote-audio 4.0.7 | pip, installed once into the workspace |
| Speech weights | `ResembleAI/chatterbox` at commit 5bb1f6ee58e50c3b8d408bc82a6d3740c2db6e18 (MIT) | Hugging Face |
| Transcription weights (default) | `mobiuslabsgmbh/faster-whisper-large-v3-turbo` at commit 0a363e9161cbc7ed1431c9597a8ceaf0c4f78fcf (MIT) | Hugging Face |
| Transcription weights (choice) | `Systran/faster-whisper-large-v3` at commit edaa852ec7e145841d8ffdb056a99866b5f0a478 (MIT) | Hugging Face |
| English word timings | torchaudio `WAV2VEC2_ASR_BASE_960H` (wav2vec 2.0, MIT) | fixed by the torchaudio 2.8.0 pin |
| Speaker labels (optional) | `pyannote/speaker-diarization-community-1` at commit 3533c8cf8e369892e6b79ff1bf80f7b0286a54ee (CC-BY-4.0, gated) | Hugging Face, downloaded only with your own token |
| FFmpeg | Debian bookworm package | apt, installed at first start |
| The stack | two services, every image, package and model download pinned | [compose.yaml](compose.yaml) in this folder |

Every audio file Chatterbox generates carries Resemble AI's imperceptible Perth watermark, as documented upstream.

## Deploy in three steps

1. Click Launch on Brev, keep the NVIDIA L4 or pick another GPU with at least 24 GB, choose the WHISPER_MODEL, optionally set HF_TOKEN, and deploy.
2. Wait until the instance shows Running and the open-voice-lab link shows both engines ready. The first start installs each service's pinned Python environment and downloads its model weights once; allow about 20 minutes after the instance is Running. On the smoke deploy of 2026-11-15, /health was ready about 14 minutes after launch.
3. Click **open-voice-lab**. The test page shows whether both engines are ready. Type text and click **Speak**, or choose an audio file and click **Transcribe**.

## Try it first

1. On the test page, keep the sample text "Hello from my own GPU." and click **Speak**. The audio plays in the page and is saved as a WAV under `outputs/` in the workspace.
2. Download that audio or record a short clip, choose it under "Speech to text - WhisperX" and click **Transcribe**. English audio comes back with segment and word timings in JSON.
3. From your machine, run the round trip with curl after the port forward in [Use it from your machine](#use-it-from-your-machine): generate `hello.wav` with the speech endpoint, then transcribe it and compare the text.

## How it works

- Two services under Docker Compose, each on the same pinned Python base image, because Chatterbox and WhisperX need different PyTorch versions.
- `chatterbox` serves port 8000: the test page at `/`, `POST /v1/audio/speech`, `/health` and `/v1/models`. It forwards `POST /v1/audio/transcriptions` to `whisperx`. Port 8000 is reached through the authenticated Brev Secure Link **open-voice-lab**.
- `whisperx` runs faster-whisper transcription, English word timings and optional speaker labels on port 8001, internal only, with no host port.
- `GET /health` returns HTTP 503 until both engines are loaded, then HTTP 200, and includes the GPU name each engine sees.
- Both engines run on the instance GPU. Audio you send is processed on the instance; model weights are downloaded from Hugging Face once at a fixed commit.
- Word timings are English only. Audio in other languages gets segment timings.

<details>
<summary>Advanced: API reference</summary>

| Endpoint | Notes |
| --- | --- |
| `POST /v1/audio/speech` | JSON body. `input` (up to 4096 characters, split into sentences internally), `response_format` `mp3` (default), `opus`, `aac`, `flac`, `wav` or `pcm` (16-bit mono, 24 kHz). `model` is accepted and ignored. Extra fields: `exaggeration` and `cfg_weight` (Chatterbox, default 0.5). `speed` is not supported. |
| `POST /v1/audio/transcriptions` | Multipart. `file` (any format ffmpeg reads), optional `language`, `response_format` `json` (default), `text`, `verbose_json`, `srt` or `vtt`. English audio gets word timings in `verbose_json`; other languages get segment timings. Extra field: `diarize=true` adds a `speaker` to each segment and word. |
| `GET /v1/models` | `chatterbox` and `whisperx`. |
| `GET /health` | 200 when both engines are ready; includes the GPU name each engine sees. |

Voices: OpenAI voice names such as `alloy` use Chatterbox's built-in voice. To clone a voice, copy a clean 10-second WAV clip to `/home/ubuntu/workspace/voice-lab/voices/NAME.wav` on the instance, then pass `"voice": "NAME"`. Only clone voices you have the right to use.

</details>

## Settings

| Parameter | Required | Default | What it does |
| --- | --- | --- | --- |
| WHISPER_MODEL | yes (Choice) | large-v3-turbo | `large-v3-turbo` (faster, smaller) or `large-v3` (most accurate). |
| HF_TOKEN | no (Text) | none | Hugging Face read token, used only for speaker labels. Accept the conditions of [pyannote/speaker-diarization-community-1](https://huggingface.co/pyannote/speaker-diarization-community-1) first. On the deploy page choose "Use a secret" to bind a saved secret if that option is available to you, or paste the token. |

## Use it from your machine

Secure Links require your Brev login, so call the API through a port forward from your machine:

```
brev port-forward INSTANCE_NAME --port 8000:8000
```

The test page and the API then answer on http://localhost:8000.

Text to speech:

```
curl http://localhost:8000/v1/audio/speech -H "Content-Type: application/json" -d '{"model": "chatterbox", "input": "Hello from my own GPU.", "response_format": "wav"}' -o hello.wav
```

Speech to text:

```
curl http://localhost:8000/v1/audio/transcriptions -F file=@hello.wav -F model=whisperx -F response_format=verbose_json
```

Speech to text with speaker labels (needs HF_TOKEN):

```
curl http://localhost:8000/v1/audio/transcriptions -F file=@meeting.mp3 -F model=whisperx -F response_format=verbose_json -F diarize=true
```

With the OpenAI Python SDK, set `base_url="http://localhost:8000/v1"` and any placeholder API key.

## Data and persistence

Everything is on the instance under `/home/ubuntu/workspace/voice-lab`:

| Path | Contents |
| --- | --- |
| `outputs/` | every generated speech file (WAV) |
| `voices/` | your reference clips for voice cloning |
| `hf-cache/`, `torch-cache/` | model weights |
| `envs/` | the pinned Python environments |

These folders survive **Stop** and are destroyed by **Delete**. Copy anything you want to keep before you delete, for example:

```
scp -r INSTANCE_NAME:/home/ubuntu/workspace/voice-lab/outputs ./voice-lab-outputs
```

## Stop, start and delete

- **Stop** pauses GPU billing. Storage keeps billing while stopped. Everything under `/home/ubuntu/workspace/voice-lab` is kept.
- **Start** it again: both services come back by themselves (`restart: unless-stopped`) with the same launch parameters; nothing is downloaded again. Later starts take about 2 to 3 minutes.
- **Delete** ends all billing and destroys the instance and all data on it. It cannot be undone.

## Troubleshooting

<details>
<summary>The test page says loading, or /health returns 503</summary>

This is expected during the first start: each service installs its pinned Python environment and downloads its model weights once, which takes about 20 minutes after the instance is Running. `/health` turns to HTTP 200 when both engines are loaded. To watch progress, open a terminal with `brev shell INSTANCE_NAME` and run `sudo docker logs --tail 30 voice-lab-chatterbox-1` and `sudo docker logs --tail 30 voice-lab-whisperx-1`. The lines `chatterbox ready on ...` and `whisperx ready: ...` mean each engine is up.

</details>

<details>
<summary>A log shows "failed to load" and the service restarts</summary>

The service exits when its engine cannot load and Docker restarts it. Read the line after `failed to load` in the same `docker logs` output. The instance needs internet access on the first start to reach PyPI, Debian and Hugging Face.

</details>

<details>
<summary>Transcription with diarize=true returns HTTP 400</summary>

Speaker labels need the HF_TOKEN launch parameter, and the Hugging Face account behind it must have accepted the conditions of pyannote/speaker-diarization-community-1. Without a token, transcription without `diarize=true` still works.

</details>

<details>
<summary>curl to the Secure Link asks for a login</summary>

Secure Links require your Brev login. Use `brev port-forward INSTANCE_NAME --port 8000:8000` and call http://localhost:8000 instead.

</details>

## FAQ

### Which GPU do I need?

One NVIDIA GPU with 24 GB of VRAM is the tested size; the default is one NVIDIA L4 24GB with 150 GiB of disk. Smaller cards are untested. If you swap the instance, keep at least 24 GB.

### Does anything leave the instance?

Audio you send and the speech you generate are processed and stored on the instance. On the first start the instance downloads its pinned Python packages, the Debian FFmpeg package and the model weights; the speaker-label model is downloaded only with your own Hugging Face token.

### Is the API compatible with OpenAI clients?

Yes, for speech and transcription. Point the OpenAI Python SDK at `http://localhost:8000/v1` through the port forward, with any placeholder API key. `model` is accepted and ignored for speech, and `speed` is not supported.

### Can I clone a voice?

Yes. Copy a clean 10-second WAV clip to `/home/ubuntu/workspace/voice-lab/voices/NAME.wav` and pass `"voice": "NAME"`. Only clone voices you have the right to use. Every output carries the Perth watermark.

### Can I run this on my own hardware?

Yes. The stack is the [compose.yaml](compose.yaml) in this folder on a host with an NVIDIA GPU and Docker with GPU support; change the host path `/home/ubuntu/workspace/voice-lab` to a folder on your machine. See [Chatterbox](https://github.com/resemble-ai/chatterbox) and [WhisperX](https://github.com/m-bain/whisperX) for their own requirements.

### How do I update to a newer version?

This Launchable pins every package and model commit so every deploy is the same. Each service installs its environment once and keeps a marker file named for the chatterbox-tts or whisperx version under `envs/`; when you run your own copy of `compose.yaml` with a new chatterbox-tts or whisperx version, the next start installs a fresh environment for it.

## Guides and related Launchables

- Step-by-step guide: [How to run Chatterbox TTS and WhisperX on your own GPU](https://www.9owls.com/guides/run-chatterbox-tts-and-whisperx-on-a-gpu/)
- [How to deploy a Launchable on NVIDIA Brev](https://www.9owls.com/guides/deploy-a-launchable-on-nvidia-brev/)
- [How to stop and delete an NVIDIA Brev instance](https://www.9owls.com/guides/stop-start-and-delete-an-nvidia-brev-instance/)
- [What is a Brev Launchable?](https://www.9owls.com/guides/what-is-a-brev-launchable/)
- [Brev Launchables FAQ](https://www.9owls.com/faq/brev-launchable-basics/): billing, persistence and choosing a GPU
- [Voice Launchables](https://www.9owls.com/topics/voice/): other speech stacks on NVIDIA Brev
- This Launchable on 9owls: https://www.9owls.com/launchables/voice-lab/
- All Launchables by 9owls: https://www.9owls.com/launchables/
- Related: [Pipecat Voice Agent with Nemotron Speech](https://www.9owls.com/launchables/pipecat-voice-agent-nemotron/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8b9S3MTLbdyBbCVcA9ZrJhGAJ)); [Nemotron Omni Multimodal Studio](https://www.9owls.com/launchables/nemotron-omni-studio/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8a9cKCTehBUEgzwkv7tqk9gZK)); [Open Notebook on Nemotron](https://www.9owls.com/launchables/open-notebook-nemotron/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8a9DRg8X8LZyGjEtqCwWcjaYS))

## Keep your own stack running

NightKeeper packages your repository as an NVIDIA Brev Launchable, proves it on a fresh GPU and keeps it running. Your Brev API key stays in your repository's GitHub secrets. NightKeeper never sees it.

[Create your Launchable](https://www.9owls.com/nightkeeper/start/) or [read about NightKeeper](https://www.9owls.com/nightkeeper/).

## Credits and licences

The files in this folder are Apache-2.0 (see [LICENSE](LICENSE)). Each component keeps its own licence:

- [Chatterbox](https://github.com/resemble-ai/chatterbox) by Resemble AI (code and weights) - MIT. Outputs carry the Perth watermark (resemble-perth, MIT).
- [WhisperX](https://github.com/m-bain/whisperX) by Max Bain and contributors - BSD-2-Clause.
- [faster-whisper](https://github.com/SYSTRAN/faster-whisper) by SYSTRAN and [CTranslate2](https://github.com/OpenNMT/CTranslate2) - MIT.
- [Whisper](https://github.com/openai/whisper) by OpenAI; weights as faster-whisper conversions by Systran and Mobius Labs - MIT.
- wav2vec 2.0 English aligner by Meta AI, packaged in [torchaudio](https://github.com/pytorch/audio) - MIT.
- [pyannote.audio](https://github.com/pyannote/pyannote-audio) by pyannoteAI and contributors - MIT. pyannote/speaker-diarization-community-1 - CC-BY-4.0: attribute pyannote if you publish diarization results.
- PyTorch, torchaudio, torchvision, torchcodec - BSD-style. The PyTorch wheels include NVIDIA CUDA libraries under NVIDIA's terms.
- FFmpeg - installed from Debian at first start, under the LGPL/GPL terms of that build.
- Other Python dependencies are installed from PyPI under their own licences.

Files in this folder: `compose.yaml` (the stack; every image, package and model download is pinned, with the reason and the date it was read) and [LICENSE](LICENSE) (Apache-2.0 for the files in this folder, with upstream attributions).

Published and maintained by [9owls, Inc.](https://www.9owls.com/). Questions: hello@9owls.com.
