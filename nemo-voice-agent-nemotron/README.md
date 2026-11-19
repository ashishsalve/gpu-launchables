# NeMo Voice Agent on Nemotron

Talk to the open-source NVIDIA NeMo Voice Agent on one GPU. Streaming speech
recognition (Parakeet Realtime EOU) hears you, Nemotron 3 Diarization labels
each speaker, NVIDIA Nemotron 3.5 Lightning answers through vLLM, and Kokoro
speaks back. All models are configured to run locally on the instance; no
hosted model endpoints are configured, and no API key is needed.

Default compute: 1x NVIDIA L40S 48 GB, 200 GiB disk.

## What you get

- The NeMo Voice Agent web client behind one HTTPS link, `nemo-voice-agent`.
- A Pipecat voice pipeline: Silero VAD, streaming ASR, speaker diarization,
  Nemotron 3.5 Lightning and text to speech (Kokoro by default; Magpie is
  available through the TTS_VOICE setting).
- An OpenAI-compatible model API on the instance at localhost:8000.

## Try these three tasks

1. Open the `nemo-voice-agent` link, allow the microphone and click Connect,
   then speak to the agent.
2. Ask two people to speak in turn, then ask the agent to summarise what each
   person said. The DIARIZATION setting controls whether speaker diarization
   is enabled in the pipeline configuration.
3. Call the model directly through the API (see below) and compare its answers
   with the spoken ones.

## How it works

Caddy on port 8080 serves the web client and answers `/connect`, and the audio
WebSocket is served on `/ws` on the same port, behind the one Brev Secure Link.
The Pipecat server, its WebSocket and vLLM listen on localhost only.

## Settings

| Parameter | Values | Default | Purpose |
| --- | --- | --- | --- |
| HF_TOKEN | text | none | Optional Hugging Face read token for model downloads. Choose "Use a secret" to pick a saved secret (the option may be off for your account), or paste a token. |
| TTS_VOICE | kokoro, magpie | kokoro | Text to speech engine. |
| DIARIZATION | on, off | on | Enable or disable speaker diarization in the pipeline. |

## Use the model API from your machine

```
brev port-forward INSTANCE_NAME --port 8000:8000
curl http://localhost:8000/v1/models
```

## Data and persistence

Everything lives under `~/workspace/nemo-voice-agent` (source, Python
environment, models, web client, configuration). Launch parameters are kept in
`~/workspace/nemo-voice-agent.env` (mode 600). Delete removes the instance and
all data.

## Stop and delete

Stop pauses the GPU and keeps your disk. Delete removes the instance and all
data.

## Troubleshooting

- Setup log: `sudo cat /var/log/brev-workspace.log`
- Service status: `systemctl status nva-llm nva-server nva-proxy`
- Logs: `journalctl -u nva-server -n 200`
- Recover: `sudo systemctl restart nva-llm nva-server nva-proxy`

## Acceptable use and safety

The agent can make mistakes; check its answers. Record other people only with
their consent. Follow each model licence below.

## Versions

Current versions: NeMo Voice Agent commit
1231dfb196aa175cb0ef62453fa96c7e4afb660b (Python 3.12, dependencies from its
uv.lock: pipecat-ai 1.6.0, vLLM client 0.24.0, torch 2.11.0);
vllm/vllm-openai v0.27.1 (by digest);
nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4 at
bee7596271d1495f6992ae224aefde4410e816b8; nvidia/parakeet_realtime_eou_120m-v1
at a7e2b4629593dce0ec19f600e00e9904353fda2d; nvidia/Nemotron-3-Diarization at
52a432672732425e4c19765b9fec9b5810e6f4ba; hexgrad/Kokoro-82M at
f3ff3571791e39611d31c381e3a41a3af07b4987; nvidia/magpie_tts_multilingual_357m at
446bff55e1fe3d3aa29c771574e7d2b0fa322990; uv 0.13.8; Node.js v22.23.5;
Caddy 2.11.9; huggingface_hub 2.4.0.

Last smoke: not yet run.

## Credits and licences

- NVIDIA NeMo Voice Agent - https://github.com/NVIDIA-NeMo/labs-Voice-Agent -
  Apache License 2.0.
- Pipecat - BSD 2-Clause License. vLLM - Apache License 2.0. Caddy - Apache
  License 2.0. Node.js - MIT License. uv - Apache License 2.0 or MIT License.
- nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4 and
  nvidia/Nemotron-3-Diarization - OpenMDW License Agreement, version 1.1.
- nvidia/parakeet_realtime_eou_120m-v1 and nvidia/magpie_tts_multilingual_357m -
  Licensed by NVIDIA Corporation under the NVIDIA Open Model License.
- hexgrad/Kokoro-82M - Apache License 2.0.

This folder (README.md and setup.sh) is licensed under the Apache License 2.0;
see LICENSE.
