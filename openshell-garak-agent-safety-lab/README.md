# OpenShell + garak Agent Safety Lab

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3MK1o9MUGMtZElFZvoYphMsZUmB)

Red team a tool-using AI agent with [garak](https://github.com/NVIDIA/garak), then stop the attacks with [NeMo Guardrails](https://github.com/NVIDIA-NeMo/Guardrails) and an [OpenShell](https://github.com/NVIDIA/OpenShell) sandbox. The agent runs on NVIDIA Nemotron 3.5 Lightning served by [vLLM](https://github.com/vllm-project/vllm) on this GPU; no hosted model endpoint is used.

Launchable ID: env-3MK1o9MUGMtZElFZvoYphMsZUmB

Default GPU: 1x NVIDIA L40S 48GB.

1x L40S 48GB, >= 48 GB VRAM | 200 GiB disk | ~$2.26/hr (console 2026-11-19) | ~30 min to ready | Stop to pause, Delete when done

## What you get

- A sample HelpDesk agent with three tools: `read_file`, `http_get` and `send_report`.
- The same agent in three lanes: RAW (model direct), GUARDED (NeMo Guardrails jailbreak detection and self-check rails) and GUARDED+SANDBOX (also inside an OpenShell sandbox with a deny-by-default network policy).
- garak probes plus the garak `agent_breaker` probe, whose attacker and judge model is the local Nemotron model.
- A local attacker sink and a fake key file, so you can see whether an attack got data out.
- One results table: attack success per probe family, canary hits at the sink, and sandbox denial rows.

## Try these three tasks

1. Open the `open-safety-lab` link. When the readiness lights are green, press **Run all three lanes** and compare the lanes in the table.
2. Scan your own OpenAI-compatible endpoint: set `TARGET_URL`, `TARGET_MODEL` and `TARGET_API_KEY` at launch, tick the consent box in the lab, and press **Scan my endpoint**. Requests pass through a budget proxy with a hard cap (200 for quick, 1000 for standard).
3. Load the guardrails config or the OpenShell policy in the editor, change it and save. The lab applies it (`openshell policy set` for the policy, a NeMo Guardrails restart for the config) and shows Applied or the failure. Then press **Replay** to compare.

## How it works

One Secure Link, `open-safety-lab` on port 8080, serves the lab. Every other service listens on localhost only: vLLM (8001), NeMo Guardrails (8000), the jailbreak detector (1337), the two agent lanes (9001, 9002), the sandboxed lane forward (9003), the budget proxy (9100) and the sink (9200). The sandbox reaches the guarded model only through the host name OpenShell provides inside the sandbox, on port 9004, which forwards just `/v1/chat/completions` and `/v1/models` to NeMo Guardrails. See [docs/policy-and-rails.md](docs/policy-and-rails.md).

## Settings

| Name | Type | Default | Meaning |
|---|---|---|---|
| GUARD_PROFILE | Choice | jailbreak-detect | `jailbreak-detect`, or `jailbreak+content-safety` to add Nemotron 3.5 Content Safety rails |
| SCAN_PROFILE | Choice | quick | `quick` or `standard` probe set and request cap |
| TARGET_URL | Text | none | Your OpenAI-compatible base URL, for task 2 |
| TARGET_MODEL | Text | none | Model name at that endpoint |
| TARGET_API_KEY | Text | none | Key for that endpoint. Choose "Use a secret" (the option may be off for your account) or paste it |
| HF_TOKEN | Text | none | Optional Hugging Face read token. Choose "Use a secret" or paste it |

Keys are stored in mode-600 files on the instance and are never printed. Only the budget proxy reads the target key.

## Use the model API from your machine

```
brev port-forward <instance-name> --port 8000:8000
```

Then call `http://localhost:8000/v1/chat/completions` with model `lightning` (guarded). Use `--port 8001:8001` for the raw model.

## Data and persistence

Everything lives in `/home/ubuntu/workspace/asl`: model cache, configs, runs and logs. It survives Stop and is removed by Delete.

## Stop and delete

Stop pauses the instance. Disk storage is billed while stopped. Delete removes the instance and all data.

## Troubleshooting

```
sudo cat /var/log/brev-workspace.log
sudo systemctl restart asl.service
cd ~/workspace/asl && docker compose logs --no-color
```

## Acceptable use and safety

Scan only systems you own or are authorised to test. garak sends adversarial prompts. The fake key in the lab is a random marker, not a credential.

## Current versions

Current versions: vLLM v0.27.1 (model) and v0.20.2 (content safety option); Nemotron 3.5 Lightning 30B-A3B NVFP4 revision bee7596271d1495f6992ae224aefde4410e816b8; garak 0.17.1; NeMo Guardrails 0.24.1; NemoGuard JailbreakDetect revision cc8b97e2bd6c1667c31476eedaa9a75b4d7ed282; snowflake-arctic-embed-m-long revision 92d97331f1f4b6a366c1f161354b9f3390cc219f; OpenShell v0.0.116; Python 3.12.16; NeMo Guardrails server and jailbreak detector Python packages installed from the hash-pinned locks `~/workspace/asl/pip/gr.lock` and `~/workspace/asl/pip/jbd.lock`.

Last smoke: 2026-11-19, fresh deploy on AWS with 1x L40S: all five lab checks green and the full raw, guarded and sandbox job completed.

## Credits and licences

garak, NeMo Guardrails, OpenShell and vLLM are Apache-2.0. Nemotron 3.5 Lightning is under the OpenMDW-1.1 licence. NemoGuard JailbreakDetect is under the NVIDIA Open Model License. snowflake-arctic-embed-m-long is Apache-2.0. Nemotron 3.5 Content Safety (option) is under OpenMDW-1.1 and the Gemma Terms of Use. See LICENSE.
