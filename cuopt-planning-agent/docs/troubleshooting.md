# Troubleshooting

All commands run on the instance (`brev shell <instance-name>`), in the folder Brev used for the compose project.

## The status strip says Model: loading

The first start downloads the model and loads it into vLLM. Follow it with:

```
docker compose logs -f vllm
```

vLLM is ready when `curl -s http://localhost:8000/v1/models` lists `nemotron-planner`.

## The status strip says cuOpt: loading

```
docker compose logs --tail 100 cuopt
docker compose ps
```

cuOpt is ready when its health check reports healthy. The compose file starts cuOpt only after vLLM reports healthy (`depends_on` with `condition: service_healthy`), so vLLM takes its share of GPU memory first. Every service has `restart: unless-stopped`. If vLLM or cuOpt fails with an out-of-memory error, restart them in that order:

```
docker compose stop cuopt
docker compose restart vllm
```

Wait until `curl -s http://localhost:8000/v1/models` lists `nemotron-planner`, then run `docker compose start cuopt`.

## Map: integrity check failed or download failed

The planner downloads MapLibre GL JS from registry.npmjs.org on first start and uses it only if its sha512 matches the pinned value. Only the map view needs this library; the solve requests do not. Check outbound access, then `docker compose restart planner`.

## The agent does not call a tool

Use the Solve without the agent buttons to check cuOpt on its own. Then ask again with explicit numbers, for example the van count, capacity and times.

## Unserved stops

If the summary lists unserved stops, compare the total demand with the van capacity. Add a van, raise the capacity or lower demand.

## Logs

```
sudo cat /var/log/brev-workspace.log
docker compose logs --no-color planner
```

## Start over

Stop the services, delete `/home/ubuntu/workspace/cuopt-planner/samples` to restore the sample CSV files, then start again:

```
docker compose down
docker compose up -d
```
