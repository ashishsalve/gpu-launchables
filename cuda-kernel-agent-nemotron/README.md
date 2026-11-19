# CUDA Kernel Engineer Agent on Nemotron

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3MJyaXnnzyUwmC2pfHx1ibrlg6C)

Launchable ID: env-3MJyaXnnzyUwmC2pfHx1ibrlg6C

Speed up slow PyTorch, NumPy or CUDA code with a third-party open-source coding agent (LangChain Deep Agents Code) running in an NVIDIA OpenShell sandbox. The agent writes CUDA, Triton or cuTile kernels, checks them with compute-sanitizer, profiles them with Nsight Compute and Nsight Systems, and benchmarks them on this GPU. The model, NVIDIA Nemotron 3.5 Lightning, is served by vLLM on the same GPU; no external model API is used.

1x L40S 48GB, >= 48 GB VRAM | 250 GiB disk | ~$2.26/hr (console 2026-11-19) | ~30 min to ready | Stop to pause, Delete when done

Minimum GPU: one NVIDIA L40S 48GB. You can pick other compute at deploy time. vLLM is configured with `--gpu-memory-utilization 0.55`, so it reserves 55 percent of GPU memory for the model and leaves the rest for kernel work in the sandbox.

## What you get

- **open-code-server** link (the main button): a browser VS Code (code-server) whose default terminal opens inside the sandbox with the agent ready. code-server itself runs on the instance, not in the sandbox: its editor and any new terminal profile give full access to the instance (host files, Docker and sudo). It is protected by the Brev Secure Link login and a password generated at setup; do not share the link or the password.
  code-server asks for a password: in the Brev terminal run `grep ^password ~/.config/code-server/config.yaml`.
- **open-kernel-report** link: the Kernel Report, a page listing each task run with baseline time, kernel time, measured speedup, test result, sanitizer result and Nsight Compute summary, with downloads.
  The report asks for a login: user report; in the Brev terminal run `cat ~/.config/kernel-report/password`.
- A sandbox with the CUDA toolkit (nvcc, compute-sanitizer), Nsight Compute, Nsight Systems, PyTorch, Triton, cuTile and CuPy, plus five pinned NVIDIA CUDA agent skills for cuTile and Triton kernel work.

## Try these three tasks

See [docs/tasks.md](docs/tasks.md). In short:

1. Fuse RMSNorm, scale and residual add into one kernel; match the eager reference within atol 1e-3 in fp16 and pass memcheck.
2. Fix a shared-memory reduction with two planted bugs; memcheck and racecheck must both report 0 errors.
3. Port a NumPy pairwise-distance function to the GPU; compare Nsight Systems traces before and after.

Speedups shown in the report are measured on your instance by the bench harness. The harness refuses to time while another process keeps the GPU busy.

## How it works

- vLLM serves the model as `coder` on localhost:8000 of the instance. The agent reaches it through NemoClaw's managed inference route, which OpenShell forwards to that local vLLM server; no external model API is used.
- NVIDIA NemoClaw installs OpenShell and onboards the agent into the `kernel-lab` sandbox with GPU access. Setup then applies the lab's own sandbox policy and stops if that policy is not the one loaded. Sandbox network egress is denied by default; the only allowed route is to the model.
- The sandbox reaches the model through a small nginx proxy that listens only on the Docker bridge address of the instance and forwards to vLLM on localhost; vLLM itself never listens on an external address.
- The sandbox is not given the host workspace or the host scripts; at most the results folder `/home/ubuntu/workspace/kernel-lab/results` is shared with it. Agent telemetry is turned off.
- code-server (13337) and the Kernel Report (3000) listen on all interfaces of the instance so that Brev Secure Links can connect to them; open them through the Secure Links. code-server requires its password. The Kernel Report also requires a login: user report, with the password in `~/.config/kernel-report/password`.

## Settings

| Parameter | Default | Meaning |
| --- | --- | --- |
| AGENT | deepagents-code | Coding agent run in the sandbox. |
| MODEL | nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4 | Model served by vLLM. |
| MAX_MODEL_LEN | 65536 | Context window: 65536, 32768 or 131072 tokens. |
| HF_TOKEN | none | Optional Hugging Face read token. Choose "Use a secret" to pick a saved secret, or paste a read token. |

## Use the model API from your machine

```
brev port-forward <instance-name> --port 8000:8000
curl http://localhost:8000/v1/models
```

## Data and persistence

Labs, results and the model cache live in `/home/ubuntu/workspace` (`/home/ubuntu/workspace/kernel-lab` and `/home/ubuntu/workspace/huggingface`). They survive Stop and are destroyed by Delete. Settings are kept in mode 600 files under `/etc/kernel-lab` so services return after a restart without re-entering parameters.

## Stop and delete

Stop pauses the instance; disk storage is still billed while stopped. Delete removes the instance and everything on it. After Start, if a link shows an error, run `sudo systemctl restart kernel-lab.service kernel-report.service code-server-lab.service` in the Brev terminal and wait a few minutes.

## Troubleshooting

- Setup log: `sudo cat /var/log/brev-workspace.log`
- Recover the sandbox: `sudo systemctl restart kernel-lab.service`
- More: [docs/troubleshooting.md](docs/troubleshooting.md)

## Acceptable use and safety

The agent runs code it writes. It is confined to the sandbox filesystem and network policy, but review generated kernels before using them elsewhere. Follow the licences and acceptable-use terms of the model and every project listed below.

Current versions: vLLM v0.27.1; Nemotron 3.5 Lightning 30B-A3B NVFP4 revision bee7596; CUDA 13.5.0 devel (Ubuntu 24.04); Nsight Compute and Nsight Systems 13.5.0; PyTorch 2.15.0 (cu132); Triton 3.9.0; cuTile 1.8.1; CuPy 14.2.0; code-server 4.145.2; NVIDIA skills e8f43c1.

Last smoke: not yet run.

## Credits and licences

- NVIDIA NemoClaw and OpenShell - Apache-2.0
- LangChain Deep Agents Code - MIT
- vLLM - Apache-2.0
- NVIDIA Nemotron 3.5 Lightning - OpenMDW-1.1
- NVIDIA skills - Apache-2.0 (code), CC-BY-4.0 (skills)
- NVIDIA TileGym - MIT
- PyTorch - BSD-3-Clause; Triton - MIT; CuPy - MIT; cuTile - Apache-2.0
- code-server - MIT
- This repository - Apache-2.0
