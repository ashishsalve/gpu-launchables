# Nemotron Omni Browser Agent

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3MK6719j1bLnhgxNjnPlFO2kuJS)

Watch NVIDIA Nemotron 3 Nano Omni drive a real Chromium browser, live, on your
own GPU. The model runs on this instance with vLLM. It controls a headed
Chromium through Playwright MCP, and the browser runs inside an NVIDIA
OpenShell sandbox whose egress allowlist decides which sites it may reach.
You watch every step in a view-only live desktop next to the chat.

1x L40S 48GB, >= 44 GB VRAM | 200 GiB disk | ~$2.23/hr | Stop to pause, Delete when done

Launchable ID: env-3MK6719j1bLnhgxNjnPlFO2kuJS

Minimum GPU: one 48 GB GPU (NVIDIA L40S class). You can pick other compute on
the deploy page.

## What you get

- A chat page with three example tasks and a step log (one Secure Link,
  `open-browser-agent`).
- A live, view-only desktop of the sandboxed Chromium (noVNC), and a Step view
  tab that shows the latest screenshot if the live view cannot connect.
- NVIDIA Nemotron 3 Nano Omni (30B-A3B, FP8) served by vLLM on this GPU. No
  hosted model and no API key are used.
- An OpenShell sandbox: read-only system files, and outbound HTTPS only to the
  host names you allow. Blocked requests appear in the step log.

## Try these three tasks

1. "On en.wikipedia.org, find the release year and the developer of the
   Chromium browser and of the Firefox browser; answer as a table with the page
   URL for each row."
2. "Open https://www.example.com and tell me what it says." This site is not on
   the default allowlist, so the sandbox blocks it and the step log shows the
   denial.
3. "Open http://localhost:8080/form.html, fill in the expense form ... and
   report the confirmation number." The form is a demo page served inside the
   sandbox.

## How it works

- vLLM serves the model on localhost port 8000 of the instance.
- The agent loop and chat page run on the instance (localhost port 7861). Each
  step it sends the task, a short history, the page snapshot and the latest
  screenshot to the model, then runs one browser action.
- Chromium, Playwright MCP (port 8931), a VNC server and noVNC (port 6080) run
  inside the OpenShell sandbox. `openshell forward` brings ports 8931 and 6080
  to localhost on the instance.
- nginx on port 7860 is the only service behind the Secure Link: `/` is the
  chat page and `/vnc/` is the live desktop.

## Settings

| Parameter | Default | Meaning |
|---|---|---|
| MODEL | nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-FP8 | Model served by vLLM |
| ALLOWED_DOMAINS | en.wikipedia.org,huggingface.co,docs.nvidia.com | Host names the browser may open over HTTPS (max 20, exact names) |
| MAX_STEPS | 25 | Browser actions per task: 10, 25 or 50 |
| HF_TOKEN | none | Optional Hugging Face read token. Choose "Use a secret" to pick a saved secret (the option may be off for your account), paste a read token, or leave it empty. |

Settings are read once at first start and saved on the instance. To change
them later, edit `~/workspace/browser-agent/agent.env` (and
`~/workspace/browser-agent/policy.yaml` for the allowlist), then run
`sudo systemctl restart browser-agent.service`.

## Use the model API from your machine

The model API listens on localhost only. Forward it with the Brev CLI:

```
brev port-forward <instance-name> --port 8000:8000
curl http://localhost:8000/v1/models
```

## Data and persistence

Everything lives under `/home/ubuntu/workspace/browser-agent` (settings, step
screenshots, the sandbox log) and `/home/ubuntu/workspace/huggingface` (model
cache). These survive Stop and are removed by Delete.

## Stop and delete

- Stop pauses the instance; storage is still billed while stopped. After Start
  the services come back by themselves (no settings to re-enter); the model
  takes a few minutes to load again.
- Delete removes the instance and all data.

## Troubleshooting

- Setup log: `sudo cat /var/log/brev-workspace.log`
- Service state: `systemctl status browser-agent.service` and
  `systemctl --user status 'browser-agent-*'`
- Restart everything: `sudo systemctl restart browser-agent.service`

More in [docs/troubleshooting.md](docs/troubleshooting.md).

## Acceptable use and safety

Read [docs/acceptable-use.md](docs/acceptable-use.md) before you run tasks.
The agent refuses to type into password, payment card or billing fields,
refuses to click buy, pay, checkout, order, subscribe, sign-up, register,
create-account or donate controls, stops at CAPTCHAs, login walls and
paywalls, stops at the step limit, and treats web page text as untrusted
data. These are keyword checks, not a guarantee, and the tool is not for bulk
scraping. Web pages can contain prompt injection: review what the agent did
in the step log.

The chat page has no login of its own. Do not share its Secure Link or make
it public: anyone who can open it can run browser tasks on your instance.

## Versions

Current versions: Nemotron 3 Nano Omni 30B-A3B Reasoning FP8 (revision 0acd4b1c237eab45d3977b1b46631919e9a75774), vLLM v0.33.0, NVIDIA OpenShell v0.1.9, Playwright MCP 0.0.85, noVNC 1.6.0, websockify 0.13.0, nginx 1.31.9

Last smoke: not yet run

## Credits and licences

This folder (README.md, setup.sh, docs) is MIT licensed; see LICENSE. The
model, vLLM, OpenShell, Playwright MCP, Chromium, noVNC and websockify are
third-party open-source projects under their own licences, listed in LICENSE.
