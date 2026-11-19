# Hermes Agent on Nemotron 3.5 Bolt

[Hermes Agent](https://github.com/NousResearch/hermes-agent) is an open-source agent from Nous Research that browses the web, runs terminal commands and saves what it learns as reusable skills. This Launchable runs it next to [NVIDIA Nemotron 3.5 Bolt](https://huggingface.co/nvidia/NVIDIA-Nemotron-3.5-Bolt-E4B-4GB), served on the same instance by [llama.cpp](https://github.com/ggml-org/llama.cpp) through an OpenAI-compatible API. On first start the stack writes a Hermes configuration that points the agent at this local model; no hosted model API key is set.

Default compute: one NVIDIA L4 24GB. You can pick a different GPU on the deploy page.

Current versions: Hermes Agent v0.23.2, llama.cpp b12464, NVIDIA-Nemotron-3.5-Bolt-E4B-4GB (default model), NVIDIA-Nemotron-3.5-Bolt-74B-A9B-24GB-GGUF (option)

Last smoke: not yet run

## What you get

| Component | Version | Image or file |
| --- | --- | --- |
| Hermes Agent (Nous Research) | v0.23.2 (pinned by digest) | `nousresearch/hermes-agent:v0.23.2` |
| llama.cpp server with CUDA | b12464 (pinned by digest) | `ghcr.io/ggml-org/llama.cpp:server-cuda-b12464` |
| NVIDIA Nemotron 3.5 Bolt E4B | fixed Hugging Face revision | `Nemotron-3.5-Bolt-E4B-Q4_K_M.gguf` |

## Try these two tasks

Open the dashboard, start a chat and paste each task. The full text, and how to check that the model runs locally, is in [docs/tasks.md](docs/tasks.md).

1. Browse: summarise the three newest llama.cpp releases with their tags and links.
2. Terminal: clone a small Python project at a release tag, install it in a virtual environment and run its tests.

## How it works

- The Launchable defines one Brev Secure Link, `open-hermes`, for port 9119, the Hermes dashboard. The dashboard is configured with a user name and password: the user is `hermes` and the password is the one you set at launch.
- llama.cpp publishes its API on the instance loopback only (`127.0.0.1:8080`). Hermes is configured to reach it inside the stack as `http://llama:8080/v1`, with the model name `nemotron-bolt`.
- The Hermes terminal backend is set to `local`, so commands run inside the hermes container. The Docker socket is not mounted.

## Settings

| Parameter | Required | Default | What it does |
| --- | --- | --- | --- |
| `MODEL` | no | `e4b` | `e4b` serves Nemotron 3.5 Bolt E4B. `74b` serves the 74B model; its model server starts only on a GPU with at least 40000 MiB of memory. See [docs/bolt-74b-on-l40s.md](docs/bolt-74b-on-l40s.md). |
| `HERMES_DASHBOARD_BASIC_AUTH_PASSWORD` | yes | none | Dashboard password, at least 12 characters. Choose "Use a secret" and pick a saved secret (the option may be off for your account), or paste a new password. |

On first start the password is written to `/home/ubuntu/workspace/hermes-bolt/hermes/.launchable-auth/password` with mode 600. On later starts the stack reads the password from that file, not from the launch parameter. The dashboard does not start if that file is missing or empty, or if the password is shorter than 12 characters: the hermes service logs the reason, waits, and shows as unhealthy in `sudo docker compose ps`.

## Use the model API from your machine

```
brev port-forward INSTANCE_NAME --port 8080:8080
curl http://localhost:8080/v1/models
```

## Data and persistence

- Models: `/home/ubuntu/workspace/hermes-bolt/models`
- Hermes data directory (`/opt/data` in the container) and the stored password: `/home/ubuntu/workspace/hermes-bolt/hermes`

Both folders are under the Brev workspace directory, which Brev keeps when the instance is stopped and removes when the instance is deleted.

The model is downloaded on first start and checked by size, and the default model also by sha256. If a file of the expected size is already on disk, it is not downloaded again.

## Stop and delete

- **Stop** the instance from the Brev console when you are not using it. Both services use the `unless-stopped` restart policy and read their settings from the workspace folders above.
- **Delete** the instance when you are finished. This removes the instance and all of its data, including models and skills.

## Troubleshooting

- Setup log: `sudo cat /var/log/brev-workspace.log`
- Service logs: `cd /home/ubuntu/workspace && sudo docker compose logs --no-color llama hermes`
- If the dashboard does not answer after a start: `cd /home/ubuntu/workspace && sudo docker compose up -d`
- The agent answers only after the model has loaded. While the model file is fetched, the llama log shows a `llama: downloading` line.
- If the llama log says the model server will not start, the model download failed its check and was removed. Run `cd /home/ubuntu/workspace && sudo docker compose restart llama` to download it again.
- If hermes shows as unhealthy, its log says why the dashboard did not start (no stored password, or one shorter than 12 characters). Deploy again with a valid `HERMES_DASHBOARD_BASIC_AUTH_PASSWORD`.
- Sign in through the dashboard's login form in the browser. If you script the login, keep the request and response output private, because it can contain the password.

## Acceptable use and safety

Hermes executes the commands the model proposes, with network access, inside its container. Review what it does, keep the dashboard password private, and do not give the agent credentials you would not hand to a new colleague. Use the model within the terms of its licence.

## Credits and licences

- Hermes Agent, by Nous Research: MIT License.
- llama.cpp: MIT License.
- NVIDIA Nemotron 3.5 Bolt E4B and 74B: OpenMDW License Agreement, version 1.1 (see each model card). The E4B model is built on Gemma 4 E4B, licensed under the Apache License 2.0. By deploying with these models you accept their terms.
- The files in this folder: Apache License 2.0; see [LICENSE](LICENSE).
