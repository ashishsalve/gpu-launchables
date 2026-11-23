<p align="center">
  <strong>Nemotron Science Agent on NVIDIA Brev</strong><br>
  Hermes Agent drives GROMACS molecular dynamics and RDKit cheminformatics with NVIDIA Nemotron 3.5 Super VL on vLLM, on one NVIDIA RTX PRO 6000 GPU.
</p>

# Nemotron Science Agent (GROMACS, RDKit)

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3MJzeo3flqm6QKSzSPh2NZEdvYR)

Launchable ID: env-3MJzeo3flqm6QKSzSPh2NZEdvYR

1x RTX PRO 6000 96GB, >= 92 GB VRAM | 300 GiB disk | ~$4.85/hr (console 2026-11-19) | ~35 min to ready | Stop to pause, Delete when done

A local science agent on one GPU. [Hermes Agent](https://github.com/NousResearch/hermes-agent) drives [GROMACS](https://www.gromacs.org) molecular dynamics and [RDKit](https://github.com/rdkit/rdkit) cheminformatics through a fixed set of tools, using [NVIDIA Nemotron 3.5 Super VL](https://huggingface.co/nvidia/NVIDIA-Nemotron-3.5-Super-VL-120B-A12B-NVFP4) served by [vLLM](https://github.com/vllm-project/vllm) on your instance, with [Open WebUI](https://github.com/open-webui/open-webui) as the chat interface. Everything starts together with Docker Compose on one NVIDIA RTX PRO 6000 96GB. Click Launch on Brev, open the `science-agent` link when it answers, and ask the agent to repair five broken GROMACS setups or rank molecules with RDKit.

| Quick facts | |
| --- | --- |
| Runs | Open WebUI + Hermes Agent + science tools (GROMACS, RDKit) + vLLM serving NVIDIA Nemotron 3.5 Super VL (NVFP4) |
| Default compute | 1x NVIDIA RTX PRO 6000 96GB on AWS; you can pick another GPU on the deploy page if it has the same GPU memory |
| Disk | 300 GiB |
| Ready in | about 35 minutes on a fresh deploy (2026-11-19), most of it downloading the model weights |
| Cost | about $4.85/hr on the default compute including 300 GiB storage (console, 2026-11-19); storage is billed while stopped |
| Secrets | `HF_TOKEN` (optional Hugging Face read token, set at launch) |
| Licences | GROMACS: LGPL 2.1; FFTW: GPL 2; RDKit: BSD 3-Clause; Hermes Agent: MIT; vLLM: Apache 2.0; Open WebUI: Open WebUI License; Nemotron 3.5 Super VL: OpenMDW 1.1 |
| Guide | https://www.9owls.com/launchables/nemotron-science-agent/ |

Current versions: vllm/vllm-openai:v0.32.0, ghcr.io/open-webui/open-webui:v0.13.3, Hermes Agent v0.23.2, GROMACS 2026.4, RDKit 2026.9.2, model nvidia/NVIDIA-Nemotron-3.5-Super-VL-120B-A12B-NVFP4

Last smoke: 2026-11-19, fresh deploy on the default instance (all services healthy about 29 minutes after deploy).

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
| vLLM (OpenAI-compatible model server) | v0.32.0 (pinned by digest) | `vllm/vllm-openai:v0.32.0` |
| Open WebUI (chat page) | v0.13.3 (pinned by digest) | `ghcr.io/open-webui/open-webui:v0.13.3` |
| Hermes Agent (Nous Research) | v0.23.2 | agent image built on `nousresearch/hermes-agent:v0.23.2`, pinned by digest in `compose.yaml` |
| GROMACS | 2026.4 | science tools image, pinned by digest in `compose.yaml` |
| RDKit | 2026.9.2 | science tools image, pinned by digest in `compose.yaml` |
| NVIDIA Nemotron 3.5 Super VL (NVFP4) | fixed Hugging Face revision | `nvidia/NVIDIA-Nemotron-3.5-Super-VL-120B-A12B-NVFP4` |

On the chat page you also get:

- A chat page (the **science-agent** link) where the agent works on GROMACS setups and computes RDKit descriptors. The model accepts images, so the setup is designed to also read reaction-scheme images.
- Five broken GROMACS input sets for hen egg-white lysozyme (PDB 1AKI), prepared when the image was built, each with a reference fix and a checker.
- A 50-question chemistry check from LitmusBench v0.2, run against the local model with a fixed seed.

## Deploy in three steps

1. Click **Launch on Brev**, keep the NVIDIA RTX PRO 6000 96GB (or pick another instance type with the same GPU memory), optionally set `HF_TOKEN`, and deploy.
2. Wait until the instance shows Running and the `science-agent` link answers. A fresh deploy took about 29 to 35 minutes, most of it downloading the model weights (about 66 GB) and loading them.
3. Click `science-agent` and create the first account right away: it becomes the admin. Then start a chat with the agent.

## Try it first

Run one long task at a time. If a tool reports it is paused, wait about a minute and retry: after a few failed tool calls the agent pauses the science tools for about a minute, for every open chat. The exact prompts are in [docs/tasks.md](docs/tasks.md).

1. **Repair the GROMACS suite.** Ask the agent to repair all five cases. For each one the agent is asked to read the inputs, fix them, and run `gmx grompp` and a 10 ps GPU `gmx mdrun`.
2. **Rank molecules with RDKit.** Give five SMILES strings and ask for a ranking by drug-likeness; then ask it to run the LitmusBench check.
3. **Read a reaction scheme.** Upload an image of a reaction scheme and ask for the reactants and products as SMILES in JSON. The agent is designed to check each SMILES with the validation tool.

To check a repaired GROMACS case yourself, open a terminal on the instance and run the case checker, as shown in [docs/tasks.md](docs/tasks.md):

```
cd /home/ubuntu/workspace && sudo docker compose exec science-tools python3 /opt/science/cases/C1/check.py /work/SESSION/C1
```

`SESSION` is the folder name under `/home/ubuntu/workspace/science-agent/work`.

## How it works

- One Secure Link, **science-agent** (port 8080), opens Open WebUI. Create the first account right away: it becomes the admin.
- Open WebUI talks to Hermes Agent on an internal network. Hermes uses the local model and the science tools only: its configuration allows just the science tool server and switches off every built-in Hermes toolset, including terminal, file, web and browser. The science tools accept calls only with an access token generated on the instance at first start.
- The science tools run in their own container with no internet access, a read-only file system and no extra privileges. The tools are fixed: list and reset cases, read and write input files, grompp, mdrun (at most 5000 steps), solvate and neutralise, RDKit descriptors, SMILES validation and the LitmusBench check. There is no shell tool.
- vLLM listens only on the instance itself (localhost port 8000).
- Only the model weights, the benchmark file and the container images are downloaded. On first start the model weights (about 66 GB) are downloaded before the model loads.

<details>
<summary>Advanced: GPU memory</summary>

The default configuration is set up for one RTX PRO 6000 with 96 GB of GPU memory: vLLM is configured to use 86 percent of GPU memory, and the GROMACS runs share the same GPU. Only one mdrun runs at a time, at most 5000 steps, with a 600 second limit; the model keeps most of the GPU memory and mdrun uses the rest. If you pick a different instance type on the deploy page, choose one with the same GPU memory.

</details>

## Settings

| Parameter | Type | Required | Default | What it does |
| --- | --- | --- | --- | --- |
| `MODEL` | Choice | no | `super-vl` | NVIDIA Nemotron 3.5 Super VL (NVFP4). |
| `MAX_MODEL_LEN` | Choice | no | `65536` | Context window in tokens: `65536` or `32768`. |
| `HF_TOKEN` | Text | no | none | Optional Hugging Face read token for downloads. Choose "Use a secret" and pick your saved Hugging Face secret (the option may be off for your account), or paste a read token, or leave empty. |

The agent's API key and the science tools' access token are generated on the instance at first start and stored in files readable only by the services; neither is a launch parameter.

## Use it from your machine

```
brev port-forward INSTANCE_NAME --port 8000:8000
curl http://localhost:8000/v1/models
```

The vLLM OpenAI-compatible API then answers on `http://localhost:8000/v1`, with the model served under the name `nemotron-3.5-super-vl`.

## Data and persistence

Everything lives under `/home/ubuntu/workspace/science-agent` on the instance:

- `huggingface` - model cache
- `open-webui` - chats, users and settings
- `hermes` - agent settings
- `work` - your case folders, one per agent session
- `data` - the LitmusBench file
- `evals` - benchmark results (item ids and scores only)
- `keys` - the agent API key and the science tools access token

This folder survives a stop and start. It is removed when the instance is deleted.

## Stop, start and delete

- **Stop** the instance from the Brev console when you are not using it. Data is kept and the containers come back on the next start. Storage is still billed while stopped.
- **Start** it again from the Brev console. After **Start**, the model takes about 15 minutes to load; the other services are back in about 2 minutes. The weights are not downloaded again. If the services are not back, run `cd /home/ubuntu/workspace && sudo docker compose up -d`.
- **Delete** the instance when you are finished. This removes the instance and all data.

## Troubleshooting

More cases are in [docs/troubleshooting.md](docs/troubleshooting.md).

<details>
<summary>Where are the logs?</summary>

- Deploy log: `sudo cat /var/log/brev-workspace.log`
- Model server log: `cd /home/ubuntu/workspace && sudo docker compose logs --tail 50 vllm`
- Agent log: `cd /home/ubuntu/workspace && sudo docker compose logs --tail 50 hermes`

</details>

<details>
<summary>The chat page opens but no model is listed</summary>

The model is still loading. First start downloads the weights (about 66 GB) and then loads them; the health check allows up to 45 minutes for this. Check progress with `cd /home/ubuntu/workspace && sudo docker compose logs --tail 50 vllm`.

</details>

<details>
<summary>A tool reports it is paused</summary>

After a few failed tool calls, the agent pauses the science tools for about a minute, and the pause applies to every open chat. Wait about a minute and retry. Run one long task at a time.

</details>

<details>
<summary>The agent does not answer</summary>

Run `cd /home/ubuntu/workspace && sudo docker compose ps` and check the hermes log. Hermes waits for the init service to create its folder and API key file. If `init` exited with an error, run it again with `cd /home/ubuntu/workspace && sudo docker compose up init`.

</details>

<details>
<summary>Services are not back after a start</summary>

Run `cd /home/ubuntu/workspace && sudo docker compose up -d`.

</details>

## FAQ

### Which GPU do I need for the Nemotron Science Agent?

One NVIDIA RTX PRO 6000 with 96 GB of GPU memory; that is the default compute and the GPU used in the last smoke. vLLM uses 86 percent of GPU memory and GROMACS shares the rest, so choose another instance type only if it has the same GPU memory.

### Is the model local, or does the agent call a hosted API?

The model is local. vLLM serves Nemotron 3.5 Super VL on the same instance and listens only on the instance itself. No hosted model API key is needed; the optional `HF_TOKEN` is only for downloads.

### Does anything leave the instance?

Only the model weights, the benchmark file and the container images are downloaded. The science tools container has no internet access, and Hermes has no terminal, file, web or browser tool. Benchmark results store question ids and scores only.

### What can the agent do?

It works only through the fixed science tools: list and reset GROMACS cases, read and write their input files, run grompp, mdrun (at most 5000 steps) and solvate and neutralise, compute RDKit descriptors, validate SMILES and run the LitmusBench check. Start with the three tasks in [Try it first](#try-it-first), and check its results before relying on them.

### Where does my data live?

Under `/home/ubuntu/workspace/science-agent` on the instance: the model cache, chats, agent settings, case folders, benchmark results and keys. It survives Stop and is removed by Delete.

### Can I run this on my own hardware?

The parts are open source: see [Hermes Agent](https://github.com/NousResearch/hermes-agent), [GROMACS](https://www.gromacs.org), [RDKit](https://github.com/rdkit/rdkit), [vLLM](https://github.com/vllm-project/vllm) and [Open WebUI](https://github.com/open-webui/open-webui), and the `compose.yaml` in this folder. You need a GPU with the same memory as the default compute.

### How do I update to a newer version?

The images and the model are pinned to the versions in "Current versions" above. To move to a newer release, deploy a new instance after this Launchable is updated, or edit the pins in `compose.yaml` on your own copy and test the result before relying on it.

## Acceptable use and safety

The agent is configured to use only the fixed science tools listed above, which work inside its own folder with step and time limits. Simulation and chemistry results are for research and teaching; check them before relying on them. Follow the licences of the model, the dataset and each tool.

## Guides and related Launchables

- Step-by-step guide: [Run a science agent on Nemotron with GROMACS and RDKit](https://www.9owls.com/guides/run-a-science-agent-on-nemotron-with-gromacs-and-rdkit/)
- Model server: [Serve NVIDIA Nemotron with vLLM](https://www.9owls.com/guides/serve-nvidia-nemotron-with-vllm/)
- New to Launchables: [Deploy a Launchable on NVIDIA Brev](https://www.9owls.com/guides/deploy-a-launchable-on-nvidia-brev/)
- Other agents: [NVIDIA Brev agent Launchables](https://www.9owls.com/guides/nvidia-brev-agent-launchables/)
- Instance lifecycle: [Stop, start and delete an NVIDIA Brev instance](https://www.9owls.com/guides/stop-start-and-delete-an-nvidia-brev-instance/)
- This Launchable on 9owls: https://www.9owls.com/launchables/nemotron-science-agent/
- All Launchables by 9owls: https://www.9owls.com/launchables/
- Related: [Nemotron Chat with Open WebUI and vLLM](https://www.9owls.com/launchables/nemotron-chat/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aArulP2ZTX7HwqGLf4pwRT6z)); [Isaac Lab + Newton Robot Learning](https://www.9owls.com/launchables/isaac-lab-newton/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8arIbDn5RySQJP1XtedUwZdFa)); [RAPIDS Data Science with cuDF and cuML](https://www.9owls.com/launchables/rapids-datascience/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aZ3FqwckUgj9tV7qQc9B3vVG))

## Keep your own stack running

NightKeeper packages your repository as an NVIDIA Brev Launchable, proves it on a fresh GPU and keeps it running. Your Brev API key stays in your repository's GitHub secrets. NightKeeper never sees it.

[Create your Launchable](https://www.9owls.com/nightkeeper/start/) or [read about NightKeeper](https://www.9owls.com/nightkeeper/).

## Credits and licences

- GROMACS 2026.4: GNU LGPL version 2.1. FFTW 3.3.10, built into GROMACS: GNU GPL version 2. The complete corresponding source for both ships inside the science tools image; see [docs/attributions.md](docs/attributions.md).
- RDKit: BSD 3-Clause.
- Hermes Agent, by Nous Research: MIT License.
- vLLM: Apache License 2.0.
- Open WebUI: Open WebUI License (BSD 3-Clause based, branding clause).
- NVIDIA Nemotron 3.5 Super VL (NVFP4): OpenMDW License Agreement 1.1 (see the model card). By deploying with this model you accept its terms.
- LitmusBench v0.2: CC BY-SA 4.0 for questions with ChEMBL data; OpenMDW 1.1 for all other questions. It is downloaded on your instance and not redistributed.
- The files in this folder: Apache License 2.0; see [LICENSE](LICENSE).

Published and maintained by [9owls, Inc.](https://www.9owls.com/). Questions: hello@9owls.com.
