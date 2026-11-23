<p align="center"><strong>Nemotron Omni Browser Agent on NVIDIA Brev</strong><br>
  Watch NVIDIA Nemotron 3 Nano Omni drive a real Chromium browser through Playwright MCP inside an NVIDIA OpenShell sandbox, served by vLLM on one NVIDIA L40S GPU.
</p>

# Nemotron Omni Browser Agent

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3MK6719j1bLnhgxNjnPlFO2kuJS)

Launchable ID: env-3MK6719j1bLnhgxNjnPlFO2kuJS

1x L40S 48GB, >= 44 GB VRAM | 200 GiB disk | ~$2.26/hr (console 2026-11-19) | ~25 min to ready | Stop to pause, Delete when done

Watch [NVIDIA Nemotron 3 Nano Omni](https://huggingface.co/nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-FP8) drive a real Chromium browser, live, on your own GPU. The model runs on this instance with [vLLM](https://github.com/vllm-project/vllm), controls a headed Chromium through [Playwright MCP](https://github.com/microsoft/playwright-mcp), and the browser runs inside an [NVIDIA OpenShell](https://github.com/NVIDIA/OpenShell) sandbox whose egress allowlist decides which sites it may reach. Click Launch on Brev, wait about 24 minutes, open the `open-browser-agent` link and watch every step in a view-only live desktop next to the chat.

| Quick facts | |
| --- | --- |
| Runs | vLLM + NVIDIA Nemotron 3 Nano Omni 30B-A3B FP8 (local model) + agent chat page + Chromium with Playwright MCP inside an NVIDIA OpenShell sandbox + noVNC live desktop |
| Default compute | 1x NVIDIA L40S 48GB on AWS (g6e.xlarge), at least 44 GB of GPU memory; you can pick another GPU on the deploy page |
| Disk | 200 GiB |
| Ready in | about 24 minutes on a fresh deploy (2026-11-19) |
| Cost | about $2.26/hr on the default compute (console, 2026-11-19); storage is billed while stopped |
| Secrets | `HF_TOKEN` (optional Hugging Face read token) |
| Licences | Nemotron 3 Nano Omni: NVIDIA Open Model Agreement; vLLM, NVIDIA OpenShell, Playwright MCP: Apache License 2.0; noVNC: MPL 2.0; websockify: LGPL 3.0 |
| Guide | https://www.9owls.com/launchables/nemotron-omni-browser-agent/ |

Minimum GPU: one 48 GB GPU (NVIDIA L40S class). You can pick other compute on the deploy page.

Current versions: Nemotron 3 Nano Omni 30B-A3B Reasoning FP8 (revision 0acd4b1c237eab45d3977b1b46631919e9a75774), vLLM v0.33.0, NVIDIA OpenShell v0.1.9, Playwright MCP 0.0.85, noVNC 1.6.0, websockify 0.13.0, nginx 1.31.9

Last smoke: 2026-11-19, fresh deploy on AWS g6e.xlarge (1x L40S): ready in about 24 minutes.

## Contents

- [What you get](#what-you-get)
- [Deploy in three steps](#deploy-in-three-steps)
- [Try it first](#try-it-first)
- [How it works](#how-it-works)
- [Settings](#settings)
- [Use the model API from your machine](#use-the-model-api-from-your-machine)
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
| NVIDIA Nemotron 3 Nano Omni 30B-A3B Reasoning, FP8 | revision 0acd4b1c237eab45d3977b1b46631919e9a75774 | `nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-FP8` |
| vLLM (OpenAI-compatible server) | v0.33.0 | `vllm/vllm-openai:v0.33.0` |
| NVIDIA OpenShell | v0.1.9 | `openshell_0.1.9-1_amd64.deb` |
| Playwright MCP with Chromium | 0.0.85 | `@playwright/mcp` |
| noVNC and websockify (live desktop) | 1.6.0 and 0.13.0 | inside the sandbox image |
| nginx (Secure Link front) | 1.31.9 | `nginx:1.31.9-alpine` |

- A chat page with three example tasks and a step log, behind one Secure Link, `open-browser-agent`.
- A live, view-only desktop of the sandboxed Chromium (noVNC), and a Step view tab that shows the latest screenshot if the live view cannot connect.
- NVIDIA Nemotron 3 Nano Omni (30B-A3B, FP8) served by vLLM on this GPU. No hosted model and no API key are used.
- An OpenShell sandbox: read-only system files, and outbound HTTPS only to the host names you allow. Blocked requests appear in the step log.

## Deploy in three steps

1. Click **Launch on Brev**, keep the NVIDIA L40S or pick another 48 GB GPU, set `ALLOWED_DOMAINS` and `MAX_STEPS` if you want other values, and deploy.
2. Wait until the instance shows Running and the `open-browser-agent` link answers. A fresh deploy took about 24 minutes, most of it installing the stack and downloading and loading the model.
3. Click `open-browser-agent`, wait until the page header shows the model is ready, and run one of the example tasks.

## Try it first

The chat page offers these three tasks. Paste one, then watch the live desktop and the step log.

1. Browse an allowed site:

```
On en.wikipedia.org, find the release year and the developer of the Chromium browser and of the Firefox browser; answer as a table with the page URL for each row.
```

2. See the sandbox block a site that is not on the default allowlist. The step log shows the denial:

```
Open https://www.example.com and tell me what it says.
```

3. Fill in a form. The form is a demo page served inside the sandbox:

```
Open http://localhost:8080/form.html, fill in the expense form for Alex Doe, 2026-11-02, Travel, 42.50 USD, purpose 'customer visit', submit it and report the confirmation number.
```

Check the agent's answers against the pages it opened. A public site can rate-limit the instance; if a task reports an error from the site, run it again a little later.

## How it works

- vLLM serves the model on localhost port 8000 of the instance.
- The agent loop and chat page run on the instance (localhost port 7861). Each step it sends the task, a short history, the page snapshot and the latest screenshot to the model, then runs one browser action.
- Chromium, Playwright MCP (port 8931), a VNC server and noVNC (port 6080) run inside the OpenShell sandbox. `openshell forward` brings ports 8931 and 6080 to localhost on the instance.
- nginx on port 7860 is the only service behind the Secure Link: `/` is the chat page and `/vnc/` is the live desktop.
- The model never leaves the instance. The browser reaches the internet only over HTTPS to the host names in `ALLOWED_DOMAINS`.

<details>
<summary>Advanced: services and recovery after a reboot</summary>

The stack is started by `browser-agent.service`, which runs at boot, and a timer re-checks it every 5 minutes. Service state: `systemctl status browser-agent.service` and `systemctl --user status 'browser-agent-*'`. To force a restart, run `sudo systemctl restart browser-agent.service`.

</details>

## Settings

| Parameter | Required | Default | What it does |
| --- | --- | --- | --- |
| `MODEL` | no | `nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-FP8` | Model served by vLLM. |
| `ALLOWED_DOMAINS` | no | `en.wikipedia.org,huggingface.co,docs.nvidia.com` | Host names the browser may open over HTTPS (max 20, exact names). |
| `MAX_STEPS` | no | `25` | Browser actions per task: 10, 25 or 50. |
| `HF_TOKEN` | no | none | Optional Hugging Face read token. Choose "Use a secret" to pick a saved secret (the option may be off for your account), paste a read token, or leave it empty. |

Settings are read once at first start and saved on the instance. To change them later, edit `~/workspace/browser-agent/agent.env` (and `~/workspace/browser-agent/policy.yaml` for the allowlist), then run `sudo systemctl restart browser-agent.service`.

## Use the model API from your machine

The model API listens on localhost only. Forward it with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 8000:8000
curl http://localhost:8000/v1/models
```

The vLLM OpenAI-compatible API then answers on `http://localhost:8000/v1`, and the model list shows `nemotron-omni`.

## Data and persistence

- Settings, step screenshots and the sandbox log: `/home/ubuntu/workspace/browser-agent`
- Model cache: `/home/ubuntu/workspace/huggingface`

Settings, screenshots and the sandbox log survive Stop and are removed by Delete. The model cache lives on the instance's local NVMe when the root disk is small and is downloaded again after a Stop; when the root disk has room it stays.

## Stop, start and delete

- Stop pauses the instance; storage is still billed while stopped. After Start, browser-agent.service starts the services again; the model loads again, or downloads again if it was on local NVMe. If the chat page is not back about 20 minutes after a start, run `sudo systemctl restart browser-agent.service`.
- If Start reports a failure, run Start again.
- Delete removes the instance and all data.

## Troubleshooting

<details>
<summary>Where are the logs?</summary>

- Setup log: `sudo cat /var/log/brev-workspace.log`
- Service state: `systemctl status browser-agent.service` and `systemctl --user status 'browser-agent-*'`
- Restart everything: `sudo systemctl restart browser-agent.service`

</details>

<details>
<summary>The page says the model is loading</summary>

The first start downloads the model and loads it into vLLM. Run `sudo docker logs --tail 50 vllm` and `curl -s http://localhost:8000/v1/models`. When the model list shows `nemotron-omni`, the header turns to "ready".

</details>

<details>
<summary>The live desktop is black or does not connect</summary>

Use the Step view tab: it shows the latest step screenshot without a live connection. Then check the sandbox with `openshell sandbox list` and the port forwards with `systemctl --user status browser-agent-forward@6080.service browser-agent-forward@8931.service`.

</details>

<details>
<summary>A site does not load</summary>

Only host names in `ALLOWED_DOMAINS` are reachable. Blocked requests show in the step log as sandbox lines, and in `tail -n 50 ~/workspace/browser-agent/data/logs/denials.log`. To change the allowlist, edit `~/workspace/browser-agent/policy.yaml` and `~/workspace/browser-agent/agent.env`, delete the sandbox with `openshell sandbox delete browser-agent`, then run `sudo systemctl restart browser-agent.service` to recreate it.

</details>

More in [docs/troubleshooting.md](docs/troubleshooting.md).

## FAQ

### Which GPU do I need?

One 48 GB GPU of the NVIDIA L40S class, with at least 44 GB of GPU memory for the model. The default compute is 1x NVIDIA L40S 48GB on AWS g6e.xlarge, the instance used in the last smoke.

### Does anything leave the instance?

The model runs on the instance and no hosted model API is called. The browser reaches the internet only over HTTPS to the host names in `ALLOWED_DOMAINS`; the sandbox blocks everything else and logs the denial.

### Can someone else use my agent?

The chat page has no login of its own. Anyone who can open its Secure Link can run browser tasks on your instance, so do not share the link or make it public.

### Can I run this on my own hardware?

The parts are open source: see [vLLM](https://github.com/vllm-project/vllm), [NVIDIA OpenShell](https://github.com/NVIDIA/OpenShell), [Playwright MCP](https://github.com/microsoft/playwright-mcp) and the `setup.sh` in this folder. Read the model card for the model's terms first.

### How do I update to a newer version?

The model, images and packages are pinned to the versions in "Current versions" above. To move to a newer release, deploy a new instance after this Launchable is updated, or edit the pins in `setup.sh` on your own copy and test the result before relying on it.

## Acceptable use and safety

Read [docs/acceptable-use.md](docs/acceptable-use.md) before you run tasks. The agent refuses to type into password, payment card or billing fields, refuses to click buy, pay, checkout, order, subscribe, sign-up, register, create-account or donate controls, stops at CAPTCHAs, login walls and paywalls, stops at the step limit, and treats web page text as untrusted data. These are keyword checks, not a guarantee, and the tool is not for bulk scraping. Web pages can contain prompt injection: review what the agent did in the step log.

The chat page has no login of its own. Do not share its Secure Link or make it public: anyone who can open it can run browser tasks on your instance.

## Guides and related Launchables

- Step-by-step guide: [Run a browser agent in an OpenShell sandbox](https://www.9owls.com/guides/run-a-browser-agent-in-an-openshell-sandbox/)
- New to Launchables: [Deploy a Launchable on NVIDIA Brev](https://www.9owls.com/guides/deploy-a-launchable-on-nvidia-brev/)
- Other agents: [NVIDIA Brev agent Launchables](https://www.9owls.com/guides/nvidia-brev-agent-launchables/)
- Instance lifecycle: [Stop, start and delete an NVIDIA Brev instance](https://www.9owls.com/guides/stop-start-and-delete-an-nvidia-brev-instance/)
- This Launchable on 9owls: https://www.9owls.com/launchables/nemotron-omni-browser-agent/
- All Launchables by 9owls: https://www.9owls.com/launchables/
- Related: [Nemotron Chat](https://www.9owls.com/launchables/nemotron-chat/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aArulP2ZTX7HwqGLf4pwRT6z)); [NeMo Guardrails with garak](https://www.9owls.com/launchables/nemo-guardrails-garak/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8bOSWcMAZsaOnuaytHUvAEC0v)); [Nemotron Omni Studio](https://www.9owls.com/launchables/nemotron-omni-studio/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8a9cKCTehBUEgzwkv7tqk9gZK))

## Keep your own stack running

NightKeeper packages your repository as an NVIDIA Brev Launchable, proves it on a fresh GPU and keeps it running. Your Brev API key stays in your repository's GitHub secrets. NightKeeper never sees it.

[Create your Launchable](https://www.9owls.com/nightkeeper/start/) or [read about NightKeeper](https://www.9owls.com/nightkeeper/).

## Credits and licences

- NVIDIA Nemotron 3 Nano Omni 30B-A3B Reasoning FP8: NVIDIA Open Model Agreement. Read the model card on Hugging Face before use.
- NVIDIA OpenShell, vLLM, Playwright MCP and Playwright: Apache License 2.0.
- Chromium: BSD 3-Clause License and the licenses of its third-party components.
- noVNC: Mozilla Public License 2.0. websockify: GNU Lesser General Public License 3.0.
- nginx: BSD 2-Clause License. FastAPI: MIT License. Uvicorn: BSD 3-Clause License.
- The files in this folder (README.md, setup.sh, docs): MIT License; see [LICENSE](LICENSE).

Published and maintained by [9owls, Inc.](https://www.9owls.com/). Questions: hello@9owls.com.
