# Troubleshooting

Run these in the Brev terminal of your instance.

## The links do not open yet

First start downloads two images, the model (about 18 GB) and the agent with its locked dependencies. Check progress:

```
cd /home/ubuntu/workspace
sudo docker compose ps
sudo docker compose logs --tail 50 vllm
sudo docker compose logs --tail 50 agent
```

`vllm` is ready when `curl -s http://localhost:8001/v1/models` lists `nemotron`. `agent` is ready when its log ends with `agent-init: ready`.

## The agent log shows a checksum or lock file error

The agent installs only pinned, checksum-verified downloads and refuses to continue if one does not match. If setup of the agent or its dashboard password fails, the Hermes dashboard does not start: the `hermes` link stays closed and the agent log ends with `the Hermes dashboard will not start`. Docker retries the service on its own; restart it once to retry a broken download:

```
cd /home/ubuntu/workspace && sudo docker compose restart agent
```

If the same error repeats, open an issue in this repository with the last 50 lines of `sudo docker compose logs agent`.

## Services are not running after Start

```
cd /home/ubuntu/workspace && sudo docker compose up -d
```

## JupyterLab asks for a login key

```
sudo cat /home/ubuntu/workspace/rapids-data-science-agent/.jupyter-token
```

## The Hermes dashboard asks for a login

The dashboard opens a login page. User `hermes`. Password:

```
sudo cat /home/ubuntu/workspace/rapids-data-science-agent/hermes/dashboard-password
```

If the `hermes` link does not open at all, check `sudo docker compose logs agent`. On its first start the dashboard builds its web page before it answers.

## The `agent` command is not found

The agent service installs Hermes on first start. Wait for `agent-init: ready` in `sudo docker compose logs agent`, then open a new terminal.

## GPU out of memory in a notebook

The model server and RAPIDS share the GPU. Read fewer columns, or process the data in chunks.

## Setup log

```
sudo cat /var/log/brev-workspace.log
```
