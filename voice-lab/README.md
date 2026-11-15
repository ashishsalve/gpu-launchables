# Chatterbox + WhisperX Voice Lab

Text-to-speech with [Chatterbox](https://github.com/resemble-ai/chatterbox) by Resemble AI and speech-to-text with [WhisperX](https://github.com/m-bain/whisperX) on your own GPU, behind OpenAI-compatible `/v1/audio/speech` and `/v1/audio/transcriptions` endpoints. The speech engines and every model they download are under permissive licences (MIT, BSD or CC-BY-4.0). Wired together with Docker Compose.

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M7TTV4QXYErJeINLDl77bsMVyb)

Launchable ID: env-3M7TTV4QXYErJeINLDl77bsMVyb

Current versions: chatterbox-tts 0.1.7 (torch 2.6.0), whisperx 3.8.6 (torch 2.8.0, faster-whisper 1.2.1, ctranslate2 4.8.5, pyannote-audio 4.0.7), python:3.11.18-slim-bookworm

Last smoke: not yet run. Versions were read from their registries on 2026-11-14.

## What it runs

| Service | What | Port |
|---|---|---|
| `chatterbox` | Chatterbox (original English model) for `POST /v1/audio/speech`, plus a small test page, `/health` and `/v1/models`. Forwards transcription requests to `whisperx`. | 8000 (Secure Link **open-voice-lab**) |
| `whisperx` | WhisperX: faster-whisper transcription, English word timings, optional speaker labels. | 8001, internal only |

Model weights download from Hugging Face at a fixed commit, under their own licences:

- Speech: `ResembleAI/chatterbox` (MIT).
- Transcription: `mobiuslabsgmbh/faster-whisper-large-v3-turbo` (default) or `Systran/faster-whisper-large-v3` (both MIT).
- English word timings: torchaudio `WAV2VEC2_ASR_BASE_960H` (wav2vec 2.0, MIT).
- Speaker labels (optional): `pyannote/speaker-diarization-community-1` (CC-BY-4.0, gated; downloaded only with your own Hugging Face token).

Every audio file Chatterbox generates carries Resemble AI's imperceptible Perth watermark, as documented upstream.

## Hardware and timing

- Default instance: 1x NVIDIA L4 24 GB, stoppable, 100 GiB disk. The deploy page shows the current hourly price.
- Minimum GPU: 24 GB VRAM is the tested size. Smaller cards are untested. If you swap the instance, keep at least 24 GB.
- First start: about 20 minutes after the instance is Running. Each service installs its pinned Python environment and downloads its model weights once.
- Later starts (after Stop and Start): about 2 to 3 minutes. Nothing is downloaded again.

`GET /health` returns HTTP 503 until both engines are loaded, then HTTP 200.

## Launch parameters

| Name | Type | Default | Purpose |
|---|---|---|---|
| WHISPER_MODEL | Choice | large-v3-turbo | `large-v3-turbo` (faster, smaller) or `large-v3` (most accurate). |
| HF_TOKEN | Text (optional) | none | Hugging Face read token, used only for speaker labels. Accept the conditions of [pyannote/speaker-diarization-community-1](https://huggingface.co/pyannote/speaker-diarization-community-1) first. On the deploy page choose "Use a secret" to bind a saved secret if that option is available to you, or paste the token. |

## Use it

1. Deploy and wait until the instance is Running, then about 20 minutes for the first start.
2. Click **open-voice-lab**. The test page shows whether both engines are ready.
3. Type text and click **Speak**, or choose an audio file and click **Transcribe**.

## OpenAI-compatible API

Secure Links require your Brev login, so call the API through a port forward from your machine:

```
brev port-forward INSTANCE_NAME --port 8000:8000
```

Text to speech:

```
curl http://localhost:8000/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{"model": "chatterbox", "input": "Hello from my own GPU.", "response_format": "wav"}' \
  -o hello.wav
```

Speech to text:

```
curl http://localhost:8000/v1/audio/transcriptions \
  -F file=@hello.wav -F model=whisperx -F response_format=verbose_json
```

Speech to text with speaker labels (needs HF_TOKEN):

```
curl http://localhost:8000/v1/audio/transcriptions \
  -F file=@meeting.mp3 -F model=whisperx -F response_format=verbose_json -F diarize=true
```

With the OpenAI Python SDK, set `base_url="http://localhost:8000/v1"` and any placeholder API key.

| Endpoint | Notes |
|---|---|
| `POST /v1/audio/speech` | JSON body. `input` (up to 4096 characters, split into sentences internally), `response_format` `mp3` (default), `opus`, `aac`, `flac`, `wav` or `pcm` (16-bit mono, 24 kHz). `model` is accepted and ignored. Extra fields: `exaggeration` and `cfg_weight` (Chatterbox, default 0.5). `speed` is not supported. |
| `POST /v1/audio/transcriptions` | Multipart. `file` (any format ffmpeg reads), optional `language`, `response_format` `json` (default), `text`, `verbose_json`, `srt` or `vtt`. English audio gets word timings in `verbose_json`; other languages get segment timings. Extra field: `diarize=true` adds a `speaker` to each segment and word. |
| `GET /v1/models` | `chatterbox` and `whisperx`. |
| `GET /health` | 200 when both engines are ready; includes the GPU name each engine sees. |

Voices: OpenAI voice names such as `alloy` use Chatterbox's built-in voice. To clone a voice, copy a clean 10-second WAV clip to `/home/ubuntu/workspace/voice-lab/voices/NAME.wav` on the instance, then pass `"voice": "NAME"`. Only clone voices you have the right to use.

## Where your data lives

Everything is on the instance under `/home/ubuntu/workspace/voice-lab`:

| Path | Contents |
|---|---|
| `outputs/` | every generated speech file (WAV) |
| `voices/` | your reference clips for voice cloning |
| `hf-cache/`, `torch-cache/` | model weights |
| `envs/` | the pinned Python environments |

These folders survive **Stop** and are destroyed by **Delete**. Copy anything you want to keep before you delete, for example:

```
scp -r INSTANCE_NAME:/home/ubuntu/workspace/voice-lab/outputs ./voice-lab-outputs
```

## Stop vs delete

- **Stop** pauses GPU billing. Storage keeps billing while stopped. On start, both services come back by themselves (`restart: unless-stopped`) with the same launch parameters; nothing is downloaded again.
- **Delete** ends all billing and destroys the instance and all data on it. It cannot be undone.

## Licences

The files in this repository are Apache-2.0 (see `LICENSE`). Each component keeps its own licence:

- Chatterbox (code and weights) - MIT, Resemble AI. Outputs carry the Perth watermark (resemble-perth, MIT).
- WhisperX - BSD-2-Clause, Max Bain.
- faster-whisper and CTranslate2 - MIT.
- Whisper weights (faster-whisper conversions by Systran and Mobius Labs) - MIT.
- wav2vec 2.0 English aligner (via torchaudio) - MIT.
- pyannote.audio - MIT. pyannote/speaker-diarization-community-1 - CC-BY-4.0: credit pyannote if you publish diarization results.
- PyTorch, torchaudio, torchvision, torchcodec - BSD-style. The PyTorch wheels include NVIDIA CUDA libraries under NVIDIA's terms.
- FFmpeg - installed from Debian at first start, under the LGPL/GPL terms of that build.
- Other Python dependencies are installed from PyPI under their own licences.

## Files

- `compose.yaml` - the stack. Every image, package and model download is pinned, with the reason and the date it was read.
- `LICENSE` - Apache-2.0 for the files in this repository, with upstream credits.

## Acknowledgements

- [Chatterbox](https://github.com/resemble-ai/chatterbox) by Resemble AI.
- [WhisperX](https://github.com/m-bain/whisperX) by Max Bain and contributors.
- [faster-whisper](https://github.com/SYSTRAN/faster-whisper) by SYSTRAN, on [CTranslate2](https://github.com/OpenNMT/CTranslate2).
- [Whisper](https://github.com/openai/whisper) by OpenAI.
- [pyannote.audio](https://github.com/pyannote/pyannote-audio) by pyannoteAI and contributors.
- wav2vec 2.0 by Meta AI, packaged in [torchaudio](https://github.com/pytorch/audio).
