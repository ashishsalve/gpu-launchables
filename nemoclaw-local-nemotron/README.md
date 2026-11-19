# NemoClaw Private Agent on Local Nemotron

[![Launch on Brev](https://brev-assets.s3.us-west-1.amazonaws.com/nv-lb-dark.svg)](https://brev.nvidia.com/launchable/deploy?launchableID=env-3MK68pYUXCux61sliWiZiwndcQ0)

Launchable ID: env-3MK68pYUXCux61sliWiZiwndcQ0

Run a private agent with [NVIDIA NemoClaw](https://github.com/NVIDIA/NemoClaw) on one GPU. The agent runs inside an [NVIDIA OpenShell](https://github.com/NVIDIA/OpenShell) sandbox and uses one of three open-source agent harnesses: OpenClaw, Hermes Agent or LangChain Deep Agents Code. Its model, NVIDIA Nemotron 3.5 Lightning, is served by [vLLM](https://github.com/vllm-project/vllm) on the same GPU, so no external model API or API key is needed.

1x L40S 48GB, >= 46 GB VRAM | 200 GiB disk | ~$2.26/hr (console 2026-11-19) | ~35 min to ready | Stop to pause, Delete when done

Minimum GPU: one 48 GB GPU (L40S class). You can pick other compute on the deploy page; a 96 GB GPU allows MAX_MODEL_LEN 131072.

Current versions: NemoClaw v0.0.144 (commit 82e1ad7), OpenShell v0.0.116, vLLM v0.27.1, Nemotron 3.5 Lightning 30B-A3B NVFP4 (revision bee7596), Node.js v22.23.5, nginx 1.30.7-alpine.
Last smoke: 2026-11-19, fresh deploy on 1x L40S (agent ready about 34 minutes after deploy).

## What you get

- A NemoClaw agent in an OpenShell sandbox, reached through one Brev Secure Link named `agent`.
- NVIDIA Nemotron 3.5 Lightning served by vLLM on `127.0.0.1:8000`, with tool calling enabled.
- An outbound network policy: NemoClaw's balanced tier plus a rule that lets `git` and `curl` in the sandbox send GET, HEAD and OPTIONS requests to `github.com` and `codeload.github.com` (OpenShell REST inspection, `read-only` access).
- Telemetry off for NemoClaw and OpenShell.

NemoClaw, OpenShell, OpenClaw, Hermes Agent and LangChain Deep Agents are third-party open-source projects. This environment installs and configures them; it does not modify them. NemoClaw is alpha software: read its documentation before relying on it.

## First 10 minutes

1. Wait until the instance shows Running and setup has finished. The model download and the sandbox build happen on first start.
2. Click the `agent` link on the instance page.
3. The dashboard asks for an access token. In the Brev terminal, run:

   ```
   cat ~/workspace/private-agent/AGENT_URL.txt
   ```

   Open that URL, or paste its token into the dashboard. The file is readable only by your user.
4. Ask the agent:

   > Which model are you running on, and where is it served?

   The agent should name `nemotron-3.5-lightning`.

## Try these three tasks

1. Private document brief. Copy your files into the sandbox (see the [NemoClaw documentation](https://github.com/NVIDIA/NemoClaw) for file transfer), then ask: "Read every file in /sandbox/docs and write a one-page brief with a citation per claim to /sandbox/docs/brief.md."
2. Repo triage. Ask: "Download https://github.com/more-itertools/more-itertools/archive/4aeb4338ae1407d8da9723e86da99efeb446f719.tar.gz (tag v11.2.1) with curl, unpack it, run its tests, and summarise any failures with a proposed patch." The GitHub rule allows only GET, HEAD and OPTIONS, so `git clone`, which sends POST requests, is not allowed.
3. Web task. Ask: "Fetch the vLLM release notes from GitHub and summarise them, then try the same from pypi.org." GitHub is in the rule this environment adds; any other host is decided by NemoClaw's balanced tier.

## Choosing a harness

Set `AGENT_HARNESS` on the deploy page:

- `openclaw` (default): OpenClaw with its web dashboard.
- `hermes`: Hermes Agent with its web dashboard.
- `langchain-deepagents-code`: LangChain Deep Agents Code, terminal only. The `agent` link shows how to connect: `sg docker -c 'nemoclaw private-agent connect'`.

`MAX_MODEL_LEN` sets the model context: 32768, 65536 (default) or 131072. Use 131072 only on a 96 GB GPU.

Both settings apply to the first start. To change them later, delete the instance and deploy again.

## How it stays local

You can check each of these on the instance:

1. No inference API key exists on the instance, and the deploy page asks for none.
2. `sg docker -c 'nemoclaw private-agent status'` shows the custom local endpoint and the model `nemotron-3.5-lightning`. Run `nemoclaw` commands through `sg docker -c '...'`: the agent runs under the `docker` group, and a plain `nemoclaw private-agent connect` can fail with "cannot attribute".
3. `sudo ss -ltnp` shows vLLM listening on 127.0.0.1:8000 only.
4. `openshell policy get private-agent` shows the active network policy.
5. `NEMOCLAW_DISABLE_TELEMETRY=1` and `OPENSHELL_TELEMETRY_ENABLED=false` are set in `~/workspace/private-agent/recover.sh`, which starts the agent after every boot.

Only port 18780 is reachable, through the Secure Link. Do not open port 8080 (the OpenShell gateway) or port 8000.

## Use the model API from your machine

```
brev port-forward INSTANCE_NAME --port 8000:8000
curl http://localhost:8000/v1/models
```

The API is OpenAI-compatible; the model name is `nemotron-3.5-lightning`. Set `max_tokens` to 4096 or more, because the model reasons before it answers.

## Data and persistence

- `~/workspace/private-agent`: launch settings, the access URL file, Node.js and the recovery scripts.
- `~/workspace/nemotron-vllm/huggingface`: the model cache.

Both survive Stop and are removed by Delete. After Start, the `private-agent-recover` systemd service waits for the model, restarts NemoClaw's local inference proxy, recovers the sandbox, re-applies the policy and rewrites `AGENT_URL.txt`. The access token may change, so read the file again.

## Stop and delete

Stop pauses the instance; disk storage is still billed while stopped. Delete removes the instance and all its data.

## Troubleshooting

- Setup log: `sudo cat /var/log/brev-workspace.log`
- Model server: `sudo docker logs --tail 100 nemotron-vllm`
- Restart the agent: `sudo systemctl restart private-agent-recover`

More in [docs/troubleshooting.md](docs/troubleshooting.md).

## Acceptable use and safety

The agent can run commands in its sandbox and reach the hosts its policy allows. Give it only data and tasks you are allowed to use. Review what it writes before you use it elsewhere. Follow the licences and acceptable-use terms of every project and model listed below.

## Credits and licences

- NVIDIA NemoClaw - Apache License 2.0
- NVIDIA OpenShell - Apache License 2.0
- vLLM - Apache License 2.0
- OpenClaw, Hermes Agent, LangChain Deep Agents - MIT License
- nginx - BSD 2-Clause License
- Node.js - MIT License
- NVIDIA Nemotron 3.5 Lightning 30B-A3B NVFP4 - OpenMDW License Agreement, version 1.1
- more-itertools (sample repository for task 2) - MIT License

The files in this folder are licensed under the Apache License 2.0; see LICENSE.
