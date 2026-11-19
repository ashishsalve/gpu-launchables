# Troubleshooting

Run these in the Brev terminal of the instance.

## The page says the model is loading

The first start downloads the model and loads it into vLLM.

```
sudo docker logs --tail 50 vllm
curl -s http://localhost:8000/v1/models
```

When the model list shows `nemotron-omni`, the header turns to "ready".

## The chat page does not open

```
curl -s http://localhost:7860/healthz
sudo docker ps --format '{{.Names}} {{.Status}}'
sudo docker logs --tail 50 agent-ui
sudo docker logs --tail 50 agent-proxy
```

The health answer has `"ui":"ok"` when the page is up, `"model":true` when the
model is ready and `"mcp":true` when the browser is reachable.

## The live desktop is black or does not connect

Use the Step view tab: it shows the latest step screenshot without a live
connection. Then check the sandbox and the port forwards:

```
openshell sandbox list
systemctl --user status browser-agent-forward@6080.service browser-agent-forward@8931.service
```

## A site does not load

Only host names in ALLOWED_DOMAINS are reachable. Blocked requests show in the
step log as sandbox lines, and in:

```
openshell logs browser-agent --since 5m --source sandbox
tail -n 50 ~/workspace/browser-agent/data/logs/denials.log
```

To change the allowlist, edit `~/workspace/browser-agent/policy.yaml` and
`~/workspace/browser-agent/agent.env`, delete the sandbox with
`openshell sandbox delete browser-agent`, then run
`sudo systemctl restart browser-agent.service` to recreate it.

## After Stop and Start

Services return by themselves: `browser-agent.service` runs at boot and a
timer re-checks every 5 minutes. To force it:

```
sudo systemctl restart browser-agent.service
journalctl -u browser-agent.service -n 50 --no-pager
```

## Setup log

```
sudo cat /var/log/brev-workspace.log
```
