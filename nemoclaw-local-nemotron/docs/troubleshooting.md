# Troubleshooting

## Setup did not finish

Read the setup log:

```
sudo cat /var/log/brev-workspace.log
```

The last line on success is `Agent ready. Open the agent link; access URL in ~/workspace/private-agent/AGENT_URL.txt`, or `Agent ready. In the terminal run: sg docker -c 'nemoclaw private-agent connect'` for `langchain-deepagents-code`.

## A nemoclaw command says it cannot attribute a listener

The agent runs under the `docker` group. Run `nemoclaw` commands in the same group, for example:

```
sg docker -c 'nemoclaw private-agent connect'
```

## The model server is not ready

```
sudo docker ps --filter name=nemotron-vllm
sudo docker logs --tail 100 nemotron-vllm
curl -fsS http://127.0.0.1:8000/v1/models
```

The first start downloads the model weights into `~/workspace/nemotron-vllm/huggingface`. If the log shows an out-of-memory error, deploy again with a smaller `MAX_MODEL_LEN`.

## NemoClaw did not install

The installer output is in `~/workspace/private-agent/.state/nemoclaw-install.log`:

```
tail -n 100 ~/workspace/private-agent/.state/nemoclaw-install.log
```

## The agent link shows an error

```
sudo docker ps --filter name=agent-proxy
sudo docker logs --tail 50 agent-proxy
sg docker -c 'nemoclaw private-agent status'
```

If the dashboard asks for a token, use the URL in `~/workspace/private-agent/AGENT_URL.txt`. The token may change after Stop and Start.

## The agent did not come back after Start

```
sudo systemctl status private-agent-recover
sudo tail -n 100 /var/log/private-agent-recover.log
sudo systemctl restart private-agent-recover
```

The service waits up to 20 minutes for the model server, restarts NemoClaw's local inference proxy, recovers the sandbox, re-applies the policy and rewrites `AGENT_URL.txt`.

## An outbound request was not allowed

The sandbox policy is NemoClaw's balanced tier plus GET, HEAD and OPTIONS to `github.com` and `codeload.github.com` for `git` and `curl`. Show the active policy:

```
openshell policy get private-agent
```

The GitHub rule is applied by `~/workspace/private-agent/post-recover.sh` after every recovery. Allow only hosts you trust.

## The agent link returns 403

The proxy accepts requests from the Brev Secure Link and plain GET requests without an `Origin` header. Open the agent through the `agent` link on the instance page.
