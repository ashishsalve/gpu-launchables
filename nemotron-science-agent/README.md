# Nemotron Science Agent (GROMACS, RDKit)

A local science agent on one GPU. [Hermes Agent](https://github.com/NousResearch/hermes-agent) drives [GROMACS](https://www.gromacs.org) molecular dynamics and [RDKit](https://github.com/rdkit/rdkit) cheminformatics through a fixed set of tools, using [NVIDIA Nemotron 3.5 Super VL](https://huggingface.co/nvidia/NVIDIA-Nemotron-3.5-Super-VL-120B-A12B-NVFP4) served by [vLLM](https://github.com/vllm-project/vllm) on your instance. [Open WebUI](https://github.com/open-webui/open-webui) is the chat interface. Everything starts together with Docker Compose.

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3MJzeo3flqm6QKSzSPh2NZEdvYR)

Launchable ID: env-3MJzeo3flqm6QKSzSPh2NZEdvYR

1x RTX PRO 6000 96GB, >= 90 GB VRAM | 300 GiB disk | ~$4.80/hr (console 2026-11-15) | ~45 min to ready | Stop to pause, Delete when done

Current versions: vllm/vllm-openai:v0.32.0, ghcr.io/open-webui/open-webui:v0.13.3, Hermes Agent v0.23.2, GROMACS 2026.4, RDKit 2026.9.2, model nvidia/NVIDIA-Nemotron-3.5-Super-VL-120B-A12B-NVFP4

Last smoke: not yet run.

## What you get

- A chat page (the **science-agent** link) where the agent works on GROMACS setups and computes RDKit descriptors. The model accepts images, so the setup is designed to also read reaction-scheme images.
- Five broken GROMACS input sets for hen egg-white lysozyme (PDB 1AKI), prepared when the image was built, each with a reference fix and a checker.
- A 50-question chemistry check from LitmusBench v0.2, run against the local model with a fixed seed.

## Minimum GPU

The default configuration is set up for one RTX PRO 6000 with 96 GB of GPU memory: vLLM is configured to use 86 percent of GPU memory, and the GROMACS runs share the same GPU. If you pick a different instance type on the deploy page, choose one with the same GPU memory.

## Try these three tasks

See [docs/tasks.md](docs/tasks.md) for the exact prompts.

1. **Repair the GROMACS suite.** Ask the agent to repair all five cases. For each one the agent is asked to read the inputs, fix them, and run `gmx grompp` and a 10 ps GPU `gmx mdrun`.
2. **Rank molecules with RDKit.** Give five SMILES strings and ask for a ranking by drug-likeness; then ask it to run the LitmusBench check.
3. **Read a reaction scheme.** Upload an image of a reaction scheme and ask for the reactants and products as SMILES in JSON. The agent is designed to check each SMILES with the validation tool.

## How it works

- One Secure Link, **science-agent** (port 8080), opens Open WebUI. Create the first account right away: it becomes the admin.
- Open WebUI talks to Hermes Agent on an internal network. Hermes uses the local model and the science tools only: its configuration allows just the science tool server and switches off every built-in Hermes toolset, including terminal, file, web and browser. The science tools accept calls only with an access token generated on the instance at first start.
- The science tools run in their own container with no internet access, a read-only file system and no extra privileges. The tools are fixed: list and reset cases, read and write input files, grompp, mdrun (at most 5000 steps), solvate and neutralise, RDKit descriptors, SMILES validation and the LitmusBench check. There is no shell tool.
- vLLM listens only on the instance itself (localhost port 8000).
- Only the model weights, the benchmark file and the container images are downloaded. On first start the model weights (about 66 GB) are downloaded before the model loads.

## Settings

| Parameter | Type | Default | Meaning |
| --- | --- | --- | --- |
| `MODEL` | Choice | `super-vl` | NVIDIA Nemotron 3.5 Super VL (NVFP4). |
| `MAX_MODEL_LEN` | Choice | `65536` | Context window in tokens: `65536` or `32768`. |
| `HF_TOKEN` | Text | none | Optional Hugging Face read token for downloads. Choose "Use a secret" and pick your saved Hugging Face secret (the option may be off for your account), or paste a read token, or leave empty. |

The agent's API key and the science tools' access token are generated on the instance at first start and stored in files readable only by the services; neither is a launch parameter.

## Use the model API from your machine

```
brev port-forward INSTANCE_NAME --port 8000:8000
curl http://localhost:8000/v1/models
```

The model is served under the name `nemotron-3.5-super-vl`.

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

## Stop and delete

- **Stop** the instance when you are not using it. Data is kept and the containers come back on the next start. Storage is still billed while stopped.
- **Delete** the instance when you are finished. This removes the instance and all data.

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md). The deploy log is at `sudo cat /var/log/brev-workspace.log`. If the services are not back after a start, open a terminal on the instance and run:

```
cd /home/ubuntu/workspace && sudo docker compose up -d
```

## Acceptable use and safety

The agent is configured to use only the fixed science tools listed above, which work inside its own folder with step and time limits. Simulation and chemistry results are for research and teaching; check them before relying on them. Follow the licences of the model, the dataset and each tool.

## Credits and licences

See [docs/attributions.md](docs/attributions.md) and `LICENSE`.
