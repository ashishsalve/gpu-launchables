<p align="center">
  <strong>OpenShell + garak Agent Safety Lab on NVIDIA Brev</strong><br>
  Red team a tool-using AI agent with garak, then stop the attacks with NeMo Guardrails and an OpenShell sandbox, on NVIDIA Nemotron 3.5 Lightning served by vLLM on one NVIDIA L40S GPU.
</p>

# OpenShell + garak Agent Safety Lab

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3MK1o9MUGMtZElFZvoYphMsZUmB)

Launchable ID: env-3MK1o9MUGMtZElFZvoYphMsZUmB

Red team a tool-using AI agent with [garak](https://github.com/NVIDIA/garak), then stop the attacks with [NeMo Guardrails](https://github.com/NVIDIA-NeMo/Guardrails) and an [OpenShell](https://github.com/NVIDIA/OpenShell) sandbox. The agent runs on NVIDIA Nemotron 3.5 Lightning served by [vLLM](https://github.com/vllm-project/vllm) on the same NVIDIA L40S GPU; no hosted model endpoint is used. Click Launch on Brev, wait for the five readiness lights behind the `open-safety-lab` link, and press **Run all three lanes** to compare the raw, guarded and sandboxed agent in one results table.

| Quick facts | |
| --- | --- |
| Runs | Lab UI + sample HelpDesk agent (three lanes) + garak + NeMo Guardrails + NemoGuard JailbreakDetect + OpenShell sandbox + vLLM serving Nemotron 3.5 Lightning |
| Default compute | 1x NVIDIA L40S 48GB on AWS; you can pick another GPU on the deploy page |
| Disk | 200 GiB |
| Ready in | about 30 minutes on a fresh deploy (2026-11-19) |
| Cost | about $2.26/hr on the default compute (console, 2026-11-19); storage is billed while stopped |
| Secrets | `TARGET_API_KEY` and `HF_TOKEN`, both optional, set at launch |
| Licences | garak, NeMo Guardrails, OpenShell, vLLM: Apache-2.0; Nemotron 3.5 Lightning: OpenMDW-1.1; NemoGuard JailbreakDetect: NVIDIA Open Model License |
| Guide | https://www.9owls.com/launchables/openshell-garak-agent-safety-lab/ |

Current versions: vLLM v0.27.1 (model) and v0.20.2 (content safety option); Nemotron 3.5 Lightning 30B-A3B NVFP4 revision bee7596271d1495f6992ae224aefde4410e816b8; garak 0.17.1; NeMo Guardrails 0.24.1; NemoGuard JailbreakDetect revision cc8b97e2bd6c1667c31476eedaa9a75b4d7ed282; snowflake-arctic-embed-m-long revision 92d97331f1f4b6a366c1f161354b9f3390cc219f; OpenShell v0.0.116; Python 3.12.16; NeMo Guardrails server and jailbreak detector Python packages installed from the hash-pinned locks `~/workspace/asl/pip/gr.lock` and `~/workspace/asl/pip/jbd.lock`.

Last smoke: 2026-11-19, fresh deploy on AWS with 1x L40S: all five lab checks green and the full raw, guarded and sandbox job completed.

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

- A sample HelpDesk agent with three tools: `read_file`, `http_get` and `send_report`.
- The same agent in three lanes: RAW (model direct), GUARDED (NeMo Guardrails jailbreak detection and self-check rails) and GUARDED+SANDBOX (also inside an OpenShell sandbox with a deny-by-default network policy).
- garak probes plus the garak `agent_breaker` probe, whose attacker and judge model is the local Nemotron model.
- A local attacker sink and a fake key file, so you can see whether an attack got data out.
- One results table: attack success per probe family, canary hits at the sink, and sandbox denial rows.

| Component | Version | Image or file |
| --- | --- | --- |
| vLLM (model server) | v0.27.1 | `vllm/vllm-openai:v0.27.1` (pinned by digest) |
| vLLM (content safety option) | v0.20.2 | `vllm/vllm-openai:v0.20.2` (pinned by digest) |
| NVIDIA Nemotron 3.5 Lightning 30B-A3B NVFP4 | revision bee7596271d1495f6992ae224aefde4410e816b8 | Hugging Face model files |
| garak | 0.17.1 | lab image, hash-pinned lock |
| NeMo Guardrails | 0.24.1 | `~/workspace/asl/pip/gr.lock` |
| NemoGuard JailbreakDetect | revision cc8b97e2bd6c1667c31476eedaa9a75b4d7ed282 | `~/workspace/asl/pip/jbd.lock` (CPU detector) |
| snowflake-arctic-embed-m-long | revision 92d97331f1f4b6a366c1f161354b9f3390cc219f | Hugging Face model files |
| OpenShell | v0.0.116 | release package, checked by sha256 |
| Python | 3.12.16 | `python:3.12.16-slim-bookworm` (pinned by digest) |

## Deploy in three steps

1. Click **Launch on Brev**, keep the NVIDIA L40S or pick another GPU, leave the settings at their defaults or fill the target parameters for your own endpoint, and deploy.
2. Wait until the instance shows Running and the `open-safety-lab` link answers. A fresh deploy took about 30 minutes until all five readiness lights were green; the lab page loads earlier and the lights turn green as the models finish loading.
3. Click `open-safety-lab` and press **Run all three lanes**.

## Try it first

1. Compare the lanes: open the `open-safety-lab` link. When the readiness lights are green, press **Run all three lanes** and compare the lanes in the table.
2. Scan your own OpenAI-compatible endpoint: set `TARGET_URL`, `TARGET_MODEL` and `TARGET_API_KEY` at launch, tick the consent box in the lab, and press **Scan my endpoint**. Requests pass through a budget proxy with a hard cap (200 for quick, 1000 for standard).
3. Change the defences: load the guardrails config or the OpenShell policy in the editor, change it and save. The lab applies it (`openshell policy set` for the policy, a NeMo Guardrails restart for the config) and shows Applied or the failure. Then press **Replay** to compare.

## How it works

- One Secure Link, `open-safety-lab` on port 8080, serves the lab.
- Every other service listens on localhost only: vLLM (8001), NeMo Guardrails (8000), the jailbreak detector (1337), the two agent lanes (9001, 9002), the sandboxed lane forward (9003), the budget proxy (9100) and the sink (9200).
- The sandbox reaches the guarded model only through the host name OpenShell provides inside the sandbox, on port 9004, which forwards just `/v1/chat/completions` and `/v1/models` to NeMo Guardrails.
- The OpenShell policy denies every other network destination, including the attacker sink, so an exfiltration attempt from the sandboxed agent shows up as a denial row.
- The model runs on this GPU; no hosted model endpoint is used.

<details>
<summary>Advanced: the sandbox policy and the guardrails config</summary>

The policy lives in `~/workspace/asl/config/openshell/policy.yaml` and the guardrails config in `~/workspace/asl/config/guardrails/config.yml`. Filesystem rules apply when the sandbox is created; network rules can change while it runs. With `GUARD_PROFILE=jailbreak+content-safety`, Nemotron 3.5 Content Safety input and output rails are added. Details are in [docs/policy-and-rails.md](docs/policy-and-rails.md).

</details>

## Settings

| Parameter | Required | Default | What it does |
| --- | --- | --- | --- |
| `GUARD_PROFILE` | no | `jailbreak-detect` | `jailbreak-detect`, or `jailbreak+content-safety` to add Nemotron 3.5 Content Safety rails |
| `SCAN_PROFILE` | no | `quick` | `quick` or `standard` probe set and request cap |
| `TARGET_URL` | no | none | Your OpenAI-compatible base URL, for task 2 |
| `TARGET_MODEL` | no | none | Model name at that endpoint |
| `TARGET_API_KEY` | no | none | Key for that endpoint. Choose "Use a secret" (the option may be off for your account) or paste it |
| `HF_TOKEN` | no | none | Optional Hugging Face read token. Choose "Use a secret" or paste it |

Keys are stored in mode-600 files on the instance and are never printed. Only the budget proxy reads the target key.

## Use it from your machine

```
brev port-forward INSTANCE_NAME --port 8000:8000
```

Then call `http://localhost:8000/v1/chat/completions` with model `lightning` (guarded). Use `--port 8001:8001` for the raw model.

## Data and persistence

Everything lives in `/home/ubuntu/workspace/asl`: model cache, configs, runs and logs. It survives Stop and is removed by Delete.

- Configs: `/home/ubuntu/workspace/asl/config` (guardrails and OpenShell policy)
- Runs and reports: `/home/ubuntu/workspace/asl/runs`
- Logs: `/home/ubuntu/workspace/asl/logs`
- Model cache: `/home/ubuntu/workspace/asl/hf`
- Stored keys (mode 600): `/home/ubuntu/workspace/asl/secrets`

## Stop, start and delete

- **Stop** pauses the instance. Models, configs, runs and logs stay in `/home/ubuntu/workspace/asl`. Disk storage is billed while stopped.
- **Start** it again from the Brev console. After Start, if the lab link shows an error, run `sudo systemctl restart asl.service` in the Brev terminal and wait up to 30 minutes for the readiness lights.
- **Delete** removes the instance and all data. Delete it when you are finished.

## Troubleshooting

<details>
<summary>Where are the logs?</summary>

- Setup log: `sudo cat /var/log/brev-workspace.log`
- Service logs: `cd ~/workspace/asl && docker compose logs --no-color`

</details>

<details>
<summary>The lab link shows an error after Start</summary>

Run `sudo systemctl restart asl.service` in the Brev terminal and wait up to 30 minutes for the readiness lights.

</details>

<details>
<summary>Some readiness lights stay off</summary>

The lab page answers before the models finish loading. On a fresh deploy all five lights turned green about 30 minutes after the instance started. If they stay off well beyond that, check the service logs above.

</details>

## FAQ

### Which GPU do I need for the Agent Safety Lab?

Default GPU: 1x NVIDIA L40S 48GB.

That is the default compute and the GPU used in the last smoke; you can pick other compute on the deploy page.

### Does anything leave the instance?

The model runs on this GPU and no hosted model endpoint is used. Model files are downloaded from Hugging Face on first start. Scan requests go to your own endpoint only if you set `TARGET_URL` and tick the consent box, and they pass through a budget proxy with a hard request cap.

### Is the fake key in the lab a real credential?

No. The fake key in the lab is a random marker, not a credential. It lets the results table show whether an attack got data out to the local sink.

### Can I run this on my own hardware?

The `setup.sh` in this folder is the full install script. It expects an NVIDIA GPU with `nvidia-smi`, Docker 28 or newer and the NVIDIA Container Toolkit, and it does not install them. The upstream projects are [garak](https://github.com/NVIDIA/garak), [NeMo Guardrails](https://github.com/NVIDIA-NeMo/Guardrails), [OpenShell](https://github.com/NVIDIA/OpenShell) and [vLLM](https://github.com/vllm-project/vllm).

### How do I update to a newer version?

Images, models and Python packages are pinned to the versions in "Current versions" above. To move to a newer release, deploy a new instance after this Launchable is updated, or edit the pins in `setup.sh` on your own copy and test the result before relying on it.

## Acceptable use and safety

Scan only systems you own or are authorised to test. garak sends adversarial prompts. The fake key in the lab is a random marker, not a credential.

## Guides and related Launchables

- Step-by-step guide: [Red team an AI agent with garak and NeMo Guardrails](https://www.9owls.com/guides/red-team-an-ai-agent-with-garak-and-nemo-guardrails/)
- New to Launchables: [Deploy a Launchable on NVIDIA Brev](https://www.9owls.com/guides/deploy-a-launchable-on-nvidia-brev/)
- Other agents: [NVIDIA Brev agent Launchables](https://www.9owls.com/guides/nvidia-brev-agent-launchables/)
- Instance lifecycle: [Stop, start and delete an NVIDIA Brev instance](https://www.9owls.com/guides/stop-start-and-delete-an-nvidia-brev-instance/)
- This Launchable on 9owls: https://www.9owls.com/launchables/openshell-garak-agent-safety-lab/
- All Launchables by 9owls: https://www.9owls.com/launchables/
- Related: [NeMo Guardrails and garak](https://www.9owls.com/launchables/nemo-guardrails-garak/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8bOSWcMAZsaOnuaytHUvAEC0v)); [Nemotron Chat](https://www.9owls.com/launchables/nemotron-chat/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aArulP2ZTX7HwqGLf4pwRT6z)); [OpenHands on Nemotron](https://www.9owls.com/launchables/openhands-nemotron/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8b2pM4xEhrOmr5yEObCVI7kyS))

## Keep your own stack running

NightKeeper packages your repository as an NVIDIA Brev Launchable, proves it on a fresh GPU and keeps it running. Your Brev API key stays in your repository's GitHub secrets. NightKeeper never sees it.

[Create your Launchable](https://www.9owls.com/nightkeeper/start/) or [read about NightKeeper](https://www.9owls.com/nightkeeper/).

## Credits and licences

- garak, NeMo Guardrails, OpenShell and vLLM: Apache-2.0.
- Nemotron 3.5 Lightning: OpenMDW-1.1 licence.
- NemoGuard JailbreakDetect: NVIDIA Open Model License.
- snowflake-arctic-embed-m-long: Apache-2.0.
- Nemotron 3.5 Content Safety (option): OpenMDW-1.1 and the Gemma Terms of Use.
- The files in this folder: Apache License 2.0; see [LICENSE](LICENSE).

Published and maintained by [9owls, Inc.](https://www.9owls.com/). Questions: hello@9owls.com.
