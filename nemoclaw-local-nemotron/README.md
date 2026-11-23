<p align="center">
  <strong>NVIDIA NemoClaw on NVIDIA Brev</strong><br>
  Run a private NemoClaw agent in an NVIDIA OpenShell sandbox, with NVIDIA Nemotron 3.5 Lightning served by vLLM on one NVIDIA L40S GPU and no external model API key.
</p>

# NemoClaw Private Agent on Local Nemotron

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3MK68pYUXCux61sliWiZiwndcQ0)

Launchable ID: env-3MK68pYUXCux61sliWiZiwndcQ0

1x L40S 48GB, >= 46 GB VRAM | 200 GiB disk | ~$2.26/hr (console 2026-11-19) | ~35 min to ready | Stop to pause, Delete when done

[NVIDIA NemoClaw](https://github.com/NVIDIA/NemoClaw) runs a private agent inside an [NVIDIA OpenShell](https://github.com/NVIDIA/OpenShell) sandbox, with one of three open-source agent harnesses: OpenClaw, Hermes Agent or LangChain Deep Agents Code. This NVIDIA Brev Launchable serves its model, NVIDIA Nemotron 3.5 Lightning, with [vLLM](https://github.com/vllm-project/vllm) on the same NVIDIA L40S GPU, so no external model API or API key is needed. Click Launch on Brev, wait about 34 minutes, open the `agent` link and ask the agent which model it runs on.

| Quick facts | |
| --- | --- |
| Runs | NVIDIA NemoClaw agent (OpenClaw by default) in an NVIDIA OpenShell sandbox + vLLM serving NVIDIA Nemotron 3.5 Lightning (local model) + nginx proxy for the `agent` link |
| Default compute | 1x NVIDIA L40S 48GB on AWS (g6e.xlarge), at least 46 GB VRAM; you can pick another GPU on the deploy page |
| Disk | 200 GiB |
| Ready in | about 34 minutes on a fresh deploy (2026-11-19) |
| Cost | about $2.26/hr on the default compute (console, 2026-11-19); storage is billed while stopped |
| Secrets | none; the deploy page asks for no API key |
| Licences | NemoClaw, OpenShell, vLLM: Apache 2.0; OpenClaw, Hermes Agent, LangChain Deep Agents: MIT; Nemotron 3.5 Lightning: OpenMDW 1.1 |
| Guide | https://www.9owls.com/launchables/nemoclaw-local-nemotron/ |

Current versions: NemoClaw v0.0.144 (commit 82e1ad7), OpenShell v0.0.116, vLLM v0.27.1, Nemotron 3.5 Lightning 30B-A3B NVFP4 (revision bee7596), Node.js v22.23.5, nginx 1.30.7-alpine.

Last smoke: 2026-11-19, fresh deploy on 1x L40S (agent ready about 34 minutes after deploy).

## Contents

- [What you get](#what-you-get)
- [Deploy in three steps](#deploy-in-three-steps)
- [Try it first](#try-it-first)
- [How it works](#how-it-works)
- [How it stays local](#how-it-stays-local)
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
| NVIDIA NemoClaw | v0.0.144 (commit 82e1ad7) | installer pinned by commit and sha256 |
| NVIDIA OpenShell | v0.0.116 | `openshell_0.0.116-1_amd64.deb` (sha256 checked) |
| vLLM | v0.27.1 (pinned by digest) | `vllm/vllm-openai:v0.27.1` |
| NVIDIA Nemotron 3.5 Lightning 30B-A3B NVFP4 | revision bee7596 | `nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4` |
| Node.js | v22.23.5 | `node-v22.23.5-linux-x64.tar.xz` (sha256 checked) |
| nginx | 1.30.7-alpine (pinned by digest) | `nginx:1.30.7-alpine` |

- A NemoClaw agent in an OpenShell sandbox, reached through one Brev Secure Link named `agent`.
- NVIDIA Nemotron 3.5 Lightning served by vLLM on port 8000 of the instance loopback, with tool calling enabled.
- An outbound network policy: NemoClaw's balanced tier plus a rule that lets `git` and `curl` in the sandbox send GET, HEAD and OPTIONS requests to `github.com` and `codeload.github.com` (OpenShell REST inspection, `read-only` access).
- Telemetry off for NemoClaw and OpenShell.

NemoClaw, OpenShell, OpenClaw, Hermes Agent and LangChain Deep Agents are third-party open-source projects. This environment installs and configures them; it does not modify them. NemoClaw is alpha software: read its documentation before relying on it.

## Deploy in three steps

1. Click **Launch on Brev**, keep the NVIDIA L40S or pick another GPU, keep or change `AGENT_HARNESS` and `MAX_MODEL_LEN`, and deploy.
2. Wait until the instance shows Running and setup has finished. The model download and the sandbox build happen on first start; a fresh deploy took about 34 minutes.
3. Click the `agent` link on the instance page. The dashboard asks for an access token. In the Brev terminal, run:

   ```
   cat ~/workspace/private-agent/AGENT_URL.txt
   ```

   Open that URL, or paste its token into the dashboard. The file is readable only by your user.

## Try it first

Start by asking the agent:

> Which model are you running on, and where is it served?

The agent should name `nemotron-3.5-lightning`. Then try these three tasks:

1. Private document brief. Copy your files into the sandbox (see the [NemoClaw documentation](https://github.com/NVIDIA/NemoClaw) for file transfer), then ask: "Read every file in /sandbox/docs and write a one-page brief with a citation per claim to /sandbox/docs/brief.md."
2. Repo triage. Ask: "Download https://github.com/more-itertools/more-itertools/archive/4aeb4338ae1407d8da9723e86da99efeb446f719.tar.gz (tag v11.2.1) with curl, unpack it, run its tests, and summarise any failures with a proposed patch." The GitHub rule allows only GET, HEAD and OPTIONS, so `git clone`, which sends POST requests, is not allowed.
3. Web task. Ask: "Fetch the vLLM release notes from GitHub and summarise them, then try the same from pypi.org." GitHub is in the rule this environment adds; any other host is decided by NemoClaw's balanced tier.

Review what the agent writes and check its answers against their sources.

## How it works

- NemoClaw builds and runs the agent inside an OpenShell sandbox on the instance, with the harness you chose at launch.
- vLLM serves Nemotron 3.5 Lightning on port 8000 of the instance loopback only; the model name is `nemotron-3.5-lightning`.
- The Launchable defines one Brev Secure Link, `agent`, for port 18780: an nginx proxy in front of the agent dashboard. It is the only reachable port.
- A `private-agent-recover` service runs `~/workspace/private-agent/recover.sh` to start the agent, and re-applies the network policy after each recovery.
- The deploy page asks for no secret, and no inference API key exists on the instance.

<details>
<summary>Advanced: choosing a harness</summary>

Set `AGENT_HARNESS` on the deploy page:

- `openclaw` (default): OpenClaw with its web dashboard.
- `hermes`: Hermes Agent with its web dashboard.
- `langchain-deepagents-code`: LangChain Deep Agents Code, terminal only. The `agent` link shows how to connect: `sg docker -c 'nemoclaw private-agent connect'`.

The harness applies to the first start. To change it later, delete the instance and deploy again.

</details>

## How it stays local

You can check each of these on the instance:

1. No inference API key exists on the instance, and the deploy page asks for none.
2. `sg docker -c 'nemoclaw private-agent status'` shows the custom local endpoint and the model `nemotron-3.5-lightning`. Run `nemoclaw` commands through `sg docker -c '...'`: the agent runs under the `docker` group, and a plain `nemoclaw private-agent connect` can fail with "cannot attribute".
3. `sudo ss -ltnp` shows vLLM listening on port 8000 of the loopback address only.
4. `openshell policy get private-agent` shows the active network policy.
5. `NEMOCLAW_DISABLE_TELEMETRY=1` and `OPENSHELL_TELEMETRY_ENABLED=false` are set in `~/workspace/private-agent/recover.sh`, which the private-agent-recover service runs to start the agent.

Only port 18780 is reachable, through the Secure Link. Do not open port 8080 (the OpenShell gateway) or port 8000.

## Settings

| Parameter | Required | Default | What it does |
| --- | --- | --- | --- |
| `AGENT_HARNESS` | no | `openclaw` | Agent harness NemoClaw installs in the sandbox: `openclaw` (web dashboard), `hermes` (Hermes Agent, web dashboard) or `langchain-deepagents-code` (terminal only). |
| `MAX_MODEL_LEN` | no | `65536` | Model context length for vLLM: `32768`, `65536` or `131072`. Use `131072` only on a 96 GB GPU. |

Both settings apply to the first start. To change them later, delete the instance and deploy again.

## Use it from your machine

```
brev port-forward INSTANCE_NAME --port 8000:8000
curl http://localhost:8000/v1/models
```

The API is OpenAI-compatible; the model name is `nemotron-3.5-lightning`. Set `max_tokens` to 4096 or more, because the model reasons before it answers.

## Data and persistence

- `/home/ubuntu/workspace/private-agent` (`~/workspace/private-agent`): launch settings, the access URL file, Node.js and the recovery scripts.
- `/home/ubuntu/workspace/nemotron-vllm/huggingface` (`~/workspace/nemotron-vllm/huggingface`): the model cache.

Both survive Stop and are removed by Delete. After Start, the agent may not come back on its own. If the `agent` link shows an error, run `sudo systemctl restart private-agent-recover` in the Brev terminal; it waits up to 20 minutes for the model, restarts NemoClaw's local inference proxy, recovers the sandbox, re-applies the policy and rewrites `AGENT_URL.txt`. The access token may change, so read the file again.

## Stop, start and delete

- **Stop** the instance from the Brev console when you are not using it. The launch settings, the access URL file and the model cache stay in the workspace folders above. Disk storage is still billed while the instance is stopped.
- **Start** it again from the Brev console. If the `agent` link shows an error, run `sudo systemctl restart private-agent-recover` (see Data and persistence), then read `AGENT_URL.txt` again.
- **Delete** the instance when you are finished. This removes the instance and all of its data, including the downloaded model.

Delete removes the instance and all its data. After Start, if the agent link shows an error, run `sudo systemctl restart private-agent-recover` (see Data and persistence).

## Troubleshooting

<details>
<summary>Where are the logs?</summary>

- Setup log: `sudo cat /var/log/brev-workspace.log`
- Model server: `sudo docker logs --tail 100 nemotron-vllm`
- NemoClaw installer: `tail -n 100 ~/workspace/private-agent/.state/nemoclaw-install.log`

</details>

<details>
<summary>The agent link shows an error after Start</summary>

Run `sudo systemctl restart private-agent-recover`, then read `~/workspace/private-agent/AGENT_URL.txt` again, because the access token may change.

</details>

<details>
<summary>A nemoclaw command says it cannot attribute a listener</summary>

The agent runs under the `docker` group. Run `nemoclaw` commands in the same group, for example `sg docker -c 'nemoclaw private-agent connect'`.

</details>

<details>
<summary>The model server runs out of memory</summary>

Deploy again with a smaller `MAX_MODEL_LEN`.

</details>

More in [docs/troubleshooting.md](docs/troubleshooting.md).

## FAQ

### Which GPU do I need for NemoClaw with local Nemotron?

One 48 GB GPU (L40S class) runs the default settings; one NVIDIA L40S 48GB is the default compute and the GPU used in the last smoke. A 96 GB GPU allows `MAX_MODEL_LEN` 131072.

### Does anything leave the instance?

The model runs on the instance: vLLM listens on port 8000 of the instance loopback only, and no external model API key is set. The agent can still reach the hosts its sandbox policy allows: NemoClaw's balanced tier plus GET, HEAD and OPTIONS to `github.com` and `codeload.github.com`. Telemetry is off for NemoClaw and OpenShell.

### Can I change the harness or context length after deploy?

No. Both settings apply to the first start. Delete the instance and deploy again with the new values.

### Why does git clone not work in the sandbox?

The sandbox network policy allows only GET, HEAD and OPTIONS requests to GitHub, and `git clone` sends POST requests. Download a release archive with `curl` instead, as in the second task in [Try it first](#try-it-first).

### Can I run this on my own hardware?

NemoClaw, OpenShell, vLLM and the Nemotron model weights are open; see the [NemoClaw repository](https://github.com/NVIDIA/NemoClaw) and the `setup.sh` in this folder.

### How do I update to a newer version?

The components are pinned to the versions in "Current versions" above. To move to a newer release, deploy a new instance after this Launchable is updated, or edit the pins in `setup.sh` on your own copy and test the result before relying on it.

## Acceptable use and safety

The agent can run commands in its sandbox and reach the hosts its policy allows. Give it only data and tasks you are allowed to use. Review what it writes before you use it elsewhere. Follow the licences and acceptable-use terms of every project and model listed below.

## Guides and related Launchables

- Step-by-step guide: [Run a private NemoClaw agent on local Nemotron](https://www.9owls.com/guides/run-a-private-nemoclaw-agent-on-local-nemotron/)
- New to Launchables: [Deploy a Launchable on NVIDIA Brev](https://www.9owls.com/guides/deploy-a-launchable-on-nvidia-brev/)
- Other agents: [NVIDIA Brev agent Launchables](https://www.9owls.com/guides/nvidia-brev-agent-launchables/) and [which agent Launchable to pick](https://www.9owls.com/guides/which-nvidia-brev-agent-launchable-to-pick/)
- Instance lifecycle: [Stop, start and delete an NVIDIA Brev instance](https://www.9owls.com/guides/stop-start-and-delete-an-nvidia-brev-instance/)
- This Launchable on 9owls: https://www.9owls.com/launchables/nemoclaw-local-nemotron/
- All Launchables by 9owls: https://www.9owls.com/launchables/
- Related: [Nemotron Chat](https://www.9owls.com/launchables/nemotron-chat/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8aArulP2ZTX7HwqGLf4pwRT6z)); [OpenHands on Nemotron](https://www.9owls.com/launchables/openhands-nemotron/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8b2pM4xEhrOmr5yEObCVI7kyS)); [Paperclip on Nemotron](https://www.9owls.com/launchables/paperclip-nemotron/) ([deploy](https://brev.nvidia.com/launchable/deploy?launchableID=env-3M8bFcmnzaZcFNHTjlLhZ2VVlaA))

## Keep your own stack running

NightKeeper packages your repository as an NVIDIA Brev Launchable, proves it on a fresh GPU and keeps it running. Your Brev API key stays in your repository's GitHub secrets. NightKeeper never sees it.

[Create your Launchable](https://www.9owls.com/nightkeeper/start/) or [read about NightKeeper](https://www.9owls.com/nightkeeper/).

## Credits and licences

- NVIDIA NemoClaw - Apache License 2.0
- NVIDIA OpenShell - Apache License 2.0
- vLLM - Apache License 2.0
- OpenClaw, Hermes Agent, LangChain Deep Agents - MIT License
- nginx - BSD 2-Clause License
- Node.js - MIT License
- NVIDIA Nemotron 3.5 Lightning 30B-A3B NVFP4 - OpenMDW License Agreement, version 1.1
- more-itertools (sample repository for task 2) - MIT License

The files in this folder are licensed under the Apache License 2.0; see [LICENSE](LICENSE).

Published and maintained by [9owls, Inc.](https://www.9owls.com/). Questions: hello@9owls.com.
