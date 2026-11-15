# OpenHands Coding Agent on Nemotron

A private AI software engineer on your own GPU. [OpenHands](https://github.com/OpenHands/OpenHands) is an open-source coding agent that writes, runs and fixes code. Here it talks to [NVIDIA Nemotron 3.5 Lightning](https://huggingface.co/nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4), served on the same instance by [vLLM](https://github.com/vllm-project/vllm) through an OpenAI-compatible API. The model runs on the same instance, so prompts are not sent to a hosted model API.

Current versions: OpenHands 1.40.0, vLLM v0.27.1, NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4 (default model)

Last smoke: not yet run

## What it runs

| Component | Version | Image |
| --- | --- | --- |
| OpenHands (Agent Canvas) | 1.40.0 (pinned) | `ghcr.io/openhands/agent-canvas:1.40.0` |
| vLLM (OpenAI-compatible server) | v0.27.1 (pinned by digest) | `vllm/vllm-openai:v0.27.1` |

OpenHands listens on port 8000 and is opened through the Brev link. Port 8000 is published on all interfaces of the instance; access to OpenHands requires its API key (step 3 below). The vLLM API is bound to the instance itself (127.0.0.1:8001) and is not exposed publicly. The agent runs commands inside the OpenHands container; it is not given the Docker socket.

## Pick a model

Set the `MODEL` launch parameter when you deploy:

- `nvidia/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-NVFP4` (default; NVIDIA Nemotron, 30B total and 3B active parameters, NVFP4 weights)
- `Qwen/Qwen3-Coder-30B-A3B-Instruct-FP8` (open alternative; about a 31 GB download)

`MAX_MODEL_LEN` sets the context window: 65536 (default), 32768 or 131072 tokens. OpenHands needs at least 22000 tokens and works best with 32768 or more. A larger window uses more GPU memory.

Whichever model you pick, vLLM serves it under the name `coder`. The model is downloaded once on first start and loaded from the local cache after that. To change the model, deploy again with a different `MODEL`.

## Hugging Face token

`HF_TOKEN` is optional. Both models are public; a token only avoids anonymous download limits. On the deploy page you can bind a saved secret or paste a read token. Never put a token anywhere except this parameter.

## Default GPU

Default: one NVIDIA L40S 48GB, with 200 GiB of disk for the container images and the model cache.

## Use it

1. Deploy and wait until the instance is Running.
2. Open the OpenHands link, then go to `/canvas` if the start page does not open it.
3. OpenHands asks for its API key. The key is generated on first start; read it on the instance (for example after `brev shell INSTANCE_NAME`) and paste it into the UI:

   ```
   docker exec $(docker ps --quiet --filter label=com.docker.compose.service=openhands) sh -c 'cat "$STATE_DIR/api-key.txt"'
   ```

   Keep this key private: anyone who has it and can reach the OpenHands link can run code on the instance.
4. Open Settings > LLM, switch to Advanced, and enter:
   - Custom model: `openai/coder`
   - Base URL: `http://vllm:8000/v1`
   - API key: any non-empty text, for example `local` (vLLM here does not check it)
5. Start a conversation. The first answer arrives once vLLM has finished loading the model; until then requests fail and can be retried.

Put the code you want the agent to work on in `/home/ubuntu/workspace/projects` on the instance; OpenHands sees it as `/projects`.

To call the OpenAI-compatible API from your own machine, forward the port with the Brev CLI:

```
brev port-forward INSTANCE_NAME --port 8001:8001
curl http://localhost:8001/v1/models
```

## How data persists

- Models (Hugging Face cache): `/home/ubuntu/workspace/huggingface`
- OpenHands settings and conversations: `/home/ubuntu/workspace/openhands`
- Your projects: `/home/ubuntu/workspace/projects`

They survive a stop and start of the instance. They are removed when the instance is deleted.

Projects in `/home/ubuntu/workspace/projects` are owned by the OpenHands user (uid 10001); use sudo to edit them from the instance shell.

## Stop or delete to control cost

- **Stop** the instance from the Brev console when you are not using it. Your models, settings and projects are kept, and both containers start again on the next start (`restart: unless-stopped`). Storage is still billed while the instance is stopped.
- **Delete** the instance when you are finished. This removes the instance and all of its data, including downloaded models and your projects. Push any work you want to keep to your own git remote first.

## Safety

OpenHands executes the commands the model proposes inside its container, with network access. Review what it does, and do not give it credentials you would not hand to a new colleague.

## Licences

- OpenHands: MIT License.
- vLLM: Apache License 2.0.
- NVIDIA Nemotron 3.5 Lightning: governed by the OpenMDW License Agreement, version 1.1 (see the model card). By deploying with this model you accept its terms.
- Qwen3-Coder-30B-A3B-Instruct-FP8: Apache License 2.0.

## Files

- `compose.yaml` - the stack, every image pinned.
- `LICENSE` - Apache-2.0 for the files in this folder, with upstream attributions.
