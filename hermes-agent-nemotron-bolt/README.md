<p align="center">
  <strong>Hermes Agent on NVIDIA Brev</strong><br>
  Run the Hermes Agent from Nous Research on NVIDIA Nemotron 3.5 Bolt, served by llama.cpp on one NVIDIA L4 GPU, with no hosted model API key.
</p>

# Hermes Agent on Nemotron 3.5 Bolt

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3MJcLXd8Xhlag4dhPLll5pTHrJV)

Launchable ID: env-3MJcLXd8Xhlag4dhPLll5pTHrJV

[Hermes Agent](https://github.com/NousResearch/hermes-agent) is an open-source agent from Nous Research that browses the web, runs terminal commands and saves what it learns as reusable skills. This NVIDIA Brev Launchable runs it next to [NVIDIA Nemotron 3.5 Bolt](https://huggingface.co/nvidia/NVIDIA-Nemotron-3.5-Bolt-E4B-4GB), served on the same NVIDIA L4 instance by [llama.cpp](https://github.com/ggml-org/llama.cpp) through an OpenAI-compatible API, so the model runs locally and no hosted model API key is set. Set a dashboard password, click Launch on Brev, and about 18 minutes later open the `open-hermes` link and give the agent its first task.

| Quick facts | |
| --- | --- |
| Runs | Hermes Agent dashboard + llama.cpp server with CUDA + NVIDIA Nemotron 3.5 Bolt E4B (local model) |
| Default compute | 1x NVIDIA L4 24GB on GCP; you can pick another GPU on the deploy page |
| Disk | 256 GiB |
| Ready in | about 18 minutes on a fresh deploy (2026-11-19) |
| Cost | the deploy page shows the hourly price for the compute you pick; storage is billed while stopped |
| Secrets | `HERMES_DASHBOARD_BASIC_AUTH_PASSWORD` (dashboard password, set at launch) |
| Licences | Hermes Agent: MIT; llama.cpp: MIT; Nemotron 3.5 Bolt: OpenMDW 1.1 |
| Guide | https://www.9owls.com/launchables/hermes-agent-nemotron-bolt/ |

Current versions: Hermes Agent v0.23.2, llama.cpp b12464, NVIDIA-Nemotron-3.5-Bolt-E4B-4GB (default model), NVIDIA-Nemotron-3.5-Bolt-74B-A9B-24GB-GGUF (option)

Last smoke: 2026-11-19, fresh deploy on GCP g2-standard-8 (1x L4): ready in about 18 minutes; services came back on their own after Stop and Start

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
| Hermes Agent (Nous Research) | v0.23.2 (pinned by digest) | `nousresearch/hermes-agent:v0.23.2` |
| llama.cpp server with CUDA | b12464 (pinned by digest) | `ghcr.io/ggml-org/llama.cpp:server-cuda-b12464` |
| NVIDIA Nemotron 3.5 Bolt E4B | fixed Hugging Face revision | `Nemotron-3.5-Bolt-E4B-Q4_K_M.gguf` |

## Deploy in three steps

1. Click **Launch on Brev**, keep the NVIDIA L4 or pick another GPU, set `HERMES_DASHBOARD_BASIC_AUTH_PASSWORD` to a password of at least 12 characters, and deploy.
2. Wait until the instance shows Running and the `open-hermes` link answers. A fresh deploy took about 18 minutes, most of it pulling images and downloading the model.
3. Click `open-hermes`, sign in as user `hermes` with the password you set, and start a chat.

## Try it first

Open the dashboard, start a chat and paste each task. The full text, and how to check that the model runs locally, is in [docs/tasks.md](docs/tasks.md).

1. Browse: summarise the three newest llama.cpp releases with their tags and links.
2. Terminal: clone a small Python project at a release tag, install it in a virtual environment and run its tests.

Check the agent's answers against their sources, for example the llama.cpp releases page for the first task.

## How it works

- The Launchable defines one Brev Secure Link, `open-hermes`, for port 9119, the Hermes dashboard. The dashboard is configured with a user name and password: the user is `hermes` and the password is the one you set at launch.
- llama.cpp publishes its API on the instance loopback only (`127.0.0.1:8080`). Hermes is configured to reach it inside the stack as `http://llama:8080/v1`, with the model name `nemotron-bolt`.
- On first start the stack writes a Hermes configuration that points the agent at this local model; no hosted model API key is set.
- The Hermes terminal backend is set to `local`, so commands run inside the hermes container. The Docker socket is not mounted.
- Both services run under Docker Compose with the `unless-stopped` restart policy.

<details>
<summary>Advanced: the larger Nemotron 3.5 Bolt 74B model</summary>

Set `MODEL` to `74b` at launch to serve NVIDIA-Nemotron-3.5-Bolt-74B-A9B-24GB-GGUF instead of the E4B model. Its model server starts only on a GPU with at least 40000 MiB of memory, such as an NVIDIA L40S 48GB; on a smaller GPU, including the default NVIDIA L4, it logs a message and waits instead of starting. Pick the larger GPU on the deploy page. Details are in [docs/bolt-74b-on-l40s.md](docs/bolt-74b-on-l40s.md).

</details>

## Settings

| Parameter | Required | Default | What it does |
| --- | --- | --- | --- |
| `MODEL` | no | `e4b` | `e4b` serves Nemotron 3.5 Bolt E4B. `74b` serves the 74B model; its model server starts only on a GPU with at least 40000 MiB of memory. See [docs/bolt-74b-on-l40s.md](docs/bolt-74b-on-l40s.md). |
| `HERMES_DASHBOARD_BASIC_AUTH_PASSWORD` | yes | none | Dashboard password, at least 12 characters. Choose "Use a secret" and pick a saved secret, or paste a new password. |

<details>
<summary>How the dashboard password is stored</summary>

On first start the password is written to `/home/ubuntu/workspace/hermes-bolt/hermes/.launchable-auth/password` with mode 600. On later starts the stack reads the password from that file, not from the launch parameter. The dashboard does not start if that file is missing or empty, or if the password is shorter than 12 characters: the hermes service logs the reason, waits, and shows as unhealthy in `sudo docker compose ps`.

</details>

## Use it from your machine

```
brev port-forward INSTANCE_NAME --port 8080:8080
curl http://localhost:8080/v1/models
```

The llama.cpp OpenAI-compatible API then answers on `http://localhost:8080/v1` with the model name `nemotron-bolt`, so any OpenAI-compatible client on your machine can use the local Nemotron model.

## Data and persistence

- Models: `/home/ubuntu/workspace/hermes-bolt/models`
- Hermes data directory (`/opt/data` in the container) and the stored password: `/home/ubuntu/workspace/hermes-bolt/hermes`
- Files the agent creates in its home folder (`/opt/data/home` in the container), such as the project cloned in the terminal task: `/home/ubuntu/workspace/hermes-bolt/hermes/home`

These folders are under the Brev workspace directory, which Brev keeps when the instance is stopped and removes when the instance is deleted.

The model is downloaded on first start and checked by size, and the default model also by sha256. If a file of the expected size is already on disk, it is not downloaded again.

## Stop, start and delete

- **Stop** the instance from the Brev console when you are not using it. Models, the Hermes data, the stored password and the agent's files stay in the workspace folders above. Storage is still billed while the instance is stopped.
- **Start** it again from the Brev console. Both services use the `unless-stopped` restart policy and read their settings from the workspace folders above. In the last smoke, both services came back on their own after Start, without re-entering parameters or downloading the model again. If the dashboard does not answer, run `cd /home/ubuntu/workspace && sudo docker compose up -d`.
- **Delete** the instance when you are finished. This removes the instance and all of its data, including models and skills.

## Troubleshooting

<details>
<summary>Where are the logs?</summary>

- Setup log: `sudo cat /var/log/brev-workspace.log`
- Service logs: `cd /home/ubuntu/workspace && sudo docker compose logs --no-color llama hermes`

</details>

<details>
<summary>The dashboard does not answer after a start</summary>

Run `cd /home/ubuntu/workspace && sudo docker compose up -d`.

</details>

<details>
<summary>The agent does not answer yet</summary>

The agent answers only after the model has loaded. While the model file is fetched, the llama log shows a `llama: downloading` line.

</details>

<details>
<summary>The llama log says the model server will not start</summary>

The model download failed its check and was removed. Run `cd /home/ubuntu/workspace && sudo docker compose restart llama` to download it again. With `MODEL=74b`, also check that the GPU has at least 40000 MiB of memory.

</details>

<details>
<summary>hermes shows as unhealthy</summary>

Its log says why the dashboard did not start (no stored password, or one shorter than 12 characters). Deploy again with a valid `HERMES_DASHBOARD_BASIC_AUTH_PASSWORD`.

</details>

<details>
<summary>Signing in from a script</summary>

Sign in through the dashboard's login form in the browser. If you script the login, keep the request and response output private, because it can contain the password.

</details>

## FAQ

### Which GPU do I need for Hermes Agent with Nemotron 3.5 Bolt?

One NVIDIA L4 24GB runs the default Nemotron 3.5 Bolt E4B model; that is the default compute and the GPU used in the last smoke. The 74B option needs a GPU with at least 40000 MiB of memory, such as an NVIDIA L40S 48GB.

### Is the model local, or does Hermes call a hosted API?

The model is local. llama.cpp serves Nemotron 3.5 Bolt on the same GPU instance, Hermes talks to it inside the stack, and no hosted model API key is set. The agent itself still reaches the web when a task asks it to browse or clone.

### What can the agent do?

Hermes Agent browses the web, runs terminal commands inside its own container and can save what it learns as reusable skills. Start with the two tasks in [Try it first](#try-it-first), and check its answers against their sources.

### What does it cost to leave it running?

The deploy page shows the hourly price of the GPU you pick. A running instance is billed by the hour; Stop it when you are not using it, and Delete it when you are finished, because storage is still billed while it is stopped.

### Where does my data live?

Under `/home/ubuntu/workspace/hermes-bolt` on the instance: models, the Hermes data directory, the stored password and the files the agent creates. It survives Stop and is removed by Delete.

### Can I run this on my own hardware?

Yes. Hermes Agent, llama.cpp and the Nemotron 3.5 Bolt model files are open; see the [Hermes Agent repository](https://github.com/NousResearch/hermes-agent) and the `compose.yaml` in this folder.

### How do I update to a newer version?

The images and model are pinned to the versions in "Current versions" above. To move to a newer release, deploy a new instance after this Launchable is updated, or edit the pins in `compose.yaml` on your own copy and test the result before relying on it.

## Acceptable use and safety

Hermes executes the commands the model proposes, with network access, inside its container. Review what it does, keep the dashboard password private, and do not give the agent credentials you would not hand to a new colleague. Check the agent's answers against their sources. Use the model within the terms of its licence.

## Guides and related Launchables

- Step-by-step guide: [Run Hermes Agent on Nemotron 3.5 Bolt](https://www.9owls.com/guides/run-hermes-agent-on-nemotron-3-5-bolt/)
- New to Launchables: [Deploy a Launchable on NVIDIA Brev](https://www.9owls.com/guides/deploy-a-launchable-on-nvidia-brev/)
- Other agents: [NVIDIA Brev agent Launchables](https://www.9owls.com/guides/nvidia-brev-agent-launchables/) and [which agent Launchable to pick](https://www.9owls.com/guides/which-nvidia-brev-agent-launchable-to-pick/)
- GPU choice: [NVIDIA L4 vs L40S for LLM inference](https://www.9owls.com/compare/nvidia-l4-vs-l40s-for-llm-inference/)
- Instance lifecycle: [Stop, start and delete an NVIDIA Brev instance](https://www.9owls.com/guides/stop-start-and-delete-an-nvidia-brev-instance/)
- This Launchable on 9owls: https://www.9owls.com/launchables/hermes-agent-nemotron-bolt/
- All Launchables by 9owls: https://www.9owls.com/launchables/
- Related: [Ollama with Open WebUI](https://www.9owls.com/launchables/ollama-open-webui/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M6T0t4dhogSr5ruwzfHUvkBAVN)); [Nemotron Chat](https://www.9owls.com/launchables/nemotron-chat/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aArulP2ZTX7HwqGLf4pwRT6z)); [OpenHands on Nemotron](https://www.9owls.com/launchables/openhands-nemotron/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8b2pM4xEhrOmr5yEObCVI7kyS))

## Keep your own stack running

NightKeeper packages your repository as an NVIDIA Brev Launchable, proves it on a fresh GPU and keeps it running. Your Brev API key stays in your repository's GitHub secrets. NightKeeper never sees it.

[Create your Launchable](https://www.9owls.com/nightkeeper/start/) or [read about NightKeeper](https://www.9owls.com/nightkeeper/).

## Credits and licences

- Hermes Agent, by Nous Research: MIT License.
- llama.cpp: MIT License.
- NVIDIA Nemotron 3.5 Bolt E4B and 74B: OpenMDW License Agreement, version 1.1 (see each model card). The E4B model is built on Gemma 4 E4B, licensed under the Apache License 2.0. By deploying with these models you accept their terms.
- The files in this folder: Apache License 2.0; see [LICENSE](LICENSE).

Published and maintained by [9owls, Inc.](https://www.9owls.com/). Questions: hello@9owls.com.
