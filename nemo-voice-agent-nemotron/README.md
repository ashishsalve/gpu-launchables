<p align="center">
  <strong>NeMo Voice Agent on NVIDIA Brev</strong><br>
  Talk to the open-source NVIDIA NeMo Voice Agent: streaming speech recognition, Nemotron 3 Diarization, NVIDIA Nemotron 3.5 Lightning on vLLM and Kokoro speech, all on one NVIDIA L40S GPU, with no API key.
</p>

# NeMo Voice Agent on Nemotron

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3MJWty68hgJwmLpbCTRMPereHGb)

Launchable ID: env-3MJWty68hgJwmLpbCTRMPereHGb

[NVIDIA NeMo Voice Agent](https://github.com/NVIDIA-NeMo/labs-Voice-Agent) is an open-source voice agent built on the [Pipecat](https://github.com/pipecat-ai/pipecat) voice pipeline. This NVIDIA Brev Launchable runs it on one NVIDIA L40S 48 GB GPU: streaming speech recognition (Parakeet Realtime EOU) hears you, Nemotron 3 Diarization labels each speaker, NVIDIA Nemotron 3.5 Lightning answers through [vLLM](https://github.com/vllm-project/vllm), and Kokoro speaks back. All models are configured to run locally on the instance; no hosted model endpoints are configured, and no API key is needed. Click Launch on Brev, and about 35 minutes later open the `nemo-voice-agent` link, allow the microphone and click Connect.

| Quick facts | |
| --- | --- |
| Runs | NeMo Voice Agent web client and Pipecat server + vLLM serving Nemotron 3.5 Lightning + Parakeet Realtime EOU speech recognition + Nemotron 3 Diarization + Kokoro or Magpie speech output + Caddy |
| Default compute | 1x NVIDIA L40S 48 GB on AWS; you can pick another GPU with at least 44000 MiB of memory on the deploy page |
| Disk | 256 GiB |
| Ready in | about 35 minutes on a fresh deploy (2026-11-19) |
| Cost | about $2.27/hr on the default compute including 256 GiB storage (console, 2026-11-19); storage is billed while stopped |
| Secrets | `HF_TOKEN` (optional Hugging Face read token) |
| Licences | NeMo Voice Agent: Apache 2.0; Pipecat: BSD 2-Clause; vLLM: Apache 2.0; Nemotron 3.5 Lightning and Nemotron 3 Diarization: OpenMDW 1.1; Parakeet and Magpie: NVIDIA Open Model License; Kokoro: Apache 2.0 |
| Guide | https://www.9owls.com/launchables/nemo-voice-agent-nemotron/ |

Current versions: NeMo Voice Agent commit 1231dfb196aa175cb0ef62453fa96c7e4afb660b (Python 3.12, dependencies from its uv.lock: pipecat-ai 1.6.0, vLLM client 0.24.0, torch 2.11.0); vllm/vllm-openai v0.27.1 (by digest); nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4 at bee7596271d1495f6992ae224aefde4410e816b8; nvidia/parakeet_realtime_eou_120m-v1 at a7e2b4629593dce0ec19f600e00e9904353fda2d; nvidia/Nemotron-3-Diarization at 52a432672732425e4c19765b9fec9b5810e6f4ba; hexgrad/Kokoro-82M at f3ff3571791e39611d31c381e3a41a3af07b4987; nvidia/magpie_tts_multilingual_357m at 446bff55e1fe3d3aa29c771574e7d2b0fa322990; uv 0.13.8; Node.js v22.23.5; Caddy 2.11.9; huggingface_hub 2.4.0.

Last smoke: 2026-11-19, fresh deploy on AWS g6e.xlarge (1x L40S): ready in about 35 minutes.

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
- [Acceptable use and safety](#acceptable-use-and-safety)
- [Guides and related Launchables](#guides-and-related-launchables)
- [Keep your own stack running](#keep-your-own-stack-running)
- [Credits and licences](#credits-and-licences)

## What you get

| Component | Version | Image or file |
| --- | --- | --- |
| NVIDIA NeMo Voice Agent (web client and Pipecat server) | commit 1231dfb196aa175cb0ef62453fa96c7e4afb660b, Python 3.12, pipecat-ai 1.6.0 | `setup.sh` in this folder |
| vLLM OpenAI-compatible server | v0.27.1 (pinned by digest) | `vllm/vllm-openai:v0.27.1` |
| NVIDIA Nemotron 3.5 Lightning 30B-A3B NVFP4 | revision bee7596271d1495f6992ae224aefde4410e816b8 | `nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4` |
| Parakeet Realtime EOU (speech recognition) | revision a7e2b4629593dce0ec19f600e00e9904353fda2d | `nvidia/parakeet_realtime_eou_120m-v1` |
| Nemotron 3 Diarization (speaker labels) | revision 52a432672732425e4c19765b9fec9b5810e6f4ba | `nvidia/Nemotron-3-Diarization` |
| Kokoro (default speech output) | revision f3ff3571791e39611d31c381e3a41a3af07b4987 | `hexgrad/Kokoro-82M` |
| Magpie TTS Multilingual (optional speech output) | revision 446bff55e1fe3d3aa29c771574e7d2b0fa322990 | `nvidia/magpie_tts_multilingual_357m` |
| Caddy (web client, `/connect`, `/ws`) | 2.11.9 | release archive, checked by sha512 |
| uv, Node.js, huggingface_hub | 0.13.8, v22.23.5, 2.4.0 | used by `setup.sh` |

## Deploy in three steps

1. Click **Launch on Brev**, keep the NVIDIA L40S or pick another GPU with at least 44000 MiB of memory, optionally set `HF_TOKEN`, `TTS_VOICE` and `DIARIZATION`, and deploy. No parameter is required.
2. Wait until the instance shows Running and the `nemo-voice-agent` link answers. A fresh deploy took about 35 minutes, most of it installing the environment and downloading the models.
3. Open the `nemo-voice-agent` link, allow the microphone and click Connect. The agent greets you first; then speak to it.

## Try it first

1. Open the `nemo-voice-agent` link, allow the microphone and click Connect. The agent greets you first; then ask it a question out loud.
2. Ask two people to speak in turn, then ask the agent to summarise what each person said. The `DIARIZATION` setting controls whether speaker diarization is enabled in the pipeline configuration.
3. Call the model directly through the API (see [Use it from your machine](#use-it-from-your-machine)) and compare its answers with the spoken ones.

## How it works

- The Launchable defines one Brev Secure Link, `nemo-voice-agent`, for port 8080. Caddy on port 8080 serves the web client and answers `/connect`, and the audio WebSocket is served on `/ws` on the same port. No other port needs to be opened.
- The Pipecat server, its WebSocket and vLLM listen on localhost only.
- vLLM serves Nemotron 3.5 Lightning in a Docker container on `localhost:8000` with an OpenAI-compatible API. The voice pipeline runs Silero VAD, streaming speech recognition, speaker diarization, the language model and text to speech.
- All models are downloaded from Hugging Face on first start and then run locally on the instance. No hosted model endpoint is configured.
- Three systemd services run the stack: `nva-llm` (vLLM), `nva-server` (the Pipecat server) and `nva-proxy` (Caddy). They start again by themselves after the instance is started.

<details>
<summary>Advanced: GPU memory check</summary>

The setup script reads the GPU memory before installing anything. On a GPU with less than 44000 MiB it stops with the message "this stack needs a 48 GB class GPU". The language model and the speech models share the one GPU.

</details>

## Settings

| Parameter | Required | Default | What it does |
| --- | --- | --- | --- |
| `HF_TOKEN` | no | none | Optional Hugging Face read token for model downloads. Choose "Use a secret" to pick a saved secret (the option may be off for your account), or paste a token. |
| `TTS_VOICE` | no | `kokoro` | Text to speech engine: `kokoro` (Kokoro-82M) or `magpie` (NVIDIA Magpie TTS Multilingual 357M). |
| `DIARIZATION` | no | `on` | Enable (`on`) or disable (`off`) speaker diarization in the pipeline. |

## Use it from your machine

```
brev port-forward INSTANCE_NAME --port 8000:8000
curl http://localhost:8000/v1/models
```

The vLLM OpenAI-compatible API then answers on `http://localhost:8000/v1`, and the model list shows `nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4`, so any OpenAI-compatible client on your machine can use the local Nemotron model.

## Data and persistence

- Everything lives under `~/workspace/nemo-voice-agent` (for the default `ubuntu` user, `/home/ubuntu/workspace/nemo-voice-agent`): source, Python environment, models, web client and configuration.
- Launch parameters are kept in `~/workspace/nemo-voice-agent.env` (mode 600), so the services start again without re-entering them.

These folders are under the Brev workspace directory, which Brev keeps when the instance is stopped and removes when the instance is deleted.

## Stop, start and delete

- **Stop** the instance from the Brev console when you are not using it. Stop pauses the GPU and keeps your disk. Storage is still billed while the instance is stopped.
- **Start** it again from the Brev console. systemd brings `nva-llm`, `nva-server` and `nva-proxy` back without re-entering parameters. If the agent does not answer, run `sudo systemctl restart nva-llm nva-server nva-proxy`.
- **Delete** the instance when you are finished. Delete removes the instance and all data, including downloaded models.

## Troubleshooting

<details>
<summary>Where are the logs?</summary>

- Setup log: `sudo cat /var/log/brev-workspace.log`, or the files under `~/.brev/instance-exec-logs/` where that log is not present
- Service status: `systemctl status nva-llm nva-server nva-proxy`
- Voice server log: `journalctl -u nva-server -n 200`

</details>

<details>
<summary>The agent does not answer</summary>

Check `systemctl status nva-llm nva-server nva-proxy`. To recover, run `sudo systemctl restart nva-llm nva-server nva-proxy`.

</details>

<details>
<summary>Connect fails right after a Start</summary>

The web client can be up a little before the voice server is ready, so the audio WebSocket may not answer for a short time. Wait a minute and click Connect again.

</details>

<details>
<summary>Setup stops with "this stack needs a 48 GB class GPU"</summary>

The selected GPU has less than 44000 MiB of memory. Deploy again on an NVIDIA L40S 48 GB or a larger GPU.

</details>

## FAQ

### Which GPU do I need for the NeMo Voice Agent on Nemotron?

One NVIDIA L40S 48 GB, the default compute and the GPU used in the last smoke. The setup script stops on a GPU with less than 44000 MiB of memory.

### Does anything leave the instance?

The models are downloaded from Hugging Face on first start. After that, speech recognition, the language model and speech output all run on the instance; no hosted model endpoint is configured and no API key is set.

### Do I need a Hugging Face token?

No. `HF_TOKEN` is optional; in the last smoke every model downloaded without one.

### Can I run this on my own hardware?

Yes, on a 48 GB class NVIDIA GPU. See the [NeMo Voice Agent repository](https://github.com/NVIDIA-NeMo/labs-Voice-Agent) and the `setup.sh` in this folder.

### How do I update to a newer version?

The source, image and models are pinned to the versions in "Current versions" above. To move to a newer release, deploy a new instance after this Launchable is updated, or edit the pins in `setup.sh` on your own copy and test the result before relying on it.

## Acceptable use and safety

The agent can make mistakes; check its answers. Record other people only with their consent. Follow each model licence below.

## Guides and related Launchables

- Step-by-step guide: [Build a NeMo voice agent on Nemotron](https://www.9owls.com/guides/build-a-nemo-voice-agent-on-nemotron/)
- New to Launchables: [Deploy a Launchable on NVIDIA Brev](https://www.9owls.com/guides/deploy-a-launchable-on-nvidia-brev/)
- Other agents: [NVIDIA Brev agent Launchables](https://www.9owls.com/guides/nvidia-brev-agent-launchables/)
- Instance lifecycle: [Stop, start and delete an NVIDIA Brev instance](https://www.9owls.com/guides/stop-start-and-delete-an-nvidia-brev-instance/)
- This Launchable on 9owls: https://www.9owls.com/launchables/nemo-voice-agent-nemotron/
- All Launchables by 9owls: https://www.9owls.com/launchables/
- Related: [Pipecat Voice Agent with Nemotron Speech](https://www.9owls.com/launchables/pipecat-voice-agent-nemotron/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8b9S3MTLbdyBbCVcA9ZrJhGAJ)); [Voice Lab](https://www.9owls.com/launchables/voice-lab/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M7TTV4QXYErJeINLDl77bsMVyb)); [Nemotron Chat](https://www.9owls.com/launchables/nemotron-chat/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aArulP2ZTX7HwqGLf4pwRT6z))

## Keep your own stack running

NightKeeper packages your repository as an NVIDIA Brev Launchable, proves it on a fresh GPU and keeps it running. Your Brev API key stays in your repository's GitHub secrets. NightKeeper never sees it.

[Create your Launchable](https://www.9owls.com/nightkeeper/start/) or [read about NightKeeper](https://www.9owls.com/nightkeeper/).

## Credits and licences

- NVIDIA NeMo Voice Agent - https://github.com/NVIDIA-NeMo/labs-Voice-Agent - Apache License 2.0.
- Pipecat - BSD 2-Clause License. vLLM - Apache License 2.0. Caddy - Apache License 2.0. Node.js - MIT License. uv - Apache License 2.0 or MIT License.
- nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4 and nvidia/Nemotron-3-Diarization - OpenMDW License Agreement, version 1.1.
- nvidia/parakeet_realtime_eou_120m-v1 and nvidia/magpie_tts_multilingual_357m - Licensed by NVIDIA Corporation under the NVIDIA Open Model License.
- hexgrad/Kokoro-82M - Apache License 2.0.
- The files in this folder (README.md and setup.sh): Apache License 2.0; see [LICENSE](LICENSE).

Published and maintained by [9owls, Inc.](https://www.9owls.com/). Questions: hello@9owls.com.
